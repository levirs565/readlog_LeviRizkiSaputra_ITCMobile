import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readlog/ui/page/collections_select.dart';
import 'package:readlog/ui/component/base_bottom_sheet.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/data/context.dart';
import 'package:readlog/utils.dart';

class BookAddEditSheet extends StatefulWidget {
  final BookEntity? book;
  final List<CollectionEntity>? collections;

  const BookAddEditSheet._({super.key, this.book, this.collections});

  static Future<int?> showAdd(BuildContext context,
      {List<CollectionEntity>? collections}) {
    return BaseBottomSheet.showModal(
      context: context,
      builder: (context) => BookAddEditSheet._(
        collections: collections,
      ),
    );
  }

  static Future<int?> showEdit(BuildContext context, BookDetailEntity book) {
    return BaseBottomSheet.showModal(
      context: context,
      builder: (context) => BookAddEditSheet._(
        book: book,
        collections: book.collections,
      ),
    );
  }

  @override
  State<BookAddEditSheet> createState() => _BookAddEditSheet();
}

class _BookAddEditSheet extends State<BookAddEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleEditingController = TextEditingController();
  final _pageCountEditingController = TextEditingController();
  List<CollectionEntity> _collections = [];
  bool _isSaving = false;

  @override
  void initState() {
    if (widget.book != null) {
      _titleEditingController.text = widget.book!.title;
      _pageCountEditingController.text = widget.book!.pageCount.toString();
    }
    if (widget.collections != null) {
      _collections = widget.collections!.map((el) => el.copy()).toList();
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

    final entity = BookDetailEntity(
      book: BookEntity(
        id: widget.book?.id,
        title: _titleEditingController.text,
        pageCount: int.parse(_pageCountEditingController.text),
        readedPageCount: 0,
      ),
      collections: _collections,
    );
    final repository = RepositoryProviderContext.get(context).books;

    try {
      int? result = entity.id;
      if (widget.book?.id == null) {
        result = await repository.add(entity);
      } else {
        await repository.update(entity);
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
    return BaseBottomSheet(
      child: Form(
        key: _formKey,
        child: _formContent(context),
      ),
    );
  }

  _trySave() {
    if (_formKey.currentState!.validate()) {
      _save();
    }
  }

  Widget _formContent(BuildContext context) {
    return Column(
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
        _collectionField(context),
        FilledButton(
          onPressed: _isSaving ? null : _trySave,
          child: Text(
            widget.book == null ? "Add" : "Save",
          ),
        )
      ],
    );
  }

  _editCollections() async {
    final result = await CollectionsSelectSheet.show(context, _collections);
    if (result == null) return;
    setState(() {
      _collections = result;
    });
  }

  Widget _collectionField(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : _editCollections,
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          label: const Text("Collections"),
          contentPadding: EdgeInsets.all(8),
        ),
        isEmpty: _collections.isEmpty,
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _collections.map((collection) {
            return Chip(label: Text(collection.name));
          }).toList(),
        ),
      ),
    );
  }
}
