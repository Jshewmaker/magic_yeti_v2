import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:player_repository/player_repository.dart';

Commander c(String name) => Commander(
      oracleId: name,
      name: name,
      colors: const ['B'],
      cardType: 'Legendary',
      imageUrl: 'https://e/$name.jpg',
      manaCost: '',
      oracleText: '',
      artist: 'A',
    );

void main() {
  test('a player with only a background has a single damage clock', () {
    final state = PlayerCustomizationState(
      commander: c('Wilson'),
      background: c('Cult of Rakdos'),
      availablePairing: CommanderPairing.background,
    );
    expect(state.partner, isNull);
    expect(state.damageClocks, 1);
  });

  test('a player with a partner has two damage clocks', () {
    final state = PlayerCustomizationState(
      commander: c('Commander'),
      partner: c('Partner'),
      availablePairing: CommanderPairing.partner,
    );
    expect(state.damageClocks, 2);
  });
}
