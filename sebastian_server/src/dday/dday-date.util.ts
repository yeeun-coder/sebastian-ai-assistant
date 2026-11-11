import { DDayCountMode } from './dday-count-mode.enum';

export function todayYmd(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function parseYmd(ymd: string): Date {
  const [y, m, d] = ymd.split('-').map(Number);
  return new Date(y, m - 1, d);
}

function daysBetween(fromYmd: string, toYmd: string): number {
  const from = parseYmd(fromYmd);
  const to = parseYmd(toYmd);
  const ms = to.getTime() - from.getTime();
  return Math.round(ms / (24 * 60 * 60 * 1000));
}

export function computeDDayMetrics(
  targetDate: string,
  countMode: DDayCountMode,
  referenceDate: string = todayYmd(),
): { daysLeft: number; label: string } {
  let diff: number;

  if (countMode === DDayCountMode.UP) {
    diff = daysBetween(targetDate, referenceDate);
  } else {
    diff = daysBetween(referenceDate, targetDate);
  }

  if (diff === 0) {
    return { daysLeft: 0, label: 'D-Day' };
  }

  if (countMode === DDayCountMode.UP) {
    if (diff > 0) {
      return { daysLeft: diff, label: `D+${diff}` };
    }
    const remaining = Math.abs(diff);
    return { daysLeft: -remaining, label: `D-${remaining}` };
  }

  if (diff > 0) {
    return { daysLeft: diff, label: `D-${diff}` };
  }

  const passed = Math.abs(diff);
  return { daysLeft: -passed, label: `D+${passed}` };
}
