import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/data_impl.dart';
import 'package:intl/intl.dart';
import 'package:readlog/utils.dart';

late RepositoryProviderImpl repositoryProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  repositoryProvider = RepositoryProviderImpl();
  await repositoryProvider.open();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProviderContext(
      provider: repositoryProvider,
      child: MaterialApp(
        title: 'Read Log',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Builder(builder: (context) => HomePage.create(context)),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final BookRepository repository;

  const HomePage({super.key, required this.repository});

  static HomePage create(BuildContext context) {
    return HomePage(repository: RepositoryProviderContext.of(context).books);
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  List<BookEntity> _list = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final newList = await widget.repository.getAll();

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
          : ListView.builder(
              itemCount: _list.length,
              itemBuilder: (context, index) => _listTile(context, _list[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          int? id = await BookAddEditSheet.showAdd(context);
          if (!context.mounted || id == null) return;
          await BookOverviewPage.show(context, id);
          if (!context.mounted) return;
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _listTile(BuildContext context, BookEntity book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        InkWell(
          onTap: () async {
            await BookOverviewPage.show(context, book.id!);
            if (mounted) {
              _refresh();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextTheme.of(context).bodyLarge,
                ),
                Text(
                  book.pageCount.toString(),
                  style: TextTheme.of(context).bodyMedium,
                )
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
        )
      ],
    );
  }
}

class BookAddEditSheet extends StatefulWidget {
  final BookEntity? book;
  final BookRepository repository;

  const BookAddEditSheet({super.key, this.book, required this.repository});

  static Future<int?> showAdd(BuildContext context) {
    return showModalBottomSheet<int>(
        isScrollControlled: true,
        context: context,
        builder: (context) => BookAddEditSheet(
              repository: RepositoryProviderContext.of(context).books,
            ));
  }

  static Future<int?> showEdit(BuildContext context, BookEntity book) {
    return showModalBottomSheet<int?>(
        context: context,
        isScrollControlled: true,
        builder: (context) => BookAddEditSheet(
              book: book,
              repository: RepositoryProviderContext.of(context).books,
            ));
  }

  @override
  State<BookAddEditSheet> createState() => _BookAddEditSheet();
}

class _BookAddEditSheet extends State<BookAddEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleEditingController = TextEditingController();
  final _pageCountEditingController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    if (widget.book != null) {
      _titleEditingController.text = widget.book!.title;
      _pageCountEditingController.text = widget.book!.pageCount.toString();
    }
    super.initState();
  }

  @override
  void dispose() {
    _titleEditingController.dispose();
    _pageCountEditingController.dispose();
    super.dispose();
  }

  _save() async {
    setState(() {
      _isSaving = true;
    });

    final entity = BookEntity(
        id: widget.book?.id,
        title: _titleEditingController.text,
        pageCount: int.parse(_pageCountEditingController.text),
        readedPageCount: 0);

    try {
      int? result = entity.id;
      if (widget.book?.id == null) {
        result = await widget.repository.add(entity);
      } else {
        await widget.repository.update(entity);
      }
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Error when saving")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            32,
            16,
            32 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            spacing: 16.0,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.book == null ? "Add Book" : "Edit Book",
                style: TextTheme.of(context).titleLarge,
                textAlign: TextAlign.center,
              ),
              TextFormField(
                controller: _titleEditingController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: const Text("Title"),
                ),
                validator: stringNotEmptyValidator,
                enabled: !_isSaving,
              ),
              TextFormField(
                controller: _pageCountEditingController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: const Text("Page Count"),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: stringIsPositiveNumberValidator,
                enabled: !_isSaving,
              ),
              FilledButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _save();
                        }
                      },
                child: Text(
                  widget.book == null ? "Add" : "Save",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class BookOverviewPage extends StatefulWidget {
  final BookRepository bookRepository;
  final BookReadHistoryRepository bookReadHistoryRepository;
  final int id;

  const BookOverviewPage(
      {super.key,
      required this.id,
      required this.bookRepository,
      required this.bookReadHistoryRepository});

  static Future<void> show(BuildContext context, int id) {
    final provider = RepositoryProviderContext.of(context);
    return Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => BookOverviewPage(
              id: id,
              bookRepository: provider.books,
              bookReadHistoryRepository: provider.readHistories,
            )));
  }

  @override
  State<BookOverviewPage> createState() => _BookOverviewPage();
}

