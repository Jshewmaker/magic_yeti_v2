import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Applies a preferred-orientation policy while the surrounding screen is in
/// the tree.
///
/// Centralizes `SystemChrome.setPreferredOrientations` calls so screens
/// declare their orientation policy instead of issuing side effects from
/// `build`. Pass `null` to leave the current orientation policy unchanged.
class OrientationLock extends StatefulWidget {
  /// Creates an [OrientationLock].
  const OrientationLock({
    required this.orientations,
    required this.child,
    super.key,
  });

  /// The orientations to allow while this widget is mounted, or `null` to
  /// leave the existing policy untouched.
  final List<DeviceOrientation>? orientations;

  /// The subtree the policy applies to.
  final Widget child;

  @override
  State<OrientationLock> createState() => _OrientationLockState();
}

class _OrientationLockState extends State<OrientationLock> {
  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(OrientationLock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orientations != oldWidget.orientations) {
      _apply();
    }
  }

  void _apply() {
    final orientations = widget.orientations;
    if (orientations != null) {
      SystemChrome.setPreferredOrientations(orientations);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
