import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_head_to_head.dart';
import 'package:magic_yeti/friends_list/friend_stats/view/friend_stats_tiles.dart';

/// Builds a [FriendHeadToHead] from [FriendHeadToHead.empty], overriding only
/// the fields a test cares about.
FriendHeadToHead _stats({
  int sharedPods = 0,
  int youFinishedAhead = 0,
  int theyFinishedAhead = 0,
  int youWon = 0,
  int theyWon = 0,
  int fieldWon = 0,
  double? yourAvgSurvival,
  double? theirAvgSurvival,
  int finalTwoCount = 0,
  int commanderDamageDealt = 0,
  int commanderDamageTaken = 0,
  int lethalBlowsLanded = 0,
  int lethalBlowsTaken = 0,
  String? theirTopCommanderName,
  int theirTopCommanderCount = 0,
}) {
  return FriendHeadToHead(
    sharedPods: sharedPods,
    firstPlayedTogether: null,
    youFinishedAhead: youFinishedAhead,
    theyFinishedAhead: theyFinishedAhead,
    youWon: youWon,
    theyWon: theyWon,
    fieldWon: fieldWon,
    expectedWinsEach: 0,
    yourAvgSurvival: yourAvgSurvival,
    theirAvgSurvival: theirAvgSurvival,
    finalTwoCount: finalTwoCount,
    commanderDamageDealt: commanderDamageDealt,
    commanderDamageTaken: commanderDamageTaken,
    lethalBlowsLanded: lethalBlowsLanded,
    lethalBlowsTaken: lethalBlowsTaken,
    theirTopCommanderName: theirTopCommanderName,
    theirTopCommanderImageUrl: null,
    theirTopCommanderCount: theirTopCommanderCount,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('LedgerHeroTile', () {
    testWidgets('shows the finish record once there are 3+ pods', (
      tester,
    ) async {
      await _pump(
        tester,
        LedgerHeroTile(
          stats: _stats(
            sharedPods: 5,
            youFinishedAhead: 3,
            theyFinishedAhead: 2,
          ),
          friendName: 'Sam',
        ),
      );

      expect(find.text('3–2'), findsOneWidget);
      expect(find.textContaining('you finish ahead in 3 of 5'), findsOneWidget);
    });

    testWidgets('asks for more pods below the sample gate', (tester) async {
      await _pump(
        tester,
        LedgerHeroTile(
          stats: _stats(sharedPods: 2, youFinishedAhead: 2),
          friendName: 'Sam',
        ),
      );

      expect(find.textContaining('Need 3+'), findsOneWidget);
      expect(find.text('2–0'), findsNothing);
    });
  });

  group('buildFriendStatTiles', () {
    testWidgets('hides damage tiles when below their gates', (tester) async {
      final tiles = buildFriendStatTiles(
        _stats(sharedPods: 5, commanderDamageDealt: 4),
      );
      await _pump(tester, Column(children: tiles));

      expect(find.text('The Beatdown'), findsNothing);
      expect(find.text('21s'), findsNothing);
    });

    testWidgets('shows The Beatdown once total flow reaches a clock', (
      tester,
    ) async {
      final tiles = buildFriendStatTiles(
        _stats(
          sharedPods: 5,
          commanderDamageDealt: 18,
          commanderDamageTaken: 6,
        ),
      );
      await _pump(tester, Column(children: tiles));

      expect(find.text('The Beatdown'), findsOneWidget);
      expect(find.text('18 / 6'), findsOneWidget);
    });

    testWidgets('shows 21s only when a lethal blow landed', (tester) async {
      final tiles = buildFriendStatTiles(
        _stats(sharedPods: 5, lethalBlowsLanded: 1),
      );
      await _pump(tester, Column(children: tiles));

      expect(find.text('21s'), findsOneWidget);
      expect(find.text('1 / 0'), findsOneWidget);
    });

    testWidgets('gates Time Alive below five pods', (tester) async {
      final tiles = buildFriendStatTiles(
        _stats(sharedPods: 3, yourAvgSurvival: 0.7, theirAvgSurvival: 0.5),
      );
      await _pump(tester, Column(children: tiles));

      // Time Alive tile present but showing the need-more sentinel.
      expect(find.text('Avg Time Alive'), findsOneWidget);
      expect(find.text('Need 5+'), findsWidgets);
    });

    testWidgets('renders captions under the values', (tester) async {
      final tiles = buildFriendStatTiles(
        _stats(sharedPods: 5, youWon: 3, theyWon: 1, fieldWon: 1),
      );
      await _pump(tester, Column(children: tiles));

      expect(find.text('You · Them · Field'), findsOneWidget);
      expect(find.text('3·1·1'), findsOneWidget);
    });
  });
}
