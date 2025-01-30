import 'package:flutter/material.dart';

class BaseBottomSheet extends StatelessWidget {
  static Future<T?> showModal<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: builder,
      isScrollControlled: true,
      // https://github.com/flutter/flutter/issues/152120
      enableDrag: false
    );
  }

  final Widget child;
  final bool scrollable;
  final Future<bool> Function(Object?)? popHandler;

  const BaseBottomSheet({
    super.key,
    required this.child,
    this.scrollable = true,
    this.popHandler,
  });

  @override
  Widget build(BuildContext context) {
    final inner = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canPop = await (popHandler?.call(result) ?? Future.value(true));
        if (canPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              32,
              16,
              32 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: child,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.close),
                )
              ],
            ),
          )
        ],
      ),
    );
    if (scrollable) {
      return SingleChildScrollView(
        child: inner,
      );
    }
    return inner;
  }
}
