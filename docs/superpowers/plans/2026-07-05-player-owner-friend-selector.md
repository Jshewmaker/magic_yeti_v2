# Player Owner + Friend Selector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the friend-tile list on the Customize Player page with a searchable dropdown that also lists the account owner, fix the rehydration bug that can silently drop or reassign an existing link, and fix two bugs in the PIN verification dialog (missing loading state, small-device keyboard overlap).

**Architecture:** All changes are confined to `PlayerCustomizationBloc`/`PlayerCustomizationState`/`PlayerCustomizationEvent`, `customize_player_page.dart`, and `player_identity_panel.dart`, plus two new/reused l10n keys. No new packages, no backend/Firestore rules changes — the existing `validatePin` callable and `getUserProfileOnce` repository method are reused as-is.

**Tech Stack:** Flutter/Dart, `flutter_bloc`, Material 3's `DropdownMenu` widget (`flutter/material.dart`, no new dependency), `bloc_test` + `mocktail` for tests.

Spec: `docs/superpowers/specs/2026-07-05-player-owner-friend-selector-design.md`

## Global Constraints

- Dart SDK `>=3.8.0 <4.0.0`; `useMaterial3: true` is already set in `app_ui`'s theme (`packages/app_ui/lib/src/theme/app_theme.dart:14`) — `DropdownMenu` needs no new dependency or theme change.
- Lint: `very_good_analysis` — every task must leave `flutter analyze` clean.
- No new dependencies in any `pubspec.yaml`.
- l10n: after any ARB edit, run `flutter gen-l10n --arb-dir="lib/l10n/arb"` and commit the regenerated `lib/l10n/arb/app_localizations*.dart` files alongside the ARB source.
- No backend changes: `validatePin` (Cloud Function) and `FirebaseDatabaseRepository.getUserProfileOnce` are reused exactly as they exist today.
- Test conventions already established in this codebase (follow them, don't invent new ones): `blocTest<Bloc, State>` from `package:bloc_test`, `mocktail`'s `Mock`/`MockBloc`, the `tester.pumpApp(...)` helper from `test/helpers/pump_app.dart`, and mock classes declared locally at the top of each test file (see `test/player/player_customization_bloc_test.dart` and `test/player/customize_player_page_anonymous_test.dart` for the exact existing pattern).

---

## File Structure

| File | Role |
|---|---|
| `lib/player/view/bloc/player_customization_state.dart` | Adds `isPinValidating` (Task 1) and `ownerUsername` (Task 3) fields; adds the three link-transition helper methods (Task 3). |
| `lib/player/view/bloc/player_customization_event.dart` | Adds `OwnerSelected`; renames `ClearFriend` → `LinkCleared` (Task 3). |
| `lib/player/view/bloc/player_customization_bloc.dart` | `_onValidatePin` emits `isPinValidating` (Task 1); new `_onOwnerSelected`, modified `_onSelectFriend`, renamed `_onLinkCleared` (Task 3). |
| `lib/player/view/widgets/player_identity_panel.dart` | `isLinked` covers the owner case; `_FriendLinkRow` shows the right name for either case (Task 4). |
| `lib/player/view/customize_player_page.dart` | PIN dialog loading spinner + `scrollable: true` (Task 2); one-line Clear-button event rename to keep compiling (Task 3); `initState` rehydration + name-sync listeners (Task 5); `_FriendSection` becomes a `DropdownMenu`-based `StatefulWidget`, `_FriendTile` and the Clear button are deleted (Task 6). |
| `lib/l10n/arb/app_en.arb`, `app_es.arb` | Two new keys (`accountOwnerOptionLabel`, `notLinkedOptionLabel`); the existing-but-unused `linkedToFriend` key is put back into use (Task 6, Task 4). |
| `test/player/player_customization_bloc_test.dart` | Extended in Tasks 1 and 3. |
| `test/player/customize_player_page_friend_picker_test.dart` | **New file**, created in Task 2, extended in Tasks 4, 5, 6. |

---

### Task 1: `isPinValidating` loading state on the bloc

**Files:**
- Modify: `lib/player/view/bloc/player_customization_state.dart`
- Modify: `lib/player/view/bloc/player_customization_bloc.dart:222-273` (`_onValidatePin`)
- Test: `test/player/player_customization_bloc_test.dart`

**Interfaces:**
- Produces: `PlayerCustomizationState.isPinValidating` (`bool`, default `false`) — later tasks (Task 2) read this to drive the Verify button's spinner.

- [ ] **Step 1: Write the failing tests**

Modify `test/player/player_customization_bloc_test.dart`. Replace the `'emits pinValidated on PinValid'` test (the first test in `group('ValidatePin', ...)`, currently lines 201-219) with a version that asserts both emitted states, and add `skip: 1` to the other four `ValidatePin` tests so they keep asserting only the terminal state. Replace the entire `group('ValidatePin', ...)` block (lines 200-319) with:

```dart
  group('ValidatePin', () {
    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits isPinValidating true, then pinValidated on PinValid',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '0742',
          ),
        ).thenAnswer((_) async => const PinValid());
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', true),
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having((s) => s.pinValidated, 'pinValidated', true)
            .having((s) => s.pinFlowError, 'pinFlowError', PinFlowError.none),
      ],
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits incorrect with attemptsRemaining on PinInvalid',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '9999',
          ),
        ).thenAnswer((_) async => const PinInvalid(attemptsRemaining: 2));
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '9999', friendUserId: 'friend1')),
      skip: 1,
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having((s) => s.pinValidated, 'pinValidated', false)
            .having(
              (s) => s.pinFlowError,
              'pinFlowError',
              PinFlowError.incorrect,
            )
            .having((s) => s.pinAttemptsRemaining, 'attempts', 2),
      ],
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits lockedOut with expiry on PinLockedOut',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '9999',
          ),
        ).thenAnswer(
          (_) async => PinLockedOut(lockedUntil: DateTime(2026, 7, 3, 12)),
        );
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '9999', friendUserId: 'friend1')),
      skip: 1,
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having(
              (s) => s.pinFlowError,
              'pinFlowError',
              PinFlowError.lockedOut,
            )
            .having(
              (s) => s.pinLockedUntil,
              'lockedUntil',
              DateTime(2026, 7, 3, 12),
            ),
      ],
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits unavailable on PinCheckUnavailable',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '0742',
          ),
        ).thenAnswer((_) async => const PinCheckUnavailable());
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
      skip: 1,
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having(
              (s) => s.pinFlowError,
              'pinFlowError',
              PinFlowError.unavailable,
            ),
      ],
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'emits notSet on PinNotSet',
      build: () {
        when(
          () => db.validatePin(
            targetUserId: 'friend1',
            pin: '0742',
          ),
        ).thenAnswer((_) async => const PinNotSet());
        return build();
      },
      act: (bloc) =>
          bloc.add(const ValidatePin(pin: '0742', friendUserId: 'friend1')),
      skip: 1,
      expect: () => [
        isA<PlayerCustomizationState>()
            .having((s) => s.isPinValidating, 'isPinValidating', false)
            .having(
              (s) => s.pinFlowError,
              'pinFlowError',
              PinFlowError.notSet,
            ),
      ],
    );
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/player/player_customization_bloc_test.dart`
Expected: FAIL to compile — `The getter 'isPinValidating' isn't defined for the class 'PlayerCustomizationState'`.

- [ ] **Step 3: Implement — add the field**

In `lib/player/view/bloc/player_customization_state.dart`, add `isPinValidating` to the constructor (after `this.pinLockedUntil,` on line 44):

```dart
    this.pinLockedUntil,
    this.isPinValidating = false,
  });
```

Add the field declaration (after `final DateTime? pinLockedUntil;` on line 65):

```dart
  final DateTime? pinLockedUntil;
  final bool isPinValidating;
```

Add it to `props` (after `pinLockedUntil,` on line 101):

```dart
        pinLockedUntil,
        isPinValidating,
      ];
```

Add it to `copyWith`'s parameter list (after `DateTime? Function()? pinLockedUntil,` on line 124) and body (after the `pinLockedUntil:` assignment on lines 145-146):

```dart
    DateTime? Function()? pinLockedUntil,
    bool? isPinValidating,
  }) {
    return PlayerCustomizationState(
      ...
      pinLockedUntil:
          pinLockedUntil != null ? pinLockedUntil() : this.pinLockedUntil,
      isPinValidating: isPinValidating ?? this.isPinValidating,
    );
  }
```

`copyWithClearedFriend()` is left unchanged — `isPinValidating` isn't in its explicit field list, so it correctly resets to `false` there, same as the other pin-flow fields.

- [ ] **Step 4: Implement — emit it around the validate call**

In `lib/player/view/bloc/player_customization_bloc.dart`, replace `_onValidatePin` (lines 222-273) with:

```dart
  Future<void> _onValidatePin(
    ValidatePin event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(state.copyWith(isPinValidating: true));
    final result = await _firebaseDatabaseRepository.validatePin(
      targetUserId: event.friendUserId,
      pin: event.pin,
    );
    switch (result) {
      case PinValid():
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: true,
            pinFlowError: PinFlowError.none,
            pinLockedUntil: () => null,
          ),
        );
      case PinInvalid(:final attemptsRemaining):
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: false,
            pinFlowError: PinFlowError.incorrect,
            pinAttemptsRemaining: attemptsRemaining,
            pinLockedUntil: () => null,
          ),
        );
      case PinLockedOut(:final lockedUntil):
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: false,
            pinFlowError: PinFlowError.lockedOut,
            pinLockedUntil: () => lockedUntil,
          ),
        );
      case PinNotSet():
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: false,
            pinFlowError: PinFlowError.notSet,
            pinLockedUntil: () => null,
          ),
        );
      case PinCheckUnavailable():
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: false,
            pinFlowError: PinFlowError.unavailable,
            pinLockedUntil: () => null,
          ),
        );
    }
  }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/player/player_customization_bloc_test.dart`
Expected: PASS (all tests, including the 5 in `group('ValidatePin', ...)`).

- [ ] **Step 6: Commit**

```bash
git add lib/player/view/bloc/player_customization_state.dart lib/player/view/bloc/player_customization_bloc.dart test/player/player_customization_bloc_test.dart
git commit -m "feat: add isPinValidating loading state to PlayerCustomizationBloc"
```

---

### Task 2: PIN dialog loading spinner + small-device keyboard fix

**Files:**
- Modify: `lib/player/view/customize_player_page.dart:337-482` (`_showPinDialog`)
- Test: Create `test/player/customize_player_page_friend_picker_test.dart`

**Interfaces:**
- Consumes: `PlayerCustomizationState.isPinValidating` (Task 1).
- Produces: nothing new for later tasks — this task only changes the dialog's internals, not its trigger point (still the friend tile's `onTap` until Task 6 moves it to the dropdown).

