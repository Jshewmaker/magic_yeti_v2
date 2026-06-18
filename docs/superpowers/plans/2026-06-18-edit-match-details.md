# Edit Finished Match — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users edit a finished match from the Match Details screen — change each player's name, commander, and partner commander — and persist it.

**Architecture:** Add an inline edit mode to the existing read-only Match Details screen. A new `MatchEditCubit` holds a draft copy of the game's players and saves via the existing `FirebaseDatabaseRepository.updateGameStats`. A small, isolated `CommanderPickerCubit` + full-screen picker reuses Scryfall search to return a `Commander`. The `MagicCard → Commander` mapping (currently inlined in the live customize flow) is extracted into one shared helper. While editing, the screen shows a single editable players list; the Winner and Metadata cards are hidden to avoid double-editing the winner.

**Tech Stack:** Flutter, `flutter_bloc` (Cubit), `equatable`, `bloc_test`, `mocktail`, `very_good_analysis`, Firestore via `firebase_database_repository`, Scryfall via `scryfall_repository`.

## Global Constraints

- Lints: `very_good_analysis`. `public_member_api_docs: false` and `omit_local_variable_types: ignore` are set — no doc comments required, local type annotations optional. Use trailing commas and `const` where possible.
- Persistence writes only the **current user's copy**: `updateGameStats(game: updatedGame, playerId: currentUserId)` where `currentUserId = context.read<AppBloc>().state.user.id`. Do not fan out to other participants (known limitation).
- No data-model changes. Use existing `copyWith`: `GameModel.copyWith(players:)`, `Player.copyWith(name:, commander:, partner:)`. Note `Player.copyWith.partner` is `Commander? Function()?` — pass `() => value` to set, `() => null` to clear, omit to leave unchanged. `Player.copyWith.commander` is `Commander?` and cannot clear (change-only) — intended (only partner is removable).
- Editable scope: player name, commander, partner. NOT editable: winner, placement, who-went-first, duration, room id, date.
- All player names are editable (including account-linked players).
- Localization: add keys to both `lib/l10n/arb/app_en.arb` and `app_es.arb`, then run `flutter gen-l10n --arb-dir="lib/l10n/arb"`. Access via `context.l10n.*`.
- No `build_runner` needed (no `@JsonSerializable` changes).
- `MagicCard`, `SearchCards`, `ImageURIs` are exported from `package:api_client/api_client.dart`. `Player`, `Commander` from `package:player_repository/player_repository.dart`.
- Tests are built with `bloc_test` + `mocktail`. `MagicCard` (60+ fields) and `SearchCards` (5 required fields) are **mocked**, never constructed by hand. Widget tests use the existing `pumpApp` helper (`test/helpers/helpers.dart` → `pump_app.dart`).
- Run commands from repo root. Tests: `flutter test <path>`. Lint: `flutter analyze`.

---

### Task 1: Extract `magicCardToCommander` helper + shared card fixture

**Files:**
- Create: `lib/app/utils/commander_mapper.dart`
- Create: `test/helpers/card_fixtures.dart`
- Modify: `lib/player/view/widgets/commander_card_grid.dart` (replace inline `Commander(...)` in `_onCardTapped`)
- Test: `test/app/utils/commander_mapper_test.dart`

**Interfaces:**
- Produces: `Commander magicCardToCommander(MagicCard card)`
- Produces (test util): `MagicCard buildMagicCard({...})` — a mocktail-backed `MagicCard` with stubbed getters and sensible defaults, used by Tasks 1, 3, 4.

- [ ] **Step 1: Create the shared card fixture**

```dart
// test/helpers/card_fixtures.dart
import 'package:api_client/api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockMagicCard extends Mock implements MagicCard {}

/// Builds a mocktail-backed [MagicCard] with only the getters the app reads
/// stubbed. Avoids the 60-field constructor and deeply-nested required models.
MagicCard buildMagicCard({
  String id = 'card-id',
  String name = 'Atraxa',
  String typeLine = 'Legendary Creature',
  String scryfallUri = 'https://scryfall.test/card',
  String? oracleId = 'oracle-1',
  int? edhrecRank = 5,
  String? artist = 'Artist',
  List<String>? colors = const ['W', 'U', 'B', 'G'],
  List<String> colorIdentity = const ['W', 'U', 'B', 'G'],
  ImageURIs? imageUris = const ImageURIs(
    small: '',
    normal: 'https://img.test/normal.jpg',
    large: '',
    png: '',
    artCrop: 'https://img.test/art_crop.jpg',
    borderCrop: '',
  ),
  String? manaCost = '{G}{W}{U}{B}',
  String? oracleText = 'text',
  String? power = '4',
  String? toughness = '4',
}) {
  final card = MockMagicCard();
  when(() => card.id).thenReturn(id);
  when(() => card.name).thenReturn(name);
  when(() => card.typeLine).thenReturn(typeLine);
  when(() => card.scryfallUri).thenReturn(scryfallUri);
  when(() => card.oracleId).thenReturn(oracleId);
  when(() => card.edhrecRank).thenReturn(edhrecRank);
  when(() => card.artist).thenReturn(artist);
  when(() => card.colors).thenReturn(colors);
  when(() => card.colorIdentity).thenReturn(colorIdentity);
  when(() => card.imageUris).thenReturn(imageUris);
  when(() => card.manaCost).thenReturn(manaCost);
  when(() => card.oracleText).thenReturn(oracleText);
  when(() => card.power).thenReturn(power);
  when(() => card.toughness).thenReturn(toughness);
  when(() => card.cardFaces).thenReturn(null);
  return card;
}
```

- [ ] **Step 2: Write the failing mapper test**

