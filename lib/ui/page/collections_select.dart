import 'package:flutter/material.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/data/context.dart';
import 'package:readlog/data/repositories.dart';
import 'package:readlog/ui/component/base_bottom_sheet.dart';
import 'package:readlog/ui/component/conditional_widget.dart';
import 'package:readlog/ui/page/collection_add_edit.dart';
import 'package:readlog/ui/utils/refresh_controller.dart';

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
  bool _hasInitialized = false;
  bool _isLoading = false;
  List<CollectionEntity> _collections = [];
  List<bool> _isSelected = [];
  late final RefreshController _refreshController;
  late RepositoryProvider _repositoryProvider;

  _CollectionsSelectSheet() {
    _refreshController = RefreshController(_refresh);
  }

  @override
  void didChangeDependencies() {
    _repositoryProvider = RepositoryProviderContext.get(context);
    _refreshController.init(
      context,
      [_repositoryProvider.collections],
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

    final repository = RepositoryProviderContext.get(context).collections;
    final collection = await repository.getAll();
    final isSelected = List<bool>.filled(collection.length, false);

    final previousSelected = _hasInitialized ? _selectedList : widget.initials;
    _hasInitialized = true;

    for (var initial in previousSelected) {
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

  List<CollectionEntity> get _selectedList {
    List<CollectionEntity> result = [];
    for (var i = 0; i < _collections.length; i++) {
      if (_isSelected[i]) {
        result.add(_collections[i]);
      }
    }

    return result;
  }

  _save() {
    if (_isLoading) return;

    Navigator.of(context).pop(_selectedList);
  }

  _showAdd() {
    CollectionAddEditSheet.showAdd(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      scrollable: false,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Select Collections",
            style: TextTheme.of(context).titleLarge,
            textAlign: TextAlign.center,
          ),
          OutlinedButton(
            onPressed: _isLoading ? null : _showAdd,
            child: const Text("New Collection"),
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
          FilledButton(
            onPressed: _save,
            child: const Text("Save"),
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
