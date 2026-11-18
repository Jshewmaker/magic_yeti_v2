# Customize Player Page — Plan C: Two-Pane UI Redesign

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rotated, search-only customize page with a non-rotated two-pane "player sheet": a player/identity + live tracking preview on the left, and a Favorites/Recent/Search picker (with auto-detected second-card handling) on the right.

**Architecture:** Refactor `PlayerCustomizationState`/events/bloc to model a single `commander`, an optional second card classified by `commanderPairingFor` (a `partner` = second clock, or a `background` = color-only), plus device recents/favorites from `CommanderLibraryRepository`. Rebuild `CustomizePlayerView` as a two-pane `Row` composed of focused widgets. Remove per-seat rotation (this fixes the original upside-down-keyboard bug). Extend `CommanderHeroBanner` to show a background as a second art.

**Tech Stack:** Flutter, `flutter_bloc`, `app_ui` (`AppColors`/`AppSpacing`), `player_repository`, `bloc_test`.

**Depends on:** Plan A (`Commander.keywords`, `Player.background`, `commanderPairingFor`, save path) and Plan B (`CommanderLibraryRepository`).

## Global Constraints

- SDK floor `>=3.8.0 <4.0.0`; `very_good_analysis` ^10.1.0; `flutter analyze` clean.
- Use `AppColors` / `AppSpacing` from `app_ui` (already used across this feature). New user-facing strings may be hardcoded, matching the existing mix in these files.
- Do not rotate this page. The life counter keeps its own rotation; only the pushed customize route renders upright.
- A Background must never populate `Player.partner` (it would render a bogus partner damage clock). Backgrounds flow into `Player.background` only.
- Color-identity order for pips: `W, U, B, R, G`.

---

### Task 1: Remove per-seat rotation (fixes the keyboard bug)

**Files:**
- Modify: `lib/player/view/customize_player_page.dart` (remove `RotatedBox`, `isRotated`)
- Modify: `lib/life_counter/widgets/life_counter_widget.dart:62-73` (drop `isRotated:`)

**Interfaces:**
- Produces: `CustomizePlayerPage({required String playerId})` and
  `CustomizePlayerView({required String playerId})` — no `isRotated`.

- [ ] **Step 1: Drop `isRotated` from the page widgets**

In `lib/player/view/customize_player_page.dart`:
- In `CustomizePlayerPage`: remove the `this.isRotated = false,` constructor line and the
  `final bool isRotated;` field; change the child to
  `CustomizePlayerView(playerId: playerId)`.
- In `CustomizePlayerView`: remove the `this.isRotated = false,` constructor line and the
  `final bool isRotated;` field.
- In `_CustomizePlayerViewState.build`: delete the `RotatedBox(quarterTurns: ... , child:`
  wrapper and its matching `)`, so the returned widget is the `Scaffold` directly.

- [ ] **Step 2: Update the call site**

In `lib/life_counter/widgets/life_counter_widget.dart`, change the push to:

```dart
                      child: CustomizePlayerPage(
                        playerId: player.id,
                      ),
```

(Remove the `isRotated: rotate,` argument.)

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/player/view/customize_player_page.dart lib/life_counter/widgets/life_counter_widget.dart`
Expected: `No issues found!`

- [ ] **Step 4: Manual check (the original bug)**

Run the app, start a 4-player game, tap player 3's name. Expected: the customize page
renders upright and the keyboard appears correctly oriented from the bottom.

- [ ] **Step 5: Commit**

```bash
git add lib/player/view/customize_player_page.dart lib/life_counter/widgets/life_counter_widget.dart
git commit -m "fix: stop rotating customize player page so keyboard is upright"
```

---

### Task 2: Refactor `PlayerCustomizationState`

**Files:**
- Modify: `lib/player/view/bloc/player_customization_state.dart` (full rewrite)

**Interfaces:**
- Produces: state with `commander`, `partner`, `background`, `availablePairing`
  (`CommanderPairing`), `selectingSecondCard`, `recents`/`favorites`
  (`List<Commander>`), `favoriteIds` (`Set<String>`), plus derived `damageClocks`
  (`int`) and `colorIdentity` (`List<String>`). `copyWith` uses `Commander? Function()?`
  wrappers for `commander`/`partner`/`background` so they can be cleared.

- [ ] **Step 1: Rewrite the state file**

Replace the entire contents of `lib/player/view/bloc/player_customization_state.dart`:

```dart
part of 'player_customization_bloc.dart';

enum PlayerCustomizationStatus { initial, loading, success, failure }

class PlayerCustomizationState extends Equatable {
  const PlayerCustomizationState({
    this.status = PlayerCustomizationStatus.initial,
    this.name = '',
    this.commander,
    this.partner,
    this.background,
    this.cardList,
    this.magicCardList,
    this.isAccountOwner = false,
    this.showOnlyLegendary = true,
    this.availablePairing = CommanderPairing.none,
    this.selectingSecondCard = false,
    this.recents = const [],
    this.favorites = const [],
    this.favoriteIds = const {},
    this.selectedFriend,
    this.pinValidated = false,
    this.pinError = '',
  });

  final PlayerCustomizationStatus status;
  final String name;
  final Commander? commander;
  final Commander? partner;
  final Commander? background;
  final SearchCards? cardList;
  final List<MagicCard>? magicCardList;
  final bool isAccountOwner;
  final bool showOnlyLegendary;
  final CommanderPairing availablePairing;
  final bool selectingSecondCard;
  final List<Commander> recents;
  final List<Commander> favorites;
  final Set<String> favoriteIds;
  final FriendModel? selectedFriend;
  final bool pinValidated;
  final String pinError;

