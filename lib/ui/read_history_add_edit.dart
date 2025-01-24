import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../data_context.dart';
import '../utils.dart';
import 'component/date_time_field.dart';

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