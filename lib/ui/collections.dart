import 'package:flutter/material.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/refresh_controller.dart';
import 'package:readlog/ui/collection_add_edit.dart';
import 'package:readlog/ui/collection_books.dart';
import 'package:readlog/ui/component/conditional_widget.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPage();
}

class _CollectionsPage extends State<CollectionsPage> {
  bool _isLoading = false;
  List<CollectionEntity> _collections = [];
  late RepositoryProvider _repositoryProvider;
  late final RefreshController _refreshController;

  _CollectionsPage() {
    _refreshController = RefreshController(_refresh);
  }

  @override
  void didChangeDependencies() {
    _repositoryProvider = RepositoryProviderContext.get(context);
    _refreshController.init(
      context,
      [
        _repositoryProvider.collections,
      ],
    );
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

    final repository = _repositoryProvider.collections;
    final list = await repository.getAll();

    setState(() {
      _isLoading = false;
      _collections = list;
    });
  }

  _showAdd() async {
    int? id = await CollectionAddEditSheet.showAdd(context);
    if (!mounted || id == null) return;
    await CollectionBooksPage.show(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Collections"),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: _isLoading ? LinearProgressIndicator() : Container()),
      ),
      body: ConditionalWidget(
        isLoading: _isLoading,
        isEmpty: _collections.isEmpty,
        contentBuilder: _content,
        emptyBuilder: _emptyWidget,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _showAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _emptyWidget(BuildContext context) {
    return Center(
      child: Text("No collections found yet"),
    );
  }

  Widget _content(BuildContext context) {
    return ListView.builder(
      itemCount: _collections.length,
      itemBuilder: (builder, index) => _listTile(context, _collections[index]),
    );
  }

  Widget _listTile(BuildContext context, CollectionEntity collection) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: () => CollectionBooksPage.show(context, collection.id!),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              collection.name,
              style: TextTheme.of(context).bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}