class _BookOverviewPage extends State<BookOverviewPage> {
  static final _dateFormatter = DateFormat("dd-MM-yyyy HH:mm");
  bool _isLoading = true;
  BookEntity? _book = null;
  BookReadHistoryEntity? _lastRead = null;
  List<BookReadingProgressItem> _readingProgress = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final book = await widget.bookRepository.getById(widget.id);
    final lastRead =
        await widget.bookReadHistoryRepository.getLastByBook(widget.id);
    final coverage = analyzeBookReadingProgress(book!.pageCount,
        await widget.bookReadHistoryRepository.getAllMergedByBook(widget.id));

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
              if (mounted) {
                _refresh();
              }
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
                await widget.bookRepository.delete(widget.id);
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
    final readPercentage =
        _book!.readedPageCount.toDouble() / _book!.pageCount.toDouble();
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
          Text("${_book!.readedPageCount} of ${_book!.pageCount} pages read"),
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              spacing: 16,
              children: [
                Expanded(
                    child: LinearProgressIndicator(
                  value: readPercentage,
                )),
                Text("${(readPercentage * 100).round()}%")
              ],
            ),
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
                  if (!mounted) return;
                  _refresh();
                },
                icon: const Icon(Icons.timer),
                label: const Text("Reading Timer"),
              ),
              FilledButton(
                  onPressed: () async {
                    await BookAddEditHistorySheet.showAdd(context, widget.id);
                    if (!mounted) return;
                    _refresh();
                  },
                  child: const Text("Add")),
              FilledButton(
                  onPressed: () async {
                    await BookReadHistoriesPage.show(context, widget.id);
                    if (!mounted) return;
                    _refresh();
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

sealed class BookReadHistoryItem {
  const BookReadHistoryItem();
}

class BookReadHistoryDateItem extends BookReadHistoryItem {
  final DateTime date;

  const BookReadHistoryDateItem(this.date);
}

class BookReadHistorySessionItem extends BookReadHistoryItem {
  final BookReadHistoryEntity session;

  const BookReadHistorySessionItem(this.session);
}

class BookReadHistoriesPage extends StatefulWidget {
  final int bookId;
  final BookReadHistoryRepository repository;

  const BookReadHistoriesPage(
      {super.key, required this.bookId, required this.repository});

  static Future<void> show(BuildContext context, int bookId) {
    return Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => BookReadHistoriesPage(
            bookId: bookId,
            repository: RepositoryProviderContext.of(context).readHistories)));
  }

  @override
  State<StatefulWidget> createState() => _BookReadHistoriesPage();
}

class DateCirclePainter extends CustomPainter {
  final Color color;
  final double radius;
  final int position;

