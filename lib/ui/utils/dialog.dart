import 'package:flutter/material.dart';

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
}) async {
  final result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: title,
      content: content,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            textStyle: TextTheme.of(context).labelLarge,
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text("Cancel"),
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: TextTheme.of(context).labelLarge,
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text("OK"),
        )
      ],
    ),
  );

  return result ?? false;
}
