import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../data_context.dart';
import '../utils.dart';

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