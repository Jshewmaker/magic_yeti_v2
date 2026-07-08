import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/search_user/bloc/search_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  late _MockFirebaseDatabaseRepository repository;

  const target = UserProfileModel(
    id: 'target',
    username: 'Target',
    friendCode: 'YETI-A3F9',
  );
  const otherMatch = UserProfileModel(
    id: 'other',
    username: 'Targetina',
    friendCode: 'YETI-ZZZZ',
  );

  SearchBloc buildBloc() => SearchBloc(repository: repository);

  setUp(() {
    repository = _MockFirebaseDatabaseRepository();
  });

  group('SearchSubmitted', () {
    blocTest<SearchBloc, SearchState>(
      'routes a friend-code-shaped query to searchByFriendCode',
      build: () {
        when(() => repository.searchByFriendCode('YETI-A3F9')).thenAnswer(
          (_) async => const FriendSearchResult(
            found: true,
            user: target,
            relationship: RelationshipStatus.none,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchSubmitted('YETI-A3F9', 'me')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>().having(
          (s) => s.matches,
          'matches',
          const [
            UserSearchMatch(
              user: target,
              relationship: RelationshipStatus.none,
            ),
          ],
        ),
      ],
      verify: (_) {
        verify(() => repository.searchByFriendCode('YETI-A3F9')).called(1);
        verifyNever(() => repository.searchByUsername(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'accepts a legacy YETI- code typed lowercase with surrounding '
      'whitespace',
      build: () {
        when(() => repository.searchByFriendCode(' yeti-a3f9 ')).thenAnswer(
          (_) async => const FriendSearchResult(
            found: true,
            user: target,
            relationship: RelationshipStatus.none,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchSubmitted(' yeti-a3f9 ', 'me')),
      expect: () => [isA<SearchLoading>(), isA<SearchLoaded>()],
      verify: (_) {
        verify(() => repository.searchByFriendCode(' yeti-a3f9 ')).called(1);
        verifyNever(() => repository.searchByUsername(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'routes a plain 8-character code-shaped query to searchByFriendCode',
      build: () {
        when(() => repository.searchByFriendCode('A3F9K2XQ')).thenAnswer(
          (_) async => const FriendSearchResult(
            found: true,
            user: target,
            relationship: RelationshipStatus.none,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchSubmitted('A3F9K2XQ', 'me')),
      expect: () => [isA<SearchLoading>(), isA<SearchLoaded>()],
      verify: (_) {
        verify(() => repository.searchByFriendCode('A3F9K2XQ')).called(1);
        verifyNever(() => repository.searchByUsername(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'falls back to searchByUsername when a code-shaped query is not a '
      'real friend code — an 8-character string could coincidentally also '
      'be a real username',
      build: () {
        when(() => repository.searchByFriendCode('GAMER123')).thenAnswer(
          (_) async => const FriendSearchResult(found: false),
        );
        when(() => repository.searchByUsername('GAMER123')).thenAnswer(
          (_) async => const [
            UserSearchMatch(
              user: target,
              relationship: RelationshipStatus.none,
            ),
          ],
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchSubmitted('GAMER123', 'me')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>().having(
          (s) => s.matches,
          'matches',
          const [
            UserSearchMatch(
              user: target,
              relationship: RelationshipStatus.none,
            ),
          ],
        ),
      ],
      verify: (_) {
        verify(() => repository.searchByFriendCode('GAMER123')).called(1);
        verify(() => repository.searchByUsername('GAMER123')).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'routes anything else to searchByUsername, preserving match order',
      build: () {
        when(() => repository.searchByUsername('targ')).thenAnswer(
          (_) async => const [
            UserSearchMatch(
              user: target,
              relationship: RelationshipStatus.none,
            ),
            UserSearchMatch(
              user: otherMatch,
              relationship: RelationshipStatus.pendingReceived,
            ),
          ],
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchSubmitted('targ', 'me')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>().having(
          (s) => s.matches,
          'matches',
          const [
            UserSearchMatch(
              user: target,
              relationship: RelationshipStatus.none,
            ),
            UserSearchMatch(
              user: otherMatch,
              relationship: RelationshipStatus.pendingReceived,
            ),
          ],
        ),
      ],
      verify: (_) {
        verify(() => repository.searchByUsername('targ')).called(1);
        verifyNever(() => repository.searchByFriendCode(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'friend-code search with no result falls back to an equally-empty '
      'username search',
      build: () {
        when(() => repository.searchByFriendCode('YETI-ZZZZ'))
            .thenAnswer((_) async => const FriendSearchResult(found: false));
        when(() => repository.searchByUsername('YETI-ZZZZ'))
            .thenAnswer((_) async => const <UserSearchMatch>[]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchSubmitted('YETI-ZZZZ', 'me')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>().having((s) => s.matches, 'matches', isEmpty),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'ArgumentError from the repository surfaces as SearchError',
      build: () {
        when(() => repository.searchByUsername('a'))
            .thenThrow(ArgumentError('too short'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchSubmitted('a', 'me')),
      expect: () => [isA<SearchLoading>(), isA<SearchError>()],
    );

    blocTest<SearchBloc, SearchState>(
      'a plain Exception from the repository surfaces as SearchError',
      build: () {
        when(() => repository.searchByUsername('targ'))
            .thenThrow(Exception('unavailable'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchSubmitted('targ', 'me')),
      expect: () => [isA<SearchLoading>(), isA<SearchError>()],
    );
  });

  group('AddFriendRequest', () {
    const meProfile = UserProfileModel(
      id: 'me',
      username: 'Me',
      friendCode: 'YETI-ME01',
    );

    blocTest<SearchBloc, SearchState>(
      "looks up the sender's own profile and denormalizes its username + "
      'friend code onto the request — never a display name passed in by '
      'the caller',
      build: () {
        when(() => repository.getUserProfileOnce('me'))
            .thenAnswer((_) async => meProfile);
        when(
          () => repository.addFriendRequest(
            'me',
            'Me',
            'YETI-ME01',
            'target',
          ),
        ).thenAnswer((_) async => FriendRequestResult.sent);
        return buildBloc();
      },
      seed: () => const SearchLoaded([
        UserSearchMatch(user: target, relationship: RelationshipStatus.none),
        UserSearchMatch(
          user: otherMatch,
          relationship: RelationshipStatus.pendingReceived,
        ),
      ]),
      act: (bloc) => bloc.add(const AddFriendRequest('me', 'target')),
      expect: () => [
        isA<FriendRequestSent>()
            .having((s) => s.result, 'result', FriendRequestResult.sent)
            .having(
              (s) => s.matches,
              'matches',
              const [
                UserSearchMatch(
                  user: target,
                  relationship: RelationshipStatus.pendingSent,
                ),
                UserSearchMatch(
                  user: otherMatch,
                  relationship: RelationshipStatus.pendingReceived,
                ),
              ],
            ),
      ],
      verify: (_) {
        verify(
          () => repository.addFriendRequest('me', 'Me', 'YETI-ME01', 'target'),
        ).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'a missing sender profile falls back to an empty name and null '
      'friend code, rather than throwing',
      build: () {
        when(() => repository.getUserProfileOnce('me'))
            .thenAnswer((_) async => null);
        when(() => repository.addFriendRequest('me', '', null, 'target'))
            .thenAnswer((_) async => FriendRequestResult.sent);
        return buildBloc();
      },
      seed: () => const SearchLoaded(
        [UserSearchMatch(user: target, relationship: RelationshipStatus.none)],
      ),
      act: (bloc) => bloc.add(const AddFriendRequest('me', 'target')),
      expect: () => [isA<FriendRequestSent>()],
      verify: (_) {
        verify(
          () => repository.addFriendRequest('me', '', null, 'target'),
        ).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'emits SearchError when addFriendRequest throws',
      build: () {
        when(() => repository.getUserProfileOnce('me'))
            .thenAnswer((_) async => meProfile);
        when(
          () => repository.addFriendRequest('me', 'Me', 'YETI-ME01', 'target'),
        ).thenThrow(Exception('boom'));
        return buildBloc();
      },
      seed: () => const SearchLoaded(
        [UserSearchMatch(user: target, relationship: RelationshipStatus.none)],
      ),
      act: (bloc) => bloc.add(const AddFriendRequest('me', 'target')),
      expect: () => [isA<SearchError>()],
    );

    blocTest<SearchBloc, SearchState>(
      'emits SearchError when the profile lookup itself throws',
      build: () {
        when(() => repository.getUserProfileOnce('me'))
            .thenThrow(Exception('offline'));
        return buildBloc();
      },
      seed: () => const SearchLoaded(
        [UserSearchMatch(user: target, relationship: RelationshipStatus.none)],
      ),
      act: (bloc) => bloc.add(const AddFriendRequest('me', 'target')),
      expect: () => [isA<SearchError>()],
      verify: (_) {
        verifyNever(
          () => repository.addFriendRequest(any(), any(), any(), any()),
        );
      },
    );
  });
}
