import { Injectable } from '@nestjs/common';
import { Schedule } from '../schedule/schedule.entity';
import { ScheduleService } from '../schedule/schedule.service';
import {
  kstDateTime,
  todayYmdKst,
} from '../schedule/schedule-datetime.util';
import { Todo } from '../todo/todo.entity';
import { TodoService } from '../todo/todo.service';
import { Routine } from '../routine/routine.entity';
import { RoutineService } from '../routine/routine.service';
import { BriefingItemDto } from './dto/briefing-item.dto';
import { TodayBriefingResponseDto } from './dto/today-briefing-response.dto';
import {
  briefingSortKey,
  formatKoreanTimeAmPm,
  formatKoreanTimeFromHhmm,
  isAllDayScheduleStart,
} from './briefing-time.util';

@Injectable()
export class BriefingService {
  constructor(
    private readonly scheduleService: ScheduleService,
    private readonly todoService: TodoService,
    private readonly routineService: RoutineService,
  ) {}

  async getTodayBriefing(
    userId: number,
    dateYmd: string = todayYmdKst(),
  ): Promise<TodayBriefingResponseDto> {
    const [
      upcomingSchedules,
      completedSchedules,
      upcomingTodos,
      completedTodos,
      upcomingRoutines,
      completedRoutines,
    ] = await Promise.all([
      this.scheduleService.findUpcomingForBriefingToday(userId, dateYmd),
      this.scheduleService.findCompletedTodayForBriefing(userId, dateYmd),
      this.todoService.findUpcomingForBriefingToday(userId, dateYmd),
      this.todoService.findCompletedTodayForBriefing(userId, dateYmd),
      this.routineService.findUpcomingForBriefingToday(userId, dateYmd),
      this.routineService.findCompletedTodayForBriefing(userId, dateYmd),
    ]);

    const upcoming: BriefingItemDto[] = [
      ...upcomingSchedules.map((s) => this.mapScheduleUpcoming(s)),
      ...upcomingTodos.map((t) => this.mapTodoUpcoming(t, dateYmd)),
      ...upcomingRoutines.map((r) => this.mapRoutineUpcoming(r, dateYmd)),
    ];

    const completedToday: BriefingItemDto[] = [
      ...completedSchedules.map((s) => this.mapScheduleCompleted(s)),
      ...completedTodos.map((t) => this.mapTodoCompleted(t)),
      ...completedRoutines.map((r) => this.mapRoutineCompleted(r, dateYmd)),
    ];

    upcoming.sort((a, b) =>
      briefingSortKey(a.time).localeCompare(briefingSortKey(b.time)),
    );
    completedToday.sort((a, b) =>
      (a.completedAt ?? '').localeCompare(b.completedAt ?? ''),
    );

    return { date: dateYmd, upcoming, completedToday };
  }

  private mapScheduleUpcoming(row: Schedule): BriefingItemDto {
    const allDay = isAllDayScheduleStart(row.startDate);
    const time = allDay
      ? '하루 종일'
      : formatKoreanTimeAmPm(row.startDate);
    return {
      type: 'schedule',
      id: row.id,
      title: row.title,
      subTitle: '일정',
      time,
      sortKey: briefingSortKey(time),
    };
  }

  private mapScheduleCompleted(row: Schedule): BriefingItemDto {
    const allDay = isAllDayScheduleStart(row.startDate);
    const time = allDay
      ? '하루 종일'
      : formatKoreanTimeAmPm(row.startDate);
    return {
      type: 'schedule',
      id: row.id,
      title: row.title,
      subTitle: '일정',
      time,
      sortKey: briefingSortKey(time),
      completedAt: row.completedAt?.toISOString() ?? null,
    };
  }

  private mapTodoUpcoming(todo: Todo, dateYmd: string): BriefingItemDto {
    const dueYmd = todo.dueDate ?? dateYmd;
    const dt = kstDateTime(dueYmd, '12:00');
    const time = formatKoreanTimeAmPm(dt);
    return {
      type: 'todo',
      id: todo.id,
      title: todo.title,
      subTitle: 'TO-DO',
      time,
      sortKey: briefingSortKey(time),
    };
  }

  private mapTodoCompleted(todo: Todo): BriefingItemDto {
    const completed = todo.completedAt ?? new Date();
    const time = formatKoreanTimeAmPm(completed);
    return {
      type: 'todo',
      id: todo.id,
      title: todo.title,
      subTitle: 'TO-DO',
      time,
      sortKey: briefingSortKey(time),
      completedAt: todo.completedAt?.toISOString() ?? null,
    };
  }

  private mapRoutineUpcoming(routine: Routine, dateYmd: string): BriefingItemDto {
    const time = formatKoreanTimeFromHhmm(routine.targetTime, dateYmd);
    return {
      type: 'routine',
      id: routine.id,
      title: `${routine.category} - ${routine.title}`,
      subTitle: '루틴',
      time,
      sortKey: briefingSortKey(time),
    };
  }

  private mapRoutineCompleted(
    routine: Routine,
    dateYmd: string,
  ): BriefingItemDto {
    const time = formatKoreanTimeFromHhmm(routine.targetTime, dateYmd);
    return {
      type: 'routine',
      id: routine.id,
      title: `${routine.category} - ${routine.title}`,
      subTitle: '루틴',
      time,
      sortKey: briefingSortKey(time),
      completedAt: `${dateYmd}T${routine.targetTime.slice(0, 5)}:00+09:00`,
    };
  }
}
