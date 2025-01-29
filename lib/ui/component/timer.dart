import 'dart:async';

import 'package:flutter/material.dart';
import 'package:readlog/utils/date_time.dart';

class TimerView extends StatefulWidget {
  final bool isStarted;
  final DateTime startTime;

  const TimerView(
      {super.key, required this.isStarted, required this.startTime});

  @override
  State<TimerView> createState() => _TimerView();
}

class _TimerView extends State<TimerView> {
  Timer? _timer;
  String _text = "00:00";

  @override
  void didUpdateWidget(covariant TimerView oldWidget) {
    if (oldWidget.isStarted != widget.isStarted) {
      if (!widget.isStarted) {
        _timer?.cancel();
        setState(() {
          _text = "00:00";
        });
      } else {
        final startTime = widget.startTime;
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          final duration =
          ParsedDuration.fromDuration(DateTime.now().difference(startTime));

          final minuteSecondStr =
              '${duration.minute.toString().padLeft(2, '0')}:${duration.second.toString().padLeft(2, '0')}';

          setState(() {
            if (duration.hour == 0) {
              _text = minuteSecondStr;
            } else {
              _text = '${duration.hour}:$minuteSecondStr';
            }
          });
        });
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: TextTheme.of(context).displayMedium,
    );
  }
}
