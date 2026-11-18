import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/match_details_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class _MockDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

Player _seat(String id, {String? firebaseId}) => Player(
  id: id,
  name: 'Name-$id',
  playerNumber: 0,
  lifePoints: 40,
  color: 0xFF000000,
  opponents: const [],
  placement: 1,
  timeOfDeath: 0,
  firebaseId: firebaseId,
);

GameModel _game(List<Player> players) => GameModel(
  id: 'game-1',
  winnerId: 'a',
  startTime: DateTime(2026),
  endTime: DateTime(2026, 1, 1, 1),
  durationInSeconds: 3600,
  players: players,
);

void main() {
  late FirebaseDatabaseRepository repository;

  setUpAll(() {
    registerFallbackValue(_game([_seat('a')]));
  });

  setUp(() {
    repository = _MockDatabaseRepository();
    when(
      () => repository.updateGameStats(
        game: any(named: 'game'),
        playerId: any(named: 'playerId'),
      ),
    ).thenAnswer((_) async {});
  });

  MatchDetailsBloc buildBloc() =>
      MatchDetailsBloc(databaseRepository: repository);

  group('AssignSeatIdentity', () {
    blocTest<MatchDetailsBloc, MatchDetailsState>(
      'tags a friend onto a seat and writes to the owner history copy',
      build: buildBloc,
      act: (bloc) => bloc.add(
        AssignSeatIdentity(
          game: _game([_seat('a'), _seat('b')]),
          seat: _seat('b'),
          assignedFirebaseId: 'friend-uid',
          ownerUserId: 'my-uid',
        ),
      ),
      expect: () => [isA<MatchDetailsSuccess>()],
      verify: (_) {
        final captured =
            verify(
                  () => repository.updateGameStats(
                    game: captureAny(named: 'game'),
                    playerId: 'my-uid',
                  ),
                ).captured.single
                as GameModel;
        final seatB = captured.players.firstWhere((p) => p.id == 'b');
        expect(seatB.firebaseId, 'friend-uid');
      },
    );

    blocTest<MatchDetailsBloc, MatchDetailsState>(
      'moves an identity off the seat that previously held it',
      build: buildBloc,
      act: (bloc) => bloc.add(
        AssignSeatIdentity(
          game: _game([
            _seat('a', firebaseId: 'friend-uid'),
            _seat('b'),
          ]),
          seat: _seat('b'),
          assignedFirebaseId: 'friend-uid',
          ownerUserId: 'my-uid',
        ),
      ),
      expect: () => [isA<MatchDetailsSuccess>()],
      verify: (_) {
        final captured =
            verify(
                  () => repository.updateGameStats(
                    game: captureAny(named: 'game'),
                    playerId: any(named: 'playerId'),
                  ),
                ).captured.single
                as GameModel;
        expect(
          captured.players.firstWhere((p) => p.id == 'a').firebaseId,
          isNull,
        );
        expect(
          captured.players.firstWhere((p) => p.id == 'b').firebaseId,
          'friend-uid',
        );
      },
    );

    blocTest<MatchDetailsBloc, MatchDetailsState>(
      'unassigns a seat when given a null identity',
      build: buildBloc,
      act: (bloc) => bloc.add(
        AssignSeatIdentity(
          game: _game([_seat('a', firebaseId: 'my-uid'), _seat('b')]),
          seat: _seat('a', firebaseId: 'my-uid'),
          assignedFirebaseId: null,
          ownerUserId: 'my-uid',
        ),
      ),
      expect: () => [isA<MatchDetailsSuccess>()],
      verify: (_) {
        final captured =
            verify(
                  () => repository.updateGameStats(
                    game: captureAny(named: 'game'),
                    playerId: any(named: 'playerId'),
                  ),
                ).captured.single
                as GameModel;
        expect(
          captured.players.firstWhere((p) => p.id == 'a').firebaseId,
          isNull,
        );
      },
    );
  });
}
