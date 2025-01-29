import 'package:flutter/material.dart';
import 'package:readlog/data.dart';

class BookReadingProgressItem {
  final bool hasRead;
  final int pageFrom, pageTo;

  const BookReadingProgressItem(
      {required this.hasRead, required this.pageFrom, required this.pageTo});
}

List<BookReadingProgressItem> analyzeBookReadingProgress(
    int pageCount, List<BookReadRangeEntity> ranges) {
  List<BookReadingProgressItem> result = [];

  for (final range in ranges) {
    if (result.isNotEmpty &&
        result.last.hasRead &&
        range.pageFrom == result.last.pageTo + 1) {
      final last = result.last;
      result.last = BookReadingProgressItem(
          hasRead: true, pageFrom: last.pageFrom, pageTo: range.pageTo);
    } else {
      if (result.isEmpty && range.pageFrom > 1) {
        result.add(BookReadingProgressItem(
            hasRead: false, pageFrom: 1, pageTo: range.pageFrom - 1));
      } else if (result.isNotEmpty) {
        result.add(BookReadingProgressItem(
            hasRead: false,
            pageFrom: result.last.pageTo + 1,
            pageTo: range.pageTo - 1));
      }
      result.add(BookReadingProgressItem(
          hasRead: true, pageFrom: range.pageFrom, pageTo: range.pageTo));
    }
  }

  if (result.isEmpty || (result.isNotEmpty && result.last.pageTo < pageCount)) {
    result.add(BookReadingProgressItem(
        hasRead: false,
        pageFrom: result.isEmpty ? 1 : result.last.pageTo + 1,
        pageTo: pageCount));
  }

  return result;
}

extension ToDateOnly on DateTime {
  DateTime toDateOnly() {
    return DateTime(year, month, day);
  }
}

extension DayOfWeek on DateTime {
  DateTime getFirstDayOfWeek() {
    final date = toDateOnly();
    final dayShift = 1 - date.weekday;
    return date.add(Duration(days: dayShift));
  }
}

int getWeekByDay(int day) => (day / 7).ceil();

class WeekDate {
  final int year;
  final int month;
  final int week;

  WeekDate.now()
      : year = DateTime.now().year,
        month = DateTime.now().month,
        week = getWeekByDay(DateTime.now().day);

  WeekDate({required this.year, required this.month, required this.week});

  DateTime getFirstDateTime() => DateTime(year, month, 1 + (week - 1) * 7);

  WeekDate getPrevious() {
    if (week > 1) {
      return WeekDate(year: year, month: month, week: week - 1);
    }
    if (month > 1) {
      return WeekDate(
        year: year,
        month: month - 1,
        week: getWeekByDay(DateUtils.getDaysInMonth(year, month - 1)),
      );
    }
    return WeekDate(
      year: year - 1,
      month: 12,
      week: getWeekByDay(DateUtils.getDaysInMonth(year - 1, 12)),
    );
  }

  WeekDate getNext() {
    final currentMonthWeeks =
        getWeekByDay(DateUtils.getDaysInMonth(year, month));
    if (week >= currentMonthWeeks) {
      return month >= 12
          ? WeekDate(year: year + 1, month: 1, week: 1)
          : WeekDate(year: year, month: month + 1, week: 1);
    }
    return WeekDate(year: year, month: month, week: week + 1);
  }
}

extension ToUnixTime on DateTime {
  int toUnixSeconds() => millisecondsSinceEpoch ~/ 1000;
}

extension FromUnixTime on int {
  DateTime unixSecondsToDateTime() =>
      DateTime.fromMillisecondsSinceEpoch(this * 1000);
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

String? dateTimeIsNotEmptyValidator(DateTime? dateTime) {
  if (dateTime == null) {
    return "Cannot empty";
  }
  return null;
}

String? stringIsPositiveNumberValidator(String? text) {
  if (text == null || text.isEmpty) {
    return "Cannot empty. Must be number";
  }
  int number = int.parse(text);
  if (number <= 0) {
    return "Must be positive number";
  }
  return null;
}

String? stringNotEmptyValidator(String? text) {
  if (text == null || text.trim().isEmpty) {
    return "Cannot empty";
  }
  return null;
}
