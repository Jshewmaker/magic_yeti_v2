import 'package:app_ui/src/layout/app_breakpoints.dart';
import 'package:flutter/widgets.dart';

/// Makes the device form factor available to the whole widget tree without
/// every screen re-deriving it from MediaQuery.
///
/// Install it once near the app root with [DeviceInfoProvider.fromMediaQuery];
/// read it anywhere with `DeviceInfoProvider.of(context).isPhone`.
class DeviceInfoProvider extends InheritedWidget {
  /// Creates a new [DeviceInfoProvider] with an explicit form factor.
  ///
  /// Prefer [DeviceInfoProvider.fromMediaQuery] in app code; this constructor
  /// is mainly useful for forcing a form factor in tests.
  const DeviceInfoProvider({
    required this.isPhone,
    required super.child,
    super.key,
  });

  /// Whether the current device is a phone
  /// (shortestSide < [AppBreakpoints.tablet]).
  final bool isPhone;

  /// Whether the current device is a tablet
  /// (shortestSide >= [AppBreakpoints.tablet]).
  bool get isTablet => !isPhone;

  /// Derives the form factor from the surrounding [MediaQuery] and provides
  /// it to [child].
  static Widget fromMediaQuery({required Widget child, Key? key}) {
    return Builder(
      key: key,
      builder: (context) => DeviceInfoProvider(
        isPhone:
            MediaQuery.sizeOf(context).shortestSide < AppBreakpoints.tablet,
        child: child,
      ),
    );
  }

  /// Get the [DeviceInfoProvider] from the given context.
  static DeviceInfoProvider of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<DeviceInfoProvider>();
    assert(result != null, 'No DeviceInfoProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(DeviceInfoProvider oldWidget) {
    return isPhone != oldWidget.isPhone;
  }
}