  DateCirclePainter(
      {required this.color, required this.radius, required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(size.center(Offset.zero), radius, Paint()..color = color);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4;
    if (position == -1) {
      canvas.drawLine(
          size.center(Offset.zero), size.bottomCenter(Offset.zero), linePaint);
    } else if (position == 0) {
      canvas.drawLine(size.topCenter(Offset.zero),
          size.bottomCenter(Offset.zero), linePaint);
    } else if (position == 1) {
      canvas.drawLine(
          size.topCenter(Offset.zero), size.center(Offset.zero), linePaint);
    }
  }

  @override
  bool shouldRepaint(DateCirclePainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      position != oldDelegate.position;
}

class _BookReadHistoriesPage extends State<BookReadHistoriesPage> {
  static final _dateFormatter = DateFormat("dd-MM-yyyy");
  static final _timeFormatter = DateFormat("HH:mm:ss");
  bool _isLoading = true;
  List<BookReadHistoryItem> _list = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final sessionList = await widget.repository.getAllByBook(widget.bookId);

    List<BookReadHistoryItem> newList = [];

    DateTime? lastSessionDate;
    for (final session in sessionList) {
      if (session.dateTimeFrom.toDateOnly() != lastSessionDate) {
        newList.add(BookReadHistoryDateItem(session.dateTimeFrom.toDateOnly()));
      }

      newList.add(BookReadHistorySessionItem(session));

      lastSessionDate = session.dateTimeFrom.toDateOnly();
    }

    setState(() {
      _isLoading = false;
      _list = newList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Read Histories"),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: _isLoading ? LinearProgressIndicator() : Container()),
      ),
      body: _list.isEmpty
          ? Center(
              child: Text("No read history yet",
                  style: TextTheme.of(context).bodyLarge),
            )
          : ListView.builder(
              itemCount: _list.length,
              itemBuilder: (BuildContext context, int index) {
                int circlePositionParam = index == 0
                    ? -1
                    : index == _list.length - 1
                        ? 1
                        : 0;
                if (_list[index] is BookReadHistorySessionItem) {
                  return _listTileSession(
                      context,
                      _list[index] as BookReadHistorySessionItem,
                      circlePositionParam);
                }
                return _listTileDate(
                    context,
                    _list[index] as BookReadHistoryDateItem,
                    circlePositionParam);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await BookAddEditHistorySheet.showAdd(context, widget.bookId);
          if (!mounted) return;
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _listTileDate(
      BuildContext context, BookReadHistoryDateItem item, int circlePosition) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: Size.fromWidth(48),
            painter: DateCirclePainter(
              color: Theme.of(context).colorScheme.primary,
              radius: 12,
              position: circlePosition,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(left: 8),
            child: Text(
              _dateFormatter.format(item.date),
              style: TextTheme.of(context).titleLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listTileSession(BuildContext context, BookReadHistorySessionItem item,
      int circlePosition) {
    final timeFrom = _timeFormatter.format(item.session.dateTimeFrom);
    final timeTo = _timeFormatter.format(item.session.dateTimeTo);
    final title = "$timeFrom - $timeTo";

    final durationSeconds =
        item.session.dateTimeTo.difference(item.session.dateTimeFrom).inSeconds;
    final showSecond = durationSeconds % Duration.secondsPerMinute;
    final minute = durationSeconds ~/ Duration.secondsPerMinute;
    final showMinute = minute % Duration.minutesPerHour;
    final hour = minute ~/ Duration.minutesPerHour;

    final duration = hour == 0 && minute == 0
        ? "$showSecond second"
        : hour == 0
            ? "$showMinute minute"
            : "$hour hour $showMinute minute";
    final readRange =
        "From page ${item.session.pageFrom} to page ${item.session.pageTo}";

    return InkWell(
      onTap: () async {
        final result = await BookHistoryActionSheet.show(context);
        if (result == null || !context.mounted) return;

        if (result == BookHistoryActionSheetResult.edit) {
          await BookAddEditHistorySheet.showEdit(context, item.session);
        } else if (result == BookHistoryActionSheetResult.delete) {
          final result = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete Confirmation"),
              content: const Text("Are you sure delete this reading session?"),
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
            ),
          );
          if (result == null || !result) return;

          await widget.repository.delete(item.session.id!);
        }
        if (!context.mounted) return;
        _refresh();
      },
      child: IntrinsicHeight(
        child: Row(
          children: [
            CustomPaint(
              size: Size.fromWidth(48),
              painter: DateCirclePainter(
                color: Theme.of(context).colorScheme.primary,
                radius: 8,
                position: circlePosition,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextTheme.of(context).titleMedium,
                  ),
                  Text(
                    duration,
                    style: TextTheme.of(context).bodyLarge,
                  ),
                  Text(
                    readRange,
                    style: TextTheme.of(context).bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BookHistoryActionSheetResult {
  edit,
  delete;
}

class BookHistoryActionSheet extends StatelessWidget {
  const BookHistoryActionSheet({super.key});

  static Future<BookHistoryActionSheetResult?> show(BuildContext context) {
    return showModalBottomSheet<BookHistoryActionSheetResult>(
      context: context,
      builder: (context) => BookHistoryActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    "Action",
                    style: TextTheme.of(context).titleLarge,
                  )),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit"),
                onTap: () => Navigator.of(context)
                    .pop(BookHistoryActionSheetResult.edit),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Remove"),
                onTap: () => Navigator.of(context)
                    .pop(BookHistoryActionSheetResult.delete),
              )
            ],
          ),
        )
      ],
    );
  }
}

class BookAddEditHistorySheet extends StatefulWidget {
  final int? bookId;
  final BookReadHistoryEntity? readHistory;
  final BookReadHistoryRepository repository;

  const BookAddEditHistorySheet(
      {super.key, this.bookId, this.readHistory, required this.repository});

  static Future<void> showAdd(BuildContext context, int bookId) {
    return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => BookAddEditHistorySheet(
              bookId: bookId,
              repository: RepositoryProviderContext.of(context).readHistories,
            ));
  }

  static Future<void> showEdit(
      BuildContext context, BookReadHistoryEntity readHistory) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => BookAddEditHistorySheet(
              readHistory: readHistory,
              repository: RepositoryProviderContext.of(context).readHistories,
            ));
  }

  @override
  State<StatefulWidget> createState() => _BookAddEditHistorySheet();
}

class _BookAddEditHistorySheet extends State<BookAddEditHistorySheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _extraError = null;
  final ValueNotifier<DateTime?> _dateFromNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> _dateToNotifier = ValueNotifier(null);
  final TextEditingController _pageFromEditingController =
      TextEditingController();
  final TextEditingController _pageToEditingController =
      TextEditingController();

  @override
  void initState() {
    if (widget.readHistory != null) {
      _dateFromNotifier.value = widget.readHistory?.dateTimeFrom;
      _dateToNotifier.value = widget.readHistory?.dateTimeTo;
      _pageFromEditingController.text = widget.readHistory!.pageFrom.toString();
      _pageToEditingController.text = widget.readHistory!.pageTo.toString();
    }
    super.initState();
  }

  @override
  void dispose() {
    _dateFromNotifier.dispose();
    _dateToNotifier.dispose();
    _pageFromEditingController.dispose();
    _pageToEditingController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    final pageFrom = int.parse(_pageFromEditingController.text);
    final pageTo = int.parse(_pageToEditingController.text);
    if (widget.readHistory == null) {
      await widget.repository.add(BookReadHistoryEntity(
          bookId: widget.bookId!,
          dateTimeFrom: _dateFromNotifier.value!,
          dateTimeTo: _dateToNotifier.value!,
          pageFrom: pageFrom,
          pageTo: pageTo));
    } else {
      await widget.repository.update(BookReadHistoryEntity(
          bookId: widget.readHistory!.bookId,
          dateTimeFrom: _dateFromNotifier.value!,
          dateTimeTo: _dateToNotifier.value!,
          pageFrom: pageFrom,
          pageTo: pageTo));
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            32,
            16,
            32 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Text(
                widget.readHistory == null
                    ? "Add Read History"
                    : "Edit Read History",
                style: TextTheme.of(context).titleLarge,
                textAlign: TextAlign.center,
              ),
              DateTimeFormField(
                controller: _dateFromNotifier,
                decoration: InputDecoration(
                  label: const Text("From Date Time"),
                  border: const OutlineInputBorder(),
                ),
                enabled: !_isSaving,
                validator: dateTimeIsNotEmptyValidator,
              ),
              DateTimeFormField(
                controller: _dateToNotifier,
                decoration: InputDecoration(
                  label: const Text("To Date Time"),
                  border: const OutlineInputBorder(),
                ),
                enabled: !_isSaving,
                validator: (DateTime? dateTime) {
                  final emptyValidator = dateTimeIsNotEmptyValidator(dateTime);
                  if (emptyValidator != null) return emptyValidator;
                  if (_dateFromNotifier.value == null) return null;
                  if (_dateFromNotifier.value!.millisecondsSinceEpoch >
                      dateTime!.millisecondsSinceEpoch) {
                    return "To Date Time must greater than From Date Time";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _pageFromEditingController,
                decoration: InputDecoration(
                  label: const Text("From Page"),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: stringIsPositiveNumberValidator,
                enabled: !_isSaving,
              ),
              TextFormField(
                controller: _pageToEditingController,
                decoration: InputDecoration(
                  label: const Text("To Page"),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: stringIsPositiveNumberValidator,
                enabled: !_isSaving,
              ),
              _extraError != null
                  ? Text(_extraError!,
                      style: TextTheme.of(context).bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ))
                  : Container(),
              FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _extraError = null;
                          });
                          if (_formKey.currentState!.validate()) {
                            if (int.parse(_pageFromEditingController.text) >
                                int.parse(_pageToEditingController.text)) {
                              setState(() {
                                _extraError =
                                    "From page must less than to page";
                              });
                              return;
                            }

                            _save();
                          }
                        },
                  child: Text(widget.readHistory == null ? "Add" : "Save"))
            ],
          ),
        ),
      ),
    );
  }
}

