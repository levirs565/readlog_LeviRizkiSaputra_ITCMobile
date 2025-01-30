import 'package:flutter/material.dart';

class ReadingProgressCircular extends StatelessWidget {
  final double value;

  const ReadingProgressCircular({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              "${(value * 100).round()}%",
              style: TextTheme.of(context).titleMedium!.copyWith(
                  fontFamily: "Roboto Condensed",
                  fontWeight: FontWeight.w700
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: value,
              ),
            ),
          )
        ],
      ),
    );
  }

}