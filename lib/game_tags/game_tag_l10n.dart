import 'package:magic_yeti/game_tags/game_tag.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';

extension GameTagL10n on GameTag {
  /// The pill text for this tag.
  String label(AppLocalizations l10n) => switch (this) {
    GameTag.bracket1 => l10n.tagBracket1,
    GameTag.bracket2 => l10n.tagBracket2,
    GameTag.bracket3 => l10n.tagBracket3,
    GameTag.bracket4 => l10n.tagBracket4,
    GameTag.bracket5 => l10n.tagBracket5,
    GameTag.endCombat => l10n.tagEndCombat,
    GameTag.endCombo => l10n.tagEndCombo,
    GameTag.endCommanderDamage => l10n.tagEndCommanderDamage,
    GameTag.endDrain => l10n.tagEndDrain,
    GameTag.endPoison => l10n.tagEndPoison,
    GameTag.endAltWin => l10n.tagEndAltWin,
    GameTag.endConceded => l10n.tagEndConceded,
    GameTag.paceFast => l10n.tagPaceFast,
    GameTag.paceLong => l10n.tagPaceLong,
    GameTag.feelClose => l10n.tagFeelClose,
    GameTag.manaScrewed => l10n.tagManaScrewed,
    GameTag.manaFlooded => l10n.tagManaFlooded,
    GameTag.manaColorScrewed => l10n.tagManaColorScrewed,
    GameTag.greatOpener => l10n.tagGreatOpener,
    GameTag.t1SolRing => l10n.tagT1SolRing,
    GameTag.savedTheTable => l10n.tagSavedTheTable,
    GameTag.clutchTopdeck => l10n.tagClutchTopdeck,
    GameTag.commanderTax6 => l10n.tagCommanderTax6,
    GameTag.koCommanderDamage => l10n.tagKoCommanderDamage,
    GameTag.commanderKill => l10n.tagCommanderKill,
    GameTag.firstOut => l10n.tagFirstOut,
  };

  /// Extra detail shown on long press, or null when the label says it all.
  String? tooltip(AppLocalizations l10n) => switch (this) {
    GameTag.bracket1 => l10n.tagBracket1Tooltip,
    GameTag.bracket2 => l10n.tagBracket2Tooltip,
    GameTag.bracket3 => l10n.tagBracket3Tooltip,
    GameTag.bracket4 => l10n.tagBracket4Tooltip,
    GameTag.bracket5 => l10n.tagBracket5Tooltip,
    _ => null,
  };
}

extension GameTagGroupL10n on GameTagGroup {
  String label(AppLocalizations l10n) => switch (this) {
    GameTagGroup.powerLevel => l10n.tagGroupPowerLevel,
    GameTagGroup.ending => l10n.tagGroupEnding,
    GameTagGroup.pace => l10n.tagGroupPace,
    GameTagGroup.mana => l10n.tagGroupMana,
    GameTagGroup.keyPlays => l10n.tagGroupKeyPlays,
    GameTagGroup.eliminations => l10n.tagGroupEliminations,
  };
}
