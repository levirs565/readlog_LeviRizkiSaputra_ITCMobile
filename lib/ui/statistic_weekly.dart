import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/refresh_controller.dart';
import 'package:readlog/ui/component/bar_chart.dart';
import 'package:readlog/utils.dart';

class WeeklyStatistic extends StatefulWidget {
  const WeeklyStatistic({super.key});

  @override
  State<WeeklyStatistic> createState() => _WeeklyStatistic();
}

class _WeeklyStatistic extends State<WeeklyStatistic> {
  static final _dateFormatShort = DateFormat("dd/MM/yyyy");
  static final _dayDateFormat = DateFormat("E");
  static final _dateDateFormat = DateFormat("dd");
  DateTime _firstDay = DateTime.now().getFirstDayOfWeek();
  List<BarChartData> _booksChartData = [];
  List<BarChartData> _pagesChartData = [];
  List<BarChartData> _durationChartData = [];
  late RepositoryProvider _repositoryProvider;
  late final RefreshController _refreshController;

  _WeeklyStatistic() {
    _refreshController = RefreshController(_refresh);
  }

  @override
  void didChangeDependencies() {
    _repositoryProvider = RepositoryProviderContext.get(context);
    _refreshController.init(
      context,
      [
        _repositoryProvider.readHistories,
        _repositoryProvider.books,
      ],
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Widget _label(DateTime day) {
    return Column(
      children: [
        Text(_dateDateFormat.format(day)),
        Text(_dayDateFormat.format(day))
      ],
    );
  }

  _refresh() async {
    final repository = _repositoryProvider.readHistories;

    List<BarChartData> booksData = [];
    List<BarChartData> pagesData = [];
    List<BarChartData> durationData = [];

    for (var i = 0; i < 7; i++) {
      final day = _firstDay.add(Duration(days: i));
      final statistic = await repository.getStatistic(day, day);
      booksData.add(BarChartData(
        label: _label(day),
        value: statistic.books,
        tooltip: "${statistic.books} books",
      ));
      pagesData.add(BarChartData(
        label: _label(day),
        value: statistic.pages,
        tooltip: "${statistic.pages} pages",
      ));
      durationData.add(BarChartData(
        label: _label(day),
        value: statistic.seconds,
        tooltip: ParsedDuration.fromSeconds(statistic.seconds)
            .toShortFormattedString(),
      ));
    }

    setState(() {
      _booksChartData = booksData;
      _pagesChartData = pagesData;
      _durationChartData = durationData;
    });
  }

  _getPrevWeekDateTime() => _firstDay.subtract(Duration(days: 7));

  _getNextWeekDateTime() => _firstDay.add(Duration(days: 7));

  get _lastDay => _firstDay.add(Duration(days: 6));

  _prevWeek() {
    setState(() {
      _firstDay = _getPrevWeekDateTime();
    });
    _refresh();
  }

  _showWeekPicker() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      initialDate: _firstDay,
    );
    if (result == null) return;
    setState(() {
      _firstDay = result.getFirstDayOfWeek();
    });
    _refresh();
  }

  _nextWeek() {
    setState(() {
      _firstDay = _getNextWeekDateTime();
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16.0,
        children: [
          _weekController(context),
          Expanded(
            child: _body(context),
          ),
        ],
      ),
    );
  }

  Widget _weekController(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        IconButton(
          onPressed: _prevWeek,
          icon: const Icon(Icons.keyboard_arrow_left),
        ),
        Spacer(),
        Text(
          "${_dateFormatShort.format(_firstDay)} - ${_dateFormatShort.format(_lastDay)}",
          style: TextTheme.of(context).bodyLarge,
        ),
        IconButton(
          onPressed: _showWeekPicker,
          icon: const Icon(Icons.arrow_drop_down_sharp),
        ),
        Spacer(),
        IconButton(
          onPressed:
              _getNextWeekDateTime().isAfter(DateTime.now()) ? null : _nextWeek,
          icon: const Icon(Icons.keyboard_arrow_right),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }
}