- [ ] **Step 1: Write the failing tests**

Create `test/player/customize_player_page_friend_picker_test.dart`:

```dart
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/customize_player_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

import '../helpers/pump_app.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockScryfallRepository extends Mock implements ScryfallRepository {}

class MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class FakeCommanderLibraryRepository implements CommanderLibraryRepository {
  @override
  Future<void> addRecent(Commander c) async {}
  @override
  Future<List<Commander>> getRecents() async => [];
  @override
  Future<List<Commander>> getFavorites() async => [];
  @override
  Future<bool> isFavorite(Commander c) async => false;
  @override
  Future<bool> toggleFavorite(Commander c) async => false;
}

const testPlayer = Player(
  id: 'p1',
  name: 'Sarah',
  playerNumber: 0,
  lifePoints: 40,
  color: 0xFF378ADD,
  opponents: [],
  state: PlayerModelState.active,
);

const bob = FriendModel(
  userId: 'bob',
  username: 'Bob',
  profilePictureUrl: '',
  friendCode: 'YETI-B0B1',
);

void main() {
  group('CustomizePlayerView PIN dialog', () {
    late MockAppBloc appBloc;
    late MockFriendBloc friendBloc;
    late MockPlayerBloc playerBloc;
    late MockPlayerRepository playerRepository;
    late MockFirebaseDatabaseRepository db;

    setUp(() {
      appBloc = MockAppBloc();
      friendBloc = MockFriendBloc();
      playerBloc = MockPlayerBloc();
      playerRepository = MockPlayerRepository();
      db = MockFirebaseDatabaseRepository();

      when(() => playerRepository.getPlayerById('p1')).thenReturn(testPlayer);
      when(() => playerBloc.state)
          .thenReturn(const PlayerState(player: testPlayer));
      when(() => appBloc.state)
          .thenReturn(const AppState.authenticated(User(id: 'alice')));
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([bob]));
    });

    Future<void> pumpCustomizePlayer(
      WidgetTester tester, {
      Size size = const Size(1600, 1200),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<FriendBloc>.value(value: friendBloc),
            BlocProvider<PlayerBloc>.value(value: playerBloc),
            BlocProvider<PlayerCustomizationBloc>(
              create: (context) => PlayerCustomizationBloc(
                scryfallRepository: MockScryfallRepository(),
                firebaseDatabaseRepository: db,
                commanderLibraryRepository: FakeCommanderLibraryRepository(),
              ),
            ),
          ],
          child: RepositoryProvider<PlayerRepository>.value(
            value: playerRepository,
            child: const CustomizePlayerView(playerId: 'p1'),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
        'Verify button shows a spinner while ValidatePin is pending and '
        'blocks re-submission', (tester) async {
      final completer = Completer<PinResult>();
      when(() => db.validatePin(targetUserId: 'bob', pin: '1234'))
          .thenAnswer((_) => completer.future);

      await pumpCustomizePlayer(tester);
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Verify'), findsNothing);

      final verifyButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(verifyButton.onPressed, isNull);

      final cancelButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancelButton.onPressed, isNull);

      completer.complete(const PinValid());
      await tester.pumpAndSettle();
    });

    testWidgets(
        'PIN dialog stays reachable on a small screen with the keyboard '
        'open', (tester) async {
      when(() => db.validatePin(targetUserId: 'bob', pin: '1234'))
          .thenAnswer((_) async => const PinValid());

      await pumpCustomizePlayer(tester, size: const Size(375, 667));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);

      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Verify'),
        warnIfMissed: true,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: FAIL — the spinner test fails because `CircularProgressIndicator` is never found (the button still shows a `Text` even mid-validation) and `FilledButton.onPressed`/`TextButton.onPressed` aren't `null`; the small-screen test fails because `AlertDialog.scrollable` is `false`.

- [ ] **Step 3: Implement**

In `lib/player/view/customize_player_page.dart`, in `_showPinDialog` (lines 337-482):

1. Add `scrollable: true` to the `AlertDialog` (the `return AlertDialog(` block starting at line 368):

```dart
                  return AlertDialog(
                    scrollable: true,
                    backgroundColor: AppColors.surface,
```

2. Replace the Cancel `TextButton` (lines 442-449) with a `BlocBuilder` that disables it while validating:

```dart
                      BlocBuilder<PlayerCustomizationBloc,
                          PlayerCustomizationState>(
                        buildWhen: (previous, current) =>
                            previous.isPinValidating != current.isPinValidating,
                        builder: (context, state) {
                          return TextButton(
                            onPressed: state.isPinValidating
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: Text(
                              l10n.cancelTextButton,
                              style:
                                  const TextStyle(color: AppColors.neutral60),
                            ),
                          );
                        },
                      ),
```

3. Replace the Verify `BlocBuilder` (lines 450-472) to key off `isPinValidating` too and swap its child for a spinner:

```dart
                      BlocBuilder<PlayerCustomizationBloc,
                          PlayerCustomizationState>(
                        buildWhen: (previous, current) =>
                            previous.pinFlowError != current.pinFlowError ||
                            previous.isPinValidating != current.isPinValidating,
                        builder: (context, state) {
                          final isLockedOut =
                              state.pinFlowError == PinFlowError.lockedOut;
                          final canSubmit = pinController.text.length == 4 &&
                              !isLockedOut &&
                              !state.isPinValidating;
                          return FilledButton(
                            onPressed: canSubmit
                                ? () {
                                    bloc.add(
                                      ValidatePin(
                                        pin: pinController.text,
                                        friendUserId: friend.userId,
                                      ),
                                    );
                                  }
                                : null,
                            child: state.isPinValidating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(l10n.verifyButtonText),
                          );
                        },
                      ),
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add lib/player/view/customize_player_page.dart test/player/customize_player_page_friend_picker_test.dart
git commit -m "fix: PIN dialog shows a loading spinner and stays reachable on small screens"
```

---

### Task 3: Owner selection, mutual exclusivity, and the owner's username

**Files:**
- Modify: `lib/player/view/bloc/player_customization_state.dart`
- Modify: `lib/player/view/bloc/player_customization_event.dart`
- Modify: `lib/player/view/bloc/player_customization_bloc.dart`
- Modify: `lib/player/view/customize_player_page.dart` (one-line rename only — see Step 6)
- Modify: `lib/player/view/widgets/player_identity_panel.dart` (one-line rename only — see Step 6 correction; missed in planning, has a second `ClearFriend()` dispatch site)
- Test: `test/player/player_customization_bloc_test.dart`

**Interfaces:**
- Produces:
  - `OwnerSelected({required String userId})` event — confirms the signed-in user as this seat's link, fetches their `UserProfileModel.username` into state, and clears any friend selection.
  - `SelectFriend({required FriendModel friend})` (existing event, changed behavior) — now unconditionally marks `pinValidated: true` and clears `isAccountOwner`. Safe because both call sites (the PIN dialog's success listener, and Task 5's `initState` rehydration) represent an already-established link, never a fresh unverified pick.
  - `LinkCleared()` event (renamed from `ClearFriend`) — clears both the owner and friend link.
  - `PlayerCustomizationState.ownerUsername` (`String?`) — the signed-in user's username, once fetched.
  - Invariant later tasks rely on: at most one of `state.isAccountOwner` or (`state.selectedFriend != null && state.pinValidated`) is ever true at once.

- [ ] **Step 1: Write the failing tests**

In `test/player/player_customization_bloc_test.dart`, add this new group right after the `group('ResetPinFlow', ...)` block (before the file's closing `}`):

```dart

  group('OwnerSelected', () {
    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'confirms isAccountOwner and clears any existing friend selection',
      build: build,
      seed: () => PlayerCustomizationState(
        selectedFriend: const FriendModel(
          userId: 'bob',
          username: 'Bob',
          profilePictureUrl: '',
        ),
        pinValidated: true,
      ),
      act: (bloc) => bloc.add(const OwnerSelected(userId: 'alice')),
      verify: (bloc) {
        expect(bloc.state.isAccountOwner, isTrue);
        expect(bloc.state.selectedFriend, isNull);
        expect(bloc.state.pinValidated, isFalse);
      },
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'fetches and stores the owner username',
      build: () {
        when(() => db.getUserProfileOnce('alice')).thenAnswer(
          (_) async => const UserProfileModel(id: 'alice', username: 'Alice'),
        );
        return build();
      },
      act: (bloc) => bloc.add(const OwnerSelected(userId: 'alice')),
      verify: (bloc) {
        expect(bloc.state.ownerUsername, 'Alice');
      },
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'leaves ownerUsername unset if the profile fetch returns null',
      build: () {
        when(() => db.getUserProfileOnce('alice'))
            .thenAnswer((_) async => null);
        return build();
      },
      act: (bloc) => bloc.add(const OwnerSelected(userId: 'alice')),
      verify: (bloc) {
        expect(bloc.state.ownerUsername, isNull);
      },
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'still confirms isAccountOwner if the profile fetch throws',
      build: () {
        when(() => db.getUserProfileOnce('alice'))
            .thenThrow(Exception('offline'));
        return build();
      },
      act: (bloc) => bloc.add(const OwnerSelected(userId: 'alice')),
      verify: (bloc) {
        expect(bloc.state.isAccountOwner, isTrue);
        expect(bloc.state.ownerUsername, isNull);
      },
    );
  });

  group('SelectFriend', () {
    const bob = FriendModel(
      userId: 'bob',
      username: 'Bob',
      profilePictureUrl: '',
    );

    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'confirms the friend as validated and clears isAccountOwner',
      build: build,
      seed: () => const PlayerCustomizationState(isAccountOwner: true),
      act: (bloc) => bloc.add(const SelectFriend(friend: bob)),
      verify: (bloc) {
        expect(bloc.state.selectedFriend, bob);
        expect(bloc.state.pinValidated, isTrue);
        expect(bloc.state.isAccountOwner, isFalse);
      },
    );
  });

  group('LinkCleared', () {
    blocTest<PlayerCustomizationBloc, PlayerCustomizationState>(
      'clears both a friend link and owner status',
      build: build,
      seed: () => const PlayerCustomizationState(isAccountOwner: true),
      act: (bloc) => bloc.add(const LinkCleared()),
      verify: (bloc) {
        expect(bloc.state.isAccountOwner, isFalse);
        expect(bloc.state.selectedFriend, isNull);
        expect(bloc.state.pinValidated, isFalse);
      },
    );
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/player/player_customization_bloc_test.dart`
Expected: FAIL to compile — `OwnerSelected` and `LinkCleared` aren't defined, `PlayerCustomizationState` has no `ownerUsername` getter, and `db.getUserProfileOnce` isn't stubbed-recognizable until the mock class covers it (it already does, since `MockDb` implements the full `FirebaseDatabaseRepository`).

- [ ] **Step 3: Implement — state**

In `lib/player/view/bloc/player_customization_state.dart`, add `ownerUsername` to the constructor (after the `isPinValidating` param added in Task 1):

```dart
    this.isPinValidating = false,
    this.ownerUsername,
  });
