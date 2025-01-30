import 'package:flutter/material.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/data/repositories.dart';
import 'package:readlog/data/context.dart';
import 'package:readlog/ui/utils/dialog.dart';
import 'package:readlog/ui/utils/refresh_controller.dart';
import 'package:readlog/ui/page/book_add_edit.dart';
import 'package:readlog/ui/page/collection_add_edit.dart';
import 'package:readlog/ui/component/conditional_widget.dart';
import 'package:readlog/ui/page/book_overview.dart';
import 'package:readlog/ui/component/book_list_view.dart';

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
  late RepositoryProvider _repositoryProvider;
  late final RefreshController _refreshController;

  _CollectionBooksPage() {
    _refreshController = RefreshController(_refresh);
  }

  @override
  void didChangeDependencies() {
    _repositoryProvider = RepositoryProviderContext.get(context);
    _refreshController.init(context, [
      _repositoryProvider.collections,
      _repositoryProvider.books,
      _repositoryProvider.readHistories
    ]);
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

    final collection = await _repositoryProvider.collections.getById(widget.id);
    final books = await _repositoryProvider.books.getAllByCollection(widget.id);

    setState(() {
      _isLoading = false;
      _collection = collection;
      _books = books;
    });
  }

  bool get _dataAvailable => !_isLoading && _collection != null;

  _edit() {
    CollectionAddEditSheet.showEdit(context, _collection!);
  }

  _tryDelete() async {
    final result = await showConfirmationDialog(
      context: context,
      title: const Text("Delete Confirmation"),
      content: const Text(
          "Are you sure delete this collection? Books in this collection will not removed"),
    );
    if (!context.mounted) return;
    if (result) {
      final repository = _repositoryProvider.collections;
      await repository.delete(_collection!.id!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  _addBook() {
    BookAddEditSheet.showAdd(context, collections: [_collection!]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_collection?.name ?? ""),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: _isLoading ? LinearProgressIndicator() : Container()),
        actions: [
          IconButton(
            onPressed: !_dataAvailable ? null : _edit,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: !_dataAvailable ? null : _tryDelete,
            icon: const Icon(Icons.delete),
          )
        ],
      ),
      body: ConditionalWidget(
        isLoading: _isLoading,
        isEmpty: _books.isEmpty,
        contentBuilder: _content,
        emptyBuilder: _emptyWidget,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return BookListView(
      list: _books,
      onTap: (BookEntity book) => BookOverviewPage.show(context, book.id!),
    );
  }

  Widget _emptyWidget(BuildContext contet) {
    return Center(
      child: Text("No book found"),
    );
  }
}
