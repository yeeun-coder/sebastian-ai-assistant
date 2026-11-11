import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Routine } from './routine.entity';
import { RoutineCompletion } from './routine-completion.entity';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { UpdateRoutineDto } from './dto/update-routine.dto';
import { RoutineResponseDto } from './dto/routine-response.dto';
import { RoutineRepeatInterval } from './routine-repeat-interval.enum';
import { routineMatchesDate } from './routine-date.util';
import { todayYmdKst } from '../schedule/schedule-datetime.util';

function normalizeTime(t: string): string {
  const parts = t.trim().split(':');
  if (parts.length < 2) return t.trim();
  const h = parts[0].padStart(2, '0');
  const m = parts[1].padStart(2, '0');
  return `${h}:${m}`;
}

function todayYmd(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

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

function parseOptionalInt(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.floor(value);
  }
  const s = scalarString(value).trim();
  if (!s) return null;
  const n = Number(s);
  return Number.isFinite(n) ? Math.floor(n) : null;
}

function parseRepeatInterval(raw: string): RoutineRepeatInterval | null {
  const u = raw.trim().toUpperCase();
  const vals = Object.values(RoutineRepeatInterval) as string[];
  return vals.includes(u) ? (u as RoutineRepeatInterval) : null;
}

/** AI 도구: habits / items 배열 또는 쉼표 구분 문자열 */
function parseHabitTitles(input: Record<string, unknown>): string[] {
  const raw = input.habits ?? input.items;
  if (Array.isArray(raw)) {
    return raw
      .map((x) => scalarString(x).trim())
      .filter((s) => s.length > 0);
  }
  if (typeof raw === 'string' && raw.trim()) {
    return raw
      .split(/[,，]/)
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
  }
  return [];
}

@Injectable()
export class RoutineService {
  constructor(
    @InjectRepository(Routine)
    private readonly routineRepo: Repository<Routine>,
    @InjectRepository(RoutineCompletion)
    private readonly completionRepo: Repository<RoutineCompletion>,
  ) {}

  private toDto(row: Routine): RoutineResponseDto {
    return {
      id: row.id,
      userId: row.userId,
      category: row.category,
      title: row.title,
      targetTime: row.targetTime,
      repeatInterval:
        row.repeatInterval ?? RoutineRepeatInterval.WEEKLY,
      repeatDays: row.repeatDays ?? '',
      repeatDayOfMonth: row.repeatDayOfMonth ?? null,
      repeatMonth: row.repeatMonth ?? null,
      biweeklyAnchorDate: row.biweeklyAnchorDate ?? null,
      isActive: row.isActive,
    };
  }

  private assertRepeatCoherent(
    interval: RoutineRepeatInterval,
    repeatDays: string,
    repeatDayOfMonth: number | null,
    repeatMonth: number | null,
  ): void {
    switch (interval) {
      case RoutineRepeatInterval.DAILY:
        break;
      case RoutineRepeatInterval.WEEKLY:
      case RoutineRepeatInterval.BIWEEKLY:
        if (!repeatDays?.trim()) {
          throw new BadRequestException(
            'WEEKLY·BIWEEKLY 반복에는 요일(repeatDays)이 필요합니다',
          );
        }
        break;
      case RoutineRepeatInterval.MONTHLY:
        if (
          repeatDayOfMonth == null ||
          repeatDayOfMonth < 1 ||
          repeatDayOfMonth > 31
        ) {
          throw new BadRequestException(
            'MONTHLY 반복에는 repeatDayOfMonth(1–31)가 필요합니다',
          );
        }
        break;
      case RoutineRepeatInterval.YEARLY:
        if (repeatMonth == null || repeatMonth < 1 || repeatMonth > 12) {
          throw new BadRequestException(
            'YEARLY 반복에는 repeatMonth(1–12)가 필요합니다',
          );
        }
        if (
          repeatDayOfMonth == null ||
          repeatDayOfMonth < 1 ||
          repeatDayOfMonth > 31
        ) {
          throw new BadRequestException(
            'YEARLY 반복에는 repeatDayOfMonth(1–31)가 필요합니다',
          );
        }
        break;
    }
  }

