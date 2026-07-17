import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// An [IconButton] with a [NotificationDot] overlaid on its top-right.
///
/// Owns the badge geometry so every entry point that can carry a dot places
/// it identically — the phone AppBar and the tablet section header would
/// otherwise drift apart.
class BadgedIconButton extends StatelessWidget {
  /// Creates a BadgedIconButton.
  const BadgedIconButton({
    required this.icon,
    required this.onPressed,
    this.showBadge = false,
    this.color,
    super.key,
  });

  /// The icon to display inside the button.
  final IconData icon;

  /// The callback to invoke when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether to overlay the dot. False renders a plain [IconButton].
  final bool showBadge;

  /// Icon color. Null inherits from the ambient [IconTheme] — which is what
  /// an AppBar action wants.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
        ),
        if (showBadge)
          const Positioned(
            right: 6,
            top: 6,
            // The dot overlaps the button's tap target; without this the
            // centre of the icon would not respond.
            child: IgnorePointer(child: NotificationDot()),
          ),
      ],
    );
  }
}
