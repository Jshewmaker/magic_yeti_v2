import 'package:flutter/material.dart';

class GameOverTokens {
  const GameOverTokens._();

  static const background = Color(0xFF080B12);
  static const surface = Color(0xFF0F1320);
  static const surfaceRaised = Color(0xFF161B2E);
  static const border = Color(0xFF1E2640);
  static const accent = Color(0xFF4F8EF7);
  static const gold = Color(0xFFFFB020);
  static const silver = Color(0xFFB0B8CC);
  static const bronze = Color(0xFFCD7F3A);
  static const fourth = Color(0xFF3A4260);
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF7A85A3);

  static Color placementColor(int placement) => switch (placement) {
    1 => gold,
    2 => silver,
    3 => bronze,
    _ => fourth,
  };

  static String placementLabel(int placement) => switch (placement) {
    1 => '1ST',
    2 => '2ND',
    3 => '3RD',
    _ => '4TH',
  };
}