  private mergeRepeatOnUpdate(
    row: Routine,
    dto: UpdateRoutineDto,
  ): {
    repeatInterval: RoutineRepeatInterval;
    repeatDays: string;
    repeatDayOfMonth: number | null;
    repeatMonth: number | null;
    biweeklyAnchorDate: string | null;
  } {
    const repeatInterval =
      dto.repeatInterval ??
      row.repeatInterval ??
      RoutineRepeatInterval.WEEKLY;

    let repeatDays =
      dto.repeatDays !== undefined ? dto.repeatDays.trim() : row.repeatDays ?? '';
    let repeatDayOfMonth =
      dto.repeatDayOfMonth !== undefined
        ? dto.repeatDayOfMonth
        : row.repeatDayOfMonth;
    let repeatMonth =
      dto.repeatMonth !== undefined ? dto.repeatMonth : row.repeatMonth;
    let biweeklyAnchorDate =
      dto.biweeklyAnchorDate !== undefined
        ? dto.biweeklyAnchorDate.trim() || null
        : row.biweeklyAnchorDate;

    switch (repeatInterval) {
      case RoutineRepeatInterval.DAILY:
        repeatDays = '';
        repeatDayOfMonth = null;
        repeatMonth = null;
        biweeklyAnchorDate = null;
        break;
      case RoutineRepeatInterval.WEEKLY:
        repeatDayOfMonth = null;
        repeatMonth = null;
        biweeklyAnchorDate = null;
        break;
      case RoutineRepeatInterval.BIWEEKLY:
        repeatDayOfMonth = null;
        repeatMonth = null;
        if (!biweeklyAnchorDate) {
          biweeklyAnchorDate = todayYmd();
        }
        break;
      case RoutineRepeatInterval.MONTHLY:
        repeatDays = '';
        repeatMonth = null;
        biweeklyAnchorDate = null;
        break;
      case RoutineRepeatInterval.YEARLY:
        repeatDays = '';
        biweeklyAnchorDate = null;
        break;
    }

    return {
      repeatInterval,
      repeatDays,
      repeatDayOfMonth,
      repeatMonth,
      biweeklyAnchorDate,
    };
  }

  async create(
    userId: number,
    dto: CreateRoutineDto,
  ): Promise<RoutineResponseDto> {
    const interval =
      dto.repeatInterval ?? RoutineRepeatInterval.WEEKLY;

    let repeatDays = '';
    let repeatDayOfMonth: number | null = null;
    let repeatMonth: number | null = null;
    let biweeklyAnchorDate: string | null = null;

    switch (interval) {
      case RoutineRepeatInterval.DAILY:
        break;
      case RoutineRepeatInterval.WEEKLY:
        repeatDays = dto.repeatDays!.trim();
        break;
      case RoutineRepeatInterval.BIWEEKLY:
        repeatDays = dto.repeatDays!.trim();
        biweeklyAnchorDate =
          dto.biweeklyAnchorDate?.trim() || todayYmd();
        break;
      case RoutineRepeatInterval.MONTHLY:
        repeatDayOfMonth = dto.repeatDayOfMonth!;
        break;
      case RoutineRepeatInterval.YEARLY:
        repeatDayOfMonth = dto.repeatDayOfMonth!;
        repeatMonth = dto.repeatMonth!;
        break;
    }

    this.assertRepeatCoherent(
      interval,
      repeatDays,
      repeatDayOfMonth,
      repeatMonth,
    );

    const row = this.routineRepo.create({
      category: dto.category.trim(),
      title: dto.title.trim(),
      targetTime: normalizeTime(dto.targetTime),
      repeatInterval: interval,
      repeatDays,
      repeatDayOfMonth,
      repeatMonth,
      biweeklyAnchorDate,
      isActive: dto.isActive ?? true,
      user: { id: userId },
    });
    const saved = await this.routineRepo.save(row);
    return this.toDto(saved);
  }

