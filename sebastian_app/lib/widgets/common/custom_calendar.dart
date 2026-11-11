import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/widgets/schedule_controller.dart';

class CustomCalendar extends StatefulWidget {
  const CustomCalendar({super.key, required this.controller, this.onDateSelected});

  final ScheduleController controller;
  final Function(DateTime)? onDateSelected;

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime currentDate = DateTime.now();
  DateTime? selectedDate;
  Worker? _eventsWorker;

  final List<String> weekDays = ["일", "월", "화", "수", "목", "금", "토"];

  @override
  void initState() {
    super.initState();
    _eventsWorker = ever(widget.controller.events, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _eventsWorker?.dispose();
    super.dispose();
  }

  int getStartWeekday(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int getDaysInPrevMonth(DateTime date) {
    return DateTime(date.year, date.month, 0).day;
  }

  void _prevMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final startWeekday = getStartWeekday(currentDate);
    final daysInMonth = getDaysInMonth(currentDate);
    final prevMonthDays = getDaysInPrevMonth(currentDate);

    List<DateTime> calendarDays = [];

    for (int i = startWeekday - 1; i >= 0; i--) {
      calendarDays.add(
        DateTime(currentDate.year, currentDate.month - 1, prevMonthDays - i),
      );
    }

    for (int i = 1; i <= daysInMonth; i++) {
      calendarDays.add(
        DateTime(currentDate.year, currentDate.month, i),
      );
    }

    while (calendarDays.length % 7 != 0) {
      calendarDays.add(
        DateTime(currentDate.year, currentDate.month + 1,
            calendarDays.length - (startWeekday + daysInMonth) + 1),
      );
    }

    return Container(
      width: 320,
      margin: const EdgeInsets.all(30),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFD9D9D9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Row(
                  children: [
                    _buildYearDropdown(),
                    const SizedBox(width: 10),
                    _buildMonthDropdown(),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: SizedBox(
              height: 24,
              child: Row(
                children: weekDays.map((d) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 3),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: calendarDays.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final date = calendarDays[index];
                final isCurrentMonth = date.month == currentDate.month;

                final isSelected = selectedDate != null &&
                    date.year == selectedDate!.year &&
                    date.month == selectedDate!.month &&
                    date.day == selectedDate!.day;

                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                final hasSchedule =
                    widget.controller.getSchedules(date).isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                    widget.controller.onDaySelected(date, date);
                    if (widget.onDateSelected != null) {
                      widget.onDateSelected!(date);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2C2C2C)
                          : isToday
                              ? Colors.grey.shade300
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${date.day}",
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Colors.white
                                : isCurrentMonth
                                    ? Colors.black
                                    : Colors.grey.shade400,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (hasSchedule)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white54
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 5),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    return PopupMenuButton<int>(
      initialValue: currentDate.year,
      color: Colors.white,
      onSelected: (int year) {
        setState(() {
          currentDate = DateTime(year, currentDate.month);
        });
      },
      itemBuilder: (BuildContext context) {
        return List.generate(10, (index) {
          int year = DateTime.now().year - 5 + index;
          return PopupMenuItem<int>(
            value: year,
            child: Text('$year'),
          );
        });
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${currentDate.year}",
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.keyboard_arrow_down_sharp, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    final months = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

    return PopupMenuButton<int>(
      initialValue: currentDate.month,
      color: Colors.white,
      onSelected: (int month) {
        setState(() {
          currentDate = DateTime(currentDate.year, month);
        });
      },
      itemBuilder: (BuildContext context) {
        return List.generate(12, (index) {
          return PopupMenuItem<int>(
            value: index + 1,
            child: Text(months[index]),
          );
        });
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${currentDate.month}월",
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.keyboard_arrow_down_sharp, size: 18),
          ],
        ),
      ),
    );
  }
}