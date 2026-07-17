import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('FriendBloc', () {
    late FirebaseDatabaseRepository repository;

    const bob = FriendModel(
      userId: 'bob',
      username: 'Bob',
      profilePictureUrl: 'http://x/bob.png',
      friendCode: 'YETI-B0B1',
    );

    const target = BlockedUserModel(
      userId: 'bob',
      username: 'Bob',
      imageUrl: 'http://x/bob.png',
    );

    setUpAll(() {
      registerFallbackValue(
        const BlockedUserModel(userId: '', username: '', imageUrl: ''),
      );
    });

    setUp(() {
      repository = _MockFirebaseDatabaseRepository();
    });

    FriendBloc buildBloc() => FriendBloc(repository: repository);

    group('LoadFriends', () {
      blocTest<FriendBloc, FriendState>(
        'emits [loading, loaded] from the stream',
        setUp: () {
          when(
            () => repository.watchFriends('alice'),
          ).thenAnswer((_) => Stream.value([bob]));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriends('alice')),
        expect: () => [
          isA<FriendsLoading>(),
          isA<FriendsLoaded>().having((s) => s.friends, 'friends', [bob]),
        ],
      );

      blocTest<FriendBloc, FriendState>(
        'emits an empty loaded list and never subscribes when userId is empty',
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriends('')),
        expect: () => [
          isA<FriendsLoaded>().having((s) => s.friends, 'friends', isEmpty),
        ],
        verify: (_) {
          verifyNever(() => repository.watchFriends(any()));
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits [loading, error] when the stream errors',
        setUp: () {
          when(
            () => repository.watchFriends('alice'),
          ).thenAnswer((_) => Stream.error(Exception('boom')));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriends('alice')),
        expect: () => [isA<FriendsLoading>(), isA<FriendsError>()],
      );
    });

    group('BlockFriend', () {
      blocTest<FriendBloc, FriendState>(
        'calls repository.blockUser and emits nothing on success — the '
        'watchFriends stream re-emits without the blocked friend',
        setUp: () {
          when(
            () => repository.blockUser(
              currentUserId: any(named: 'currentUserId'),
              target: any(named: 'target'),
            ),
          ).thenAnswer((_) async {});
        },
        build: buildBloc,
        seed: () => const FriendsLoaded([bob]),
        act: (bloc) => bloc.add(const BlockFriend('alice', target)),
        expect: () => <FriendState>[],
        verify: (_) {
          verify(
            () => repository.blockUser(currentUserId: 'alice', target: target),
          ).called(1);
        },
      );

      blocTest<FriendBloc, FriendState>(
        'emits FriendsError when blockUser fails',
        setUp: () {
          when(
            () => repository.blockUser(
              currentUserId: any(named: 'currentUserId'),
              target: any(named: 'target'),
            ),
          ).thenThrow(Exception('boom'));
        },
        build: buildBloc,
        seed: () => const FriendsLoaded([bob]),
        act: (bloc) => bloc.add(const BlockFriend('alice', target)),
        expect: () => [isA<FriendsError>()],
      );
    });
  });
}
