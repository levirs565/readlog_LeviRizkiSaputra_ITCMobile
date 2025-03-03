import 'package:flutter/material.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/data/context.dart';
import 'package:readlog/ui/component/base_bottom_sheet.dart';
import 'package:readlog/ui/utils/dialog.dart';
import 'package:readlog/ui/utils/validator.dart';

class CollectionAddEditSheet extends StatefulWidget {
  final CollectionEntity? collection;

  const CollectionAddEditSheet._({super.key, this.collection});

  static Future<int?> showAdd(BuildContext context) {
    return BaseBottomSheet.showModal(
      context: context,
      builder: (context) => CollectionAddEditSheet._(),
    );
  }

  static Future<int?> showEdit(
      BuildContext context, CollectionEntity collection) {
    return BaseBottomSheet.showModal(
      context: context,
      builder: (context) => CollectionAddEditSheet._(
        collection: collection,
      ),
    );
  }

  @override
  State<CollectionAddEditSheet> createState() => _CollectionAddEditSheet();
}

class _CollectionAddEditSheet extends State<CollectionAddEditSheet> {
  final TextEditingController _nameEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    if (widget.collection != null) {
      _nameEditingController.text = widget.collection!.name;
    }
    super.initState();
  }

  @override
  void dispose() {
    _nameEditingController.dispose();
    super.dispose();
  }

  Future<bool> _popHandler(Object? result) async {
    if (result is int) return true;
    return showConfirmationDialog(
      context: context,
      title: const Text("Close"),
      content: const Text("Are you sure discarding your changed"),
    );
  }

  _save() async {
    setState(() {
      _isSaving = true;
    });

    final repository = RepositoryProviderContext.get(context).collections;
    int? result = widget.collection?.id;

    if (widget.collection == null) {
      result = await repository.add(
        CollectionEntity(
          name: _nameEditingController.text,
        ),
      );
    } else {
      await repository.update(
        CollectionEntity(
          id: widget.collection!.id!,
          name: _nameEditingController.text,
        ),
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop(result);
  }

  _trySave() {
    if (_formKey.currentState!.validate()) {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      popHandler: _popHandler,
      child: Form(
        key: _formKey,
        child: _formContent(context),
      ),
    );
  }

  Widget _formContent(BuildContext context) {
    return Column(
      spacing: 16.0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.collection == null ? "Add Collection" : "Edit Collection",
          style: TextTheme.of(context).titleLarge,
          textAlign: TextAlign.center,
        ),
        TextFormField(
          controller: _nameEditingController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            label: const Text("Title"),
          ),
          validator: stringNotEmptyValidator,
          enabled: !_isSaving,
        ),
        FilledButton(
          onPressed: _isSaving ? null : _trySave,
          child: Text(
            widget.collection == null ? "Add" : "Save",
          ),
        )
      ],
    );
  }
}
