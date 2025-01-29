extension ToDateOnly on DateTime {
  DateTime toDateOnly() {
    return DateTime(year, month, day);
  }
}

extension ToUnixTime on DateTime {
  int toUnixSeconds() => millisecondsSinceEpoch ~/ 1000;
}

extension FromUnixTime on int {
  DateTime unixSecondsToDateTime() =>
      DateTime.fromMillisecondsSinceEpoch(this * 1000);
}

extension DayOfWeek on DateTime {
  DateTime getFirstDayOfWeek() {
    final date = toDateOnly();
    final dayShift = 1 - date.weekday;
    return date.add(Duration(days: dayShift));
  }
}

class ParsedDuration {
  int second = 0;
  int minute = 0;
  int hour = 0;

  ParsedDuration.fromSeconds(int seconds) {
    second = seconds % Duration.secondsPerMinute;
    int originalMinute = seconds ~/ Duration.secondsPerMinute;
    minute = originalMinute % Duration.minutesPerHour;
    hour = originalMinute ~/ Duration.minutesPerHour;
  }

  ParsedDuration.fromDuration(Duration duration)
      : this.fromSeconds(duration.inSeconds);

  String toShortFormattedString() {
    var durationStr = minute == 0 && hour == 0
        ? "$second seconds"
        : "$minute minutes";
    if (hour != 0) {
      durationStr = "$hour hour $durationStr";
    }
    return durationStr;
  }
}