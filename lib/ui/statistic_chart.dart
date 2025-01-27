import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readlog/ui/component/week_scroll_picker.dart';
import 'package:readlog/utils.dart';

class ChartStatistic extends StatefulWidget {
  const ChartStatistic({super.key});

  @override
  State<ChartStatistic> createState() => _ChartStatistic();
}

class _ChartStatistic extends State<ChartStatistic> {
  static final _monthNames = DateFormat().dateSymbols.MONTHS;
  WeekDate _week = WeekDate.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 8,
          children: [
            IconButton(
              onPressed: _week.getPrevious().year < 1970
                  ? null
                  : () {
                      setState(() {
                        _week = _week.getPrevious();
                      });
                    },
              icon: const Icon(Icons.keyboard_arrow_left),
            ),
            Spacer(),
            Text(
              "Week ${_week.week}, ${_monthNames[_week.month - 1]}, ${_week.year}",
              style: TextTheme.of(context).bodyLarge,
            ),
            IconButton(
                onPressed: () async {
                  final result = await WeekScrollPickerDialog.show(
                    context: context,
                    initial: _week,
                  );
                  if (result == null || !context.mounted) return;
                  setState(() {
                    _week = result;
                  });
                },
                icon: const Icon(Icons.arrow_drop_down_sharp)),
            Spacer(),
            IconButton(
              onPressed:
                  _week.getNext().getFirstDateTime().isAfter(DateTime.now())
                      ? null
                      : () {
                          setState(() {
                            _week = _week.getNext();
                          });
                        },
              icon: const Icon(Icons.keyboard_arrow_right),
            ),
          ],
        )
      ],
    );
  }
}
