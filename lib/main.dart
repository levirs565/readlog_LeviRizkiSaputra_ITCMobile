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
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  List<BookEntity> _list = [];
  late BookRepository _repository;

  @override
  void didChangeDependencies() {
    _repository = RepositoryProviderContext.of(context).books;
    _refresh();
    super.didChangeDependencies();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final newList = await _repository.getAll();

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
      body: ListView.builder(
        itemCount: _list.length,
        itemBuilder: _listTile,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddEditPage(
                    repository: RepositoryProviderContext.of(context).books,
                  )));
          if (!mounted) return;
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _listTile(BuildContext context, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        InkWell(
          onTap: () async {
            await BookOverviewPage.show(context, _list[index].id!);
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
                  _list[index].title,
                  style: TextTheme.of(context).bodyLarge,
                ),
                Text(
                  _list[index].pageCount.toString(),
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

class AddEditPage extends StatefulWidget {
  final int? id;
  final BookRepository repository;

  const AddEditPage({super.key, this.id, required this.repository});

  @override
  State<AddEditPage> createState() => _AddEditPage();
}

class _AddEditPage extends State<AddEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleEditingController = TextEditingController();
  final _pageCountEditingController = TextEditingController();
  bool _isSaving = false;

  _loadData() async {
    if (widget.id == null) return;
    final book = await widget.repository.getById(widget.id!);
    if (book == null) return;
    _titleEditingController.text = book.title;
    _pageCountEditingController.text = book.pageCount.toString();
  }

  @override
  void initState() {
    _loadData();
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
        id: widget.id,
        title: _titleEditingController.text,
        pageCount: int.parse(_pageCountEditingController.text),
        readedPageCount: 0);

    try {
      if (widget.id == null) {
        await widget.repository.add(entity);
      } else {
        await widget.repository.update(entity);
      }
      if (mounted) {
        Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.id == null ? "Add Book" : "Edit Book"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            spacing: 16.0,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleEditingController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: const Text("Title"),
                ),
                validator: (value) => value == null || value.trim().isNotEmpty
                    ? null
                    : "Cannot blank",
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
                validator: (value) => value == null || value.trim().isNotEmpty
                    ? null
                    : "Cannot blank",
                enabled: !_isSaving,
              ),
              Spacer(),
              FilledButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _save();
                        }
                      },
                child: Text(
                  widget.id == null ? "Add" : "Save",
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
  void didChangeDependencies() {
    _refresh();
    super.didChangeDependencies();
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
    final readPercentage = _book != null
        ? _book!.readedPageCount.toDouble() / _book!.pageCount.toDouble()
        : 0.toDouble();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: _isLoading ? LinearProgressIndicator() : Container()),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AddEditPage(
                        id: widget.id,
                        repository: RepositoryProviderContext.of(context).books,
                      )));
              if (mounted) {
                _refresh();
              }
            },
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
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
                Container(
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _book!.title,
                        style: TextTheme.of(context).titleLarge,
                      ),
                      Text(
                          "${_book!.readedPageCount} of ${_book!.pageCount} pages read"),
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
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text("Read History",
                          style: TextTheme.of(context).titleMedium),
                      Text(_lastRead == null
                          ? "No read history yet"
                          : "Last read from page ${_lastRead!.pageFrom} to page ${_lastRead!.pageTo} at ${_dateFormatter.format(_lastRead!.date)}"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 8,
                        children: [
                          FilledButton(
                              onPressed: () async {
                                await BookAddEditHistorySheet.showAdd(
                                    context, widget.id);
                                if (!mounted) return;
                                _refresh();
                              },
                              child: const Text("Add")),
                          FilledButton(
                              onPressed: () async {
                                await BookReadHistoriesPage.show(
                                    context, widget.id);
                                if (!mounted) return;
                                _refresh();
                              },
                              child: const Text("Show All"))
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
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
                        child: Text(
                            "Add Read History to update Reading Progress",
                            textAlign: TextAlign.left,
                            style: TextTheme.of(context).bodySmall),
                      ),
                      ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _readingProgress.length,
                          padding: EdgeInsets.all(0),
                          itemBuilder: (context, index) => Container(
                              color: _readingProgress[index].hasRead
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                              padding: EdgeInsets.symmetric(
                                  vertical: 8 +
                                      ((_readingProgress[index].pageTo -
                                              _readingProgress[index].pageFrom +
                                              1) /
                                          8),
                                  horizontal: 16),
                              child: Column(children: [
                                Text(
                                  "From page ${_readingProgress[index].pageFrom} to ${_readingProgress[index].pageTo}",
                                  style: TextTheme.of(context).bodyMedium,
                                ),
                                Text(_readingProgress[index].hasRead
                                    ? "Has been read"
                                    : "Unread")
                              ])))
                    ],
                  ),
                )
              ],
            )),
    );
  }
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

class _BookReadHistoriesPage extends State<BookReadHistoriesPage> {
  static final _dateFormatter = DateFormat("dd-MM-yyyy HH:mm");
  bool _isLoading = true;
  List<BookReadHistoryEntity> _list = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final newList = await widget.repository.getAllByBook(widget.bookId);
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
      body: ListView.builder(
        itemCount: _list.length,
        itemBuilder: _listTile,
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

  Widget _listTile(BuildContext context, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "From page ${_list[index].pageFrom} to page ${_list[index].pageTo}",
                style: TextTheme.of(context).bodyLarge,
              ),
              Text(
                _dateFormatter.format(_list[index].date),
                style: TextTheme.of(context).bodyMedium,
              )
            ],
          ),
        ),
        Divider(
          height: 1,
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
        builder: (context) => BookAddEditHistorySheet(
              bookId: bookId,
              repository: RepositoryProviderContext.of(context).readHistories,
            ));
  }

  static Future<void> showEdit(
      BuildContext context, BookReadHistoryEntity readHistory) {
    return showModalBottomSheet(
        context: context,
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
  bool _isLoading = false;
  String? _extraError = null;
  final TextEditingController _pageFromEditingController =
      TextEditingController();
  final TextEditingController _pageToEditingController =
      TextEditingController();

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    final pageFrom = int.parse(_pageFromEditingController.text);
    final pageTo = int.parse(_pageToEditingController.text);
    if (widget.readHistory == null) {
      await widget.repository.add(BookReadHistoryEntity(
          bookId: widget.bookId!,
          date: DateTime.now(),
          pageFrom: pageFrom,
          pageTo: pageTo));
    } else {
      await widget.repository.update(BookReadHistoryEntity(
          bookId: widget.readHistory!.bookId,
          date: widget.readHistory!.date,
          pageFrom: pageFrom,
          pageTo: pageTo));
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(children: [
      Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 32, 16, 48),
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
              TextFormField(
                controller: _pageFromEditingController,
                decoration: InputDecoration(
                  label: const Text("From Page"),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value == null || value.trim().isNotEmpty
                    ? null
                    : "Cannot blank",
              ),
              TextFormField(
                controller: _pageToEditingController,
                decoration: InputDecoration(
                  label: const Text("To Page"),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value == null || value.trim().isNotEmpty
                    ? null
                    : "Cannot blank",
              ),
              _extraError != null
                  ? Text(_extraError!,
                      style: TextTheme.of(context).bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ))
                  : Container(),
              FilledButton(
                  onPressed: () {
                    setState(() {
                      _extraError = null;
                    });
                    if (_formKey.currentState!.validate()) {
                      if (int.parse(_pageFromEditingController.text) >
                          int.parse(_pageToEditingController.text)) {
                        setState(() {
                          _extraError = "From page must less than to page";
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
      )
    ]);
  }
}
