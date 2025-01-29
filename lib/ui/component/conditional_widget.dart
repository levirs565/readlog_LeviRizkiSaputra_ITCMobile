import 'package:flutter/material.dart';

class ConditionalWidget extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder contentBuilder;

  const ConditionalWidget({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    this.loadingBuilder,
    this.emptyBuilder,
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingBuilder != null ? loadingBuilder!(context) : Container();
    }
    if (isEmpty) {
      return emptyBuilder != null ? emptyBuilder!(context) : Container();
    }
    return contentBuilder(context);
  }
}
