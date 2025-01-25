import 'package:flutter/material.dart';

class BaseBottomSheet extends StatelessWidget {
  static Future<T?> showModal<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet(
        context: context, builder: builder, isScrollControlled: true);
  }

  Widget child;
  bool scrollable;

  BaseBottomSheet({super.key, required this.child, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        32,
        16,
        32 + MediaQuery
            .of(context)
            .viewInsets
            .bottom,
      ),
      child: child,);
    if (scrollable) {
      return SingleChildScrollView(
        child: inner,
      );
    }
    return inner;
  }
}
