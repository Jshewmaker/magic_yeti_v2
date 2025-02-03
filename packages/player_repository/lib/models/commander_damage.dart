import 'package:json_annotation/json_annotation.dart';
import 'package:player_repository/models/player.dart';
import 'package:player_repository/player_repository.dart';

part 'commander_damage.g.dart';

/// {@template commander_damage}
/// Model representing a damage done by a commander
/// {@endtemplate}
@JsonSerializable()
class CommanderDamage {
  /// {@macro commander_damage}
  CommanderDamage({required this.damageType, required this.amount});

  /// Connect the generated [_$CommanderDamageFromJson] function to the `fromJson`
  factory CommanderDamage.fromJson(Map<String, dynamic> json) =>
      _$CommanderDamageFromJson(json);

  /// The type of damage done
  final DamageType damageType;

  /// The amount of damage done
  final int amount;

  /// Connect the generated [_$CommanderDamageToJson] function to the `toJson`
  Map<String, dynamic> toJson() => _$CommanderDamageToJson(this);

  /// Creates a new instance of the `CommanderDamage` class with the same values
  /// as the current instance
  CommanderDamage copyWith({
    DamageType? damageType,
    int? amount,
  }) =>
      CommanderDamage(
        damageType: damageType ?? this.damageType,
        amount: amount ?? this.amount,
      );
}
