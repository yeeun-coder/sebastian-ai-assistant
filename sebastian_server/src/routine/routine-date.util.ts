import { Routine } from './routine.entity';
import { RoutineRepeatInterval } from './routine-repeat-interval.enum';

const KO_DAY_TO_CODE: Record<string, string> = {
  월: 'MON',
  화: 'TUE',
  수: 'WED',
  목: 'THU',
  금: 'FRI',
  토: 'SAT',
  일: 'SUN',
};

const LONG_EN_TO_CODE: Record<string, string> = {
  MONDAY: 'MON',
  TUESDAY: 'TUE',
  WEDNESDAY: 'WED',
  THURSDAY: 'THU',
  FRIDAY: 'FRI',
  SATURDAY: 'SAT',
  SUNDAY: 'SUN',
};

function weekdayCodeFromYmd(dateYmd: string): string {
  const d = new Date(`${dateYmd}T12:00:00+09:00`);
  const day = d.getUTCDay();
  const map: Record<number, string> = {
    0: 'SUN',
    1: 'MON',
    2: 'TUE',
    3: 'WED',
    4: 'THU',
    5: 'FRI',
    6: 'SAT',
  };
  return map[day] ?? 'MON';
}

function repeatDayTokenToCode(raw: string): string {
  const t = raw.trim();
  if (!t) return '';
  if (KO_DAY_TO_CODE[t]) return KO_DAY_TO_CODE[t];
  const u = t.toUpperCase();
  if (LONG_EN_TO_CODE[u]) return LONG_EN_TO_CODE[u];
  if (u.length === 3) return u;
  return u;
}

function parseYmdParts(dateYmd: string): { y: number; m: number; d: number } | null {
  const p = dateYmd.split('-');
  if (p.length !== 3) return null;
  const y = Number(p[0]);
  const m = Number(p[1]);
  const d = Number(p[2]);
  if (!Number.isFinite(y) || !Number.isFinite(m) || !Number.isFinite(d)) {
    return null;
  }
  return { y, m, d };
}

function matchesWeekly(routine: Routine, dateYmd: string): boolean {
  const raw = routine.repeatDays ?? '';
  const parts = raw.split(/[,，、\s]+/);
  const days = new Set<string>();
  for (const p of parts) {
    const code = repeatDayTokenToCode(p);
    if (code) days.add(code);
  }
  if (days.size === 0) return true;
  return days.has(weekdayCodeFromYmd(dateYmd));
}

function matchesBiweekly(routine: Routine, dateYmd: string): boolean {
  if (!matchesWeekly(routine, dateYmd)) return false;
  const anchorStr = routine.biweeklyAnchorDate?.trim();
  if (!anchorStr) return true;
  const anchor = parseYmdParts(anchorStr);
  const target = parseYmdParts(dateYmd);
  if (!anchor || !target) return true;
  const anchorMs = Date.UTC(anchor.y, anchor.m - 1, anchor.d);
  const targetMs = Date.UTC(target.y, target.m - 1, target.d);
  const weekDiff = Math.floor((targetMs - anchorMs) / (7 * 24 * 60 * 60 * 1000));
  return weekDiff % 2 === 0;
}

/** 앱 RoutineController.matchesDate 와 동일 규칙 (dateYmd: YYYY-MM-DD, KST 달력) */
export function routineMatchesDate(
  routine: Routine,
  dateYmd: string,
): boolean {
  if (!routine.isActive) return false;
  const parts = parseYmdParts(dateYmd);
  if (!parts) return false;

  const interval = (
    routine.repeatInterval ?? RoutineRepeatInterval.WEEKLY
  ).toUpperCase();

  switch (interval) {
    case RoutineRepeatInterval.DAILY:
    case 'DAILY':
      return true;
    case RoutineRepeatInterval.WEEKLY:
    case 'WEEKLY':
      return matchesWeekly(routine, dateYmd);
    case RoutineRepeatInterval.BIWEEKLY:
    case 'BIWEEKLY':
      return matchesBiweekly(routine, dateYmd);
    case RoutineRepeatInterval.MONTHLY:
    case 'MONTHLY':
      return routine.repeatDayOfMonth === parts.d;
    case RoutineRepeatInterval.YEARLY:
    case 'YEARLY':
      return (
        routine.repeatMonth === parts.m &&
        routine.repeatDayOfMonth === parts.d
      );
    default:
      return matchesWeekly(routine, dateYmd);
  }
}
