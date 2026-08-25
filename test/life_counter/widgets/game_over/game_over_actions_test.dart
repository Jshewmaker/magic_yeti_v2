import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('GameOverActionBar', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      required bool stacked,
      required bool canSubmit,
      required Size size,
      VoidCallback? onPlayAgain,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpApp(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: GameOverActionBar(
                canSubmit: canSubmit,
                stacked: stacked,
                onReturnHome: () {},
                onPlayAgain: onPlayAgain ?? () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('stacked bar fits phone width without overflow',
        (tester) async {
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: true,
        size: const Size(390, 844),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows the required-fields hint only when disabled',
        (tester) async {
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: false,
        size: const Size(390, 844),
      );
      expect(find.text('Fill out both fields to continue'), findsOneWidget);

      await pumpBar(
        tester,
        stacked: true,
        canSubmit: true,
        size: const Size(390, 844),
      );
      expect(find.text('Fill out both fields to continue'), findsNothing);
    });

    testWidgets('disabled buttons do not fire their callbacks',
        (tester) async {
      var played = false;
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: false,
        size: const Size(390, 844),
        onPlayAgain: () => played = true,
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(played, isFalse);
    });

    testWidgets('enabled play again fires its callback', (tester) async {
      var played = false;
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: true,
        size: const Size(390, 844),
        onPlayAgain: () => played = true,
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(played, isTrue);
    });

    testWidgets('play again renders before return home when stacked',
        (tester) async {
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: true,
        size: const Size(390, 844),
      );

      final playAgainCenter = tester.getCenter(find.byType(ElevatedButton));
      final returnHomeCenter = tester.getCenter(find.byType(OutlinedButton));
      expect(playAgainCenter.dy, lessThan(returnHomeCenter.dy));
    });

    testWidgets('stacked bar fits phone width at 2x text scale',
        (tester) async {
      await pumpBar(
        tester,
        stacked: true,
        canSubmit: false,
        size: const Size(390, 844),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('side-by-side bar fits tablet width without overflow',
        (tester) async {
      await pumpBar(
        tester,
        stacked: false,
        canSubmit: true,
        size: const Size(1280, 800),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('side-by-side bar fits tablet width at 2x text scale',
        (tester) async {
      await pumpBar(
        tester,
        stacked: false,
        canSubmit: false,
        size: const Size(1280, 800),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('side-by-side bar fits phone width at 2x text scale',
        (tester) async {
      await pumpBar(
        tester,
        stacked: false,
        canSubmit: false,
        size: const Size(390, 844),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
