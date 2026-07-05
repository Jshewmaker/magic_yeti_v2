import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('FriendRequestBloc', () {
    late FirebaseDatabaseRepository repository;

    final request = FriendRequestModel(
      id: 'bob_alice',
      senderId: 'bob',
      senderName: 'Bob',
      receiverId: 'alice',
      status: 'pending',
      timestamp: DateTime(2024),
    );

    setUp(() {
      repository = _MockFirebaseDatabaseRepository();
    });

    FriendRequestBloc buildBloc() =>
        FriendRequestBloc(repository: repository);

    group('AcceptFriendRequest', () {
      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits FriendRequestLegacyAcceptError when the repository throws '
        'LegacyFriendRequestException',
        setUp: () {
          when(() => repository.acceptFriendRequest(request, 'alice'))
              .thenThrow(
            const LegacyFriendRequestException(
              message: 'Failed to accept friend request',
              stackTrace: 'stack',
            ),
          );
        },
        build: buildBloc,
        seed: () => FriendRequestLoaded([request]),
        act: (bloc) => bloc.add(AcceptFriendRequest(request, 'alice')),
        expect: () => [isA<FriendRequestLegacyAcceptError>()],
      );

      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits generic FriendRequestError for other failures',
        setUp: () {
          when(() => repository.acceptFriendRequest(request, 'alice'))
              .thenThrow(Exception('boom'));
        },
        build: buildBloc,
        seed: () => FriendRequestLoaded([request]),
        act: (bloc) => bloc.add(AcceptFriendRequest(request, 'alice')),
        expect: () => [
          isA<FriendRequestError>().having(
            (s) => s is FriendRequestLegacyAcceptError,
            'isLegacy',
            false,
          ),
        ],
      );

      blocTest<FriendRequestBloc, FriendRequestState>(
        'removes the accepted request from the in-memory list on success',
        setUp: () {
          when(() => repository.acceptFriendRequest(request, 'alice'))
              .thenAnswer((_) async {});
        },
        build: buildBloc,
        seed: () => FriendRequestLoaded([request]),
        act: (bloc) => bloc.add(AcceptFriendRequest(request, 'alice')),
        expect: () => [
          isA<FriendRequestLoaded>().having(
            (s) => s.requests,
            'requests',
            isEmpty,
          ),
        ],
      );
    });
  });
}
