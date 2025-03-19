import 'package:flutter/material.dart';

/// A utility class that provides device-specific information
/// such as whether the current device is a phone or tablet.
class DeviceUtils {
  /// Private constructor to prevent instantiation
  DeviceUtils._();

  /// A MediaQuery-independent way to determine if the device is a phone
  /// based on the screen width.
  ///
  /// This is a common breakpoint used for responsive design in Flutter.
  /// Devices with a shortest side < 600dp are considered phones.
  static bool isPhone(BuildContext context) {
    final data = MediaQuery.of(context);
    return data.size.shortestSide < 600;
  }

  /// A MediaQuery-independent way to determine if the device is a tablet
  /// based on the screen width.
  static bool isTablet(BuildContext context) {
    return !isPhone(context);
  }
}
