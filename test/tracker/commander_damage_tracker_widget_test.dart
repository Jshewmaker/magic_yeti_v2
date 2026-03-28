import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/tracker/commander_damage_tracker_widget.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/models/models.dart';

class MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

class MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

/// Creates a test player with optional partner.
Player createTestPlayer({
  required String id,
  String name = 'Test Player',
  int color = 0xFF0000FF,
  Commander? commander,
  Commander? partner,
  List<Opponent>? opponents,
}) {
  return Player(
    id: id,
    name: name,
    playerNumber: 1,
    lifePoints: 40,
    color: color,
    commander: commander,
    partner: partner,
    opponents: opponents ?? [],
    state: PlayerModelState.active,
  );
}

Commander createTestCommander({
  String name = 'Test Commander',
  String imageUrl = 'https://example.com/image.jpg',
}) {
  return Commander(
    name: name,
    imageUrl: imageUrl,
    colors: const [],
    cardType: 'Legendary Creature',
    manaCost: '{2}{W}',
    oracleText: 'Test oracle text',
    artist: 'Test Artist',
  );
}

/// Wraps widget with required BlocProviders for testing.
Widget buildTestWidget({
  required Widget child,
  required PlayerBloc playerBloc,
  required GameBloc gameBloc,
}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<PlayerBloc>.value(value: playerBloc),
        BlocProvider<GameBloc>.value(value: gameBloc),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  late MockPlayerBloc mockPlayerBloc;
  late MockGameBloc mockGameBloc;

  final commanderPlayer = createTestPlayer(
    id: 'target-1',
    commander: createTestCommander(name: 'Commander A'),
    opponents: [],
  );

  final partnerPlayer = createTestPlayer(
    id: 'target-2',
    commander: createTestCommander(name: 'Commander B'),
    partner: createTestCommander(name: 'Partner B'),
    opponents: [],
  );

  final ownerPlayer = createTestPlayer(
    id: 'owner',
    opponents: [
      Opponent(
        playerId: 'target-1',
        damages: [
          CommanderDamage(damageType: DamageType.commander, amount: 3),
        ],
      ),
      Opponent(
        playerId: 'target-2',
        damages: [
          CommanderDamage(damageType: DamageType.commander, amount: 5),
          CommanderDamage(damageType: DamageType.partner, amount: 2),
        ],
      ),
    ],
  );

  setUp(() {
    mockPlayerBloc = MockPlayerBloc();
    mockGameBloc = MockGameBloc();

    when(() => mockPlayerBloc.state).thenReturn(
      PlayerState(player: ownerPlayer),
    );
    when(() => mockGameBloc.state).thenReturn(
      GameState(
        playerList: [ownerPlayer, commanderPlayer, partnerPlayer],
      ),
    );
  });

  group('CommanderDamageTracker partner layout', () {
    testWidgets(
      'renders single CommanderDamageButton when no partner',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageTracker(
              playerId: 'owner',
              player: ownerPlayer,
              commanderPlayerId: 'target-1',
            ),
          ),
        );

        expect(
          find.byType(CommanderDamageButton),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders two CommanderDamageButtons in a Row when partner exists',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageTracker(
              playerId: 'owner',
              player: ownerPlayer,
              commanderPlayerId: 'target-2',
            ),
          ),
        );

        // Two buttons: one for commander, one for partner
        expect(
          find.byType(CommanderDamageButton),
          findsNWidgets(2),
        );

        // They should be in a Row, not a Column
        expect(find.byType(Row), findsWidgets);
        // Verify a Row is a direct parent of both buttons
        final row = tester.widgetList<Row>(find.byType(Row)).where((row) {
          return row.children.whereType<CommanderDamageButton>().length == 2;
        });
        expect(row, isNotEmpty);
      },
    );

    testWidgets(
      'partner container uses target player color',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageTracker(
              playerId: 'owner',
              player: ownerPlayer,
              commanderPlayerId: 'target-2',
            ),
          ),
        );

        // Find the container wrapping partner tiles
        final container = tester.widgetList<Container>(
          find.byType(Container),
        ).where((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            return decoration.color == Color(partnerPlayer.color);
          }
          return false;
        });
        expect(container, isNotEmpty);
      },
    );
  });

  group('CommanderDamageButton tap behavior', () {
    testWidgets(
      'tap anywhere on tile increments damage',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageButton(
              playerId: 'owner',
              commanderPlayerId: 'target-1',
              player: ownerPlayer,
              targetPlayer: commanderPlayer,
              commanderDamage: 3,
              damageType: DamageType.commander,
            ),
          ),
        );

        // Tap the center of the tile (not specifically right half)
        await tester.tap(find.byType(CommanderDamageButton));
        await tester.pumpAndSettle();

        verify(
          () => mockPlayerBloc.add(
            const UpdatePlayerLifeEvent(
              decrement: true,
              playerId: 'owner',
            ),
          ),
        ).called(1);
        verify(
          () => mockPlayerBloc.add(
            const PlayerCommanderDamageIncremented(
              commanderId: 'target-1',
              damageType: DamageType.commander,
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tap on left half of tile also increments (no longer decrements)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            playerBloc: mockPlayerBloc,
            gameBloc: mockGameBloc,
            child: CommanderDamageButton(
              playerId: 'owner',
              commanderPlayerId: 'target-1',
              player: ownerPlayer,
              targetPlayer: commanderPlayer,
              commanderDamage: 3,
              damageType: DamageType.commander,
            ),
          ),
        );

        // Tap the left side of the tile
        final buttonFinder = find.byType(CommanderDamageButton);
        final topLeft = tester.getTopLeft(buttonFinder);
        await tester.tapAt(topLeft + const Offset(5, 50));
        await tester.pumpAndSettle();

        // Should increment, NOT decrement
        verify(
          () => mockPlayerBloc.add(
            const PlayerCommanderDamageIncremented(
              commanderId: 'target-1',
              damageType: DamageType.commander,
            ),
          ),
        ).called(1);
        verifyNever(
          () => mockPlayerBloc.add(
            const PlayerCommanderDamageDecremented(
              commanderId: 'target-1',
              damageType: DamageType.commander,
            ),
          ),
        );
      },
    );
  });
}
