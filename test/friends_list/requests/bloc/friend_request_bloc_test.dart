import 'dart:async';

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
        'emits FriendRequestLegacyAcceptError then re-emits the prior '
        'loaded list when the repository throws '
        'LegacyFriendRequestException, so the page recovers instead of '
        'showing an empty list',
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
        expect: () => [
          isA<FriendRequestLegacyAcceptError>(),
          isA<FriendRequestLoaded>().having(
            (s) => s.requests,
            'requests',
            [request],
          ),
        ],
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
    });

    group('LoadFriendRequests', () {
      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits [loading, loaded] from the stream',
        setUp: () {
          when(() => repository.watchFriendRequests('alice')).thenAnswer(
            (_) => Stream.value([request]),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriendRequests('alice')),
        expect: () => [
          isA<FriendRequestLoading>(),
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', [request]),
        ],
      );

      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits again when the stream emits an update',
        setUp: () {
          when(() => repository.watchFriendRequests('alice')).thenAnswer(
            (_) => Stream.fromIterable([
              [request],
              <FriendRequestModel>[],
            ]),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriendRequests('alice')),
        expect: () => [
          isA<FriendRequestLoading>(),
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', [request]),
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', isEmpty),
        ],
      );

      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits an empty loaded list and never subscribes when userId is empty',
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriendRequests('')),
        expect: () => [
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', isEmpty),
        ],
        verify: (_) {
          verifyNever(() => repository.watchFriendRequests(any()));
        },
      );

      blocTest<FriendRequestBloc, FriendRequestState>(
        'emits [loading, error] when the stream errors',
        setUp: () {
          when(() => repository.watchFriendRequests('alice')).thenAnswer(
            (_) => Stream.error(Exception('boom')),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadFriendRequests('alice')),
        expect: () => [
          isA<FriendRequestLoading>(),
          isA<FriendRequestError>(),
        ],
      );
    });

    group('AcceptFriendRequest with a live stream', () {
      blocTest<FriendRequestBloc, FriendRequestState>(
        'accepting emits nothing itself — the stream re-emits without the '
        'request, which is what clears the badge',
        setUp: () {
          final controller =
              StreamController<List<FriendRequestModel>>.broadcast();
          when(() => repository.watchFriendRequests('alice'))
              .thenAnswer((_) => controller.stream);
          when(() => repository.acceptFriendRequest(request, 'alice'))
              .thenAnswer((_) async {
            // Stand in for Firestore's latency compensation: the batch delete
            // makes the live query re-emit without the accepted request.
            controller.add(<FriendRequestModel>[]);
          });
          addTearDown(controller.close);
        },
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const LoadFriendRequests('alice'));
          await Future<void>.delayed(Duration.zero);
          bloc.add(AcceptFriendRequest(request, 'alice'));
        },
        expect: () => [
          isA<FriendRequestLoading>(),
          isA<FriendRequestLoaded>()
              .having((s) => s.requests, 'requests', isEmpty),
        ],
      );
    });
  });
}
