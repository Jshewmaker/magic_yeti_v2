# Onboarding Flow Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-page onboarding form with a 4-step wizard gated by a Firestore `onboardingComplete` field, adding profile picture upload via Firebase Storage.

**Architecture:** Firestore `onboardingComplete` boolean replaces `isNewUser` as the onboarding gate. AppBloc fetches profile on auth to determine routing. OnboardingBloc accumulates state across 4 wizard steps and submits once at the end with deferred image upload.

**Tech Stack:** Flutter, BLoC, Cloud Firestore, Firebase Storage, GoRouter, image_picker, formz

**Spec:** `docs/superpowers/specs/2026-03-13-onboarding-flow-design.md`

---

## Chunk 1: Model & Repository Layer

### Task 1: Add `onboardingComplete` to UserProfileModel

**Files:**
- Modify: `packages/firebase_database_repository/lib/models/user_profile_model.dart`

- [ ] **Step 1: Add `onboardingComplete` field to UserProfileModel**

Add the field to the constructor (after `pin` on line 23), add the property declaration (after line 64), add to `copyWith` (after `pin` on line 81/94), and add to `props` (after `pin` on line 109):

```dart
// In constructor (line 12-24), add after pin:
    this.onboardingComplete = false,

// Property declaration (after line 64):
  /// Whether the user has completed the onboarding flow
  final bool onboardingComplete;

// In copyWith parameters (after line 81):
    bool? onboardingComplete,

// In copyWith body (after line 94):
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,

// In props (after line 109):
        onboardingComplete,
```

- [ ] **Step 2: Regenerate JSON serialization**

Run: `cd packages/firebase_database_repository && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze packages/firebase_database_repository/lib/models/`

- [ ] **Step 4: Commit**

```bash
git add packages/firebase_database_repository/lib/models/
git commit -m "feat: add onboardingComplete field to UserProfileModel"
```

---

### Task 2: Add `getUserProfileOnce` and `uploadProfilePicture` to repository

**Files:**
- Modify: `packages/firebase_database_repository/lib/src/firebase_database_repository.dart`
- Modify: `packages/firebase_database_repository/pubspec.yaml`

- [ ] **Step 1: Add `firebase_storage` and `image_picker` dependencies**

In `packages/firebase_database_repository/pubspec.yaml`, add under dependencies (after line 18 `crypto: ^3.0.3`):

```yaml
  firebase_storage: ^12.3.7
  image_picker: ^1.1.2
```

Run: `cd packages/firebase_database_repository && flutter pub get`

- [ ] **Step 2: Add `getUserProfileOnce` method**

Add this method to `FirebaseDatabaseRepository` (after the existing `getUserProfile` stream method around line 320):

```dart
  /// Get a user's profile as a one-shot Future.
  /// Returns null if the document does not exist.
  Future<UserProfileModel?> getUserProfileOnce(String userId) async {
    try {
      final doc = await _firebase.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfileModel.fromJson(doc.data()!);
    } on Exception catch (error, stackTrace) {
      throw GetUserProfileException(
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }
```

- [ ] **Step 3: Add `uploadProfilePicture` method**

Add this method after `getUserProfileOnce`. Uses `Uint8List` bytes for cross-platform compatibility (works on iOS, Android, Web, Windows — no `dart:io` dependency):

```dart
  /// Upload a profile picture to Firebase Storage.
  /// Accepts raw image bytes for cross-platform compatibility.
  /// Returns the download URL.
  Future<String> uploadProfilePicture(
    String userId,
    Uint8List imageBytes,
  ) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await storageRef.getDownloadURL();
    } on Exception catch (error, stackTrace) {
      throw UpdateUserProfileException(
        message: 'Failed to upload profile picture: $error',
        stackTrace: stackTrace,
      );
    }
  }
```

Add these imports at the top of the file:

```dart
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze packages/firebase_database_repository/`

- [ ] **Step 5: Commit**

```bash
git add packages/firebase_database_repository/
git commit -m "feat: add getUserProfileOnce and uploadProfilePicture to repository"
```

---

### Task 3: Add `image_picker` to root pubspec and platform permissions

**Files:**
- Modify: `pubspec.yaml` (root)
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add `image_picker` to root pubspec.yaml**