```

Add the field (after `final bool isPinValidating;`):

```dart
  final bool isPinValidating;
  final String? ownerUsername;
```

Add to `props` (after `isPinValidating,`):

```dart
        isPinValidating,
        ownerUsername,
      ];
```

Add to `copyWith`'s parameters (after `bool? isPinValidating,`) and body (after the `isPinValidating:` line):

```dart
    bool? isPinValidating,
    String? ownerUsername,
  }) {
    return PlayerCustomizationState(
      ...
      isPinValidating: isPinValidating ?? this.isPinValidating,
      ownerUsername: ownerUsername ?? this.ownerUsername,
    );
  }
```

Replace `copyWithClearedFriend()` with three methods — a renamed/expanded version plus two new ones. This is now the **only** place that constructs a confirmed link transition, so all three must explicitly carry `ownerUsername` through and set `isAccountOwner` deliberately (not preserve it) so at most one link type is ever true at once:

```dart
  /// Clears any link (owner or friend) — returns this seat to a fully
  /// unlinked, freely-editable state.
  PlayerCustomizationState copyWithLinkCleared() {
    return PlayerCustomizationState(
      status: status,
      name: name,
      commander: commander,
      partner: partner,
      background: background,
      cardList: cardList,
      magicCardList: magicCardList,
      isAccountOwner: false,
      showOnlyLegendary: showOnlyLegendary,
      availablePairing: availablePairing,
      selectingSecondCard: selectingSecondCard,
      recents: recents,
      favorites: favorites,
      favoriteIds: favoriteIds,
      ownerUsername: ownerUsername,
    );
  }

  /// Confirms the account owner as this seat's linked identity, clearing
  /// any friend link — a seat is linked to at most one account at a time.
  PlayerCustomizationState copyWithOwnerSelected() {
    return PlayerCustomizationState(
      status: status,
      name: name,
      commander: commander,
      partner: partner,
      background: background,
      cardList: cardList,
      magicCardList: magicCardList,
      isAccountOwner: true,
      showOnlyLegendary: showOnlyLegendary,
      availablePairing: availablePairing,
      selectingSecondCard: selectingSecondCard,
      recents: recents,
      favorites: favorites,
      favoriteIds: favoriteIds,
      ownerUsername: ownerUsername,
    );
  }

  /// Confirms [friend] as this seat's linked identity — always treated as
  /// already PIN-validated, since both call sites (the PIN dialog's success
  /// listener, and initState rehydration from an already-persisted
  /// firebaseId) represent a link that was already established, never a
  /// fresh unverified pick. Clears any owner selection.
  PlayerCustomizationState copyWithFriendSelected(FriendModel friend) {
    return PlayerCustomizationState(
      status: status,
      name: name,
      commander: commander,
      partner: partner,
      background: background,
      cardList: cardList,
      magicCardList: magicCardList,
      isAccountOwner: false,
      showOnlyLegendary: showOnlyLegendary,
      availablePairing: availablePairing,
      selectingSecondCard: selectingSecondCard,
      recents: recents,
      favorites: favorites,
      favoriteIds: favoriteIds,
      ownerUsername: ownerUsername,
      selectedFriend: friend,
      pinValidated: true,
    );
  }
