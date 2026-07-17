import 'package:equatable/equatable.dart';

/// Aggregated head-to-head statistics between the signed-in user and one
/// friend, computed over the pods the two of them have shared.
///
/// Every field is a raw count or a simple average — never a percentage. At the
/// small samples this screen operates on (a friend pair may have 3–15 shared
/// pods ever), counts are honest where rates would imply precision that isn't
/// there. See the design note for the reasoning:
/// docs/superpowers/specs/2026-07-17-friend-head-to-head-stats-design.md
class FriendHeadToHead extends Equatable {
  const FriendHeadToHead({
    required this.sharedPods,
    required this.firstPlayedTogether,
    required this.youFinishedAhead,
    required this.theyFinishedAhead,
    required this.youWon,
    required this.theyWon,
    required this.fieldWon,
    required this.expectedWinsEach,
    required this.yourAvgSurvival,
    required this.theirAvgSurvival,
    required this.finalTwoCount,
    required this.commanderDamageDealt,
    required this.commanderDamageTaken,
    required this.lethalBlowsLanded,
    required this.lethalBlowsTaken,
    required this.theirTopCommanderName,
    required this.theirTopCommanderImageUrl,
    required this.theirTopCommanderCount,
  });

  /// The zero-state: no shared pods, nothing to show.
  static const empty = FriendHeadToHead(
    sharedPods: 0,
    firstPlayedTogether: null,
    youFinishedAhead: 0,
    theyFinishedAhead: 0,
    youWon: 0,
    theyWon: 0,
    fieldWon: 0,
    expectedWinsEach: 0,
    yourAvgSurvival: null,
    theirAvgSurvival: null,
    finalTwoCount: 0,
    commanderDamageDealt: 0,
    commanderDamageTaken: 0,
    lethalBlowsLanded: 0,
    lethalBlowsTaken: 0,
    theirTopCommanderName: null,
    theirTopCommanderImageUrl: null,
    theirTopCommanderCount: 0,
  );

  /// Number of pods both accounts played in together.
  final int sharedPods;

  /// Start time of the earliest shared pod, or null if there are none.
  final DateTime? firstPlayedTogether;

  /// Pods where you outlasted the friend (finished ahead by time of death).
  final int youFinishedAhead;

  /// Pods where the friend outlasted you.
  final int theyFinishedAhead;

  /// Pods you won.
  final int youWon;

  /// Pods the friend won.
  final int theyWon;

  /// Pods won by someone other than the two of you.
  final int fieldWon;

  /// Expected wins for one player if every shared pod were a coin flip against
  /// its own pod size — i.e. the sum of `1 / podSize`. Used to contextualise
  /// [youWon]/[theyWon] against the multiplayer baseline (25% in a 4-pod).
  final double expectedWinsEach;

  /// Mean fraction of the pod's wall-clock window you survived (0..1), or null
  /// if there are no shared pods.
  final double? yourAvgSurvival;

  /// Mean fraction of the pod's wall-clock window the friend survived (0..1).
  final double? theirAvgSurvival;

  /// Pods where the two of you were the last two standing.
  final int finalTwoCount;

  /// Total commander-damage volume you dealt to the friend across shared pods
  /// (both commander and partner clocks summed).
  final int commanderDamageDealt;

  /// Total commander-damage volume the friend dealt to you.
  final int commanderDamageTaken;

  /// Shared pods where a single one of your clocks put 21+ into the friend.
  final int lethalBlowsLanded;

  /// Shared pods where a single one of the friend's clocks put 21+ into you.
  final int lethalBlowsTaken;

  /// The friend's most-played commander name across shared pods, or null.
  final String? theirTopCommanderName;

  /// Art for [theirTopCommanderName], if available.
  final String? theirTopCommanderImageUrl;

  /// How many shared pods the friend brought [theirTopCommanderName].
  final int theirTopCommanderCount;

  /// The Ledger and Pods Won need a real sample before a count reads as a
  /// pattern rather than the match list with extra steps.
  bool get hasEnoughForLedger => sharedPods >= 3;

  /// Time Alive is a mean; below 5 pods an average is too jumpy to show.
  bool get hasEnoughForSurvival => sharedPods >= 5;

  /// Final Two has a ~1/6 baseline; below 5 pods one occurrence looks like a
  /// trend.
  bool get hasEnoughForFinalTwo => sharedPods >= 5;

  /// Their Go-To needs a modal commander to exist.
  bool get hasEnoughForTopCommander =>
      sharedPods >= 3 && theirTopCommanderName != null;

  /// Commander damage is archetype-sparse; hide the trade entirely below one
  /// clock's worth of total flow rather than showing a rivalry of zeroes.
  bool get hasBeatdown => (commanderDamageDealt + commanderDamageTaken) >= 21;

  /// Only surface 21s when at least one actually happened.
  bool get hasLethalBlows => (lethalBlowsLanded + lethalBlowsTaken) >= 1;

  @override
  List<Object?> get props => [
    sharedPods,
    firstPlayedTogether,
    youFinishedAhead,
    theyFinishedAhead,
    youWon,
    theyWon,
    fieldWon,
    expectedWinsEach,
    yourAvgSurvival,
    theirAvgSurvival,
    finalTwoCount,
    commanderDamageDealt,
    commanderDamageTaken,
    lethalBlowsLanded,
    lethalBlowsTaken,
    theirTopCommanderName,
    theirTopCommanderImageUrl,
    theirTopCommanderCount,
  ];
}
