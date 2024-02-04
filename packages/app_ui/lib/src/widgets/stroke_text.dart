import 'package:flutter/material.dart';

/// Adds outline boarder to text widget.
class StrokeText extends StatelessWidget {
  /// Adds outline boarder to text widget.
  const StrokeText({
    required this.text,
    required this.fontSize,
    required this.color,
    super.key,
  });
  final String text;
  final double fontSize;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        shadows: const [
          Shadow(
              // bottomLeft
              offset: Offset(-1.5, -1.5)),
          Shadow(
              // bottomRight
              offset: Offset(1.5, -1.5)),
          Shadow(
              // topRight
              offset: Offset(1.5, 1.5)),
          Shadow(
              // topLeft
              offset: Offset(-1.5, 1.5)),
        ],
      ).copyWith(color: color),
    );
  }
}
