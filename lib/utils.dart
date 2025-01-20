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

  if (result.isEmpty ||
      (result.isNotEmpty && result.last.pageTo < pageCount)) {
    result.add(BookReadingProgressItem(
        hasRead: false,
        pageFrom: result.isEmpty ? 1 : result.last.pageTo + 1,
        pageTo: pageCount));
  }

  return result;
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