Add under dependencies (alphabetical order, near other packages):

```yaml
  image_picker: ^1.1.2
```

Run: `flutter pub get`

- [ ] **Step 2: Add iOS photo library permission**

In `ios/Runner/Info.plist`, add before the closing `</dict>`:

```xml
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Magic Yeti needs access to your photo library to set a profile picture.</string>
```

- [ ] **Step 3: Add Android photo permission**

In `android/app/src/main/AndroidManifest.xml`, add before the `<application` tag:

```xml
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "feat: add image_picker dependency and platform permissions"
```

---

## Chunk 2: AppBloc Onboarding Gate

### Task 4: Update AppBloc to check Firestore `onboardingComplete`

**Files:**
- Modify: `lib/app/bloc/app_bloc.dart`
- Modify: `lib/app/view/app.dart`

- [ ] **Step 1: Add FirebaseDatabaseRepository dependency to AppBloc**

In `lib/app/bloc/app_bloc.dart`, add the import (after line 9):

```dart
import 'package:firebase_database_repository/firebase_database_repository.dart';
```

Update the constructor (lines 16-27) to accept and store the repository:

```dart
class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required AppConfigRepository appConfigRepository,
    required UserRepository userRepository,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required User user,
  })  : _userRepository = userRepository,
        _firebaseDatabaseRepository = firebaseDatabaseRepository,
        super(
          user == User.unauthenticated
              ? const AppState.unauthenticated()
              : user.isAnonymous
                  ? AppState.anonymous(user)
                  : AppState.authenticated(user),
        ) {
```

Add the fields (after line 44):

```dart
  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  int _onboardingCheckGeneration = 0;
```

- [ ] **Step 2: Replace `_onUserChanged` with async Firestore check**

Replace the `_onUserChanged` method (lines 95-118) with:

```dart
  Future<void> _onUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    switch (state.status) {
      case AppStatus.forceUpgradeRequired:
        return emit(
          AppState.forceUpgradeRequired(state.forceUpgrade, event.user),
        );
      case AppStatus.downForMaintenance:
        return emit(AppState.downForMaintenance(event.user));
      case AppStatus.authenticated:
      case AppStatus.anonymous:
      case AppStatus.unauthenticated:
      case AppStatus.onboardingRequired:
        if (event.user == User.unauthenticated) {
          return emit(const AppState.unauthenticated());
        }
        if (event.user.isAnonymous) {
          return emit(AppState.anonymous(event.user));
        }
        // Guard against race conditions from rapid user stream events
        final generation = ++_onboardingCheckGeneration;
        // Check Firestore for onboarding completion
        try {
          final profile = await _firebaseDatabaseRepository
              .getUserProfileOnce(event.user.id);
          // Stale check — a newer event has arrived
          if (generation != _onboardingCheckGeneration) return;
          if (profile == null || !profile.onboardingComplete) {
            return emit(AppState.onboardingRequired(event.user));
          }
          return emit(AppState.authenticated(event.user));
        } catch (_) {
          if (generation != _onboardingCheckGeneration) return;
          // Network failure — don't block existing users
          return emit(AppState.authenticated(event.user));
        }
    }
  }
```

- [ ] **Step 3: Update App widget to pass repository to AppBloc**

In `lib/app/view/app.dart`, update the `BlocProvider` for `AppBloc` (lines 54-59) to pass the repository:

```dart
          BlocProvider(
            create: (_) => AppBloc(
              appConfigRepository: _appConfigRepository,
              userRepository: _userRepository,
              firebaseDatabaseRepository: _firebaseDatabaseRepository,
              user: _user,
            ),
          ),
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze lib/app/`

- [ ] **Step 5: Commit**

```bash
git add lib/app/
git commit -m "feat: AppBloc checks Firestore onboardingComplete instead of isNewUser"
```

---

## Chunk 3: OnboardingBloc Refactor

### Task 5: Refactor OnboardingState for multi-step wizard

**Files:**
- Modify: `lib/onboarding/bloc/onboarding_state.dart`

- [ ] **Step 1: Replace the entire OnboardingState**

Replace `lib/onboarding/bloc/onboarding_state.dart` with:

