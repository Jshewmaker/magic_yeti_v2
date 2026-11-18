/// Named breakpoints for responsive layout decisions.
///
/// The single source of truth for form-factor thresholds; never hardcode
/// these values at call sites.
abstract class AppBreakpoints {
  /// Devices whose shortest side is below this value are treated as phones;
  /// everything at or above it is treated as a tablet.
  static const double tablet = 600;
}
