import 'package:flutter/material.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/ui/collection_add_edit.dart';
import 'package:readlog/ui/collection_books.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPage();
}

class _CollectionsPage extends State<CollectionsPage> {
  bool _isLoading = false;
  List<CollectionEntity> _collections = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final repository = RepositoryProviderContext.get(context).collections;
    final list = await repository.getAll();

    setState(() {
      _isLoading = false;
      _collections = list;
    });
  }

  _showAdd() async {
      int? id = await CollectionAddEditSheet.showAdd(context);
      if (!context.mounted || id == null) return;
      // await BookOverviewPage.show(context, id);
      // if (!context.mounted) return;
      _refresh();
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
      body: _collections.isEmpty
          ? Center(
              child: Text("No collections found yet"),
            )
          : ListView.builder(
              itemCount: _collections.length,
              itemBuilder: (builder, index) =>
                  _listTile(context, _collections[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _listTile(BuildContext context, CollectionEntity collection) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Card(
        child: InkWell(
          onTap: () async {
            await CollectionBooksPage.show(context, collection.id!);
            if (!mounted) return;
            _refresh();
          },
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
