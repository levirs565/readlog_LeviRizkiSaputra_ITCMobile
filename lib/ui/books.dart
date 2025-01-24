import 'package:flutter/material.dart';

import '../data.dart';
import '../data_context.dart';
import 'book_add_edit.dart';
import 'book_overview.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  bool _isLoading = true;
  List<BookEntity> _list = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final bookRepository = RepositoryProviderContext.get(context).books;
    final newList = await bookRepository.getAll();

    setState(() {
      _list = newList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Read Log"),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: _isLoading ? LinearProgressIndicator() : Container()),
      ),
      body: _list.isEmpty
          ? Center(
        child: Text("No book found"),
      )
          : ListView.builder(
        itemCount: _list.length,
        itemBuilder: (context, index) => _listTile(context, _list[index]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          int? id = await BookAddEditSheet.showAdd(context);
          if (!context.mounted || id == null) return;
          await BookOverviewPage.show(context, id);
          if (!context.mounted) return;
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _listTile(BuildContext context, BookEntity book) {
    final readRange = "${book.readedPageCount} of ${book.pageCount} ui read";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        InkWell(
          onTap: () async {
            await BookOverviewPage.show(context, book.id!);
            if (mounted) {
              _refresh();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              spacing: 16,
              children: [
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
                      SizedBox(
                        height: 8,
                      ),
                      LinearProgressIndicator(
                        value: book.readPercentage,
                      ),
                    ],
                  ),
                ),
                Text(
                  "${(book.readPercentage * 100).round()}%",
                  style: TextTheme.of(context).titleLarge,
                ),
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