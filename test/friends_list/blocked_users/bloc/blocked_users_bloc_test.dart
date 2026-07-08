import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/blocked_users/bloc/blocked_users_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('BlockedUsersBloc', () {
    late FirebaseDatabaseRepository repository;

    const bob = BlockedUserModel(
      userId: 'bob',
      username: 'Bob',
      imageUrl: 'http://x/bob.png',
    );

    const carol = BlockedUserModel(
      userId: 'carol',
      username: 'Carol',
      imageUrl: 'http://x/carol.png',
    );

    setUp(() {
      repository = _MockFirebaseDatabaseRepository();
    });

    BlockedUsersBloc buildBloc() =>
        BlockedUsersBloc(repository: repository);

    test('initial state is BlockedUsersLoading', () {
      expect(buildBloc().state, isA<BlockedUsersLoading>());
    });

    group('LoadBlockedUsers', () {
      blocTest<BlockedUsersBloc, BlockedUsersState>(
        'emits [loading, loaded] when getBlockedUsers succeeds',
        setUp: () {
          when(() => repository.getBlockedUsers('alice')).thenAnswer(
            (_) => Stream.value([bob, carol]),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadBlockedUsers('alice')),
        expect: () => [
          isA<BlockedUsersLoading>(),
          isA<BlockedUsersLoaded>().having(
            (s) => s.blockedUsers,
            'blockedUsers',
            [bob, carol],
          ),
        ],
      );

      blocTest<BlockedUsersBloc, BlockedUsersState>(
        'emits [loading, loaded] again when the stream emits an update',
        setUp: () {
          when(() => repository.getBlockedUsers('alice')).thenAnswer(
            (_) => Stream.fromIterable([
              [bob, carol],
              [carol],
            ]),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadBlockedUsers('alice')),
        expect: () => [
          isA<BlockedUsersLoading>(),
          isA<BlockedUsersLoaded>().having(
            (s) => s.blockedUsers,
            'blockedUsers',
            [bob, carol],
          ),
          isA<BlockedUsersLoaded>().having(
            (s) => s.blockedUsers,
            'blockedUsers',
            [carol],
          ),
        ],
      );

      blocTest<BlockedUsersBloc, BlockedUsersState>(
        'emits [loading, error] when getBlockedUsers stream errors',
        setUp: () {
          when(() => repository.getBlockedUsers('alice')).thenAnswer(
            (_) => Stream.error(Exception('boom')),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadBlockedUsers('alice')),
        expect: () => [
          isA<BlockedUsersLoading>(),
          isA<BlockedUsersError>(),
        ],
      );
    });

    group('UnblockUser', () {
      blocTest<BlockedUsersBloc, BlockedUsersState>(
        'calls repository.unblockUser with currentUserId and targetUserId',
        setUp: () {
          when(
            () => repository.unblockUser(
              currentUserId: any(named: 'currentUserId'),
              targetUserId: any(named: 'targetUserId'),
            ),
          ).thenAnswer((_) async {});
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const UnblockUser('alice', 'bob')),
        verify: (_) {
          verify(
            () => repository.unblockUser(
              currentUserId: 'alice',
              targetUserId: 'bob',
            ),
          ).called(1);
        },
      );

      blocTest<BlockedUsersBloc, BlockedUsersState>(
        'emits error when unblockUser fails',
        setUp: () {
          when(
            () => repository.unblockUser(
              currentUserId: any(named: 'currentUserId'),
              targetUserId: any(named: 'targetUserId'),
            ),
          ).thenThrow(Exception('boom'));
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const UnblockUser('alice', 'bob')),
        expect: () => [isA<BlockedUsersError>()],
      );
    });
  });
}
