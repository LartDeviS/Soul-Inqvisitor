/// Data-driven weapon catalog used by the legacy Flame combat loop and new equipment systems.
enum WeaponId { bolter, rifle, shotgun, plasmaGun, staff, stormStaff, warpBeam, daggers, needles, sniperNeedle, meltaGun, flamer, heavyBolter }
enum DamageType { kinetic, plasma, melta, flame, melee, warp, explosive }
class WeaponData {
  final WeaponId id; final String nameRu; final DamageType damageType;
  final double damage, cooldown, range, armorPenetration, spread, projectileSpeed;
  final int pellets, magazine; final bool piercing, areaDamage, appliesBurn;
  const WeaponData(this.id, this.nameRu, {required this.damageType, required this.damage, required this.cooldown, required this.range, this.armorPenetration=0, this.spread=0, this.projectileSpeed=500, this.pellets=1, this.magazine=0, this.piercing=false, this.areaDamage=false, this.appliesBurn=false});
  static const Map<WeaponId,WeaponData> all={
    WeaponId.bolter: WeaponData(WeaponId.bolter,'Болтер',damageType:DamageType.kinetic,damage:8,cooldown:.28,range:520,projectileSpeed:520,magazine:30),
    WeaponId.rifle: WeaponData(WeaponId.rifle,'Лазвинтовка',damageType:DamageType.kinetic,damage:18,cooldown:.55,range:680,projectileSpeed:680,magazine:24),
    WeaponId.shotgun: WeaponData(WeaponId.shotgun,'Боевой дробовик',damageType:DamageType.kinetic,damage:10,cooldown:.72,range:320,spread:.22,pellets:3,projectileSpeed:480,magazine:8),
    WeaponId.plasmaGun: WeaponData(WeaponId.plasmaGun,'Плазмаган',damageType:DamageType.plasma,damage:31,cooldown:.82,range:420,armorPenetration:.45,projectileSpeed:430,magazine:12,piercing:true,areaDamage:true),
    WeaponId.staff: WeaponData(WeaponId.staff,'Психический посох',damageType:DamageType.warp,damage:14,cooldown:.48,range:300,areaDamage:true),
    WeaponId.stormStaff: WeaponData(WeaponId.stormStaff,'Посох бури',damageType:DamageType.warp,damage:13,cooldown:.55,range:280,spread:.35,pellets:3,areaDamage:true),
    WeaponId.warpBeam: WeaponData(WeaponId.warpBeam,'Варп-излучатель',damageType:DamageType.warp,damage:26,cooldown:.70,range:720,armorPenetration:.18,piercing:true,projectileSpeed:720),
    WeaponId.daggers: WeaponData(WeaponId.daggers,'Метательные клинки',damageType:DamageType.kinetic,damage:7,cooldown:.22,range:360,spread:.18,pellets:2,projectileSpeed:560),
    WeaponId.needles: WeaponData(WeaponId.needles,'Игломёт',damageType:DamageType.kinetic,damage:9,cooldown:.32,range:600,spread:.12,pellets:3,projectileSpeed:600),
    WeaponId.sniperNeedle: WeaponData(WeaponId.sniperNeedle,'Снайперский игломёт',damageType:DamageType.kinetic,damage:20,cooldown:.85,range:800,armorPenetration:.30,piercing:true,projectileSpeed:800),
    WeaponId.meltaGun: WeaponData(WeaponId.meltaGun,'Мельтаган',damageType:DamageType.melta,damage:42,cooldown:1.05,range:170,armorPenetration:.72,projectileSpeed:330,magazine:5,piercing:true,areaDamage:true),
    WeaponId.flamer: WeaponData(WeaponId.flamer,'Огнемёт',damageType:DamageType.flame,damage:4,cooldown:.12,range:145,spread:.315,pellets:7,projectileSpeed:270,magazine:100,areaDamage:true,appliesBurn:true),
    WeaponId.heavyBolter: WeaponData(WeaponId.heavyBolter,'Тяжёлый болтер',damageType:DamageType.kinetic,damage:6,cooldown:.20,range:520,spread:.035,pellets:3,projectileSpeed:470,magazine:80),
  };
  static WeaponData forLegacyName(String name) => all.values.firstWhere((w)=>w.id.name==name,orElse:()=>all[WeaponId.bolter]!);
}