class TimerView extends StatefulWidget {
  final bool isStarted;
  final DateTime startTime;

  const TimerView(
      {super.key, required this.isStarted, required this.startTime});

  @override
  State<TimerView> createState() => _TimerView();
}

class _TimerView extends State<TimerView> {
  Timer? _timer;
  String _text = "00:00";

  @override
  void didUpdateWidget(covariant TimerView oldWidget) {
    if (oldWidget.isStarted != widget.isStarted) {
      if (!widget.isStarted) {
        _timer?.cancel();
        setState(() {
          _text = "00:00";
        });
      } else {
        final startTime = widget.startTime;
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          final duration = DateTime.now().difference(startTime);
          final second = duration.inSeconds;
          final shownSecond = second % Duration.secondsPerMinute;
          final minute = second ~/ Duration.secondsPerMinute;
          final shownMinute = minute % Duration.minutesPerHour;
          final hour = minute ~/ Duration.minutesPerHour;

          final minuteSecondStr =
              '${shownMinute.toString().padLeft(2, '0')}:${shownSecond.toString().padLeft(2, '0')}';

          setState(() {
            if (hour == 0) {
              _text = minuteSecondStr;
            } else {
              _text = '$hour:$minuteSecondStr';
            }
          });
        });
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: TextTheme.of(context).displayMedium,
    );
  }
}

