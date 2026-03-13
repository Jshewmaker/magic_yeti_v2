# Onboarding Flow — Design Spec

## Problem

The app has onboarding building blocks (bloc, form, routing) but the current implementation has gaps:

1. **Trigger is unreliable** — Uses `isNewUser` from Firebase auth, which is only true on the very first sign-in and can be lost across re-installs.
2. **No catch for existing users** — Users who signed up before the friends feature have no username, PIN, or friend code, but bypass onboarding entirely.
3. **Scattered profile setup** — PIN is prompted via a dialog on HomePage as a fallback; friend code is generated on-the-fly in `ensureFriendCode()`. There's no single, cohesive flow.
4. **No profile picture support** — The app falls back to first-letter avatars everywhere; there's no way for users to upload a photo.
5. **Single-page form** — Current onboarding dumps all fields on one page with no context for why each is needed.

## Approach

**Firestore-driven onboarding gate + multi-step wizard.** Replace the `isNewUser` auth flag with a Firestore `onboardingComplete` boolean as the single source of truth. Build a 4-step wizard that collects all required profile data with contextual explanations, uploads profile pictures to Firebase Storage, and only marks onboarding complete on final submit.

## Design

### 1. Onboarding Trigger — Firestore `onboardingComplete`

Replace `isNewUser` with a Firestore field on the user profile document.

**UserProfileModel** gains one new field:
- `onboardingComplete` — `bool`, defaults to `false`, set to `true` only on final onboarding submit

**AppBloc changes:**

`AppBloc` gains a new dependency: `FirebaseDatabaseRepository`. This must be injected via the constructor alongside the existing `UserRepository` and `AppConfigRepository` dependencies. The DI wiring in `main_development.dart`, `main_staging.dart`, and `main_production.dart` must be updated to pass it.

In `_onUserChanged`:
1. Receive `user` from auth stream (`user_repository.User`, which has `.id`, `.email`, `.name`, `.photo`, `.isNewUser`, `.isAnonymous`)
2. If user is authenticated (not anonymous), fetch Firestore profile via `getUserProfileOnce(user.id)` — a new repository method returning `Future<UserProfileModel?>`. Returns `null` if no document exists; throws on network error.
3. If fetch succeeds and profile is `null` or `profile.onboardingComplete != true`, emit `AppState.onboardingRequired(user)`
4. If fetch succeeds and `profile.onboardingComplete == true`, emit `AppState.authenticated(user)`
5. If fetch throws (network error), fall back to `AppState.authenticated(user)` — don't block existing users on transient failures. New users will simply see the home page and get caught on next app launch.
6. Stop checking `User.isNewUser` for routing decisions

To prevent race conditions from rapid user stream events (e.g., token refresh during fetch), the handler should cancel any in-flight Firestore fetch before starting a new one. Use a `CancelableOperation` or track a generation counter.

The existing router redirect (`AppStatus.onboardingRequired → /onboarding`) handles the rest automatically. No flash of home screen — the route guard fires before any UI renders.

### 2. Multi-Step Wizard Flow

Four steps with a horizontal progress indicator, Next/Back navigation, and contextual explanations on each page.

#### Step 1 — Identity (Username + Names)
- **Header:** "Choose Your Identity"
- **Explanation:** "Your username is how other players will find you. It's used for friend requests and game history."
- Username field (required, validated — same `Username` formz input as current)
- First name field (optional)
- Last name field (optional)
- Next button disabled until username is valid

#### Step 2 — PIN Setup
- **Header:** "Set Your PIN"
- **Explanation:** "Your 4-digit PIN protects your profile when sharing a device during games."
- 4-digit PIN field (required, validated — same `Pin` formz input as current)
- Next button disabled until PIN is exactly 4 digits

#### Step 3 — Profile Picture
- **Header:** "Add a Profile Picture"
- **Explanation:** "Help your friends recognize you. This is optional — you can always add one later in your profile."
- Circular image preview (shows first letter of username as placeholder when no image selected)
- "Choose from Gallery" button — opens image picker (gallery only, no camera)
- Shows local file preview after selection
- Skip button always visible
- Actual upload deferred to final submit

#### Step 4 — Bio
- **Header:** "Tell Us About Yourself"
- **Explanation:** "Share a bit about your play style or favorite formats. Other players can see this on your profile."
- Multi-line text field (optional, 3 lines)
- "Complete" button that triggers the full submit

