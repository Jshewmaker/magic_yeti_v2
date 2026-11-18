import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/player/bloc/player_bloc.dart';
import 'package:magic_yeti/tracker/commander_damage_tracker_widget.dart';
import 'package:mocktail/mocktail.dart';
import 'package:player_repository/player_repository.dart';

class MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

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
    home: DeviceInfoProvider(
      isPhone: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>.value(value: playerBloc),
          BlocProvider<GameBloc>.value(value: gameBloc),
        ],
        child: Scaffold(body: child),
      ),
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
        final container = tester
            .widgetList<Container>(
              find.byType(Container),
            )
            .where((c) {
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

  group('CommanderDamageButton hold behavior', () {
    Future<void> pumpTile(WidgetTester tester) => tester.pumpWidget(
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

    const holdStarted = PlayerCommanderDamageHoldStarted(
      commanderId: 'target-1',
      damageType: DamageType.commander,
    );

    testWidgets('holding starts a hold, and lifting ends it', (tester) async {
      await pumpTile(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CommanderDamageButton)),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      verify(() => mockPlayerBloc.add(holdStarted)).called(1);
      verifyNever(
        () => mockPlayerBloc.add(const PlayerCommanderDamageHoldEnded()),
      );

      await gesture.up();
      await tester.pump();

      verify(
        () => mockPlayerBloc.add(const PlayerCommanderDamageHoldEnded()),
      ).called(1);
    });

    testWidgets('a hold does not add damage or change the tile size', (
      tester,
    ) async {
      await pumpTile(tester);
      final sizeBefore = tester.getSize(find.byType(CommanderDamageButton));

      await tester.longPress(find.byType(CommanderDamageButton));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockPlayerBloc.add(
          const PlayerCommanderDamageIncremented(
            commanderId: 'target-1',
            damageType: DamageType.commander,
          ),
        ),
      );
      expect(tester.getSize(find.byType(CommanderDamageButton)), sizeBefore);
      expect(find.byIcon(Icons.remove), findsNothing);
    });

    testWidgets('a tap does not start or end a hold', (tester) async {
      await pumpTile(tester);

      await tester.tap(find.byType(CommanderDamageButton));
      await tester.pumpAndSettle();

      verifyNever(() => mockPlayerBloc.add(holdStarted));
      verifyNever(
        () => mockPlayerBloc.add(const PlayerCommanderDamageHoldEnded()),
      );
    });

    testWidgets('removing a held tile ends the hold', (tester) async {
      await pumpTile(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CommanderDamageButton)),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      await tester.pumpWidget(const SizedBox.shrink());

      verify(
        () => mockPlayerBloc.add(const PlayerCommanderDamageHoldEnded()),
      ).called(1);
      await gesture.up();
    });
  });

  group('CommanderDamageTracker partner tiles', () {
    testWidgets('shows two tiles when the partner has no art', (tester) async {
      final noArtPartner = createTestPlayer(
        id: 'target-1',
        commander: createTestCommander(name: 'Commander C'),
        partner: createTestCommander(name: 'Partner C', imageUrl: ''),
      );
      when(() => mockGameBloc.state).thenReturn(
        GameState(playerList: [ownerPlayer, noArtPartner]),
      );

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

      expect(find.byType(CommanderDamageButton), findsNWidgets(2));
    });
  });

  group('holding a tile with real blocs', () {
    const interval = PlayerBloc.commanderDamageRepeatInterval;

    late PlayerRepository repository;
    late PlayerBloc playerBloc;

    Player owner() => repository.getPlayerById('owner');

    int damage(DamageType type) => owner().opponents!
        .firstWhere((o) => o.playerId == 'target-2')
        .damages
        .firstWhere((d) => d.damageType == type)
        .amount;

    Future<void> pumpTracker(
      WidgetTester tester, {
      required int commanderDamage,
      int partnerDamage = 0,
    }) async {
      repository = PlayerRepository()
        ..createPlayer(
          createTestPlayer(
            id: 'owner',
            opponents: [
              Opponent(
                playerId: 'target-2',
                damages: [
                  CommanderDamage(
                    damageType: DamageType.commander,
                    amount: commanderDamage,
                  ),
                  CommanderDamage(
                    damageType: DamageType.partner,
                    amount: partnerDamage,
                  ),
                ],
              ),
            ],
          ),
        )
        ..createPlayer(partnerPlayer);
      playerBloc = PlayerBloc(playerRepository: repository, playerId: 'owner');
      addTearDown(playerBloc.close);
      when(() => mockGameBloc.state).thenReturn(
        GameState(playerList: repository.getPlayers()),
      );

      await tester.pumpWidget(
        buildTestWidget(
          playerBloc: playerBloc,
          gameBloc: mockGameBloc,
          child: CommanderDamageTracker(
            playerId: 'owner',
            player: owner(),
            commanderPlayerId: 'target-2',
          ),
        ),
      );
      await tester.pump();
    }

    Future<TestGesture> startHold(WidgetTester tester, {int tile = 0}) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CommanderDamageButton).at(tile)),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
      await tester.pump();
      return gesture;
    }

    testWidgets('a tap adds 1 damage and takes 1 life', (tester) async {
      await pumpTracker(tester, commanderDamage: 3);

      await tester.tap(find.byType(CommanderDamageButton).first);
      await tester.pumpAndSettle();

      expect(damage(DamageType.commander), 4);
      expect(owner().lifePoints, 39);
    });

    testWidgets('a hold subtracts 1 at once and then 1 each second', (
      tester,
    ) async {
      await pumpTracker(tester, commanderDamage: 5);

      final gesture = await startHold(tester);
      expect(damage(DamageType.commander), 4);
      expect(owner().lifePoints, 41);

      await tester.pump(interval);
      await tester.pump();
      expect(damage(DamageType.commander), 3);

      await tester.pump(interval);
      await tester.pump();
      expect(damage(DamageType.commander), 2);
      expect(owner().lifePoints, 43);
      expect(find.text('2'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      await tester.pump(interval * 3);
      await tester.pump();
      expect(damage(DamageType.commander), 2);
      expect(owner().lifePoints, 43);
    });

    testWidgets('a hold stops at 0 and gives back no extra life', (
      tester,
    ) async {
      await pumpTracker(tester, commanderDamage: 1);

      final gesture = await startHold(tester);
      await tester.pump(interval * 3);
      await tester.pump();

      expect(damage(DamageType.commander), 0);
      expect(owner().lifePoints, 41);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('holding the partner tile changes only the partner damage', (
      tester,
    ) async {
      await pumpTracker(tester, commanderDamage: 5, partnerDamage: 2);

      final gesture = await startHold(tester, tile: 1);
      await gesture.up();
      await tester.pump();

      expect(damage(DamageType.partner), 1);
      expect(damage(DamageType.commander), 5);
    });

    testWidgets('removing lethal damage brings the player back', (
      tester,
    ) async {
      await pumpTracker(tester, commanderDamage: 20);

      await tester.tap(find.byType(CommanderDamageButton).first);
      await tester.pumpAndSettle();
      expect(owner().isEliminated, isTrue);

      final gesture = await startHold(tester);
      await gesture.up();
      await tester.pump();

      expect(damage(DamageType.commander), 20);
      expect(owner().isActive, isTrue);
    });
  });
}
