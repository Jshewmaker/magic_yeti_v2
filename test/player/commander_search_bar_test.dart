import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/commander_search_bar.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc
    extends MockBloc<PlayerCustomizationEvent, PlayerCustomizationState>
    implements PlayerCustomizationBloc {}

void main() {
  late _MockBloc bloc;

  setUpAll(() {
    registerFallbackValue(const CardListRequested(cardName: ''));
  });

  setUp(() {
    bloc = _MockBloc();
    whenListen(
      bloc,
      const Stream<PlayerCustomizationState>.empty(),
      initialState: const PlayerCustomizationState(),
    );
  });

  Future<void> pumpBar(
    WidgetTester tester,
    TextEditingController controller,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<PlayerCustomizationBloc>.value(
            value: bloc,
            child: CommanderSearchBar(
              textController: controller,
              selectingPartner: false,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('does not search with fewer than 3 characters', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpBar(tester, controller);

    await tester.enterText(find.byType(TextField), 'at');
    await tester.pump(const Duration(milliseconds: 500));

    verifyNever(() => bloc.add(any(that: isA<CardListRequested>())));
  });

  testWidgets('live-searches after the debounce at 3+ characters',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpBar(tester, controller);

    await tester.enterText(find.byType(TextField), 'atr');

    // Nothing fires before the debounce elapses.
    await tester.pump(const Duration(milliseconds: 100));
    verifyNever(() => bloc.add(any(that: isA<CardListRequested>())));

    // Exactly one search fires after the debounce, carrying the typed query.
    await tester.pump(const Duration(milliseconds: 400));
    final captured = verify(() => bloc.add(captureAny()))
        .captured
        .whereType<CardListRequested>();
    expect(captured.length, 1);
    expect(captured.single.cardName, 'atr');
  });
}
