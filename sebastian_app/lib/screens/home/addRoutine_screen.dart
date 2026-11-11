import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:sebastian_app/widgets/routine_controller.dart';
import 'package:sebastian_app/services/routine_service.dart';
import 'package:sebastian_app/models/routine.dart';

class AddRoutineScreen extends StatefulWidget {
  const AddRoutineScreen({super.key});

  @override
  State<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends State<AddRoutineScreen> {
  /// API `category` — 루틴 묶음 이름(상단 '루틴 이름')
  final categoryController = TextEditingController();
  // 시간 입력
  TimeOfDay selectedTime = TimeOfDay.now();

  DateTime selectedDateTime = DateTime.now();
  String repeatType = "WEEKLY"; // DAILY, WEEKLY, MONTHLY, YEARLY, BIWEEKLY

  List<String> selectedDays = []; // WEEKLY
  int? selectedDayOfMonth;        // MONTHLY, YEARLY
  int? selectedMonth;             // YEARLY
  DateTime? biweeklyAnchorDate;   // BIWEEKLY

  // 알림 활성화 여부
  bool isTimeEnabled = false;
  bool isActive = false;

  // 루틴 목록 아이템
  List<TextEditingController> routineItems = [TextEditingController()];

  String formatTime(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $displayHour:$minute';
  }

  List<String> parseDays(String days) {
    const map = {
      "MON": "월",
      "TUE": "화",
      "WED": "수",
      "THU": "목",
      "FRI": "금",
      "SAT": "토",
      "SUN": "일",
    };

    return days
        .split(",")
        .map((d) => d.trim().toUpperCase())
        .where((d) => d.isNotEmpty)
        .map((d) => map[d])
        .whereType<String>()
        .toList();
  }

  String convertDays(List<String> days) {
    const map = {
      "월": "MON",
      "화": "TUE",
      "수": "WED",
      "목": "THU",
      "금": "FRI",
      "토": "SAT",
      "일": "SUN",
    };

    return days.map((d) => map[d]!).join(",");
  }

  /// 알림 ON일 때만 DB 저장 가능. 반복 유형별 필수 입력 검사.
  String? _validateAlarmForSave() {
    if (!isTimeEnabled) {
      return '알림을 켜고 시간·반복을 입력해 주세요.';
    }

    switch (repeatType) {
      case 'DAILY':
        return null;
      case 'WEEKLY':
        if (selectedDays.isEmpty) {
          return '매주 반복할 요일을 선택해 주세요.';
        }
        return null;
      case 'BIWEEKLY':
        if (selectedDays.isEmpty) {
          return '격주 반복할 요일을 선택해 주세요.';
        }
        if (biweeklyAnchorDate == null) {
          return '격주 기준일을 선택해 주세요.';
        }
        return null;
      case 'MONTHLY':
        if (selectedDayOfMonth == null ||
            selectedDayOfMonth! < 1 ||
            selectedDayOfMonth! > 31) {
          return '매월 반복할 날짜(1~31)를 입력해 주세요.';
        }
        return null;
      case 'YEARLY':
        if (selectedMonth == null ||
            selectedMonth! < 1 ||
            selectedMonth! > 12 ||
            selectedDayOfMonth == null ||
            selectedDayOfMonth! < 1 ||
            selectedDayOfMonth! > 31) {
          return '매년 반복할 월·일을 입력해 주세요.';
        }
        return null;
      default:
        return null;
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

  @override
  void dispose() {
    categoryController.dispose();
    for (final c in routineItems) {
      c.dispose();
    }
    super.dispose();
  }

  // 수정
  Routine? editingRoutine;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args != null && args is Routine) {
      editingRoutine = args;

      categoryController.text = args.category;

      // 기존 리스트 초기화 후 1개만 넣기
      routineItems = [TextEditingController(text: args.title)];

      // 시간
      if (args.targetTime != null && args.targetTime.isNotEmpty) {
        final parts = args.targetTime.split(":");
        selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        selectedDateTime = DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        isTimeEnabled = true;
      }

      // 반복
      repeatType = args.repeatInterval ?? "WEEKLY";

      final days = args.repeatDays;

      if (days != null && days.isNotEmpty) {
        selectedDays = parseDays(days);
      }

      selectedDayOfMonth = args.repeatDayOfMonth;
      selectedMonth = args.repeatMonth;

      isActive = args.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editingRoutine == null ? '루틴 추가' : '루틴 수정'),
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
                            '루틴',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            '루틴을 직접 등록하기',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          // 루틴 이름 → API category
                          TextField(
                            controller: categoryController,
                            decoration: InputDecoration(
                              hintText: '루틴 이름',
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

                          const SizedBox(height: 24),

                          // 알림
                          _buildTimeSection(),

                          const SizedBox(height: 24),

                          // 습관 한 줄 → API title (여러 줄이면 레코드 여러 개)
                          _buildRoutineListSection(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
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
                  onPressed: () async {
                    final category = categoryController.text.trim();
                    final titles = routineItems
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    if (category.isEmpty) {
                      Get.snackbar('오류', '루틴 이름을 입력하세요');
                      return;
                    }
                    if (titles.isEmpty) {
                      Get.snackbar('오류', '루틴 목록에 습관을 하나 이상 입력하세요');
                      return;
                    }

                    final alarmError = _validateAlarmForSave();
                    if (alarmError != null) {
                      Get.snackbar('오류', alarmError);
                      return;
                    }

                    if (editingRoutine != null && titles.length > 1) {
                      Get.snackbar('오류', '수정 시에는 하나의 루틴만 수정할 수 있습니다.');
                      return;
                    }

                    // final base = <String, dynamic>{
                    //   'category': category,
                    //   'targetTime': formatTime(selectedTime),
                    //   'repeatInterval': repeatType,
                    //   'repeatDays': (repeatType == 'WEEKLY' || repeatType == 'BIWEEKLY')
                    //       ? selectedDays.join(',')
                    //       : null,
                    //   'repeatDayOfMonth':
                    //       (repeatType == 'MONTHLY' || repeatType == 'YEARLY')
                    //           ? selectedDayOfMonth
                    //           : null,
                    //   'repeatMonth':
                    //       repeatType == 'YEARLY' ? selectedMonth : null,
                    //   'biweeklyAnchorDate': repeatType == 'BIWEEKLY'
                    //       ? biweeklyAnchorDate?.toIso8601String().split('T')[0]
                    //       : null,
                    //   'isActive': isActive,
                    // };

                    final base = <String, dynamic>{
                      'category': category,
                      'targetTime': formatTime(selectedTime),
                      'repeatInterval': repeatType,
                      'isActive': isActive,
                    };

                    if (repeatType == 'WEEKLY' || repeatType == 'BIWEEKLY') {
                      if (selectedDays.isNotEmpty) {
                        base['repeatDays'] = convertDays(selectedDays);
                      }
                    }

                    if (repeatType == 'MONTHLY' || repeatType == 'YEARLY') {
                      base['repeatDayOfMonth'] = selectedDayOfMonth;
                    }

                    if (repeatType == 'YEARLY') {
                      base['repeatMonth'] = selectedMonth;
                    }

                    if (repeatType == 'BIWEEKLY') {
                      base['biweeklyAnchorDate'] =
                          biweeklyAnchorDate?.toIso8601String().split('T')[0];
                    }

                    try {
                      if (editingRoutine == null) {
                        // 신규
                        for (final title in titles) {
                          await RoutineService.createRoutine({
                            ...base,
                            'title': title,
                          });
                        }
                      } else {
                        // 기존 것 수정
                        await RoutineService.updateRoutine(
                          editingRoutine!.id,
                          {
                            ...base,
                            'title': titles.first,
                          },
                        );

                        // 나머지는 새로 추가
                        if (titles.length > 1) {
                          for (int i = 1; i < titles.length; i++) {
                            await RoutineService.createRoutine({
                              ...base,
                              'title': titles[i],
                            });
                          }
                        }
                      }

                      await Get.find<RoutineController>().fetch();
                      if (context.mounted) Get.back();

                    } catch (e) {
                      Get.snackbar('오류', e.toString());
                    }
                  },
                  child: Text(
                    editingRoutine == null ? '추가 하기' : '수정 하기',
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

  // 반복
  Widget buildDaySelector() {
    final days = ["월", "화", "수", "목", "금", "토", "일"];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: days.map((day) {
          final isSelected = selectedDays.contains(day);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedDays.remove(day);
                } else {
                  selectedDays.add(day);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                day,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRepeatDetail() {
    switch (repeatType) {
      case "DAILY":
        return const Text("매일 반복");

      case "WEEKLY":
        return buildDaySelector();

      case "MONTHLY":
        return TextField(
          decoration: InputDecoration(
            hintText: "매달 날짜 (1~31)",
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            selectedDayOfMonth = int.tryParse(val);
          },
        );

      case "YEARLY":
        return Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: "월 (1~12)"),
                onChanged: (val) {
                  selectedMonth = int.tryParse(val);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: "일 (1~31)"),
                onChanged: (val) {
                  selectedDayOfMonth = int.tryParse(val);
                },
              ),
            ),
          ],
        );

      case "BIWEEKLY":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDaySelector(),
            const SizedBox(height: 12),
            _buildChip(
              biweeklyAnchorDate == null
                  ? "기준일 선택"
                  : "${biweeklyAnchorDate!.toLocal()}".split(' ')[0],
              () => _showDateTimePicker(DateTime.now(), (dt) {
                setState(() {
                  biweeklyAnchorDate = dt;
                });
              }),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildRow({
    required String title,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          trailing,
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // 알림
          _buildRow(
            title: "알림",
            trailing: Switch(
              value: isTimeEnabled,
              onChanged: (value) {
                setState(() {
                  isTimeEnabled = value;
                });
              },
              activeColor: Colors.white,
              activeTrackColor: Colors.black,
            ),
          ),

          if (isTimeEnabled) ...[
            Divider(color: Colors.grey.shade300),

            // 시간
            _buildRow(
              title: "시간",
              trailing: GestureDetector(
                onTap: () => _showDateTimePicker(selectedDateTime, (dt) {
                  setState(() {
                    selectedDateTime = dt;
                    selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  });
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_formatTime(selectedDateTime)),
                ),
              ),
            ),

            Divider(color: Colors.grey.shade300),

            // 반복
            _buildRow(
              title: "반복",
              trailing: DropdownButton<String>(
                value: repeatType,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.black, fontSize: 16),
                items: const [
                  DropdownMenuItem(value: "DAILY", child: Text("매일")),
                  DropdownMenuItem(value: "WEEKLY", child: Text("매주")),
                  DropdownMenuItem(value: "BIWEEKLY", child: Text("격주")),
                  DropdownMenuItem(value: "MONTHLY", child: Text("매월")),
                  DropdownMenuItem(value: "YEARLY", child: Text("매년")),
                ],
                onChanged: (value) {
                  setState(() {
                    repeatType = value!;
                    selectedDays.clear();
                    selectedDayOfMonth = null;
                    selectedMonth = null;
                    biweeklyAnchorDate = null;
                  });
                },
              ),
            ),

            const SizedBox(height: 5),

            // 반복 상세
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildRepeatDetail(),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // 루틴 목록 섹션
  Widget _buildRoutineListSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '루틴 목록',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Divider(color: Colors.grey.shade300),

          // 드래그로 순서 변경 가능한 루틴 아이템 목록
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // 기본 드래그 핸들 대신 커스텀 핸들(= 아이콘)을 사용
            buildDefaultDragHandles: false,
            itemCount: routineItems.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = routineItems.removeAt(oldIndex);
                routineItems.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              return _buildRoutineItem(
                index,
                // key: ValueKey(routineItems[index]),
                key: ValueKey(index),
              );
            },
          ),

          const SizedBox(height: 8),

          // + 추가하기 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                routineItems.add(TextEditingController());
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '+ 추가하기',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(int index, {required Key key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // 번호
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // 습관 목록 작성
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: routineItems[index],
                style: const TextStyle(fontSize: 14),
                textAlignVertical: TextAlignVertical.center,
                maxLines: 1,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 삭제 버튼
          GestureDetector(
            onTap: () {
              if (routineItems.length > 1) {
                setState(() {
                  routineItems[index].dispose();
                  routineItems.removeAt(index);
                });
              }
            },
            child: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 6),

          // 드래그 핸들 - 이 아이콘을 드래그하면 순서가 변경됨
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}