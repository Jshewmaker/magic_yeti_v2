import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template app_theme}
/// The Default App [ThemeData].
/// {@endtemplate}
class AppTheme {
  /// {@macro app_theme}
  const AppTheme();

  /// Default `ThemeData` for App UI.
  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      primaryColor: _primaryColor,
      canvasColor: _backgroundColor,
      textButtonTheme: _textButtonTheme,
      textTheme: uiTextTheme.apply(
        bodyColor: AppColors.black,
        displayColor: AppColors.black,
        decorationColor: AppColors.black,
      ),
      tabBarTheme: _tabBarTheme,
      appBarTheme: _appBarTheme,
      inputDecorationTheme: _inputDecorationTheme,
      checkboxTheme: _checkBoxTheme,
      colorScheme: _colorScheme,
    );
  }

  Color get _primaryColor => AppColors.primary;
  Color get _backgroundColor => AppColors.background;

  ColorScheme get _colorScheme {
    return ColorScheme.dark(
      primary: _backgroundColor,
      onPrimary: _backgroundColor,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurfaceVariant: AppColors.onSurfaceVariant,
    );
  }

  TextTheme get _textTheme => Typography.englishLike2021;

  /// The UI text theme based on [UITextStyle].
  static final uiTextTheme = TextTheme(
    displayLarge: UITextStyle.displayLarge,
    displayMedium: UITextStyle.displayMedium,
    displaySmall: UITextStyle.displaySmall,
    headlineLarge: UITextStyle.headlineLarge,
    headlineMedium: UITextStyle.headlineMedium,
    headlineSmall: UITextStyle.headlineSmall,
    titleLarge: UITextStyle.titleLarge,
    titleMedium: UITextStyle.titleMedium,
    titleSmall: UITextStyle.titleSmall,
    labelLarge: UITextStyle.labelLarge,
    labelMedium: UITextStyle.labelMedium,
    labelSmall: UITextStyle.labelSmall,
    bodyLarge: UITextStyle.bodyLarge,
    bodyMedium: UITextStyle.bodyMedium,
    bodySmall: UITextStyle.bodySmall,
  );

  /// InputDecoration Theme.
  InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      disabledBorder: _textFieldBorder,
      border: const OutlineInputBorder(),
      filled: true,
      isDense: true,
      errorStyle: UITextStyle.bodySmall,
    );
  }

  InputBorder get _textFieldBorder => const OutlineInputBorder();

  /// Checkbox Theme
  CheckboxThemeData get _checkBoxTheme {
    return CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  AppBarTheme get _appBarTheme {
    return AppBarTheme(
      color: _backgroundColor,
      scrolledUnderElevation: 0,
    );
  }

  TabBarTheme get _tabBarTheme {
    return TabBarTheme(
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all<Color>(AppColors.background),
    );
  }

  /// Text Button Theme
  TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        textStyle: _textTheme.labelLarge,
      ),
    );
  }
}

/// Material State Extension.
extension MaterialStateSet on Set<WidgetState> {
  /// Check if is focused.
  bool get isFocused => contains(WidgetState.focused);

  /// Check if is disabled.
  bool get isDisabled => contains(WidgetState.disabled);
}
