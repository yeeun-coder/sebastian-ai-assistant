import { kstDateTime } from '../schedule/schedule-datetime.util';

/** Date → 오전/오후 H:mm (KST 표시용) */
export function formatKoreanTimeAmPm(date: Date): string {
  const kst = new Date(
    date.toLocaleString('en-US', { timeZone: 'Asia/Seoul' }),
  );
  const hour = kst.getHours();
  const minute = kst.getMinutes().toString().padStart(2, '0');
  const period = hour < 12 ? '오전' : '오후';
  const displayHour = hour % 12 === 0 ? 12 : hour % 12;
  return `${period} ${displayHour}:${minute}`;
}

/** HH:mm(24h) → 오전/오후 */
export function formatKoreanTimeFromHhmm(hhmm: string, dateYmd: string): string {
  const t = hhmm.trim();
  if (!t.includes(':')) {
    const dt = kstDateTime(dateYmd, t.length <= 2 ? `${t}:00` : t);
    return formatKoreanTimeAmPm(dt);
  }
  const dt = kstDateTime(dateYmd, t.slice(0, 5));
  return formatKoreanTimeAmPm(dt);
}

export function isAllDayScheduleStart(date: Date): boolean {
  const kst = new Date(
    date.toLocaleString('en-US', { timeZone: 'Asia/Seoul' }),
  );
  return kst.getHours() === 0 && kst.getMinutes() === 0;
}

/** 브리핑 목록 정렬용 (하루 종일 → 00:00, 그 외 time 문자열) */
export function briefingSortKey(timeLabel: string): string {
  if (timeLabel === '하루 종일') return '0000';
  return timeLabel;
}
