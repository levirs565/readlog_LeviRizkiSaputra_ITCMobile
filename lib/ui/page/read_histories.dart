import 'package:flutter/material.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/ui/component/base_bottom_sheet.dart';
import 'package:readlog/ui/utils/dialog.dart';
import 'package:readlog/ui/utils/refresh_controller.dart';
import 'package:readlog/ui/component/conditional_widget.dart';
import 'package:readlog/ui/component/read_history_timeline.dart';
import 'package:readlog/ui/page/read_history_add_edit.dart';
import 'package:readlog/data/repositories.dart';
import 'package:readlog/data/context.dart';

class BookReadHistoriesPage extends StatefulWidget {
  final int bookId;

  const BookReadHistoriesPage({super.key, required this.bookId});

  static Future<void> show(BuildContext context, int bookId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookReadHistoriesPage(
          bookId: bookId,
        ),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => _BookReadHistoriesPage();
}

class _BookReadHistoriesPage extends State<BookReadHistoriesPage> {
  bool _isLoading = true;
  List<ReadHistoryTimelineItem> _list = [];
  late RepositoryProvider _repositoryProvider;
  late final RefreshController _refreshController;

  _BookReadHistoriesPage() {
    _refreshController = RefreshController(_refresh);
  }

  @override
  void didChangeDependencies() {
    _repositoryProvider = RepositoryProviderContext.get(context);
    _refreshController.init(
      context,
      [
        _repositoryProvider.readHistories,
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

    final sessionList =
        await _repositoryProvider.readHistories.getAllByBook(widget.bookId);
    final newList = ReadHistoryTimeline.buildItems(sessionList);

    setState(() {
      _isLoading = false;
      _list = newList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Read Histories"),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: _isLoading ? LinearProgressIndicator() : Container()),
      ),
      body: ConditionalWidget(
        isLoading: _isLoading,
        isEmpty: _list.isEmpty,
        emptyBuilder: _emptyContent,
        contentBuilder: _content,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            BookAddEditHistorySheet.showAdd(context, widget.bookId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _emptyContent(BuildContext context) {
    return Center(
      child:
          Text("No read history yet", style: TextTheme.of(context).bodyLarge),
    );
  }

  Widget _content(BuildContext context) {
    return ReadHistoryTimeline(
      items: _list,
      onSelected: _showAction,
    );
  }

  _tryDelete(BookReadHistoryEntity entity) async {
    final result = await showConfirmationDialog(
      context: context,
      title: const Text("Delete Confirmation"),
      content: const Text("Are you sure delete this reading session?"),
    );
    if (!result || !mounted) return;

    await _repositoryProvider.readHistories.delete(entity.id!);
  }

  _showAction(BookReadHistoryEntity entity) async {
    final result = await _ActionSheet.show(context);
    if (result == null || !mounted) return;

    if (result == _ActionResult.edit) {
      await BookAddEditHistorySheet.showEdit(context, entity);
    } else if (result == _ActionResult.delete) {
      await _tryDelete(entity);
    }
  }
}

enum _ActionResult {
  edit,
  delete;
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({super.key});

  static Future<_ActionResult?> show(BuildContext context) {
    return BaseBottomSheet.showModal(
      context: context,
      builder: (context) => _ActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      horizontalPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Action",
            style: TextTheme.of(context).titleLarge,
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit"),
            onTap: () =>
                Navigator.of(context).pop(_ActionResult.edit),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Remove"),
            onTap: () => Navigator.of(context)
                .pop(_ActionResult.delete),
          )
        ],
      ),
    );
  }
}