  /// Commander-damage clocks this player will be tracked with: the commander,
  /// plus the partner if present. A background never adds a clock.
  int get damageClocks => 1 + (partner != null ? 1 : 0);

  /// Combined color identity across commander, partner and background, ordered
  /// W, U, B, R, G.
  List<String> get colorIdentity {
    final set = <String>{};
    for (final c in [commander, partner, background]) {
      set.addAll(c?.colorIdentity ?? c?.colors ?? const []);
    }
    const order = ['W', 'U', 'B', 'R', 'G'];
    return order.where(set.contains).toList();
  }

  @override
  List<Object?> get props => [
        status,
        name,
        commander,
        partner,
        background,
        cardList,
        magicCardList,
        isAccountOwner,
        showOnlyLegendary,
        availablePairing,
        selectingSecondCard,
        recents,
        favorites,
        favoriteIds,
        selectedFriend,
        pinValidated,
        pinError,
      ];

  PlayerCustomizationState copyWith({
    PlayerCustomizationStatus? status,
    String? name,
    Commander? Function()? commander,
    Commander? Function()? partner,
    Commander? Function()? background,
    SearchCards? cardList,
    List<MagicCard>? filteredCards,
    bool? isAccountOwner,
    bool? showOnlyLegendary,
    CommanderPairing? availablePairing,
    bool? selectingSecondCard,
    List<Commander>? recents,
    List<Commander>? favorites,
    Set<String>? favoriteIds,
    FriendModel? selectedFriend,
    bool? pinValidated,
    String? pinError,
  }) {
    return PlayerCustomizationState(
      status: status ?? this.status,
      name: name ?? this.name,
      commander: commander != null ? commander() : this.commander,
      partner: partner != null ? partner() : this.partner,
      background: background != null ? background() : this.background,
      cardList: cardList ?? this.cardList,
      magicCardList: filteredCards ?? this.magicCardList,
      isAccountOwner: isAccountOwner ?? this.isAccountOwner,
      showOnlyLegendary: showOnlyLegendary ?? this.showOnlyLegendary,
      availablePairing: availablePairing ?? this.availablePairing,
      selectingSecondCard: selectingSecondCard ?? this.selectingSecondCard,
      recents: recents ?? this.recents,
      favorites: favorites ?? this.favorites,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      selectedFriend: selectedFriend ?? this.selectedFriend,
      pinValidated: pinValidated ?? this.pinValidated,
      pinError: pinError ?? this.pinError,
    );
  }

  PlayerCustomizationState copyWithClearedFriend() {
    return PlayerCustomizationState(
      status: status,
      name: name,
      commander: commander,
      partner: partner,
      background: background,
      cardList: cardList,
      magicCardList: magicCardList,
      isAccountOwner: isAccountOwner,
      showOnlyLegendary: showOnlyLegendary,
      availablePairing: availablePairing,
      selectingSecondCard: selectingSecondCard,
      recents: recents,
      favorites: favorites,
      favoriteIds: favoriteIds,
    );
  }
}
```

- [ ] **Step 2: (Compiles after Task 3/4)** — the bloc references old fields until updated; do
not run analyze until Task 4. Commit deferred to Task 4.

---

### Task 3: Refactor customization events

**Files:**
- Modify: `lib/player/view/bloc/player_customization_event.dart` (full rewrite)

**Interfaces:**
- Produces events: `LibraryRequested`, `CardListRequested({cardName, searchBackgrounds})`,
  `CommanderSelected(Commander)`, `SecondCardSelected(Commander)`,
  `StartSelectingSecondCard`, `CancelSelectingSecondCard`, `SecondCardCleared`,
  `CommanderFavoriteToggled(Commander)`, plus the unchanged `UpdateAccountOwnership`,
  `UpdateCommanderFilters({showOnlyLegendary})`, `ClearCardList`, `SelectFriend`,
  `ClearFriend`, `ValidatePin`.

- [ ] **Step 1: Rewrite the events file**

Replace the entire contents of `lib/player/view/bloc/player_customization_event.dart`:

```dart
part of 'player_customization_bloc.dart';

sealed class PlayerCustomizationEvent extends Equatable {
  const PlayerCustomizationEvent();

  @override
  List<Object?> get props => [];
}

/// Loads device recents + favorites into state.
final class LibraryRequested extends PlayerCustomizationEvent {
  const LibraryRequested();
}

final class CardListRequested extends PlayerCustomizationEvent {
  const CardListRequested({
    required this.cardName,
    this.searchBackgrounds = false,
  });

  final String cardName;
  final bool searchBackgrounds;

  @override
  List<Object> get props => [cardName, searchBackgrounds];
}

/// User picked a primary commander.
final class CommanderSelected extends PlayerCustomizationEvent {
  const CommanderSelected(this.commander);

  final Commander commander;

  @override
  List<Object?> get props => [commander];
}

/// User picked the second card (partner or background, per availablePairing).
final class SecondCardSelected extends PlayerCustomizationEvent {
  const SecondCardSelected(this.card);

  final Commander card;

  @override
  List<Object?> get props => [card];
}

final class StartSelectingSecondCard extends PlayerCustomizationEvent {
  const StartSelectingSecondCard();
}

final class CancelSelectingSecondCard extends PlayerCustomizationEvent {
  const CancelSelectingSecondCard();
}

final class SecondCardCleared extends PlayerCustomizationEvent {
  const SecondCardCleared();
}

final class CommanderFavoriteToggled extends PlayerCustomizationEvent {
  const CommanderFavoriteToggled(this.commander);

  final Commander commander;

  @override
  List<Object?> get props => [commander];
}

final class ClearCardList extends PlayerCustomizationEvent {
  const ClearCardList();
}

