import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:magic_yeti/profile/bloc/profile_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockFirebaseDatabaseRepository firebaseDatabaseRepository;
  late _MockUserRepository userRepository;

  const authUser = User(id: 'u1', email: 'josh@example.com', name: 'Josh');

  const loadedProfile = UserProfileModel(
    id: 'u1',
    email: 'josh@example.com',
    username: 'josh',
    firstName: 'Josh',
    lastName: 'Shew',
    bio: 'hello',
    friendCode: 'YETI-A3F9',
    pin: 'legacyhash',
    hasPin: true,
    onboardingComplete: true,
  );

  ProfileBloc buildBloc() => ProfileBloc(
        firebaseDatabaseRepository: firebaseDatabaseRepository,
        userRepository: userRepository,
        userProfile: authUser,
      );

  setUpAll(() {
    registerFallbackValue(const UserProfileModel(id: 'fallback'));
  });

  setUp(() {
    firebaseDatabaseRepository = _MockFirebaseDatabaseRepository();
    userRepository = _MockUserRepository();
  });

  group('ProfileLoadRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'loads the profile and emits loaded status',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenAnswer((_) async => loadedProfile);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested('u1')),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>()
            .having((s) => s.status, 'status', ProfileStatus.loaded)
            .having((s) => s.profile, 'profile', loadedProfile),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits failure when the load throws',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenThrow(Exception('boom'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested('u1')),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.failure,
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'a missing profile doc emits failure, not an empty loaded state',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenAnswer((_) async => null);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoadRequested('u1')),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.failure,
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'submit before load completes is a no-op (race guard)',
      build: buildBloc,
      act: (bloc) => bloc.add(const ProfileSubmitted()),
      expect: () => <ProfileState>[],
      verify: (_) {
        verifyNever(
          () => firebaseDatabaseRepository.updateUserProfile(any(), any()),
        );
      },
    );
  });

  group('ProfileSubmitted', () {
    blocTest<ProfileBloc, ProfileState>(
      'builds the save model from the loaded profile via copyWith so '
      'pin/hasPin/friendCode/onboardingComplete/imageUrl are preserved '
      '(Fix-2-class regression guard)',
      build: () {
        when(
          () => firebaseDatabaseRepository.updateUserProfile(
            'u1',
            any(),
          ),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const ProfileState(
        user: authUser,
        status: ProfileStatus.loaded,
        profile: loadedProfile,
        isEditing: true,
        username: Username.dirty('newname'),
        firstName: 'NewFirst',
        lastName: 'NewLast',
        bio: 'new bio',
      ),
      act: (bloc) => bloc.add(const ProfileSubmitted()),
      verify: (_) {
        final saved = verify(
          () => firebaseDatabaseRepository.updateUserProfile(
            'u1',
            captureAny(),
          ),
        ).captured.single as UserProfileModel;

        // Fields explicitly changed by the form.
        expect(saved.username, 'newname');
        expect(saved.firstName, 'NewFirst');
        expect(saved.lastName, 'NewLast');
        expect(saved.bio, 'new bio');

        // Fields NOT touched by the profile form must carry over from
        // the loaded profile untouched.
        expect(saved.pin, loadedProfile.pin);
        expect(saved.hasPin, loadedProfile.hasPin);
        expect(saved.friendCode, loadedProfile.friendCode);
        expect(saved.onboardingComplete, loadedProfile.onboardingComplete);
        expect(saved.imageUrl, loadedProfile.imageUrl);
        expect(saved.email, loadedProfile.email);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'flips isEditing off and refreshes the loaded profile on success',
      build: () {
        when(
          () => firebaseDatabaseRepository.updateUserProfile('u1', any()),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const ProfileState(
        user: authUser,
        status: ProfileStatus.loaded,
        profile: loadedProfile,
        isEditing: true,
        username: Username.dirty('newname'),
      ),
      act: (bloc) => bloc.add(const ProfileSubmitted()),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>()
            .having((s) => s.status, 'status', ProfileStatus.success)
            .having((s) => s.isEditing, 'isEditing', isFalse)
            .having(
              (s) => s.profile?.username,
              'profile.username',
              'newname',
            ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits failure and does not save when the edited username is '
      'present but invalid (e.g. cleared to empty) — an empty username '
      'would flip UserProfileModel.isComplete false and bounce the user '
      'to onboarding on the next auth event',
      build: buildBloc,
      seed: () => const ProfileState(
        user: authUser,
        status: ProfileStatus.loaded,
        profile: loadedProfile,
        isEditing: true,
        username: Username.dirty(),
      ),
      act: (bloc) => bloc.add(const ProfileSubmitted()),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.failure,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => firebaseDatabaseRepository.updateUserProfile(any(), any()),
        );
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits failure when updateUserProfile throws',
      build: () {
        when(
          () => firebaseDatabaseRepository.updateUserProfile('u1', any()),
        ).thenThrow(Exception('boom'));
        return buildBloc();
      },
      seed: () => const ProfileState(
        user: authUser,
        status: ProfileStatus.loaded,
        profile: loadedProfile,
        isEditing: true,
      ),
      act: (bloc) => bloc.add(const ProfileSubmitted()),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.failure,
        ),
      ],
    );
  });

  group('ProfilePinChanged / ProfilePinSubmitted', () {
    blocTest<ProfileBloc, ProfileState>(
      'ProfilePinChanged updates the Pin formz input',
      build: buildBloc,
      seed: () => const ProfileState(
        user: authUser,
        status: ProfileStatus.loaded,
        profile: loadedProfile,
      ),
      act: (bloc) => bloc.add(const ProfilePinChanged('1234')),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.pin,
          'pin',
          const Pin.dirty('1234'),
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'ProfilePinSubmitted calls setPin with the entered pin and emits '
      'pinSaved on success (no old-PIN prompt required — decision #5)',
      build: () {
        when(() => firebaseDatabaseRepository.setPin('u1', '4321'))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const ProfileState(
        user: authUser,
        status: ProfileStatus.loaded,
        profile: loadedProfile,
        pin: Pin.dirty('4321'),
      ),
      act: (bloc) => bloc.add(const ProfilePinSubmitted()),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.pinSaved,
        ),
      ],
      verify: (_) {
        verify(() => firebaseDatabaseRepository.setPin('u1', '4321'))
            .called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'ProfilePinSubmitted emits failure when setPin throws',
      build: () {
        when(() => firebaseDatabaseRepository.setPin('u1', '4321'))
            .thenThrow(Exception('boom'));
        return buildBloc();
      },
      seed: () => const ProfileState(
        user: authUser,
        status: ProfileStatus.loaded,
        profile: loadedProfile,
        pin: Pin.dirty('4321'),
      ),
      act: (bloc) => bloc.add(const ProfilePinSubmitted()),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.failure,
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'ProfilePinSubmitted does not call setPin when the pin is invalid',
      build: buildBloc,
      seed: () => const ProfileState(
        user: authUser,
        status: ProfileStatus.loaded,
        profile: loadedProfile,
        pin: Pin.dirty('12'),
      ),
      act: (bloc) => bloc.add(const ProfilePinSubmitted()),
      expect: () => <ProfileState>[],
      verify: (_) {
        verifyNever(() => firebaseDatabaseRepository.setPin(any(), any()));
      },
    );
  });

  group('ProfileDeleted', () {
    blocTest<ProfileBloc, ProfileState>(
      'calls deleteAccount and emits success',
      build: () {
        when(() => userRepository.deleteAccount()).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileDeleted()),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => userRepository.deleteAccount()).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits failure when deleteAccount throws',
      build: () {
        when(() => userRepository.deleteAccount())
            .thenThrow(Exception('boom'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileDeleted()),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.loading,
        ),
        isA<ProfileState>().having(
          (s) => s.status,
          'status',
          ProfileStatus.failure,
        ),
      ],
    );
  });
}