```

- [ ] **Step 4: Implement — events**

In `lib/player/view/bloc/player_customization_event.dart`, replace `ClearFriend` (lines 100-102) with:

```dart
final class OwnerSelected extends PlayerCustomizationEvent {
  const OwnerSelected({required this.userId});

  final String userId;

  @override
  List<Object> get props => [userId];
}

final class LinkCleared extends PlayerCustomizationEvent {
  const LinkCleared();
}
```

- [ ] **Step 5: Implement — bloc**

In `lib/player/view/bloc/player_customization_bloc.dart`:

Replace the event registration for `ClearFriend` (line 34, `on<ClearFriend>(_onClearFriend);`) with:

```dart
    on<OwnerSelected>(_onOwnerSelected);
    on<LinkCleared>(_onLinkCleared);
```

Replace `_onSelectFriend` (lines 203-213) with:

```dart
  void _onSelectFriend(
    SelectFriend event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWithFriendSelected(event.friend));
  }

  Future<void> _onOwnerSelected(
    OwnerSelected event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(state.copyWithOwnerSelected());
    try {
      final profile =
          await _firebaseDatabaseRepository.getUserProfileOnce(event.userId);
      if (profile?.username != null && profile!.username!.isNotEmpty) {
        emit(state.copyWith(ownerUsername: profile.username));
      }
    } on Exception catch (_) {
      // Leave ownerUsername unset — PlayerIdentityPanel falls back to
      // whatever name was already persisted for this seat. isAccountOwner
      // stays confirmed either way; a failed username fetch shouldn't
      // block linking the seat to the owner's account.
    }
  }
```

Replace `_onClearFriend` (lines 215-220) with:

```dart
  void _onLinkCleared(
    LinkCleared event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWithLinkCleared());
  }
