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

    group('BlockFriend', () {
      blocTest<FriendBloc, FriendState>(
        'calls repository.blockUser then reloads friends',
        setUp: () {
          when(
            () => repository.blockUser(
              currentUserId: any(named: 'currentUserId'),
              target: any(named: 'target'),
            ),
          ).thenAnswer((_) async {});
          when(() => repository.getFriends('alice'))
              .thenAnswer((_) async => <FriendModel>[]);
        },
        build: buildBloc,
        seed: () => const FriendsLoaded([bob]),
        act: (bloc) => bloc.add(const BlockFriend('alice', target)),
        expect: () => [
          isA<FriendsLoaded>().having((s) => s.friends, 'friends', isEmpty),
        ],
        verify: (_) {
          verify(
            () => repository.blockUser(currentUserId: 'alice', target: target),
          ).called(1);
          verify(() => repository.getFriends('alice')).called(1);
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
