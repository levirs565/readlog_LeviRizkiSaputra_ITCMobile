import 'package:flutter/material.dart';
import 'package:readlog/ui/statictic_quick.dart';
import 'package:readlog/ui/statistic_chart.dart';

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
          title: Text("Read Log"),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: "Quick",
              ),
              Tab(
                text: "Monthly",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            QuickStatistic(),
            ChartStatistic(),
          ],
        ),
      ),
    );
  }
}