```

- [ ] **Step 6: Keep the still-tile-based Clear button compiling**

`_FriendSection`'s tile-based UI isn't replaced until Task 6, but its existing
Clear button dispatches the event class just renamed above. Left alone, this
would leave `customize_player_page.dart` failing to compile for Tasks 3-5. In
`lib/player/view/customize_player_page.dart`, inside `_FriendSection.build()`'s
Clear `TextButton`, replace:

```dart
                TextButton(
                  onPressed: () {
                    context
                        .read<PlayerCustomizationBloc>()
                        .add(const ClearFriend());
                    nameController.clear();
                  },
```

with:

```dart
                TextButton(
                  onPressed: () {
                    context
                        .read<PlayerCustomizationBloc>()
                        .add(const LinkCleared());
                    nameController.clear();
                  },
```

This is a pure rename, no behavior change — `_FriendSection` still deletes
and gets fully replaced by Task 6.

**Correction (found during implementation, not caught in planning):** `_FriendLinkRow`'s
"Unlink" button in `lib/player/view/widgets/player_identity_panel.dart` *also*
dispatches `ClearFriend()` — a second call site the pre-flight review missed. It
needs the identical rename. Replace:

```dart
            TextButton(
              onPressed: () => context
                  .read<PlayerCustomizationBloc>()
                  .add(const ClearFriend()),
              child: const Text('Unlink'),
            ),
```

with:

```dart
            TextButton(
              onPressed: () => context
                  .read<PlayerCustomizationBloc>()
                  .add(const LinkCleared()),
              child: const Text('Unlink'),
            ),
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/player/player_customization_bloc_test.dart`
Expected: PASS (all tests, including the 3 new groups).

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: PASS (both Task 2 tests) — this confirms `customize_player_page.dart` still compiles after the Step 6 rename.

- [ ] **Step 8: Commit**

```bash
git add lib/player/view/bloc/player_customization_state.dart lib/player/view/bloc/player_customization_event.dart lib/player/view/bloc/player_customization_bloc.dart lib/player/view/customize_player_page.dart test/player/player_customization_bloc_test.dart
git commit -m "feat: add OwnerSelected event, enforce owner/friend mutual exclusivity"
```

---

### Task 4: Lock the name field for the owner case too

**Files:**
- Modify: `lib/player/view/widgets/player_identity_panel.dart:25-26,176`
- Modify: `lib/l10n/arb/app_en.arb`, `lib/l10n/arb/app_es.arb` (no new keys — see below)
- Test: `test/player/customize_player_page_friend_picker_test.dart`

**Interfaces:**
- Consumes: `PlayerCustomizationState.isAccountOwner`, `.ownerUsername` (Task 3).
- Produces: `PlayerIdentityPanel`'s `isLinked` now also covers the owner case — Task 6's dropdown doesn't depend on this directly, but the visual lock is what the design's "auto-fill and lock" decision is actually about.

The existing `linkedToFriend` ARB key (`"Linked to {name}"`, defined in both `app_en.arb:728` and `app_es.arb:31` but currently unreferenced — the March 2026 predecessor spec left it in place but stopped using it) is put back into use for both the friend and owner cases. No new ARB keys are needed for this task.

- [ ] **Step 1: Write the failing test**

Add this group to `test/player/customize_player_page_friend_picker_test.dart` (add `import 'package:magic_yeti/player/view/bloc/player_customization_event.dart';` and `import 'package:player_repository/player_repository.dart';` if not already present from Task 2 — they are):

```dart

  group('CustomizePlayerView name lock', () {
    late MockAppBloc appBloc;
    late MockFriendBloc friendBloc;
    late MockPlayerBloc playerBloc;
    late MockPlayerRepository playerRepository;
    late MockFirebaseDatabaseRepository db;

    setUp(() {
      appBloc = MockAppBloc();
      friendBloc = MockFriendBloc();
      playerBloc = MockPlayerBloc();
      playerRepository = MockPlayerRepository();
      db = MockFirebaseDatabaseRepository();

      when(() => playerRepository.getPlayerById('p1')).thenReturn(testPlayer);
      when(() => playerBloc.state)
          .thenReturn(const PlayerState(player: testPlayer));
      when(() => appBloc.state)
          .thenReturn(const AppState.authenticated(User(id: 'alice')));
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([bob]));
      when(() => db.getUserProfileOnce('alice')).thenAnswer(
        (_) async => const UserProfileModel(id: 'alice', username: 'Alice'),
      );
    });

    testWidgets(
        'locks the name field and shows "Linked to Alice" once the owner '
        'is confirmed', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late PlayerCustomizationBloc customizationBloc;
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<FriendBloc>.value(value: friendBloc),
            BlocProvider<PlayerBloc>.value(value: playerBloc),
            BlocProvider<PlayerCustomizationBloc>(
              create: (context) {
                customizationBloc = PlayerCustomizationBloc(
                  scryfallRepository: MockScryfallRepository(),
                  firebaseDatabaseRepository: db,
                  commanderLibraryRepository: FakeCommanderLibraryRepository(),
                );
                return customizationBloc;
              },
            ),
          ],
          child: RepositoryProvider<PlayerRepository>.value(
            value: playerRepository,
            child: const CustomizePlayerView(playerId: 'p1'),
          ),
        ),
      );
      await tester.pump();

      customizationBloc.add(const OwnerSelected(userId: 'alice'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Player name',
        ),
      );
      expect(nameField.readOnly, isTrue);
      expect(find.text('Linked to Alice'), findsOneWidget);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: FAIL — `nameField.readOnly` is `false` and `find.text('Linked to Alice')` finds nothing, because `isLinked` doesn't yet consider `isAccountOwner`.

- [ ] **Step 3: Implement**

In `lib/player/view/widgets/player_identity_panel.dart`, replace the `isLinked` computation (lines 25-26):

```dart
        final isLinked = state.isAccountOwner ||
            (state.selectedFriend != null && state.pinValidated);
```

Replace the `_FriendLinkRow` text (line 176):

```dart
              child: Text(
                context.l10n.linkedToFriend(
                  state.isAccountOwner
                      ? (state.ownerUsername ?? context.l10n.accountOwnerOptionLabel)
                      : (state.selectedFriend?.username ?? ''),
                ),
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
```

This references `context.l10n.accountOwnerOptionLabel`, which Task 6 adds. Add it now (Task 6 will also add `notLinkedOptionLabel` at the same time it builds the dropdown, but this task needs `accountOwnerOptionLabel` to exist first). In `lib/l10n/arb/app_en.arb`, add after the `verifyButtonText` block (after line 757):

```json
  "accountOwnerOptionLabel": "Me",
  "@accountOwnerOptionLabel": {
    "description": "Dropdown entry / fallback label to link a player slot to the signed-in user's own account"
  },
```

In `lib/l10n/arb/app_es.arb`, add after `"verifyButtonText": "Verificar",` (line 35):

```json
    "accountOwnerOptionLabel": "Yo",
```

Also import `player_customization_event.dart` at the top of `player_identity_panel.dart` if it's not already reachable through `player_customization_bloc.dart`'s barrel export — check first: `player_customization_bloc.dart` already does `part 'player_customization_event.dart';` and `player_identity_panel.dart` already imports `player_customization_bloc.dart`, so `OwnerSelected` etc. are already visible; no new import needed there.

- [ ] **Step 4: Regenerate localizations**

Run: `flutter gen-l10n --arb-dir="lib/l10n/arb"`
Expected: regenerates `lib/l10n/arb/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_es.dart` with no errors.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/player/view/widgets/player_identity_panel.dart lib/l10n/arb/app_en.arb lib/l10n/arb/app_es.arb lib/l10n/arb/app_localizations.dart lib/l10n/arb/app_localizations_en.dart lib/l10n/arb/app_localizations_es.dart test/player/customize_player_page_friend_picker_test.dart
git commit -m "fix: lock and populate the player name field for the owner link too"
```

---

### Task 5: Rehydrate link state on reopen, and centralize name-field syncing

**Files:**
- Modify: `lib/player/view/customize_player_page.dart` (`initState`, `build`, `_showPinDialog`'s listener)
- Test: `test/player/customize_player_page_friend_picker_test.dart`

**Interfaces:**
- Consumes: `OwnerSelected`, `SelectFriend`, `PlayerCustomizationState.isAccountOwner`/`.ownerUsername`/`.selectedFriend` (Task 3); `FriendBloc`'s `FriendsLoaded` state (existing).
- Produces: after this task, `_nameController.text` is kept in sync with the bloc's confirmed link state by a single listener — Task 6's dropdown `onSelected` handler must NOT also write to `_nameController` directly, to avoid double-handling.

- [ ] **Step 1: Write the failing tests**

Add this group to `test/player/customize_player_page_friend_picker_test.dart`:

```dart

  group('CustomizePlayerView rehydration', () {
    late MockAppBloc appBloc;
    late MockFriendBloc friendBloc;
    late MockPlayerBloc playerBloc;
    late MockPlayerRepository playerRepository;
    late MockFirebaseDatabaseRepository db;

    const linkedToOwnerPlayer = Player(
      id: 'p1',
      name: 'Old Name',
      playerNumber: 0,
      lifePoints: 40,
      color: 0xFF378ADD,
      opponents: [],
      state: PlayerModelState.active,
      firebaseId: 'alice',
    );

    const linkedToFriendPlayer = Player(
      id: 'p1',
      name: 'Bob',
      playerNumber: 0,
      lifePoints: 40,
      color: 0xFF378ADD,
      opponents: [],
      state: PlayerModelState.active,
      firebaseId: 'bob',
    );

    setUp(() {
      appBloc = MockAppBloc();
      friendBloc = MockFriendBloc();
      playerBloc = MockPlayerBloc();
      playerRepository = MockPlayerRepository();
      db = MockFirebaseDatabaseRepository();

      when(() => appBloc.state)
          .thenReturn(const AppState.authenticated(User(id: 'alice')));
      when(() => db.getUserProfileOnce('alice')).thenAnswer(
        (_) async => const UserProfileModel(id: 'alice', username: 'Alice'),
      );
    });

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<FriendBloc>.value(value: friendBloc),
            BlocProvider<PlayerBloc>.value(value: playerBloc),
            BlocProvider<PlayerCustomizationBloc>(
              create: (context) => PlayerCustomizationBloc(
                scryfallRepository: MockScryfallRepository(),
                firebaseDatabaseRepository: db,
                commanderLibraryRepository: FakeCommanderLibraryRepository(),
              ),
            ),
          ],
          child: RepositoryProvider<PlayerRepository>.value(
            value: playerRepository,
            child: const CustomizePlayerView(playerId: 'p1'),
          ),
        ),
      );
    }

    testWidgets(
        'reopening an owner-linked seat re-confirms Me and shows the owner '
        'username, without needing a fresh selection', (tester) async {
      when(() => playerRepository.getPlayerById('p1'))
          .thenReturn(linkedToOwnerPlayer);
      when(() => playerBloc.state)
          .thenReturn(const PlayerState(player: linkedToOwnerPlayer));
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([bob]));

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('Linked to Alice'), findsOneWidget);
    });

    testWidgets(
        'reopening a friend-linked seat re-confirms that friend once the '
        'friend list finishes loading, without a PIN prompt', (tester) async {
      when(() => playerRepository.getPlayerById('p1'))
          .thenReturn(linkedToFriendPlayer);
      when(() => playerBloc.state)
          .thenReturn(const PlayerState(player: linkedToFriendPlayer));
      // Starts loading, then transitions to FriendsLoaded — whenListen
      // drives both the initial `.state` read and the later stream event
      // that the page's BlocListener reacts to, without a manual re-stub.
      whenListen<FriendState>(
        friendBloc,
        Stream.fromIterable([const FriendsLoaded([bob])]),
        initialState: FriendsLoading(),
      );

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Linked to Bob'), findsOneWidget);
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: FAIL — neither "Linked to Alice" nor "Linked to Bob" is found, because `initState` still only dispatches the old (Task-3-removed) `UpdateAccountOwnership` event and nothing reacts to `FriendBloc` reaching `FriendsLoaded`. (This will actually fail to *compile* first, since `UpdateAccountOwnership` was not removed from `player_customization_event.dart`/`_bloc.dart` — it's untouched by Task 3 and still exists, so it still compiles; the failure here is a runtime assertion failure, not a compile error.)

- [ ] **Step 3: Implement**

In `lib/player/view/customize_player_page.dart`, replace the ownership-detection block at the end of `initState` (originally lines 85-88, now shifted slightly by earlier tasks — locate by content, it's the last statements in `initState`):

```dart
    final isOwner = context.read<PlayerBloc>().state.player.firebaseId != null;
    context.read<PlayerCustomizationBloc>().add(
      UpdateAccountOwnership(isOwner: isOwner),
    );
  }
```

with:

```dart
    final currentUserId = context.read<AppBloc>().state.user.id;
    final linkedFirebaseId = context.read<PlayerBloc>().state.player.firebaseId;
    if (linkedFirebaseId != null && linkedFirebaseId == currentUserId) {
      context.read<PlayerCustomizationBloc>().add(
        OwnerSelected(userId: currentUserId),
      );
    }
  }
```

`UpdateAccountOwnership` and its handler/state field (`isAccountOwner`'s setter path via that event) are no longer dispatched from anywhere in the app after this change. Remove the now-dead event entirely: delete the `UpdateAccountOwnership` class from `lib/player/view/bloc/player_customization_event.dart` (the block at lines 73-80), delete its registration `on<UpdateAccountOwnership>(_onUpdateAccountOwnership);` and its handler method `_onUpdateAccountOwnership` from `lib/player/view/bloc/player_customization_bloc.dart` (lines 30 and 169-174). `isAccountOwner` itself stays on `PlayerCustomizationState` — it's now only ever set via `copyWithOwnerSelected()`/`copyWithFriendSelected()`/`copyWithLinkCleared()` from Task 3.

Now replace `CustomizePlayerView.build()`'s top-level return (the `return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(...)` that wraps the whole `Scaffold`) so it's wrapped in a `MultiBlocListener`:

```dart
    return MultiBlocListener(
      listeners: [
        BlocListener<FriendBloc, FriendState>(
          listenWhen: (previous, current) => current is FriendsLoaded,
          listener: (context, friendState) {
            final customState = context.read<PlayerCustomizationBloc>().state;
            if (customState.isAccountOwner ||
                customState.selectedFriend != null) {
              return;
            }
            final linkedFirebaseId =
                context.read<PlayerBloc>().state.player.firebaseId;
            if (linkedFirebaseId == null) return;
            final friends = (friendState as FriendsLoaded).friends;
            FriendModel? match;
            for (final f in friends) {
              if (f.userId == linkedFirebaseId) {
                match = f;
                break;
              }
            }
            if (match != null) {
              context.read<PlayerCustomizationBloc>().add(
                SelectFriend(friend: match),
              );
            }
          },
        ),
        BlocListener<PlayerCustomizationBloc, PlayerCustomizationState>(
          listenWhen: (previous, current) =>
              previous.isAccountOwner != current.isAccountOwner ||
              previous.ownerUsername != current.ownerUsername ||
              previous.selectedFriend != current.selectedFriend,
          listener: (context, state) {
            if (state.isAccountOwner) {
              final owner = state.ownerUsername;
              if (owner != null && owner.isNotEmpty) {
                _nameController.text = owner;
              }
            } else if (state.selectedFriend != null) {
              _nameController.text = state.selectedFriend!.username;
            } else {
              _nameController.clear();
            }
          },
        ),
      ],
      child: BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
        builder: (context, state) {
          // ...existing builder body, unchanged...
        },
      ),
    );
```

Finally, remove the now-redundant manual name write from `_showPinDialog`'s `BlocListener` (the page-level listener above now owns this) — replace:

```dart
              listener: (listenerContext, state) {
                if (state.pinValidated) {
                  // PIN succeeded — select friend, populate name, close
                  bloc.add(SelectFriend(friend: friend));
                  nameController.text = friend.username;
                  Navigator.pop(listenerContext);
                }
                // pinFlowError is shown reactively via the BlocBuilder below
              },
```

with:

```dart
              listener: (listenerContext, state) {
                if (state.pinValidated) {
                  // PIN succeeded — select friend, close. The page-level
                  // BlocListener in CustomizePlayerView.build() populates
                  // the name field once selectedFriend changes.
                  bloc.add(SelectFriend(friend: friend));
                  Navigator.pop(listenerContext);
                }
                // pinFlowError is shown reactively via the BlocBuilder below
              },
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: PASS (all groups so far: PIN dialog, name lock, rehydration).

- [ ] **Step 5: Run the full test suite to check for regressions**

Run: `flutter test`
Expected: PASS. In particular `test/player/customize_player_page_anonymous_test.dart` must still pass unchanged — it never sets a `firebaseId` on its `player` fixture, so the new `initState` owner check is a no-op for it, same as before.

- [ ] **Step 6: Commit**

```bash
git add lib/player/view/customize_player_page.dart lib/player/view/bloc/player_customization_event.dart lib/player/view/bloc/player_customization_bloc.dart test/player/customize_player_page_friend_picker_test.dart
git commit -m "fix: rehydrate owner/friend link state when reopening an already-linked seat"
```

---

### Task 6: Replace the tile list with a searchable dropdown

**Files:**
- Modify: `lib/player/view/customize_player_page.dart` (`_FriendSection`, `_FriendTile` deleted, `CustomizePlayerView.build()`'s call site)
- Modify: `lib/l10n/arb/app_en.arb`, `app_es.arb`
- Test: `test/player/customize_player_page_friend_picker_test.dart`

**Interfaces:**
- Consumes: `OwnerSelected`, `SelectFriend`, `LinkCleared` (Task 3); the name-sync `BlocListener` (Task 5, so `onSelected` below must only dispatch bloc events, never touch `_nameController` itself).
- Produces: nothing further — this is the last task.

- [ ] **Step 1: Write the failing tests**

Add this group to `test/player/customize_player_page_friend_picker_test.dart`:

```dart

  group('CustomizePlayerView friend/owner dropdown', () {
    late MockAppBloc appBloc;
    late MockFriendBloc friendBloc;
    late MockPlayerBloc playerBloc;
    late MockPlayerRepository playerRepository;
    late MockFirebaseDatabaseRepository db;

    setUp(() {
      appBloc = MockAppBloc();
      friendBloc = MockFriendBloc();
      playerBloc = MockPlayerBloc();
      playerRepository = MockPlayerRepository();
      db = MockFirebaseDatabaseRepository();

      when(() => playerRepository.getPlayerById('p1')).thenReturn(testPlayer);
      when(() => playerBloc.state)
          .thenReturn(const PlayerState(player: testPlayer));
      when(() => appBloc.state)
          .thenReturn(const AppState.authenticated(User(id: 'alice')));
      when(() => db.getUserProfileOnce('alice')).thenAnswer(
        (_) async => const UserProfileModel(id: 'alice', username: 'Alice'),
      );
    });

    Future<void> pump(WidgetTester tester, {List<FriendModel>? friends}) async {
      when(() => friendBloc.state)
          .thenReturn(FriendsLoaded(friends ?? const [bob]));
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<FriendBloc>.value(value: friendBloc),
            BlocProvider<PlayerBloc>.value(value: playerBloc),
            BlocProvider<PlayerCustomizationBloc>(
              create: (context) => PlayerCustomizationBloc(
                scryfallRepository: MockScryfallRepository(),
                firebaseDatabaseRepository: db,
                commanderLibraryRepository: FakeCommanderLibraryRepository(),
              ),
            ),
          ],
          child: RepositoryProvider<PlayerRepository>.value(
            value: playerRepository,
            child: const CustomizePlayerView(playerId: 'p1'),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows Me as an entry even with zero friends', (tester) async {
      await pump(tester, friends: []);

      await tester.tap(find.byType(DropdownMenu<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Not linked'), findsOneWidget);
    });

    testWidgets('typing filters the entries', (tester) async {
      const zara = FriendModel(
        userId: 'zara',
        username: 'Zara',
        profilePictureUrl: '',
      );
      await pump(tester, friends: const [bob, zara]);

      await tester.tap(find.byType(DropdownMenu<String?>));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Za');
      await tester.pumpAndSettle();

      expect(find.text('Zara'), findsWidgets);
      expect(find.text('Bob'), findsNothing);
    });

    testWidgets('selecting Me dispatches OwnerSelected with no PIN dialog',
        (tester) async {
      await pump(tester);

      await tester.tap(find.byType(DropdownMenu<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Me').last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Linked to Alice'), findsOneWidget);
    });

    testWidgets('selecting a friend opens the PIN dialog', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(DropdownMenu<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Verify Bob'), findsOneWidget);
    });

    testWidgets('cancelling the PIN dialog reverts the dropdown display',
        (tester) async {
      await pump(tester);

      await tester.tap(find.byType(DropdownMenu<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, isNot('Bob'));
    });

    testWidgets('selecting Not linked clears an existing link', (tester) async {
      late PlayerCustomizationBloc customizationBloc;
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([bob]));
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<FriendBloc>.value(value: friendBloc),
            BlocProvider<PlayerBloc>.value(value: playerBloc),
            BlocProvider<PlayerCustomizationBloc>(
              create: (context) {
                customizationBloc = PlayerCustomizationBloc(
                  scryfallRepository: MockScryfallRepository(),
                  firebaseDatabaseRepository: db,
                  commanderLibraryRepository: FakeCommanderLibraryRepository(),
                );
                return customizationBloc;
              },
            ),
          ],
          child: RepositoryProvider<PlayerRepository>.value(
            value: playerRepository,
            child: const CustomizePlayerView(playerId: 'p1'),
          ),
        ),
      );
      await tester.pump();
      customizationBloc.add(const OwnerSelected(userId: 'alice'));
      await tester.pumpAndSettle();
      expect(customizationBloc.state.isAccountOwner, isTrue);

      await tester.tap(find.byType(DropdownMenu<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not linked').last);
      await tester.pumpAndSettle();

      expect(customizationBloc.state.isAccountOwner, isFalse);
      expect(find.text('Linked to Alice'), findsNothing);
    });
  });
```

**Corrections (found during implementation, not caught in planning):** two of the
assertions above and the tap target used throughout don't hold against real
`DropdownMenu` internals in this Flutter SDK:

1. `find.byType(DropdownMenu<String?>)` cannot be tapped to open the menu once
   wrapped in `SizedBox(width: double.infinity)` — the computed tap center lands
   outside the internal `TextField`'s actual hit-testable area. Use
   `find.byType(TextField).first` as the tap target everywhere a test needs to
   open the dropdown (matches the existing `find.byType(TextField).last` idiom
   already used for the PIN field elsewhere in this file). This also applies to
   the two pre-existing PIN-dialog tests from Task 2, which tapped `'Bob'`
   directly against the old tile UI — they need the same "open the dropdown
   first" treatment now that the tile is gone.
2. `DropdownMenu` keeps a permanent, invisible, `excludeSemantics: true` copy of
   every entry's label in the tree (for internal width measurement, built from
   the *unfiltered* entry list) — separate from the live, filterable overlay.
   So `findsOneWidget`/`findsNothing` against a label's `Text` will never hold:
   every original label always has at least one match, filtered or not, open or
   closed. Use `findsWidgets` for "the entry exists" (as the "typing filters the
   entries" test already does for "Zara"), and to assert something is
   genuinely *filtered out*, scope the finder to exclude the invisible copy
   (e.g. via an `ExcludeSemantics(excluding: false)` ancestor predicate,
   distinguishing the real interactive list from the hidden measurement one).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: FAIL — `find.byType(DropdownMenu<String?>)` finds nothing (the tile list is still in place), and `'Not linked'`/`'Me'` text doesn't exist anywhere yet.

- [ ] **Step 3: Implement**

In `lib/player/view/customize_player_page.dart`:

Update the `_FriendSection` call site inside `CustomizePlayerView.build()` (the `Column` inside the left `_Panel`):

```dart
                              children: [
                                const _FriendSection(),
                                PlayerIdentityPanel(
```

Delete `_FriendTile` entirely (the class at the end of the file, originally lines 485-561).

Replace the whole `_FriendSection` class with:

```dart
class _FriendSection extends StatefulWidget {
  const _FriendSection();

  @override
  State<_FriendSection> createState() => _FriendSectionState();
}

class _FriendSectionState extends State<_FriendSection> {
  int _resetNonce = 0;

  void _forceReset() {
    if (mounted) setState(() => _resetNonce++);
  }

  @override
  Widget build(BuildContext context) {
    final customState = context.watch<PlayerCustomizationBloc>().state;
    final friendState = context.watch<FriendBloc>().state;
    final appState = context.watch<AppBloc>().state;
    final isAnonymous = appState.status == AppStatus.anonymous;

    // Anonymous users have no friend graph to link against — the callable
    // backing this list requires an authenticated uid, so show intentional
    // copy instead of an empty/loading friend list.
    if (isAnonymous) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xlg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          context.l10n.signInToLinkFriends,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutral60,
          ),
        ),
      );
    }

    final friends =
        friendState is FriendsLoaded ? friendState.friends : <FriendModel>[];
    final sortedFriends = List<FriendModel>.from(friends)
      ..sort(
        (a, b) =>
            a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );

    final currentUserId = appState.user.id;
    final confirmedValue = customState.isAccountOwner
        ? currentUserId
        : (customState.selectedFriend != null && customState.pinValidated
            ? customState.selectedFriend!.userId
            : null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectFriendLabel,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral60,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: DropdownMenu<String?>(
              key: ValueKey('$confirmedValue-$_resetNonce'),
              initialSelection: confirmedValue,
              enableFilter: true,
              enableSearch: true,
              // Correction (found during implementation, not caught in
              // planning): DropdownMenu.requestFocusOnTap defaults to false
              // on iOS/Android/Fuchsia, which makes the internal TextField
              // readOnly and silently disables type-to-search on this app's
              // two primary platforms. Required for enableFilter to do
              // anything on a real device.
              requestFocusOnTap: true,
              hintText: context.l10n.notLinkedOptionLabel,
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: null,
                  label: context.l10n.notLinkedOptionLabel,
                ),
                DropdownMenuEntry(
                  value: currentUserId,
                  label: context.l10n.accountOwnerOptionLabel,
                ),
                ...sortedFriends.map(
                  (friend) => DropdownMenuEntry(
                    value: friend.userId,
                    label: friend.username,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == null) {
                  context.read<PlayerCustomizationBloc>().add(
                        const LinkCleared(),
                      );
                } else if (value == currentUserId) {
                  context.read<PlayerCustomizationBloc>().add(
                        OwnerSelected(userId: currentUserId),
                      );
                } else {
                  final friend = sortedFriends.firstWhere(
                    (f) => f.userId == value,
                  );
                  _showPinDialog(context, friend);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  String? _pinErrorText(BuildContext context, PlayerCustomizationState state) {
    final l10n = context.l10n;
    return switch (state.pinFlowError) {
      PinFlowError.none => null,
      PinFlowError.incorrect =>
        l10n.pinIncorrectError(state.pinAttemptsRemaining),
      PinFlowError.lockedOut => l10n.pinLockedOutError(
          state.pinLockedUntil == null
              ? 15
              : (state.pinLockedUntil!
                          .difference(DateTime.now())
                          .inSeconds /
                      60)
                  .ceil()
                  .clamp(1, 15),
        ),
      PinFlowError.unavailable => l10n.pinUnavailableError,
      PinFlowError.notSet => l10n.pinNotSetError,
    };
  }

  void _showPinDialog(BuildContext context, FriendModel friend) {
    final pinController = TextEditingController();
    final bloc = context.read<PlayerCustomizationBloc>();
    final l10n = context.l10n;

    // Clear any stale error/lockout state left over from a previous
    // friend's dialog before this one opens.
    bloc.add(const ResetPinFlow());

    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return BlocProvider.value(
            value: bloc,
            child: BlocListener<PlayerCustomizationBloc,
                PlayerCustomizationState>(
              listenWhen: (previous, current) =>
                  previous.pinValidated != current.pinValidated ||
                  previous.pinFlowError != current.pinFlowError,
              listener: (listenerContext, state) {
                if (state.pinValidated) {
                  // PIN succeeded — select friend, close. The page-level
                  // BlocListener in CustomizePlayerView.build() populates
                  // the name field once selectedFriend changes.
                  bloc.add(SelectFriend(friend: friend));
                  Navigator.pop(listenerContext);
                }
                // pinFlowError is shown reactively via the BlocBuilder below
              },
              child: StatefulBuilder(
                builder: (dialogContext, setDialogState) {
                  return AlertDialog(
                    scrollable: true,
                    backgroundColor: AppColors.surface,
                    title: Text(
                      l10n.verifyFriendTitle(friend.username),
                      style: const TextStyle(color: AppColors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.enterPinPrompt,
                          style:
                              const TextStyle(color: AppColors.neutral60),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        BlocBuilder<PlayerCustomizationBloc,
                            PlayerCustomizationState>(
                          buildWhen: (previous, current) =>
                              previous.pinFlowError != current.pinFlowError ||
                              previous.pinAttemptsRemaining !=
                                  current.pinAttemptsRemaining ||
                              previous.pinLockedUntil !=
                                  current.pinLockedUntil,
                          builder: (context, state) {
                            return TextField(
                              controller: pinController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 8,
                                color: AppColors.white,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                counterText: '',
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.neutral60,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.tertiary,
                                  ),
                                ),
                                errorBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.red,
                                  ),
                                ),
                                focusedErrorBorder:
                                    const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.red,
                                  ),
                                ),
                                errorText: _pinErrorText(context, state),
                                errorStyle: const TextStyle(
                                  color: AppColors.red,
                                ),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            );
                          },
                        ),
                      ],
                    ),
                    actions: [
                      BlocBuilder<PlayerCustomizationBloc,
                          PlayerCustomizationState>(
                        buildWhen: (previous, current) =>
                            previous.isPinValidating != current.isPinValidating,
                        builder: (context, state) {
                          return TextButton(
                            onPressed: state.isPinValidating
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: Text(
                              l10n.cancelTextButton,
                              style:
                                  const TextStyle(color: AppColors.neutral60),
                            ),
                          );
                        },
                      ),
                      BlocBuilder<PlayerCustomizationBloc,
                          PlayerCustomizationState>(
                        buildWhen: (previous, current) =>
                            previous.pinFlowError != current.pinFlowError ||
                            previous.isPinValidating != current.isPinValidating,
                        builder: (context, state) {
                          final isLockedOut =
                              state.pinFlowError == PinFlowError.lockedOut;
                          final canSubmit =
                              pinController.text.length == 4 &&
                                  !isLockedOut &&
                                  !state.isPinValidating;
                          return FilledButton(
                            onPressed: canSubmit
                                ? () {
                                    bloc.add(
                                      ValidatePin(
                                        pin: pinController.text,
                                        friendUserId: friend.userId,
                                      ),
                                    );
                                  }
                                : null,
                            child: state.isPinValidating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(l10n.verifyButtonText),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ).then((_) {
        final confirmed =
            bloc.state.selectedFriend?.userId == friend.userId &&
                bloc.state.pinValidated;
        if (!confirmed) {
          _forceReset();
        }
      }),
    );
  }
}
```

(This step folds in Task 2's and Task 5's dialog changes verbatim since the whole class is being replaced — nothing from those tasks is lost, the `scrollable: true`, the two `isPinValidating`-aware `BlocBuilder`s, and the `SelectFriend`-without-manual-name-write listener are all still here.)

Add the two new l10n keys. In `lib/l10n/arb/app_en.arb`, after the `accountOwnerOptionLabel` block added in Task 4:

```json
  "notLinkedOptionLabel": "Not linked",
  "@notLinkedOptionLabel": {
    "description": "Dropdown entry meaning this player slot is not linked to any account"
  },
```

In `lib/l10n/arb/app_es.arb`, after `"accountOwnerOptionLabel": "Yo",`:

```json
    "notLinkedOptionLabel": "Sin vincular",
```

- [ ] **Step 4: Regenerate localizations**

Run: `flutter gen-l10n --arb-dir="lib/l10n/arb"`
Expected: no errors.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/player/customize_player_page_friend_picker_test.dart`
Expected: PASS (every group in the file).

- [ ] **Step 6: Run the full test suite and analyzer**

Run: `flutter test`
Expected: PASS, including `test/player/customize_player_page_anonymous_test.dart` (the anonymous placeholder path is untouched by this task — `_FriendSection` still checks `isAnonymous` first, before ever building the dropdown).

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 7: Manual verification**

Run the app (`flutter run --flavor development --target lib/main_development.dart`) on a small simulated device (e.g. iPhone SE) and confirm: the dropdown opens and filters as you type with 0 and with several friends; picking "Me" locks the name immediately with no dialog; picking a friend opens the PIN dialog and the Verify button is reachable with the keyboard open; cancelling reverts the dropdown's displayed text.

- [ ] **Step 8: Commit**

```bash
git add lib/player/view/customize_player_page.dart lib/l10n/arb/app_en.arb lib/l10n/arb/app_es.arb lib/l10n/arb/app_localizations.dart lib/l10n/arb/app_localizations_en.dart lib/l10n/arb/app_localizations_es.dart test/player/customize_player_page_friend_picker_test.dart
git commit -m "feat: replace the friend tile list with a searchable Me/friend/unlinked dropdown"
```

---

## Deliberate deviations from the spec (called out, not hidden)

- **Stale/unfriended link on reopen:** the spec says "don't silently clear a real, persisted link" if the friend list doesn't contain a match. This plan does exactly that by taking no action — but since `_save()` always recomputes `firebaseId` fresh from the confirmed bloc state (never "preserves whatever was there if the dropdown was never touched"), an untouched dropdown showing "Not linked" *will* save as unlinked, clearing the stale id on next save. Implementing true preservation would require a fourth state bucket ("unresolved but present") purely to distinguish "user explicitly chose unlinked" from "we couldn't resolve a display label" — not justified for an edge case (a friend who unfriended you) where clearing the link on next save is arguably the more correct outcome anyway, not just the simpler one.
- **Fast-tap-save race:** if a user hits Save before `FriendBloc` finishes loading on an already friend-linked seat, the same clearing-on-save behavior applies (the rehydration listener hasn't had a chance to fire yet). Not mitigated — blocking Save until friends finish loading would hurt the common no-link-anyway case to guard a narrow, low-frequency race.

## Self-Review Notes

- **Spec coverage:** dropdown+search (Task 6), owner as a selectable entry (Tasks 3, 6), rehydration fix (Task 5), name lock extended to owner (Task 4), PIN dialog loading state + click-only-submit preserved (Tasks 1, 2), keyboard overlap fix (Task 2) — all covered. The two accepted deviations above are the only places this plan doesn't literally match the spec's wording, and both are explained.
- **Placeholder scan:** no TBD/TODO; every step has complete code; the one place code is repeated verbatim across tasks (Task 6 restates Task 2's and Task 5's dialog changes) is because Task 6 replaces the entire enclosing class, not a "see Task N" reference.
- **Type consistency:** `OwnerSelected(userId: ...)`, `SelectFriend(friend: ...)`, `LinkCleared()`, `isPinValidating`, `ownerUsername`, `copyWithOwnerSelected()`/`copyWithFriendSelected()`/`copyWithLinkCleared()` are named and typed identically everywhere they're introduced (Tasks 1, 3) and consumed (Tasks 2, 4, 5, 6).

## Post-implementation design pass (2026-07-06)

After all 6 tasks shipped, the dropdown didn't visually match the page's
existing dark theme (`DropdownMenu` has its own dedicated theme slot,
`DropdownMenuThemeData`, which nothing in `app_theme.dart` sets — it was
rendering in unthemed Material 3 defaults while every sibling control had
explicit dark-theme styling). Fixed in `_FriendSectionState.build()`:

- `inputDecorationTheme`, `textStyle`, `menuStyle`, and a `leadingIcon`
  added directly to the `DropdownMenu` construction, reusing only
  colors/spacing already established elsewhere on this page
  (`AppColors.surface`/`neutral60`/`white`, `AppSpacing.sm` corner radius) —
  no new design tokens introduced.
- Each `DropdownMenuEntry` gets a shared `_entryStyle` (white foreground)
  since the popup's dark background made Material 3's default entry text
  color barely legible.
- Replaced the `SizedBox(width: double.infinity)` wrapper with
  `expandedInsets: EdgeInsets.zero` — confirmed via the Flutter SDK source
  that `DropdownMenu` sizes itself to content width regardless of a
  `SizedBox` parent; the field never actually stretched to match the name
  field below it (visually confirmed by the user on a real device/tablet
  build, since this sandbox's browser preview never got past initial
  compile — see below).
- `expandedInsets` has a real, SDK-documented side effect: it skips
  building the always-present "invisible measurement copy" of every entry
  label that a non-expanded `DropdownMenu` keeps in the tree for width
  calculation. `test/player/customize_player_page_anonymous_test.dart`'s
  "shows the friend list... when authenticated" test relied on that
  implementation detail (`find.text('Bob')` with no interaction) and had
  to open the dropdown first before checking for the entry.

**Environment note:** this session's browser-preview tooling repeatedly
stalled at the same Flutter web DDC-compile step (twice, including one
outright server crash) and could never render the page — likely a sandbox
resource limit for this app's dependency size, not a code issue. All
visual confirmation for this pass came from a screenshot the user
provided from their own device.
