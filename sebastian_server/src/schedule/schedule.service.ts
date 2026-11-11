import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  INPUT_SOURCE_AI,
  INPUT_SOURCE_MANUAL,
  Schedule,
} from './schedule.entity';
import { CreateScheduleDto } from './dto/create-schedule.dto';
import { UpdateScheduleDto } from './dto/update-schedule.dto';
import { ScheduleResponseDto } from './dto/schedule-response.dto';
import {
  addOneHourKst,
  kstDateTime,
  kstEndOfDay,
  kstStartOfDay,
  SCHEDULE_TZ,
  todayYmdKst,
  toKstIso,
} from './schedule-datetime.util';
import { DDayService } from '../dday/dday.service';
import { ScheduleDdayDateBasis } from './schedule-dday-date-basis.enum';

const AI_DRAFT_MATCH_MINUTES = 30;

function ymdFromDateKst(d: Date): string {
  return d.toLocaleDateString('en-CA', { timeZone: SCHEDULE_TZ });
}

function resolveDdayTargetYmd(
  start: Date,
  end: Date,
  basis: ScheduleDdayDateBasis,
): string {
  return basis === ScheduleDdayDateBasis.END
    ? ymdFromDateKst(end)
    : ymdFromDateKst(start);
}

function isAllDayKst(start: Date, end: Date, dateYmd: string): boolean {
  return (
    start.getTime() === kstStartOfDay(dateYmd).getTime() &&
    end.getTime() === kstEndOfDay(dateYmd).getTime()
  );
}

/** AI 도구 JSON 필드: 문자열·숫자 등만 문자열로 (객체는 빈 문자열) — no-base-to-string 대응 */
function scalarString(value: unknown): string {
  if (value === null || value === undefined) return '';
  if (typeof value === 'string') return value;
  if (
    typeof value === 'number' ||
    typeof value === 'boolean' ||
    typeof value === 'bigint'
  ) {
    return String(value);
  }
  return '';
}

const DEFAULT_PAGE = 1;
const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 100;

@Injectable()
export class ScheduleService {
  private readonly logger = new Logger(ScheduleService.name);

  constructor(
    @InjectRepository(Schedule)
    private readonly scheduleRepo: Repository<Schedule>,
    private readonly ddayService: DDayService,
  ) {}

  private toDto(row: Schedule): ScheduleResponseDto {
    return {
      id: row.id,
      userId: row.userId,
      title: row.title,
      content: row.content,
      originalText: row.originalText,
      startDate: row.startDate,
      endDate: row.endDate,
      createdAt: row.createdAt,
      category: row.category,
      priority: row.priority ?? 2,
      inputSource: row.inputSource,
      isCompleted: row.isCompleted,
      completedAt: row.completedAt,
      isAlarmOn: row.isAlarmOn,
      isImportant: row.isImportant ?? false,
      notificationLeadMinutes: row.notificationLeadMinutes ?? 30,
      ddayId: row.ddayId ?? null,
      ddayDateBasis: row.ddayDateBasis ?? null,
    };
  }

  private normalizeDdayDateBasis(
    basis?: ScheduleDdayDateBasis,
  ): ScheduleDdayDateBasis {
    return basis === ScheduleDdayDateBasis.END
      ? ScheduleDdayDateBasis.END
      : ScheduleDdayDateBasis.START;
  }

  private async syncLinkedDday(
    userId: number,
    row: Schedule,
    createDday: boolean | undefined,
    ddayDateBasis: ScheduleDdayDateBasis | undefined,
  ): Promise<void> {
    const wantDday = createDday === true;
    const basis = this.normalizeDdayDateBasis(ddayDateBasis);

    if (!wantDday) {
      if (row.ddayId != null) {
        await this.ddayService.remove(row.ddayId, userId);
        row.ddayId = null;
        row.ddayDateBasis = null;
      }
      return;
    }

    const targetDate = resolveDdayTargetYmd(
      row.startDate,
      row.endDate,
      basis,
    );

    if (row.ddayId != null) {
      await this.ddayService.update(row.ddayId, userId, {
        title: row.title,
        targetDate,
      });
      row.ddayDateBasis = basis;
      return;
    }

    const created = await this.ddayService.create(userId, {
      title: row.title,
      targetDate,
      memo: row.content ?? undefined,
      inputSource: 'MANUAL',
    });
    row.ddayId = created.id;
    row.ddayDateBasis = basis;
  }