```dart
part of 'onboarding_bloc.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.currentStep = 0,
    this.username = const Username.pure(),
    this.pin = const Pin.pure(),
    this.firstName = '',
    this.lastName = '',
    this.bio = '',
    this.profileImagePath,
    this.existingPinHash,
    this.existingImageUrl,
    this.status = FormzSubmissionStatus.initial,
  });

  final int currentStep;
  final Username username;
  final Pin pin;
  final String firstName;
  final String lastName;
  final String bio;
  final String? profileImagePath;
  final String? existingPinHash;
  final String? existingImageUrl;
  final FormzSubmissionStatus status;

  /// Per-step validation.
  /// Step 0: username must be valid
  /// Step 1: PIN must be valid OR existing PIN hash exists
  /// Steps 2-3: always valid (optional fields)
  bool get isStepValid {
    switch (currentStep) {
      case 0:
        return username.isValid;
      case 1:
        return pin.isValid || existingPinHash != null;
      case 2:
      case 3:
        return true;
      default:
        return false;
    }
  }

  OnboardingState copyWith({
    int? currentStep,
    Username? username,
    Pin? pin,
    String? firstName,
    String? lastName,
    String? bio,
    String? Function()? profileImagePath,
    String? Function()? existingPinHash,
    String? Function()? existingImageUrl,
    FormzSubmissionStatus? status,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      username: username ?? this.username,
      pin: pin ?? this.pin,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      profileImagePath: profileImagePath != null
          ? profileImagePath()
          : this.profileImagePath,
      existingPinHash: existingPinHash != null
          ? existingPinHash()
          : this.existingPinHash,
      existingImageUrl: existingImageUrl != null
          ? existingImageUrl()
          : this.existingImageUrl,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        username,
        pin,
        firstName,
        lastName,
        bio,
        profileImagePath,
        existingPinHash,
        existingImageUrl,
        status,
      ];
}
```

Note: `profileImagePath`, `existingPinHash`, and `existingImageUrl` use `Function()?` pattern in `copyWith` to allow setting them to `null` explicitly.

- [ ] **Step 2: Verify it compiles (will have errors in bloc — expected)**

Run: `flutter analyze lib/onboarding/bloc/onboarding_state.dart`
Expected: May show errors from bloc referencing removed `isValid` — this is fixed in Task 6.

- [ ] **Step 3: Commit**

```bash
git add lib/onboarding/bloc/onboarding_state.dart
git commit -m "feat: refactor OnboardingState for multi-step wizard"
```

---

### Task 6: Refactor OnboardingEvent for multi-step wizard

**Files:**
- Modify: `lib/onboarding/bloc/onboarding_event.dart`

- [ ] **Step 1: Replace the entire OnboardingEvent file**

Replace `lib/onboarding/bloc/onboarding_event.dart` with:

```dart
part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingUsernameChanged extends OnboardingEvent {
  const OnboardingUsernameChanged(this.username);
  final String username;

  @override
  List<Object?> get props => [username];
}

class OnboardingPinChanged extends OnboardingEvent {
  const OnboardingPinChanged(this.pin);
  final String pin;

  @override
  List<Object?> get props => [pin];
}

class OnboardingFirstNameChanged extends OnboardingEvent {
  const OnboardingFirstNameChanged(this.firstName);
  final String firstName;

  @override
  List<Object?> get props => [firstName];
}

class OnboardingLastNameChanged extends OnboardingEvent {
  const OnboardingLastNameChanged(this.lastName);
  final String lastName;

  @override
  List<Object?> get props => [lastName];
}

class OnboardingBioChanged extends OnboardingEvent {
  const OnboardingBioChanged(this.bio);
  final String bio;

  @override
  List<Object?> get props => [bio];
}

class OnboardingStepNext extends OnboardingEvent {
  const OnboardingStepNext();
}

class OnboardingStepBack extends OnboardingEvent {
  const OnboardingStepBack();
}

class OnboardingProfileImagePicked extends OnboardingEvent {
  const OnboardingProfileImagePicked(this.imagePath);
  final String imagePath;

  @override
  List<Object?> get props => [imagePath];
}

class OnboardingSubmitted extends OnboardingEvent {
  const OnboardingSubmitted(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/onboarding/bloc/onboarding_event.dart
git commit -m "feat: refactor OnboardingEvent for multi-step wizard"
```

---

