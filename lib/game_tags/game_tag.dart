/// Whether a tag describes the whole game or one player in it.
enum GameTagScope { game, player }

/// A row of related tags on the tag picker.
enum GameTagGroup {
  powerLevel(GameTagScope.game),
  ending(GameTagScope.game),
  pace(GameTagScope.game),
  mana(GameTagScope.player),
  keyPlays(GameTagScope.player),
  eliminations(GameTagScope.player);

  const GameTagGroup(this.scope);

  final GameTagScope scope;

  /// The tags in this group, in display order.
  List<GameTag> get tags =>
      GameTag.values.where((tag) => tag.group == this).toList();

  /// The groups for [scope], in display order.
  static List<GameTagGroup> forScope(GameTagScope scope) =>
      values.where((group) => group.scope == scope).toList();
}

/// The catalog of tags a game or a player can carry.
///
/// Firestore stores only [id]. Never change or reuse an id: saved games keep
/// it forever, and the stats filter matches on it. To retire a tag, delete
/// the enum value; games that still hold its id keep it untouched (see
/// [toggleIn]) and the UI does not show it.
enum GameTag {
  bracket1('bracket_1', GameTagGroup.powerLevel, exclusiveKey: 'bracket'),
  bracket2('bracket_2', GameTagGroup.powerLevel, exclusiveKey: 'bracket'),
  bracket3('bracket_3', GameTagGroup.powerLevel, exclusiveKey: 'bracket'),
  bracket4('bracket_4', GameTagGroup.powerLevel, exclusiveKey: 'bracket'),
  bracket5('bracket_5', GameTagGroup.powerLevel, exclusiveKey: 'bracket'),

  endCombat('end_combat', GameTagGroup.ending, exclusiveKey: 'ending'),
  endCombo('end_combo', GameTagGroup.ending, exclusiveKey: 'ending'),
  endCommanderDamage(
    'end_commander_damage',
    GameTagGroup.ending,
    exclusiveKey: 'ending',
  ),
  endDrain('end_drain', GameTagGroup.ending, exclusiveKey: 'ending'),
  endPoison('end_poison', GameTagGroup.ending, exclusiveKey: 'ending'),
  endAltWin('end_alt_win', GameTagGroup.ending, exclusiveKey: 'ending'),
  endConceded('end_conceded', GameTagGroup.ending, exclusiveKey: 'ending'),

  paceFast('pace_fast', GameTagGroup.pace, exclusiveKey: 'pace'),
  paceLong('pace_long', GameTagGroup.pace, exclusiveKey: 'pace'),
  feelClose('feel_close', GameTagGroup.pace),

  manaScrewed('mana_screwed', GameTagGroup.mana, exclusiveKey: 'land_count'),
  manaFlooded('mana_flooded', GameTagGroup.mana, exclusiveKey: 'land_count'),
  manaColorScrewed('mana_color_screwed', GameTagGroup.mana),
  greatOpener('great_opener', GameTagGroup.mana),

  t1SolRing('t1_sol_ring', GameTagGroup.keyPlays),
  savedTheTable('saved_the_table', GameTagGroup.keyPlays),
  clutchTopdeck('clutch_topdeck', GameTagGroup.keyPlays),
  commanderTax6('commander_tax_6', GameTagGroup.keyPlays),

  koCommanderDamage('ko_commander_damage', GameTagGroup.eliminations),
  commanderKill('commander_kill', GameTagGroup.eliminations),
  firstOut('first_out', GameTagGroup.eliminations);

  const GameTag(this.id, this.group, {this.exclusiveKey});

  /// The stable id stored in Firestore.
  final String id;

  final GameTagGroup group;

  /// Tags that share a key replace each other: selecting one clears the
  /// others. Null means the tag combines freely with any other tag.
  final String? exclusiveKey;

  GameTagScope get scope => group.scope;

  /// The tag with [id], or null for an id this version does not know.
  static GameTag? fromId(String id) {
    for (final tag in values) {
      if (tag.id == id) return tag;
    }
    return null;
  }

  /// The known tags in [ids], in catalog order. Unknown ids are skipped.
  static List<GameTag> fromIds(Iterable<String> ids) {
    final idSet = ids.toSet();
    return values.where((tag) => idSet.contains(tag.id)).toList();
  }

  /// Returns [ids] with this tag switched on or off.
  ///
  /// Switching on clears any tag with the same [exclusiveKey]. Ids this
  /// version does not know are kept, so an older app never deletes a tag
  /// that a newer app added.
  List<String> toggleIn(List<String> ids) {
    if (ids.contains(id)) {
      return ids.where((other) => other != id).toList();
    }
    final key = exclusiveKey;
    return [
      for (final other in ids)
        if (key == null || fromId(other)?.exclusiveKey != key) other,
      id,
    ];
  }
}
