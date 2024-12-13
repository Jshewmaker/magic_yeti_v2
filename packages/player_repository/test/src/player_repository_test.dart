// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:player_repository/player_repository.dart';

void main() {
  group('PlayerRepository', () {
    test('can be instantiated', () {
      expect(PlayerRepository(), isNotNull);
    });
  });
}
