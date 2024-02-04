import 'package:app_ui/src/typography/typography.dart';
import 'package:flutter/material.dart';

/// UI Text Style Definitions
abstract class UITextStyle {
  static const _baseTextStyle = TextStyle(
    package: 'app_ui',
    fontWeight: AppFontWeight.regular,
    fontFamily: 'Teko',
    decoration: TextDecoration.none,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Display Large Text Style.
  static final TextStyle displayLarge = _baseTextStyle.copyWith(
    fontSize: 64,
    fontWeight: AppFontWeight.regular,
  );

  /// Display Medium Text Style.
  static final TextStyle displayMedium = _baseTextStyle.copyWith(
    fontSize: 48,
    fontWeight: AppFontWeight.medium,
  );

  /// Display Small Text Style.
  static final TextStyle displaySmall = _baseTextStyle.copyWith(
    fontSize: 40,
    fontWeight: AppFontWeight.medium,
  );

  /// Headline Large Text Style.
  static final TextStyle headlineLarge = _baseTextStyle.copyWith(
    fontSize: 40,
    fontWeight: AppFontWeight.regular,
  );

  /// Headline medium Text Style.
  static final TextStyle headlineMedium = _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: AppFontWeight.regular,
  );

  /// Headline small Text Style.
  static final TextStyle headlineSmall = _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: AppFontWeight.regular,
  );

  /// Title large Text Style.
  static final TextStyle titleLarge = _baseTextStyle.copyWith(
    fontSize: 26,
    fontWeight: AppFontWeight.regular,
  );

  /// Title medium Text Style.
  static final TextStyle titleMedium = _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: AppFontWeight.regular,
    letterSpacing: 0.15,
  );

  /// Title small Text Style.
  static final TextStyle titleSmall = _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: AppFontWeight.regular,
    letterSpacing: 0.1,
  );

  /// Label large Text Style.
  static final TextStyle labelLarge = _baseTextStyle.copyWith(
    fontSize: 18,
    height: 1,
    fontWeight: AppFontWeight.regular,
    letterSpacing: 0.1,
  );

  /// Label medium Text Style.
  static final TextStyle labelMedium = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
    letterSpacing: 0.5,
  );

  /// Label small Text Style.
  static final TextStyle labelSmall = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: AppFontWeight.small,
    letterSpacing: -0.5,
  );

  /// Body large Text Style.
  static final TextStyle bodyLarge = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
    letterSpacing: -0.5,
  );

  /// Body medium Text Style.
  static final TextStyle bodyMedium = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: AppFontWeight.regular,
    letterSpacing: -0.25,
  );

  /// Body small Text Style.
  static final TextStyle bodySmall = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: AppFontWeight.regular,
    letterSpacing: -0.4,
  );
}
