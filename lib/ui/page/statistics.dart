import 'package:flutter/material.dart';
import 'package:readlog/ui/page//statistic_custom.dart';
import 'package:readlog/ui/page//statistic_weekly.dart';

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
          title: Text("Statistic"),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: "Weekly",
              ),
              Tab(
                text: "Custom",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            WeeklyStatistic(),
            CustomStatistic(),
          ],
        ),
      ),
    );
  }
}