  /**
   * AI 채팅 도구 `create_routine` 입력 → 동일 조건으로 습관(title)마다 행 저장
   */
  async createFromAiToolInput(
    userId: number,
    input: Record<string, unknown>,
    _originalChat: string,
  ): Promise<
    | { ok: true; routines: RoutineResponseDto[] }
    | { ok: false; error: string }
  > {
    try {
      const fromHabits = parseHabitTitles(input);
      const singleTitle = scalarString(input.title).trim();
      const titles =
        fromHabits.length > 0
          ? fromHabits
          : singleTitle
            ? [singleTitle]
            : [];

      if (titles.length === 0) {
        return {
          ok: false,
          error:
            '습관 제목이 필요합니다. title 하나 또는 habits(문자열 배열)를 넣어 주세요.',
        };
      }

      const targetTimeRaw = scalarString(input.targetTime).trim();
      if (!targetTimeRaw || !/^\d{1,2}:\d{2}$/.test(targetTimeRaw)) {
        return {
          ok: false,
          error: 'targetTime은 HH:mm 형식(예: 09:00, 13:30)이 필요합니다.',
        };
      }

      const interval = parseRepeatInterval(
        scalarString(input.repeatInterval),
      );
      if (!interval) {
        return {
          ok: false,
          error:
            'repeatInterval은 DAILY, WEEKLY, BIWEEKLY, MONTHLY, YEARLY 중 하나여야 합니다.',
        };
      }

      const category = scalarString(input.category).trim() || '일반';

      const routines: RoutineResponseDto[] = [];

      for (const title of titles) {
        const dto: CreateRoutineDto = {
          category,
          title,
          targetTime: targetTimeRaw,
          repeatInterval: interval,
        };

        switch (interval) {
          case RoutineRepeatInterval.DAILY:
            break;
          case RoutineRepeatInterval.WEEKLY:
          case RoutineRepeatInterval.BIWEEKLY: {
            const repeatDays = scalarString(input.repeatDays).trim();
            if (!repeatDays) {
              return {
                ok: false,
                error:
                  'WEEKLY·BIWEEKLY 반복에는 repeatDays(예: MON,WED,FRI)가 필요합니다.',
              };
            }
            dto.repeatDays = repeatDays;
            if (interval === RoutineRepeatInterval.BIWEEKLY) {
              const ad = scalarString(input.biweeklyAnchorDate).trim();
              if (ad && /^\d{4}-\d{2}-\d{2}$/.test(ad)) {
                dto.biweeklyAnchorDate = ad;
              }
            }
            break;
          }
          case RoutineRepeatInterval.MONTHLY: {
            const dom = parseOptionalInt(input.repeatDayOfMonth);
            if (dom == null || dom < 1 || dom > 31) {
              return {
                ok: false,
                error: 'MONTHLY에는 repeatDayOfMonth(1–31)가 필요합니다.',
              };
            }
            dto.repeatDayOfMonth = dom;
            break;
          }
          case RoutineRepeatInterval.YEARLY: {
            const m = parseOptionalInt(input.repeatMonth);
            const dom = parseOptionalInt(input.repeatDayOfMonth);
            if (m == null || m < 1 || m > 12) {
              return {
                ok: false,
                error: 'YEARLY에는 repeatMonth(1–12)가 필요합니다.',
              };
            }
            if (dom == null || dom < 1 || dom > 31) {
              return {
                ok: false,
                error: 'YEARLY에는 repeatDayOfMonth(1–31)가 필요합니다.',
              };
            }
            dto.repeatMonth = m;
            dto.repeatDayOfMonth = dom;
            break;
          }
        }

        routines.push(await this.create(userId, dto));
      }

      return { ok: true, routines };
    } catch (e: unknown) {
      const msg =
        e instanceof Error
          ? e.message
          : typeof e === 'string'
            ? e
            : '루틴 생성에 실패했습니다.';
      return { ok: false, error: msg };
    }
  }

  async findAll(userId: number): Promise<RoutineResponseDto[]> {
    const rows = await this.routineRepo.find({
      where: { user: { id: userId } },
      order: { category: 'ASC', id: 'ASC' },
    });
    return rows.map((r) => this.toDto(r));
  }

