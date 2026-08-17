import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DatePickerCalendarDialog extends StatefulWidget {
  final String title;
  final DateTime? initialDate;
  final DateTime? initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool isRangeMode;

  const DatePickerCalendarDialog({
    super.key,
    required this.title,
    this.initialDate,
    this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
    this.isRangeMode = false,
  });

  static Future<DateTime?> showSingle({
    required BuildContext context,
    required String title,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final result = await showDialog<_PickerResult>(
      context: context,
      builder: (_) => DatePickerCalendarDialog(
        title: title,
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(2020),
        lastDate: lastDate ?? DateTime.now(),
        isRangeMode: false,
      ),
    );
    return result?.start;
  }

  static Future<({DateTime start, DateTime end})?> showRange({
    required BuildContext context,
    required String title,
    DateTime? initialStart,
    DateTime? initialEnd,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final result = await showDialog<_PickerResult>(
      context: context,
      builder: (_) => DatePickerCalendarDialog(
        title: title,
        initialDate: initialStart,
        initialEndDate: initialEnd,
        firstDate: firstDate ?? DateTime(2020),
        lastDate: lastDate ?? DateTime.now(),
        isRangeMode: true,
      ),
    );
    if (result != null && result.start != null && result.end != null) {
      return (start: result.start!, end: result.end!);
    }
    return null;
  }

  @override
  State<DatePickerCalendarDialog> createState() =>
      _DatePickerCalendarDialogState();
}

class _PickerResult {
  final DateTime? start;
  final DateTime? end;
  _PickerResult({this.start, this.end});
}

class _DatePickerCalendarDialogState extends State<DatePickerCalendarDialog> {
  late DateTime _currentMonth;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;
  bool _isLocaleReady = false;

  @override
  void initState() {
    super.initState();
    _selectedStart = widget.initialDate;
    _selectedEnd = widget.isRangeMode ? widget.initialEndDate : null;
    _currentMonth = DateTime(
      (widget.initialDate ?? DateTime.now()).year,
      (widget.initialDate ?? DateTime.now()).month,
    );
    initializeDateFormatting('pt_BR', null).then((_) {
      if (mounted) setState(() => _isLocaleReady = true);
    });
  }

  void _onDayTap(DateTime date) {
    if (widget.isRangeMode) {
      setState(() {
        if (_selectedStart == null || _selectedEnd != null) {
          _selectedStart = date;
          _selectedEnd = null;
        } else {
          if (date.isBefore(_selectedStart!)) {
            _selectedEnd = _selectedStart;
            _selectedStart = date;
          } else {
            _selectedEnd = date;
          }
        }
      });
    } else {
      Navigator.of(context).pop(_PickerResult(start: date));
    }
  }

  bool _isInRange(DateTime date) {
    if (_selectedStart == null || _selectedEnd == null) return false;
    return date.isAfter(_selectedStart!) && date.isBefore(_selectedEnd!);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLocaleReady
                ? _buildContent()
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (widget.isRangeMode) ...[
          _buildRangeDisplay(),
          const SizedBox(height: 12),
        ],
        _buildMonthHeader(),
        const SizedBox(height: 8),
        _buildDaysOfWeekRow(),
        const SizedBox(height: 4),
        _buildGrid(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            if (widget.isRangeMode) ...[
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _selectedStart != null && _selectedEnd != null
                    ? () => Navigator.of(context).pop(_PickerResult(
                        start: _selectedStart, end: _selectedEnd))
                    : null,
                child: const Text('OK'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRangeDisplay() {
    final fmt = DateFormat('dd/MM/yyyy');
    final startLabel =
        _selectedStart != null ? fmt.format(_selectedStart!) : '--/--/----';
    final endLabel =
        _selectedEnd != null ? fmt.format(_selectedEnd!) : '--/--/----';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(startLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, size: 16),
        ),
        Text(endLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _currentMonth =
              DateTime(_currentMonth.year, _currentMonth.month - 1)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text(
          DateFormat('MMMM yyyy', 'pt_BR').format(_currentMonth),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() => _currentMonth =
              DateTime(_currentMonth.year, _currentMonth.month + 1)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeekRow() {
    const days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 13)),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGrid() {
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    final List<Widget> cells = [];

    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isFuture = date.isAfter(widget.lastDate);
      final isBeforeFirst = date.isBefore(widget.firstDate);
      final isDisabled = isFuture || isBeforeFirst;
      final isToday = _isSameDay(date, DateTime.now());
      final isSelectedStart =
          _selectedStart != null && _isSameDay(date, _selectedStart!);
      final isSelectedEnd =
          _selectedEnd != null && _isSameDay(date, _selectedEnd!);
      final isSelected = isSelectedStart || isSelectedEnd;
      final inRange = _isInRange(date);

      Color bgColor;
      if (isSelected) {
        bgColor = const Color(0xFF089bfe);
      } else if (inRange) {
        bgColor = const Color(0xFF089bfe).withValues(alpha: 0.15);
      } else {
        bgColor = Colors.transparent;
      }

      cells.add(
        GestureDetector(
          onTap: isDisabled ? null : () => _onDayTap(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: isToday && !isSelected
                  ? Border.all(color: const Color(0xFF089bfe), width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDisabled ? Colors.grey[350] : Colors.black87),
                  fontWeight: (isSelected || isToday)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
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
      children: cells,
    );
  }
}
