import 'package:json_annotation/json_annotation.dart';

part 'commander_damage.g.dart';

/// Type of damage done to a player.
///
/// [DamageType.commander] - Damage done from the player's commander
/// [DamageType.partner] - Damage done from the player's commander's partner
enum DamageType {
  /// Damage done from the player's commander
  @JsonValue('commander')
  commander,

  /// Damage done from the player's commander's partner
  @JsonValue('partner')
  partner,
}

/// {@template commander_damage}
/// Model representing a damage done by a commander
/// {@endtemplate}
@JsonSerializable(explicitToJson: true)
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
