
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readlog/ui/read_history_add_edit.dart';
import 'package:readlog/utils.dart';

import '../data.dart';
import '../data_context.dart';
import '../main.dart';

sealed class BookReadHistoryItem {
  const BookReadHistoryItem();
}

class BookReadHistoryDateItem extends BookReadHistoryItem {
  final DateTime date;

  const BookReadHistoryDateItem(this.date);
}

class BookReadHistorySessionItem extends BookReadHistoryItem {
  final BookReadHistoryEntity session;

  const BookReadHistorySessionItem(this.session);
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

class DateCirclePainter extends CustomPainter {
  final Color color;
  final double radius;
  final int position;

  DateCirclePainter(
      {required this.color, required this.radius, required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(size.center(Offset.zero), radius, Paint()..color = color);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4;
    if (position == -1) {
      canvas.drawLine(
          size.center(Offset.zero), size.bottomCenter(Offset.zero), linePaint);
    } else if (position == 0) {
      canvas.drawLine(size.topCenter(Offset.zero),
          size.bottomCenter(Offset.zero), linePaint);
    } else if (position == 1) {
      canvas.drawLine(
          size.topCenter(Offset.zero), size.center(Offset.zero), linePaint);
    }
  }

  @override
  bool shouldRepaint(DateCirclePainter oldDelegate) =>
      color != oldDelegate.color ||
          radius != oldDelegate.radius ||
          position != oldDelegate.position;
}

class _BookReadHistoriesPage extends State<BookReadHistoriesPage> {
  static final _dateFormatter = DateFormat("dd-MM-yyyy");
  static final _timeFormatter = DateFormat("HH:mm:ss");
  bool _isLoading = true;
  List<BookReadHistoryItem> _list = [];

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final sessionList = await widget.repository.getAllByBook(widget.bookId);

    List<BookReadHistoryItem> newList = [];

    DateTime? lastSessionDate;
    for (final session in sessionList) {
      if (session.dateTimeFrom.toDateOnly() != lastSessionDate) {
        newList.add(BookReadHistoryDateItem(session.dateTimeFrom.toDateOnly()));
      }

      newList.add(BookReadHistorySessionItem(session));

      lastSessionDate = session.dateTimeFrom.toDateOnly();
    }

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
      body: _list.isEmpty
          ? Center(
        child: Text("No read history yet",
            style: TextTheme.of(context).bodyLarge),
      )
          : ListView.builder(
        itemCount: _list.length,
        itemBuilder: (BuildContext context, int index) {
          int circlePositionParam = index == 0
              ? -1
              : index == _list.length - 1
              ? 1
              : 0;
          if (_list[index] is BookReadHistorySessionItem) {
            return _listTileSession(
                context,
                _list[index] as BookReadHistorySessionItem,
                circlePositionParam);
          }
          return _listTileDate(
              context,
              _list[index] as BookReadHistoryDateItem,
              circlePositionParam);
        },
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

  Widget _listTileDate(
      BuildContext context, BookReadHistoryDateItem item, int circlePosition) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: Size.fromWidth(48),
            painter: DateCirclePainter(
              color: Theme.of(context).colorScheme.primary,
              radius: 12,
              position: circlePosition,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(left: 8),
            child: Text(
              _dateFormatter.format(item.date),
              style: TextTheme.of(context).titleLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listTileSession(BuildContext context, BookReadHistorySessionItem item,
      int circlePosition) {
    final timeFrom = _timeFormatter.format(item.session.dateTimeFrom);
    final timeTo = _timeFormatter.format(item.session.dateTimeTo);
    final title = "$timeFrom - $timeTo";

    final durationSeconds =
        item.session.dateTimeTo.difference(item.session.dateTimeFrom).inSeconds;
    final showSecond = durationSeconds % Duration.secondsPerMinute;
    final minute = durationSeconds ~/ Duration.secondsPerMinute;
    final showMinute = minute % Duration.minutesPerHour;
    final hour = minute ~/ Duration.minutesPerHour;

    final duration = hour == 0 && minute == 0
        ? "$showSecond second"
        : hour == 0
        ? "$showMinute minute"
        : "$hour hour $showMinute minute";
    final readRange =
        "From page ${item.session.pageFrom} to page ${item.session.pageTo}";

    return InkWell(
      onTap: () async {
        final result = await BookHistoryActionSheet.show(context);
        if (result == null || !context.mounted) return;

        if (result == BookHistoryActionSheetResult.edit) {
          await BookAddEditHistorySheet.showEdit(context, item.session);
        } else if (result == BookHistoryActionSheetResult.delete) {
          final result = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete Confirmation"),
              content: const Text("Are you sure delete this reading session?"),
              actions: [
                TextButton(
                    style: TextButton.styleFrom(
                      textStyle: TextTheme.of(context).labelLarge,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text("Cancel")),
                TextButton(
                    style: TextButton.styleFrom(
                      textStyle: TextTheme.of(context).labelLarge,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text("OK"))
              ],
            ),
          );
          if (result == null || !result) return;

          await widget.repository.delete(item.session.id!);
        }
        if (!context.mounted) return;
        _refresh();
      },
      child: IntrinsicHeight(
        child: Row(
          children: [
            CustomPaint(
              size: Size.fromWidth(48),
              painter: DateCirclePainter(
                color: Theme.of(context).colorScheme.primary,
                radius: 8,
                position: circlePosition,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextTheme.of(context).titleMedium,
                  ),
                  Text(
                    duration,
                    style: TextTheme.of(context).bodyLarge,
                  ),
                  Text(
                    readRange,
                    style: TextTheme.of(context).bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BookHistoryActionSheetResult {
  edit,
  delete;
}

class BookHistoryActionSheet extends StatelessWidget {
  const BookHistoryActionSheet({super.key});

  static Future<BookHistoryActionSheetResult?> show(BuildContext context) {
    return showModalBottomSheet<BookHistoryActionSheetResult>(
      context: context,
      builder: (context) => BookHistoryActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    "Action",
                    style: TextTheme.of(context).titleLarge,
                  )),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit"),
                onTap: () => Navigator.of(context)
                    .pop(BookHistoryActionSheetResult.edit),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Remove"),
                onTap: () => Navigator.of(context)
                    .pop(BookHistoryActionSheetResult.delete),
              )
            ],
          ),
        )
      ],
    );
  }
}