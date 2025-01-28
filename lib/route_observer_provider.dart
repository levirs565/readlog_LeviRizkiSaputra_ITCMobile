import 'package:flutter/material.dart';

class RouteObserverProvider extends InheritedWidget {
  final RouteObserver observer;

  const RouteObserverProvider({super.key, required this.observer, required super.child});

  static RouteObserver of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<RouteObserverProvider>();
    assert(result != null, "No RouteObserverProvider found");
    return result!.observer;
  }

  @override
  bool updateShouldNotify(RouteObserverProvider oldWidget) => oldWidget.observer != observer;


}