final class UpdateAccountOwnership extends PlayerCustomizationEvent {
  const UpdateAccountOwnership({required this.isOwner});

  final bool isOwner;

  @override
  List<Object> get props => [isOwner];
}

final class UpdateCommanderFilters extends PlayerCustomizationEvent {
  const UpdateCommanderFilters({required this.showOnlyLegendary});

  final bool showOnlyLegendary;

  @override
  List<Object> get props => [showOnlyLegendary];
}

final class SelectFriend extends PlayerCustomizationEvent {
  const SelectFriend({required this.friend});

  final FriendModel friend;

  @override
  List<Object> get props => [friend];
}

final class ClearFriend extends PlayerCustomizationEvent {
  const ClearFriend();
}

final class ValidatePin extends PlayerCustomizationEvent {
  const ValidatePin({required this.pin, required this.friendUserId});

  final String pin;
  final String friendUserId;

  @override
  List<Object> get props => [pin, friendUserId];
}
```

- [ ] **Step 2:** Commit deferred to Task 4 (bloc must update for it to compile).

---

### Task 4: Refactor the customization bloc

**Files:**
- Modify: `lib/player/view/bloc/player_customization_bloc.dart` (full rewrite)
- Test: `test/player/player_customization_bloc_test.dart` (create)

**Interfaces:**
- Consumes: `CommanderLibraryRepository` (Plan B), `commanderPairingFor` (Plan A),
  `magicCardToCommander` (`lib/app/utils/commander_mapper.dart`).
- Produces: `PlayerCustomizationBloc({required ScryfallRepository, required
  FirebaseDatabaseRepository, required CommanderLibraryRepository})`.

- [ ] **Step 1: Write the failing bloc test**

Create `test/player/player_customization_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class _MockScryfall extends Mock implements ScryfallRepository {}

class _MockDb extends Mock implements FirebaseDatabaseRepository {}

class _FakeLibrary implements CommanderLibraryRepository {
  final List<Commander> recents = [];
  final List<Commander> favorites = [];
  String _id(Commander c) => c.oracleId ?? c.name;

  @override
  Future<void> addRecent(Commander c) async {
    recents
      ..removeWhere((e) => _id(e) == _id(c))
      ..insert(0, c);
  }

  @override
  Future<List<Commander>> getRecents() async => recents;

  @override
  Future<List<Commander>> getFavorites() async => favorites;

  @override
  Future<bool> isFavorite(Commander c) async =>
      favorites.any((e) => _id(e) == _id(c));

  @override
  Future<bool> toggleFavorite(Commander c) async {
    final i = favorites.indexWhere((e) => _id(e) == _id(c));
    if (i >= 0) {
      favorites.removeAt(i);
      return false;
    }
    favorites.insert(0, c);
    return true;
  }
}

Commander cmdr({
  String name = 'X',
  String? oracleId = 'x',
  List<String> keywords = const [],
  String oracleText = '',
}) =>
    Commander(
      oracleId: oracleId,
      name: name,
      colors: const ['U'],
      cardType: 'Legendary Creature',
      imageUrl: 'https://e/$name.jpg',
      manaCost: '{U}',
      oracleText: oracleText,
      artist: 'A',
      keywords: keywords,
    );

