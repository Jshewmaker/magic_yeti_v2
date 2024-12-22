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
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
        decorationColor: AppColors.white,
      ),
      buttonTheme: _buttonTheme,
      tabBarTheme: _tabBarTheme,
      appBarTheme: _appBarTheme,
      inputDecorationTheme: _inputDecorationTheme,
      checkboxTheme: _checkBoxTheme,
      colorScheme: _colorScheme,
      elevatedButtonTheme: _elevatedButtonTheme,
    );
  }

  Color get _primaryColor => AppColors.neutral60;
  Color get _backgroundColor => AppColors.background;

  ColorScheme get _colorScheme {
    return ColorScheme.dark(
      primary: _backgroundColor,
      onPrimary: _backgroundColor,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.background,
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

  ButtonThemeData get _buttonTheme {
    return const ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
      buttonColor: AppColors.white,
      colorScheme: ColorScheme.dark(
        primary: AppColors.white,
        onPrimary: AppColors.background,
      ),
      shape: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.white, width: 2),
      ),
    );
  }

  ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.background,
        backgroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.white,
        disabledForegroundColor: AppColors.neutral60,
      ),
    );
  }

  /// InputDecoration Theme.
  InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      disabledBorder: _textFieldBorder,
      border: const OutlineInputBorder(),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.neutral60, width: 1.5),
      ),
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

  ThemeData copyWith({
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryColorLight,
    Color? primaryColorDark,
    Color? accentColor,
    Color? canvasColor,
    Color? scaffoldBackgroundColor,
    Color? bottomAppBarColor,
    Color? cardColor,
    Color? dividerColor,
    Color? highlightColor,
    Color? splashColor,
    Color? selectedRowColor,
    Color? unselectedWidgetColor,
    Color? disabledColor,
    Color? buttonColor,
    Color? secondaryHeaderColor,
    Color? textSelectionColor,
    Color? backgroundColor,
    Color? dialogBackgroundColor,
    Color? indicatorColor,
    Color? hintColor,
    Color? errorColor,
    Color? toggleableActiveColor,
  }) {
    final ThemeData theme = ThemeData(
      brightness: brightness ?? Brightness.dark,
      primaryColor: primaryColor ?? AppColors.primary,
      primaryColorLight: primaryColorLight,
      primaryColorDark: primaryColorDark,
      canvasColor: canvasColor ?? _backgroundColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      unselectedWidgetColor: unselectedWidgetColor,
      disabledColor: disabledColor,
      secondaryHeaderColor: secondaryHeaderColor,
      dialogBackgroundColor: dialogBackgroundColor,
      indicatorColor: indicatorColor,
      hintColor: hintColor,
      buttonTheme: _buttonTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
    );
    return theme;
  }
}

/// Material State Extension.
extension MaterialStateSet on Set<WidgetState> {
  /// Check if is focused.
  bool get isFocused => contains(WidgetState.focused);

  /// Check if is disabled.
  bool get isDisabled => contains(WidgetState.disabled);
}
