import 'weapon_data.dart';
class DamageTargetProfile { final double armor; final Set<DamageType> resistances, weaknesses; const DamageTargetProfile({this.armor = 0, this.resistances = const {}, this.weaknesses = const {}}); }
class DamageSystem {
  static double calculate({required WeaponData weapon, required DamageTargetProfile target, double powerMultiplier = 1, bool critical = false}) {
    var damage = weapon.damage * powerMultiplier;
    damage *= 1 - (target.armor * (1 - weapon.armorPenetration)).clamp(0, .9).toDouble();
    if (target.resistances.contains(weapon.damageType)) damage *= .65;
    if (target.weaknesses.contains(weapon.damageType)) damage *= 1.35;
    if (critical) damage *= 1.75;
    return damage;
  }
}
