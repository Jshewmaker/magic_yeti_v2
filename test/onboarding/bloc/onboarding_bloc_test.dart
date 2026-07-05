import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:magic_yeti/onboarding/bloc/onboarding_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  late _MockFirebaseDatabaseRepository firebaseDatabaseRepository;

  OnboardingBloc buildBloc({UserProfileModel? existingProfile}) =>
      OnboardingBloc(
        firebaseDatabaseRepository: firebaseDatabaseRepository,
        existingProfile: existingProfile,
      );

  setUpAll(() {
    registerFallbackValue(const UserProfileModel(id: 'fallback'));
  });

  setUp(() {
    firebaseDatabaseRepository = _MockFirebaseDatabaseRepository();
  });

  group('PIN handling', () {
    test('empty legacy pin string does NOT count as an existing PIN', () {
      final bloc = OnboardingBloc(
        firebaseDatabaseRepository: firebaseDatabaseRepository,
        existingProfile: const UserProfileModel(id: 'u1', pin: ''),
      );
      expect(bloc.state.hasExistingPin, isFalse);
      addTearDown(bloc.close);
    });

    test('hasPin flag counts as an existing PIN', () {
      final bloc = OnboardingBloc(
        firebaseDatabaseRepository: firebaseDatabaseRepository,
        existingProfile: const UserProfileModel(id: 'u1', hasPin: true),
      );
      expect(bloc.state.hasExistingPin, isTrue);
      addTearDown(bloc.close);
    });

    blocTest<OnboardingBloc, OnboardingState>(
      'submit with a new PIN calls setPin and writes hasPin without pin',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenAnswer((_) async => null);
        when(() => firebaseDatabaseRepository.generateUniqueFriendCode())
            .thenAnswer((_) async => 'YETI-A3F9');
        when(() => firebaseDatabaseRepository.setPin('u1', '0742'))
            .thenAnswer((_) async {});
        when(
          () => firebaseDatabaseRepository.updateUserProfile(
            'u1',
            any(),
          ),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const OnboardingState(
        username: Username.dirty('josh'),
        pin: Pin.dirty('0742'),
      ),
      act: (bloc) => bloc.add(const OnboardingSubmitted('u1')),
      verify: (_) {
        verify(() => firebaseDatabaseRepository.setPin('u1', '0742'))
            .called(1);
        final profile = verify(
          () => firebaseDatabaseRepository.updateUserProfile(
            'u1',
            captureAny(),
          ),
        ).captured.single as UserProfileModel;
        expect(profile.hasPin, isTrue);
        expect(profile.pin, isNull);
        expect(profile.onboardingComplete, isTrue);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'submit with an untouched pin and an existing PIN keeps hasPin true '
      'without calling setPin',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenAnswer(
          (_) async => const UserProfileModel(id: 'u1', hasPin: true),
        );
        when(() => firebaseDatabaseRepository.generateUniqueFriendCode())
            .thenAnswer((_) async => 'YETI-A3F9');
        when(
          () => firebaseDatabaseRepository.updateUserProfile(
            'u1',
            any(),
          ),
        ).thenAnswer((_) async {});
        return buildBloc(
          existingProfile: const UserProfileModel(id: 'u1', hasPin: true),
        );
      },
      seed: () => const OnboardingState(
        username: Username.dirty('josh'),
        hasExistingPin: true,
      ),
      act: (bloc) => bloc.add(const OnboardingSubmitted('u1')),
      verify: (_) {
        verifyNever(() => firebaseDatabaseRepository.setPin(any(), any()));
        final profile = verify(
          () => firebaseDatabaseRepository.updateUserProfile(
            'u1',
            captureAny(),
          ),
        ).captured.single as UserProfileModel;
        expect(profile.hasPin, isTrue);
        expect(profile.pin, isNull);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'submit fails without saving the profile when setPin throws '
      '(pins the setPin-before-save ordering)',
      build: () {
        when(() => firebaseDatabaseRepository.getUserProfileOnce('u1'))
            .thenAnswer((_) async => null);
        when(() => firebaseDatabaseRepository.generateUniqueFriendCode())
            .thenAnswer((_) async => 'YETI-A3F9');
        when(() => firebaseDatabaseRepository.setPin('u1', '0742'))
            .thenThrow(Exception('boom'));
        when(
          () => firebaseDatabaseRepository.updateUserProfile(
            'u1',
            any(),
          ),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const OnboardingState(
        username: Username.dirty('josh'),
        pin: Pin.dirty('0742'),
      ),
      act: (bloc) => bloc.add(const OnboardingSubmitted('u1')),
      expect: () => [
        isA<OnboardingState>().having(
          (s) => s.status,
          'status',
          FormzSubmissionStatus.inProgress,
        ),
        isA<OnboardingState>().having(
          (s) => s.status,
          'status',
          FormzSubmissionStatus.failure,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => firebaseDatabaseRepository.updateUserProfile(any(), any()),
        );
      },
    );
  });
}
