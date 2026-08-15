import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime) onDaySelected;
  final bool Function(DateTime) hasRecordings;

  const CalendarWidget({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.onDaySelected,
    required this.hasRecordings,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;
  bool _isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.focusedDay.year, widget.focusedDay.month);
    initializeDateFormatting('pt_BR', null).then((_) {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildDaysOfWeek(),
              const SizedBox(height: 4),
              _buildCalendarGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy', 'pt_BR').format(_currentMonth).toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final int firstWeekday = firstDayOfMonth.weekday % 7;

    final List<Widget> dayWidgets = [];

    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final isSelected = widget.selectedDay != null &&
          DateUtils.isSameDay(date, widget.selectedDay);
      final isToday = DateUtils.isSameDay(date, DateTime.now());
      final hasData = widget.hasRecordings(date);
      final isFuture = date.isAfter(DateTime.now());

      dayWidgets.add(
        GestureDetector(
          onTap: isFuture ? null : () => widget.onDaySelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF089bfe)
                  : (hasData
                      ? const Color(0xFF089bfe).withValues(alpha: 0.2)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
              border: isToday && !isSelected
                  ? Border.all(color: const Color(0xFF089bfe), width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isFuture ? Colors.grey[300] : Colors.black87),
                  fontWeight:
                      (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.2,
      children: dayWidgets,
    );
  }
}