  assertDateRange(start: Date, end: Date): void {
    if (end.getTime() < start.getTime()) {
      throw new BadRequestException(
        '종료 시각은 시작 시각과 같거나 이후여야 합니다.',
      );
    }
  }

  async create(
    userId: number,
    dto: CreateScheduleDto,
  ): Promise<ScheduleResponseDto> {
    const start = new Date(dto.startDate);
    const end = new Date(dto.endDate);
    this.assertDateRange(start, end);

    const inputSource = dto.inputSource ?? INPUT_SOURCE_MANUAL;
    const row = this.scheduleRepo.create({
      title: dto.title.trim(),
      content: dto.content?.trim() ?? null,
      originalText: dto.originalText?.trim() ?? null,
      startDate: start,
      endDate: end,
      category: dto.category?.trim() ?? null,
      priority: dto.priority ?? 2,
      inputSource,
      isCompleted: dto.isCompleted ?? false,
      isAlarmOn: dto.isAlarmOn ?? true,
      isImportant: dto.isImportant ?? false,
      notificationLeadMinutes: dto.notificationLeadMinutes ?? 30,
      user: { id: userId },
    });
    let saved = await this.scheduleRepo.save(row);

    if (dto.createDday) {
      await this.syncLinkedDday(
        userId,
        saved,
        true,
        dto.ddayDateBasis,
      );
      saved = await this.scheduleRepo.save(saved);
    }

    return this.toDto(saved);
  }

  /** AI가 종일로 먼저 넣은 뒤 시간만 보충하는 경우 — 최근 초안 일정 */
  private async findRecentAiDraftSchedule(
    userId: number,
    title: string,
    dateYmd: string,
    withinMinutes = AI_DRAFT_MATCH_MINUTES,
  ): Promise<Schedule | null> {
    const since = new Date(Date.now() - withinMinutes * 60 * 1000);
    const dayStart = kstStartOfDay(dateYmd);
    const dayEnd = kstEndOfDay(dateYmd);

    const rows = await this.scheduleRepo
      .createQueryBuilder('s')
      .leftJoin('s.user', 'u')
      .where('u.id = :uid', { uid: userId })
      .andWhere('s.input_source = :src', { src: INPUT_SOURCE_AI })
      .andWhere('s.created_at >= :since', { since })
      .andWhere('LOWER(TRIM(s.title)) = LOWER(TRIM(:title))', { title })
      .andWhere('s.start_date = :dayStart', { dayStart })
      .andWhere('s.end_date = :dayEnd', { dayEnd })
      .orderBy('s.createdAt', 'DESC')
      .take(1)
      .getMany();

    const row = rows[0];
    if (!row) return null;
    const ymd = ymdFromDateKst(row.startDate);
    return isAllDayKst(row.startDate, row.endDate, ymd) ? row : null;
  }

