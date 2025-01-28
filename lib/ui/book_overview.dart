import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readlog/refresh_controller.dart';
import 'package:readlog/route_observer_provider.dart';
import 'package:readlog/ui/read_timer.dart';

import '../data.dart';
import '../data_context.dart';
import '../utils.dart';
import 'book_add_edit.dart';
import 'read_histories.dart';

class BookOverviewPage extends StatefulWidget {
  final int id;

  const BookOverviewPage({
    super.key,
    required this.id,
  });

  static Future<void> show(BuildContext context, int id) {
    return Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => BookOverviewPage(
              id: id,
            )));
  }

  @override
  State<BookOverviewPage> createState() => _BookOverviewPage();
}

class _BookOverviewPage extends State<BookOverviewPage> {
  static final _dateFormatter = DateFormat("dd-MM-yyyy HH:mm");
  bool _isLoading = true;
  BookDetailEntity? _book = null;
  BookReadHistoryEntity? _lastRead = null;
  List<BookReadingProgressItem> _readingProgress = [];
  late RepositoryProvider _repositoryProvider;
  late RefreshController _refreshController;

  _BookOverviewPage() {
    _refreshController = RefreshController(_refresh);
  }

  @override
  void didChangeDependencies() {
    _repositoryProvider = RepositoryProviderContext.get(context);
    _refreshController.init(
      context,
      [_repositoryProvider.readHistories, _repositoryProvider.books],
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

    final book = await _repositoryProvider.books.getById(widget.id);
    final lastRead =
        await _repositoryProvider.readHistories.getLastByBook(widget.id);
    final coverage = analyzeBookReadingProgress(book!.pageCount,
        await _repositoryProvider.readHistories.getAllMergedByBook(widget.id));

    setState(() {
      _isLoading = false;
      _lastRead = lastRead;
      _readingProgress = coverage;
      _book = book;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: _isLoading ? LinearProgressIndicator() : Container()),
        actions: [
          IconButton(
            onPressed: () async {
              if (_isLoading || _book == null) return;
              await BookAddEditSheet.showEdit(context, _book!);
            },
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
          ),
          IconButton(
            onPressed: () async {
              if (_isLoading || _book == null) return;
              final result = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Delete Confirmation"),
                    content: const Text("Are you sure delete this book?"),
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
              if (result != null && result) {
                final repository = _repositoryProvider.books;
                await repository.delete(widget.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.delete),
            tooltip: "Delete",
          )
        ],
      ),
      body: _book == null
          ? null
          : SingleChildScrollView(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                _detailContainer(context),
                _readHistoryContainer(context),
                _readingProgressContainer(context),
              ],
            )),
    );
  }

  Widget _detailContainer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _book!.title,
            style: TextTheme.of(context).titleLarge,
          ),
          Text("${_book!.readedPageCount} of ${_book!.pageCount} ui read"),
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              spacing: 16,
              children: [
                Expanded(
                    child: LinearProgressIndicator(
                  value: _book!.readPercentage,
                )),
                Text("${(_book!.readPercentage * 100).round()}%")
              ],
            ),
          ),
          Wrap(
            runSpacing: 4,
            spacing: 8,
            children: _book!.collections.map((element) {
              return Chip(label: Text(element.name));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _readHistoryContainer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text("Read History", style: TextTheme.of(context).titleMedium),
          Text(_lastRead == null
              ? "No read history yet"
              : "Last read from page ${_lastRead!.pageFrom} to page ${_lastRead!.pageTo} at ${_dateFormatter.format(_lastRead!.dateTimeFrom)} - ${_dateFormatter.format(_lastRead!.dateTimeTo)}"),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await BookReadingTimerPage.show(context, widget.id);
                },
                icon: const Icon(Icons.timer),
                label: const Text("Reading Timer"),
              ),
              FilledButton(
                  onPressed: () async {
                    await BookReadHistoriesPage.show(context, widget.id);
                  },
                  child: const Text("Show All"))
            ],
          ),
        ],
      ),
    );
  }

  Widget _readingProgressContainer(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Reading Progress",
                textAlign: TextAlign.left,
                style: TextTheme.of(context).titleMedium),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Add Read History to update Reading Progress",
                textAlign: TextAlign.left,
                style: TextTheme.of(context).bodySmall),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _readingProgress.length,
            padding: EdgeInsets.all(0),
            itemBuilder: (context, index) =>
                _readingProgressItem(context, _readingProgress[index]),
          )
        ],
      ),
    );
  }

  Widget _readingProgressItem(
      BuildContext context, BookReadingProgressItem item) {
    return Container(
      color: item.hasRead
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      padding: EdgeInsets.symmetric(
          vertical: 8 + ((item.pageTo - item.pageFrom + 1) / 8),
          horizontal: 16),
      child: Column(
        children: [
          Text(
            "From page ${item.pageFrom} to ${item.pageTo}",
            style: TextTheme.of(context).bodyMedium,
          ),
          Text(item.hasRead ? "Has been read" : "Unread")
        ],
      ),
    );
  }
}
