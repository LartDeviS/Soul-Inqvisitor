import 'weapon_data.dart';

enum AmmoType { standard, sanctified, armorPiercing, warpStabilized, incendiary }

class AmmoProfile {
  final AmmoType id;
  final String nameRu, description;
  final double damageMultiplier, armorPenetrationBonus;
  final bool appliesBurn, antiWarp;
  const AmmoProfile(this.id, this.nameRu, this.description, {this.damageMultiplier=1, this.armorPenetrationBonus=0, this.appliesBurn=false, this.antiWarp=false});
  static const Map<AmmoType, AmmoProfile> all = {
    AmmoType.standard: AmmoProfile(AmmoType.standard, 'Стандартные', 'Надёжные штатные боеприпасы.'),
    AmmoType.sanctified: AmmoProfile(AmmoType.sanctified, 'Освящённые', 'Освящённые заряды для борьбы с варп-сущностями.', damageMultiplier:1.08, antiWarp:true),
    AmmoType.armorPiercing: AmmoProfile(AmmoType.armorPiercing, 'Бронебойные', 'Улучшают пробитие брони ценой части урона.', damageMultiplier:.94, armorPenetrationBonus:.22),
    AmmoType.warpStabilized: AmmoProfile(AmmoType.warpStabilized, 'Стабилизированные против Варпа', 'Стабилизированный заряд с дополнительным эффектом против демонов.', damageMultiplier:1.12, antiWarp:true),
    AmmoType.incendiary: AmmoProfile(AmmoType.incendiary, 'Зажигательные', 'Наносят дополнительный урон органическим целям и оставляют горение.', damageMultiplier:1.04, appliesBurn:true),
  };
  static AmmoProfile byId(AmmoType id) => all[id]!;
  static AmmoType parse(Object? raw) => AmmoType.values.firstWhere((e)=>e.name==raw, orElse:()=>AmmoType.standard);
  bool compatibleWith(DamageType type) => id == AmmoType.standard || id == AmmoType.armorPiercing || (id == AmmoType.sanctified && (type == DamageType.kinetic || type == DamageType.warp)) || (id == AmmoType.warpStabilized && type == DamageType.warp) || (id == AmmoType.incendiary && (type == DamageType.kinetic || type == DamageType.flame));
}
