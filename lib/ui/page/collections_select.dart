import 'package:flutter/material.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/data/context.dart';
import 'package:readlog/ui/component/base_bottom_sheet.dart';
import 'package:readlog/ui/component/conditional_widget.dart';

class CollectionsSelectSheet extends StatefulWidget {
  final List<CollectionEntity> initials;

  const CollectionsSelectSheet._({super.key, required this.initials});

  static Future<List<CollectionEntity>?> show(
      BuildContext context, List<CollectionEntity> initials) {
    return BaseBottomSheet.showModal<List<CollectionEntity>>(
      context: context,
      builder: (context) => CollectionsSelectSheet._(
        initials: initials,
      ),
    );
  }

  @override
  State<CollectionsSelectSheet> createState() => _CollectionsSelectSheet();
}

class _CollectionsSelectSheet extends State<CollectionsSelectSheet> {
  bool _isLoading = false;
  List<CollectionEntity> _collections = [];
  List<bool> _isSelected = [];

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
    final collection = await repository.getAll();
    final isSelected = List<bool>.filled(collection.length, false);

    for (var initial in widget.initials) {
      final index = collection.indexWhere((el) => el.id == initial.id);
      if (index >= 0) {
        isSelected[index] = true;
      }
    }

    setState(() {
      _isLoading = false;
      _collections = collection;
      _isSelected = isSelected;
    });
  }

  _save() {
    if (_isLoading) return;
    List<CollectionEntity> result = [];
    for (var i = 0; i < _collections.length; i++) {
      if (_isSelected[i]) {
        result.add(_collections[i]);
      }
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      scrollable: false,
      child: Column(
        spacing: 16,
        children: [
          Text(
            "Select Collections",
            style: TextTheme.of(context).titleLarge,
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: ConditionalWidget(
              isLoading: _isLoading,
              isEmpty: _collections.isEmpty,
              loadingBuilder: _loadingContent,
              emptyBuilder: _emptyContent,
              contentBuilder: _content,
            ),
          ),
          Row(
            spacing: 16,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: _save,
                child: const Text("Save"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _loadingContent(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _emptyContent(BuildContext context) {
    return const Center(
      child: Text("No collection found"),
    );
  }

  Widget _content(BuildContext context) {
    return ListView.builder(
      itemCount: _collections.length,
      itemBuilder: _listTile,
    );
  }

  Widget _listTile(BuildContext context, int index) {
    final collection = _collections[index];
    final isSelected = _isSelected[index];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        spacing: 8.0,
        children: [
          Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  _isSelected[index] = value!;
                });
              }),
          Text(
            collection.name,
            style: TextTheme.of(context).bodyLarge,
          )
        ],
      ),
    );
  }
}
