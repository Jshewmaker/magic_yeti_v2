import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A widget that displays a stat with a title and value.
class StatsWidget extends StatelessWidget {
  const StatsWidget({
    required this.title,
    required this.stat,
    super.key,
  });

  final String title;
  final String stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          width: 50,
          child: AutoSizeText(
            stat,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
