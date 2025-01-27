import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
          !_scrollController.position.hasPixels) return;
      _scrollController.jumpTo(_getScrollOffset());
    });
  }

  int _getSelectedIndex();

  double get _itemWidth;

  double _getScrollOffset() {
    int index = _getSelectedIndex();

    final inStartOffset = _itemWidth * index;
    if (_scrollController.hasClients &&
        _scrollController.position.hasViewportDimension) {
      final inCenterOffset = inStartOffset -
          _scrollController.position.viewportDimension / 2 +
          _itemWidth / 2;
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
  final double width;
  final Widget child;
  final bool isSelected;
  final void Function() onSelect;

  const _ScrollPickerItem({
    super.key,
    required this.padding,
    required this.width,
    required this.isSelected,
    required this.onSelect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.all(Radius.circular(16));
    return Padding(
      padding: padding,
      child: Ink(
        width: width,
        decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: borderRadius),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onSelect,
          child: Center(
            child: child,
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
  double get _itemWidth => 96 + 8 + 8;

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
    return SizedBox(
      height: 48,
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollController,
        itemBuilder: _item,
        itemCount: widget.max - widget.min + 1,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    int year = widget.min + index;
    return _ScrollPickerItem(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      width: 96,
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
  final int selected;
  final void Function(int value) onSelect;

  const MonthScrollPicker({
    super.key,
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
  double get _itemWidth => 128 + 8 + 8;

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
    if (widget.selected != oldWidget.selected) {
      _updateScroll();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollController,
        itemBuilder: _item,
        itemCount: 12,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    int month = index + 1;
    return _ScrollPickerItem(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      width: 128,
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
  double get _itemWidth => 128 + 8 + 8;

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
    if (widget.selected != oldWidget.selected || widget.max != oldWidget.max ) {
      _updateScroll();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollController,
        itemBuilder: _item,
        itemCount: widget.max,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    int week = index + 1;
    return _ScrollPickerItem(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      width: 128,
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
