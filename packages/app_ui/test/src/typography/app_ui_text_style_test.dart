import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Nunito Sans font wiring.
///
/// Context, because this is easy to get wrong twice: Nunito Sans is published
/// as a variable font, and Flutter does NOT drive a variable font's `wght` axis
/// from [TextStyle.fontWeight] — only from `fontVariations`. Shipping the
/// variable file directly renders every weight at the axis default of 200
/// (ExtraLight) and turns every `fontWeight` in the app into dead code. So the
/// assets are static instances cut from it (see assets/fonts/README.md), which
/// restores normal `fontWeight` behaviour.
///
/// These tests would not catch a regression to the variable font on their own
/// if they ran against Ahem — `flutter test` does not load pubspec font assets
/// and silently falls back to it, where every glyph is a fixed square and all
/// weights measure identically. So the fonts are registered from disk with
/// [FontLoader], and the first test asserts we escaped Ahem.
void main() {
  const family = 'NunitoSansTest';

  setUpAll(() async {
    final loader = FontLoader(family);
    for (final name in const [
      'NunitoSans-Light',
      'NunitoSans-Regular',
      'NunitoSans-Medium',
      'NunitoSans-SemiBold',
      'NunitoSans-Bold',
    ]) {
      final bytes = File('assets/fonts/$name.ttf').readAsBytesSync();
      loader.addFont(
        Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
      );
    }
    await loader.load();
  });

  double widthAt(FontWeight weight) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'HAMBURGEFONTSIV',
        style: TextStyle(
          fontFamily: family,
          fontSize: 48,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  group('Nunito Sans assets', () {
    test('the real font is loaded, not the Ahem fallback', () {
      // Ahem renders every glyph as a fixed square, so its width is exactly
      // fontSize * charCount. Hitting that number means the assets did not
      // load and every other assertion here would be meaningless.
      const ahemWidth = 48.0 * 15;
      expect(widthAt(FontWeight.w400), isNot(ahemWidth));
    });

    test('fontWeight actually changes the rendered weight', () {
      // The whole reason the variable font was instanced to static weights.
      // If this fails, the assets have regressed to a variable font and every
      // fontWeight in the app is silently doing nothing.
      final light = widthAt(FontWeight.w300);
      final regular = widthAt(FontWeight.w400);
      final bold = widthAt(FontWeight.w700);

      expect(light, lessThan(regular));
      expect(regular, lessThan(bold));
    });
  });

  group('UITextStyle', () {
    test('every style uses the NunitoSans family from app_ui', () {
      final styles = <String, TextStyle>{
        'displayLarge': UITextStyle.displayLarge,
        'displayMedium': UITextStyle.displayMedium,
        'displaySmall': UITextStyle.displaySmall,
        'headlineLarge': UITextStyle.headlineLarge,
        'headlineMedium': UITextStyle.headlineMedium,
        'headlineSmall': UITextStyle.headlineSmall,
        'titleLarge': UITextStyle.titleLarge,
        'titleMedium': UITextStyle.titleMedium,
        'titleSmall': UITextStyle.titleSmall,
        'labelLarge': UITextStyle.labelLarge,
        'labelMedium': UITextStyle.labelMedium,
        'labelSmall': UITextStyle.labelSmall,
        'bodyLarge': UITextStyle.bodyLarge,
        'bodyMedium': UITextStyle.bodyMedium,
        'bodySmall': UITextStyle.bodySmall,
      };

      // TextStyle folds `package:` into fontFamily at construction, so the
      // resolved value carries the prefix. Asserting the full string proves
      // both the family AND that package: app_ui is set — without that prefix
      // the asset does not resolve from the host app and text silently falls
      // back to the platform default.
      for (final entry in styles.entries) {
        expect(
          entry.value.fontFamily,
          'packages/app_ui/NunitoSans',
          reason: '${entry.key} should resolve to the app_ui NunitoSans asset',
        );
      }
    });
  });
}