```dart
// test/app/utils/commander_mapper_test.dart
import 'package:api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/utils/commander_mapper.dart';

import '../../helpers/card_fixtures.dart';

void main() {
  group('magicCardToCommander', () {
    test('maps MagicCard fields onto a Commander', () {
      final card = buildMagicCard(
        oracleId: 'oracle-1',
        name: 'Atraxa',
        typeLine: 'Legendary Creature',
        scryfallUri: 'https://scryfall.test/atraxa',
        manaCost: '{G}{W}{U}{B}',
        power: '4',
        toughness: '4',
      );

      final commander = magicCardToCommander(card);

      expect(commander.oracleId, 'oracle-1');
      expect(commander.name, 'Atraxa');
      expect(commander.scryFallUrl, 'https://scryfall.test/atraxa');
      expect(commander.imageUrl, 'https://img.test/art_crop.jpg');
      expect(commander.colors, ['W', 'U', 'B', 'G']);
      expect(commander.cardType, 'Legendary Creature');
      expect(commander.manaCost, '{G}{W}{U}{B}');
      expect(commander.power, '4');
      expect(commander.toughness, '4');
    });

    test('falls back to empty image url when imageUris is null', () {
      final card = buildMagicCard(imageUris: null);
      expect(magicCardToCommander(card).imageUrl, '');
    });

    test('falls back to empty colors when colors is null', () {
      final card = buildMagicCard(colors: null);
      expect(magicCardToCommander(card).colors, isEmpty);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/app/utils/commander_mapper_test.dart`
Expected: FAIL — cannot resolve `magic_yeti/app/utils/commander_mapper.dart`.

- [ ] **Step 4: Create the helper**

```dart
// lib/app/utils/commander_mapper.dart
import 'package:api_client/api_client.dart';
import 'package:player_repository/player_repository.dart';

/// Builds a [Commander] from a Scryfall [MagicCard].
///
/// Single source of truth for this mapping, shared by the live player
/// customization flow and the match-details edit flow.
Commander magicCardToCommander(MagicCard card) {
  return Commander(
    oracleId: card.oracleId,
    name: card.name,
    typeLine: card.typeLine ?? '',
    scryFallUrl: card.scryfallUri,
    edhrecRank: card.edhrecRank,
    artist: card.artist ?? '',
    colors: card.colors ?? [],
    colorIdentity: card.colorIdentity,
    cardType: card.typeLine ?? '',
    imageUrl: card.imageUris?.artCrop ?? '',
    manaCost: card.manaCost ?? '',
    oracleText: card.oracleText ?? '',
    power: card.power,
    toughness: card.toughness,
  );
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/app/utils/commander_mapper_test.dart`
Expected: PASS (all three).

- [ ] **Step 6: Refactor `CommanderCardGrid` to use the helper**

In `lib/player/view/widgets/commander_card_grid.dart`, add
`import 'package:magic_yeti/app/utils/commander_mapper.dart';` and replace the
`Commander(...)` literal in `_CardGridSliver._onCardTapped` with the helper call:

```dart
  void _onCardTapped(BuildContext context, MagicCard card) {
    unawaited(
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );

    final commander = magicCardToCommander(card);

    context.read<PlayerCustomizationBloc>().add(
          selectingPartner
              ? UpdatePlayerCommander(partner: commander)
              : UpdatePlayerCommander(commander: commander),
        );
  }
```

- [ ] **Step 7: Verify analyze**

Run: `flutter analyze lib/app/utils/commander_mapper.dart lib/player/view/widgets/commander_card_grid.dart`
Expected: "No issues found!"

- [ ] **Step 8: Commit**

```bash
git add lib/app/utils/commander_mapper.dart lib/player/view/widgets/commander_card_grid.dart test/helpers/card_fixtures.dart test/app/utils/commander_mapper_test.dart
git commit -m "refactor: extract shared magicCardToCommander helper"
```

---

### Task 2: Localization strings

**Files:**
- Modify: `lib/l10n/arb/app_en.arb`
- Modify: `lib/l10n/arb/app_es.arb`
- Generated (do not hand-edit): `lib/l10n/arb/app_localizations*.dart`

**Interfaces:**
- Produces getters on `AppLocalizations`: `editMatchTooltip`, `saveButtonLabel`,
  `playerNameLabel`, `addPartnerLabel`, `removePartnerTooltip`,
  `selectCommanderTitle`, `selectPartnerTitle`, `matchUpdatedMessage`.
- Reuses existing: `cancelButtonLabel`, `searchButtonText`,
  `searchCommanderHintText`, `somethingWentWrong`, `noCommanders`,
  `errorSnackbarMessage`.

- [ ] **Step 1: Add keys to `app_en.arb`**

Insert before the final closing `}`. Ensure the preceding entry ends with a comma and
there is no trailing comma before the closing brace.

```json
  "editMatchTooltip": "Edit match",
  "@editMatchTooltip": {
    "description": "Tooltip for the edit action on the match details screen"
  },
  "saveButtonLabel": "Save",
  "@saveButtonLabel": {
    "description": "Label for the save action while editing a match"
  },
  "playerNameLabel": "Player name",
  "@playerNameLabel": {
    "description": "Label for the player name field while editing a match"
  },
  "addPartnerLabel": "Add partner",
  "@addPartnerLabel": {
    "description": "Action to add a partner commander while editing a match"
  },
  "removePartnerTooltip": "Remove partner",
  "@removePartnerTooltip": {
    "description": "Tooltip to remove a partner commander while editing a match"
  },
  "selectCommanderTitle": "Select Commander",
  "@selectCommanderTitle": {
    "description": "Title for the commander picker"
  },
  "selectPartnerTitle": "Select Partner",
  "@selectPartnerTitle": {
    "description": "Title for the partner commander picker"
  },
  "matchUpdatedMessage": "Match updated",
  "@matchUpdatedMessage": {
    "description": "Snackbar confirmation shown after saving match edits"
  }
```

- [ ] **Step 2: Add the same keys to `app_es.arb`**

```json
  "editMatchTooltip": "Editar partida",
  "@editMatchTooltip": {
    "description": "Tooltip for the edit action on the match details screen"
  },
  "saveButtonLabel": "Guardar",
  "@saveButtonLabel": {
    "description": "Label for the save action while editing a match"
  },
  "playerNameLabel": "Nombre del jugador",
  "@playerNameLabel": {
    "description": "Label for the player name field while editing a match"
  },
  "addPartnerLabel": "Agregar compañero",
  "@addPartnerLabel": {
    "description": "Action to add a partner commander while editing a match"
  },
  "removePartnerTooltip": "Quitar compañero",
  "@removePartnerTooltip": {
    "description": "Tooltip to remove a partner commander while editing a match"
  },
  "selectCommanderTitle": "Seleccionar comandante",
  "@selectCommanderTitle": {
    "description": "Title for the commander picker"
  },
  "selectPartnerTitle": "Seleccionar compañero",
  "@selectPartnerTitle": {
    "description": "Title for the partner commander picker"
  },
  "matchUpdatedMessage": "Partida actualizada",
  "@matchUpdatedMessage": {
    "description": "Snackbar confirmation shown after saving match edits"
  }
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n --arb-dir="lib/l10n/arb"`
Expected: completes without error; the new getters exist on `AppLocalizations`.