void main() {
  late _MockScryfall scryfall;
  late _MockDb db;
  late _FakeLibrary library;

  PlayerCustomizationBloc build() => PlayerCustomizationBloc(
        scryfallRepository: scryfall,
        firebaseDatabaseRepository: db,
        commanderLibraryRepository: library,
      );

  setUp(() {
    scryfall = _MockScryfall();
    db = _MockDb();
    library = _FakeLibrary();
  });

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'CommanderSelected sets commander, detects partner, records recent',
    build: build,
    act: (b) => b.add(CommanderSelected(cmdr(keywords: ['Partner']))),
    verify: (b) {
      expect(b.state.commander?.name, 'X');
      expect(b.state.availablePairing, CommanderPairing.partner);
      expect(library.recents.single.name, 'X');
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'SecondCardSelected with background pairing fills background, not partner',
    build: build,
    seed: () => PlayerCustomizationState(
      commander: cmdr(oracleText: 'Choose a Background'),
      availablePairing: CommanderPairing.background,
    ),
    act: (b) => b.add(SecondCardSelected(cmdr(name: 'Cult', oracleId: 'c'))),
    verify: (b) {
      expect(b.state.background?.name, 'Cult');
      expect(b.state.partner, isNull);
      expect(b.state.damageClocks, 1);
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'SecondCardSelected with partner pairing fills partner (two clocks)',
    build: build,
    seed: () => PlayerCustomizationState(
      commander: cmdr(keywords: ['Partner']),
      availablePairing: CommanderPairing.partner,
    ),
    act: (b) => b.add(SecondCardSelected(cmdr(name: 'Ally', oracleId: 'al'))),
    verify: (b) {
      expect(b.state.partner?.name, 'Ally');
      expect(b.state.background, isNull);
      expect(b.state.damageClocks, 2);
    },
  );

  blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
    'CommanderFavoriteToggled updates favorites + favoriteIds',
    build: build,
    act: (b) => b.add(CommanderFavoriteToggled(cmdr(oracleId: 'fav'))),
    verify: (b) {
      expect(b.state.favoriteIds.contains('fav'), isTrue);
      expect(b.state.favorites.single.oracleId, 'fav');
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/player/player_customization_bloc_test.dart`
Expected: FAIL — constructor lacks `commanderLibraryRepository`; events undefined.

- [ ] **Step 3: Rewrite the bloc**

Replace the entire contents of `lib/player/view/bloc/player_customization_bloc.dart`:

```dart
import 'package:api_client/api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/app/utils/commander_mapper.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'player_customization_event.dart';
part 'player_customization_state.dart';

class PlayerCustomizationBloc
    extends Bloc<PlayerCustomizationEvent, PlayerCustomizationState> {
  PlayerCustomizationBloc({
    required ScryfallRepository scryfallRepository,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required CommanderLibraryRepository commanderLibraryRepository,
  })  : _scryfallRepository = scryfallRepository,
        _firebaseDatabaseRepository = firebaseDatabaseRepository,
        _library = commanderLibraryRepository,
        super(const PlayerCustomizationState()) {
    on<LibraryRequested>(_onLibraryRequested);
    on<CardListRequested>(_cardListRequested);
    on<CommanderSelected>(_onCommanderSelected);
    on<SecondCardSelected>(_onSecondCardSelected);
    on<StartSelectingSecondCard>(_onStartSelectingSecondCard);
    on<CancelSelectingSecondCard>(_onCancelSelectingSecondCard);
    on<SecondCardCleared>(_onSecondCardCleared);
    on<CommanderFavoriteToggled>(_onFavoriteToggled);
    on<UpdateAccountOwnership>(_onUpdateAccountOwnership);
    on<UpdateCommanderFilters>(_onUpdateCommanderFilters);
    on<ClearCardList>(_onClearCardList);
    on<SelectFriend>(_onSelectFriend);
    on<ClearFriend>(_onClearFriend);
    on<ValidatePin>(_onValidatePin);
  }

  final ScryfallRepository _scryfallRepository;
  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final CommanderLibraryRepository _library;

  String _id(Commander c) => c.oracleId ?? c.name;

  Future<void> _onLibraryRequested(
    LibraryRequested event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    final recents = await _library.getRecents();
    final favorites = await _library.getFavorites();
    emit(
      state.copyWith(
        recents: recents,
        favorites: favorites,
        favoriteIds: favorites.map(_id).toSet(),
      ),
    );
  }

  Future<void> _cardListRequested(
    CardListRequested event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(state.copyWith(status: PlayerCustomizationStatus.loading));
    try {
      final cardList = await _scryfallRepository.getCardFullText(
        cardName: event.cardName,
      );
      final filteredCards = cardList.data.where((card) {
        final type = card.typeLine?.toLowerCase() ?? '';
        if (event.searchBackgrounds) return type.contains('background');
        return type.contains('legendary');
      }).toList();
      emit(
        state.copyWith(
          status: PlayerCustomizationStatus.success,
          cardList: cardList,
          filteredCards: filteredCards,
        ),
      );
    } on Exception catch (_) {
      emit(state.copyWith(status: PlayerCustomizationStatus.failure));
    }
  }

  Future<void> _onCommanderSelected(
    CommanderSelected event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    await _library.addRecent(event.commander);
    final recents = await _library.getRecents();
    emit(
      state.copyWith(
        status: PlayerCustomizationStatus.success,
        commander: () => event.commander,
        partner: () => null,
        background: () => null,
        availablePairing: commanderPairingFor(event.commander),
        selectingSecondCard: false,
        recents: recents,
      ),
    );
  }

  Future<void> _onSecondCardSelected(
    SecondCardSelected event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    await _library.addRecent(event.card);
    final recents = await _library.getRecents();
    final isBackground = state.availablePairing == CommanderPairing.background;
    emit(
      state.copyWith(
        status: PlayerCustomizationStatus.success,
        partner: () => isBackground ? state.partner : event.card,
        background: () => isBackground ? event.card : state.background,
        selectingSecondCard: false,
        recents: recents,
      ),
    );
  }

  void _onStartSelectingSecondCard(
    StartSelectingSecondCard event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWith(
        selectingSecondCard: true,
        filteredCards: [],
      ),
    );
  }

  void _onCancelSelectingSecondCard(
    CancelSelectingSecondCard event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWith(selectingSecondCard: false));
  }

  void _onSecondCardCleared(
    SecondCardCleared event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWith(
        partner: () => null,
        background: () => null,
        selectingSecondCard: false,
      ),
    );
  }

  Future<void> _onFavoriteToggled(
    CommanderFavoriteToggled event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    await _library.toggleFavorite(event.commander);
    final favorites = await _library.getFavorites();
    emit(
      state.copyWith(
        favorites: favorites,
        favoriteIds: favorites.map(_id).toSet(),
      ),
    );
  }

  void _onUpdateAccountOwnership(
    UpdateAccountOwnership event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWith(isAccountOwner: event.isOwner));
  }

  void _onClearCardList(
    ClearCardList event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWith(filteredCards: []));
  }

  void _onUpdateCommanderFilters(
    UpdateCommanderFilters event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    final cards = event.showOnlyLegendary
        ? state.cardList?.data
            .where(
              (card) =>
                  card.typeLine?.toLowerCase().contains('legendary') ?? false,
            )
            .toList()
        : state.cardList?.data ?? [];
    emit(
      state.copyWith(
        showOnlyLegendary: event.showOnlyLegendary,
        filteredCards: cards,
      ),
    );
  }

  void _onSelectFriend(
    SelectFriend event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWith(selectedFriend: event.friend, pinError: ''));
  }

  void _onClearFriend(
    ClearFriend event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWithClearedFriend());
  }

  Future<void> _onValidatePin(
    ValidatePin event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    try {
      final isValid = await _firebaseDatabaseRepository.validatePin(
        event.friendUserId,
        event.pin,
      );
      if (isValid) {
        emit(state.copyWith(pinValidated: true, pinError: ''));
      } else {
        emit(state.copyWith(pinValidated: false, pinError: 'Incorrect PIN'));
      }
    } on Exception catch (_) {
      emit(
        state.copyWith(
          pinValidated: false,
          pinError: 'Failed to validate PIN',
        ),
      );
    }
  }
}
```

- [ ] **Step 4: Run the bloc test to verify it passes**

Run: `flutter test test/player/player_customization_bloc_test.dart`
Expected: PASS (4 blocTests).

- [ ] **Step 5: Commit (state + events + bloc together)**

```bash
git add lib/player/view/bloc/player_customization_state.dart \
        lib/player/view/bloc/player_customization_event.dart \
        lib/player/view/bloc/player_customization_bloc.dart \
        test/player/player_customization_bloc_test.dart
