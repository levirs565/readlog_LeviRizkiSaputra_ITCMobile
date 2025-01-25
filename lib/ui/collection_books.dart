import 'package:flutter/material.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/ui/collection_add_edit.dart';

import 'book_overview.dart';
import 'component/book_list_view.dart';

class CollectionBooksPage extends StatefulWidget {
  final int id;

  const CollectionBooksPage({super.key, required this.id});

  static Future<void> show(BuildContext context, int id) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollectionBooksPage(id: id),
      ),
    );
  }

  @override
  State<CollectionBooksPage> createState() => _CollectionBooksPage();
}

class _CollectionBooksPage extends State<CollectionBooksPage> {
  bool _isLoading = false;
  CollectionEntity? _collection = null;
  List<BookEntity> _books = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final repositoryProvider = RepositoryProviderContext.get(context);
    final collection = await repositoryProvider.collections.getById(widget.id);
    final books = await repositoryProvider.books.getAllByCollection(widget.id);

    setState(() {
      _isLoading = false;
      _collection = collection;
      _books = books;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_collection?.name ?? ""),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: _isLoading ? LinearProgressIndicator() : Container()),
        actions: [
          IconButton(
            onPressed: () async {
              if (_isLoading) return;
              await CollectionAddEditSheet.showEdit(context, _collection!);
              if (!mounted) return;
              _refresh();
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () async {
              if (_isLoading) return;
              final result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Delete Confirmation"),
                    content: const Text(
                        "Are you sure delete this collection? Books in this collection will not removed"),
                    actions: [
                      TextButton(
                          style: TextButton.styleFrom(
                            textStyle: TextTheme.of(context).labelLarge,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text("Cancel")),
                      TextButton(
                          style: TextButton.styleFrom(
                            textStyle: TextTheme.of(context).labelLarge,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text("OK"))
                    ],
                  );
                },
              );
              if (!context.mounted) return;
              if (result != null && result) {
                final repository =
                    RepositoryProviderContext.get(context).collections;
                await repository.delete(_collection!.id!);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.delete),
          )
        ],
      ),
      body: _books.isEmpty
          ? Center(
              child: Text("No book found"),
            )
          : BookListView(
              list: _books,
              onTap: (BookEntity book) async {
                await BookOverviewPage.show(context, book.id!);
                if (mounted) {
                  _refresh();
                }
              },
            ),
    );
  }
}