- [ ] **Step 4: Verify analyze**

Run: `flutter analyze lib/l10n`
Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/arb/
git commit -m "feat: add l10n strings for match editing"
```

---

### Task 3: `CommanderPickerCubit`

**Files:**
- Create: `lib/match_details/bloc/commander_picker_cubit.dart`
- Create: `lib/match_details/bloc/commander_picker_state.dart`
- Test: `test/match_details/bloc/commander_picker_cubit_test.dart`

**Interfaces:**
- Consumes: `ScryfallRepository.getCardFullText({required String cardName}) → Future<SearchCards>` (`SearchCards.data` is `List<MagicCard>`).
- Produces:
  - `enum CommanderPickerStatus { initial, loading, success, failure }`
  - `class CommanderPickerState { CommanderPickerStatus status; List<MagicCard> cards; }`
  - `class CommanderPickerCubit extends Cubit<CommanderPickerState> { CommanderPickerCubit({required ScryfallRepository scryfallRepository}); Future<void> search(String cardName); }`

- [ ] **Step 1: Write the failing test**

```dart
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
      when(() => result.data).thenReturn([
        buildMagicCard(name: 'Atraxa', typeLine: 'Legendary Creature'),
        buildMagicCard(name: 'Forest', typeLine: 'Basic Land'),
      ]);
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/match_details/bloc/commander_picker_cubit_test.dart`
Expected: FAIL — cannot resolve `commander_picker_cubit.dart`.

- [ ] **Step 3: Create the state**

```dart
// lib/match_details/bloc/commander_picker_state.dart
part of 'commander_picker_cubit.dart';

enum CommanderPickerStatus { initial, loading, success, failure }

class CommanderPickerState extends Equatable {
  const CommanderPickerState({
    this.status = CommanderPickerStatus.initial,
    this.cards = const [],
  });

  final CommanderPickerStatus status;
  final List<MagicCard> cards;

  CommanderPickerState copyWith({
    CommanderPickerStatus? status,
    List<MagicCard>? cards,
  }) {
    return CommanderPickerState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
    );
  }

  @override
  List<Object?> get props => [status, cards];
}
```

- [ ] **Step 4: Create the cubit**

```dart
// lib/match_details/bloc/commander_picker_cubit.dart
import 'package:api_client/api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'commander_picker_state.dart';

class CommanderPickerCubit extends Cubit<CommanderPickerState> {
  CommanderPickerCubit({required ScryfallRepository scryfallRepository})
      : _scryfallRepository = scryfallRepository,
        super(const CommanderPickerState());

  final ScryfallRepository _scryfallRepository;

