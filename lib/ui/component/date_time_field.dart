import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
