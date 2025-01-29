import 'package:flutter/material.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/ui/component/conditional_widget.dart';
import 'package:readlog/ui/component/date_time_field.dart';
import 'package:readlog/utils.dart';

class RangeStatistic extends StatefulWidget {
  const RangeStatistic({super.key});

  @override
  State<RangeStatistic> createState() => _RangeStatistic();
}

class _RangeStatistic extends State<RangeStatistic> {
  final ValueNotifier<DateTime?> _fromValueNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> _toValueNotifier = ValueNotifier(null);
  bool _isLoading = false;
  BookReadStatistic? _statistic = null;

  @override
  void initState() {
    _fromValueNotifier.value = DateTime.now();
    _toValueNotifier.value = DateTime.now();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final repository = RepositoryProviderContext.get(context).readHistories;
    final statistic = await repository.getStatistic(
        _fromValueNotifier.value!, _toValueNotifier.value!);

    setState(() {
      _isLoading = false;
      _statistic = statistic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            DateTimeFormField(
              controller: _fromValueNotifier,
              decoration: const InputDecoration(
                label: Text("From Date"),
                border: OutlineInputBorder(),
              ),
              dateOnly: true,
            ),
            DateTimeFormField(
              controller: _toValueNotifier,
              decoration: const InputDecoration(
                  label: Text("To Date"), border: OutlineInputBorder()),
              dateOnly: true,
            ),
            FilledButton(
              onPressed: _isLoading ? null : _refresh,
              child: const Text("Show"),
            ),
            ConditionalWidget(
              isLoading: _isLoading,
              isEmpty: false,
              contentBuilder: _statisticView,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticView(BuildContext context) {
    final duration = ParsedDuration.fromSeconds(_statistic!.seconds);
    final durationStr = duration.toShortFormattedString();

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  durationStr,
                  style: TextTheme.of(context).headlineSmall,
                ),
                Text(
                  "read time",
                  style: TextTheme.of(context).titleMedium,
                )
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "${_statistic!.pages} pages",
                  style: TextTheme.of(context).headlineSmall,
                ),
                Text(
                  "has been read",
                  style: TextTheme.of(context).titleMedium,
                )
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "${_statistic!.books} books",
                  style: TextTheme.of(context).headlineSmall,
                ),
                Text(
                  "has been read",
                  style: TextTheme.of(context).titleMedium,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
