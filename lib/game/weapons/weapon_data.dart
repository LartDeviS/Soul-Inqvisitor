enum WeaponId { bolter, plasmaGun, melta, flamer, heavyBolter, chainsword, powerSword }
enum DamageType { kinetic, plasma, melta, flame, melee, warp }
class WeaponData {
  final WeaponId id; final String name; final DamageType damageType; final double damage, cooldown, range, armorPenetration; final int magazine; final bool overheats, areaDamage;
  const WeaponData(this.id, this.name, {required this.damageType, required this.damage, required this.cooldown, required this.range, this.armorPenetration = 0, this.magazine = 30, this.overheats = false, this.areaDamage = false});
  static const all = <WeaponId, WeaponData>{
    WeaponId.bolter: WeaponData(WeaponId.bolter, 'Болтер', damageType: DamageType.kinetic, damage: 18, cooldown: .32, range: 480, magazine: 30),
    WeaponId.plasmaGun: WeaponData(WeaponId.plasmaGun, 'Плазмаган', damageType: DamageType.plasma, damage: 42, cooldown: .82, range: 420, armorPenetration: .45, magazine: 12, overheats: true, areaDamage: true),
    WeaponId.melta: WeaponData(WeaponId.melta, 'Мельтаган', damageType: DamageType.melta, damage: 68, cooldown: 1.1, range: 170, armorPenetration: .7, magazine: 5),
    WeaponId.flamer: WeaponData(WeaponId.flamer, 'Огнемёт', damageType: DamageType.flame, damage: 9, cooldown: .12, range: 145, areaDamage: true, magazine: 100),
    WeaponId.heavyBolter: WeaponData(WeaponId.heavyBolter, 'Тяжёлый болтер', damageType: DamageType.kinetic, damage: 24, cooldown: .22, range: 520, magazine: 80),
    WeaponId.chainsword: WeaponData(WeaponId.chainsword, 'Цепной меч', damageType: DamageType.melee, damage: 32, cooldown: .55, range: 55, armorPenetration: .15, magazine: 0),
    WeaponId.powerSword: WeaponData(WeaponId.powerSword, 'Силовой меч', damageType: DamageType.melee, damage: 48, cooldown: .72, range: 62, armorPenetration: .4, magazine: 0),
  };
}
