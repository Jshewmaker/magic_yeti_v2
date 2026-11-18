// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commander_damage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommanderDamage _$CommanderDamageFromJson(Map<String, dynamic> json) =>
    CommanderDamage(
      damageType: $enumDecode(_$DamageTypeEnumMap, json['damageType']),
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$CommanderDamageToJson(CommanderDamage instance) =>
    <String, dynamic>{
      'damageType': _$DamageTypeEnumMap[instance.damageType]!,
      'amount': instance.amount,
    };

const _$DamageTypeEnumMap = {
  DamageType.commander: 'commander',
  DamageType.partner: 'partner',
};