class BookReadingTimerPage extends StatefulWidget {
  final BookReadHistoryRepository repository;
  final int bookId;

  const BookReadingTimerPage(
      {super.key, required this.repository, required this.bookId});

  static Future<void> show(BuildContext context, int bookId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookReadingTimerPage(
            repository: RepositoryProviderContext.of(context).readHistories,
            bookId: bookId),
      ),
    );
  }

  @override
  State<BookReadingTimerPage> createState() => _BookReadingTimerPage();
}

class _BookReadingTimerPage extends State<BookReadingTimerPage> {
  final TextEditingController _pageFromEditingController =
      TextEditingController();
  final TextEditingController _pageToEditingController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();
  String? _extraError;
  DateTime _timerStartTime = DateTime.now();
  bool _isSaving = false;
  bool _isStarted = false;

  @override
  void dispose() {
    _pageFromEditingController.dispose();
    _pageToEditingController.dispose();
    super.dispose();
  }

  _saveSession() async {
    setState(() {
      _isSaving = true;
    });

    final pageFrom = int.parse(_pageFromEditingController.text);
    final pageTo = int.parse(_pageToEditingController.text);

    await widget.repository.add(
      BookReadHistoryEntity(
        bookId: widget.bookId,
        dateTimeFrom: _timerStartTime,
        dateTimeTo: DateTime.now(),
        pageFrom: pageFrom,
        pageTo: pageTo,
      ),
    );

    setState(() {
      _isSaving = false;
      _isStarted = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session has been saved")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Reading Timer"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 16,
            children: [
              TextFormField(
                controller: _pageFromEditingController,
                validator: stringIsPositiveNumberValidator,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    label: Text("Page From"), border: OutlineInputBorder()),
              ),
              TextFormField(
                controller: _pageToEditingController,
                validator: stringIsPositiveNumberValidator,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    label: Text("Page To"), border: OutlineInputBorder()),
              ),
              _extraError != null
                  ? Text(_extraError!,
                      style: TextTheme.of(context).bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ))
                  : Container(),
              TimerView(
                isStarted: _isStarted,
                startTime: _timerStartTime,
              ),
              !_isStarted
                  ? FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _isStarted = true;
                          _timerStartTime = DateTime.now();
                        });
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start"),
                    )
                  : FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _extraError = "";
                              });
                              if (_formKey.currentState!.validate()) {
                                if (int.parse(_pageFromEditingController.text) >
                                    int.parse(_pageToEditingController.text)) {
                                  setState(() {
                                    _extraError =
                                        "From page must less than to page";
                                  });
                                  return;
                                }
                                _saveSession();
                              }
                            },
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop"),
                    )
            ],
          ),
        ),
      ),
    );
  }
}

