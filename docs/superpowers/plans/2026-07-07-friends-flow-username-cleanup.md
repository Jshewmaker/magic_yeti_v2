# Friends Flow Username Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make username the sole user identity — harden its validation, remove firstName/lastName from every layer (model, onboarding, profile, auth, l10n, tests), and clean up friends-search error copy.

**Architecture:** BLoC + Repository Flutter app. Changes are ordered so every commit leaves the tree green: validator first, l10n string additions second, then usage removal (onboarding → profile), then model field removal + codegen, then the auth layer, then the search-copy fix. The Firestore docs need no migration: `updateUserProfile` writes the full doc with `set()` (no merge), so stale name keys drop on each user's next save, and `json_serializable` ignores unknown keys on read.

**Tech Stack:** Flutter, bloc/flutter_bloc, formz (`form_inputs` package), json_serializable codegen, flutter gen-l10n (ARB, en+es), mocktail/bloc_test.

**Spec:** `docs/superpowers/specs/2026-07-07-friends-flow-username-cleanup-design.md`

## Global Constraints

- Lints: `very_good_analysis` (strict). Run `flutter analyze` before each commit; pre-existing `app_ui` gallery errors are the known baseline — introduce nothing new.
- Codegen: after editing any `@JsonSerializable` model run `dart run build_runner build --delete-conflicting-outputs` in that package.
- Localization: ARB files in `lib/l10n/arb/` (en + es, both mandatory); regenerate with `flutter gen-l10n --arb-dir="lib/l10n/arb"`; generated `app_localizations*.dart` files are committed.
- Username bounds (spec): trimmed, min 2 chars, max 30 chars. `UserProfileModel.isComplete` keeps its loose non-empty check (legacy users must not be bounced into onboarding).
- Commit messages: semantic prefixes (`feat:`/`fix:`/`test:`/`chore:`/`refactor:`), ending with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Do NOT touch `functions/`, `firestore.rules`, or `firestore.indexes.json` — this plan is app-client only and must add no deploy gates.

---

### Task 0: Commit the pending friend-dropdown polish

The working tree carries finished-but-uncommitted UI polish from the previous session (dropdown theming/alignment in `customize_player_page.dart`, X-to-clear button in `player_identity_panel.dart`, matching l10n + test updates). Land it as its own commit so this plan's commits stay clean.

**Files:**
- Modify (already modified, just commit): `lib/player/view/customize_player_page.dart`, `lib/player/view/widgets/player_identity_panel.dart`, `lib/l10n/arb/app_en.arb`, `lib/l10n/arb/app_es.arb`, `lib/l10n/arb/app_localizations*.dart`, `test/player/customize_player_page_anonymous_test.dart`, `test/player/customize_player_page_friend_picker_test.dart`

- [ ] **Step 1: Verify the pending work is green**

Run: `flutter test test/player/customize_player_page_anonymous_test.dart test/player/customize_player_page_friend_picker_test.dart && flutter analyze lib/player`
Expected: all tests pass; no analyzer issues in lib/player.

- [ ] **Step 2: Commit**

```bash
git add lib/player lib/l10n test/player
git commit -m "style: theme the friend dropdown for the dark surface and move clear into the name field

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 1: Harden the Username formz input

**Files:**
- Create: `packages/form_inputs/test/src/username_test.dart`
- Modify: `packages/form_inputs/lib/src/username.dart`

**Interfaces:**
- Produces: `UsernameValidationError { empty, tooShort, tooLong }`, `Username.minLength == 2`, `Username.maxLength == 30`. Validation runs on the **trimmed** value. Later tasks map each error to l10n copy and persist `value.trim()`.

- [ ] **Step 1: Write the failing test**

Create `packages/form_inputs/test/src/username_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:form_inputs/form_inputs.dart';

