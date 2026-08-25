import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/life_counter/bloc/game_over_bloc.dart';
import 'package:magic_yeti/life_counter/widgets/game_over/game_over.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('canSubmitGameOver', () {
    const base = GameOverState(
      standings: [],
      selectedPlayerId: 'selected',
      firstPlayerId: 'first',
    );

    test('true once a first player and an account owner are both chosen', () {
      expect(canSubmitGameOver(base), isTrue);
    });

    test('false when no account owner is selected', () {
      // copyWith can't null out a field (it falls back to `?? this.field`),
      // so build the state directly instead of via copyWith here.
      const state = GameOverState(
        standings: [],
        selectedPlayerId: null,
        firstPlayerId: 'first',
      );
      expect(canSubmitGameOver(state), isFalse);
    });

    test('false when no first player is chosen', () {
      const state = GameOverState(
        standings: [],
        selectedPlayerId: 'selected',
        firstPlayerId: null,
      );
      expect(canSubmitGameOver(state), isFalse);
    });

    test('false while a save is in flight, even with both fields set', () {
      expect(
        canSubmitGameOver(base.copyWith(status: GameOverStatus.loading)),
        isFalse,
      );
    });

    test('true again once the save settles into success or failure', () {
      expect(
        canSubmitGameOver(base.copyWith(status: GameOverStatus.success)),
        isTrue,
      );
      expect(
        canSubmitGameOver(base.copyWith(status: GameOverStatus.failure)),
        isTrue,
      );
    });
  });

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

    testWidgets(
      'side-by-side bar fits the real tablet details-panel width at 2x '
      'text scale',
      (tester) async {
        // Fix 2: on a 1280pt-wide tablet, GameOverDetailsPanel is the
        // flex:4-of-9 column (with the standings panel as flex:5, separated
        // by a 12pt gap and 16pt outer padding on each side), then loses
        // its own 20pt-per-side Container padding:
        //   (1280 - 16 - 16 - 12) * 4 / 9 - 20 - 20 ≈ 509pt.
        // That's the actual width GameOverActionBar's hint row renders at
        // on the tablet — nothing like the full 1280pt or 390pt widths the
        // other tests above use. Before Fix 1/2, the tablet hint was a bare
        // Row(icon, Text) with no Flexible, so at this width and 2x scale
        // it overflowed horizontally; GameOverRequiredHint's Flexible wrap
        // must keep it from overflowing here too.
        await pumpBar(
          tester,
          stacked: false,
          canSubmit: false,
          size: const Size(509, 800),
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
      },
    );
  });
}
