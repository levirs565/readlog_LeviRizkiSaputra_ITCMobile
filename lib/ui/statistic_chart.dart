import 'package:flutter/material.dart';
import 'package:readlog/ui/component/date_scroll_picker.dart';

class ChartStatistic extends StatefulWidget {
  const ChartStatistic({super.key});

  @override
  State<ChartStatistic> createState() => _ChartStatistic();
}

class _ChartStatistic extends State<ChartStatistic> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _selectedWeek = DateTime.now().day ~/ 7;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      spacing: 16,
      mainAxisSize: MainAxisSize.min,
      children: [
        YearScrollPicker(
          min: 2000,
          max: now.year,
          selected: _selectedYear,
          onSelect: (year) {
            setState(() {
              _selectedYear = year;
            });
          },
        ),
        MonthScrollPicker(
          selected: _selectedMonth,
          onSelect: (month) {
            setState(() {
              _selectedMonth = month;
            });
          },
        ),
        WeekScrollPicker(
          selected: _selectedWeek,
          max: _selectedYear == now.year && _selectedMonth == now.month ? 2 : 4,
          onSelect: (week) {
            setState(() {
              _selectedWeek = week;
            });
          },
        )
      ],
    );
  }
}
