import 'package:flutter/material.dart';

/// 주간 날짜 바를 아래로 펼치면 같은 영역에서 월 달력으로 확장됩니다.
enum WeekBarStyle {
  /// 선택일 기준 앞뒤 3일(총 7일) — 일기 화면
  centeredOnSelected,

  /// 해당 주 월요일~일요일 — 루틴 화면
  mondayWeek,
}

class ExpandableWeekMonthCalendar extends StatefulWidget {
  const ExpandableWeekMonthCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.hasMarker,
    this.onVisibleMonthChanged,
    this.weekBarStyle = WeekBarStyle.centeredOnSelected,
    this.horizontalPadding = 16,
    this.markerColor = const Color(0xFF4CAF50),
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool Function(DateTime date)? hasMarker;
  final ValueChanged<DateTime>? onVisibleMonthChanged;
  final WeekBarStyle weekBarStyle;
  final double horizontalPadding;
  final Color markerColor;

  @override
  State<ExpandableWeekMonthCalendar> createState() =>
      _ExpandableWeekMonthCalendarState();
}

class _ExpandableWeekMonthCalendarState extends State<ExpandableWeekMonthCalendar> {
  bool _expanded = false;
  late DateTime _visibleMonth;

  static const _weekdayHeader = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  void didUpdateWidget(ExpandableWeekMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_expanded &&
        !_isSameMonth(_visibleMonth, widget.selectedDate)) {
      _visibleMonth =
          DateTime(widget.selectedDate.year, widget.selectedDate.month);
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime _weekStart(DateTime selected) {
    switch (widget.weekBarStyle) {
      case WeekBarStyle.centeredOnSelected:
        return _dateOnly(selected.subtract(const Duration(days: 3)));
      case WeekBarStyle.mondayWeek:
        return _dateOnly(
          selected.subtract(Duration(days: selected.weekday - 1)),
        );
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _visibleMonth = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
        );
        widget.onVisibleMonthChanged?.call(_visibleMonth);
      }
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    widget.onVisibleMonthChanged?.call(_visibleMonth);
  }

  void _selectDate(DateTime date) {
    widget.onDateSelected(_dateOnly(date));
    if (_expanded && !_isSameMonth(_visibleMonth, date)) {
      setState(() {
        _visibleMonth = DateTime(date.year, date.month);
      });
      widget.onVisibleMonthChanged?.call(_visibleMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final selected = _dateOnly(widget.selectedDate);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          final circleSize = (cellWidth * 0.72).clamp(24.0, 34.0);
          final compact = cellWidth < 36;

          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expanded) ...[
                  _buildMonthNav(compact),
                  const SizedBox(height: 4),
                ],
                _buildWeekdayHeaderRow(compact),
                SizedBox(height: compact ? 4 : 6),
                if (_expanded)
                  _buildMonthBody(
                    constraints: constraints,
                    circleSize: circleSize,
                    compact: compact,
                    today: today,
                    selected: selected,
                  )
                else
                  _buildWeekBody(
                    weekStart: _weekStart(selected),
                    circleSize: circleSize,
                    compact: compact,
                    today: today,
                    selected: selected,
                  ),
                GestureDetector(
                  onTap: _toggleExpanded,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthNav(bool compact) {
    return Row(
      children: [
        _navButton(Icons.chevron_left, () => _shiftMonth(-1)),
        Expanded(
          child: Text(
            '${_visibleMonth.year}년 ${_visibleMonth.month}월',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _navButton(Icons.chevron_right, () => _shiftMonth(1)),
      ],
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 18,
      ),
    );
  }

  Widget _buildWeekdayHeaderRow(bool compact) {
    return Row(
      children: _weekdayHeader.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekBody({
    required DateTime weekStart,
    required double circleSize,
    required bool compact,
    required DateTime today,
    required DateTime selected,
  }) {
    return Row(
      children: List.generate(7, (index) {
        final date = _dateOnly(weekStart.add(Duration(days: index)));
        return Expanded(
          child: _buildDayCell(
            date: date,
            circleSize: circleSize,
            compact: compact,
            today: today,
            selected: selected,
            inMonth: true,
          ),
        );
      }),
    );
  }

  Widget _buildMonthBody({
    required BoxConstraints constraints,
    required double circleSize,
    required bool compact,
    required DateTime today,
    required DateTime selected,
  }) {
    final days = _buildMonthDays(_visibleMonth);
    final rowCount = days.length ~/ 7;
    final rowHeight = circleSize + (compact ? 12 : 14);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rowCount, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row < rowCount - 1 ? 4 : 0),
          child: SizedBox(
            height: rowHeight,
            child: Row(
              children: List.generate(7, (col) {
                final date = days[row * 7 + col];
                final inMonth = date.month == _visibleMonth.month;
                return Expanded(
                  child: _buildDayCell(
                    date: date,
                    circleSize: circleSize,
                    compact: compact,
                    today: today,
                    selected: selected,
                    inMonth: inMonth,
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required double circleSize,
    required bool compact,
    required DateTime today,
    required DateTime selected,
    required bool inMonth,
  }) {
    final isToday = date == today;
    final isSelected = date == selected;
    final hasMarker = widget.hasMarker?.call(date) ?? false;
    final dayFontSize = compact ? 12.0 : 14.0;

    return GestureDetector(
      onTap: () => _selectDate(date),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.black : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: Colors.black, width: 1.5)
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: dayFontSize,
                  color: isSelected
                      ? Colors.white
                      : inMonth
                          ? Colors.black
                          : Colors.grey.shade400,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Opacity(
            opacity: hasMarker && inMonth ? 1.0 : 0.0,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.markerColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _buildMonthDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;

    final days = <DateTime>[];

    for (var i = leading; i > 0; i--) {
      days.add(_dateOnly(first.subtract(Duration(days: i))));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      days.add(DateTime(month.year, month.month, d));
    }
    while (days.length % 7 != 0) {
      final last = days.last;
      days.add(_dateOnly(last.add(const Duration(days: 1))));
    }
    return days;
  }
}