### Task 7: Refactor OnboardingBloc for multi-step wizard

**Files:**
- Modify: `lib/onboarding/bloc/onboarding_bloc.dart`

- [ ] **Step 1: Replace the entire OnboardingBloc**

Replace `lib/onboarding/bloc/onboarding_bloc.dart` with:

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:image_picker/image_picker.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    UserProfileModel? existingProfile,
  })  : _firebaseDatabaseRepository = firebaseDatabaseRepository,
        super(
          OnboardingState(
            username: existingProfile?.username != null &&
                    existingProfile!.username!.isNotEmpty
                ? Username.dirty(existingProfile.username!)
                : const Username.pure(),
            firstName: existingProfile?.firstName ?? '',
            lastName: existingProfile?.lastName ?? '',
            bio: existingProfile?.bio ?? '',
            existingPinHash: existingProfile?.pin,
            existingImageUrl: existingProfile?.imageUrl,
          ),
        ) {
    on<OnboardingUsernameChanged>(_onUsernameChanged);
    on<OnboardingPinChanged>(_onPinChanged);
    on<OnboardingFirstNameChanged>(_onFirstNameChanged);
    on<OnboardingLastNameChanged>(_onLastNameChanged);
    on<OnboardingBioChanged>(_onBioChanged);
    on<OnboardingStepNext>(_onStepNext);
    on<OnboardingStepBack>(_onStepBack);
    on<OnboardingProfileImagePicked>(_onProfileImagePicked);
    on<OnboardingSubmitted>(_onSubmitted);
  }

  final FirebaseDatabaseRepository _firebaseDatabaseRepository;

  void _onUsernameChanged(
    OnboardingUsernameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(username: Username.dirty(event.username)));
  }

  void _onPinChanged(
    OnboardingPinChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(pin: Pin.dirty(event.pin)));
  }

  void _onFirstNameChanged(
    OnboardingFirstNameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(firstName: event.firstName));
  }

  void _onLastNameChanged(
    OnboardingLastNameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(lastName: event.lastName));
  }

  void _onBioChanged(
    OnboardingBioChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(bio: event.bio));
  }

  void _onStepNext(
    OnboardingStepNext event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.isStepValid && state.currentStep < 3) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void _onStepBack(
    OnboardingStepBack event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void _onProfileImagePicked(
    OnboardingProfileImagePicked event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(profileImagePath: () => event.imagePath));
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      // Upload profile picture if selected
      String? imageUrl = state.existingImageUrl;
      if (state.profileImagePath != null) {
        final file = XFile(state.profileImagePath!);
        final bytes = await file.readAsBytes();
        imageUrl = await _firebaseDatabaseRepository.uploadProfilePicture(
          event.userId,
          bytes,
        );
      }

      // Generate friend code if not already present
      final existingProfile = await _firebaseDatabaseRepository
          .getUserProfileOnce(event.userId);
      final friendCode = existingProfile?.friendCode ??
          await _firebaseDatabaseRepository.generateUniqueFriendCode();

      // Hash PIN — use new PIN if entered, otherwise keep existing
      final pinHash = state.pin.value.isNotEmpty
          ? FirebaseDatabaseRepository.hashPin(state.pin.value)
          : state.existingPinHash ?? '';

      await _firebaseDatabaseRepository.updateUserProfile(
        event.userId,
        UserProfileModel(
          id: event.userId,
          email: existingProfile?.email,
          username: state.username.value,
          firstName: state.firstName,
          lastName: state.lastName,
          bio: state.bio,
          imageUrl: imageUrl,
          friendCode: friendCode,
          pin: pinHash,
          isNewUser: false,
          isAnonymous: false,
          onboardingComplete: true,
        ),
      );
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/onboarding/bloc/`

- [ ] **Step 3: Commit**

```bash
git add lib/onboarding/bloc/
git commit -m "feat: refactor OnboardingBloc for multi-step wizard with deferred image upload"
```

---

## Chunk 4: Onboarding UI — Multi-Step Wizard

### Task 8: Update OnboardingPage to pass existing profile

**Files:**
- Modify: `lib/onboarding/view/onboarding_page.dart`

- [ ] **Step 1: Replace OnboardingPage with profile-aware version**

Replace the entire file. Note: uses `StatefulWidget` to store the future in `initState` and avoid re-fetching on rebuilds:

```dart
import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/onboarding/onboarding.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  factory OnboardingPage.pageBuilder(_, __) {
    return const OnboardingPage(
      key: Key('onboarding_page'),
    );
  }

  static const routeName = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final Future<UserProfileModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context
        .read<FirebaseDatabaseRepository>()
        .getUserProfileOnce(
          context.read<AppBloc>().state.user.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<UserProfileModel?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return BlocProvider(
              create: (context) => OnboardingBloc(
                firebaseDatabaseRepository:
                    context.read<FirebaseDatabaseRepository>(),
                existingProfile: snapshot.data,
              ),
              child: const OnboardingForm(),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/onboarding/view/onboarding_page.dart
git commit -m "feat: OnboardingPage fetches existing profile for pre-fill"
```

---

### Task 9: Build the 4-step wizard OnboardingForm

**Files:**
- Modify: `lib/onboarding/view/onboarding_form.dart`

- [ ] **Step 1: Replace the entire OnboardingForm with multi-step wizard**

Replace `lib/onboarding/view/onboarding_form.dart` with:

```dart
import 'dart:typed_data';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/onboarding/onboarding.dart';

class OnboardingForm extends StatefulWidget {
  const OnboardingForm({super.key});

  @override
  State<OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends State<OnboardingForm> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep ||
          previous.status != current.status,
      listener: (context, state) {
        // Animate page transitions
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            state.currentStep,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        // Handle submission result
        if (state.status.isSuccess) {
          context.read<AppBloc>().add(const AppOnboardingCompleted());
        } else if (state.status.isFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to save profile. Please try again.',
                ),
                backgroundColor: AppColors.red,
              ),
            );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Progress indicator
            _StepIndicator(currentStep: state.currentStep),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _IdentityStep(),
                  _PinStep(),
                  _ProfilePictureStep(),
                  _BioStep(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? AppColors.tertiary
                    : AppColors.neutral60,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Step 1: Identity (Username + Names)
// Uses StatefulWidget to own TextEditingControllers with proper lifecycle.
class _IdentityStep extends StatefulWidget {
  const _IdentityStep();

  @override
  State<_IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends State<_IdentityStep> {
  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    _usernameController = TextEditingController(text: state.username.value);
    _firstNameController = TextEditingController(text: state.firstName);
    _lastNameController = TextEditingController(text: state.lastName);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      header: 'Choose Your Identity',
      explanation: 'Your username is how other players will find you. '
          "It's used for friend requests and game history.",
      showBack: false,
      child: Column(
        children: [
          BlocBuilder<OnboardingBloc, OnboardingState>(
            buildWhen: (previous, current) =>
                previous.username != current.username,
            builder: (context, state) {
              return TextField(
                key: const Key('onboarding_username_input'),
                controller: _usernameController,
                onChanged: (value) => context
                    .read<OnboardingBloc>()
                    .add(OnboardingUsernameChanged(value)),
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Username *',
                  labelStyle: const TextStyle(color: AppColors.neutral60),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neutral60),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.tertiary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),
                  errorText: state.username.displayError != null
                      ? 'Username is required'
                      : null,
                  errorStyle: const TextStyle(color: AppColors.red),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('onboarding_firstName_input'),
            controller: _firstNameController,
            onChanged: (value) => context
                .read<OnboardingBloc>()
                .add(OnboardingFirstNameChanged(value)),
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'First Name (Optional)',
              labelStyle: const TextStyle(color: AppColors.neutral60),
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.tertiary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('onboarding_lastName_input'),
            controller: _lastNameController,
            onChanged: (value) => context
                .read<OnboardingBloc>()
                .add(OnboardingLastNameChanged(value)),
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Last Name (Optional)',
              labelStyle: const TextStyle(color: AppColors.neutral60),
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.tertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 2: PIN Setup
class _PinStep extends StatelessWidget {
  const _PinStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.pin != current.pin ||
          previous.existingPinHash != current.existingPinHash,
      builder: (context, state) {
        final hasExistingPin = state.existingPinHash != null;
        return _StepLayout(
          header: 'Set Your PIN',
          explanation: hasExistingPin
              ? 'Your PIN is already set. Enter a new 4-digit PIN '
                  'to change it, or tap Next to keep your current one.'
              : 'Your 4-digit PIN protects your profile when sharing '
                  'a device during games.',
          child: TextField(
            key: const Key('onboarding_pin_input'),
            onChanged: (value) => context
                .read<OnboardingBloc>()
                .add(OnboardingPinChanged(value)),
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              color: AppColors.white,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.tertiary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red),
              ),
              errorText: !hasExistingPin && state.pin.displayError != null
                  ? 'PIN must be exactly 4 digits'
                  : null,
              errorStyle: const TextStyle(color: AppColors.red),
            ),
          ),
        );
      },
    );
  }
}

// Step 3: Profile Picture
// Uses FutureBuilder to load image bytes for cross-platform preview.
class _ProfilePictureStep extends StatelessWidget {
  const _ProfilePictureStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.profileImagePath != current.profileImagePath ||
          previous.existingImageUrl != current.existingImageUrl ||
          previous.username != current.username,
      builder: (context, state) {
        final hasImage = state.profileImagePath != null ||
            (state.existingImageUrl != null &&
                state.existingImageUrl!.isNotEmpty);
        return _StepLayout(
          header: 'Add a Profile Picture',
          explanation:
              'Help your friends recognize you. This is optional — '
              'you can always add one later in your profile.',
          buttonText: hasImage ? 'Next' : 'Next',
          child: Column(
            children: [
              const SizedBox(height: 24),
              _ProfileImagePreview(
                imagePath: state.profileImagePath,
                existingImageUrl: state.existingImageUrl,
                initial: state.username.value.isNotEmpty
                    ? state.username.value[0].toUpperCase()
                    : '?',
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 80,
                  );
                  if (image != null && context.mounted) {
                    context.read<OnboardingBloc>().add(
                          OnboardingProfileImagePicked(image.path),
                        );
                  }
                },
                icon: const Icon(
                  Icons.photo_library,
                  color: AppColors.tertiary,
                ),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: AppColors.tertiary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.tertiary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              if (!hasImage) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context
                      .read<OnboardingBloc>()
                      .add(const OnboardingStepNext()),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.neutral60),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProfileImagePreview extends StatelessWidget {
  const _ProfileImagePreview({
    required this.initial,
    this.imagePath,
    this.existingImageUrl,
  });

  final String? imagePath;
  final String? existingImageUrl;
  final String initial;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      // Use XFile.readAsBytes for cross-platform image loading
      return FutureBuilder<Uint8List>(
        future: XFile(imagePath!).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 64,
              backgroundColor: AppColors.tertiary,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }
          return _placeholder();
        },
      );
    }
    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 64,
        backgroundColor: AppColors.tertiary,
        backgroundImage: NetworkImage(existingImageUrl!),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return CircleAvatar(
      radius: 64,
      backgroundColor: AppColors.tertiary,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
    );
  }
}

// Step 4: Bio
class _BioStep extends StatelessWidget {
  const _BioStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return _StepLayout(
          header: 'Tell Us About Yourself',
          explanation:
              'Share a bit about your play style or favorite formats. '
              'Other players can see this on your profile.',
          buttonText: 'Complete',
          isSubmit: true,
          isLoading: state.status.isInProgress,
          child: _OptionalTextField(
            key: const Key('onboarding_bio_input'),
            label: 'Bio (Optional)',
            initialValue: context.read<OnboardingBloc>().state.bio,
            maxLines: 3,
            onChanged: (value) => context
                .read<OnboardingBloc>()
                .add(OnboardingBioChanged(value)),
          ),
        );
      },
    );
  }
}

