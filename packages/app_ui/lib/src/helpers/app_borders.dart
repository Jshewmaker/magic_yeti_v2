import 'package:dotted_decoration/dotted_decoration.dart';

/// {@template dashed_line}
/// Decoration object to add a dashed line.
/// {@endtemplate}
class DriverDashedLine extends DottedDecoration {
  /// {@macro dashed_line}
  DriverDashedLine({
    required this.index,
    super.color,
  }) : super(
          linePosition: LinePosition.top,
          strokeWidth: 2,
          dash: [
            if (index == 0) 1 else 8 ~/ index,
            if (index == 0) 0 else 2,
          ],
        );

  /// Driver racing order. This controls the dash length. Only valid 0-3.
  /// 0 being a solid line and 3 being the smallest dashes.
  final int index;
}
