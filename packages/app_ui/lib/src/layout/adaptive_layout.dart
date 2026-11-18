import 'package:app_ui/src/layout/device_info_provider.dart';
import 'package:flutter/widgets.dart';

/// Builds a phone or tablet layout based on the surrounding
/// [DeviceInfoProvider].
///
/// This is the standard way to split a screen by form factor. Keep the
/// builders thin — layout shells only — and share the actual content
/// widgets between them:
///
/// ```dart
/// AdaptiveLayout(
///   phone: (context) => Column(children: [content, actions]),
///   tablet: (context) => Row(children: [content, actions]),
/// )
/// ```
class AdaptiveLayout extends StatelessWidget {
  /// Creates an [AdaptiveLayout].
  const AdaptiveLayout({
    required this.phone,
    required this.tablet,
    super.key,
  });

  /// Builder used when the device is a phone.
  final WidgetBuilder phone;

  /// Builder used when the device is a tablet.
  final WidgetBuilder tablet;

  @override
  Widget build(BuildContext context) {
    return DeviceInfoProvider.of(context).isPhone
        ? phone(context)
        : tablet(context);
  }
}