// Shared step layout with header, explanation, content, and nav buttons
class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.header,
    required this.explanation,
    required this.child,
    this.showBack = true,
    this.buttonText = 'Next',
    this.isSubmit = false,
    this.isLoading = false,
  });

  final String header;
  final String explanation;
  final Widget child;
  final bool showBack;
  final String buttonText;
  final bool isSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            header,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral60,
            ),
          ),
          const SizedBox(height: 32),
          child,
          const Spacer(),
          Row(
            children: [
              if (showBack)
                Expanded(
                  child: TextButton(
                    onPressed: () => context
                        .read<OnboardingBloc>()
                        .add(const OnboardingStepBack()),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: AppColors.neutral60),
                    ),
                  ),
                ),
              if (showBack) const SizedBox(width: 16),
              Expanded(
                flex: showBack ? 2 : 1,
                child: BlocBuilder<OnboardingBloc, OnboardingState>(
                  buildWhen: (previous, current) =>
                      previous.isStepValid != current.isStepValid ||
                      previous.status != current.status,
                  builder: (context, state) {
                    return FilledButton(
                      onPressed: state.isStepValid && !isLoading
                          ? () {
                              if (isSubmit) {
                                final userId = context
                                    .read<AppBloc>()
                                    .state
                                    .user
                                    .id;
                                context.read<OnboardingBloc>().add(
                                      OnboardingSubmitted(userId),
                                    );
                              } else {
                                context.read<OnboardingBloc>().add(
                                      const OnboardingStepNext(),
                                    );
                              }
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.tertiary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(buttonText),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Reusable optional text field with dark theme
class _OptionalTextField extends StatelessWidget {
  const _OptionalTextField({
    required this.label,
    required this.onChanged,
    super.key,
    this.initialValue = '',
    this.maxLines = 1,
  });

  final String label;
  final String initialValue;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.neutral60),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutral60),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.tertiary),
        ),
      ),
    );
  }
}

