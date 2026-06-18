// test/match_details/widgets/editable_player_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/widgets/editable_player_tile.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/helpers.dart';

Player _player({Commander? partner}) => Player(
      id: 'p1',
      name: 'Alice',
      playerNumber: 1,
      lifePoints: 40,
      color: 0xFF112233,
      opponents: const [],
      state: PlayerModelState.eliminated,
      placement: 1,
      timeOfDeath: 0,
      partner: partner,
    );

const _commander = Commander(
  name: 'Atraxa',
  colors: ['W'],
  cardType: 'Legendary Creature',
  imageUrl: '',
  manaCost: '',
  oracleText: '',
  artist: '',
);

void main() {
  testWidgets('shows the name and calls onNameChanged when edited',
      (tester) async {
    final changes = <String>[];
    await tester.pumpApp(
      EditablePlayerTile(
        player: _player(),
        onNameChanged: changes.add,
        onTapCommander: () {},
        onTapPartner: () {},
        onRemovePartner: () {},
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Alicia');
    expect(changes.last, 'Alicia');
  });

  testWidgets('tapping the commander avatar calls onTapCommander',
      (tester) async {
    var tapped = false;
    await tester.pumpApp(
      EditablePlayerTile(
        player: _player(),
        onNameChanged: (_) {},
        onTapCommander: () => tapped = true,
        onTapPartner: () {},
        onRemovePartner: () {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey('edit-commander-p1')));
    expect(tapped, isTrue);
  });

  testWidgets('shows Add partner affordance when no partner is set',
      (tester) async {
    var tapped = false;
    await tester.pumpApp(
      EditablePlayerTile(
        player: _player(),
        onNameChanged: (_) {},
        onTapCommander: () {},
        onTapPartner: () => tapped = true,
        onRemovePartner: () {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey('add-partner-p1')));
    expect(tapped, isTrue);
  });

  testWidgets('shows remove-partner control when a partner is set',
      (tester) async {
    var removed = false;
    await tester.pumpApp(
      EditablePlayerTile(
        player: _player(partner: _commander),
        onNameChanged: (_) {},
        onTapCommander: () {},
        onTapPartner: () {},
        onRemovePartner: () => removed = true,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('remove-partner-p1')));
    expect(removed, isTrue);
  });
}
