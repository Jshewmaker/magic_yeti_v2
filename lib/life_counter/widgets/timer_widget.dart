import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late Stopwatch stopwatch;
  late Timer t;

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    stopwatch.start();
    t = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {});
    });
  }

  String returnFormattedText() {
    final milli = stopwatch.elapsed.inMilliseconds;

    final seconds = ((milli ~/ 1000) % 60)
        .toString()
        .padLeft(2, '0'); // this is for the second
    final minutes = ((milli ~/ 1000) ~/ 60)
        .toString()
        .padLeft(2, '0'); // this is for the minute

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: GestureDetector(
        onTap: () {
          if (stopwatch.isRunning) {
            stopwatch.stop();
          } else {
            stopwatch.start();
          }
        },
        child: Text(
          returnFormattedText(),
          style: const TextStyle(
            color: AppColors.neutral60,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
