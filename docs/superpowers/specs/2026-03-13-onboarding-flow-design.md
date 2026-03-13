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

**AppBloc changes** in `_onUserChanged`:
1. Receive user from auth stream
2. If user is authenticated (not anonymous), fetch Firestore profile via `getUserProfileOnce(userId)` (new repository method — single Future, not a stream)
3. If profile is missing or `onboardingComplete != true`, emit `AppState.onboardingRequired`
4. If `onboardingComplete == true`, emit `AppState.authenticated`
5. Stop checking `User.isNewUser` for routing decisions

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

The bloc accumulates state across all steps and submits once at the end.

**State tracks:**
- `currentStep` — int (0–3)
- `username` — Username (formz validated)
- `pin` — Pin (formz validated)
- `firstName`, `lastName`, `bio` — String
- `profileImage` — File? (local file, not yet uploaded)
- `status` — FormzSubmissionStatus
- `isValid` — per-step validation (step 0: username valid, step 1: PIN valid, steps 2–3: always valid)

**Events:**
- Existing: `UsernameChanged`, `PinChanged`, `FirstNameChanged`, `LastNameChanged`, `BioChanged`
- New: `OnboardingStepNext`, `OnboardingStepBack`, `ProfileImagePicked(File)`, `Submitted`

**Submit flow** (on `Submitted` event):
1. If `profileImage` is not null, upload to Firebase Storage via `uploadProfilePicture(userId, file)` → get download URL
2. Generate friend code via `generateUniqueFriendCode()`
3. Hash PIN via `hashPin(pin)`
4. Call `updateUserProfile(userId, profile)` with all fields + `onboardingComplete: true`
5. On success, emit completed status
6. OnboardingPage dispatches `AppOnboardingCompleted` to AppBloc

**Image upload is deferred to submit** — not during step 3. This prevents orphaned uploads if the user abandons onboarding.

#### Repository Changes

**FirebaseDatabaseRepository:**
- Add `getUserProfileOnce(userId)` — returns `Future<UserProfileModel?>`. Single Firestore document fetch, not a stream. Used by AppBloc to check `onboardingComplete`.
- Add `uploadProfilePicture(userId, File)` — uploads image to Firebase Storage at `profile_pictures/{userId}.jpg`, returns download URL string.
- Existing `updateUserProfile(userId, profile)` handles the rest.

#### HomePage Cleanup

- Remove `ensureFriendCode()` method — onboarding now guarantees username, PIN, and friend code exist before the user reaches home.
- Remove the PIN setup dialog — PIN is always collected during onboarding.
- Keep a minimal safety net: if `onboardingComplete` is true but friend code is somehow missing, regenerate it silently.

### 4. Edge Cases & Error Handling

**Existing users without `onboardingComplete`:** On first launch after the update, AppBloc won't find the field in Firestore → routes to onboarding. The form pre-fills any existing data (username, PIN hash, name, etc.) so users don't re-enter what they already have. They confirm and complete.

**Pre-filling existing PIN:** Since PINs are stored hashed, we can't pre-fill the PIN field. If the user already has a hashed PIN in Firestore, skip PIN validation on step 2 (show a message like "PIN already set" with option to change it). Only hash and overwrite if the user enters a new one.

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
| `packages/firebase_database_repository/lib/models/user_profile_model.dart` | Add `onboardingComplete` bool field |
| `packages/firebase_database_repository/lib/models/user_profile_model.g.dart` | Regenerate with build_runner |
| `packages/firebase_database_repository/lib/src/firebase_database_repository.dart` | Add `getUserProfileOnce()`, `uploadProfilePicture()` |
| `packages/firebase_database_repository/pubspec.yaml` | Add `firebase_storage` dependency (if not present) |
| `lib/app/bloc/app_bloc.dart` | Replace `isNewUser` check with Firestore `onboardingComplete` check |
| `lib/onboarding/bloc/onboarding_bloc.dart` | Refactor for multi-step wizard: add step navigation, image picking, deferred upload |
| `lib/onboarding/bloc/onboarding_event.dart` | Add `OnboardingStepNext`, `OnboardingStepBack`, `ProfileImagePicked` events |
| `lib/onboarding/bloc/onboarding_state.dart` | Add `currentStep`, `profileImage` fields, per-step validation |
| `lib/onboarding/view/onboarding_form.dart` | Replace single form with 4-step wizard using PageView |
| `lib/home/home_page.dart` | Remove `ensureFriendCode()` and PIN dialog, add minimal friend code safety net |

## Dependencies

- `image_picker` package — for gallery image selection
- `firebase_storage` — for profile picture upload (may already be a transitive dependency)

## Out of Scope

- Camera capture (gallery only)
- Preset avatar picker
- Username uniqueness enforcement
- Profile editing after onboarding (future feature)
- Animated transitions between steps (standard PageView is sufficient)