void main() {
  group('Username', () {
    test('pure empty value reports no display error and is not valid', () {
      const username = Username.pure();
      expect(username.displayError, isNull);
      expect(username.isValid, isFalse);
    });

    test('empty dirty value has the empty error', () {
      const username = Username.dirty();
      expect(username.error, UsernameValidationError.empty);
    });

    test('whitespace-only value has the empty error', () {
      const username = Username.dirty('   ');
      expect(username.error, UsernameValidationError.empty);
    });

    test('one character after trimming is too short', () {
      const username = Username.dirty(' a ');
      expect(username.error, UsernameValidationError.tooShort);
    });

    test('31 characters after trimming is too long', () {
      final username = Username.dirty('a' * 31);
      expect(username.error, UsernameValidationError.tooLong);
    });

    test('2 and 30 trimmed characters are valid', () {
      expect(Username.dirty('ab').isValid, isTrue);
      expect(Username.dirty(' ${'a' * 30} ').isValid, isTrue);
    });

    test('interior spaces are allowed', () {
      expect(Username.dirty('Cool Name').isValid, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/form_inputs && flutter test test/src/username_test.dart`
Expected: FAIL — `tooShort`/`tooLong` are not defined; whitespace test fails against the current `isNotEmpty` check.

- [ ] **Step 3: Implement the validator**

Replace the body of `packages/form_inputs/lib/src/username.dart`:

```dart
import 'package:formz/formz.dart';

/// Username Form Input Validation Error
enum UsernameValidationError {
  /// Username is empty or whitespace-only.
  empty,

  /// Username is shorter than [Username.minLength] after trimming.
  tooShort,

  /// Username is longer than [Username.maxLength] after trimming.
  tooLong,
}

/// {@template username}
/// Reusable username form input.
///
/// Validates the trimmed value; callers persist `value.trim()` so stored
/// usernames never carry edge whitespace.
/// {@endtemplate}
class Username extends FormzInput<String, UsernameValidationError> {
  /// {@macro username}
  const Username.pure() : super.pure('');

  /// {@macro username}
  const Username.dirty([super.value = '']) : super.dirty();

  /// Minimum trimmed length — matches the server-side username search's
  /// 2-character minimum query, so every valid username is discoverable.
  static const minLength = 2;

  /// Maximum trimmed length.
  static const maxLength = 30;

  @override
  UsernameValidationError? validator(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return UsernameValidationError.empty;
    if (trimmed.length < minLength) return UsernameValidationError.tooShort;
    if (trimmed.length > maxLength) return UsernameValidationError.tooLong;
    return null;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/form_inputs && flutter test`
Expected: PASS (all package tests).

- [ ] **Step 5: Check downstream suites still pass**

Run: `flutter test test/onboarding test/profile`
Expected: PASS — existing tests use usernames like `'josh'` which satisfy the new bounds. If any test uses a 1-char username, lengthen it to a 2+ char value in that test.

- [ ] **Step 6: Commit**

```bash
git add packages/form_inputs
git commit -m "feat: validate usernames on the trimmed value with 2-30 char bounds

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Add the new l10n strings (en + es)

**Files:**
- Modify: `lib/l10n/arb/app_en.arb`, `lib/l10n/arb/app_es.arb`
- Regenerate: `lib/l10n/arb/app_localizations*.dart`

**Interfaces:**
- Produces l10n getters used by Tasks 3, 4, 7: `usernameRequiredError`, `usernameTooShortError`, `usernameTooLongError`, `usernameInvalidMessage`, `searchFailedMessage`.

- [ ] **Step 1: Add the English strings**

In `lib/l10n/arb/app_en.arb`, insert after the `@usernameHelperText` block (currently ends at line 898, right before `"firstNameLabel"`):

```json
  "usernameRequiredError": "Username is required",
  "@usernameRequiredError": {
    "description": "Inline error when the username field is empty or whitespace-only"
  },
  "usernameTooShortError": "Username must be at least 2 characters",
  "@usernameTooShortError": {
    "description": "Inline error when the trimmed username is shorter than 2 characters"
  },
  "usernameTooLongError": "Username must be 30 characters or fewer",
  "@usernameTooLongError": {
    "description": "Inline error when the trimmed username is longer than 30 characters"
  },
  "usernameInvalidMessage": "Fix your username before saving.",
  "@usernameInvalidMessage": {
    "description": "Snackbar shown when a profile save is blocked by an invalid username"
  },
  "searchFailedMessage": "Search failed. Check your connection and try again.",
  "@searchFailedMessage": {
    "description": "Friendly error shown when a friend search fails"
  },
```

- [ ] **Step 2: Add the Spanish strings**

In `lib/l10n/arb/app_es.arb`, insert after the `"usernameHelperText"` line (line 67; the es file carries values only, no `@` description blocks):

```json
    "usernameRequiredError": "El nombre de usuario es obligatorio",
    "usernameTooShortError": "El nombre de usuario debe tener al menos 2 caracteres",
    "usernameTooLongError": "El nombre de usuario debe tener 30 caracteres o menos",
    "usernameInvalidMessage": "Corrige tu nombre de usuario antes de guardar.",
    "searchFailedMessage": "La búsqueda falló. Comprueba tu conexión e inténtalo de nuevo.",
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n --arb-dir="lib/l10n/arb"`
Expected: exits 0; `lib/l10n/arb/app_localizations.dart` gains the five new abstract getters; en/es implementations updated.

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/l10n`
Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n
git commit -m "feat: add localized username validation and search failure copy

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Onboarding — username-only identity step, trimmed save, localized errors

**Files:**
- Modify: `lib/onboarding/bloc/onboarding_event.dart` (delete lines 26–40)
- Modify: `lib/onboarding/bloc/onboarding_state.dart`
- Modify: `lib/onboarding/bloc/onboarding_bloc.dart`
- Modify: `lib/onboarding/view/onboarding_form.dart`
- Test: `test/onboarding/bloc/onboarding_bloc_test.dart`

**Interfaces:**
- Consumes: `UsernameValidationError.{empty,tooShort,tooLong}` (Task 1), l10n getters (Task 2).
- Produces: `OnboardingState` without `firstName`/`lastName`; submit persists `state.username.value.trim()`.

- [ ] **Step 1: Write the failing bloc tests**

Append a new group inside `main()` in `test/onboarding/bloc/onboarding_bloc_test.dart` (harness already provides `buildBloc` and `firebaseDatabaseRepository`):

```dart
  group('username hardening', () {
    test('whitespace-only username keeps step 0 invalid', () {
      final bloc = buildBloc()..add(const OnboardingUsernameChanged('   '));
      addTearDown(bloc.close);
      expect(bloc.state.isStepValid, isFalse);
    });

    blocTest<OnboardingBloc, OnboardingState>(
      'submit persists the trimmed username',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenAnswer(
          (_) async => const UserProfileModel(id: 'u1', friendCode: 'ABCD1234'),
        );
        when(
          () => firebaseDatabaseRepository.updateUserProfile(any(), any()),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc
        ..add(const OnboardingUsernameChanged('  josh  '))
        ..add(const OnboardingSubmitted('u1')),
      verify: (_) {
        final saved = verify(
          () => firebaseDatabaseRepository.updateUserProfile('u1', captureAny()),
        ).captured.single as UserProfileModel;
        expect(saved.username, 'josh');
      },
    );
  });
```

- [ ] **Step 2: Run tests to verify the new ones fail**

Run: `flutter test test/onboarding/bloc/onboarding_bloc_test.dart`
Expected: the trim test FAILS (saved username is `'  josh  '`); the whitespace test FAILS only if Task 1 was skipped — it should already pass. (If the submit test fails on an unstubbed `setPin`, no PIN was entered so `setPin` must not be called — that would indicate a harness drift to fix here.)

- [ ] **Step 3: Remove firstName/lastName from the onboarding bloc layer and trim the saved username**

`lib/onboarding/bloc/onboarding_event.dart`: delete the `OnboardingFirstNameChanged` and `OnboardingLastNameChanged` classes.

`lib/onboarding/bloc/onboarding_state.dart`: delete the `firstName`/`lastName` constructor params (`this.firstName = ''`, `this.lastName = ''`), field declarations, `copyWith` params and assignments, and their two `props` entries.

`lib/onboarding/bloc/onboarding_bloc.dart`:
- Delete `firstName: existingProfile?.firstName ?? '',` and `lastName: existingProfile?.lastName ?? '',` from the constructor's initial state.
- Delete `on<OnboardingFirstNameChanged>(_onFirstNameChanged);` and `on<OnboardingLastNameChanged>(_onLastNameChanged);` plus both handler methods.
- In `_onSubmitted`'s `UserProfileModel(...)`: delete `firstName: state.firstName,` and `lastName: state.lastName,`, and change `username: state.username.value,` to:

```dart
          username: state.username.value.trim(),
```

- [ ] **Step 4: Remove the name fields from the identity step and localize the username error**

`lib/onboarding/view/onboarding_form.dart`, in `_IdentityStepState`:
- Delete `_firstNameController`/`_lastNameController` declarations, their `initState` assignments, and their `dispose()` calls.
- Delete the two name `TextField`s and the two `const SizedBox(height: 16)` separators that precede them (everything after the username `BlocBuilder` inside the `Column`).
- Replace the hardcoded error text:

```dart
                  errorText: switch (state.username.displayError) {
                    UsernameValidationError.empty =>
                      context.l10n.usernameRequiredError,
                    UsernameValidationError.tooShort =>
                      context.l10n.usernameTooShortError,
                    UsernameValidationError.tooLong =>
                      context.l10n.usernameTooLongError,
                    null => null,
                  },
```

Add `import 'package:form_inputs/form_inputs.dart';` and `import 'package:magic_yeti/l10n/l10n.dart';` if not already present.

- [ ] **Step 5: Run tests and analyze**

Run: `flutter test test/onboarding && flutter analyze lib/onboarding`
Expected: PASS; no analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add lib/onboarding test/onboarding
git commit -m "refactor: onboarding identity step collects only a username, trimmed on save

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Profile — remove names, inline username errors, distinct blocked-save copy

**Files:**
- Modify: `lib/profile/bloc/profile_event.dart` (delete `ProfileFirstNameChanged`, `ProfileLastNameChanged`)
- Modify: `lib/profile/bloc/profile_state.dart`
- Modify: `lib/profile/bloc/profile_bloc.dart`
- Modify: `lib/profile/view/profile_page.dart`
- Test: `test/profile/bloc/profile_bloc_test.dart`, `test/profile/view/profile_page_test.dart`

**Interfaces:**
- Consumes: `UsernameValidationError` (Task 1), `usernameInvalidMessage` + username error getters (Task 2).
- Produces: `ProfileStatus.usernameInvalid` enum value; `ProfileState` without `firstName`/`lastName`; saves persist `state.username?.value.trim()`.

- [ ] **Step 1: Write the failing bloc tests**

In `test/profile/bloc/profile_bloc_test.dart`:

Remove `firstName: 'Josh',` and `lastName: 'Shew',` from the `loadedProfile` fixture and `name: 'Josh'` stays for now (auth cleanup is Task 6). Replace the existing "saves first/last name" expectations (the test around lines 140–165 that dispatches `ProfileFirstNameChanged('NewFirst')` / `ProfileLastNameChanged('NewLast')` and asserts `saved.firstName`/`saved.lastName`) with a bio-based equivalent, and add the two new tests:

```dart
    blocTest<ProfileBloc, ProfileState>(
      'submit saves edited bio and trimmed username onto the loaded profile',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenAnswer((_) async => loadedProfile);
        when(
          () => firebaseDatabaseRepository.updateUserProfile(any(), any()),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc
        ..add(const ProfileLoadRequested('u1'))
        ..add(const ProfileUsernameChanged('  josh2  '))
        ..add(const ProfileBioChanged('new bio'))
        ..add(const ProfileSubmitted()),
      verify: (_) {
        final saved = verify(
          () => firebaseDatabaseRepository.updateUserProfile('u1', captureAny()),
        ).captured.single as UserProfileModel;
        expect(saved.username, 'josh2');
        expect(saved.bio, 'new bio');
        // Untouched fields carry over from the loaded profile.
        expect(saved.friendCode, 'YETI-A3F9');
        expect(saved.hasPin, isTrue);
        expect(saved.onboardingComplete, isTrue);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'submit with an invalid username emits usernameInvalid and never saves',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenAnswer((_) async => loadedProfile);
        return buildBloc();
      },
      act: (bloc) => bloc
        ..add(const ProfileLoadRequested('u1'))
        ..add(const ProfileUsernameChanged('   '))
        ..add(const ProfileSubmitted()),
      verify: (bloc) {
        expect(bloc.state.status, ProfileStatus.usernameInvalid);
        verifyNever(
          () => firebaseDatabaseRepository.updateUserProfile(any(), any()),
        );
      },
    );
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/profile/bloc/profile_bloc_test.dart`
Expected: FAIL — `ProfileStatus.usernameInvalid` undefined; trim not implemented; old first/last test now removed so no reference errors remain.

- [ ] **Step 3: Update the profile bloc layer**

`lib/profile/bloc/profile_event.dart`: delete the `ProfileFirstNameChanged` and `ProfileLastNameChanged` classes.

`lib/profile/bloc/profile_state.dart`: delete `firstName`/`lastName` constructor params, fields, `copyWith` params/assignments, and `props` entries. Change the enum:

```dart
enum ProfileStatus {
  initial,
  loading,
  loaded,
  success,
  failure,
  pinSaved,
  usernameInvalid,
}
```

`lib/profile/bloc/profile_bloc.dart`:
- Delete the two `on<...>` registrations and both handler methods for first/last name.
- In `_onSubmitted`, replace the invalid-username guard's emit and the copyWith:

```dart
    // A present-but-invalid username (e.g. cleared to empty) must never
    // reach updateUserProfile: saving `username: ''` would flip
    // UserProfileModel.isComplete false, bouncing the user back into
    // onboarding on the next auth event.
    if (state.username != null && !Formz.validate([state.username!])) {
      emit(state.copyWith(status: ProfileStatus.usernameInvalid));
      return;
    }
```

```dart
      final updatedProfile = loaded.copyWith(
        username: state.username?.value.trim() ?? loaded.username,
        bio: state.bio ?? loaded.bio,
      );
```

- [ ] **Step 4: Update the profile page**

`lib/profile/view/profile_page.dart`:
- Delete the two `_ProfileField` widgets for `firstNameLabel`/`lastNameLabel`.
- In the `BlocListener`, add before the generic failure branch:

```dart
        if (state.status == ProfileStatus.usernameInvalid) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.usernameInvalidMessage),
                backgroundColor: Colors.red,
              ),
            );
        }
```

- Extend `_ProfileField` with a live error builder (the parent builder only rebuilds on status/isEditing, so the error must come through this widget's own `BlocBuilder`):

```dart
class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.helperText,
    this.errorTextBuilder,
  });

  final String label;
  final String initialValue;
  final void Function(String) onChanged;
  final String? helperText;

  /// Builds live inline error copy from bloc state; null for fields
  /// without validation.
  final String? Function(BuildContext context, ProfileState state)?
      errorTextBuilder;
```

with `buildWhen` extended to `previous.isEditing != current.isEditing || previous.username != current.username` and the editor's decoration becoming:

```dart
                            decoration: InputDecoration(
                              hintText: 'Enter $label',
                              errorText:
                                  errorTextBuilder?.call(context, state),
                            ),
```

- Wire it on the username field only:

```dart
                            _ProfileField(
                              label: context.l10n.usernameLabel,
                              initialValue: profile.username ?? '',
                              helperText: context.l10n.usernameHelperText,
                              errorTextBuilder: (context, state) =>
                                  switch (state.username?.displayError) {
                                UsernameValidationError.empty =>
                                  context.l10n.usernameRequiredError,
                                UsernameValidationError.tooShort =>
                                  context.l10n.usernameTooShortError,
                                UsernameValidationError.tooLong =>
                                  context.l10n.usernameTooLongError,
                                null => null,
                              },
                              onChanged: (value) => context
                                  .read<ProfileBloc>()
                                  .add(ProfileUsernameChanged(value)),
                            ),
```

Add `import 'package:form_inputs/form_inputs.dart';` to the page.

- In `test/profile/view/profile_page_test.dart`, delete `firstName: 'Josh',` and `lastName: 'Shew',` from the profile fixture (and any finder expecting the removed fields, if present).

- [ ] **Step 5: Run tests and analyze**

Run: `flutter test test/profile && flutter analyze lib/profile`
Expected: PASS; no analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add lib/profile test/profile
git commit -m "refactor: profile page drops name fields and gains inline username validation

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: Remove firstName/lastName from UserProfileModel + ARB labels

**Files:**
- Modify: `packages/firebase_database_repository/lib/models/user_profile_model.dart`
- Regenerate: `packages/firebase_database_repository/lib/models/user_profile_model.g.dart`
- Modify: `lib/l10n/arb/app_en.arb` (delete `firstNameLabel`/`lastNameLabel` + their `@` blocks, lines 899–906), `lib/l10n/arb/app_es.arb` (delete the two label lines)
- Regenerate: `lib/l10n/arb/app_localizations*.dart`

**Interfaces:**
- Produces: `UserProfileModel` without `firstName`/`lastName` (constructor, fields, `copyWith`, `props`). `isComplete` is untouched.

- [ ] **Step 1: Remove the model fields**

In `user_profile_model.dart` delete: constructor params `this.firstName,`/`this.lastName,`; the two field declarations with their doc comments (`/// First name of the user` etc.); the two `copyWith` params and assignments; the two `props` entries.

- [ ] **Step 2: Regenerate JSON codegen**

Run: `cd packages/firebase_database_repository && dart run build_runner build --delete-conflicting-outputs`
Expected: exits 0; `user_profile_model.g.dart` no longer mentions firstName/lastName.

- [ ] **Step 3: Remove the ARB labels and regenerate l10n**

Delete from `app_en.arb`:

```json
  "firstNameLabel": "First Name",
  "@firstNameLabel": {
    "description": "Label for the first name field on the profile page"
  },
  "lastNameLabel": "Last Name",
  "@lastNameLabel": {
    "description": "Label for the last name field on the profile page"
  },
```

Delete from `app_es.arb`:

```json
    "firstNameLabel": "Nombre",
    "lastNameLabel": "Apellido",
```

Run: `flutter gen-l10n --arb-dir="lib/l10n/arb"`

- [ ] **Step 4: Verify nothing references the fields anymore**

Run: `grep -rn "firstName\|lastName" lib packages test --include="*.dart" | grep -v app_localizations`
Expected: no output. (Then `grep -rn "firstName" lib/l10n` must also be empty after regen.)

- [ ] **Step 5: Run tests and analyze**

Run: `cd packages/firebase_database_repository && flutter test && cd ../.. && flutter test && flutter analyze lib packages/firebase_database_repository`
Expected: all PASS; no new analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add packages/firebase_database_repository lib/l10n
git commit -m "feat: drop firstName/lastName from the user profile model and localizations

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: Auth layer — remove User.name and the Apple fullName scope

**Files:**
- Modify: `packages/authentication_client/authentication_client/lib/src/models/user.dart`
- Modify: `packages/authentication_client/firebase_authentication_client/lib/src/firebase_authentication_client.dart`
- Test: `test/profile/bloc/profile_bloc_test.dart:18`, `test/profile/view/profile_page_test.dart:25`

**Interfaces:**
- Produces: `User` without `name` (field, constructor param, `copyWith`, `props`). Apple sign-in requests only the `email` scope.

- [ ] **Step 1: Remove the field from the User model**

In `user.dart` delete: `this.name,` from the constructor; the `/// The current user's name (display name).` field; `String? name,` + `name: name ?? this.name,` from `copyWith`; `name` from `props`.

- [ ] **Step 2: Update the Firebase client**

In `firebase_authentication_client.dart`:
- In the `toUser()` extension (line ~332), delete `name: displayName,`.
- In `logInWithApple()`, change the scopes list to request only email:

```dart
        scopes: [
          AppleIDAuthorizationScopes.email,
        ],
```

- [ ] **Step 3: Fix the fixtures**

`test/profile/bloc/profile_bloc_test.dart` and `test/profile/view/profile_page_test.dart`: change

```dart
  const authUser = User(id: 'u1', email: 'josh@example.com', name: 'Josh');
```

to

```dart
  const authUser = User(id: 'u1', email: 'josh@example.com');
```

(same change for the page test's `authUser`).

- [ ] **Step 4: Sweep for stragglers**

Run: `grep -rn "name:" lib test packages --include="*.dart" | grep -i "user(" ; grep -rn "\.name" packages/user_repository packages/authentication_client --include="*.dart" | grep -v "\.named\|Name"`
Expected: no `User(name: ...)` constructions and no `.name` reads on the auth user remain. Fix any hits by deleting the argument/read.

- [ ] **Step 5: Run tests and analyze**

Run: `cd packages/authentication_client/authentication_client && flutter test; cd ../firebase_authentication_client && flutter test; cd ../../.. && flutter test && flutter analyze`
Expected: PASS everywhere (package test suites may be small/empty — a "No tests" result is acceptable where none exist); analyzer clean apart from the known app_ui baseline.

- [ ] **Step 6: Commit**

```bash
git add packages/authentication_client test/profile
git commit -m "feat: stop collecting the provider display name; identity is username-only

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: Friendly friend-search error copy

**Files:**
- Modify: `lib/friends_list/search_user/search_user_page.dart` (the `SearchError` branch, lines ~163–171)
- Create: `test/friends_list/search_user/search_user_page_error_test.dart`

**Interfaces:**
- Consumes: `searchFailedMessage` (Task 2). `SearchError.message` keeps carrying the raw detail for logs/tests; only the rendering changes.

- [ ] **Step 1: Write the failing widget test**

Create `test/friends_list/search_user/search_user_page_error_test.dart` (mirrors the harness of `search_user_page_anonymous_test.dart`):

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/search_user/search_user_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/pump_app.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('SearchUserPage error state', () {
    late MockAppBloc appBloc;
    late MockFirebaseDatabaseRepository databaseRepository;

    setUp(() {
      appBloc = MockAppBloc();
      databaseRepository = MockFirebaseDatabaseRepository();
      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'alice')),
      );
    });

    testWidgets('renders localized copy, not the raw exception',
        (tester) async {
      when(() => databaseRepository.searchByUsername(any()))
          .thenThrow(Exception('boom'));

      await tester.pumpApp(
        MultiBlocProvider(
          providers: [BlocProvider<AppBloc>.value(value: appBloc)],
          child: RepositoryProvider<FirebaseDatabaseRepository>.value(
            value: databaseRepository,
            child: const SearchUserPage(),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'someone');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        find.text('Search failed. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('boom'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });
  });
}
```

(If `searchByUsername` needs the caller id — check its signature in the repository — adjust the stub to `searchByUsername(any(), any())` accordingly.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/friends_list/search_user/search_user_page_error_test.dart`
Expected: FAIL — the page currently renders `Error: Failed to search: Exception: boom`.

- [ ] **Step 3: Render localized copy**

In `search_user_page.dart`, replace the `SearchError` branch's text:

```dart
              } else if (state is SearchError) {
                return Center(
                  child: Text(
                    context.l10n.searchFailedMessage,
                    style: const TextStyle(
                      color: AppColors.red,
                    ),
                  ),
                );
              }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/friends_list`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/friends_list test/friends_list
git commit -m "fix: friend search failures show localized copy instead of raw exceptions

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: Full verification sweep

**Files:** none new — verification only, plus doc touch-ups if greps hit.

- [ ] **Step 1: Repo-wide leftovers grep**

Run: `grep -rniE "firstname|lastname|first name|last name" lib packages test docs/friends_feature_plan.md --include="*.dart" --include="*.md" | grep -v superpowers`
Expected: no code hits. If `docs/friends_feature_plan.md` mentions the identity fields, update that prose to username-only.

- [ ] **Step 2: Full analyze**

Run: `flutter analyze`
Expected: no NEW issues versus the known pre-existing `app_ui` gallery baseline.

- [ ] **Step 3: Full test suites**

Run: `flutter test` (root), then `flutter test` in `packages/form_inputs`, `packages/firebase_database_repository`, `packages/player_repository`, `packages/authentication_client/authentication_client`, `packages/authentication_client/firebase_authentication_client`, `packages/user_repository`.
Expected: all PASS.

- [ ] **Step 4: Commit any doc fixes**

```bash
git add docs
git commit -m "docs: friends feature README reflects username-only identity

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

(Skip if Step 1 found nothing to fix.)
