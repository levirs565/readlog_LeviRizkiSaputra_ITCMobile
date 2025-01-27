import 'package:flutter/material.dart';
import 'package:readlog/ui/statistic_range.dart';
import 'package:readlog/ui/statistic_weekly.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPage();
}

class _StatisticsPage extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("Statistic"),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: "Weekly",
              ),
              Tab(
                text: "Range",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WeeklyStatistic(),
            RangeStatistic(),
          ],
        ),
      ),
    );
  }
}
