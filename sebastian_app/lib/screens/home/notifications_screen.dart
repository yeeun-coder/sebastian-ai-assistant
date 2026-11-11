import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/constants/schedule_notification_constants.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';

class NotificationsScreen extends StatefulWidget {
  //알림 화면
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final ScheduleController _controller;  //일정 컨트롤러

  Future<void> _showLeadMinutesSheet(ScheduleItem item) async {
    await Get.bottomSheet<void>(
      Material(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    '몇 분 전에 알릴까요?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ...kScheduleLeadMinuteOptions.map((minutes) {
                  return ListTile(
                    title: Text(formatScheduleLeadLabel(minutes)),
                    leading: Radio<int>(
                      value: minutes,
                      groupValue: item.notificationLeadMinutes,
                      onChanged: (value) async {
                        if (value == null) return;
                        await _controller.setScheduleNotificationLead(
                          item.id,
                          value,
                        );
                        Get.back<void>();
                      },
                    ),
                    onTap: () async {
                      await _controller.setScheduleNotificationLead(
                        item.id,
                        minutes,
                      );
                      Get.back<void>();
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
    if (mounted) setState(() {});
  }

  @override
  void initState() {  //초기화 함수
    super.initState();
    _controller = Get.find<ScheduleController>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.loadSchedulesFromDB();
    });
  }

  Future<void> _onRefresh() async {  //새로고침 함수
    await _controller.loadSchedulesFromDB();
  }

  @override
  Widget build(BuildContext context) { //알림 화면 빌드
    return Scaffold(  //스크롤 가능한 화면
      backgroundColor: Colors.white,  //배경색
      appBar: AppBar(
        title: const Text(
          '알림',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        final items = _controller.upcomingSchedulesForNotifications();

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    '예정된 일정이 없습니다.\n캘린더에서 일정을 추가해 보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFFEEEEEE),
            ),
            itemBuilder: (context, index) {
              return _buildNotificationItem(items[index]);
            },
          ),
        );
      }),
    );
  }

  /// 알림 카드 부제: 내용(있을 때) + 시작 N분 전 안내.
  String _notificationSubtitle(ScheduleItem item) {
    final body = item.content.trim();
    final tail =
        '일정 시작 ${formatScheduleLeadLabel(item.notificationLeadMinutes)} 알림';
    if (body.isEmpty) return tail;
    return '$body\n$tail';
  }

  Widget _buildNotificationItem(ScheduleItem item) {
    final timeLabel = formatKoreanTimeAmPm(item.dateTime);
    final subtitle = _notificationSubtitle(item);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: const Icon(
          Icons.event,
          color: Colors.black87,
          size: 26,
        ),
        title: Text(
          '$timeLabel  ${item.title}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.35,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '몇 분 전 알림',
              icon: const Icon(Icons.schedule, color: Colors.black54),
              onPressed: () => _showLeadMinutesSheet(item),
            ),
            Transform.scale(
              scale: 0.95,
              child: Switch(
                value: item.isAlarmOn,
                onChanged: (value) {
                  _controller.setScheduleAlarm(item.id, value);
                },
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.black;
                  }
                  return Colors.white;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.grey[300];
                  }
                  return Colors.grey[200];
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';                         // 플러터 기본 UI 도구 가져오기!
import 'package:get/get.dart';                                  // GetX (상태관리, 라우팅 등) 사용!
import 'package:sebastian_app/widgets/common/custom_TextField.dart'; // 커스텀 텍스트필드 (지금은 안쓰지만 일단 가져옴)

class NotificationsScreen extends StatefulWidget {              // 상태 바뀌니까 StatefulWidget 사용!
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final titleController = TextEditingController();               // 텍스트 입력값 관리용 (현재는 안쓰는중)

  bool isNotificationEnabled = true;                             // 알림 ON/OFF 상태 저장 변수

  @override
  Widget build(BuildContext context) {                           // UI 그리는 함수
    return Scaffold(                                             // 기본 화면 틀
      backgroundColor: Colors.white,                           // 전체 배경 흰색으로 깔끔하게~
      appBar: AppBar(
        title: const Text(
          '알림',                                                 // 상단 제목
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,                                       // 제목 가운데 정렬
        backgroundColor: Colors.white,                         // 앱바도? 흰색이시다~
        elevation: 0.5,                                          // 살짝 구분선 느낌만 주기
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),               // 뒤로가기 버튼
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.black, size: 28),
            onPressed: () {
                                                                  // 나중에 편집 기능? 넣을? 자리?가 필요하대요 
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(                                              // 남은 공간 전부 차지
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),  // 위아래 여백
              itemCount: 1,                                      // 지금은 테스트용 1개만!
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFEEEEEE),
              ),                                                 // 아이템 사이 구분선
              itemBuilder: (context, index) {
                return _buildNotificationItem();                 // 알림 하나 생성!
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem() {                              // 알림 하나 UI 만드는 함수!
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),         // 위아래 여백
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20), // 좌우 여백

        leading: const Icon(
          Icons.computer,                                        // 왼쪽 아이콘 (노트북 느낌)
          color: Colors.black,
          size: 26,
        ),

        title: const Text(
          '13:00 프로젝트 회의',                                    // 제목 (시간 + 내용)
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Text(
            '프로젝트 회의 30분 전입니다.',                            // 설명 텍스트
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),

        trailing: Transform.scale(
          scale: 1.0,                                            // 스위치 크기 조절 가능
          child: Switch(
            value: isNotificationEnabled,                        // 현재 상태 반영
            onChanged: (value) {
              setState(() {                                      // 상태 변경하면 UI 다시 그림!
                isNotificationEnabled = value;
              });
              print('알림 상태 변경: $value');                      // 콘솔 확인용
            },
            activeColor: Colors.black,                         // ON일 때 버튼 색
            activeTrackColor: Colors.grey[300],                // ON일 때 배경
            inactiveThumbColor: Colors.white,                  // OFF 버튼 색
            inactiveTrackColor: Colors.grey[200],              // OFF 배경
          ),
        ),
      ),
    );
  }
}
 */
