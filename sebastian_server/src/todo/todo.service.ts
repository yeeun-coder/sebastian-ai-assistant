import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Todo } from './todo.entity';
import { CreateTodoDto } from './dto/create-todo.dto';
import { UpdateTodoDto } from './dto/update-todo.dto';
import { TodoResponseDto } from './dto/todo-response.dto';
import {
  kstEndOfDay,
  kstStartOfDay,
  todayYmdKst,
} from '../schedule/schedule-datetime.util';

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

function parseLeadDaysValue(value: unknown): number | undefined {
  if (value === null || value === undefined) return undefined;
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.max(0, Math.min(365, Math.floor(value)));
  }

  const raw = scalarString(value).trim();
  if (!raw) return undefined;

  const direct = Number(raw);
  if (Number.isFinite(direct)) {
    return Math.max(0, Math.min(365, Math.floor(direct)));
  }

  const dayMatch = raw.match(/(\d+)\s*일/);
  if (dayMatch) {
    const parsed = Number(dayMatch[1]);
    if (Number.isFinite(parsed)) {
      return Math.max(0, Math.min(365, Math.floor(parsed)));
    }
  }

  return undefined;
}

@Injectable()
export class TodoService {
  constructor(
    @InjectRepository(Todo)
    private readonly todoRepo: Repository<Todo>,
  ) {}

  private toDto(todo: Todo): TodoResponseDto {
    return {
      id: todo.id,
      userId: todo.userId,
      title: todo.title,
      content: todo.content,
      priority: todo.priority,
      category: todo.category,
      inputSource: todo.inputSource,
      originalText: todo.originalText,
      isDone: todo.isDone,
      dueDate: todo.dueDate,
      scheduleLeadDays: todo.scheduleLeadDays,
      createdAt: todo.createdAt,
      completedAt: todo.completedAt,
    };
  }

  // 내 할 일 목록 조회
  async getMyTodos(userId: number): Promise<TodoResponseDto[]> {
    const todos = await this.todoRepo.find({
      where: { userId },
      order: { createdAt: 'ASC' },
    });
    return todos.map((t) => this.toDto(t));
  }

  // 할 일 생성
  async create(userId: number, dto: CreateTodoDto): Promise<TodoResponseDto> {
    const isDone = false;
    const todo = this.todoRepo.create({
      userId,
      title: dto.title,
      content: dto.content ?? null,
      priority: dto.priority ?? 2,
      category: dto.category ?? null,
      inputSource: dto.inputSource ?? 'MANUAL',
      originalText: dto.originalText ?? null,
      isDone,
      dueDate: dto.dueDate ?? null,
      scheduleLeadDays: dto.scheduleLeadDays ?? 0,
      completedAt: null,
    });
    const saved = await this.todoRepo.save(todo);
    return this.toDto(saved);
  }

  private async findRecentAiDraftTodo(
    userId: number,
    title: string,
    withinMinutes = 30,
  ): Promise<Todo | null> {
    const since = new Date(Date.now() - withinMinutes * 60 * 1000);
    const rows = await this.todoRepo
      .createQueryBuilder('t')
      .where('t.userId = :userId', { userId })
      .andWhere('t.input_source = :src', { src: 'AI' })
      .andWhere('t.dueDate IS NULL')
      .andWhere('t.createdAt >= :since', { since })
      .andWhere('LOWER(TRIM(t.title)) = LOWER(TRIM(:title))', { title })
      .orderBy('t.createdAt', 'DESC')
      .take(1)
      .getMany();

    return rows[0] ?? null;
  }

  async updateFromAiToolInput(
    userId: number,
    todoId: number,
    input: Record<string, unknown>,
    originalChat: string,
  ): Promise<
    | { ok: true; todo: TodoResponseDto; updated: true }
    | { ok: false; error: string }
  > {
    try {
      const todo = await this.todoRepo.findOne({ where: { id: todoId } });
      if (!todo) {
        return { ok: false, error: '할 일을 찾을 수 없습니다.' };
      }
      if (todo.userId !== userId) {
        return { ok: false, error: '본인의 할 일만 수정할 수 있습니다.' };
      }

      const title =
        input.title !== undefined
          ? scalarString(input.title).trim() || todo.title
          : todo.title;

      const dueDateRaw = scalarString(input.dueDate).trim();
      const dueDate =
        dueDateRaw && /^\d{4}-\d{2}-\d{2}$/.test(dueDateRaw)
          ? dueDateRaw
          : todo.dueDate ?? undefined;

      const content =
        input.description === undefined
          ? undefined
          : scalarString(input.description).trim() || null;
      const category =
        input.category === undefined
          ? undefined
          : scalarString(input.category).trim() || null;

      const scheduleLeadDays =
        parseLeadDaysValue(input.scheduleLeadDays) ??
        parseLeadDaysValue(input.alarm) ??
        parseLeadDaysValue(input.remindBefore) ??
        parseLeadDaysValue(input.notificationLeadDays);

      const dto: UpdateTodoDto = {
        title,
        originalText: originalChat,
      };
      if (dueDate !== undefined) dto.dueDate = dueDate;
      if (content !== undefined) dto.content = content;
      if (category !== undefined) dto.category = category;
      if (scheduleLeadDays !== undefined) {
        dto.scheduleLeadDays = scheduleLeadDays;
      }

      const updated = await this.update(userId, todoId, dto);
      return { ok: true, todo: updated, updated: true };
    } catch (e: unknown) {
      const msg =
        e instanceof Error
          ? e.message
          : typeof e === 'string'
            ? e
            : '할 일 수정에 실패했습니다.';
      return { ok: false, error: msg };
    }
  }