  private parseAiScheduleTimes(
    dateYmd: string,
    endDateYmd: string,
    startTime: string | null,
    endTime: string | null,
  ):
    | { ok: true; startDate: Date; endDate: Date }
    | { ok: false; error: string } {
    if (!startTime && !endTime) {
      return {
        ok: true,
        startDate: kstStartOfDay(dateYmd),
        endDate: kstEndOfDay(endDateYmd),
      };
    }

    if (!startTime) {
      return {
        ok: false,
        error: '시간이 있는 일정은 startTime(HH:mm)이 필요합니다.',
      };
    }

    const norm = (t: string): string => {
      const p = t.trim().split(':');
      if (p.length < 2) return t.trim();
      return `${p[0].padStart(2, '0')}:${p[1].padStart(2, '0')}`;
    };
    const validateHhmm = (t: string, label: string): { ok: false; error: string } | null => {
      const p = t.split(':');
      const h = parseInt(p[0], 10);
      const m = parseInt(p[1] ?? '0', 10);
      if (isNaN(h) || isNaN(m) || h < 0 || h > 23 || m < 0 || m > 59) {
        return { ok: false, error: `${label}(${t})이 유효한 HH:mm 범위(00:00~23:59)가 아닙니다.` };
      }
      return null;
    };
    const st = norm(startTime);
    const stErr = validateHhmm(st, 'startTime');
    if (stErr) return stErr;
    const startDate = kstDateTime(dateYmd, st);
    let endDate: Date;
    if (endTime) {
      const et = norm(endTime);
      const etErr = validateHhmm(et, 'endTime');
      if (etErr) return etErr;
      endDate = kstDateTime(endDateYmd, et);
    } else {
      endDate = addOneHourKst(startDate);
    }
    return { ok: true, startDate, endDate };
  }

