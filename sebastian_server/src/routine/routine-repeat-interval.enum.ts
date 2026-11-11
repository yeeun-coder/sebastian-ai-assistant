/** 루틴 알림 반복 주기 */
export enum RoutineRepeatInterval {
  /** 매일 (추가 필드 없음) */
  DAILY = 'DAILY',
  /** 매주 (repeatDays: MON,TUE,...) */
  WEEKLY = 'WEEKLY',
  /** 격주 (repeatDays + 선택적 biweeklyAnchorDate) */
  BIWEEKLY = 'BIWEEKLY',
  /** 매월 같은 날 (repeatDayOfMonth) */
  MONTHLY = 'MONTHLY',
  /** 매년 같은 월·일 (repeatMonth + repeatDayOfMonth) */
  YEARLY = 'YEARLY',
}
