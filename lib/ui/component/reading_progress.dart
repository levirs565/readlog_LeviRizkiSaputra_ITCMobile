import 'package:flutter/material.dart';
import 'package:readlog/data/entities.dart';

class BookReadingProgressItem {
  final bool hasRead;
  final int pageFrom, pageTo;

  const BookReadingProgressItem(
      {required this.hasRead, required this.pageFrom, required this.pageTo});
}

class ReadingProgress extends StatelessWidget {
  static List<BookReadingProgressItem> buildItems(
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
              pageTo: range.pageFrom - 1));
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

  final List<BookReadingProgressItem> items;

  const ReadingProgress({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: EdgeInsets.all(0),
      itemBuilder: (context, index) => _readingProgressItem(
        context,
        items[index],
      ),
    );
  }

  Widget _readingProgressItem(
    BuildContext context,
    BookReadingProgressItem item,
  ) {
    return Container(
      color: item.hasRead
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      padding: EdgeInsets.symmetric(
        vertical: 8 + ((item.pageTo - item.pageFrom + 1) / 8),
        horizontal: 16,
      ),
      child: Column(
        children: [
          Text(
            "From page ${item.pageFrom} to ${item.pageTo}",
            style: TextTheme.of(context).bodyMedium,
          ),
          Text(item.hasRead ? "Has been read" : "Unread")
        ],
      ),
    );
  }
}
