import 'dart:math';

import 'package:flutter/material.dart';
import 'package:readlog/utils.dart';

class BarChartData {
  final Widget label;
  final int value;
  final String tooltip;

  const BarChartData({
    required this.label,
    required this.value,
    required this.tooltip,
  });
}

class BarChartItem extends StatelessWidget {
  final BarChartData data;
  final double height;
  final int maxValue;

  const BarChartItem({
    super.key,
    required this.data,
    required this.height,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        Tooltip(
          triggerMode: TooltipTriggerMode.tap,
          message: data.tooltip,
          child: SizedBox(
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4))),
                  width: 16,
                  height:
                      height * (data.value.toDouble() / maxValue.toDouble()),
                  duration: const Duration(milliseconds: 500),
                  curve: Easing.standard,
                ),
              ],
            ),
          ),
        ),
        data.label,
      ],
    );
  }
}

class BarChart extends StatelessWidget {
  final double height;
  final List<BarChartData> data;

  const BarChart({
    super.key,
    required this.data,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    var maxValue = data.fold(0, (prev, el) => max(prev, el.value));
    if (maxValue == 0) maxValue = 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data
          .map((item) =>
              BarChartItem(data: item, height: height, maxValue: maxValue))
          .toList(),
    );
  }
}