  async findOne(id: number, userId: number): Promise<RoutineResponseDto> {
    const row = await this.routineRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('루틴을 찾을 수 없습니다');
    }
    return this.toDto(row);
  }

  async update(
    id: number,
    userId: number,
    dto: UpdateRoutineDto,
  ): Promise<RoutineResponseDto> {
    const row = await this.routineRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('루틴을 찾을 수 없습니다');
    }

    if (dto.category !== undefined) row.category = dto.category.trim();
    if (dto.title !== undefined) row.title = dto.title.trim();
    if (dto.targetTime !== undefined) {
      row.targetTime = normalizeTime(dto.targetTime);
    }
    if (dto.isActive !== undefined) row.isActive = dto.isActive;

    const repeatTouched =
      dto.repeatInterval !== undefined ||
      dto.repeatDays !== undefined ||
      dto.repeatDayOfMonth !== undefined ||
      dto.repeatMonth !== undefined ||
      dto.biweeklyAnchorDate !== undefined;

    if (repeatTouched) {
      const merged = this.mergeRepeatOnUpdate(row, dto);
      this.assertRepeatCoherent(
        merged.repeatInterval,
        merged.repeatDays,
        merged.repeatDayOfMonth,
        merged.repeatMonth,
      );
      row.repeatInterval = merged.repeatInterval;
      row.repeatDays = merged.repeatDays;
      row.repeatDayOfMonth = merged.repeatDayOfMonth;
      row.repeatMonth = merged.repeatMonth;
      row.biweeklyAnchorDate = merged.biweeklyAnchorDate;
    }

    const saved = await this.routineRepo.save(row);
    return this.toDto(saved);
  }

  async remove(id: number, userId: number): Promise<void> {
    const row = await this.routineRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('루틴을 찾을 수 없습니다');
    }
    await this.routineRepo.remove(row);
  }

  async getCompletedRoutineIds(
    userId: number,
    date: string,
  ): Promise<number[]> {
    const rows = await this.completionRepo.find({
      where: { user: { id: userId }, completedDate: date },
      relations: { routine: true },
    });
    return rows.map((r) => r.routine.id);
  }

  async setCompletion(
    userId: number,
    routineId: number,
    date: string,
    completed: boolean,
  ): Promise<void> {
    const routine = await this.routineRepo.findOne({
      where: { id: routineId, user: { id: userId } },
    });
    if (!routine) {
      throw new NotFoundException('루틴을 찾을 수 없습니다');
    }

    if (completed) {
      const existing = await this.completionRepo.findOne({
        where: {
          routine: { id: routineId },
          user: { id: userId },
          completedDate: date,
        },
      });
      if (!existing) {
        await this.completionRepo.save(
          this.completionRepo.create({
            routine: { id: routineId },
            user: { id: userId },
            completedDate: date,
          }),
        );
      }
      return;
    }

    await this.completionRepo.delete({
      routine: { id: routineId },
      user: { id: userId },
      completedDate: date,
    });
  }

  /** 브리핑: 오늘 해당·미완료 루틴 */
  async findUpcomingForBriefingToday(
    userId: number,
    dateYmd: string = todayYmdKst(),
  ): Promise<Routine[]> {
    const completedIds = new Set(
      await this.getCompletedRoutineIds(userId, dateYmd),
    );
    const rows = await this.routineRepo.find({
      where: { user: { id: userId }, isActive: true },
      order: { category: 'ASC', title: 'ASC' },
    });
    return rows.filter(
      (r) =>
        routineMatchesDate(r, dateYmd) && !completedIds.has(r.id),
    );
  }

  /** 브리핑: 오늘 체크 완료한 루틴 (제목·시간 포함) */
  async findCompletedTodayForBriefing(
    userId: number,
    dateYmd: string = todayYmdKst(),
  ): Promise<Routine[]> {
    const completedIds = new Set(
      await this.getCompletedRoutineIds(userId, dateYmd),
    );
    if (completedIds.size === 0) return [];

    const rows = await this.routineRepo.find({
      where: { user: { id: userId }, isActive: true },
      order: { category: 'ASC', title: 'ASC' },
    });
    return rows.filter(
      (r) => completedIds.has(r.id) && routineMatchesDate(r, dateYmd),
    );
  }
}
