import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:sebastian_app/widgets/common/custom_TextField.dart';
import 'package:sebastian_app/widgets/common/custom_calendar.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';
import 'package:sebastian_app/widgets/common/custom_button.dart';

class AddScheduleScreen extends StatefulWidget {
  final ScheduleItem? schedule;

  const AddScheduleScreen({
    super.key,
    this.schedule,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  // 제목 입력
  final titleController = TextEditingController();

  // 내용 입력
  final contentController = TextEditingController();

  // 시간 선택 여부 (토글)
  bool isTimeEnabled = false;

  // 선택된 날짜 (기본값: 오늘)
  DateTime selectedDate = DateTime.now();

  // 선택된 시간 (기본값)
  TimeOfDay selectedTime = TimeOfDay.now();

  // 시작 날짜/시간
  DateTime startDateTime = DateTime.now();

  // 종료 날짜/시간
  DateTime endDateTime = DateTime.now();

  // 달력에서 날짜를 한 번 선택했는지 여부
  bool isStartDateSelected = false;

  // 중요! 체크 여부
  bool isImportant = false;

  // D-Day 설정 여부
  bool isDdayEnabled = false;
  String ddayBasis = 'start';

  // ScheduleController 가져오기
  final controller = Get.find<ScheduleController>();

  @override
  void initState() {
    super.initState();

    if (widget.schedule != null) {

      final s = widget.schedule!;

      titleController.text = s.title;
      contentController.text = s.content;

      startDateTime = s.dateTime;

      endDateTime = s.endDateTime ?? s.dateTime;

      isTimeEnabled = s.isAllDay;
      isImportant = s.isImportant;

      isDdayEnabled = s.createDday;
      ddayBasis = s.ddayBasis ?? 'start';
    }
  }

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

  Widget _dateTimeChip(String label, VoidCallback onTap) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.schedule == null
              ? '일정 추가'
              : '일정 수정',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 최상단 제목 및 안내 문구
                    const Text(
                      '달력',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.schedule == null ? '일정을 직접 등록하기' : '일정을 직접 수정하기',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: titleController,
                      type: TextFieldType.box,
                      hintText: '제목',
                    ),
                  ],
                ),
              ),
            
              Align(
                alignment: Alignment.center,
                child: CustomCalendar(
                  controller: controller,
                  onDateSelected: (date) {
                    setState(() {
                      selectedDate = date;
                      if (!isStartDateSelected) {
                        // 첫 번째 클릭: 시작일 설정
                        startDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          startDateTime.hour,
                          startDateTime.minute,
                        );
                        isStartDateSelected = true;
                      } else {
                        // 두 번째 클릭: 종료일 설정
                        endDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          endDateTime.hour,
                          endDateTime.minute,
                        );
                        isStartDateSelected = false;
                      }
                    });
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 5),
                child: Column(
                  children: [
                    // 시간 하는 자리
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('하루 종일', style: TextStyle(fontSize: 16)),
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
                          ),
                          Divider(height: 1, color: Colors.grey.shade300),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 48,
                                  child: Text('시작', style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                _dateTimeChip(_formatDate(startDateTime), () {
                                  _showDateTimePicker(startDateTime, (dt) {
                                    setState(() => startDateTime = dt);
                                  });
                                }),
                                const SizedBox(width: 8),
                                // 하루 종일 OFF일 때만 시간 칩 표시
                                if (!isTimeEnabled)
                                  _dateTimeChip(_formatTime(startDateTime), () {
                                    _showDateTimePicker(startDateTime, (dt) {
                                      setState(() => startDateTime = dt);
                                    });
                                  }),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade300),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 48,
                                  child: Text('종료', style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                _dateTimeChip(_formatDate(endDateTime), () {
                                  _showDateTimePicker(endDateTime, (dt) {
                                    setState(() => endDateTime = dt);
                                  });
                                }),
                                const SizedBox(width: 8),
                                // 하루 종일 OFF일 때만 시간 칩 표시
                                if (!isTimeEnabled)
                                  _dateTimeChip(_formatTime(endDateTime), () {
                                    _showDateTimePicker(endDateTime, (dt) {
                                      setState(() => endDateTime = dt);
                                    });
                                  }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [

                          // 상단 스위치
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'D-Day',
                                  style: TextStyle(fontSize: 16),
                                ),

                                Switch(
                                  value: isDdayEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      isDdayEnabled = value;
                                    });
                                  },
                                  activeColor: Colors.white,
                                  activeTrackColor: Colors.black,
                                ),
                              ],
                            ),
                          ),

                          // ON일 때만 펼쳐짐
                          if (isDdayEnabled) ...[
                            Divider(height: 1, color: Colors.grey.shade300),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),

                              child: Column(
                                children: [

                                  RadioListTile<String>(
                                    value: 'start',
                                    groupValue: ddayBasis,

                                    title: const Text('시작 날짜 기준'),

                                    onChanged: (value) {
                                      setState(() {
                                        ddayBasis = value!;
                                      });
                                    },
                                  ),

                                  RadioListTile<String>(
                                    value: 'end',
                                    groupValue: ddayBasis,

                                    title: const Text('종료 날짜 기준'),

                                    onChanged: (value) {
                                      setState(() {
                                        ddayBasis = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 중요! 체크
                    InkWell(
                      onTap: () => setState(() => isImportant = !isImportant),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isImportant
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 22,
                                  color: isImportant
                                      ? Colors.amber.shade700
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '중요!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Checkbox(
                              value: isImportant,
                              onChanged: (v) =>
                                  setState(() => isImportant = v ?? false),
                              activeColor: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 내용 입력도 추가하는게 좋을 것 같아서 넣어봄
                    CustomTextField(
                      controller: contentController,
                      type: TextFieldType.box,
                      hintText: '내용',
                      maxLines: 7,
                      minLines: 7,
                    ),

                    const SizedBox(height: 30),

                    CustomButton(
                      label: widget.schedule == null
                        ? "추가하기"
                        : "수정하기",
                      variant: CustomButtonVariant.darkLong,
                      expandWidth: true,
                      height: 45,

                      // 저장 버튼 눌렀을 때 해야 할 일
                      onPressed: () {
                        /// 1. 제목 입력값 가져오기
                        final title = titleController.text;
                        final content = contentController.text;

                        if (title.isEmpty) {
                          Get.snackbar("오류", "제목을 입력하세요");
                          return;
                        }

                        // // 2. 날짜 + 시간 합치기
                        // final dateTime = DateTime(
                        //   selectedDate.year,
                        //   selectedDate.month,
                        //   selectedDate.day,
                        //   isTimeEnabled ? selectedTime.hour : 0,
                        //   isTimeEnabled ? selectedTime.minute : 0,
                        // );
                        DateTime finalDateTime;
                        if (isTimeEnabled) {
                          // 하루 종일인 경우 시간만 00:00으로 초기화
                          finalDateTime = DateTime(
                            startDateTime.year,
                            startDateTime.month,
                            startDateTime.day,
                            0, 0, 0
                          );
                        } else {
                          // 시간을 설정한 경우 startDateTime 그대로 사용
                          finalDateTime = startDateTime;
                        }

                        DateTime finalEndDateTime = endDateTime;
                        if (finalEndDateTime.isBefore(finalDateTime)) {
                          finalEndDateTime = finalDateTime;
                        }

                        // 3. ScheduleItem 생성
                        final newItem = ScheduleItem(
                          id: widget.schedule?.id
                              ?? DateTime.now().toString(),
                          title: title,
                          dateTime: finalDateTime, // 시작 시간
                          endDateTime: finalEndDateTime, // 종료 시간
                          icon: Icons.event,
                          content: content,
                          isAllDay: isTimeEnabled, // true = 하루 종일
                          isImportant: isImportant,
                          createDday: isDdayEnabled,
                          ddayBasis: ddayBasis,
                        );

                        /// 4. 컨트롤러에 추가
                        if (widget.schedule == null) {
                          controller.addScheduleToDB(newItem);
                        } else {
                          controller.updateSchedule(
                            widget.schedule!.id,
                            newItem,
                          );
                        }

                        /// 5. 이전 화면으로 돌아가기
                        // Get.back();
                        // Get.back();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}