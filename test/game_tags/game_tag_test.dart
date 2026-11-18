import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/game_tags/game_tags.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';

void main() {
  group('GameTag catalog', () {
    test('every id is unique snake_case', () {
      final ids = GameTag.values.map((tag) => tag.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$')), reason: id);
      }
    });

    test('ids stay stable', () {
      // Saved games hold these ids. A failure here means a rename that
      // would orphan every tag already in Firestore.
      expect(GameTag.bracket3.id, 'bracket_3');
      expect(GameTag.bracket5.id, 'bracket_5');
      expect(GameTag.t1SolRing.id, 't1_sol_ring');
      expect(GameTag.manaScrewed.id, 'mana_screwed');
      expect(GameTag.koCommanderDamage.id, 'ko_commander_damage');
      expect(GameTag.firstOut.id, 'first_out');
    });

    test('fromId finds a known tag and returns null for an unknown id', () {
      expect(GameTag.fromId('bracket_2'), GameTag.bracket2);
      expect(GameTag.fromId('from_a_newer_app'), isNull);
    });

    test('fromIds keeps catalog order and skips unknown ids', () {
      expect(
        GameTag.fromIds(['first_out', 'unknown', 'bracket_1']),
        [GameTag.bracket1, GameTag.firstOut],
      );
    });

    test('forScope splits the groups into game and player groups', () {
      expect(GameTagGroup.forScope(GameTagScope.game), [
        GameTagGroup.powerLevel,
        GameTagGroup.ending,
        GameTagGroup.pace,
      ]);
      expect(GameTagGroup.forScope(GameTagScope.player), [
        GameTagGroup.mana,
        GameTagGroup.keyPlays,
        GameTagGroup.eliminations,
      ]);
      expect(GameTag.bracket1.scope, GameTagScope.game);
      expect(GameTag.t1SolRing.scope, GameTagScope.player);
    });

    test('every tag is in exactly one group', () {
      final grouped = GameTagGroup.values.expand((group) => group.tags);
      expect(grouped.toList(), GameTag.values);
    });
  });

  group('GameTag.toggleIn', () {
    test('adds a tag that is not selected', () {
      expect(GameTag.t1SolRing.toggleIn(const []), ['t1_sol_ring']);
    });

    test('removes a tag that is selected', () {
      expect(
        GameTag.t1SolRing.toggleIn(const ['t1_sol_ring', 'great_opener']),
        ['great_opener'],
      );
    });

    test('replaces a tag with the same exclusive key', () {
      expect(
        GameTag.bracket3.toggleIn(const ['bracket_2', 'feel_close']),
        ['feel_close', 'bracket_3'],
      );
      expect(
        GameTag.manaFlooded.toggleIn(const ['mana_screwed']),
        ['mana_flooded'],
      );
      expect(GameTag.paceLong.toggleIn(const ['pace_fast']), ['pace_long']);
    });

    test('keeps tags without an exclusive key', () {
      expect(
        GameTag.feelClose.toggleIn(const ['pace_fast']),
        ['pace_fast', 'feel_close'],
      );
      expect(
        GameTag.manaColorScrewed.toggleIn(const ['mana_screwed']),
        ['mana_screwed', 'mana_color_screwed'],
      );
    });

    test('keeps ids this version does not know', () {
      expect(
        GameTag.bracket1.toggleIn(const ['from_a_newer_app']),
        ['from_a_newer_app', 'bracket_1'],
      );
    });
  });

  group('labels', () {
    for (final locale in AppLocalizations.supportedLocales) {
      test('every tag and group has a label in ${locale.languageCode}', () {
        final l10n = lookupAppLocalizations(Locale(locale.languageCode));
        for (final tag in GameTag.values) {
          expect(tag.label(l10n), isNotEmpty, reason: tag.id);
        }
        for (final group in GameTagGroup.values) {
          expect(group.label(l10n), isNotEmpty, reason: group.name);
        }
      });
    }

    test('only the brackets have a tooltip', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(GameTag.bracket2.tooltip(l10n), 'Core');
      expect(GameTag.bracket5.tooltip(l10n), 'Competitive EDH');
      final withTooltip = GameTag.values.where(
        (tag) => tag.tooltip(l10n) != null,
      );
      expect(withTooltip.map((tag) => tag.group).toSet(), {
        GameTagGroup.powerLevel,
      });
    });
  });
}
