import 'package:flutter/material.dart';
import 'package:readlog/refresh_controller.dart';
import 'package:readlog/ui/component/book_list_view.dart';

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
  late RepositoryProvider _repositoryProvider;
  late final RefreshController _refreshController;

  _BooksPageState() {
    _refreshController = RefreshController(_refresh);
  }

  @override
  void didChangeDependencies() {
    _repositoryProvider = RepositoryProviderContext.get(context);
    _refreshController.init(context, [_repositoryProvider.books, _repositoryProvider.readHistories]);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final newList = await _repositoryProvider.books.getAll();

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
          : BookListView(
              list: _list,
              onTap: (BookEntity book) async {
                await BookOverviewPage.show(context, book.id!);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          int? id = await BookAddEditSheet.showAdd(context);
          if (!context.mounted || id == null) return;
          await BookOverviewPage.show(context, id);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
