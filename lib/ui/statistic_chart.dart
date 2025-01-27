import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/ui/component/bar_chart.dart';
import 'package:readlog/ui/component/week_scroll_picker.dart';
import 'package:readlog/utils.dart';

class ChartStatistic extends StatefulWidget {
  const ChartStatistic({super.key});

  @override
  State<ChartStatistic> createState() => _ChartStatistic();
}

class _ChartStatistic extends State<ChartStatistic> {
  static final _dayDateFormat = DateFormat("E");
  static final _monthNames = DateFormat().dateSymbols.MONTHS;
  WeekDate _week = WeekDate.now();
  List<BarChartData> _booksChartData = [];
  List<BarChartData> _pagesChartData = [];
  List<BarChartData> _durationChartData = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    final repository = RepositoryProviderContext.get(context).readHistories;

    List<BarChartData> booksData = [];
    List<BarChartData> pagesData = [];
    List<BarChartData> durationData = [];
    final firstDay = _week.getFirstDateTime();
    final lastDay = _week.getNext().getFirstDateTime(); // exclusive

    for (var day = firstDay.toDateOnly();
        day.isBefore(lastDay);
        day = day.add(Duration(days: 1)).toDateOnly()) {
      final statistic = await repository.getStatistic(day, day);
      final label = _dayDateFormat.format(day);
      booksData.add(BarChartData(
        label: label,
        value: statistic.books,
        tooltip: "${statistic.books} books",
      ));
      pagesData.add(BarChartData(
        label: label,
        value: statistic.pages,
        tooltip: "${statistic.pages} pages",
      ));
      durationData.add(
        BarChartData(
            label: label,
            value: statistic.seconds,
            tooltip: ParsedDuration.fromSeconds(statistic.seconds)
                .toShortFormattedString()),
      );
    }

    setState(() {
      _booksChartData = booksData;
      _pagesChartData = pagesData;
      _durationChartData = durationData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16.0,
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
                        _refresh();
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
                    _refresh();
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
                            _refresh();
                          },
                icon: const Icon(Icons.keyboard_arrow_right),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 16,
                children: [
                  Text(
                    "Books Read",
                    style: TextTheme.of(context).titleLarge,
                  ),
                  BarChart(
                    height: 150,
                    data: _booksChartData,
                  ),
                  Text(
                    "Pages Read",
                    style: TextTheme.of(context).titleLarge,
                  ),
                  BarChart(
                    height: 150,
                    data: _pagesChartData,
                  ),
                  Text(
                    "Read Duration",
                    style: TextTheme.of(context).titleLarge,
                  ),
                  BarChart(
                    height: 150,
                    data: _durationChartData,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