  Future<void> search(String cardName) async {
    emit(state.copyWith(status: CommanderPickerStatus.loading));
    try {
      final result = await _scryfallRepository.getCardFullText(
        cardName: cardName,
      );
      final legendary = result.data
          .where(
            (card) =>
                card.typeLine?.toLowerCase().contains('legendary') ?? false,
          )
          .toList();
      emit(
        state.copyWith(
          status: CommanderPickerStatus.success,
          cards: legendary,
        ),
      );
    } on Exception catch (_) {
      emit(state.copyWith(status: CommanderPickerStatus.failure));
    }
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/match_details/bloc/commander_picker_cubit_test.dart`
Expected: PASS (both `blocTest`s).

- [ ] **Step 6: Commit**

```bash
git add lib/match_details/bloc/commander_picker_cubit.dart lib/match_details/bloc/commander_picker_state.dart test/match_details/bloc/commander_picker_cubit_test.dart
git commit -m "feat: add CommanderPickerCubit for match-details commander search"
```

---

### Task 4: Full-screen commander picker + `showCommanderPicker`

**Files:**
- Create: `lib/match_details/widgets/commander_picker.dart`
- Test: `test/match_details/widgets/commander_picker_test.dart`

**Interfaces:**
- Consumes: `CommanderPickerCubit`, `magicCardToCommander`, `ScryfallRepository`
  (read from context), `context.l10n.{searchCommanderHintText, searchButtonText,
  selectCommanderTitle, selectPartnerTitle, somethingWentWrong, noCommanders}`.
- Produces:
  - `typedef PickCommander = Future<Commander?> Function(BuildContext context, {required bool selectingPartner});`
  - `Future<Commander?> showCommanderPicker(BuildContext context, {required bool selectingPartner});`
  - `class CommanderPickerView extends StatefulWidget`
- Card item key format: `ValueKey('commander-card-${card.id}')`.

- [ ] **Step 1: Write the failing test**

```dart
// test/match_details/widgets/commander_picker_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/commander_picker_cubit.dart';
import 'package:magic_yeti/match_details/widgets/commander_picker.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/card_fixtures.dart';
import '../../helpers/helpers.dart';

class _MockCommanderPickerCubit extends MockCubit<CommanderPickerState>
    implements CommanderPickerCubit {}

void main() {
  late CommanderPickerCubit cubit;

  setUp(() => cubit = _MockCommanderPickerCubit());

  testWidgets('tapping a result card pops with the mapped commander',
      (tester) async {
    final card = buildMagicCard(id: 'card-id', name: 'Atraxa');
    whenListen(
      cubit,
      const Stream<CommanderPickerState>.empty(),
      initialState: CommanderPickerState(
        status: CommanderPickerStatus.success,
        cards: [card],
      ),
    );

    Commander? result;
    await tester.pumpApp(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await Navigator.of(context).push<Commander>(
              MaterialPageRoute<Commander>(
                builder: (_) => BlocProvider<CommanderPickerCubit>.value(
                  value: cubit,
                  child: const CommanderPickerView(selectingPartner: false),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('commander-card-card-id')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Atraxa');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/match_details/widgets/commander_picker_test.dart`
Expected: FAIL — cannot resolve `commander_picker.dart`.

- [ ] **Step 3: Create the picker view + entry point**

```dart
// lib/match_details/widgets/commander_picker.dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/utils/commander_mapper.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/match_details/bloc/commander_picker_cubit.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

typedef PickCommander = Future<Commander?> Function(
  BuildContext context, {
  required bool selectingPartner,
});

/// Opens a full-screen commander picker and resolves to the chosen [Commander],
/// or `null` if dismissed.
Future<Commander?> showCommanderPicker(
  BuildContext context, {
  required bool selectingPartner,
}) {
  final scryfallRepository = context.read<ScryfallRepository>();
  return Navigator.of(context).push<Commander>(
    MaterialPageRoute<Commander>(
      fullscreenDialog: true,
      builder: (_) => BlocProvider(
        create: (_) =>
            CommanderPickerCubit(scryfallRepository: scryfallRepository),
        child: CommanderPickerView(selectingPartner: selectingPartner),
      ),
    ),
  );
}

class CommanderPickerView extends StatefulWidget {
  const CommanderPickerView({required this.selectingPartner, super.key});

  final bool selectingPartner;

  @override
  State<CommanderPickerView> createState() => _CommanderPickerViewState();
}

class _CommanderPickerViewState extends State<CommanderPickerView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    context.read<CommanderPickerCubit>().search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectingPartner
              ? l10n.selectPartnerTitle
              : l10n.selectCommanderTitle,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autocorrect: false,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: l10n.searchCommanderHintText,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _search,
                  child: Text(l10n.searchButtonText),
                ),
              ],
            ),
          ),
          const Expanded(child: _ResultsGrid()),
        ],
      ),
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CommanderPickerCubit, CommanderPickerState>(
      builder: (context, state) {
        switch (state.status) {
          case CommanderPickerStatus.initial:
            return const SizedBox.shrink();
          case CommanderPickerStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case CommanderPickerStatus.failure:
            return Center(child: Text(l10n.somethingWentWrong));
          case CommanderPickerStatus.success:
            if (state.cards.isEmpty) {
              return Center(child: Text(l10n.noCommanders));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 0.72,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: state.cards.length,
              itemBuilder: (context, index) {
                final card = state.cards[index];
                final imageUrl = card.imageUris?.normal ??
                    card.cardFaces?.first.imageUris?.normal ??
                    '';
                return GestureDetector(
                  key: ValueKey('commander-card-${card.id}'),
                  onTap: () =>
                      Navigator.of(context).pop(magicCardToCommander(card)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                        color: AppColors.neutral60,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                );
              },
            );
        }
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/match_details/widgets/commander_picker_test.dart`
Expected: PASS.

- [ ] **Step 5: Verify analyze**

Run: `flutter analyze lib/match_details/widgets/commander_picker.dart`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git add lib/match_details/widgets/commander_picker.dart test/match_details/widgets/commander_picker_test.dart
git commit -m "feat: add full-screen commander picker for match editing"
```

---

### Task 5: `MatchEditCubit`

**Files:**
- Create: `lib/match_details/bloc/match_edit_cubit.dart`
- Create: `lib/match_details/bloc/match_edit_state.dart`
- Test: `test/match_details/bloc/match_edit_cubit_test.dart`

**Interfaces:**
- Consumes: `FirebaseDatabaseRepository.updateGameStats({required GameModel game, required String playerId})`, `GameModel.copyWith(players:)`, `Player.copyWith(...)`.
- Produces:
  - `enum MatchEditStatus { viewing, editing, saving, success, error }`
  - `class MatchEditState { MatchEditStatus status; List<Player> draftPlayers; String errorMessage; bool get isEditing; }`
  - `class MatchEditCubit extends Cubit<MatchEditState> { MatchEditCubit({required FirebaseDatabaseRepository databaseRepository, required String currentUserId}); void startEditing(GameModel game); void cancel(); void updateName(String playerId, String name); void setCommander(String playerId, Commander commander); void setPartner(String playerId, Commander? partner); Future<void> save(); }`

- [ ] **Step 1: Write the failing tests**

```dart
// test/match_details/bloc/match_edit_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

Player _player(String id, String name) => Player(
      id: id,
      name: name,
      playerNumber: 1,
      lifePoints: 40,
      color: 0xFF000000,
      opponents: const [],
      state: PlayerModelState.eliminated,
      placement: 1,
      timeOfDeath: 0,
    );

GameModel _game() => GameModel(
      id: 'game-1',
      players: [_player('p1', 'Alice'), _player('p2', 'Bob')],
      startTime: DateTime(2026, 1, 1),
      endTime: DateTime(2026, 1, 1, 1),
      winnerId: 'p1',
      durationInSeconds: 3600,
    );

const _commander = Commander(
  name: 'Atraxa',
  colors: ['W', 'U', 'B', 'G'],
  cardType: 'Legendary Creature',
  imageUrl: 'img',
  manaCost: '{G}{W}{U}{B}',
  oracleText: 'text',
  artist: 'artist',
);

void main() {
  late FirebaseDatabaseRepository repository;

  setUpAll(() => registerFallbackValue(_game()));

  setUp(() => repository = _MockDatabaseRepository());

  MatchEditCubit build() => MatchEditCubit(
        databaseRepository: repository,
        currentUserId: 'user-1',
      );

  blocTest<MatchEditCubit, MatchEditState>(
    'startEditing seeds the draft and enters editing',
    build: build,
    act: (cubit) => cubit.startEditing(_game()),
    expect: () => [
      isA<MatchEditState>()
          .having((s) => s.status, 'status', MatchEditStatus.editing)
          .having((s) => s.isEditing, 'isEditing', true)
          .having((s) => s.draftPlayers.length, 'draft', 2),
    ],
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'updateName changes only the targeted player',
    build: build,
    act: (cubit) {
      cubit
        ..startEditing(_game())
        ..updateName('p2', 'Bobby');
    },
    verify: (cubit) {
      expect(
        cubit.state.draftPlayers.firstWhere((p) => p.id == 'p2').name,
        'Bobby',
      );
      expect(
        cubit.state.draftPlayers.firstWhere((p) => p.id == 'p1').name,
        'Alice',
      );
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'setCommander updates the targeted player commander',
    build: build,
    act: (cubit) {
      cubit
        ..startEditing(_game())
        ..setCommander('p1', _commander);
    },
    verify: (cubit) {
      expect(
        cubit.state.draftPlayers.firstWhere((p) => p.id == 'p1').commander,
        _commander,
      );
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'setPartner(null) clears the partner',
    build: build,
    act: (cubit) {
      cubit
        ..startEditing(_game())
        ..setPartner('p1', _commander)
        ..setPartner('p1', null);
    },
    verify: (cubit) {
      expect(
        cubit.state.draftPlayers.firstWhere((p) => p.id == 'p1').partner,
        isNull,
      );
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'cancel returns to viewing with an empty draft',
    build: build,
    act: (cubit) {
      cubit
        ..startEditing(_game())
        ..cancel();
    },
    verify: (cubit) {
      expect(cubit.state.status, MatchEditStatus.viewing);
      expect(cubit.state.isEditing, false);
      expect(cubit.state.draftPlayers, isEmpty);
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'save persists the merged game and ends in success',
    setUp: () {
      when(
        () => repository.updateGameStats(
          game: any(named: 'game'),
          playerId: any(named: 'playerId'),
        ),
      ).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      cubit
        ..startEditing(_game())
        ..updateName('p1', 'Alicia');
      await cubit.save();
    },
    verify: (cubit) {
      expect(cubit.state.status, MatchEditStatus.success);
      final captured = verify(
        () => repository.updateGameStats(
          game: captureAny(named: 'game'),
          playerId: 'user-1',
        ),
      ).captured.single as GameModel;
      expect(
        captured.players.firstWhere((p) => p.id == 'p1').name,
        'Alicia',
      );
    },
  );

  blocTest<MatchEditCubit, MatchEditState>(
    'save emits error and preserves the draft when the repository throws',
    setUp: () {
      when(
        () => repository.updateGameStats(
          game: any(named: 'game'),
          playerId: any(named: 'playerId'),
        ),
      ).thenThrow(Exception('network'));
    },
    build: build,
    act: (cubit) async {
      cubit.startEditing(_game());
      await cubit.save();
    },
    verify: (cubit) {
      expect(cubit.state.status, MatchEditStatus.error);
      expect(cubit.state.isEditing, true);
      expect(cubit.state.draftPlayers.length, 2);
    },
  );
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/match_details/bloc/match_edit_cubit_test.dart`
Expected: FAIL — cannot resolve `match_edit_cubit.dart`.

- [ ] **Step 3: Create the state**

```dart
// lib/match_details/bloc/match_edit_state.dart
part of 'match_edit_cubit.dart';

enum MatchEditStatus { viewing, editing, saving, success, error }

class MatchEditState extends Equatable {
  const MatchEditState({
    this.status = MatchEditStatus.viewing,
    this.draftPlayers = const [],
    this.errorMessage = '',
  });

  final MatchEditStatus status;
  final List<Player> draftPlayers;
  final String errorMessage;

  bool get isEditing =>
      status == MatchEditStatus.editing ||
      status == MatchEditStatus.saving ||
      status == MatchEditStatus.error;

  MatchEditState copyWith({
    MatchEditStatus? status,
    List<Player>? draftPlayers,
    String? errorMessage,
  }) {
    return MatchEditState(
      status: status ?? this.status,
      draftPlayers: draftPlayers ?? this.draftPlayers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, draftPlayers, errorMessage];
}
```

- [ ] **Step 4: Create the cubit**

```dart
// lib/match_details/bloc/match_edit_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/player_repository.dart';

part 'match_edit_state.dart';

class MatchEditCubit extends Cubit<MatchEditState> {
  MatchEditCubit({
    required FirebaseDatabaseRepository databaseRepository,
    required String currentUserId,
  })  : _databaseRepository = databaseRepository,
        _currentUserId = currentUserId,
        super(const MatchEditState());

  final FirebaseDatabaseRepository _databaseRepository;
  final String _currentUserId;

  GameModel? _game;

  void startEditing(GameModel game) {
    _game = game;
    emit(
      state.copyWith(
        status: MatchEditStatus.editing,
        draftPlayers: List<Player>.of(game.players),
      ),
    );
  }

  void cancel() {
    _game = null;
    emit(const MatchEditState());
  }

  void updateName(String playerId, String name) {
    emit(
      state.copyWith(
        draftPlayers: _replace(playerId, (p) => p.copyWith(name: name)),
      ),
    );
  }

  void setCommander(String playerId, Commander commander) {
    emit(
      state.copyWith(
        draftPlayers:
            _replace(playerId, (p) => p.copyWith(commander: commander)),
      ),
    );
  }

  void setPartner(String playerId, Commander? partner) {
    emit(
      state.copyWith(
        draftPlayers:
            _replace(playerId, (p) => p.copyWith(partner: () => partner)),
      ),
    );
  }

  Future<void> save() async {
    final game = _game;
    if (game == null) return;
    emit(state.copyWith(status: MatchEditStatus.saving));
    try {
      final updated = game.copyWith(players: state.draftPlayers);
      await _databaseRepository.updateGameStats(
        game: updated,
        playerId: _currentUserId,
      );
      _game = updated;
      emit(state.copyWith(status: MatchEditStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: MatchEditStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  List<Player> _replace(String playerId, Player Function(Player) update) {
    return state.draftPlayers
        .map((p) => p.id == playerId ? update(p) : p)
        .toList();
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/match_details/bloc/match_edit_cubit_test.dart`
Expected: PASS (all `blocTest`s).

- [ ] **Step 6: Commit**

```bash
git add lib/match_details/bloc/match_edit_cubit.dart lib/match_details/bloc/match_edit_state.dart test/match_details/bloc/match_edit_cubit_test.dart
git commit -m "feat: add MatchEditCubit for editing finished matches"
```

---

### Task 6: `EditablePlayerTile` widget

**Files:**
- Create: `lib/match_details/widgets/editable_player_tile.dart`
- Test: `test/match_details/widgets/editable_player_tile_test.dart`

**Interfaces:**
- Consumes: `Player`, `context.l10n.{playerNameLabel, addPartnerLabel, removePartnerTooltip}`.
- Produces: `class EditablePlayerTile extends StatefulWidget { Player player; ValueChanged<String> onNameChanged; VoidCallback onTapCommander; VoidCallback onTapPartner; VoidCallback onRemovePartner; }`
- Keys: `edit-commander-${player.id}`, `add-partner-${player.id}`, `edit-partner-${player.id}`, `remove-partner-${player.id}`.

- [ ] **Step 1: Write the failing test**

```dart
// test/match_details/widgets/editable_player_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/widgets/editable_player_tile.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/helpers.dart';

Player _player({Commander? partner}) => Player(
      id: 'p1',
      name: 'Alice',
      playerNumber: 1,
      lifePoints: 40,
      color: 0xFF112233,
      opponents: const [],
      state: PlayerModelState.eliminated,
      placement: 1,
      timeOfDeath: 0,
      partner: partner,
    );

const _commander = Commander(
  name: 'Atraxa',
  colors: ['W'],
  cardType: 'Legendary Creature',
  imageUrl: '',
  manaCost: '',
  oracleText: '',
  artist: '',
);

void main() {
  testWidgets('shows the name and calls onNameChanged when edited',
      (tester) async {
    final changes = <String>[];
    await tester.pumpApp(
      EditablePlayerTile(
        player: _player(),
        onNameChanged: changes.add,
        onTapCommander: () {},
        onTapPartner: () {},
        onRemovePartner: () {},
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Alicia');
    expect(changes.last, 'Alicia');
  });

  testWidgets('tapping the commander avatar calls onTapCommander',
      (tester) async {
    var tapped = false;
    await tester.pumpApp(
      EditablePlayerTile(
        player: _player(),
        onNameChanged: (_) {},
        onTapCommander: () => tapped = true,
        onTapPartner: () {},
        onRemovePartner: () {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey('edit-commander-p1')));
    expect(tapped, isTrue);
  });

  testWidgets('shows Add partner affordance when no partner is set',
      (tester) async {
    var tapped = false;
    await tester.pumpApp(
      EditablePlayerTile(
        player: _player(),
        onNameChanged: (_) {},
        onTapCommander: () {},
        onTapPartner: () => tapped = true,
        onRemovePartner: () {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey('add-partner-p1')));
    expect(tapped, isTrue);
  });

  testWidgets('shows remove-partner control when a partner is set',
      (tester) async {
    var removed = false;
    await tester.pumpApp(
      EditablePlayerTile(
        player: _player(partner: _commander),
        onNameChanged: (_) {},
        onTapCommander: () {},
        onTapPartner: () {},
        onRemovePartner: () => removed = true,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('remove-partner-p1')));
    expect(removed, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/match_details/widgets/editable_player_tile_test.dart`
Expected: FAIL — cannot resolve `editable_player_tile.dart`.

- [ ] **Step 3: Create the widget**

```dart
// lib/match_details/widgets/editable_player_tile.dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:player_repository/player_repository.dart';

class EditablePlayerTile extends StatefulWidget {
  const EditablePlayerTile({
    required this.player,
    required this.onNameChanged,
    required this.onTapCommander,
    required this.onTapPartner,
    required this.onRemovePartner,
    super.key,
  });

  final Player player;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onTapCommander;
  final VoidCallback onTapPartner;
  final VoidCallback onRemovePartner;

  @override
  State<EditablePlayerTile> createState() => _EditablePlayerTileState();
}

class _EditablePlayerTileState extends State<EditablePlayerTile> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.player.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final player = widget.player;
    final partner = player.partner;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              key: ValueKey('edit-commander-${player.id}'),
              onTap: widget.onTapCommander,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Color(player.color),
                backgroundImage: player.commander?.imageUrl.isNotEmpty ?? false
                    ? NetworkImage(player.commander!.imageUrl)
                    : null,
                child: player.commander == null
                    ? const Icon(Icons.add_a_photo, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    onChanged: widget.onNameChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: l10n.playerNameLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (partner == null)
                    TextButton.icon(
                      key: ValueKey('add-partner-${player.id}'),
                      onPressed: widget.onTapPartner,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.addPartnerLabel),
                    )
                  else
                    Row(
                      children: [
                        GestureDetector(
                          key: ValueKey('edit-partner-${player.id}'),
                          onTap: widget.onTapPartner,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(player.color),
                            backgroundImage: partner.imageUrl.isNotEmpty
                                ? NetworkImage(partner.imageUrl)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            partner.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          key: ValueKey('remove-partner-${player.id}'),
                          tooltip: l10n.removePartnerTooltip,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: widget.onRemovePartner,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/match_details/widgets/editable_player_tile_test.dart`
Expected: PASS (all four).

- [ ] **Step 5: Commit**

```bash
git add lib/match_details/widgets/editable_player_tile.dart test/match_details/widgets/editable_player_tile_test.dart
git commit -m "feat: add EditablePlayerTile widget for match editing"
```

---

### Task 7: Edit-aware app bar actions

**Files:**
- Create: `lib/match_details/widgets/match_details_app_bar_actions.dart`
- Test: `test/match_details/widgets/match_details_app_bar_actions_test.dart`

**Interfaces:**
- Consumes: `MatchEditCubit` (`startEditing`, `cancel`, `save`, `state.isEditing`,
  `state.status`), `GameModel`, `context.l10n.{editMatchTooltip, saveButtonLabel,
  cancelButtonLabel}`, and a `deleteAction` widget slot (so this widget does not depend
  on `MatchDetailsBloc`).
- Produces: `class MatchDetailsAppBarActions extends StatelessWidget { GameModel game; Widget deleteAction; }`

- [ ] **Step 1: Write the failing test**

```dart
// test/match_details/widgets/match_details_app_bar_actions_test.dart
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:magic_yeti/match_details/widgets/match_details_app_bar_actions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/helpers.dart';

class _MockDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

GameModel _game() => GameModel(
      id: 'g1',
      players: [
        Player(
          id: 'p1',
          name: 'Alice',
          playerNumber: 1,
          lifePoints: 40,
          color: 0xFF000000,
          opponents: const [],
          state: PlayerModelState.eliminated,
          placement: 1,
          timeOfDeath: 0,
        ),
      ],
      startTime: DateTime(2026),
      endTime: DateTime(2026, 1, 1, 1),
      winnerId: 'p1',
      durationInSeconds: 10,
    );

void main() {
  late MatchEditCubit cubit;

  setUp(() {
    cubit = MatchEditCubit(
      databaseRepository: _MockDatabaseRepository(),
      currentUserId: 'u1',
    );
  });

  Widget subject() => BlocProvider.value(
        value: cubit,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              MatchDetailsAppBarActions(
                game: _game(),
                deleteAction: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      );

  testWidgets('shows edit + delete when viewing', (tester) async {
    await tester.pumpApp(subject());
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('tapping edit enters editing and shows save/cancel',
      (tester) async {
    await tester.pumpApp(subject());
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(cubit.state.isEditing, isTrue);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('tapping cancel returns to viewing', (tester) async {
    await tester.pumpApp(subject());
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(cubit.state.isEditing, isFalse);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/match_details/widgets/match_details_app_bar_actions_test.dart`
Expected: FAIL — cannot resolve `match_details_app_bar_actions.dart`.

- [ ] **Step 3: Create the widget**

```dart
// lib/match_details/widgets/match_details_app_bar_actions.dart
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';

class MatchDetailsAppBarActions extends StatelessWidget {
  const MatchDetailsAppBarActions({
    required this.game,
    required this.deleteAction,
    super.key,
  });

  final GameModel game;
  final Widget deleteAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<MatchEditCubit, MatchEditState>(
      builder: (context, state) {
        if (state.isEditing) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.cancelButtonLabel,
                icon: const Icon(Icons.close),
                onPressed: () => context.read<MatchEditCubit>().cancel(),
              ),
              IconButton(
                tooltip: l10n.saveButtonLabel,
                icon: const Icon(Icons.check),
                onPressed: state.status == MatchEditStatus.saving
                    ? null
                    : () => context.read<MatchEditCubit>().save(),
              ),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.editMatchTooltip,
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.read<MatchEditCubit>().startEditing(game),
            ),
            deleteAction,
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/match_details/widgets/match_details_app_bar_actions_test.dart`
Expected: PASS (all three).

- [ ] **Step 5: Commit**

```bash
git add lib/match_details/widgets/match_details_app_bar_actions.dart test/match_details/widgets/match_details_app_bar_actions_test.dart
git commit -m "feat: add edit-aware match details app bar actions"
```

---

### Task 8: Editable players section

**Files:**
- Create: `lib/match_details/widgets/match_edit_players_list.dart`
- Test: `test/match_details/widgets/match_edit_players_list_test.dart`

**Interfaces:**
- Consumes: `MatchEditCubit` (`state.draftPlayers`, `updateName`, `setCommander`,
  `setPartner`), `EditablePlayerTile`, `PickCommander` typedef + `showCommanderPicker`
  default from Task 4.
- Produces: `class MatchEditPlayersList extends StatelessWidget { PickCommander pickCommander; }` (defaults to `showCommanderPicker`).

- [ ] **Step 1: Write the failing test**

```dart
// test/match_details/widgets/match_edit_players_list_test.dart
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:magic_yeti/match_details/widgets/match_edit_players_list.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/helpers.dart';

class _MockDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

const _picked = Commander(
  name: 'Krenko',
  colors: ['R'],
  cardType: 'Legendary Creature',
  imageUrl: '',
  manaCost: '',
  oracleText: '',
  artist: '',
);

GameModel _game() => GameModel(
      id: 'g1',
      players: [
        Player(
          id: 'p1',
          name: 'Alice',
          playerNumber: 1,
          lifePoints: 40,
          color: 0xFF000000,
          opponents: const [],
          state: PlayerModelState.eliminated,
          placement: 1,
          timeOfDeath: 0,
        ),
      ],
      startTime: DateTime(2026),
      endTime: DateTime(2026, 1, 1, 1),
      winnerId: 'p1',
      durationInSeconds: 10,
    );

void main() {
  late MatchEditCubit cubit;

  setUp(() {
    cubit = MatchEditCubit(
      databaseRepository: _MockDatabaseRepository(),
      currentUserId: 'u1',
    )..startEditing(_game());
  });

  testWidgets('renders a tile per draft player', (tester) async {
    await tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: SingleChildScrollView(
          child: MatchEditPlayersList(
            pickCommander: (_, {required bool selectingPartner}) async => null,
          ),
        ),
      ),
    );
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('selecting a commander from the picker updates the draft',
      (tester) async {
    await tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: SingleChildScrollView(
          child: MatchEditPlayersList(
            pickCommander: (_, {required bool selectingPartner}) async =>
                _picked,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('edit-commander-p1')));
    await tester.pumpAndSettle();

    expect(cubit.state.draftPlayers.first.commander, _picked);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/match_details/widgets/match_edit_players_list_test.dart`
Expected: FAIL — cannot resolve `match_edit_players_list.dart`.

- [ ] **Step 3: Create the widget**

```dart
// lib/match_details/widgets/match_edit_players_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:magic_yeti/match_details/widgets/commander_picker.dart';
import 'package:magic_yeti/match_details/widgets/editable_player_tile.dart';

class MatchEditPlayersList extends StatelessWidget {
  const MatchEditPlayersList({
    this.pickCommander = showCommanderPicker,
    super.key,
  });

  final PickCommander pickCommander;

  Future<void> _pickCommander(BuildContext context, String playerId) async {
    final cubit = context.read<MatchEditCubit>();
    final commander = await pickCommander(context, selectingPartner: false);
    if (commander != null) {
      cubit.setCommander(playerId, commander);
    }
  }

  Future<void> _pickPartner(BuildContext context, String playerId) async {
    final cubit = context.read<MatchEditCubit>();
    final commander = await pickCommander(context, selectingPartner: true);
    if (commander != null) {
      cubit.setPartner(playerId, commander);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchEditCubit, MatchEditState>(
      builder: (context, state) {
        return Column(
          children: [
            for (final player in state.draftPlayers)
              EditablePlayerTile(
                key: ValueKey('editable-tile-${player.id}'),
                player: player,
                onNameChanged: (name) =>
                    context.read<MatchEditCubit>().updateName(player.id, name),
                onTapCommander: () => _pickCommander(context, player.id),
                onTapPartner: () => _pickPartner(context, player.id),
                onRemovePartner: () =>
                    context.read<MatchEditCubit>().setPartner(player.id, null),
              ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/match_details/widgets/match_edit_players_list_test.dart`
Expected: PASS (both).

- [ ] **Step 5: Commit**

```bash
git add lib/match_details/widgets/match_edit_players_list.dart test/match_details/widgets/match_edit_players_list_test.dart
git commit -m "feat: add editable players list for match editing"
```

---

### Task 9: Integrate edit mode into the Match Details screen

**Files:**
- Modify: `lib/match_details/view/match_details_page.dart`
- Modify: `lib/match_details/match_details.dart` (exports)
- Verify: `flutter analyze` + full `flutter test` + manual run

**Interfaces:**
- Consumes: `MatchEditCubit`, `MatchDetailsAppBarActions`, `MatchEditPlayersList`,
  `context.l10n.{matchUpdatedMessage, errorSnackbarMessage}`.

- [ ] **Step 1: Provide `MatchEditCubit` in `MatchDetailsPage.build`**

Replace the `build` method body of `MatchDetailsPage` (wrap the existing provider in a
`MultiBlocProvider`):

```dart
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MatchDetailsBloc(
            databaseRepository: context.read<FirebaseDatabaseRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => MatchEditCubit(
            databaseRepository: context.read<FirebaseDatabaseRepository>(),
            currentUserId: context.read<AppBloc>().state.user.id,
          ),
        ),
      ],
      child: MatchDetailsView(gameId: gameId),
    );
  }
```

Add these imports at the top of the file:

```dart
import 'package:magic_yeti/match_details/bloc/match_edit_cubit.dart';
import 'package:magic_yeti/match_details/widgets/match_details_app_bar_actions.dart';
import 'package:magic_yeti/match_details/widgets/match_edit_players_list.dart';
```

- [ ] **Step 2: Add the save/error listener in `MatchDetailsView.build`**

Wrap the existing returned `BlocConsumer<MatchDetailsBloc, MatchDetailsState>` in a
`BlocListener<MatchEditCubit, MatchEditState>`:

```dart
    return BlocListener<MatchEditCubit, MatchEditState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == MatchEditStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.matchUpdatedMessage),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state.status == MatchEditStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(context.l10n.errorSnackbarMessage(state.errorMessage)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: BlocConsumer<MatchDetailsBloc, MatchDetailsState>(
        // ...existing listener + builder unchanged...
      ),
    );
```

- [ ] **Step 3: Make the phone view edit-aware**

In `_PhoneMatchDetailsView.build`, replace the `actions:` list and the `body:`:

```dart
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.matchDetailsHeading),
        actions: [
          MatchDetailsAppBarActions(
            game: game,
            deleteAction: _DeleteMatchButton(gameId: gameId),
          ),
        ],
      ),
      body: BlocBuilder<MatchEditCubit, MatchEditState>(
        builder: (context, editState) {
          if (editState.isEditing) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: MatchEditPlayersList(),
            );
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MatchWinnerWidget(
                    winner: winningPlayer,
                    gameDuration: gameDuration,
                    startingPlayerId: game.startingPlayerId,
                    gameId: gameId,
                  ),
                  const SizedBox(height: 16),
                  MatchStandingsWidget(
                    players: game.players,
                    winner: winningPlayer,
                    currentUserFirebaseId: game.hostId,
                    startingPlayerId: game.startingPlayerId,
                    onSelectPlayer: (player) =>
                        _handlePlayerSelection(context, player),
                  ),
                  const SizedBox(height: 16),
                  MatchMetadataWidget(game: game),
                ],
              ),
            ),
          );
        },
      ),
    );
```

- [ ] **Step 4: Make the tablet view edit-aware**

In `_TabletMatchDetailsView.build`, replace `actions: [_DeleteMatchButton(gameId: gameId)]`
with the `MatchDetailsAppBarActions` widget (same as Step 3), and wrap the body in a
`BlocBuilder<MatchEditCubit, MatchEditState>`:

```dart
      body: BlocBuilder<MatchEditCubit, MatchEditState>(
        builder: (context, editState) {
          if (editState.isEditing) {
            return const CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(child: MatchEditPlayersList()),
                ),
              ],
            );
          }
          return CustomScrollView(
            slivers: [
              // ...existing SliverPadding / SliverList content unchanged...
            ],
          );
        },
      ),
```

- [ ] **Step 5: Export the new units from the feature barrel**

`lib/match_details/match_details.dart`:

```dart
export 'bloc/commander_picker_cubit.dart';
export 'bloc/match_details_bloc.dart';
export 'bloc/match_edit_cubit.dart';
export 'view/match_details_page.dart';
export 'widgets/commander_picker.dart';
export 'widgets/editable_player_tile.dart';
export 'widgets/match_details_app_bar_actions.dart';
export 'widgets/match_edit_players_list.dart';
```

- [ ] **Step 6: Analyze the feature**

Run: `flutter analyze lib/match_details`
Expected: "No issues found!"

- [ ] **Step 7: Run the full test suite**

Run: `flutter test`
Expected: all tests pass (new cubit/widget tests plus the existing `app_test`).

- [ ] **Step 8: Manual verification**

Run: `flutter run --flavor development --target lib/main_development.dart`, then:
1. Home → a finished match → Match Details.
2. Tap the **pencil**. Expected: winner/metadata hide; an editable list of all players
   appears; app bar shows **✓** and **✕**.
3. Change a player's **name**; tap a **commander avatar** → picker opens → search →
   tap a card → returns and the avatar updates.
4. **Add partner** → picker (partner title) → select; then **✕** removes it.
5. Tap **✓**. Expected: "Match updated" snackbar; screen returns to read-only with the
   new name/commander (reflected via the live `MatchHistoryBloc` stream).
6. Re-enter edit, change something, tap **✕** (cancel). Expected: changes discarded.

- [ ] **Step 9: Commit**

```bash
git add lib/match_details/view/match_details_page.dart lib/match_details/match_details.dart
git commit -m "feat: enable inline editing of finished matches"
```

---

## Notes / Known Limitations

- Edits write only the current user's copy (`users/{currentUserId}/matches/{gameId}`).
  Other participants' synced copies are not updated. Fan-out is a future enhancement.
- `stats_overview` derives from the games list, so edited commanders/names flow into
  stats automatically.
- Winner / placement / who-went-first / duration / room id / date remain read-only.
- Refinement vs. spec wording: editing happens in a single players list (Winner and
  Metadata cards hidden while editing) to avoid two competing editable controls for the
  winner. Read-only view is unchanged.
```