import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readlog/data/repositories.dart';
import 'package:readlog/ui/component/reading_progress_circular.dart';
import 'package:readlog/ui/utils/dialog.dart';
import 'package:readlog/ui/utils/refresh_controller.dart';
import 'package:readlog/ui/component/conditional_widget.dart';
import 'package:readlog/ui/component/reading_progress.dart';
import 'package:readlog/ui/page/read_timer.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/data/context.dart';
import 'package:readlog/ui/page/book_add_edit.dart';
import 'package:readlog/ui/page/read_histories.dart';

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
  BookDetailEntity? _book;
  BookReadHistoryEntity? _lastRead;
  List<BookReadingProgressItem> _readingProgress = [];
  late RepositoryProvider _repositoryProvider;
  late RefreshController _refreshController;
  late final ScrollController _scrollController;
  bool _isAppBarTitleShown = false;

  _BookOverviewPage() {
    _refreshController = RefreshController(_refresh);
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  _onScroll() {
    bool show = _scrollController.position.pixels > 48;
    if (show != _isAppBarTitleShown) {
      setState(() {
        _isAppBarTitleShown = show;
      });
    }
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
    _scrollController.dispose();
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
    final coverage = ReadingProgress.buildItems(
      book!.pageCount,
      await _repositoryProvider.readHistories.getAllMergedByBook(widget.id),
    );

    setState(() {
      _isLoading = false;
      _lastRead = lastRead;
      _readingProgress = coverage;
      _book = book;
    });
  }

  _edit() async {
    await BookAddEditSheet.showEdit(context, _book!);
  }

  _tryDelete() async {
    final result = await showConfirmationDialog(
      context: context,
      title: const Text("Delete Confirmation"),
      content: const Text("Are you sure delete this book?"),
    );

    if (result) {
      final repository = _repositoryProvider.books;
      await repository.delete(widget.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  bool get _bookAvailable => !_isLoading && _book != null;

  static final _titleHiddenTransform =
      Transform.translate(offset: Offset(0, 56)).transform;
  static final _titleShownTransform =
      Transform.translate(offset: Offset.zero).transform;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 56,
          title: AnimatedContainer(
            height: 56,
            duration: Duration(milliseconds: 250),
            curve: Easing.standard,
            transform: _isAppBarTitleShown
                ? _titleShownTransform
                : _titleHiddenTransform,
            child: Row(
              children: [
                AnimatedOpacity(
                    duration: Duration(milliseconds: 250),
                    curve: Easing.standard,
                    opacity: _isAppBarTitleShown ? 1 : 0,
                    child: Text(
                      _book?.title ?? "",
                    ))
              ],
            ),
          ),
          bottom: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: _isLoading ? LinearProgressIndicator() : Container()),
          actions: [
            IconButton(
              onPressed: !_bookAvailable ? null : _edit,
              icon: const Icon(Icons.edit),
              tooltip: "Edit",
            ),
            IconButton(
              onPressed: !_bookAvailable ? null : _tryDelete,
              icon: const Icon(Icons.delete),
              tooltip: "Delete",
            )
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: ConditionalWidget(
          isLoading: _isLoading,
          isEmpty: _book == null,
          contentBuilder: _content,
        ));
  }

  Widget _content(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          _detailContainer(context),
          _readHistoryContainer(context),
          _readingProgressContainer(context),
        ],
      ),
    );
  }

  Widget _detailHeader(BuildContext context) {
    return Row(
      spacing: 16,
      children: [
        ReadingProgressCircular(value: _book!.readPercentage),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _book!.title,
                style: TextTheme.of(context).titleLarge,
              ),
              Text("${_book!.readedPageCount} of ${_book!.pageCount} ui read"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailContainer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          _detailHeader(context),
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

  _showReadingTimer() {
    BookReadingTimerPage.show(context, widget.id);
  }

  _showAllReadHistory() {
    BookReadHistoriesPage.show(context, widget.id);
  }

  String _getLastReadText(BookReadHistoryEntity entity) {
    final pageFrom = entity.pageFrom;
    final pageTo = entity.pageTo;
    final dateFrom = _dateFormatter.format(_lastRead!.dateTimeFrom);
    final dateTo = _dateFormatter.format(_lastRead!.dateTimeTo);
    return "Last read from page $pageFrom to page $pageTo at $dateFrom - $dateTo";
  }

  Widget _readHistoryContainer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text("Read History", style: TextTheme.of(context).titleMedium),
          Text(
            _lastRead == null
                ? "No read history yet"
                : _getLastReadText(_lastRead!),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _showAllReadHistory,
                child: const Text("Show All"),
              ),
              FilledButton.icon(
                onPressed: _showReadingTimer,
                icon: const Icon(Icons.timer),
                label: const Text("Reading Timer"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readingProgressContainer(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Reading Progress",
              textAlign: TextAlign.left,
              style: TextTheme.of(context).titleMedium,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Add Read History to update Reading Progress",
                textAlign: TextAlign.left,
                style: TextTheme.of(context).bodySmall),
          ),
          ReadingProgress(
            items: _readingProgress,
          )
        ],
      ),
    );
  }
}