class DateTimeFormField extends FormField<DateTime> {
  final ValueNotifier<DateTime?> controller;
  final InputDecoration decoration;

  DateTimeFormField({
    super.key,
    required this.controller,
    required this.decoration,
    super.validator,
    super.enabled,
  }) : super(
          builder: (FormFieldState<DateTime> field) {
            final state = field as _DateTimeFormField;
            return TextField(
              decoration: decoration.copyWith(
                errorText: state.errorText,
              ),
              controller: field._textController,
              readOnly: true,
              onTap: state._showPicker,
              enabled: enabled,
            );
          },
        );

  @override
  FormFieldState<DateTime> createState() => _DateTimeFormField();
}

class _DateTimeFormField extends FormFieldState<DateTime> {
  static final _dateFormatter = DateFormat("dd-MM-yyyy HH:mm");

  @override
  DateTimeFormField get widget => super.widget as DateTimeFormField;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    widget.controller.addListener(_handleControllerChange);
    setValue(widget.controller.value);
    _updateText(value);
    super.initState();
  }

  _showPicker() async {
    final initial = value ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.fromMillisecondsSinceEpoch(0),
      lastDate: DateTime.now(),
      initialDate: initial,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child ?? Container(),
          );
        });
    if (time == null) return;

    final dateTime = date.copyWith(hour: time.hour, minute: time.minute);
    didChange(dateTime);
    widget.controller.value = dateTime;
  }

  @override
  void didUpdateWidget(DateTimeFormField oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);

      didChange(widget.controller.value);
    }
    super.didUpdateWidget(oldWidget);
  }

  _updateText(DateTime? value) {
    final formatted = value == null ? "" : _dateFormatter.format(value);
    if (formatted != _textController.text) _textController.text = formatted;
  }

  @override
  void didChange(DateTime? value) {
    _updateText(value);
    super.didChange(value);
  }

  _handleControllerChange() {
    if (widget.controller.value != value) didChange(widget.controller.value);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _textController.dispose();
    super.dispose();
  }
}
