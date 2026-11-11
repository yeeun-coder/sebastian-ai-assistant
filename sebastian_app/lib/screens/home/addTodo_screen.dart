import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/common/custom_calendar.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';

class AddTodoScreen extends StatefulWidget {
  final Map<String, dynamic>? todo;

  const AddTodoScreen({
    super.key,
    this.todo,
  });

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  // 제목 입력
  final titleController = TextEditingController();

  // 시간 토글
  bool isTimeEnabled = false;

  // 선택된 날짜 (기본값: 오늘)
  DateTime selectedDate = DateTime.now();

  // 선택된 시간 (기본값)
  TimeOfDay selectedTime = TimeOfDay.now();

  // 달력에서 날짜를 한 번 선택했는지 여부
  bool isStartDateSelected = false;

  // 날짜+시간을 합친 DateTime (시간 선택용)
  DateTime selectedDateTime = DateTime.now();

  // 알림 옵션
  String selectedAlarm = '없음';
    final List<String> alarmOptions = [
    '없음',
    '10분 전',
    '30분 전',
    '1시간 전',
    '1일 전',
    '2일 전',
    '3일 전',
  ];
  int convertAlarmToDays(String alarm) {
    switch (alarm) {
      case '10분 전': return 0;
      case '30분 전': return 0;
      case '1시간 전': return 0;
      case '1일 전': return 1;
      case '2일 전': return 2;
      case '3일 전': return 3;
      default: return 0;
    }
  }

  // ScheduleController 가져오기(TodoController말고 scheduleController안에 만듦)
  final controller = Get.find<ScheduleController>();

  // AddScheduleScreen과 동일한 CupertinoDatePicker 방식
  void _showDateTimePicker(DateTime initial, ValueChanged<DateTime> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Container(
          height: 250,
          color: Colors.white,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            use24hFormat: false,
            initialDateTime: initial,
            onDateTimeChanged: onChanged,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $displayHour:$minute';
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Column(
      children: [
        // 자세한 UI는 Figma 참고해서 만들어주시면 될 것 같아요!
        // 시간이랑 날짜 선택하는 부분은 그래로 가져오는데
        // 1. 시간 선택에 하루 종일은 필요 없을 것 같아서 제거
        // 2. 밑에 시작 text 대신 시간이라고 바꿔주면 될 것 같아요
        // 3. 종료 대신 알림으로 바꾸고 날짜는 X 시간도 X
        //    그대신 몇 일 전이지(드롭다운으로 선택) - 종류: 10분 전, 30분 전, 1시간 전, 1~3일 전

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // 시간 행
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 48,
                      child: Text('시간', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                    // 날짜 칩
                    _buildChip(
                      _formatDate(selectedDateTime),
                      () => _showDateTimePicker(selectedDateTime, (dt) {
                        setState(() {
                          selectedDateTime = dt;
                          selectedDate = dt;
                          selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                        });
                      }),
                    ),
                    const SizedBox(width: 8),
                    // 시간 칩
                    _buildChip(
                      _formatTime(selectedDateTime),
                      () => _showDateTimePicker(selectedDateTime, (dt) {
                        setState(() {
                          selectedDateTime = dt;
                          selectedDate = dt;
                          selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                        });
                      }),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              // 알림 행
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('알림', style: TextStyle(fontSize: 16)),
                    // 알림 칩 (시간 칩과 동일한 모양)
                    PopupMenuButton<String>(
                      color: Colors.white,
                      initialValue: selectedAlarm,
                      onSelected: (val) => setState(() => selectedAlarm = val),
                      itemBuilder: (context) => alarmOptions.map((option) {
                        return PopupMenuItem(value: option, child: Text(option));
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(selectedAlarm, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.todo != null) {
      final todo = widget.todo!;

      titleController.text = todo['title'];

      final dt = DateTime.parse(todo['dueDate']);

      selectedDate = dt;
      selectedDateTime = dt;
      selectedTime = TimeOfDay(
        hour: dt.hour,
        minute: dt.minute,
      );

      isTimeEnabled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.todo == null ? '할 일 추가' : '할 일 수정',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 타이틀
                          const Text(
                            'To-Do',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.todo == null ? '할 일을 직접 등록하기' : '할 일을 직접 수정하기',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          // 제목
                          // const Text(
                          //   '제목',
                          //   style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          // ),
                          // const SizedBox(height: 8),
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              hintText: '제목',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 날짜 - addSchedule에서 customCalendar까지 그대로 가져와서 사용
                    Align(
                      alignment: Alignment.center,
                      child: CustomCalendar(
                        controller: controller,
                        onDateSelected: (date) {
                          setState(() {
                            selectedDate = date;
                            // 캘린더에서 날짜 선택 시 selectedDateTime의 날짜도 동기화
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              selectedDateTime.hour,
                              selectedDateTime.minute,
                            );
                          });
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 시간 선택 토글 (ON일 때만 시간 선택 UI 표시)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '시간',
                                style: TextStyle(fontSize: 16),
                              ),
                              Switch(
                                value: isTimeEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    isTimeEnabled = value;
                                  });
                                },
                                activeColor: Colors.white,
                                activeTrackColor: Colors.black,
                              ),
                            ],
                          ),

                          if (isTimeEnabled) ...[
                            const SizedBox(height: 8),
                            _buildTimeSection(),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 버튼도 addSchedule에서 그대로 가져와서 사용하시면 될 것 같아요!
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: ()  async {
                    /// 1. 제목 입력값 가져오기
                    final title = titleController.text;
                    final leadDays = convertAlarmToDays(selectedAlarm);

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("제목을 입력하세요"),
                        ),
                      );
                      return;
                    }

                    // 2. 날짜 + 시간 합치기
                    DateTime finalDateTime;

                    if (isTimeEnabled) {
                      finalDateTime = DateTime(
                        selectedDateTime.year,
                        selectedDateTime.month,
                        selectedDateTime.day,
                        selectedDateTime.hour,
                        selectedDateTime.minute,
                      );
                    } else {
                      // 시간 OFF → 날짜만 (00:00)
                      finalDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                      );
                    }

                    if (widget.todo == null) {
                      await controller.addTodo(
                        title,
                        finalDateTime,
                        leadDays,
                      );
                    } else {
                      await controller.editTodo(
                        widget.todo!['id'],
                        title,
                        finalDateTime,
                        leadDays,
                      );
                    }

                    /// 이전 화면으로 돌아가기
                    Get.back();
                  },
                  child: Text(
                    widget.todo == null ? '추가하기' : '수정하기',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
