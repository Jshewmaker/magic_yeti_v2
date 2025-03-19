import 'package:flutter/material.dart';

/// A provider that makes device information available throughout the app
/// without requiring a LayoutBuilder in every widget that needs this information.
class DeviceInfoProvider extends InheritedWidget {
  /// Creates a new [DeviceInfoProvider].
  const DeviceInfoProvider({
    required this.isPhone,
    required super.child,
    super.key,
  });

  /// Whether the current device is a phone (shortestSide < 600).
  final bool isPhone;

  /// Whether the current device is a tablet (shortestSide >= 600).
  bool get isTablet => !isPhone;

  /// Get the [DeviceInfoProvider] from the given context.
  static DeviceInfoProvider of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<DeviceInfoProvider>();
    assert(result != null, 'No DeviceInfoProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(DeviceInfoProvider oldWidget) {
    return isPhone != oldWidget.isPhone;
  }
}