  async createFromAiToolInput(
    userId: number,
    input: Record<string, unknown>,
    originalChat: string,
  ): Promise<
    | { ok: true; todo: TodoResponseDto; updated?: boolean }
    | { ok: false; error: string }
  > {
    try {
      const title = scalarString(input.title).trim();
      if (!title) {
        return { ok: false, error: 'title이 필요합니다.' };
      }

      const dueDateRaw = scalarString(input.dueDate).trim();
      const dueDate =
        dueDateRaw && /^\d{4}-\d{2}-\d{2}$/.test(dueDateRaw)
          ? dueDateRaw
          : undefined;

      if (dueDate) {
        const draft = await this.findRecentAiDraftTodo(userId, title);
        if (draft) {
          return this.updateFromAiToolInput(
            userId,
            draft.id,
            input,
            originalChat,
          );
        }
      }

      const content = scalarString(input.description).trim() || undefined;
      const category = scalarString(input.category).trim() || undefined;

      const scheduleLeadDays =
        parseLeadDaysValue(input.scheduleLeadDays) ??
        parseLeadDaysValue(input.alarm) ??
        parseLeadDaysValue(input.remindBefore) ??
        parseLeadDaysValue(input.notificationLeadDays);

      const dto: CreateTodoDto = {
        title,
        dueDate,
        content,
        category,
        inputSource: 'AI',
        originalText: originalChat,
        scheduleLeadDays,
      };

      const todo = await this.create(userId, dto);
      return { ok: true, todo };
    } catch (e: unknown) {
      const msg =
        e instanceof Error
          ? e.message
          : typeof e === 'string'
            ? e
            : '할 일 생성에 실패했습니다.';
      return { ok: false, error: msg };
    }
  }

  // 할 일 수정
  async update(userId: number, todoId: number, dto: UpdateTodoDto): Promise<TodoResponseDto> {
    const todo = await this.todoRepo.findOne({ where: { id: todoId } });
    if (!todo) {
      throw new NotFoundException('할 일을 찾을 수 없습니다');
    }
    if (todo.userId !== userId) {
      throw new ForbiddenException('본인의 할 일만 수정할 수 있습니다');
    }

    if (dto.title !== undefined) todo.title = dto.title;
    if (dto.content !== undefined) todo.content = dto.content ?? null;
    if (dto.priority !== undefined) todo.priority = dto.priority;
    if (dto.category !== undefined) todo.category = dto.category ?? null;
    if (dto.inputSource !== undefined) todo.inputSource = dto.inputSource;
    if (dto.originalText !== undefined) todo.originalText = dto.originalText ?? null;
    if (dto.dueDate !== undefined) todo.dueDate = dto.dueDate ?? null;
    if (dto.scheduleLeadDays !== undefined) {
      todo.scheduleLeadDays = dto.scheduleLeadDays;
    }
    if (dto.completedAt !== undefined) {
      todo.completedAt = dto.completedAt ? new Date(dto.completedAt) : null;
      if (dto.completedAt === null) {
        todo.isDone = false;
      }
    }
    if (dto.isDone !== undefined) {
      todo.isDone = dto.isDone;
      if (dto.isDone && !todo.completedAt) {
        todo.completedAt = new Date();
      }
      if (!dto.isDone) {
        todo.completedAt = null;
      }
    }

    const saved = await this.todoRepo.save(todo);
    return this.toDto(saved);
  }

  // 할 일 삭제
  async remove(userId: number, todoId: number): Promise<void> {
    const todo = await this.todoRepo.findOne({ where: { id: todoId } });
    if (!todo) {
      throw new NotFoundException('할 일을 찾을 수 없습니다');
    }
    if (todo.userId !== userId) {
      throw new ForbiddenException('본인의 할 일만 삭제할 수 있습니다');
    }
    await this.todoRepo.remove(todo);
  }

  private static addDaysYmd(dateYmd: string, days: number): string {
    const d = new Date(`${dateYmd}T12:00:00+09:00`);
    d.setDate(d.getDate() + days);
    return d.toLocaleDateString('en-CA', { timeZone: 'Asia/Seoul' });
  }

  /** 브리핑: 오늘 알림 구간에 해당하는 미완료 To-Do */
  async findUpcomingForBriefingToday(
    userId: number,
    dateYmd: string = todayYmdKst(),
  ): Promise<Todo[]> {
    const rows = await this.todoRepo.find({
      where: { userId, isDone: false },
      order: { createdAt: 'ASC' },
    });

    return rows.filter((todo) => {
      if (!todo.dueDate) return false;
      const lead = todo.scheduleLeadDays ?? 0;
      const startYmd = TodoService.addDaysYmd(todo.dueDate, -lead);
      return dateYmd >= startYmd && dateYmd <= todo.dueDate;
    });
  }

  /** 브리핑: 오늘(KST)에 완료 체크한 To-Do */
  async findCompletedTodayForBriefing(
    userId: number,
    dateYmd: string = todayYmdKst(),
  ): Promise<Todo[]> {
    const rangeStart = kstStartOfDay(dateYmd);
    const rangeEnd = kstEndOfDay(dateYmd);

    return this.todoRepo
      .createQueryBuilder('t')
      .where('t.userId = :userId', { userId })
      .andWhere('t.isDone = :done', { done: true })
      .andWhere('t.completed_at IS NOT NULL')
      .andWhere('t.completed_at >= :rangeStart', { rangeStart })
      .andWhere('t.completed_at <= :rangeEnd', { rangeEnd })
      .orderBy('t.completed_at', 'ASC')
      .getMany();
  }
}
