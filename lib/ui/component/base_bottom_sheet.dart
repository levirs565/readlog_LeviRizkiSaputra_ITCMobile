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

  BaseBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            32,
            16,
            32 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: child),
    );
  }
}
