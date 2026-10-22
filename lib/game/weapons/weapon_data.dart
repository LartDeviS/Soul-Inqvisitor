/// Data-driven weapon catalog used by the legacy Flame combat loop and expansion systems.
enum WeaponId {
  bolter, rifle, shotgun, plasmaGun, staff, stormStaff, warpBeam, daggers,
  needles, sniperNeedle, meltaGun, flamer, heavyBolter,
  // Ordo Malleus additions
  psycannon, exorcistIncinerator, daemonbanePistol,
  // Ordo Hereticus additions
  condemnorBoltgun, sanctifiedStakeCrossbow, infernoPistol,
}
enum DamageType { kinetic, plasma, melta, flame, melee, warp, explosive }
enum WeaponOrdo { common, xenos, malleus, hereticus }

class WeaponData {
  final WeaponId id;
  final String nameRu;
  final DamageType damageType;
  final double damage, cooldown, range, armorPenetration, spread, projectileSpeed;
  final int pellets, magazine;
  final bool piercing, areaDamage, appliesBurn;
  final WeaponOrdo ordo;
  final String description;
  const WeaponData(this.id, this.nameRu, {
    required this.damageType, required this.damage, required this.cooldown,
    required this.range, this.armorPenetration=0, this.spread=0,
    this.projectileSpeed=500, this.pellets=1, this.magazine=0,
    this.piercing=false, this.areaDamage=false, this.appliesBurn=false,
    this.ordo=WeaponOrdo.common, this.description='',
  });

  static const Map<WeaponId, WeaponData> all = {
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
    WeaponId.psycannon: WeaponData(WeaponId.psycannon,'Психопушка Маллеус',damageType:DamageType.warp,damage:30,cooldown:.68,range:650,armorPenetration:.38,projectileSpeed:660,magazine:18,piercing:true,ordo:WeaponOrdo.malleus,description:'Тяжёлые психически заряженные снаряды, особенно эффективные против варп-сущностей.'),
    WeaponId.exorcistIncinerator: WeaponData(WeaponId.exorcistIncinerator,'Экзорцистский инцинератор',damageType:DamageType.flame,damage:7,cooldown:.18,range:190,spread:.25,pellets:5,projectileSpeed:300,magazine:70,areaDamage:true,appliesBurn:true,ordo:WeaponOrdo.malleus,description:'Короткий веер очищающего пламени для срыва атак и уничтожения скоплений демонов.'),
    WeaponId.daemonbanePistol: WeaponData(WeaponId.daemonbanePistol,'Пистолет «Губитель демонов»',damageType:DamageType.warp,damage:24,cooldown:.48,range:390,armorPenetration:.28,projectileSpeed:560,magazine:10,piercing:true,ordo:WeaponOrdo.malleus,description:'Компактное оружие с антиварп-боеприпасом; точный выстрел с умеренной скорострельностью.'),
    WeaponId.condemnorBoltgun: WeaponData(WeaponId.condemnorBoltgun,'Осудительный болтер',damageType:DamageType.kinetic,damage:25,cooldown:.72,range:610,armorPenetration:.20,projectileSpeed:650,magazine:18,piercing:true,ordo:WeaponOrdo.hereticus,description:'Болтер с особым осудительным зарядом для поражения опасных псайкеров.'),
    WeaponId.sanctifiedStakeCrossbow: WeaponData(WeaponId.sanctifiedStakeCrossbow,'Арбалет освящённых кольев',damageType:DamageType.kinetic,damage:22,cooldown:.82,range:560,armorPenetration:.32,projectileSpeed:740,magazine:6,piercing:true,ordo:WeaponOrdo.hereticus,description:'Точный одиночный выстрел; пробивает броню и вознаграждает аккуратное прицеливание.'),
    WeaponId.infernoPistol: WeaponData(WeaponId.infernoPistol,'Инферно-пистолет',damageType:DamageType.melta,damage:38,cooldown:.95,range:210,armorPenetration:.65,projectileSpeed:380,magazine:5,piercing:true,areaDamage:true,ordo:WeaponOrdo.hereticus,description:'Крайне мощный пистолет короткой дистанции с малым магазином.'),
  };

  static WeaponData forLegacyName(String name) => all.values.firstWhere((w)=>w.id.name==name,orElse:()=>all[WeaponId.bolter]!);
}
