import 'package:flutter/material.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/ui/component/reading_progress_circular.dart';

class BookListView extends StatelessWidget {
  final List<BookEntity> list;
  final Function(BookEntity) onTap;

  const BookListView({super.key, required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) => _listTile(context, list[index]));
  }

  Widget _listTile(BuildContext context, BookEntity book) {
    final readRange = "${book.readedPageCount} of ${book.pageCount} ui read";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        InkWell(
          onTap: () => onTap(book),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              spacing: 16,
              children: [
                ReadingProgressCircular(value: book.readPercentage),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: TextTheme.of(context).bodyLarge,
                      ),
                      Text(
                        readRange,
                        style: TextTheme.of(context).bodyMedium,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
        )
      ],
    );
  }
}