```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/onboarding/`

- [ ] **Step 3: Commit**

```bash
git add lib/onboarding/
git commit -m "feat: multi-step onboarding wizard with 4 steps and dark theme"
```

---

## Chunk 5: HomePage Cleanup and Final Verification

### Task 10: Remove ensureFriendCode and PIN dialog from HomePage

**Files:**
- Modify: `lib/home/home_page.dart`

- [ ] **Step 1: Remove `_ensureFriendCode` and `_showPinSetupDialog` methods**

In `lib/home/home_page.dart`:

1. Find and delete the `_ensureFriendCode` method (the entire method body from `Future<void> _ensureFriendCode()` to its closing brace).
2. Find and delete the entire `_showPinSetupDialog` method (from `void _showPinSetupDialog()` to its closing brace, including the `.then((_) => pinController.dispose())` line).
3. Replace the `initState` override to call a minimal safety net instead:

```dart
  @override
  void initState() {
    super.initState();
    unawaited(_ensureFriendCodeSafetyNet());
  }

  /// Minimal safety net: if onboarding was completed but friend code
  /// is somehow missing, regenerate it silently.
  Future<void> _ensureFriendCodeSafetyNet() async {
    final appState = context.read<AppBloc>().state;
    if (appState.status != AppStatus.authenticated) return;

    final db = context.read<FirebaseDatabaseRepository>();
    final user = appState.user;

    final profile = await db.getUserProfileOnce(user.id);
    if (!mounted) return;

    if (profile != null && profile.friendCode == null) {
      final friendCode = await db.generateUniqueFriendCode();
      if (!mounted) return;
      await db.updateUserProfile(
        user.id,
        profile.copyWith(friendCode: friendCode),
      );
    }
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/home/home_page.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/home/home_page.dart
git commit -m "fix: replace ensureFriendCode and PIN dialog with minimal safety net"
```

---

### Task 11: Full integration verification

- [ ] **Step 1: Run full analysis**

Run: `flutter analyze`

Fix any new warnings or errors introduced by the onboarding changes. Pre-existing warnings (like `_, __` factory patterns) can be ignored.

- [ ] **Step 2: Manual test checklist**

1. Fresh sign-up → should route to onboarding wizard (not home)
2. Step 1: Enter username → Next button enables. First/last name optional.
3. Step 2: Enter 4-digit PIN → Next button enables.
4. Step 3: Pick image from gallery → shows preview. Skip works.
5. Step 4: Enter bio (optional) → Complete button submits.
6. After submit → routes to home page automatically.
7. Kill app, relaunch → should go straight to home (onboardingComplete = true).
8. Existing user without onboardingComplete → routes to onboarding with pre-filled data.
9. Existing user with PIN → Step 2 shows "PIN already set", Next enabled without entering new PIN.
10. Network failure on submit → error snackbar, data preserved, can retry.
11. Back button works on steps 2-4.
12. Progress indicator updates correctly across all 4 steps.