**Progress indicator:** Horizontal step indicator at the top showing 4 segments/dots with the current step highlighted. Back button available on steps 2–4. Users cannot skip required fields (steps 1–2).

### 3. Architecture & Data Flow

#### OnboardingBloc Refactor

The bloc receives two constructor parameters: `FirebaseDatabaseRepository repository` and `UserProfileModel? existingProfile`. The `existingProfile` is the profile fetched during the AppBloc check (passed from the onboarding page's `BlocProvider` setup). If non-null, pre-fill fields from it. The `userId` comes from `AppBloc.state.user.id`, read in the onboarding page and passed to the bloc's `OnboardingSubmitted` event.

The bloc accumulates state across all steps and submits once at the end.

**State tracks:**
- `currentStep` — int (0–3), displayed in UI as step 1–4
- `username` — Username (formz validated)
- `pin` — Pin (formz validated)
- `firstName`, `lastName`, `bio` — String
- `profileImage` — XFile? (from `image_picker`, cross-platform; local file, not yet uploaded)
- `existingPinHash` — String? (if user already has a hashed PIN, pre-filled from existing profile)
- `status` — FormzSubmissionStatus
- `isStepValid` — computed getter, not a stored field. Returns `true` based on `currentStep`: step 0 requires `username.isValid`, step 1 requires `pin.isValid || existingPinHash != null` (PIN already set counts as valid), steps 2–3 always return true.

**Events** (all prefixed with `Onboarding` to match existing convention):
- Existing: `OnboardingUsernameChanged`, `OnboardingPinChanged`, `OnboardingFirstNameChanged`, `OnboardingLastNameChanged`, `OnboardingBioChanged`
- New: `OnboardingStepNext`, `OnboardingStepBack`, `OnboardingProfileImagePicked(XFile)`, `OnboardingSubmitted(String userId)`

**Pre-fill logic:** In the bloc constructor, if `existingProfile` is non-null:
- Set `username` to `Username.dirty(existingProfile.username ?? '')`
- Set `firstName`, `lastName`, `bio` from existing values
- Set `existingPinHash` to `existingProfile.pin` (the hashed value, used to skip PIN validation)
- Set `profileImage` to null (existing imageUrl is shown in the UI directly, not as an XFile)

**Submit flow** (on `OnboardingSubmitted` event):
1. If `profileImage` is not null, upload to Firebase Storage via `uploadProfilePicture(userId, xFile)` → get download URL
2. Generate friend code via `generateUniqueFriendCode()` (skip if existing profile already has one)
3. If `pin` field has a value (user entered a new PIN), hash it via `hashPin(pin)`. Otherwise, keep `existingPinHash`.
4. Call `updateUserProfile(userId, profile)` with all fields + `onboardingComplete: true`
5. On success, emit completed status
6. OnboardingPage's `BlocListener` detects success and dispatches `AppOnboardingCompleted` to AppBloc via `context.read<AppBloc>().add(AppOnboardingCompleted())`
7. AppBloc transitions to `authenticated`, router redirects to home

**Image upload is deferred to submit** — not during step 3. This prevents orphaned uploads if the user abandons onboarding. The Storage path `profile_pictures/{userId}.jpg` is deterministic, so retries after partial failure safely overwrite.

#### Repository Changes

**FirebaseDatabaseRepository:**
- Add `getUserProfileOnce(userId)` — returns `Future<UserProfileModel?>`. Single Firestore document fetch, not a stream. Used by AppBloc to check `onboardingComplete`.
- Add `uploadProfilePicture(userId, XFile)` — uploads image to Firebase Storage at `profile_pictures/{userId}.jpg`, returns download URL string. Uses `XFile` from `image_picker` for cross-platform compatibility (works on iOS, Android, Web, Windows).
- Existing `updateUserProfile(userId, profile)` handles the rest.

#### HomePage Cleanup

- Remove `ensureFriendCode()` method — onboarding now guarantees username, PIN, and friend code exist before the user reaches home.
- Remove the PIN setup dialog — PIN is always collected during onboarding.
- Keep a minimal safety net: if `onboardingComplete` is true but friend code is somehow missing, regenerate it silently.

### 4. Edge Cases & Error Handling

**Existing users without `onboardingComplete`:** On first launch after the update, AppBloc won't find the field in Firestore → routes to onboarding. The form pre-fills any existing data (username, PIN hash, name, etc.) so users don't re-enter what they already have. They confirm and complete.

**Pre-filling existing PIN:** Since PINs are stored hashed, we can't pre-fill the PIN field. If the user already has a hashed PIN in Firestore (`existingPinHash != null` in bloc state), step 2 shows "PIN already set" with the PIN field empty and a subtitle: "Enter a new 4-digit PIN to change it, or tap Next to keep your current one." The Next button is enabled (since `isStepValid` returns true when `existingPinHash` is set). If the user enters a new PIN (all 4 digits), that replaces the old hash on submit. If they clear the field and hit Next, the existing hash is preserved.

**Abandoned onboarding:** If the user kills the app mid-flow, nothing is saved. `onboardingComplete` remains false → they're routed back to onboarding on next launch. No orphaned data since image upload is deferred.

**Image picker failure:** If gallery access is denied or user cancels, stay on step 3 with no image. Skip option is always visible.

**Network failure on submit:** Show an error snackbar, keep user on step 4 with all data intact for retry. Don't clear form state.

**Username uniqueness:** Not enforced. Users are discovered by friend code, not username. Usernames are display-only.

### 5. UI Styling

Follow the existing app dark theme:
- Scaffold background: `AppColors.background`
- Input fields: filled with `AppColors.surface`, borders in `AppColors.neutral60`/`AppColors.tertiary`
- Headers: `AppColors.white`, bold
- Explanatory text: `AppColors.neutral60`
- Progress indicator: `AppColors.tertiary` for active/completed steps, `AppColors.neutral60` for inactive
- Buttons: `FilledButton` with `AppColors.tertiary` for primary actions, `TextButton` with `AppColors.neutral60` for Back/Skip

## Files to Modify

| File | Changes |
|------|---------|
| `packages/firebase_database_repository/lib/models/user_profile_model.dart` | Add `onboardingComplete` bool field, update `copyWith` and `props` |
| `packages/firebase_database_repository/lib/models/user_profile_model.g.dart` | Regenerate with `dart run build_runner build --delete-conflicting-outputs` |
| `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` | Add `getUserProfileOnce()`, `uploadProfilePicture(userId, XFile)` |
| `packages/firebase_database_repository/pubspec.yaml` | Add `firebase_storage` dependency (required, not currently present) |
| `lib/app/bloc/app_bloc.dart` | Add `FirebaseDatabaseRepository` constructor dependency, replace `isNewUser` check with Firestore `onboardingComplete` check, add race condition guard |
| `lib/main_development.dart` | Pass `FirebaseDatabaseRepository` to `AppBloc` |
| `lib/main_staging.dart` | Pass `FirebaseDatabaseRepository` to `AppBloc` |
| `lib/main_production.dart` | Pass `FirebaseDatabaseRepository` to `AppBloc` |
| `lib/onboarding/bloc/onboarding_bloc.dart` | Refactor for multi-step wizard: accept `existingProfile`, add step navigation, image picking, deferred upload |
| `lib/onboarding/bloc/onboarding_event.dart` | Add `OnboardingStepNext`, `OnboardingStepBack`, `OnboardingProfileImagePicked`, `OnboardingSubmitted(userId)` events |
| `lib/onboarding/bloc/onboarding_state.dart` | Add `currentStep`, `profileImage` (XFile), `existingPinHash`, `isStepValid` getter |
| `lib/onboarding/view/onboarding_form.dart` | Replace single form with 4-step wizard using PageView |
| `lib/home/home_page.dart` | Remove `ensureFriendCode()` and PIN dialog, add minimal friend code safety net |

## Platform Configuration

- **iOS:** Add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist` for gallery access
- **Android:** Add `READ_MEDIA_IMAGES` permission to `android/app/src/main/AndroidManifest.xml` (API 33+), or `READ_EXTERNAL_STORAGE` for older APIs

## Dependencies

- `image_picker` package — for gallery image selection (add to `pubspec.yaml` at root)
- `firebase_storage` — for profile picture upload (add to `packages/firebase_database_repository/pubspec.yaml`, not currently present)
- `cross_file` or use `image_picker`'s `XFile` directly — for cross-platform file handling (XFile is included with `image_picker`)

## Out of Scope

- Camera capture (gallery only)
- Preset avatar picker
- Username uniqueness enforcement
- Profile editing after onboarding (future feature)
- Animated transitions between steps (standard PageView is sufficient)
