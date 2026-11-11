/// 알림 “몇 분 전” 선택지(분).
const List<int> kScheduleLeadMinuteOptions = [
  5,
  10,
  15,
  20,
  30,
  60,
  120,
  1440,
];

/// 신규 일정·일정별 저장값이 없을 때 쓰는 기본 선행(분).
const int kDefaultScheduleNotificationLeadMinutes = 30;

/// 글로벌 기본(‘알림 시간 설정’ 화면). 일정별로 따로 저장한 값이 없으면 이 값을 씁니다.
int kScheduleNotificationLeadMinutes = kDefaultScheduleNotificationLeadMinutes;

/// UI용 라벨 (예: 30분 전, 2시간 전).
String formatScheduleLeadLabel(int minutes) {
  if (minutes < 60) {
    return '$minutes분 전';
  }
  if (minutes < 1440) {
    final hours = minutes ~/ 60;
    return '$hours시간 전';
  }
  final days = minutes ~/ 1440;
  return '$days일 전';
}
