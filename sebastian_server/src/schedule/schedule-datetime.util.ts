/** 일정 파싱·검증용 (기본 타임존: Asia/Seoul) */
export const SCHEDULE_TZ = 'Asia/Seoul';

export function kstStartOfDay(dateYmd: string): Date {
  return new Date(`${dateYmd}T00:00:00+09:00`);
}

export function kstEndOfDay(dateYmd: string): Date {
  return new Date(`${dateYmd}T23:59:59.999+09:00`);
}

export function kstDateTime(dateYmd: string, hhmm: string): Date {
  const t =
    hhmm.length === 5 ? hhmm : `${hhmm.padStart(2, '0')}:00`.slice(0, 5);
  return new Date(`${dateYmd}T${t}:00+09:00`);
}

export function addOneHourKst(d: Date): Date {
  return new Date(d.getTime() + 60 * 60 * 1000);
}

export function todayYmdKst(now = new Date()): string {
  return now.toLocaleDateString('en-CA', { timeZone: SCHEDULE_TZ });
}

/** Date → KST(+09:00) ISO 문자열. AI가 한국 달력 날짜로 인식하도록. */
export function toKstIso(d: Date): string {
  // 'sv-SE' → "2026-06-02 13:30:00"
  return d.toLocaleString('sv-SE', { timeZone: SCHEDULE_TZ }).replace(' ', 'T') + '+09:00';
}
