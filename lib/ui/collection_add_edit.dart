import 'package:flutter/material.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/ui/component/base_bottom_sheet.dart';

import '../utils.dart';

class CollectionAddEditSheet extends StatefulWidget {
  final CollectionEntity? collection;

  const CollectionAddEditSheet._({super.key, this.collection});

  static Future<int?> showAdd(BuildContext context) {
    return BaseBottomSheet.showModal(
      context: context,
      builder: (context) => CollectionAddEditSheet._(),
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
  void dispose() {
    _nameEditingController.dispose();
    super.dispose();
  }

  _save() async {
    setState(() {
      _isSaving = true;
    });

    final repository = RepositoryProviderContext.get(context).collections;
    int? result = null;

    if (widget.collection == null) {
      result = await repository.add(
        CollectionEntity(
          name: _nameEditingController.text,
        ),
      );
    } else {
      await repository.update(
        CollectionEntity(
          name: _nameEditingController.text,
        ),
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      child: Form(
        key: _formKey,
        child: Column(
          spacing: 16.0,
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
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _save();
                      }
                    },
              child: Text(
                widget.collection == null ? "Add" : "Save",
              ),
            )
          ],
        ),
      ),
    );
  }
}
