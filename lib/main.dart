import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/data_impl.dart';

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
            await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => BookOverviewPage(id: _list[index].id!)));
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
  final int id;

  const BookOverviewPage({super.key, required this.id});

  @override
  State<BookOverviewPage> createState() => _BookOverviewPage();
}

class _BookOverviewPage extends State<BookOverviewPage> {
  late BookRepository _repository;
  bool _isLoading = true;
  BookEntity? _book = null;

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

    final book = await _repository.getById(widget.id);

    setState(() {
      _isLoading = false;
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
              ],
            ),
    );
  }
}
