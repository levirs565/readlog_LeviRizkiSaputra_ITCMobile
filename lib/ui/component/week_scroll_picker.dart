import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils.dart';

mixin _ScrollPicker {
  late final ScrollController _scrollController;

  void _initScrollController() {
    _scrollController = ScrollController(
      onAttach: _onScrollControllerAttach,
    );
  }

  void _disposeScrollContainer() {
    _scrollController.dispose();
  }

  _onScrollControllerAttach(ScrollPosition position) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients ||
          !_scrollController.position.hasPixels) {
        return;
      }
      _scrollController.jumpTo(_getScrollOffset());
    });
  }

  int _getSelectedIndex();

  double get _itemHeight;

  double _getScrollOffset() {
    int index = _getSelectedIndex();

    final inStartOffset = _itemHeight * index;
    if (_scrollController.hasClients &&
        _scrollController.position.hasViewportDimension) {
      final inCenterOffset = inStartOffset -
          _scrollController.position.viewportDimension / 2 +
          _itemHeight / 2;
      return inCenterOffset;
    }

    return inStartOffset;
  }

  _updateScroll() {
    _scrollController.animateTo(
      _getScrollOffset(),
      duration: Duration(milliseconds: 500),
      curve: Easing.standard,
    );
  }
}

class _ScrollPickerItem extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final double height;
  final Widget child;
  final bool isSelected;
  final void Function() onSelect;

  const _ScrollPickerItem({
    super.key,
    required this.padding,
    required this.height,
    required this.isSelected,
    required this.onSelect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.all(Radius.circular(16));
    return Padding(
      padding: padding,
      child: Material(
        color: Color.fromARGB(0, 0, 0, 0),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: borderRadius),
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class YearScrollPicker extends StatefulWidget {
  final int min;
  final int max;
  final int selected;
  final void Function(int year) onSelect;

  const YearScrollPicker({
    super.key,
    required this.min,
    required this.max,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<YearScrollPicker> createState() => _YearScrollPicker();
}

class _YearScrollPicker extends State<YearScrollPicker> with _ScrollPicker {
  @override
  int _getSelectedIndex() => widget.selected - widget.min;

  @override
  double get _itemHeight => 48 + 8 + 8;

  _YearScrollPicker() {
    _initScrollController();
  }

  @override
  void dispose() {
    _disposeScrollContainer();
    super.dispose();
  }

  @override
  void didUpdateWidget(YearScrollPicker oldWidget) {
    if (oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.selected != widget.selected) {
      _updateScroll();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemBuilder: _item,
      itemCount: widget.max - widget.min + 1,
    );
  }

  Widget _item(BuildContext context, int index) {
    int year = widget.min + index;
    return _ScrollPickerItem(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      height: 48,
      isSelected: widget.selected == year,
      onSelect: () {
        widget.onSelect(year);
      },
      child: Text(
        year.toString(),
        style: TextTheme.of(context).titleMedium,
      ),
    );
  }
}

class MonthScrollPicker extends StatefulWidget {
  final int max;
  final int selected;
  final void Function(int value) onSelect;

  const MonthScrollPicker({
    super.key,
    required this.max,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<MonthScrollPicker> createState() => _MonthScrollPicker();
}

class _MonthScrollPicker extends State<MonthScrollPicker> with _ScrollPicker {
  static final _monthNames = DateFormat().dateSymbols.MONTHS;

  @override
  int _getSelectedIndex() => widget.selected - 1;

  @override
  double get _itemHeight => 48 + 8 + 8;

  _MonthScrollPicker() {
    _initScrollController();
  }

  @override
  void dispose() {
    _disposeScrollContainer();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MonthScrollPicker oldWidget) {
    if (widget.selected != oldWidget.selected || widget.max != oldWidget.max) {
      _updateScroll();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemBuilder: _item,
      itemCount: widget.max,
    );
  }

  Widget _item(BuildContext context, int index) {
    int month = index + 1;
    return _ScrollPickerItem(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      height: 48,
      isSelected: widget.selected == month,
      onSelect: () {
        widget.onSelect(month);
      },
      child: Text(
        _monthNames[index],
        style: TextTheme.of(context).titleMedium,
      ),
    );
  }
}

class WeekScrollPicker extends StatefulWidget {
  final int max;
  final int selected;
  final void Function(int value) onSelect;

  const WeekScrollPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.max,
  });

  @override
  State<WeekScrollPicker> createState() => _WeekScrollPicker();
}

class _WeekScrollPicker extends State<WeekScrollPicker> with _ScrollPicker {
  @override
  int _getSelectedIndex() => widget.selected - 1;

  @override
  double get _itemHeight => 48 + 8 + 8;

  _WeekScrollPicker() {
    _initScrollController();
  }

  @override
  void dispose() {
    _disposeScrollContainer();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeekScrollPicker oldWidget) {
    if (widget.selected != oldWidget.selected || widget.max != oldWidget.max) {
      _updateScroll();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemBuilder: _item,
      itemCount: widget.max,
    );
  }

  Widget _item(BuildContext context, int index) {
    int week = index + 1;
    return _ScrollPickerItem(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      height: 48,
      isSelected: widget.selected == week,
      onSelect: () {
        widget.onSelect(week);
      },
      child: Text(
        "Week $week",
        style: TextTheme.of(context).titleMedium,
      ),
    );
  }
}

class WeekScrollPickerDialog extends StatefulWidget {
  final WeekDate initial;

  const WeekScrollPickerDialog({super.key, required this.initial});

  static Future<WeekDate?> show({required BuildContext context, required WeekDate initial}) {
    return showDialog<WeekDate>(
      context: context,
      builder: (context) => WeekScrollPickerDialog(
        initial: initial
      ),
    );
  }

  @override
  State<WeekScrollPickerDialog> createState() => _WeekScrollPickerDialog();
}

class _WeekScrollPickerDialog extends State<WeekScrollPickerDialog> {
  int _selectedYear = 0;
  int _selectedMonth = 0;
  int _maxMonth = 0;
  int _selectedWeek = 0;
  int _maxWeek = 0;
  final _now = DateTime.now();

  @override
  void initState() {
    _setWeek(widget.initial.week);
    _setMonth(widget.initial.month);
    _setYear(widget.initial.year);
    super.initState();
  }

  _setYear(int year) {
    _selectedYear = year;
    _maxMonth = _now.year == _selectedYear ? _now.month : 12;
    _setMonth(_selectedMonth > _maxMonth ? _maxMonth : _selectedMonth);
  }

  _setMonth(int month) {
    _selectedMonth = month;
    final dayCount = _now.year == _selectedYear && _now.month == _selectedMonth
        ? _now.day
        : DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    _maxWeek = getWeekByDay(dayCount);
    _setWeek(_selectedWeek > _maxWeek ? _maxWeek : _selectedWeek);
  }

  _setWeek(int week) {
    _selectedWeek = week;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Week"),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 320),
        child: SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                "Week $_selectedWeek, ${_MonthScrollPicker._monthNames[_selectedMonth - 1]}, $_selectedYear",
                style: TextTheme.of(context).bodyLarge,
              ),
              Expanded(
                child: Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: YearScrollPicker(
                        min: 1970,
                        max: _now.year,
                        selected: _selectedYear,
                        onSelect: (year) {
                          setState(() {
                            _setYear(year);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: MonthScrollPicker(
                        max: _maxMonth,
                        selected: _selectedMonth,
                        onSelect: (month) {
                          setState(() {
                            _setMonth(month);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: WeekScrollPicker(
                        selected: _selectedWeek,
                        max: _maxWeek,
                        onSelect: (week) {
                          setState(() {
                            _setWeek(week);
                          });
                        },
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            style: TextButton.styleFrom(
              textStyle: TextTheme.of(context).labelLarge,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel")),
        TextButton(
            style: TextButton.styleFrom(
              textStyle: TextTheme.of(context).labelLarge,
            ),
            onPressed: () {
              Navigator.of(context).pop(
                WeekDate(
                  year: _selectedYear,
                  month: _selectedMonth,
                  week: _selectedWeek,
                ),
              );
            },
            child: Text("OK"))
      ],
    );
  }
}
