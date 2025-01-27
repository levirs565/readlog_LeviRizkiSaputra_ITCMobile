import 'dart:math';

import 'package:flutter/material.dart';
import 'package:readlog/utils.dart';

class BarChartData {
  final String label;
  final int value;
  final String tooltip;

  const BarChartData({
    required this.label,
    required this.value,
    required this.tooltip,
  });
}

class BarChartItem extends StatefulWidget {
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
  State<BarChartItem> createState() => _BarChartItem();
}

class _BarChartItem extends State<BarChartItem> {
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        Tooltip(
          triggerMode: TooltipTriggerMode.tap,
          message: widget.data.tooltip,
          child: SizedBox(
            height: widget.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                  width: 16,
                  height: widget.height *
                      (widget.data.value.toDouble() / widget.maxValue.toDouble()),
                ),
              ],
            ),
          ),
        ),
        Text(widget.data.label),
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