git commit -m "refactor: model typed second card + library in customization bloc"
```

---

### Task 5: `TrackingPreview` widget

**Files:**
- Create: `lib/player/view/widgets/tracking_preview.dart`
- Test: `test/player/tracking_preview_test.dart` (create)

**Interfaces:**
- Produces: `TrackingPreview({required int damageClocks, required List<String> colorIdentity})`.

- [ ] **Step 1: Write the failing widget test**

Create `test/player/tracking_preview_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/player/view/widgets/tracking_preview.dart';

void main() {
  testWidgets('shows clock count and a pip per color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrackingPreview(
            damageClocks: 2,
            colorIdentity: ['W', 'U', 'B'],
          ),
        ),
      ),
    );

    expect(find.text('2 commander-damage clocks'), findsOneWidget);
    expect(
      find.byKey(const Key('tracking_preview_pips')),
      findsOneWidget,
    );
  });

  testWidgets('uses singular label for one clock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrackingPreview(damageClocks: 1, colorIdentity: []),
        ),
      ),
    );
    expect(find.text('1 commander-damage clock'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/player/tracking_preview_test.dart`
Expected: FAIL — `tracking_preview.dart` not found.

- [ ] **Step 3: Implement the widget**

Create `lib/player/view/widgets/tracking_preview.dart`:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

const _manaColors = <String, Color>{
  'W': Color(0xFFEFE8D2),
  'U': Color(0xFF378ADD),
  'B': Color(0xFF444441),
  'R': Color(0xFFE24B4A),
  'G': Color(0xFF639922),
};

class TrackingPreview extends StatelessWidget {
  const TrackingPreview({
    required this.damageClocks,
    required this.colorIdentity,
    super.key,
  });

  final int damageClocks;
  final List<String> colorIdentity;

  @override
  Widget build(BuildContext context) {
    final clockLabel = damageClocks == 1
        ? '1 commander-damage clock'
        : '$damageClocks commander-damage clocks';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This game will track',
            style: TextStyle(fontSize: 12, color: AppColors.neutral60),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.gavel, size: 17, color: AppColors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                clockLabel,
                style: const TextStyle(fontSize: 13, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            key: const Key('tracking_preview_pips'),
            children: [
              const Text(
                'Colors',
                style: TextStyle(fontSize: 13, color: AppColors.neutral60),
              ),
              const SizedBox(width: AppSpacing.sm),
              for (final c in colorIdentity)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _manaColors[c] ?? AppColors.neutral60,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.neutral60.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              if (colorIdentity.isEmpty)
                const Text(
                  'Colorless',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral60),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/player/tracking_preview_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/player/view/widgets/tracking_preview.dart test/player/tracking_preview_test.dart
git commit -m "feat: add TrackingPreview widget"
```

---

### Task 6: Extend `CommanderHeroBanner` for backgrounds

**Files:**
- Modify: `lib/player/view/widgets/commander_hero_banner.dart`

**Interfaces:**
- Produces: `CommanderHeroBanner({Commander? commander, Commander? partner,
  Commander? background, required int playerColor})`.

- [ ] **Step 1: Add a `background` parameter and treat it as a second art**

In `lib/player/view/widgets/commander_hero_banner.dart`:

Add the field + constructor param:

```dart
  const CommanderHeroBanner({
    required this.playerColor,
    this.commander,
    this.partner,
    this.background,
    super.key,
  });

  final Commander? commander;
  final Commander? partner;
  final Commander? background;
  final int playerColor;
```

In `build`, compute a single "second card" (partner takes precedence, else background):

```dart
  @override
  Widget build(BuildContext context) {
    final hasCommander = commander?.imageUrl.isNotEmpty ?? false;
    final secondCard = partner ?? background;
    final hasSecond = secondCard?.imageUrl.isNotEmpty ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(hasCommander, hasSecond, secondCard),
        _buildGradientOverlay(),
        _buildNameOverlay(context, hasCommander, hasSecond, secondCard),
      ],
    );
  }
```

Update `_buildBackground` to take the resolved second card:

```dart
  Widget _buildBackground(
    bool hasCommander,
    bool hasSecond,
    Commander? secondCard,
  ) {
    if (!hasCommander) {
      return ColoredBox(
        color: Color(playerColor).withAlpha(80),
        child: const Center(
          child: Icon(Icons.person, size: 64, color: AppColors.neutral60),
        ),
      );
    }

    if (hasSecond) {
      return Row(
        children: [
          Expanded(child: _ArtCropImage(url: commander!.imageUrl)),
          Expanded(child: _ArtCropImage(url: secondCard!.imageUrl)),
        ],
      );
    }

    return _ArtCropImage(url: commander!.imageUrl);
  }
```

Update `_buildNameOverlay`'s signature and its `hasPartner` branch to use the resolved
second card:

```dart
  Widget _buildNameOverlay(
    BuildContext context,
    bool hasCommander,
    bool hasSecond,
    Commander? secondCard,
  ) {
    if (!hasCommander) return const SizedBox.shrink();

    return Positioned(
      bottom: AppSpacing.md,
      left: AppSpacing.xlg,
      right: AppSpacing.xlg,
      child: Row(
        children: [
          Flexible(
            child: Text(
              commander!.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasSecond) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                '&',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: Text(
                secondCard!.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/player/view/widgets/commander_hero_banner.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/player/view/widgets/commander_hero_banner.dart
git commit -m "feat: show background as second art in commander hero banner"
```

---

### Task 7: Commander card + picker panel

**Files:**
- Create: `lib/player/view/widgets/commander_card.dart`
- Create: `lib/player/view/widgets/commander_picker_panel.dart`
- Modify: `lib/player/view/widgets/widgets.dart` (exports)

**Interfaces:**
- Consumes: `PlayerCustomizationBloc` + state (Task 4), `magicCardToCommander`,
  `CommanderSearchBar` (existing).
- Produces: `CommanderCard({required Commander commander, required bool isFavorite,
  required VoidCallback onTap, required VoidCallback onToggleFavorite})` and
  `CommanderPickerPanel({required TextEditingController searchController})`.

- [ ] **Step 1: Create `CommanderCard`**

Create `lib/player/view/widgets/commander_card.dart`:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:player_repository/player_repository.dart';

class CommanderCard extends StatelessWidget {
  const CommanderCard({
    required this.commander,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.isSelected = false,
    super.key,
  });

  final Commander commander;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: ColoredBox(
          color: AppColors.quaternary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (commander.imageUrl.isNotEmpty)
                Image.network(
                  commander.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.neutral60,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                )
              else
                const ColoredBox(
                  color: AppColors.neutral60,
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              if (isSelected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.secondary, width: 3),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: onToggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: isFavorite ? AppColors.secondary : AppColors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: AppColors.black.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    commander.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `CommanderPickerPanel`**

Create `lib/player/view/widgets/commander_picker_panel.dart`:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/utils/commander_mapper.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/commander_card.dart';
import 'package:magic_yeti/player/view/widgets/commander_search_bar.dart';
import 'package:player_repository/player_repository.dart';

enum _PickerTab { favorites, recent, search }

class CommanderPickerPanel extends StatefulWidget {
  const CommanderPickerPanel({required this.searchController, super.key});

  final TextEditingController searchController;

  @override
  State<CommanderPickerPanel> createState() => _CommanderPickerPanelState();
}

class _CommanderPickerPanelState extends State<CommanderPickerPanel> {
  _PickerTab? _tab;

  _PickerTab _defaultTab(PlayerCustomizationState s) {
    if (s.favorites.isNotEmpty) return _PickerTab.favorites;
    if (s.recents.isNotEmpty) return _PickerTab.recent;
    return _PickerTab.search;
  }

  String _id(Commander c) => c.oracleId ?? c.name;

  void _select(BuildContext context, Commander commander) {
    final bloc = context.read<PlayerCustomizationBloc>();
    if (bloc.state.selectingSecondCard) {
      bloc.add(SecondCardSelected(commander));
    } else {
      bloc.add(CommanderSelected(commander));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        final tab = _tab ??= _defaultTab(state);

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_PickerTab>(
                segments: const [
                  ButtonSegment(
                    value: _PickerTab.favorites,
                    label: Text('Favorites'),
                    icon: Icon(Icons.star_border),
                  ),
                  ButtonSegment(
                    value: _PickerTab.recent,
                    label: Text('Recent'),
                    icon: Icon(Icons.history),
                  ),
                  ButtonSegment(
                    value: _PickerTab.search,
                    label: Text('Search'),
                    icon: Icon(Icons.search),
                  ),
                ],
                selected: {tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.commander != null &&
                  state.availablePairing != CommanderPairing.none &&
                  !state.selectingSecondCard &&
                  state.partner == null &&
                  state.background == null)
                _SecondCardBanner(pairing: state.availablePairing),
              if (state.selectingSecondCard) _SelectingSecondCardBanner(),
              if (tab == _PickerTab.search) ...[
                const SizedBox(height: AppSpacing.sm),
                CommanderSearchBar(
                  textController: widget.searchController,
                  selectingPartner: state.selectingSecondCard,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _grid(context, state, tab),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grid(
    BuildContext context,
    PlayerCustomizationState state,
    _PickerTab tab,
  ) {
    final List<Commander> commanders;
    switch (tab) {
      case _PickerTab.favorites:
        commanders = state.favorites;
      case _PickerTab.recent:
        commanders = state.recents;
      case _PickerTab.search:
        commanders =
            (state.magicCardList ?? []).map(magicCardToCommander).toList();
    }

    if (state.status == PlayerCustomizationStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }
    if (commanders.isEmpty) {
      return Center(
        child: Text(
          tab == _PickerTab.search
              ? 'Search for a commander above'
              : 'Nothing here yet — try Search',
          style: const TextStyle(color: AppColors.neutral60),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.72,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: commanders.length,
      itemBuilder: (context, index) {
        final commander = commanders[index];
        final selected = state.commander != null &&
            _id(state.commander!) == _id(commander);
        return CommanderCard(
          commander: commander,
          isFavorite: state.favoriteIds.contains(_id(commander)),
          isSelected: selected,
          onTap: () => _select(context, commander),
          onToggleFavorite: () => context
              .read<PlayerCustomizationBloc>()
              .add(CommanderFavoriteToggled(commander)),
        );
      },
    );
  }
}

class _SecondCardBanner extends StatelessWidget {
  const _SecondCardBanner({required this.pairing});

  final CommanderPairing pairing;

  @override
  Widget build(BuildContext context) {
    final isBackground = pairing == CommanderPairing.background;
    final label = isBackground ? 'Add background' : 'Add partner';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withAlpha(40),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.tertiary.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline,
              color: AppColors.tertiary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isBackground
                  ? 'This commander can choose a Background'
                  : 'This commander can take a partner',
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => context
                .read<PlayerCustomizationBloc>()
                .add(const StartSelectingSecondCard()),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _SelectingSecondCardBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(40),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Selecting second card',
              style: TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => context
                .read<PlayerCustomizationBloc>()
                .add(const CancelSelectingSecondCard()),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Export the new widgets**

In `lib/player/view/widgets/widgets.dart`, add:

```dart
export 'commander_card.dart';
export 'commander_picker_panel.dart';
export 'tracking_preview.dart';
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze lib/player/view/widgets/`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/player/view/widgets/commander_card.dart \
        lib/player/view/widgets/commander_picker_panel.dart \
        lib/player/view/widgets/widgets.dart
git commit -m "feat: add commander card and reuse-first picker panel"
```

---

### Task 8: `PlayerIdentityPanel` (left pane)

**Files:**
- Create: `lib/player/view/widgets/player_identity_panel.dart`
- Modify: `lib/player/view/widgets/widgets.dart` (export)

**Interfaces:**
- Consumes: `PlayerCustomizationBloc` state, `FriendBloc` state, `TrackingPreview`.
- Produces: `PlayerIdentityPanel({required TextEditingController nameController,
  required FocusNode nameFocusNode, required int playerColor,
  required VoidCallback onSave})`.

- [ ] **Step 1: Create the panel**

Create `lib/player/view/widgets/player_identity_panel.dart`:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/tracking_preview.dart';

class PlayerIdentityPanel extends StatelessWidget {
  const PlayerIdentityPanel({
    required this.nameController,
    required this.nameFocusNode,
    required this.playerColor,
    required this.onSave,
    super.key,
  });

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final int playerColor;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        final isLinked =
            state.selectedFriend != null && state.pinValidated;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Color(playerColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      readOnly: isLinked,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        hintText: 'Player name',
                        prefixIcon: Icon(
                          isLinked ? Icons.link : Icons.edit,
                          color:
                              isLinked ? AppColors.green : AppColors.neutral60,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _FriendLinkRow(isLinked: isLinked),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Commander',
                style: TextStyle(fontSize: 12, color: AppColors.neutral60),
              ),
              const SizedBox(height: AppSpacing.xs),
              _SecondCardSummary(state: state),
              const Spacer(),
              TrackingPreview(
                damageClocks: state.damageClocks,
                colorIdentity: state.colorIdentity,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save player'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
                onPressed: onSave,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SecondCardSummary extends StatelessWidget {
  const _SecondCardSummary({required this.state});

  final PlayerCustomizationState state;

  @override
  Widget build(BuildContext context) {
    final commanderName = state.commander?.name ?? 'No commander selected';
    final second = state.partner ?? state.background;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          commanderName,
          style: const TextStyle(color: AppColors.white, fontSize: 15),
        ),
        if (second != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  state.partner != null ? Icons.people : Icons.auto_awesome,
                  size: 14,
                  color: AppColors.neutral60,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    second.name,
                    style: const TextStyle(
                      color: AppColors.neutral60,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  color: AppColors.neutral60,
                  onPressed: () => context
                      .read<PlayerCustomizationBloc>()
                      .add(const SecondCardCleared()),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FriendLinkRow extends StatelessWidget {
  const _FriendLinkRow({required this.isLinked});

  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerCustomizationBloc>().state;
    if (isLinked) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: AppColors.green, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Linked to ${state.selectedFriend?.username ?? ''}',
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => context
                  .read<PlayerCustomizationBloc>()
                  .add(const ClearFriend()),
              child: const Text('Unlink'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
```

Note: the existing friend-selection list + PIN dialog (`_FriendSection` / `_showPinDialog`
in `customize_player_page.dart`) is reused as the "Link to a friend" entry; it is wired into
the left pane in Task 9.

- [ ] **Step 2: Export it**

In `lib/player/view/widgets/widgets.dart`, add:

```dart
export 'player_identity_panel.dart';
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/player/view/widgets/player_identity_panel.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/player/view/widgets/player_identity_panel.dart lib/player/view/widgets/widgets.dart
git commit -m "feat: add PlayerIdentityPanel (left pane)"
```

---

### Task 9: Assemble the two-pane `CustomizePlayerView`

**Files:**
- Modify: `lib/player/view/customize_player_page.dart` (rebuild `build`, `_save`, bloc create)
- Delete: `lib/player/view/widgets/commander_slot_selector.dart` (replaced by the banner)

**Interfaces:**
- Consumes: `CommanderLibraryRepository` (Plan B), `PlayerIdentityPanel`,
  `CommanderPickerPanel`, `CommanderHeroBanner` (with `background`), the existing
  `_FriendSection` (kept in this file as the link entry).

- [ ] **Step 1: Inject the library repo and dispatch `LibraryRequested`**

In `CustomizePlayerPage.build`, add the repo to the bloc create:

```dart
        BlocProvider(
          create: (context) => PlayerCustomizationBloc(
            scryfallRepository: context.read<ScryfallRepository>(),
            firebaseDatabaseRepository:
                context.read<FirebaseDatabaseRepository>(),
            commanderLibraryRepository:
                context.read<CommanderLibraryRepository>(),
          )..add(const LibraryRequested()),
        ),
```

Add the import at the top of the file:

```dart
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
```

- [ ] **Step 2: Rewrite `_save` to pass `background`**

In `_CustomizePlayerViewState._save`, update the dispatched event:

```dart
    context.read<PlayerBloc>().add(
      UpdatePlayerInfoEvent(
        playerName: _nameController.text,
        commander: state.commander,
        partner: state.partner,
        background: state.background,
        playerId: widget.playerId,
        firebaseId: firebaseId,
      ),
    );
    Navigator.pop(context);
```

- [ ] **Step 3: Rewrite `build` as a two-pane layout**

Replace the body of `_CustomizePlayerViewState.build` with:

```dart
  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerRepository>().getPlayerById(
      widget.playerId,
    );

    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        final commander = state.commander ?? player.commander;
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              CommanderHeroBanner(
                commander: commander,
                partner: state.partner,
                background: state.background,
                playerColor: player.color,
              ),
              ColoredBox(color: AppColors.black.withValues(alpha: 0.45)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 39,
                        child: _Panel(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _FriendSection(nameController: _nameController),
                                PlayerIdentityPanel(
                                  nameController: _nameController,
                                  nameFocusNode: _nameFocusNode,
                                  playerColor: player.color,
                                  onSave: () => _save(context, state),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 61,
                        child: _Panel(
                          child: CommanderPickerPanel(
                            searchController: _searchController,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
```

Add a small private panel wrapper at the bottom of the file (after `_CustomizePlayerViewState`):

```dart
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 4: Remove obsolete imports/usages**

In `customize_player_page.dart`, delete the now-unused `CustomScrollView`/sliver code that
was replaced, and remove any import of `commander_slot_selector.dart`. Delete the file
`lib/player/view/widgets/commander_slot_selector.dart` and its export line in
`widgets.dart`. (The old `PlayerNameRow`/`CommanderSlotSelector` partner chips are replaced
by the picker banner; if `PlayerNameRow` is no longer referenced anywhere, delete it and its
export too — confirm with `grep -rn "PlayerNameRow" lib`.)

- [ ] **Step 5: Verify the app compiles**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Run the app and exercise the flow**

Run a 4-player game → tap a player → confirm: upright page, two panes, recents/favorites
populate after picks, search works, picking a partner shows two clocks in the preview,
picking a background shows one clock, Save persists.

- [ ] **Step 7: Commit**

```bash
git add lib/player/view/customize_player_page.dart lib/player/view/widgets/widgets.dart
git rm lib/player/view/widgets/commander_slot_selector.dart
git commit -m "feat: assemble two-pane customize player view"
```

---

### Task 10: Regression — Background never creates a partner clock

**Files:**
- Test: `test/player/background_no_partner_clock_test.dart` (create)

**Interfaces:**
- Consumes: `PlayerCustomizationState` derived getters.

- [ ] **Step 1: Write the regression test**

Create `test/player/background_no_partner_clock_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:player_repository/player_repository.dart';

Commander c(String name) => Commander(
      oracleId: name,
      name: name,
      colors: const ['B'],
      cardType: 'Legendary',
      imageUrl: 'https://e/$name.jpg',
      manaCost: '',
      oracleText: '',
      artist: 'A',
    );

void main() {
  test('a player with only a background has a single damage clock', () {
    final state = PlayerCustomizationState(
      commander: c('Wilson'),
      background: c('Cult of Rakdos'),
      availablePairing: CommanderPairing.background,
    );
    expect(state.partner, isNull);
    expect(state.damageClocks, 1);
  });

  test('a player with a partner has two damage clocks', () {
    final state = PlayerCustomizationState(
      commander: c('Commander'),
      partner: c('Partner'),
      availablePairing: CommanderPairing.partner,
    );
    expect(state.damageClocks, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/player/background_no_partner_clock_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/player/background_no_partner_clock_test.dart
git commit -m "test: background yields one clock, partner yields two"
```

---

### Task 11: Full verification

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Run all tests**

Run: `flutter test` then `cd packages/player_repository && flutter test`
Expected: all pass.

- [ ] **Step 3: Manual regression checklist**

- Player 3 / 4: customize page is upright; keyboard is upright. ✓
- Two-pane layout renders; left = identity + preview, right = picker. ✓
- Recents tab fills after picks; favorites star toggles persist across reopening the page. ✓
- Partner commander → "2 commander-damage clocks"; background → "1"; color pips reflect all cards. ✓
- Save → reopen player → selections (incl. background) persist; in-game commander-damage tracker shows a partner clock only when a partner (not a background) is set. ✓

- [ ] **Step 4: Final commit (if any cleanup remains)**

```bash
git add -A
git commit -m "chore: finalize customize player page redesign"
```

---

## Self-Review

- **Spec coverage (UI):** no rotation (Task 1); two-pane layout (Task 9); typed second card + auto-detected banner (Tasks 4, 7); recents/favorites tabs with adaptive default + star toggle (Tasks 4, 7); tracking preview (Task 5); friend link first-class (Task 8 + reused `_FriendSection`); hero banner background (Task 6); save carries background (Task 9); ~4-col grid (Task 7); background-no-clock regression (Task 10). ✓
- **Placeholder scan:** none — full code in every step. Task 9 Step 4 instructs deleting genuinely dead code with a `grep` guard, not a vague "clean up."
- **Type consistency:** `availablePairing`/`CommanderPairing`, `partner`/`background` `Commander?`, `damageClocks` `int`, `colorIdentity` `List<String>`, `favoriteIds` `Set<String>`, and copyWith `Commander? Function()?` wrappers are used consistently across state, bloc, and widgets. The bloc constructor signature (`commanderLibraryRepository`) matches the page's `context.read<CommanderLibraryRepository>()` and the test's `_FakeLibrary`.
- **Known follow-ups (not blocking):** `_FriendSection`/`_showPinDialog` remain in `customize_player_page.dart` and are reused as the link entry; a later cleanup could extract them into their own widget file.
