import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/utils/date_time.dart';

sealed class ReadHistoryTimelineItem {
  const ReadHistoryTimelineItem();
}

class ReadHistoryTimelineDateItem extends ReadHistoryTimelineItem {
  final DateTime date;

  const ReadHistoryTimelineDateItem(this.date);
}

class ReadHistoryTimelineSessionItem extends ReadHistoryTimelineItem {
  final BookReadHistoryEntity session;

  const ReadHistoryTimelineSessionItem(this.session);
}

class ReadHistoryTimeline extends StatelessWidget {
  static final _dateFormatter = DateFormat("dd-MM-yyyy");
  static final _timeFormatter = DateFormat("HH:mm:ss");

  static List<ReadHistoryTimelineItem> buildItems(
      List<BookReadHistoryEntity> sessionList) {
    List<ReadHistoryTimelineItem> newList = [];

    DateTime? lastSessionDate;
    for (final session in sessionList) {
      if (session.dateTimeFrom.toDateOnly() != lastSessionDate) {
        newList.add(
            ReadHistoryTimelineDateItem(session.dateTimeFrom.toDateOnly()));
      }

      newList.add(ReadHistoryTimelineSessionItem(session));

      lastSessionDate = session.dateTimeFrom.toDateOnly();
    }

    return newList;
  }

  final List<ReadHistoryTimelineItem> items;
  final void Function(BookReadHistoryEntity item) onSelected;

  const ReadHistoryTimeline({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        int circlePositionParam = index == 0
            ? -1
            : index == items.length - 1
                ? 1
                : 0;
        if (items[index] is ReadHistoryTimelineSessionItem) {
          return _listTileSession(
              context,
              items[index] as ReadHistoryTimelineSessionItem,
              circlePositionParam);
        }
        return _listTileDate(context,
            items[index] as ReadHistoryTimelineDateItem, circlePositionParam);
      },
    );
  }

  Widget _listTileDate(
    BuildContext context,
    ReadHistoryTimelineDateItem item,
    int circlePosition,
  ) {
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

  Widget _listTileSession(BuildContext context,
      ReadHistoryTimelineSessionItem item, int circlePosition) {
    final timeFrom = _timeFormatter.format(item.session.dateTimeFrom);
    final timeTo = _timeFormatter.format(item.session.dateTimeTo);
    final title = "$timeFrom - $timeTo";

    final parsedDuration = ParsedDuration.fromDuration(
      item.session.dateTimeTo.difference(item.session.dateTimeFrom),
    );
    final duration = parsedDuration.toShortFormattedString();
    final readRange =
        "From page ${item.session.pageFrom} to page ${item.session.pageTo}";

    return InkWell(
      onTap: () => onSelected(item.session),
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
