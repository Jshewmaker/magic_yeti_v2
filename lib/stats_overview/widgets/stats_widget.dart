import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A widget that displays a stat with a title and value.
class StatsWidget extends StatelessWidget {
  const StatsWidget({
    required this.title,
    required this.stat,
    this.tooltip,
    super.key,
  });

  final String title;
  final String stat;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          width: 80,
          child: AutoSizeText(
            stat,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
        SizedBox(
          height: 50,
          width: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AutoSizeText(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
              ),
              if (tooltip != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: GestureDetector(
                    onTap: () => _showTooltip(context),
                    child: Icon(
                      Icons.info_outline,
                      size: 10,
                      color:
                          Colors.blueGrey.withAlpha(150),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTooltip(BuildContext context) {
    unawaited(showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title.replaceAll('\n', ' '),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Text(tooltip!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    ));
  }
}
