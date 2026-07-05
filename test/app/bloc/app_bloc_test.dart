import 'package:app_config_repository/app_config_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

class _MockAppConfigRepository extends Mock implements AppConfigRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('AppBloc', () {
    late AppConfigRepository appConfigRepository;
    late UserRepository userRepository;
    late FirebaseDatabaseRepository firebaseDatabaseRepository;

    setUp(() {
      appConfigRepository = _MockAppConfigRepository();
      userRepository = _MockUserRepository();
      firebaseDatabaseRepository = _MockFirebaseDatabaseRepository();

      // Stub user stream to return empty
      when(() => userRepository.user).thenAnswer(
        (_) => const Stream.empty(),
      );

      // Stub app config streams to return empty
      when(() => appConfigRepository.isForceUpgradeRequired()).thenAnswer(
        (_) => const Stream.empty(),
      );
      when(() => appConfigRepository.isDownForMaintenance()).thenAnswer(
        (_) => const Stream.empty(),
      );

      // Default stub for migrateLegacyPin to avoid errors in existing tests
      when(() => firebaseDatabaseRepository.migrateLegacyPin(any()))
          .thenAnswer((_) async {});
    });

    AppBloc buildBloc() => AppBloc(
          appConfigRepository: appConfigRepository,
          userRepository: userRepository,
          firebaseDatabaseRepository: firebaseDatabaseRepository,
          user: const User(id: 'initial-user-id'),
        );

    group('_onUserChanged', () {
      blocTest<AppBloc, AppState>(
        'migrates legacy PIN before evaluating the profile',
        setUp: () {
          when(() => firebaseDatabaseRepository.migrateLegacyPin('user1'))
              .thenAnswer((_) async {});
          when(() => firebaseDatabaseRepository.getUserProfileOnce('user1'))
              .thenAnswer(
            (_) async => const UserProfileModel(
              id: 'user1',
              username: 'josh',
              hasPin: true,
              onboardingComplete: true,
            ),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(
          const AppUserChanged(
            User(id: 'user1', email: 'josh@example.com'),
          ),
        ),
        verify: (_) {
          verifyInOrder([
            () => firebaseDatabaseRepository.migrateLegacyPin('user1'),
            () => firebaseDatabaseRepository.getUserProfileOnce('user1'),
          ]);
        },
      );
    });
  });
}