  /**
   * AI 도구(update_schedule) — 기존 일정 수정.
   */
  async updateFromAiToolInput(
    userId: number,
    scheduleId: number,
    input: Record<string, unknown>,
    originalChat: string,
  ): Promise<
    | { ok: true; schedule: ScheduleResponseDto; updated: true }
    | { ok: false; error: string }
  > {
    try {
      const row = await this.scheduleRepo.findOne({
        where: { id: scheduleId, user: { id: userId } },
      });
      if (!row) {
        return { ok: false, error: '일정을 찾을 수 없습니다.' };
      }

      const title =
        input.title !== undefined
          ? scalarString(input.title).trim() || row.title
          : row.title;

      const date =
        input.date !== undefined
          ? scalarString(input.date).trim()
          : ymdFromDateKst(row.startDate);
      if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        return { ok: false, error: 'date(YYYY-MM-DD) 형식이 올바르지 않습니다.' };
      }

      const endDateYmd = scalarString(
        input.endDate !== undefined && input.endDate !== null
          ? input.endDate
          : date,
      ).trim();
      if (!/^\d{4}-\d{2}-\d{2}$/.test(endDateYmd)) {
        return { ok: false, error: 'endDate 형식이 올바르지 않습니다.' };
      }

      const hasTimeInput =
        (input.startTime !== undefined &&
          input.startTime !== null &&
          scalarString(input.startTime).trim() !== '') ||
        (input.endTime !== undefined &&
          input.endTime !== null &&
          scalarString(input.endTime).trim() !== '');

      let startDate: Date;
      let endDate: Date;

      if (hasTimeInput) {
        const startTimeRaw = input.startTime;
        const endTimeRaw = input.endTime;
        const startTime =
          startTimeRaw == null || startTimeRaw === ''
            ? null
            : scalarString(startTimeRaw).trim();
        const endTime =
          endTimeRaw == null || endTimeRaw === ''
            ? null
            : scalarString(endTimeRaw).trim();

        const parsed = this.parseAiScheduleTimes(
          date,
          endDateYmd,
          startTime,
          endTime,
        );
        if (!parsed.ok) {
          return { ok: false, error: parsed.error };
        }
        startDate = parsed.startDate;
        endDate = parsed.endDate;
      } else {
        startDate = row.startDate;
        endDate = row.endDate;
      }

      const category =
        input.category === undefined
          ? undefined
          : scalarString(input.category).trim() || null;
      const content =
        input.description === undefined
          ? undefined
          : scalarString(input.description).trim() || null;

      const dto: UpdateScheduleDto = {
        title,
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
        originalText: originalChat,
      };
      if (category !== undefined) dto.category = category ?? undefined;
      if (content !== undefined) dto.content = content ?? undefined;
      if (typeof input.isAlarmOn === 'boolean') {
        dto.isAlarmOn = input.isAlarmOn;
      }

      const schedule = await this.update(scheduleId, userId, dto);
      return { ok: true, schedule, updated: true };
    } catch (e: unknown) {
      const msg =
        e instanceof Error
          ? e.message
          : typeof e === 'string'
            ? e
            : '일정 수정에 실패했습니다.';
      return { ok: false, error: msg };
    }
  }

  /**
   * AI 도구(create_schedule)에서 받은 JSON으로 일정 생성.
   * 실패 시 ok:false (채팅 tool_result에 전달).
   */
  async createFromAiToolInput(
    userId: number,
    input: Record<string, unknown>,
    originalChat: string,
  ): Promise<
    | { ok: true; schedule: ScheduleResponseDto; updated?: boolean }
    | { ok: false; error: string }
  > {
    try {
      const title = scalarString(input.title).trim();
      const date = scalarString(input.date).trim();
      if (!title || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        return {
          ok: false,
          error: 'title과 date(YYYY-MM-DD)가 필요합니다.',
        };
      }

      const endDateYmd = scalarString(
        input.endDate !== undefined && input.endDate !== null
          ? input.endDate
          : date,
      ).trim();
      if (!/^\d{4}-\d{2}-\d{2}$/.test(endDateYmd)) {
        return { ok: false, error: 'endDate 형식이 올바르지 않습니다.' };
      }

      const startTimeRaw = input.startTime;
      const endTimeRaw = input.endTime;
      const startTime =
        startTimeRaw == null || startTimeRaw === ''
          ? null
          : scalarString(startTimeRaw).trim();
      const endTime =
        endTimeRaw == null || endTimeRaw === ''
          ? null
          : scalarString(endTimeRaw).trim();

      if (startTime) {
        const draft = await this.findRecentAiDraftSchedule(
          userId,
          title,
          date,
        );
        if (draft) {
          return this.updateFromAiToolInput(
            userId,
            draft.id,
            input,
            originalChat,
          );
        }
      }

      const category =
        input.category == null
          ? null
          : scalarString(input.category).trim() || null;
      const content =
        input.description == null
          ? null
          : scalarString(input.description).trim() || null;

      const priorityRaw = input.priority;
      let priority: number | undefined;
      if (priorityRaw !== undefined && priorityRaw !== null) {
        const n = Number(priorityRaw);
        if (Number.isInteger(n) && n >= 1 && n <= 3) {
          priority = n;
        }
      }

      const parsed = this.parseAiScheduleTimes(
        date,
        endDateYmd,
        startTime,
        endTime,
      );
      if (!parsed.ok) {
        return { ok: false, error: parsed.error };
      }
      const { startDate, endDate } = parsed;

      this.assertDateRange(startDate, endDate);

      const isAlarmOn =
        typeof input.isAlarmOn === 'boolean' ? input.isAlarmOn : true;

      const dto: CreateScheduleDto = {
        title,
        content: content ?? undefined,
        originalText: originalChat,
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
        category: category ?? undefined,
        priority,
        inputSource: INPUT_SOURCE_AI,
        isCompleted: false,
        isAlarmOn,
      };

      const schedule = await this.create(userId, dto);
      return { ok: true, schedule };
    } catch (e: unknown) {
      this.logger.error('createFromAiToolInput/updateFromAiToolInput error', e);
      const msg =
        e instanceof Error
          ? e.message
          : typeof e === 'string'
            ? e
            : '일정 생성에 실패했습니다.';
      return { ok: false, error: msg };
    }
  }

  async findAll(
    userId: number,
    from?: string,
    to?: string,
    page: number = DEFAULT_PAGE,
    limit: number = DEFAULT_LIMIT,
  ): Promise<{
    items: ScheduleResponseDto[];
    total: number;
    page: number;
    limit: number;
  }> {
    const take = Math.min(Math.max(limit, 1), MAX_LIMIT);
    const skip = (Math.max(page, 1) - 1) * take;

    const buildFiltered = () => {
      const qb = this.scheduleRepo
        .createQueryBuilder('s')
        .leftJoin('s.user', 'u')
        .where('u.id = :uid', { uid: userId });
      if (from && to) {
        qb.andWhere('s.startDate <= :rangeEnd', {
          rangeEnd: new Date(to),
        }).andWhere('s.endDate >= :rangeStart', {
          rangeStart: new Date(from),
        });
      }
      return qb;
    };

    const total = await buildFiltered().getCount();
    const rows = await buildFiltered()
      .orderBy('s.startDate', 'ASC')
      .skip(skip)
      .take(take)
      .getMany();

    return {
      items: rows.map((r) => this.toDto(r)),
      total,
      page: Math.max(page, 1),
      limit: take,
    };
  }

  /**
   * AI 채팅 프롬프트용: 미완료 일정의 최소 필드(id·title·startTime ISO8601).
   * 자연어로 일정 제목·시간을 매칭해 scheduleId를 찾는 데 사용.
   */
  async findActiveForAiContext(
    userId: number,
  ): Promise<{ id: number; title: string; startTime: string }[]> {
    const todayStart = kstStartOfDay(todayYmdKst()); // 오늘 00:00(KST) 이전의 지난 일정 제외
    const rows = await this.scheduleRepo
      .createQueryBuilder('s')
      .select(['s.id', 's.title', 's.startDate'])
      .leftJoin('s.user', 'u')
      .where('u.id = :uid', { uid: userId })
      .andWhere('s.is_completed = :done', { done: false })
      .andWhere('s.start_date >= :todayStart', { todayStart })
      .orderBy('s.startDate', 'ASC')
      .getMany();

    return rows.map((r) => ({
      id: r.id,
      title: r.title,
      startTime: toKstIso(r.startDate), // UTC(Z) 대신 KST(+09:00) — 한국 날짜 기준 인식
    }));
  }

  /**
   * 미루기용: 시작이 지났는데 아직 미완료인 일정 — id·title·startTime만.
   */
  async findOverdue(
    userId: number,
  ): Promise<{ id: number; title: string; startTime: string }[]> {
    const now = new Date();
    // 7일 이내의 미완료 일정만 조회. 그 이상 오래된 것은 브리핑하지 않음.
    const cutoff = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const rows = await this.scheduleRepo
      .createQueryBuilder('s')
      .select(['s.id', 's.title', 's.startDate'])
      .leftJoin('s.user', 'u')
      .where('u.id = :uid', { uid: userId })
      .andWhere('s.is_completed = :done', { done: false })
      .andWhere('s.start_date >= :cutoff', { cutoff })
      .andWhere('s.start_date < :now', { now })
      .orderBy('s.startDate', 'ASC')
      .getMany();

    return rows.map((r) => ({
      id: r.id,
      title: r.title,
      startTime: toKstIso(r.startDate), // UTC(Z) 대신 KST(+09:00) — AI·Flutter가 한국 시각으로 인식
    }));
  }

  /**
   * 로컬 알림용: 알림 켜짐·미완료·시작이 [지금, 지금+withinHours] 안에 있는 일정.
   */
  async findUpcomingForAlarms(
    userId: number,
    withinHours = 24,
  ): Promise<ScheduleResponseDto[]> {
    const now = new Date();
    const until = new Date(now.getTime() + withinHours * 3600 * 1000);

    const rows = await this.scheduleRepo
      .createQueryBuilder('s')
      .leftJoin('s.user', 'u')
      .where('u.id = :uid', { uid: userId })
      .andWhere('s.is_alarm_on = :aon', { aon: true })
      .andWhere('s.is_completed = :done', { done: false })
      .andWhere('s.startDate >= :now', { now })
      .andWhere('s.startDate <= :until', { until })
      .orderBy('s.startDate', 'ASC')
      .getMany();

    return rows.map((r) => this.toDto(r));
  }

  async findOne(id: number, userId: number): Promise<ScheduleResponseDto> {
    const row = await this.scheduleRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('일정을 찾을 수 없습니다');
    }
    return this.toDto(row);
  }

  async update(
    id: number,
    userId: number,
    dto: UpdateScheduleDto,
  ): Promise<ScheduleResponseDto> {
    const row = await this.scheduleRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('일정을 찾을 수 없습니다');
    }

    if (dto.title !== undefined) row.title = dto.title.trim();
    if (dto.content !== undefined) {
      row.content = dto.content?.trim() ?? null;
    }
    if (dto.originalText !== undefined) {
      row.originalText = dto.originalText?.trim() ?? null;
    }
    if (dto.startDate !== undefined) {
      row.startDate = new Date(dto.startDate);
    }
    if (dto.endDate !== undefined) {
      row.endDate = new Date(dto.endDate);
    }
    if (dto.category !== undefined) {
      row.category = dto.category?.trim() ?? null;
    }
    if (dto.priority !== undefined) row.priority = dto.priority;
    if (dto.inputSource !== undefined) row.inputSource = dto.inputSource;
    if (dto.isCompleted !== undefined) {
      row.isCompleted = dto.isCompleted;
      if (dto.isCompleted && !row.completedAt) {
        row.completedAt = new Date();
      }
      if (!dto.isCompleted) {
        row.completedAt = null;
      }
    }
    if (dto.isAlarmOn !== undefined) row.isAlarmOn = dto.isAlarmOn;
    if (dto.isImportant !== undefined) row.isImportant = dto.isImportant;
    if (dto.notificationLeadMinutes !== undefined) {
      row.notificationLeadMinutes = dto.notificationLeadMinutes;
    }

    this.assertDateRange(row.startDate, row.endDate);

    let saved = await this.scheduleRepo.save(row);

    if (dto.createDday !== undefined || dto.ddayDateBasis !== undefined) {
      await this.syncLinkedDday(
        userId,
        saved,
        dto.createDday ?? saved.ddayId != null,
        dto.ddayDateBasis ?? saved.ddayDateBasis ?? undefined,
      );
      saved = await this.scheduleRepo.save(saved);
    } else if (saved.ddayId != null) {
      const basis =
        saved.ddayDateBasis ?? ScheduleDdayDateBasis.START;
      await this.ddayService.update(saved.ddayId, userId, {
        title: saved.title,
        targetDate: resolveDdayTargetYmd(
          saved.startDate,
          saved.endDate,
          basis,
        ),
      });
    }

    return this.toDto(saved);
  }

  async remove(id: number, userId: number): Promise<void> {
    const row = await this.scheduleRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('일정을 찾을 수 없습니다');
    }
    if (row.ddayId != null) {
      await this.ddayService.remove(row.ddayId, userId);
    }
    await this.scheduleRepo.remove(row);
  }

  /** 브리핑: 오늘(KST)과 겹치는 미완료 일정 */
  async findUpcomingForBriefingToday(
    userId: number,
    dateYmd: string = todayYmdKst(),
  ): Promise<Schedule[]> {
    const rangeStart = kstStartOfDay(dateYmd);
    const rangeEnd = kstEndOfDay(dateYmd);

    return this.scheduleRepo
      .createQueryBuilder('s')
      .leftJoin('s.user', 'u')
      .where('u.id = :uid', { uid: userId })
      .andWhere('s.is_completed = :done', { done: false })
      .andWhere('s.start_date <= :rangeEnd', { rangeEnd })
      .andWhere('s.end_date >= :rangeStart', { rangeStart })
      .orderBy('s.start_date', 'ASC')
      .getMany();
  }

  /** 브리핑: 오늘(KST)에 완료 체크한 일정 */
  async findCompletedTodayForBriefing(
    userId: number,
    dateYmd: string = todayYmdKst(),
  ): Promise<Schedule[]> {
    const rangeStart = kstStartOfDay(dateYmd);
    const rangeEnd = kstEndOfDay(dateYmd);

    return this.scheduleRepo
      .createQueryBuilder('s')
      .leftJoin('s.user', 'u')
      .where('u.id = :uid', { uid: userId })
      .andWhere('s.is_completed = :done', { done: true })
      .andWhere('s.completed_at IS NOT NULL')
      .andWhere('s.completed_at >= :rangeStart', { rangeStart })
      .andWhere('s.completed_at <= :rangeEnd', { rangeEnd })
      .orderBy('s.completed_at', 'ASC')
      .getMany();
  }
}
