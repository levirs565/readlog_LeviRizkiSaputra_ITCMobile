import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readlog/ui/component/base_bottom_sheet.dart';
import 'package:readlog/ui/component/conditional_widget.dart';
import 'package:readlog/data.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/utils.dart';
import 'package:readlog/ui/component/date_time_field.dart';

class BookAddEditHistorySheet extends StatefulWidget {
  final int? bookId;
  final BookReadHistoryEntity? readHistory;

  const BookAddEditHistorySheet._({super.key, this.bookId, this.readHistory});

  static Future<void> showAdd(BuildContext context, int bookId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BookAddEditHistorySheet._(
        bookId: bookId,
      ),
    );
  }

  static Future<void> showEdit(
      BuildContext context, BookReadHistoryEntity readHistory) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BookAddEditHistorySheet._(
        readHistory: readHistory,
      ),
    );
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

  int get _pageFrom => int.parse(_pageFromEditingController.text);

  int get _pageTo => int.parse(_pageToEditingController.text);

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

    final repository = RepositoryProviderContext.get(context).readHistories;
    if (widget.readHistory == null) {
      await repository.add(BookReadHistoryEntity(
          bookId: widget.bookId!,
          dateTimeFrom: _dateFromNotifier.value!,
          dateTimeTo: _dateToNotifier.value!,
          pageFrom: _pageFrom,
          pageTo: _pageTo));
    } else {
      await repository.update(BookReadHistoryEntity(
          id: widget.readHistory!.id,
          bookId: widget.readHistory!.bookId,
          dateTimeFrom: _dateFromNotifier.value!,
          dateTimeTo: _dateToNotifier.value!,
          pageFrom: _pageFrom,
          pageTo: _pageTo));
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  _trySave() {
    setState(() {
      _extraError = null;
    });
    if (_formKey.currentState!.validate()) {
      if (_pageFrom > _pageTo) {
        setState(() {
          _extraError = "From page must less than to page";
        });
        return;
      }

      _save();
    }
  }

  String? _validateToDateTime(DateTime? dateTime) {
    final emptyValidator = dateTimeIsNotEmptyValidator(dateTime);
    if (emptyValidator != null) return emptyValidator;
    if (_dateFromNotifier.value == null) return null;
    if (_dateFromNotifier.value!.millisecondsSinceEpoch >
        dateTime!.millisecondsSinceEpoch) {
      return "To Date Time must greater than From Date Time";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      child: Form(
        key: _formKey,
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
              validator: _validateToDateTime,
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
            ConditionalWidget(
              isLoading: false,
              isEmpty: _extraError == null,
              contentBuilder: (context) => Text(
                _extraError!,
                style: TextTheme.of(context).bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
            FilledButton(
                onPressed: _isSaving ? null : _trySave,
                child: Text(widget.readHistory == null ? "Add" : "Save"))
          ],
        ),
      ),
    );
  }
}
