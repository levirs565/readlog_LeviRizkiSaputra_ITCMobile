import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../data_context.dart';
import '../utils.dart';
import 'component/conditional_widget.dart';

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
          final duration =
              ParsedDuration.fromDuration(DateTime.now().difference(startTime));

          final minuteSecondStr =
              '${duration.minute.toString().padLeft(2, '0')}:${duration.second.toString().padLeft(2, '0')}';

          setState(() {
            if (duration.hour == 0) {
              _text = minuteSecondStr;
            } else {
              _text = '${duration.hour}:$minuteSecondStr';
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
  final int bookId;

  const BookReadingTimerPage({
    super.key,
    required this.bookId,
  });

  static Future<void> show(BuildContext context, int bookId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookReadingTimerPage(bookId: bookId),
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

  int get _pageFrom => int.parse(_pageFromEditingController.text);

  int get _pageTo => int.parse(_pageToEditingController.text);

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

    final repository = RepositoryProviderContext.get(context).readHistories;
    await repository.add(
      BookReadHistoryEntity(
        bookId: widget.bookId,
        dateTimeFrom: _timerStartTime,
        dateTimeTo: DateTime.now(),
        pageFrom: _pageFrom,
        pageTo: _pageTo,
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

  _trySave() {
    setState(() {
      _extraError = "";
    });
    if (_formKey.currentState!.validate()) {
      if (_pageFrom > _pageTo) {
        setState(() {
          _extraError = "From page must less than to page";
        });
        return;
      }
      _saveSession();
    }
  }

  _startTimer() {
    setState(() {
      _isStarted = true;
      _timerStartTime = DateTime.now();
    });
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
          child: _formContent(context),
        ),
      ),
    );
  }

  Widget _formContent(BuildContext context) {
    return Column(
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
            label: Text("Page From"),
            border: OutlineInputBorder(),
          ),
        ),
        TextFormField(
          controller: _pageToEditingController,
          validator: stringIsPositiveNumberValidator,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            label: Text("Page To"),
            border: OutlineInputBorder(),
          ),
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
        TimerView(
          isStarted: _isStarted,
          startTime: _timerStartTime,
        ),
        !_isStarted
            ? FilledButton.icon(
                onPressed: _startTimer,
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start"),
              )
            : FilledButton.icon(
                onPressed: _isSaving ? null : _trySave,
                icon: const Icon(Icons.stop),
                label: const Text("Stop"),
              )
      ],
    );
  }
}
