// test/match_details/bloc/commander_picker_cubit_test.dart
import 'package:api_client/api_client.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/commander_picker_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

import '../../helpers/card_fixtures.dart';

class _MockScryfallRepository extends Mock implements ScryfallRepository {}

class _MockSearchCards extends Mock implements SearchCards {}

void main() {
  late ScryfallRepository repository;

  setUp(() => repository = _MockScryfallRepository());

  CommanderPickerCubit build() =>
      CommanderPickerCubit(scryfallRepository: repository);

  blocTest<CommanderPickerCubit, CommanderPickerState>(
    'emits [loading, success] with only legendary cards on a successful search',
    setUp: () {
      final result = _MockSearchCards();
      // Build cards before stubbing to avoid mocktail _whenCall nesting issue.
      final cards = [
        buildMagicCard(name: 'Atraxa', typeLine: 'Legendary Creature'),
        buildMagicCard(name: 'Forest', typeLine: 'Basic Land'),
      ];
      when(() => result.data).thenReturn(cards);
      when(() => repository.getCardFullText(cardName: any(named: 'cardName')))
          .thenAnswer((_) async => result);
    },
    build: build,
    act: (cubit) => cubit.search('a'),
    expect: () => [
      const CommanderPickerState(status: CommanderPickerStatus.loading),
      isA<CommanderPickerState>()
          .having((s) => s.status, 'status', CommanderPickerStatus.success)
          .having((s) => s.cards.length, 'cards.length', 1)
          .having((s) => s.cards.first.name, 'cards.first.name', 'Atraxa'),
    ],
  );

  blocTest<CommanderPickerCubit, CommanderPickerState>(
    'emits [loading, failure] when the repository throws',
    setUp: () {
      when(() => repository.getCardFullText(cardName: any(named: 'cardName')))
          .thenThrow(Exception('boom'));
    },
    build: build,
    act: (cubit) => cubit.search('a'),
    expect: () => [
      const CommanderPickerState(status: CommanderPickerStatus.loading),
      const CommanderPickerState(status: CommanderPickerStatus.failure),
    ],
  );
}
