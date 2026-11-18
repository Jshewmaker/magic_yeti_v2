import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// A small solid dot signalling "something is waiting" without a count.
///
/// Used to mark entry points that lead to unseen items — e.g. the friends
/// icon on home when a friend request is pending. Deliberately countless:
/// the destination shows the number, this only has to be noticed.
class NotificationDot extends StatelessWidget {
  /// Creates a NotificationDot.
  ///
  /// The [size] argument defaults to 10 logical pixels.
  const NotificationDot({super.key, this.size = 10});

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
