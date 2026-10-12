import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── ENUMS ───────────────────────────────────────────────────

enum Difficulty { easy, normal, hard }

extension DiffLabel on Difficulty {
  String get labelRu {
    switch (this) {
      case Difficulty.easy:
        return 'Легко';
      case Difficulty.normal:
        return 'Норма';
      case Difficulty.hard:
        return 'Хард';
    }
  }

  int get maxFloors {
    switch (this) {
      case Difficulty.easy:
        return 5;
      case Difficulty.normal:
        return 7;
      case Difficulty.hard:
        return 10;
    }
  }

  int get maxOverallLevels => maxFloors * 5;

  double get hpMult {
    switch (this) {
      case Difficulty.easy:
        return 0.75;
      case Difficulty.normal:
        return 1.15;
      case Difficulty.hard:
        return 1.70;
    }
  }

  double get dmgMult {
    switch (this) {
      case Difficulty.easy:
        return 0.70;
      case Difficulty.normal:
        return 1.05;
      case Difficulty.hard:
        return 1.45;
    }
  }

  double get bossHpMult {
    switch (this) {
      case Difficulty.easy:
        return 0.80;
      case Difficulty.normal:
        return 1.20;
      case Difficulty.hard:
        return 1.85;
    }
  }
}

enum PlayerClass { xenos, malleus, hereticus }

extension ClassLabel on PlayerClass {
  String get title {
    switch (this) {
      case PlayerClass.xenos:
        return 'Ordo Xenos';
      case PlayerClass.malleus:
        return 'Ordo Malleus';
      case PlayerClass.hereticus:
        return 'Ordo Hereticus';
    }
  }

  String get subtitle {
    switch (this) {
      case PlayerClass.xenos:
        return 'Болтер, винтовка, дробовик';
      case PlayerClass.malleus:
        return 'Псайкер: посох и варп Ψ';
      case PlayerClass.hereticus:
        return 'Ассасин: рывок и клинки';
    }
  }
}

enum RangedWeapon {
  bolter,
  rifle,
  shotgun,
  staff,
  stormStaff,
  warpBeam,
  daggers,
  needles,
  sniperNeedle,
}

enum MeleeWeapon {
  sword,
  axe,
  hammer,
  forceBlade,
  forceSword,
  daemonHammer,
  katana,
  powerKatana,
  executioner,
}

enum EnemyType {
  shooter,
  melee,
  shielded,
  dog,
  shieldedShooter,
  flamer,
  sniper,
  brute,
  cultPsyker,
  plagueBearer,
  bloodletter,
}

enum StatusType { burn, bleed, slow, corruption, plague }

enum ActiveArtifact { fragGrenade, holyAura, servoTurret }

enum RelicId {
  crit,
  lifesteal,
  shieldPierce,
  killExplosion,
  haste,
  jediPath,
  ammoSavant,
  warpAnchor,
  shadowStep,
  ironWill,
  executionerMark,
  scavenger,
}

extension RelicMeta on RelicId {
  String get title {
    switch (this) {
      case RelicId.crit:
        return 'Око Императора';
      case RelicId.lifesteal:
        return 'Кровавая печать';
      case RelicId.shieldPierce:
        return 'Иглы веры';
      case RelicId.killExplosion:
        return 'Разряд очищения';
      case RelicId.haste:
        return 'Шаги святого';
      case RelicId.jediPath:
        return 'Путь Джедая';
      case RelicId.ammoSavant:
        return 'Арсенал Адептус';
      case RelicId.warpAnchor:
        return 'Якорь Варпа';
      case RelicId.shadowStep:
        return 'Тень аколита';
      case RelicId.ironWill:
        return 'Железная воля';
      case RelicId.executionerMark:
        return 'Метка палача';
      case RelicId.scavenger:
        return 'Сборщик трофеев';
    }
  }
}

enum CodexId {
  shooter,
  melee,
  shielded,
  dog,
  shieldedShooter,
  flamer,
  sniper,
  brute,
  cultPsyker,
  plagueBearer,
  bloodletter,
  miniBoss,
  boss,
  knight,
  king,
  tentacle,
  cyclops,
  champion,
  plagueLord,
  bloodChampion,
}

extension CodexMeta on CodexId {
  String get title {
    switch (this) {
      case CodexId.shooter:
        return 'Культист-стрелок';
      case CodexId.melee:
        return 'Культист-клинок';
      case CodexId.shielded:
        return 'Еретик со щитом';
      case CodexId.dog:
        return 'Хаос-гончая';
      case CodexId.shieldedShooter:
        return 'Щитовой стрелок';
      case CodexId.flamer:
        return 'Огнемётчик';
      case CodexId.sniper:
        return 'Снайпер';
      case CodexId.brute:
        return 'Зверь культа';
      case CodexId.cultPsyker:
        return 'Культист-псайкер';
      case CodexId.plagueBearer:
        return 'Носитель чумы';
      case CodexId.bloodletter:
        return 'Кровопускатель';
      case CodexId.miniBoss:
        return 'Мини-босс';
      case CodexId.boss:
        return 'Чемпион ереси';
      case CodexId.knight:
        return 'Рыцарь-отступник';
      case CodexId.king:
        return 'Король еретиков';
      case CodexId.tentacle:
        return 'Тентаклевый ужас';
      case CodexId.cyclops:
        return 'Циклоп Варпа';
      case CodexId.champion:
        return 'Чемпион-элита';
      case CodexId.plagueLord:
        return 'Повелитель чумы';
      case CodexId.bloodChampion:
        return 'Кровавый чемпион';
    }
  }

  String get lore {
    switch (this) {
      case CodexId.shooter:
        return 'Кустарные болтеры культа. Держат дистанцию.';
      case CodexId.melee:
        return 'Клинок — молитва Кхорну. Не дай им коснуться.';
      case CodexId.shielded:
        return 'Щит из обломков. Бей ближним.';
      case CodexId.dog:
        return 'Быстрые твари из ульев.';
      case CodexId.shieldedShooter:
        return 'Щит и очередь — двойная угроза.';
      case CodexId.flamer:
        return 'Прометий культа. Не стой в огне.';
      case CodexId.sniper:
        return 'Один выстрел — один труп.';
      case CodexId.brute:
        return 'Толстая броня, тяжёлый удар.';
      case CodexId.cultPsyker:
        return 'Волны варпа. Приоритет ликвидации.';
      case CodexId.plagueBearer:
        return 'Чума при касании. Огонь и вера.';
      case CodexId.bloodletter:
        return 'Жаждут ближнего боя.';
      case CodexId.miniBoss:
        return 'Дробовик-лейтенант культа.';
      case CodexId.boss:
        return 'Залпы кольцом/конусом/крестом.';
      case CodexId.knight:
        return 'Рывок и удар в упор.';
      case CodexId.king:
        return 'Неуязвим, пока жива свита.';
      case CodexId.tentacle:
        return 'Секрет: угол 33с. 6666 HP.';
      case CodexId.cyclops:
        return 'Секрет: лазер из глаза.';
      case CodexId.champion:
        return 'Элита с аффиксом.';
      case CodexId.plagueLord:
        return 'Реген и призыв чумы.';
      case CodexId.bloodChampion:
        return 'Ярость растёт с потерей HP.';
    }
  }

  String get knowledgeBonus {
    switch (this) {
      case CodexId.shooter:
      case CodexId.sniper:
        return '+2% урон по стрелкам';
      case CodexId.melee:
      case CodexId.dog:
      case CodexId.brute:
      case CodexId.bloodletter:
        return '+2% урон в ближнем';
      case CodexId.shielded:
      case CodexId.shieldedShooter:
        return '+3% пробитие щитов';
      case CodexId.flamer:
      case CodexId.plagueBearer:
        return '+1с к DoT';
      case CodexId.cultPsyker:
        return '+5% сопротивление варпу';
      case CodexId.champion:
        return '+5% обломков с элит';
      case CodexId.boss:
      case CodexId.knight:
      case CodexId.king:
      case CodexId.miniBoss:
      case CodexId.plagueLord:
      case CodexId.bloodChampion:
        return '+3% урон боссам';
      case CodexId.tentacle:
      case CodexId.cyclops:
        return '+1 SP за секрет';
    }
  }
}

enum EliteAffix { none, swift, regenerating, explosive, reflect, summoner }

extension AffixMeta on EliteAffix {
  String get letter {
    switch (this) {
      case EliteAffix.none:
        return '';
      case EliteAffix.swift:
        return 'S';
      case EliteAffix.regenerating:
        return 'R';
      case EliteAffix.explosive:
        return 'E';
      case EliteAffix.reflect:
        return 'F';
      case EliteAffix.summoner:
        return 'N';
    }
  }

  Color get color {
    switch (this) {
      case EliteAffix.none:
        return Colors.transparent;
      case EliteAffix.swift:
        return const Color(0xFF00E5FF);
      case EliteAffix.regenerating:
        return const Color(0xFF69F0AE);
      case EliteAffix.explosive:
        return const Color(0xFFFF6D00);
      case EliteAffix.reflect:
        return const Color(0xFFE040FB);
      case EliteAffix.summoner:
        return const Color(0xFFFFEB3B);
    }
  }
}

enum PathNodeKind { combat, event, elite, rest, boss }
enum EventRoomType { none, altar, merchant, trap }
enum EchoBossKind { none, mini, ranged, knight, king, plague, blood }
enum BulletMod { normal, slow, ricochet, split }
enum GunBarrelMod { none, rapid, heavy }
enum GunSightMod { none, precision, wide }
enum GunAmmoMod { none, ricochet, explosive, pierce }
enum StaffFocusMod { none, wideSphere, focusCore, dissipator }
enum BladeEdgeMod { none, serrated, monomolecular, weighted }
enum RankPerk { none, startSp, scrapBonus }
enum RankChallenge { none, meleeBossOnly, noDash }
enum RewardKind { skillPoint, scraps, heal, relic }

extension ChallengeMeta on RankChallenge {
  String get title {
    switch (this) {
      case RankChallenge.none:
        return 'Без испытания';
      case RankChallenge.meleeBossOnly:
        return 'Клинок Императора';
      case RankChallenge.noDash:
        return 'Стоять насмерть';
    }
  }

  String get desc {
    switch (this) {
      case RankChallenge.none:
        return 'Обычный забег';
      case RankChallenge.meleeBossOnly:
        return 'Боссов — только ближний. +ранг.';
      case RankChallenge.noDash:
        return 'Рывок U запрещён. +ранг.';
    }
  }
}

enum AchievementId {
  firstBlood,
  noKills,
  bossSlayer,
  secretTentacle,
  secretCyclops,
  clearEasy,
  clearNormal,
  clearHard,
  arena50,
  arena100,
  combo15,
  fullCodex,
  allClasses,
  ironWillProc,
  relicHunter,
  scrapHoarder,
  timedPortal,
  championHunter,
}

extension AchievementX on AchievementId {
  String get title {
    switch (this) {
      case AchievementId.firstBlood:
        return 'Первая кровь';
      case AchievementId.noKills:
        return 'Без убийств';
      case AchievementId.bossSlayer:
        return 'Убийца лордов';
      case AchievementId.secretTentacle:
        return 'Ужас из угла';
      case AchievementId.secretCyclops:
        return 'Глаз Циклопа';
      case AchievementId.clearEasy:
        return 'Испытание (Лёгко)';
      case AchievementId.clearNormal:
        return 'Испытание (Норма)';
      case AchievementId.clearHard:
        return 'Испытание (Хард)';
      case AchievementId.arena50:
        return 'Арена: 50';
      case AchievementId.arena100:
        return 'Арена: 100';
      case AchievementId.combo15:
        return 'Комбо x15';
      case AchievementId.fullCodex:
        return 'Полный кодекс';
      case AchievementId.allClasses:
        return 'Три ордо';
      case AchievementId.ironWillProc:
        return 'Железная воля';
      case AchievementId.relicHunter:
        return 'Охотник за реликвиями';
      case AchievementId.scrapHoarder:
        return 'Сборщик обломков';
      case AchievementId.timedPortal:
        return 'Терпение Императора';
      case AchievementId.championHunter:
        return 'Охотник на чемпионов';
    }
  }

  String get desc {
    switch (this) {
      case AchievementId.firstBlood:
        return 'Убейте любого врага';
      case AchievementId.noKills:
        return '5 мин без убийств + уход порталом';
      case AchievementId.bossSlayer:
        return 'Победите любого босса';
      case AchievementId.secretTentacle:
        return 'Секрет 1–5, угол 33с';
      case AchievementId.secretCyclops:
        return 'Секрет 2–5 / 10, угол 33с';
      case AchievementId.clearEasy:
        return 'Пройдите кампанию на Лёгком';
      case AchievementId.clearNormal:
        return 'Пройдите на Норме';
      case AchievementId.clearHard:
        return 'Пройдите на Харде';
      case AchievementId.arena50:
        return '50 убийств на арене';
      case AchievementId.arena100:
        return '100 убийств на арене';
      case AchievementId.combo15:
        return 'Комбо x15';
      case AchievementId.fullCodex:
        return 'Все записи кодекса';
      case AchievementId.allClasses:
        return 'Сыграйте всеми ордо';
      case AchievementId.ironWillProc:
        return 'Сработала Железная воля';
      case AchievementId.relicHunter:
        return '5 реликвий за забег';
      case AchievementId.scrapHoarder:
        return '100 обломков за забег';
      case AchievementId.timedPortal:
        return 'Портал через 5 минут';
      case AchievementId.championHunter:
        return '10 чемпионов суммарно';
    }
  }
}

// ─── HUD LAYOUT ──────────────────────────────────────────────

class HudLayout {
  double joystickSize;
  double buttonSize;
  double moveX, moveY, atkX, atkY;
  double settingsX, settingsY, backpackX, backpackY;
  double dashX, dashY, laserX, laserY, artifactX, artifactY;
  double warpX, warpY, portalBtnX, portalBtnY;

  HudLayout({
    this.joystickSize = 90,
    this.buttonSize = 42,
    this.moveX = 0.12,
    this.moveY = 0.18,
    this.atkX = 0.88,
    this.atkY = 0.18,
    this.settingsX = 0.94,
    this.settingsY = 0.08,
    this.backpackX = 0.82,
    this.backpackY = 0.08,
    this.dashX = 0.72,
    this.dashY = 0.32,
    this.laserX = 0.80,
    this.laserY = 0.32,
    this.artifactX = 0.88,
    this.artifactY = 0.38,
    this.warpX = 0.64,
    this.warpY = 0.32,
    this.portalBtnX = 0.50,
    this.portalBtnY = 0.88,
  });

  void reset() {
    joystickSize = 90;
    buttonSize = 42;
    moveX = 0.12;
    moveY = 0.18;
    atkX = 0.88;
    atkY = 0.18;
    settingsX = 0.94;
    settingsY = 0.08;
    backpackX = 0.82;
    backpackY = 0.08;
    dashX = 0.72;
    dashY = 0.32;
    laserX = 0.80;
    laserY = 0.32;
    artifactX = 0.88;
    artifactY = 0.38;
    warpX = 0.64;
    warpY = 0.32;
    portalBtnX = 0.50;
    portalBtnY = 0.88;
  }

  Map<String, dynamic> toJson() => {
        'js': joystickSize,
        'bs': buttonSize,
        'mx': moveX,
        'my': moveY,
        'ax': atkX,
        'ay': atkY,
        'sx': settingsX,
        'sy': settingsY,
        'bx': backpackX,
        'by': backpackY,
        'dx': dashX,
        'dy': dashY,
        'lx': laserX,
        'ly': laserY,
        'arx': artifactX,
        'ary': artifactY,
        'wx': warpX,
        'wy': warpY,
        'px': portalBtnX,
        'py': portalBtnY,
      };

  factory HudLayout.fromJson(Map<String, dynamic>? j) {
    if (j == null) return HudLayout();
    return HudLayout(
      joystickSize: (j['js'] as num?)?.toDouble() ?? 90,
      buttonSize: (j['bs'] as num?)?.toDouble() ?? 42,
      moveX: (j['mx'] as num?)?.toDouble() ?? 0.12,
      moveY: (j['my'] as num?)?.toDouble() ?? 0.18,
      atkX: (j['ax'] as num?)?.toDouble() ?? 0.88,
      atkY: (j['ay'] as num?)?.toDouble() ?? 0.18,
      settingsX: (j['sx'] as num?)?.toDouble() ?? 0.94,
      settingsY: (j['sy'] as num?)?.toDouble() ?? 0.08,
      backpackX: (j['bx'] as num?)?.toDouble() ?? 0.82,
      backpackY: (j['by'] as num?)?.toDouble() ?? 0.08,
      dashX: (j['dx'] as num?)?.toDouble() ?? 0.72,
      dashY: (j['dy'] as num?)?.toDouble() ?? 0.32,
      laserX: (j['lx'] as num?)?.toDouble() ?? 0.80,
      laserY: (j['ly'] as num?)?.toDouble() ?? 0.32,
      artifactX: (j['arx'] as num?)?.toDouble() ?? 0.88,
      artifactY: (j['ary'] as num?)?.toDouble() ?? 0.38,
      warpX: (j['wx'] as num?)?.toDouble() ?? 0.64,
      warpY: (j['wy'] as num?)?.toDouble() ?? 0.32,
      portalBtnX: (j['px'] as num?)?.toDouble() ?? 0.50,
      portalBtnY: (j['py'] as num?)?.toDouble() ?? 0.88,
    );
  }
}

// ─── DATA CLASSES (с явными конструкторами!) ─────────────────

class SkillTree {
  int hp = 0, speed = 0, attackSpeed = 0, defense = 0, damage = 0;
  SkillTree(); // обязательно

  Map<String, dynamic> toJson() => {
        'hp': hp,
        'sp': speed,
        'as': attackSpeed,
        'df': defense,
        'dm': damage,
      };

  factory SkillTree.fromJson(Map<String, dynamic>? j) {
    if (j == null) return SkillTree();
    return SkillTree()
      ..hp = j['hp'] as int? ?? 0
      ..speed = j['sp'] as int? ?? 0
      ..attackSpeed = j['as'] as int? ?? 0
      ..defense = j['df'] as int? ?? 0
      ..damage = j['dm'] as int? ?? 0;
  }
}

class Customization {
  int armorHue = 0;
  int capeHue = 0;
  int weaponHue = 200;
  Customization(); // обязательно

  Color armorColor([double s = 0.35]) =>
      HSLColor.fromAHSL(1, armorHue.toDouble(), s, 0.35).toColor();
  Color capeColor([double s = 0.55]) =>
      HSLColor.fromAHSL(1, capeHue.toDouble(), s, 0.4).toColor();
  Color weaponColor([double s = 0.5]) =>
      HSLColor.fromAHSL(1, weaponHue.toDouble(), s, 0.55).toColor();

  Map<String, dynamic> toJson() => {'a': armorHue, 'c': capeHue, 'w': weaponHue};

  factory Customization.fromJson(Map<String, dynamic>? j) {
    if (j == null) return Customization();
    return Customization()
      ..armorHue = j['a'] as int? ?? 0
      ..capeHue = j['c'] as int? ?? 0
      ..weaponHue = j['w'] as int? ?? 200;
  }
}

class WeaponLoadout {
  GunBarrelMod gunBarrel;
  GunSightMod gunSight;
  GunAmmoMod gunAmmo;
  StaffFocusMod staffFocus;
  BladeEdgeMod bladeEdge;

  WeaponLoadout({
    this.gunBarrel = GunBarrelMod.none,
    this.gunSight = GunSightMod.none,
    this.gunAmmo = GunAmmoMod.none,
    this.staffFocus = StaffFocusMod.none,
    this.bladeEdge = BladeEdgeMod.none,
  });

  Map<String, dynamic> toJson() => {
        'gb': gunBarrel.name,
        'gs': gunSight.name,
        'ga': gunAmmo.name,
        'sf': staffFocus.name,
        'be': bladeEdge.name,
      };

  factory WeaponLoadout.fromJson(Map<String, dynamic>? j) {
    if (j == null) return WeaponLoadout();
    T parse<T extends Enum>(List<T> values, String? name, T def) {
      if (name == null) return def;
      return values.firstWhere((e) => e.name == name, orElse: () => def);
    }

    return WeaponLoadout(
      gunBarrel: parse(GunBarrelMod.values, j['gb'] as String?, GunBarrelMod.none),
      gunSight: parse(GunSightMod.values, j['gs'] as String?, GunSightMod.none),
      gunAmmo: parse(GunAmmoMod.values, j['ga'] as String?, GunAmmoMod.none),
      staffFocus: parse(StaffFocusMod.values, j['sf'] as String?, StaffFocusMod.none),
      bladeEdge: parse(BladeEdgeMod.values, j['be'] as String?, BladeEdgeMod.none),
    );
  }
}

class InquisitionRank {
  int wins;
  RankPerk chosenPerk;
  InquisitionRank({this.wins = 0, this.chosenPerk = RankPerk.none});

  int get rank => (wins ~/ 2).clamp(0, 20);
  double get critBonus => rank * 0.01;
  int get startScraps =>
      rank * 3 + (chosenPerk == RankPerk.scrapBonus ? (rank * 0.05 * 20).round() : 0);
  int get startSpBonus => chosenPerk == RankPerk.startSp ? 1 : 0;
  double get scrapMult => chosenPerk == RankPerk.scrapBonus ? 1.05 : 1.0;

  String get title {
    if (rank <= 0) return 'Новичок';
    if (rank <= 3) return 'Адепт';
    if (rank <= 7) return 'Интеррогатор';
    if (rank <= 12) return 'Инквизитор';
    if (rank <= 16) return 'Лорд-Инквизитор';
    return 'Мастер Ордо';
  }

  Map<String, dynamic> toJson() => {'wins': wins, 'perk': chosenPerk.name};

  factory InquisitionRank.fromJson(Map<String, dynamic>? j) {
    if (j == null) return InquisitionRank();
    return InquisitionRank(
      wins: j['wins'] as int? ?? 0,
      chosenPerk: RankPerk.values.firstWhere(
        (e) => e.name == j['perk'],
        orElse: () => RankPerk.none,
      ),
    );
  }
}

class WeaponMastery {
  final Map<String, int> kills = {};
  WeaponMastery(); // обязательно

  int getCount(String key) => kills[key] ?? 0;
  void addKill(String key) => kills[key] = getCount(key) + 1;

  int bolterExtraShots(int base, {bool ammoSavant = false, bool xenosSynergy = false}) {
    final k = getCount('bolter');
    var extra = (k ~/ 50).clamp(0, 3);
    if (ammoSavant) extra += (k ~/ 80).clamp(0, 1);
    if (xenosSynergy && k >= 50 && extra < 1) extra = 1;
    return base + extra;
  }

  double staffRadiusMult() => 1.0 + (getCount('staff') ~/ 40) * 0.10;
  double meleeMasteryMult(String key) => 1.0 + (getCount(key) ~/ 40) * 0.05;

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(kills);

  factory WeaponMastery.fromJson(Map<String, dynamic>? j) {
    final m = WeaponMastery();
    if (j != null) {
      j.forEach((k, v) => m.kills[k] = (v as num?)?.toInt() ?? 0);
    }
    return m;
  }
}

class PathNode {
  final PathNodeKind kind;
  final String label;
  PathNode(this.kind, this.label);
}

class StatusEffect {
  final StatusType type;
  double remaining;
  final double tickEvery;
  double tickAcc;
  final int tickDamage;

  StatusEffect(this.type, this.remaining, {this.tickEvery = 0.5, this.tickDamage = 1})
      : tickAcc = 0;

  Color get color {
    switch (type) {
      case StatusType.burn:
        return const Color(0xFFFF6D00);
      case StatusType.bleed:
        return const Color(0xFFE53935);
      case StatusType.slow:
        return const Color(0xFF4FC3F7);
      case StatusType.corruption:
        return const Color(0xFF9C27B0);
      case StatusType.plague:
        return const Color(0xFF8BC34A);
    }
  }
}

class AchievementState {
  final Set<String> unlocked = {};
  final Set<String> classesPlayed = {};
  int championsKilledTotal = 0;
  AchievementState(); // обязательно

  bool has(AchievementId id) => unlocked.contains(id.name);

  Map<String, dynamic> toJson() => {
        'u': unlocked.toList(),
        'c': classesPlayed.toList(),
        'ch': championsKilledTotal,
      };

  factory AchievementState.fromJson(Map<String, dynamic>? j) {
    final s = AchievementState();
    if (j == null) return s;
    s.unlocked.addAll((j['u'] as List?)?.map((e) => e.toString()) ?? []);
    s.classesPlayed.addAll((j['c'] as List?)?.map((e) => e.toString()) ?? []);
    s.championsKilledTotal = j['ch'] as int? ?? 0;
    return s;
  }
}

class HighScoreEntry {
  final String name;
  final int score;
  final int seconds;
  final String difficulty;
  final String playerClass;
  final int floor;
  final int level;
  final bool completed;
  final List<String> keyRelics;

  HighScoreEntry({
    required this.name,
    required this.score,
    required this.seconds,
    required this.difficulty,
    required this.playerClass,
    required this.floor,
    required this.level,
    this.completed = false,
    this.keyRelics = const [],
  });

  String get timeStr {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get progressStr {
    if (completed) return 'ВСЁ ПРОЙДЕНО • $difficulty';
    return 'Этаж $floor • Ур.$level • $difficulty';
  }

  Map<String, dynamic> toJson() => {
        'n': name,
        'sc': score,
        't': seconds,
        'd': difficulty,
        'pc': playerClass,
        'f': floor,
        'l': level,
        'c': completed,
        'r': keyRelics,
      };

  factory HighScoreEntry.fromJson(Map<String, dynamic> j) => HighScoreEntry(
        name: j['n'] as String? ?? '?',
        score: j['sc'] as int? ?? 0,
        seconds: j['t'] as int? ?? 0,
        difficulty: j['d'] as String? ?? 'Норма',
        playerClass: j['pc'] as String? ?? 'Xenos',
        floor: j['f'] as int? ?? 1,
        level: j['l'] as int? ?? 1,
        completed: j['c'] as bool? ?? false,
        keyRelics: (j['r'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class GameSave {
  final String name;
  final String dateStr;
  final String playerClass;
  final String difficulty;
  final int floor;
  final int level;
  final int score;
  final int scraps;
  final int skillPoints;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> mastery;
  final List<String> relics;
  final Map<String, dynamic> loadout;
  final Map<String, int> loreRanks;
  final List<String> codex;
  final int health;
  final String ranged;
  final String melee;
  final bool usingMelee;
  final String payload;

  GameSave({
    required this.name,
    required this.dateStr,
    required this.playerClass,
    required this.difficulty,
    required this.floor,
    required this.level,
    required this.score,
    required this.scraps,
    required this.skillPoints,
    required this.skills,
    required this.mastery,
    required this.relics,
    required this.loadout,
    required this.loreRanks,
    required this.codex,
    required this.health,
    required this.ranged,
    required this.melee,
    required this.usingMelee,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': dateStr,
        'pc': playerClass,
        'diff': difficulty,
        'floor': floor,
        'level': level,
        'score': score,
        'scraps': scraps,
        'sp': skillPoints,
        'skills': skills,
        'mastery': mastery,
        'relics': relics,
        'loadout': loadout,
        'lore': loreRanks,
        'codex': codex,
        'hp': health,
        'rw': ranged,
        'mw': melee,
        'um': usingMelee,
        'payload': payload,
      };

  factory GameSave.fromJson(Map<String, dynamic> j) => GameSave(
        name: j['name'] as String? ?? '?',
        dateStr: j['date'] as String? ?? '',
        playerClass: j['pc'] as String? ?? 'xenos',
        difficulty: j['diff'] as String? ?? 'Норма',
        floor: j['floor'] as int? ?? 1,
        level: j['level'] as int? ?? 1,
        score: j['score'] as int? ?? 0,
        scraps: j['scraps'] as int? ?? 0,
        skillPoints: j['sp'] as int? ?? 0,
        skills: Map<String, dynamic>.from(j['skills'] as Map? ?? {}),
        mastery: Map<String, dynamic>.from(j['mastery'] as Map? ?? {}),
        relics: (j['relics'] as List?)?.map((e) => e.toString()).toList() ?? [],
        loadout: Map<String, dynamic>.from(j['loadout'] as Map? ?? {}),
        loreRanks: (j['lore'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
            {},
        codex: (j['codex'] as List?)?.map((e) => e.toString()).toList() ?? [],
        health: j['hp'] as int? ?? 6,
        ranged: j['rw'] as String? ?? 'bolter',
        melee: j['mw'] as String? ?? 'sword',
        usingMelee: j['um'] as bool? ?? false,
        payload: j['payload'] as String? ?? jsonEncode(j),
      );
}
// ─── VISUAL FX ────────────────────────────────────────────────

class DamageNumber extends PositionComponent {
  final int amount;
  final Color color;
  final String? label;
  double life = 0.85;

  DamageNumber({
    required Vector2 position,
    required this.amount,
    this.color = const Color(0xFFFFEB3B),
    this.label,
  }) : super(position: position.clone(), priority: 100);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position.y -= 40 * dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final text = label ?? '-$amount';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(life.clamp(0.0, 1.0)),
          fontSize: label != null ? 14 : 16,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 0));
  }
}

class BloodSplash extends PositionComponent {
  final List<_Drop> drops = [];
  double life = 0.9;

  BloodSplash({required Vector2 position, int count = 12, Vector2? fromDir})
      : super(position: position.clone(), priority: 8) {
    final rnd = Random();
    final base = fromDir?.normalized() ?? Vector2(0, -1);
    for (int i = 0; i < count; i++) {
      final spread = (rnd.nextDouble() - 0.5) * 1.4;
      final ang = atan2(base.y, base.x) + spread;
      final spd = 40 + rnd.nextDouble() * 90;
      drops.add(_Drop(Vector2(cos(ang) * spd, sin(ang) * spd), 2 + rnd.nextDouble() * 3));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    for (final d in drops) {
      d.pos += d.vel * dt;
      d.vel.y += 180 * dt;
    }
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / 0.9).clamp(0.0, 1.0);
    for (final d in drops) {
      canvas.drawCircle(
        Offset(d.pos.x, d.pos.y),
        d.r,
        Paint()..color = Color.fromRGBO(180, 0, 0, a),
      );
    }
  }
}

class _Drop {
  Vector2 pos = Vector2.zero();
  Vector2 vel;
  double r;
  _Drop(this.vel, this.r);
}

class KillExplosion extends PositionComponent with CollisionCallbacks {
  final double radius;
  final int damage;
  final bool applyBurn;
  double life = 0.35;

  KillExplosion({
    required Vector2 position,
    this.radius = 60,
    this.damage = 4,
    this.applyBurn = false,
  }) : super(
          position: position.clone(),
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
          priority: 12,
        );

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / 0.35).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius * (1.2 - a * 0.3),
      Paint()..color = Color.fromRGBO(255, 109, 0, 0.45 * a),
    );
  }
}

class ComboBanner extends PositionComponent {
  final int combo;
  double life = 1.2;

  ComboBanner({required Vector2 position, required this.combo})
      : super(position: position.clone(), priority: 110);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position.y -= 20 * dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'x$combo',
        style: TextStyle(
          color: Color.fromRGBO(255, 215, 0, life.clamp(0.0, 1.0)),
          fontSize: 22 + min(combo, 20) * 0.4,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.red, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 0));
  }
}

class AfterImage extends PositionComponent {
  double life = 0.25;
  final double startLife = 0.25;
  final Color tint;

  AfterImage({
    required Vector2 position,
    required Vector2 size,
    this.tint = const Color(0xFF81D4FA),
  }) : super(
          position: position.clone(),
          size: size.clone(),
          anchor: Anchor.center,
          priority: 18,
        );

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / startLife).clamp(0.0, 1.0) * 0.35;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: size.x * 0.7, height: size.y * 0.8),
        const Radius.circular(8),
      ),
      Paint()..color = tint.withOpacity(a),
    );
  }
}

class TelegraphZone extends PositionComponent {
  final String shape; // circle | cone | cross
  final double radius;
  final double angle;
  double life;
  final double maxLife;

  TelegraphZone({
    required Vector2 position,
    required this.shape,
    required this.radius,
    this.angle = 0,
    this.life = 0.7,
  })  : maxLife = life,
        super(
          position: position.clone(),
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
          priority: 6,
        );

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / maxLife).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Color.fromRGBO(255, 40, 40, 0.22 + 0.25 * a)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Color.fromRGBO(255, 80, 80, 0.5 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final c = Offset(size.x / 2, size.y / 2);
    switch (shape) {
      case 'circle':
        canvas.drawCircle(c, radius, paint);
        canvas.drawCircle(c, radius, stroke);
        break;
      case 'cone':
        final path = Path()..moveTo(c.dx, c.dy);
        path.arcTo(Rect.fromCircle(center: c, radius: radius), angle - 0.55, 1.1, false);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, stroke);
        break;
      case 'cross':
        canvas.drawRect(Rect.fromCenter(center: c, width: radius * 2, height: 28), paint);
        canvas.drawRect(Rect.fromCenter(center: c, width: 28, height: radius * 2), paint);
        break;
    }
  }
}

class BulletTrail extends PositionComponent {
  final Vector2 from;
  final Vector2 to;
  final Color color;
  double life = 0.1;

  BulletTrail({required this.from, required this.to, required this.color}) : super(priority: 12);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      Offset(from.x, from.y),
      Offset(to.x, to.y),
      Paint()
        ..color = color.withOpacity((life / 0.1).clamp(0.0, 1.0) * 0.7)
        ..strokeWidth = 2,
    );
  }
}

// ─── WHDraw ───────────────────────────────────────────────────

class WHDraw {
  static void _shadow(Canvas c, double cx, double cy, double w, double h) {
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.55), width: w, height: h * 0.18),
      Paint()..color = Colors.black.withOpacity(0.25),
    );
  }

  static void _flash(Canvas c, double cx, double cy, double r, double flash) {
    if (flash > 0) {
      c.drawCircle(Offset(cx, cy), r, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
    }
  }

  static void inquisitor(
    Canvas canvas, {
    required double cx,
    required double cy,
    double s = 1.2,
    double flash = 0,
    Customization? custom,
    PlayerClass cls = PlayerClass.xenos,
  }) {
    final armor = custom?.armorColor(0.4) ?? const Color(0xFF2A2A2A);
    final cape = custom?.capeColor(0.55) ?? const Color(0xFFB71C1C);
    final accent = switch (cls) {
      PlayerClass.xenos => const Color(0xFFB71C1C),
      PlayerClass.malleus => const Color(0xFF5C6BC0),
      PlayerClass.hereticus => const Color(0xFF8E24AA),
    };
    _shadow(canvas, cx, cy, 50 * s, 70 * s);
    final capePath = Path()
      ..moveTo(cx - 18 * s, cy - 8 * s)
      ..quadraticBezierTo(cx - 28 * s, cy + 20 * s, cx - 16 * s, cy + 38 * s)
      ..lineTo(cx + 16 * s, cy + 38 * s)
      ..quadraticBezierTo(cx + 28 * s, cy + 20 * s, cx + 18 * s, cy - 8 * s)
      ..close();
    canvas.drawPath(capePath, Paint()..color = cape);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 8 * s, cy + 28 * s), width: 12 * s, height: 22 * s),
        Radius.circular(3 * s),
      ),
      Paint()..color = armor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 8 * s, cy + 28 * s), width: 12 * s, height: 22 * s),
        Radius.circular(3 * s),
      ),
      Paint()..color = armor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 34 * s, height: 36 * s),
        Radius.circular(5 * s),
      ),
      Paint()..color = armor,
    );
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 2 * s), width: 28 * s, height: 6 * s), Paint()..color = accent);
    canvas.drawCircle(Offset(cx - 18 * s, cy - 4 * s), 9 * s, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(Offset(cx + 18 * s, cy - 4 * s), 9 * s, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 22 * s), width: 22 * s, height: 24 * s),
        Radius.circular(4 * s),
      ),
      Paint()..color = const Color(0xFF1C1C1C),
    );
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 22 * s), width: 14 * s, height: 5 * s), Paint()..color = accent);
    _flash(canvas, cx, cy, 40 * s, flash);
  }

  static void bolter(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFF6D00)}) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 4 * s, 28 * s, 8 * s), Radius.circular(2 * s)),
      Paint()..color = const Color(0xFF37474F),
    );
    c.drawRect(Rect.fromLTWH(cx + 28 * s, cy - 2 * s, 10 * s, 4 * s), Paint()..color = accent);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy + 4 * s, 10 * s, 12 * s), Radius.circular(2 * s)),
      Paint()..color = const Color(0xFF263238),
    );
  }

  static void rifle(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF00E5FF)}) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, cy - 3 * s, 36 * s, 6 * s), Radius.circular(2 * s)),
      Paint()..color = const Color(0xFF455A64),
    );
    c.drawRect(Rect.fromLTWH(cx + 34 * s, cy - 2 * s, 8 * s, 3 * s), Paint()..color = accent);
  }

  static void shotgun(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFFAB40)}) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 5 * s, 24 * s, 10 * s), Radius.circular(3 * s)),
      Paint()..color = const Color(0xFF5D4037),
    );
    c.drawRect(Rect.fromLTWH(cx + 24 * s, cy - 3 * s, 8 * s, 6 * s), Paint()..color = accent);
  }

  static void staff(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFB388FF)}) {
    c.drawLine(
      Offset(cx + 6 * s, cy + 20 * s),
      Offset(cx + 10 * s, cy - 22 * s),
      Paint()
        ..color = const Color(0xFF5D4E37)
        ..strokeWidth = 4 * s,
    );
    c.drawCircle(Offset(cx + 10 * s, cy - 26 * s), 8 * s, Paint()..color = accent.withOpacity(0.85));
  }

  static void stormStaff(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF7C4DFF)}) {
    staff(c, cx, cy, s, accent: accent);
  }

  static void warpBeamGun(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFEA80FC)}) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 6 * s, 26 * s, 12 * s), Radius.circular(4 * s)),
      Paint()..color = const Color(0xFF4A148C),
    );
    c.drawCircle(Offset(cx + 30 * s, cy), 6 * s, Paint()..color = accent);
  }

  static void daggers(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE0E0E0)}) {
    c.drawLine(Offset(cx + 8 * s, cy + 8 * s), Offset(cx + 22 * s, cy - 12 * s), Paint()..color = accent..strokeWidth = 3 * s);
  }

  static void needles(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFCE93D8)}) {
    for (int i = 0; i < 3; i++) {
      c.drawLine(
        Offset(cx + 6 * s, cy - 4 * s + i * 4 * s),
        Offset(cx + 26 * s, cy - 10 * s + i * 4 * s),
        Paint()
          ..color = accent
          ..strokeWidth = 1.5 * s,
      );
    }
  }

  static void sniperNeedle(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE040FB)}) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, cy - 2 * s, 34 * s, 4 * s), Radius.circular(1 * s)),
      Paint()..color = const Color(0xFF6A1B9A),
    );
  }

  static void powerSword(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF00BCD4)}) {
    c.drawLine(
      Offset(cx + 6 * s, cy + 12 * s),
      Offset(cx + 28 * s, cy - 18 * s),
      Paint()
        ..color = accent
        ..strokeWidth = 4 * s,
    );
  }

  static void chainAxe(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFF6D00)}) {
    c.drawLine(Offset(cx + 6 * s, cy + 10 * s), Offset(cx + 18 * s, cy - 6 * s), Paint()..color = const Color(0xFF5D4037)..strokeWidth = 4 * s);
    c.drawOval(Rect.fromCenter(center: Offset(cx + 24 * s, cy - 12 * s), width: 18 * s, height: 14 * s), Paint()..color = accent);
  }

  static void thunderHammer(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFFD700)}) {
    c.drawLine(Offset(cx + 6 * s, cy + 14 * s), Offset(cx + 16 * s, cy - 8 * s), Paint()..color = const Color(0xFF455A64)..strokeWidth = 5 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 20 * s, cy - 14 * s), width: 20 * s, height: 14 * s),
        Radius.circular(2 * s),
      ),
      Paint()..color = accent,
    );
  }

  static void forceBlade(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF7C4DFF)}) =>
      powerSword(c, cx, cy, s * 1.1, accent: accent);

  static void forceSword(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFB388FF)}) =>
      powerSword(c, cx, cy, s * 1.15, accent: accent);

  static void daemonHammer(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE040FB)}) =>
      thunderHammer(c, cx, cy, s * 1.05, accent: accent);

  static void katana(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE0E0E0)}) {
    c.drawLine(Offset(cx + 4 * s, cy + 14 * s), Offset(cx + 32 * s, cy - 16 * s), Paint()..color = accent..strokeWidth = 2.5 * s);
  }

  static void powerKatana(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE040FB)}) =>
      katana(c, cx, cy, s, accent: accent);

  static void executioner(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFF1744)}) {
    c.drawLine(Offset(cx + 6 * s, cy + 12 * s), Offset(cx + 26 * s, cy - 14 * s), Paint()..color = accent..strokeWidth = 5 * s);
  }

  static void cultistShooter(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 40 * s, 55 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 26 * s, height: 30 * s), Radius.circular(4 * s)),
      Paint()..color = const Color(0xFF1B5E20),
    );
    c.drawCircle(Offset(cx, cy - 16 * s), 11 * s, Paint()..color = const Color(0xFF2E7D32));
    bolter(c, cx, cy, s * 0.85, accent: const Color(0xFF76FF03));
    _flash(c, cx, cy, 30 * s, flash);
  }

  static void cultistMelee(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 40 * s, 55 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 28 * s, height: 32 * s), Radius.circular(4 * s)),
      Paint()..color = const Color(0xFFF9A825),
    );
    c.drawCircle(Offset(cx, cy - 16 * s), 11 * s, Paint()..color = const Color(0xFFF57F17));
    powerSword(c, cx, cy, s * 0.9, accent: const Color(0xFFFFF176));
    _flash(c, cx, cy, 30 * s, flash);
  }

  static void shieldedMarine(Canvas c, double cx, double cy, double s, {bool withGun = false, double flash = 0}) {
    _shadow(c, cx, cy, 48 * s, 60 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 32 * s, height: 36 * s), Radius.circular(5 * s)),
      Paint()..color = const Color(0xFF1565C0),
    );
    c.drawCircle(Offset(cx, cy - 18 * s), 12 * s, Paint()..color = const Color(0xFF0D47A1));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 16 * s, cy + 4 * s), width: 14 * s, height: 28 * s), Radius.circular(3 * s)),
      Paint()..color = const Color(0xFF90CAF9).withOpacity(0.85),
    );
    if (withGun) bolter(c, cx + 4 * s, cy, s * 0.8, accent: const Color(0xFF42A5F5));
    _flash(c, cx, cy, 32 * s, flash);
  }

  static void chaosHound(Canvas c, double cx, double cy, {double flash = 0}) {
    _shadow(c, cx, cy, 44, 30);
    final body = Path()
      ..moveTo(cx - 20, cy)
      ..quadraticBezierTo(cx, cy - 16, cx + 22, cy - 4)
      ..quadraticBezierTo(cx + 18, cy + 10, cx - 8, cy + 12)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx + 18, cy - 8), 8, Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx + 21, cy - 9), 2.5, Paint()..color = const Color(0xFFFF1744));
    _flash(c, cx, cy, 28, flash);
  }

  static void flamerCultist(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    cultistShooter(c, cx, cy, s, flash: flash);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy - 2 * s, 18 * s, 10 * s), Radius.circular(3 * s)),
      Paint()..color = const Color(0xFFFF6D00),
    );
  }

  static void sniperCultist(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    cultistShooter(c, cx, cy, s, flash: flash);
    rifle(c, cx, cy, s * 0.9, accent: const Color(0xFF4FC3F7));
  }

  static void brute(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 60 * s, 70 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 44 * s, height: 48 * s), Radius.circular(6 * s)),
      Paint()..color = const Color(0xFF5D4037),
    );
    c.drawCircle(Offset(cx, cy - 22 * s), 16 * s, Paint()..color = const Color(0xFF3E2723));
    _flash(c, cx, cy, 40 * s, flash);
  }

  static void cultPsyker(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 42 * s, 58 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 28 * s, height: 34 * s), Radius.circular(5 * s)),
      Paint()..color = const Color(0xFF6A1B9A),
    );
    c.drawCircle(Offset(cx, cy - 18 * s), 12 * s, Paint()..color = const Color(0xFF4A148C));
    c.drawCircle(Offset(cx, cy - 28 * s), 7 * s, Paint()..color = const Color(0xFFEA80FC).withOpacity(0.8));
    _flash(c, cx, cy, 32 * s, flash);
  }

  static void plagueBearer(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 48 * s, 60 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 36 * s, height: 40 * s), Radius.circular(8 * s)),
      Paint()..color = const Color(0xFF558B2F),
    );
    c.drawCircle(Offset(cx, cy - 20 * s), 14 * s, Paint()..color = const Color(0xFF33691E));
    _flash(c, cx, cy, 34 * s, flash);
  }

  static void bloodletter(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 44 * s, 58 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 30 * s, height: 36 * s), Radius.circular(4 * s)),
      Paint()..color = const Color(0xFFB71C1C),
    );
    c.drawCircle(Offset(cx, cy - 18 * s), 12 * s, Paint()..color = const Color(0xFF7F0000));
    powerSword(c, cx, cy, s, accent: const Color(0xFFFF1744));
    _flash(c, cx, cy, 32 * s, flash);
  }

  static void hereticBoss(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 70 * s, 80 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 50 * s, height: 56 * s), Radius.circular(6 * s)),
      Paint()..color = const Color(0xFF4A0000),
    );
    c.drawCircle(Offset(cx, cy - 28 * s), 18 * s, Paint()..color = const Color(0xFF1A0000));
    bolter(c, cx + 6 * s, cy, s * 1.1, accent: const Color(0xFFFF5252));
    _flash(c, cx, cy, 48 * s, flash);
  }

  static void knightBoss(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 68 * s, 80 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 48 * s, height: 54 * s), Radius.circular(5 * s)),
      Paint()..color = const Color(0xFF263238),
    );
    c.drawCircle(Offset(cx, cy - 26 * s), 16 * s, Paint()..color = const Color(0xFF102027));
    powerSword(c, cx, cy, s * 1.2, accent: const Color(0xFF90CAF9));
    _flash(c, cx, cy, 46 * s, flash);
  }

  static void kingBossDraw(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 80 * s, 90 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 58 * s, height: 64 * s), Radius.circular(7 * s)),
      Paint()..color = const Color(0xFF3E2723),
    );
    final crown = Path()
      ..moveTo(cx - 16 * s, cy - 36 * s)
      ..lineTo(cx - 12 * s, cy - 48 * s)
      ..lineTo(cx - 4 * s, cy - 38 * s)
      ..lineTo(cx, cy - 52 * s)
      ..lineTo(cx + 4 * s, cy - 38 * s)
      ..lineTo(cx + 12 * s, cy - 48 * s)
      ..lineTo(cx + 16 * s, cy - 36 * s)
      ..close();
    c.drawPath(crown, Paint()..color = const Color(0xFFFFD700));
    c.drawCircle(Offset(cx, cy - 28 * s), 16 * s, Paint()..color = const Color(0xFF1A1A1A));
    _flash(c, cx, cy, 55 * s, flash);
  }

  static void plagueLord(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 75 * s, 85 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 54 * s, height: 58 * s), Radius.circular(10 * s)),
      Paint()..color = const Color(0xFF33691E),
    );
    c.drawCircle(Offset(cx, cy - 26 * s), 18 * s, Paint()..color = const Color(0xFF1B5E20));
    _flash(c, cx, cy, 50 * s, flash);
  }

  static void bloodChampion(Canvas c, double cx, double cy, double s, {double flash = 0, double rage = 0}) {
    _shadow(c, cx, cy, 70 * s, 80 * s);
    final body = Color.lerp(const Color(0xFFB71C1C), const Color(0xFFFF1744), rage)!;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 48 * s, height: 54 * s), Radius.circular(5 * s)),
      Paint()..color = body,
    );
    c.drawCircle(Offset(cx, cy - 26 * s), 16 * s, Paint()..color = const Color(0xFF7F0000));
    powerSword(c, cx, cy, s * 1.15, accent: const Color(0xFFFF1744));
    _flash(c, cx, cy, 48 * s, flash);
  }

  static void cyclops(Canvas c, double cx, double cy, double s, {double flash = 0, double charge = 0}) {
    _shadow(c, cx, cy, 78 * s, 90 * s);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 56 * s, height: 62 * s), Radius.circular(8 * s)),
      Paint()..color = const Color(0xFF4E342E),
    );
    c.drawCircle(Offset(cx, cy - 28 * s), 20 * s, Paint()..color = const Color(0xFF3E2723));
    final eyeR = 8 * s + charge * 6 * s;
    c.drawCircle(
      Offset(cx, cy - 30 * s),
      eyeR,
      Paint()..color = Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFFEA00), charge)!,
    );
    _flash(c, cx, cy, 52 * s, flash);
  }

  static void statusIcons(Canvas c, double cx, double topY, List<StatusEffect> statuses) {
    if (statuses.isEmpty) return;
    double x = cx - statuses.length * 7.0;
    for (final e in statuses) {
      c.drawCircle(Offset(x, topY), 5, Paint()..color = e.color);
      x += 14;
    }
  }

  static void championMark(Canvas c, double cx, double topY, {EliteAffix affix = EliteAffix.none}) {
    c.drawCircle(Offset(cx, topY), 7, Paint()..color = affix != EliteAffix.none ? affix.color : const Color(0xFFFFD700));
    if (affix != EliteAffix.none && affix.letter.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: affix.letter,
          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(cx - tp.width / 2, topY - tp.height / 2));
    }
  }

  static void altar(Canvas c, double cx, double cy, double t) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 28), const Radius.circular(4)),
      Paint()..color = const Color(0xFF5D4037),
    );
    final pulse = 0.5 + 0.5 * sin(t * 3);
    c.drawCircle(Offset(cx, cy - 18), 10 + pulse * 3, Paint()..color = Color.fromRGBO(255, 215, 0, 0.4 + pulse * 0.3));
  }

  static void merchantStall(Canvas c, double cx, double cy, double t) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 48, height: 32), const Radius.circular(4)),
      Paint()..color = const Color(0xFF6D4C41),
    );
  }

  static void barrel(Canvas c, double cx, double cy) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 28, height: 34), const Radius.circular(4)),
      Paint()..color = const Color(0xFF8D6E63),
    );
  }
}
// ─── SMART MOVER ──────────────────────────────────────────────

mixin SmartMover on PositionComponent {
  double stuckTimer = 0;
  Vector2 _lastPos = Vector2.zero();
  int _stuckFrames = 0;

  InquisitorGame get _g => findGame() as InquisitorGame;

  void smartMove(
    Vector2 target,
    double speed,
    double dt, {
    double radius = 20,
    bool kite = false,
    double preferDist = 160,
  }) {
    if (stuckTimer > 0) stuckTimer -= dt;

    Vector2 desired;
    final toTarget = target - position;
    final dist = toTarget.length;

    if (kite && dist < preferDist) {
      desired = -toTarget.normalized();
    } else if (dist > 8) {
      desired = toTarget.normalized();
    } else {
      desired = Vector2.zero();
    }

    // separation from other hostiles
    Vector2 sep = Vector2.zero();
    for (final o in _g.world.children) {
      if (identical(o, this)) continue;
      if (o is! PositionComponent) continue;
      if (o is! Enemy && o is! MiniBoss && o is! Boss && o is! KnightBoss &&
          o is! KingBoss && o is! TentacleBoss && o is! CyclopsBoss &&
          o is! PlagueLordBoss && o is! BloodChampionBoss) {
        continue;
      }
      final d = position.distanceTo(o.position);
      if (d > 0 && d < radius * 2.2) {
        sep += (position - o.position).normalized() * ((radius * 2.2 - d) / (radius * 2.2));
      }
    }
    if (sep.length2 > 0.01) {
      desired = (desired + sep.normalized() * 0.55).normalized();
    }

    // avoid walls / obstacles / barrels
    Vector2 avoid = Vector2.zero();
    for (final o in _g.world.children) {
      if (o is Wall || o is Obstacle || o is BreakableBarrel) {
        final d = position.distanceTo(o.position);
        final lim = radius + 36;
        if (d > 0 && d < lim) {
          avoid += (position - o.position).normalized() * ((lim - d) / lim);
        }
      }
    }
    if (avoid.length2 > 0.01) {
      desired = (desired + avoid.normalized() * 0.9).normalized();
    }

    if (stuckTimer > 0) {
      final a = Random().nextDouble() * pi * 2;
      desired = Vector2(cos(a), sin(a));
    }

    if (desired.length2 < 0.01) return;

    final next = position + desired * speed * dt;
    // soft bounds
    next.x = next.x.clamp(radius + 20, _g.mapWidth - radius - 20);
    next.y = next.y.clamp(radius + 20, _g.mapHeight - radius - 20);
    position.setFrom(next);

    if ((position - _lastPos).length < speed * dt * 0.15) {
      _stuckFrames++;
      if (_stuckFrames > 12) {
        stuckTimer = 0.55;
        _stuckFrames = 0;
      }
    } else {
      _stuckFrames = 0;
    }
    _lastPos.setFrom(position);
  }

  void pushOutOfWalls(double radius) {
    for (final o in _g.world.children) {
      if (o is Wall || o is Obstacle || o is BreakableBarrel) {
        final d = position.distanceTo(o.position);
        final minD = radius + 28;
        if (d > 0 && d < minD) {
          position += (position - o.position).normalized() * (minD - d);
        }
      }
    }
    position.x = position.x.clamp(radius + 16, _g.mapWidth - radius - 16);
    position.y = position.y.clamp(radius + 16, _g.mapHeight - radius - 16);
  }
}

// ─── INQUISITOR GAME ──────────────────────────────────────────

class InquisitorGame extends FlameGame with HasCollisionDetection {
  // map
  double mapWidth = 1400;
  double mapHeight = 1000;
  double cellSize = 48;
  final double safeRadius = 160;

  // run state
  bool isPlaying = false;
  bool isPaused = false;
  bool isArena = false;
  bool portalSpawned = false;
  bool timedPortalUsed = false;
  bool secretBossSpawned = false;
  bool eventResolved = false;
  bool nearPortal = false;
  bool ironWillUsedThisFloor = false;

  String playerName = 'Аколит';
  PlayerClass playerClass = PlayerClass.xenos;
  Difficulty difficulty = Difficulty.normal;
  RankChallenge activeChallenge = RankChallenge.none;

  int currentFloor = 1;
  int currentLevel = 1; // 1..5 on floor, synced with pathIndex
  int pathIndex = 0;
  List<PathNode> floorPath = [];

  int score = 0;
  int scraps = 0;
  int skillPoints = 0;
  int runSeconds = 0;
  double runTimeAcc = 0;

  int enemiesAlive = 0;
  int enemiesToSpawn = 0;
  int enemiesSpawned = 0;
  int arenaKills = 0;
  int levelsSinceEvent = 0;

  // timed portal (5 min) for no-kill / timed achievements
  static const double timedPortalSec = 300;
  double levelTimer = 0;
  int killsThisLevel = 0;

  // combat stats (recomputed)
  double playerSpeed = 160;
  double attackSpeedMult = 1.0;
  int maxHealth = 6;
  int rangedDamage = 7;
  int meleeDamage = 12;
  int rangedCooldownMs = 280;
  int meleeCooldownMs = 380;
  int lastShotTime = 0;
  int lastMeleeTime = 0;

  bool usingMelee = false;
  RangedWeapon rangedWeapon = RangedWeapon.bolter;
  MeleeWeapon meleeWeapon = MeleeWeapon.sword;

  SkillTree skills = SkillTree();
  Customization custom = Customization();
  WeaponLoadout loadout = WeaponLoadout();
  WeaponMastery mastery = WeaponMastery();
  InquisitionRank rank = InquisitionRank();
  AchievementState achievements = AchievementState();
  HudLayout hud = HudLayout();

  final Set<RelicId> relics = {};
  final Set<CodexId> codexUnlocked = {};
  final Map<String, int> loreRanks = {}; // 0..2

  ActiveArtifact activeArtifact = ActiveArtifact.fragGrenade;
  double artifactCd = 0;
  double dashCooldown = 0;
  double laserCooldown = 0;
  double warpResetCd = 0;
  double invulnTimer = 0;
  double shieldTimer = 0;
  double hasteTimer = 0;
  double bolterHeat = 0;
  double staffWarpStress = 0;
  double bossRetreatTimer = 0;
  double cinemaZoomTimer = 0;
  double shakeTimer = 0;
  double shakePower = 0;

  int combo = 0;
  double comboTimer = 0;
  EchoBossKind lastBossEcho = EchoBossKind.none;
  EventRoomType currentEvent = EventRoomType.none;

  late Player player;
  Vector2 playerSpawnPos = Vector2(200, 500);

  // HUD refs
  JoystickComponent? moveJoystick;
  JoystickComponent? attackJoystick;
  HudButtonComponent? settingsBtn;
  HudButtonComponent? backpackBtn;
  HudButtonComponent? dashBtn;
  HudButtonComponent? laserBtn;
  HudButtonComponent? artifactBtn;
  HudButtonComponent? warpBtn;
  HudButtonComponent? portalBtn;
  Component? attackCdRing;

  // audio volumes
  double musicVol = 0.55;
  double sfxVol = 0.8;

  // meta lists
  List<HighScoreEntry> highScores = [];
  List<GameSave> saves = [];

  bool get isBossLevel =>
      floorPath.isNotEmpty && pathIndex < floorPath.length && floorPath[pathIndex].kind == PathNodeKind.boss;

  bool get areOtherBossesAlive {
    return world.children.whereType<Boss>().isNotEmpty ||
        world.children.whereType<KnightBoss>().isNotEmpty ||
        world.children.whereType<MiniBoss>().isNotEmpty;
  }

  double get worldThreat => 1.0 + (currentFloor - 1) * 0.08 + (currentLevel - 1) * 0.03;

  double get codexShieldBonus {
    double b = 0;
    for (final id in [CodexId.shielded, CodexId.shieldedShooter]) {
      b += (loreRanks[id.name] ?? 0) * 0.015;
    }
    return b;
  }

  double get codexBossBonus {
    double b = 0;
    for (final id in [
      CodexId.boss,
      CodexId.knight,
      CodexId.king,
      CodexId.miniBoss,
      CodexId.plagueLord,
      CodexId.bloodChampion
    ]) {
      b += (loreRanks[id.name] ?? 0) * 0.015;
    }
    return b;
  }

  bool get hasShieldPierce => relics.contains(RelicId.shieldPierce);
  bool get hasJediPath => relics.contains(RelicId.jediPath);
  bool get hasAmmoSavant => relics.contains(RelicId.ammoSavant);
  bool get hasWarpAnchor => relics.contains(RelicId.warpAnchor);
  bool get hasShadowStep => relics.contains(RelicId.shadowStep);
  bool get hasIronWill => relics.contains(RelicId.ironWill);
  bool get hasExecutioner => relics.contains(RelicId.executionerMark);
  bool get hasScavenger => relics.contains(RelicId.scavenger);
  bool get hasCrit => relics.contains(RelicId.crit);
  bool get hasLifesteal => relics.contains(RelicId.lifesteal);
  bool get hasKillExplosion => relics.contains(RelicId.killExplosion);
  bool get hasHaste => relics.contains(RelicId.haste);

  // ── lifecycle ──

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
    await _loadMeta();
    try {
      await FlameAudio.audioCache.loadAll([
        'bgm.mp3',
        'shoot.mp3',
        'melee.mp3',
        'hit.mp3',
      ]);
    } catch (_) {}
  }

  Future<void> _loadMeta() async {
    final prefs = await SharedPreferences.getInstance();
    musicVol = prefs.getDouble('musicVol') ?? 0.55;
    sfxVol = prefs.getDouble('sfxVol') ?? 0.8;
    final hudJson = prefs.getString('hud');
    if (hudJson != null) {
      try {
        hud = HudLayout.fromJson(jsonDecode(hudJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    final rankJson = prefs.getString('rank');
    if (rankJson != null) {
      try {
        rank = InquisitionRank.fromJson(jsonDecode(rankJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    final achJson = prefs.getString('achievements');
    if (achJson != null) {
      try {
        achievements = AchievementState.fromJson(jsonDecode(achJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    final hs = prefs.getString('highScores');
    if (hs != null) {
      try {
        final list = jsonDecode(hs) as List;
        highScores = list.map((e) => HighScoreEntry.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    final sv = prefs.getString('saves');
    if (sv != null) {
      try {
        final list = jsonDecode(sv) as List;
        saves = list.map((e) => GameSave.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
  }

  Future<void> _saveMeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVol', musicVol);
    await prefs.setDouble('sfxVol', sfxVol);
    await prefs.setString('hud', jsonEncode(hud.toJson()));
    await prefs.setString('rank', jsonEncode(rank.toJson()));
    await prefs.setString('achievements', jsonEncode(achievements.toJson()));
    await prefs.setString('highScores', jsonEncode(highScores.map((e) => e.toJson()).toList()));
    await prefs.setString('saves', jsonEncode(saves.map((e) => e.toJson()).toList()));
  }

  void recomputeStats() {
    maxHealth = 6 + skills.hp + playerClass.hpMod + (hasIronWill ? 1 : 0) + rank.startSpBonus.clamp(0, 0);
    // startSp is skill points, not HP — fix:
    maxHealth = 6 + skills.hp + (playerClass == PlayerClass.malleus ? -1 : 0) + (playerClass == PlayerClass.hereticus ? -1 : 0) + (hasIronWill ? 1 : 0);
    playerSpeed = 160 + skills.speed * 12 + playerClass.speedMod + (hasteTimer > 0 ? 30 : 0);
    attackSpeedMult = 1.0 + skills.attackSpeed * 0.08;
    rangedDamage = (7 + skills.damage * 1.5).round();
    meleeDamage = (12 + skills.damage * 2).round();
    rangedCooldownMs = (280 / attackSpeedMult).round();
    meleeCooldownMs = (380 / attackSpeedMult).round();
    if (loadout.gunBarrel == GunBarrelMod.rapid) rangedCooldownMs = (rangedCooldownMs * 0.75).round();
    if (loadout.gunBarrel == GunBarrelMod.heavy) rangedDamage = (rangedDamage * 1.35).round();
  }

  int scaleDamage(num base) {
    var d = base.toDouble() * playerClass.dmgMod;
    if (hasCrit && Random().nextDouble() < 0.15 + rank.critBonus) d *= 2;
    return d.round().clamp(1, 9999);
  }

  // ── HUD ──

  void rebuildHud() {
    // remove old
    for (final c in [
      moveJoystick,
      attackJoystick,
      settingsBtn,
      backpackBtn,
      dashBtn,
      laserBtn,
      artifactBtn,
      warpBtn,
      portalBtn,
      attackCdRing,
    ]) {
      c?.removeFromParent();
    }

    final size = camera.viewport.size;
    final js = hud.joystickSize;
    final bs = hud.buttonSize;

    Vector2 anchorOf(double nx, double nyFromBottom, {bool fromTop = false}) {
      final x = size.x * nx;
      final y = fromTop ? size.y * nyFromBottom : size.y * (1.0 - nyFromBottom);
      return Vector2(x, y);
    }

    moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: js * 0.28, paint: Paint()..color = const Color(0xFFB71C1C)),
      background: CircleComponent(radius: js * 0.5, paint: Paint()..color = const Color(0x55FFFFFF)),
      margin: EdgeInsets.only(
        left: size.x * hud.moveX - js * 0.5,
        bottom: size.y * hud.moveY - js * 0.5,
      ),
    );

    attackJoystick = JoystickComponent(
      knob: CircleComponent(radius: js * 0.28, paint: Paint()..color = const Color(0xFFFFD700)),
      background: CircleComponent(radius: js * 0.5, paint: Paint()..color = const Color(0x55FFFFFF)),
      margin: EdgeInsets.only(
        right: size.x * (1 - hud.atkX) - js * 0.5,
        bottom: size.y * hud.atkY - js * 0.5,
      ),
    );

    HudButtonComponent mkBtn(String label, Vector2 pos, void Function() onPress) {
      return HudButtonComponent(
        button: CircleComponent(radius: bs * 0.5, paint: Paint()..color = const Color(0xFF1A1A1A))
          ..add(TextComponent(
            text: label,
            anchor: Anchor.center,
            position: Vector2(bs * 0.5, bs * 0.5),
            textRenderer: TextPaint(style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
          )),
        buttonDown: CircleComponent(radius: bs * 0.5, paint: Paint()..color = const Color(0xFFB71C1C)),
        position: pos,
        onPressed: onPress,
      );
    }

    settingsBtn = mkBtn('S', anchorOf(hud.settingsX, hud.settingsY, fromTop: true), openSettings);
    backpackBtn = mkBtn('B', anchorOf(hud.backpackX, hud.backpackY, fromTop: true), openBackpack);
    dashBtn = mkBtn('U', anchorOf(hud.dashX, hud.dashY), () => player.dash());
    laserBtn = mkBtn('L', anchorOf(hud.laserX, hud.laserY), useLaser);
    artifactBtn = mkBtn('R', anchorOf(hud.artifactX, hud.artifactY), useArtifact);
    warpBtn = mkBtn('Ψ', anchorOf(hud.warpX, hud.warpY), resetWarp);
    portalBtn = mkBtn('P', anchorOf(hud.portalBtnX, hud.portalBtnY), usePortal);
    portalBtn!.debugMode = false;

    camera.viewport.add(moveJoystick!);
    camera.viewport.add(attackJoystick!);
    camera.viewport.add(settingsBtn!);
    camera.viewport.add(backpackBtn!);
    camera.viewport.add(dashBtn!);
    camera.viewport.add(laserBtn!);
    camera.viewport.add(artifactBtn!);
    camera.viewport.add(warpBtn!);
    camera.viewport.add(portalBtn!);
    portalBtn!.opacity = 0; // shown when near portal
  }

  void playSfx(String name) {
    try {
      FlameAudio.play(name, volume: sfxVol);
    } catch (_) {}
  }

  void ensureBgm() {
    try {
      FlameAudio.bgm.play('bgm.mp3', volume: musicVol);
    } catch (_) {}
  }

  void stopBgm() {
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  void spawnDamageNumber(Vector2 at, int amount, {Color color = const Color(0xFFFFEB3B), String? label}) {
    world.add(DamageNumber(position: at + Vector2(0, -20), amount: amount, color: color, label: label));
  }

  void spawnBlood(Vector2 at, {int count = 12, Vector2? fromDir}) {
    world.add(BloodSplash(position: at, count: count, fromDir: fromDir));
  }

  void triggerShake({double power = 6, double time = 0.15}) {
    shakePower = power;
    shakeTimer = time;
  }

  void triggerCinemaZoom() {
    cinemaZoomTimer = 0.4;
  }

  void markBossRetreat() {
    bossRetreatTimer = 0.8;
  }

  void spawnCorruptionZone(Vector2 at) {
    world.add(CorruptionPuddle(position: at.clone())..priority = 5);
  }

  void unlockAchievement(AchievementId id) {
    if (achievements.has(id)) return;
    achievements.unlocked.add(id.name);
    _saveMeta();
    spawnDamageNumber(player.position, 0, color: const Color(0xFFFFD700), label: '★ ${id.title}');
  }

  void unlockCodex(CodexId id) {
    if (codexUnlocked.contains(id)) return;
    codexUnlocked.add(id);
    loreRanks[id.name] = 0;
    overlays.add('lorePopup');
  }

  BulletMod rollBulletMod() {
    final r = Random().nextDouble();
    if (r < 0.08) return BulletMod.slow;
    if (r < 0.14) return BulletMod.ricochet;
    if (r < 0.18) return BulletMod.split;
    return BulletMod.normal;
  }

  // stubs used by menus / player — filled in PART 4+
  void openSettings() {
    isPaused = true;
    overlays.add('settings');
  }

  void closeSettings() {
    overlays.remove('settings');
    isPaused = false;
    rebuildHud(); // фикс размеров/позиций в бою
    _saveMeta();
  }

  void openBackpack() {
    isPaused = true;
    overlays.add('backpack');
  }

  void closeBackpack() {
    overlays.remove('backpack');
    isPaused = false;
  }

  void openCodex() {
    isPaused = true;
    overlays.add('codex');
  }

  void closeCodex() {
    overlays.remove('codex');
    isPaused = false;
  }

  void usePortal() {
    if (!nearPortal || !portalSpawned) return;
    if (timedPortalUsed && killsThisLevel == 0) {
      unlockAchievement(AchievementId.noKills);
      unlockAchievement(AchievementId.timedPortal);
    }
    nextLevel();
  }

  void useLaser() {
    if (laserCooldown > 0) return;
    if (!achievements.unlocked.contains(AchievementId.secretCyclops.name) &&
        !codexUnlocked.contains(CodexId.cyclops)) {
      return; // unlocked by secret
    }
    laserCooldown = 20;
    final dir = player.aimDir;
    world.add(CyclopsLaserBeam(position: player.position.clone(), direction: dir, damage: scaleDamage(28))..priority = 22);
    playSfx('shoot.mp3');
  }

  void useArtifact() {
    if (artifactCd > 0) return;
    artifactCd = activeArtifact.cooldown;
    switch (activeArtifact) {
      case ActiveArtifact.fragGrenade:
        world.add(KillExplosion(position: player.position + player.aimDir * 80, radius: 90, damage: scaleDamage(18), applyBurn: true));
        triggerShake(power: 8, time: 0.2);
        break;
      case ActiveArtifact.holyAura:
        shieldTimer = 3.5;
        for (final e in world.children.whereType<Enemy>()) {
          if (e.position.distanceTo(player.position) < 140) {
            e.applyDamage(scaleDamage(6));
          }
        }
        break;
      case ActiveArtifact.servoTurret:
        world.add(ServoTurret(position: player.position + Vector2(40, 0))..priority = 20);
        break;
    }
  }

  void resetWarp() {
    if (warpResetCd > 0) return;
    if (playerClass != PlayerClass.malleus) return;
    staffWarpStress = 0;
    warpResetCd = hasWarpAnchor ? 12 : 8;
    if (!hasWarpAnchor && skillPoints > 0) {
      skillPoints--;
    }
    spawnDamageNumber(player.position, 0, color: const Color(0xFFB388FF), label: 'Ψ СБРОС');
  }

  // navigation stubs
  void openNameInput() {
    for (final o in overlays.activeOverlays.toList()) {
      overlays.remove(o);
    }
    overlays.add('nameInput');
  }

  void backToMenu() {
    isPlaying = false;
    isPaused = false;
    isArena = false;
    stopBgm();
    world.removeAll(world.children);
    for (final o in overlays.activeOverlays.toList()) {
      overlays.remove(o);
    }
    overlays.add('mainMenu');
  }

  void showGameOver() {
    isPlaying = false;
    isPaused = true;
    stopBgm();
    _pushHighScore(completed: false);
    overlays.add('gameOver');
  }

  void _pushHighScore({required bool completed}) {
    highScores.add(HighScoreEntry(
      name: playerName,
      score: score,
      seconds: runSeconds,
      difficulty: difficulty.labelRu,
      playerClass: playerClass.title,
      floor: currentFloor,
      level: currentLevel,
      completed: completed,
      keyRelics: relics.take(2).map((e) => e.title).toList(),
    ));
    highScores.sort((a, b) => b.score.compareTo(a.score));
    if (highScores.length > 30) highScores = highScores.take(30).toList();
    if (completed) {
      rank.wins++;
      switch (difficulty) {
        case Difficulty.easy:
          unlockAchievement(AchievementId.clearEasy);
          break;
        case Difficulty.normal:
          unlockAchievement(AchievementId.clearNormal);
          break;
        case Difficulty.hard:
          unlockAchievement(AchievementId.clearHard);
          break;
      }
    }
    _saveMeta();
  }

  void finishAfterVictory() {
    _pushHighScore(completed: true);
    backToMenu();
  }

  void startArena() {
    isArena = true;
    arenaKills = 0;
    overlays.remove('victory');
    isPaused = false;
    isPlaying = true;
    currentFloor = difficulty.maxFloors;
    currentLevel = 5;
    _startLevel(forceArena: true);
  }

  void nextLevel() {
    // implemented PART 4
  }

  void finishRewardThenShop() {
    overlays.remove('reward');
    overlays.add('shop');
  }

  void finishShopThenSkills() {
    overlays.remove('shop');
    overlays.add('skills');
  }

  void finishSkillsAndContinue() {
    overlays.remove('skills');
    isPaused = false;
    pathIndex++;
    currentLevel = pathIndex + 1;
    if (pathIndex >= floorPath.length) {
      currentFloor++;
      pathIndex = 0;
      currentLevel = 1;
      if (currentFloor > difficulty.maxFloors) {
        isPlaying = false;
        isPaused = true;
        overlays.add('victory');
        return;
      }
      _buildFloorPath();
      overlays.add('pathSelect');
      return;
    }
    _startLevel();
  }

  void spendSkill(String key) {
    if (skillPoints <= 0) return;
    skillPoints--;
    switch (key) {
      case 'hp':
        skills.hp++;
        break;
      case 'speed':
        skills.speed++;
        break;
      case 'attackSpeed':
        skills.attackSpeed++;
        break;
      case 'defense':
        skills.defense++;
        break;
      case 'damage':
        skills.damage++;
        break;
    }
    recomputeStats();
    if (player.health > maxHealth) player.health = maxHealth.toDouble();
  }

  void resolveMerchantBuy(String id) {
    // PART 4
  }

  void closeMerchant() {
    overlays.remove('eventMerchant');
    isPaused = false;
    eventResolved = true;
  }

  void _buildFloorPath() {
    // PART 4
  }

  void _startLevel({bool forceArena = false}) {
    // PART 4
  }
    // ── floor path ──

  void _buildFloorPath() {
    floorPath = [];
    // 5 nodes: combat / event / combat / elite|combat / boss
    floorPath.add(PathNode(PathNodeKind.combat, 'Бой'));
    floorPath.add(Random().nextBool() ? PathNode(PathNodeKind.event, 'Событие') : PathNode(PathNodeKind.combat, 'Бой'));
    floorPath.add(PathNode(PathNodeKind.combat, 'Бой'));
    floorPath.add(Random().nextDouble() < 0.45 ? PathNode(PathNodeKind.elite, 'Элита') : PathNode(PathNodeKind.combat, 'Бой'));
    floorPath.add(PathNode(PathNodeKind.boss, 'Босс'));
    pathIndex = 0;
    currentLevel = 1;
  }

  List<Vector2> getEnemySpawnPointsRaw() {
    final cx = mapWidth / 2, cy = mapHeight / 2;
    final pts = <Vector2>[];
    switch (((currentFloor - 1) % 5) + 1) {
      case 1: // corners
        pts.addAll([
          Vector2(180, 180),
          Vector2(mapWidth - 180, 180),
          Vector2(180, mapHeight - 180),
          Vector2(mapWidth - 180, mapHeight - 180),
          Vector2(cx, 160),
          Vector2(cx, mapHeight - 160),
          Vector2(160, cy),
          Vector2(mapWidth - 160, cy),
        ]);
        break;
      case 2: // sides
        for (double y = 160; y < mapHeight - 160; y += 140) {
          pts.add(Vector2(160, y));
          pts.add(Vector2(mapWidth - 160, y));
        }
        break;
      default: // grid
        for (double x = 160; x < mapWidth - 160; x += 180) {
          for (double y = 160; y < mapHeight - 160; y += 180) {
            pts.add(Vector2(x, y));
          }
        }
    }
    return pts.where((p) => p.x > 100 && p.x < mapWidth - 100 && p.y > 100 && p.y < mapHeight - 100).toList();
  }

  List<Vector2> getEnemySpawnPoints() {
    final origin = playerSpawnPos;
    return getEnemySpawnPointsRaw().where((p) => p.distanceTo(origin) >= safeRadius + 40).toList();
  }

  EventRoomType _rollEvent() {
    levelsSinceEvent++;
    if (levelsSinceEvent < 2) return EventRoomType.none;
    if (Random().nextDouble() < 0.55) {
      levelsSinceEvent = 0;
      final r = Random().nextDouble();
      if (r < 0.34) return EventRoomType.altar;
      if (r < 0.67) return EventRoomType.merchant;
      return EventRoomType.trap;
    }
    return EventRoomType.none;
  }

  void _forceSpawnPortal({bool fromTimer = false}) {
    if (portalSpawned) return;
    portalSpawned = true;
    if (fromTimer) timedPortalUsed = true;
    for (final p in world.children.whereType<Portal>().toList()) {
      p.removeFromParent();
    }
    world.add(Portal(position: Vector2(mapWidth / 2, 160))..priority = 9);
    spawnDamageNumber(
      Vector2(mapWidth / 2, 200),
      0,
      color: const Color(0xFFE040FB),
      label: fromTimer ? 'ПОРТАЛ (5 мин)' : 'ПОРТАЛ',
    );
  }

  int countLivingHostiles() {
    int n = 0;
    n += world.children.whereType<Enemy>().length;
    n += world.children.whereType<MiniBoss>().length;
    n += world.children.whereType<Boss>().length;
    n += world.children.whereType<KnightBoss>().length;
    n += world.children.whereType<KingBoss>().length;
    n += world.children.whereType<TentacleBoss>().length;
    n += world.children.whereType<CyclopsBoss>().length;
    n += world.children.whereType<PlagueLordBoss>().length;
    n += world.children.whereType<BloodChampionBoss>().length;
    return n;
  }

  void _checkPortal() {
    if (portalSpawned || isArena) return;
    if (countLivingHostiles() <= 0 && enemiesSpawned >= enemiesToSpawn && !isBossLevel) {
      _forceSpawnPortal();
      return;
    }
    if (isBossLevel && countLivingHostiles() <= 0 && secretBossSpawned == false) {
      _forceSpawnPortal();
    }
  }

  void _clearWorldKeepPlayer() {
    for (final c in world.children.toList()) {
      if (c is Player) continue;
      c.removeFromParent();
    }
  }

  void _buildMapGeometry() {
    // floor visual + border walls
    world.add(FloorLayer(size: Vector2(mapWidth, mapHeight))..priority = 0);
    const t = 40.0;
    world.add(Wall(position: Vector2(mapWidth / 2, t / 2), size: Vector2(mapWidth, t)));
    world.add(Wall(position: Vector2(mapWidth / 2, mapHeight - t / 2), size: Vector2(mapWidth, t)));
    world.add(Wall(position: Vector2(t / 2, mapHeight / 2), size: Vector2(t, mapHeight)));
    world.add(Wall(position: Vector2(mapWidth - t / 2, mapHeight / 2), size: Vector2(t, mapHeight)));

    // obstacles away from spawn
    final rnd = Random(currentFloor * 97 + currentLevel * 13);
    final count = 6 + currentFloor;
    for (int i = 0; i < count; i++) {
      final p = Vector2(
        120 + rnd.nextDouble() * (mapWidth - 240),
        120 + rnd.nextDouble() * (mapHeight - 240),
      );
      if (p.distanceTo(playerSpawnPos) < safeRadius) continue;
      if (rnd.nextDouble() < 0.35) {
        world.add(BreakableBarrel(position: p)..priority = 8);
      } else {
        world.add(Obstacle(position: p)..priority = 7);
      }
    }
  }

  EnemyType _rollEnemyType() {
    final f = currentFloor;
    final pool = <EnemyType>[EnemyType.shooter, EnemyType.melee, EnemyType.shielded];
    if (f >= 2) pool.add(EnemyType.dog);
    if (f >= 3) pool.addAll([EnemyType.flamer, EnemyType.sniper]);
    if (f >= 4) pool.add(EnemyType.brute);
    if (f >= 3) pool.add(EnemyType.cultPsyker);
    if (f >= 4) pool.addAll([EnemyType.plagueBearer, EnemyType.bloodletter]);
    if (f >= 4) pool.add(EnemyType.shieldedShooter);
    return pool[Random().nextInt(pool.length)];
  }

  EliteAffix _rollAffix() {
    final v = EliteAffix.values.where((e) => e != EliteAffix.none).toList();
    return v[Random().nextInt(v.length)];
  }

  void _spawnWave({bool eliteRoom = false}) {
    final points = getEnemySpawnPoints();
    if (points.isEmpty) return;
    final base = 4 + currentFloor + currentLevel;
    enemiesToSpawn = isArena ? 9999 : base;
    enemiesSpawned = 0;
    enemiesAlive = 0;

    final toSpawnNow = isArena ? 8 : base;
    for (int i = 0; i < toSpawnNow; i++) {
      final pos = points[Random().nextInt(points.length)].clone();
      final isChamp = eliteRoom || Random().nextDouble() < 0.12 + currentFloor * 0.01;
      final e = Enemy(
        floor: currentFloor,
        type: _rollEnemyType(),
        isChampion: isChamp,
        affix: isChamp ? _rollAffix() : EliteAffix.none,
      );
      e.position = pos;
      world.add(e);
      enemiesSpawned++;
      enemiesAlive++;
    }
  }

  void _spawnBosses() {
    final cx = mapWidth / 2, cy = mapHeight / 2 - 40;
    final f = currentFloor;

    if (f % 5 == 0 || f == difficulty.maxFloors) {
      // king + retinue
      world.add(KingBoss(position: Vector2(cx, cy)));
      world.add(Boss(floor: f, position: Vector2(cx - 160, cy + 40)));
      world.add(KnightBoss(floor: f, position: Vector2(cx + 160, cy + 40)));
      if (f >= 7) world.add(PlagueLordBoss(position: Vector2(cx, cy + 140)));
      if (f >= 8) world.add(BloodChampionBoss(position: Vector2(cx, cy - 120)));
    } else if (f % 3 == 0) {
      world.add(MiniBoss(floor: f, position: Vector2(cx, cy)));
      world.add(Boss(floor: f, position: Vector2(cx + 120, cy + 60)));
    } else {
      world.add(Boss(floor: f, position: Vector2(cx, cy)));
      if (f >= 3) world.add(KnightBoss(floor: f, position: Vector2(cx + 140, cy)));
    }
    enemiesToSpawn = 0;
    enemiesSpawned = 0;
  }

  void _startLevel({bool forceArena = false}) {
    _clearWorldKeepPlayer();
    portalSpawned = false;
    timedPortalUsed = false;
    secretBossSpawned = false;
    eventResolved = false;
    nearPortal = false;
    levelTimer = 0;
    killsThisLevel = 0;
    ironWillUsedThisFloor = false;
    bolterHeat = 0;
    staffWarpStress = 0;
    combo = 0;
    comboTimer = 0;
    currentEvent = EventRoomType.none;

    mapWidth = 1300 + currentFloor * 40.0;
    mapHeight = 950 + currentFloor * 30.0;
    playerSpawnPos = Vector2(180, mapHeight / 2);
    _buildMapGeometry();

    if (!world.children.whereType<Player>().isNotEmpty) {
      player = Player(position: playerSpawnPos.clone(), pClass: playerClass);
      world.add(player);
    } else {
      player.position = playerSpawnPos.clone();
    }
    recomputeStats();
    player.health = maxHealth.toDouble();
    camera.follow(player);
    rebuildHud();

    if (forceArena || isArena) {
      isArena = true;
      _spawnWave();
      ensureBgm();
      isPlaying = true;
      isPaused = false;
      return;
    }

    final node = floorPath.isNotEmpty && pathIndex < floorPath.length
        ? floorPath[pathIndex]
        : PathNode(PathNodeKind.combat, 'Бой');

    switch (node.kind) {
      case PathNodeKind.boss:
        _spawnBosses();
        break;
      case PathNodeKind.elite:
        _spawnWave(eliteRoom: true);
        break;
      case PathNodeKind.event:
        currentEvent = _rollEvent();
        if (currentEvent == EventRoomType.none) currentEvent = EventRoomType.altar;
        _spawnEventProps();
        break;
      case PathNodeKind.rest:
        player.heal(3);
        _forceSpawnPortal();
        break;
      case PathNodeKind.combat:
        _spawnWave();
        break;
    }

    // echo boss chance
    if (lastBossEcho != EchoBossKind.none && Random().nextDouble() < 0.10 && node.kind == PathNodeKind.combat) {
      _spawnEcho(lastBossEcho);
    }

    ensureBgm();
    isPlaying = true;
    isPaused = false;
  }

  void _spawnEventProps() {
    final c = Vector2(mapWidth / 2, mapHeight / 2);
    switch (currentEvent) {
      case EventRoomType.altar:
        world.add(EventAltar(position: c)..priority = 9);
        overlays.add('eventAltar');
        isPaused = true;
        break;
      case EventRoomType.merchant:
        world.add(EventMerchant(position: c)..priority = 9);
        overlays.add('eventMerchant');
        isPaused = true;
        break;
      case EventRoomType.trap:
        for (int i = 0; i < 10; i++) {
          final a = i / 10 * pi * 2;
          world.add(Enemy(floor: currentFloor, type: EnemyType.melee)
            ..position = c + Vector2(cos(a) * 120, sin(a) * 120));
          enemiesSpawned++;
          enemiesAlive++;
          enemiesToSpawn++;
        }
        break;
      case EventRoomType.none:
        break;
    }
  }

  void _spawnEcho(EchoBossKind kind) {
    final p = Vector2(mapWidth / 2 + 80, mapHeight / 2 - 80);
    switch (kind) {
      case EchoBossKind.mini:
        world.add(MiniBoss(floor: currentFloor, position: p, isEcho: true));
        break;
      case EchoBossKind.ranged:
        world.add(Boss(floor: currentFloor, position: p, isEcho: true));
        break;
      case EchoBossKind.knight:
        world.add(KnightBoss(floor: currentFloor, position: p, isEcho: true));
        break;
      case EchoBossKind.king:
        world.add(KingBoss(position: p, isEcho: true));
        break;
      case EchoBossKind.plague:
        world.add(PlagueLordBoss(position: p, isEcho: true));
        break;
      case EchoBossKind.blood:
        world.add(BloodChampionBoss(position: p, isEcho: true));
        break;
      case EchoBossKind.none:
        break;
    }
  }

  void nextLevel() {
    portalSpawned = false;
    nearPortal = false;
    isPaused = true;
    skillPoints += 1;
    scraps += 3 + currentFloor;
    overlays.add('reward');
  }

  void onEnemyKilled({
    Vector2? at,
    bool isChampion = false,
    bool isBoss = false,
    EnemyType? type,
    bool meleeKill = false,
    EliteAffix affix = EliteAffix.none,
    EchoBossKind echoKind = EchoBossKind.none,
    Vector2? fromDir,
  }) {
    killsThisLevel++;
    enemiesAlive = max(0, enemiesAlive - 1);
    unlockAchievement(AchievementId.firstBlood);

    combo++;
    comboTimer = 2.5;
    if (combo >= 15) unlockAchievement(AchievementId.combo15);
    if (combo == 5 || combo == 10 || combo == 15) {
      scraps += 1;
      if (at != null) world.add(ComboBanner(position: at, combo: combo));
    }

    var pts = 10 + currentFloor * 2;
    if (isChampion) {
      pts *= 3;
      achievements.championsKilledTotal++;
      if (achievements.championsKilledTotal >= 10) unlockAchievement(AchievementId.championHunter);
      scraps += hasScavenger ? 5 : 3;
      if (Random().nextDouble() < 0.25) {
        _grantRandomRelic();
      }
    }
    if (isBoss) {
      pts *= 8;
      unlockAchievement(AchievementId.bossSlayer);
      if (echoKind != EchoBossKind.none) lastBossEcho = echoKind;
    }
    score += (pts * (1 + combo * 0.05)).round();

    if (isArena) {
      arenaKills++;
      if (arenaKills >= 50) unlockAchievement(AchievementId.arena50);
      if (arenaKills >= 100) unlockAchievement(AchievementId.arena100);
      // endless: keep spawning
      if (enemiesAlive < 6) {
        final points = getEnemySpawnPoints();
        if (points.isNotEmpty) {
          final e = Enemy(floor: currentFloor, type: _rollEnemyType(), isChampion: arenaKills % 100 == 0, affix: arenaKills % 100 == 0 ? _rollAffix() : EliteAffix.none);
          e.position = points[Random().nextInt(points.length)];
          world.add(e);
          enemiesAlive++;
          enemiesSpawned++;
        }
        if (arenaKills % 100 == 0) {
          world.add(Boss(floor: currentFloor, position: Vector2(mapWidth / 2, mapHeight / 2)));
        }
      }
    }

    // mastery
    if (meleeKill) {
      mastery.addKill(meleeWeapon.name);
    } else {
      mastery.addKill(rangedWeapon.name.contains('staff') || rangedWeapon == RangedWeapon.staff || rangedWeapon == RangedWeapon.stormStaff || rangedWeapon == RangedWeapon.warpBeam
          ? 'staff'
          : rangedWeapon == RangedWeapon.bolter || rangedWeapon == RangedWeapon.rifle || rangedWeapon == RangedWeapon.shotgun
              ? 'bolter'
              : rangedWeapon.name);
    }

    if (hasLifesteal && Random().nextDouble() < 0.15) {
      player.heal(1);
    }
    if (hasHaste) {
      hasteTimer = 3.0;
    }
    if (hasKillExplosion && at != null) {
      world.add(KillExplosion(position: at, radius: 70, damage: scaleDamage(8), applyBurn: true));
    }
    if (type != null) {
      final codex = switch (type) {
        EnemyType.shooter => CodexId.shooter,
        EnemyType.melee => CodexId.melee,
        EnemyType.shielded => CodexId.shielded,
        EnemyType.dog => CodexId.dog,
        EnemyType.shieldedShooter => CodexId.shieldedShooter,
        EnemyType.flamer => CodexId.flamer,
        EnemyType.sniper => CodexId.sniper,
        EnemyType.brute => CodexId.brute,
        EnemyType.cultPsyker => CodexId.cultPsyker,
        EnemyType.plagueBearer => CodexId.plagueBearer,
        EnemyType.bloodletter => CodexId.bloodletter,
      };
      unlockCodex(codex);
    }
    if (scraps >= 100) unlockAchievement(AchievementId.scrapHoarder);
    if (relics.length >= 5) unlockAchievement(AchievementId.relicHunter);

    _checkPortal();
  }

  void onSecretBossKilled({required bool cyclops}) {
    score += 6666;
    skillPoints += 1;
    if (cyclops) {
      unlockAchievement(AchievementId.secretCyclops);
      unlockCodex(CodexId.cyclops);
    } else {
      unlockAchievement(AchievementId.secretTentacle);
      unlockCodex(CodexId.tentacle);
    }
    _forceSpawnPortal();
  }

  void _grantRandomRelic() {
    final pool = RelicId.values.where((r) => !relics.contains(r)).toList();
    if (pool.isEmpty) return;
    final r = pool[Random().nextInt(pool.length)];
    relics.add(r);
    spawnDamageNumber(player.position, 0, color: const Color(0xFFFFD700), label: r.title);
  }

  // ── secret corner 33s ──
  double cornerTimer = 0;

  void _updateSecretCorner(double dt) {
    if (secretBossSpawned || !isBossLevel) return;
    if (countLivingHostiles() > 0) {
      cornerTimer = 0;
      return;
    }
    final inCorner = player.position.x < 120 && player.position.y < 120;
    if (!inCorner) {
      cornerTimer = 0;
      return;
    }
    cornerTimer += dt;
    if (cornerTimer >= 33) {
      secretBossSpawned = true;
      final pos = Vector2(mapWidth / 2, mapHeight / 2);
      if (currentFloor == 1 || (currentFloor % 5 == 0 && currentFloor < 10)) {
        world.add(TentacleBoss(position: pos));
      } else if (currentFloor >= 2) {
        world.add(CyclopsBoss(position: pos));
      }
      spawnDamageNumber(pos, 0, color: const Color(0xFF9C27B0), label: 'СЕКРЕТ');
      triggerShake(power: 12, time: 0.4);
    }
  }

  // ── update ──

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying) return;

    // camera shake / cinema
    if (shakeTimer > 0) {
      shakeTimer -= dt;
      final ox = (Random().nextDouble() - 0.5) * shakePower * 2;
      final oy = (Random().nextDouble() - 0.5) * shakePower * 2;
      camera.viewfinder.position = player.position + Vector2(ox, oy);
    } else if (!camera.viewfinder.isFollowing) {
      camera.follow(player);
    }
    if (cinemaZoomTimer > 0) {
      cinemaZoomTimer -= dt;
      camera.viewfinder.zoom = 1.0 + 0.15 * (cinemaZoomTimer / 0.4);
    } else {
      camera.viewfinder.zoom = 1.0;
    }

    if (isPaused) return;

    runTimeAcc += dt;
    if (runTimeAcc >= 1) {
      runTimeAcc = 0;
      runSeconds++;
    }
    levelTimer += dt;

    // 5-minute portal
    if (!portalSpawned && !isArena && levelTimer >= timedPortalSec) {
      _forceSpawnPortal(fromTimer: true);
    }

    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 0;
    }
    if (invulnTimer > 0) invulnTimer -= dt;
    if (shieldTimer > 0) shieldTimer -= dt;
    if (hasteTimer > 0) hasteTimer -= dt;
    if (dashCooldown > 0) dashCooldown -= dt;
    if (laserCooldown > 0) laserCooldown -= dt;
    if (artifactCd > 0) artifactCd -= dt;
    if (warpResetCd > 0) warpResetCd -= dt;
    if (bossRetreatTimer > 0) bossRetreatTimer -= dt;

    // heat dissipation
    bolterHeat = max(0, bolterHeat - dt * (hasAmmoSavant ? 0.35 : 0.25));
    staffWarpStress = max(0, staffWarpStress - dt * (hasWarpAnchor ? 0.2 : 0.12));

    // portal proximity
    nearPortal = false;
    for (final p in world.children.whereType<Portal>()) {
      if (player.position.distanceTo(p.position) < 70) {
        nearPortal = true;
        break;
      }
    }
    portalBtn?.opacity = nearPortal ? 1.0 : 0.0;

    _updateSecretCorner(dt);
    _checkPortal();

    // arena continuous spawn
    if (isArena && enemiesAlive < 8) {
      final points = getEnemySpawnPoints();
      if (points.isNotEmpty) {
        final e = Enemy(floor: max(1, currentFloor), type: _rollEnemyType());
        e.position = points[Random().nextInt(points.length)];
        world.add(e);
        enemiesAlive++;
        enemiesSpawned++;
      }
    }
  }

  // ── save / load ──

  Future<void> saveGame() async {
    final payload = jsonEncode({
      'floor': currentFloor,
      'level': currentLevel,
      'pathIndex': pathIndex,
      'score': score,
      'scraps': scraps,
      'sp': skillPoints,
      'skills': skills.toJson(),
      'mastery': mastery.toJson(),
      'relics': relics.map((e) => e.name).toList(),
      'loadout': loadout.toJson(),
      'lore': loreRanks,
      'codex': codexUnlocked.map((e) => e.name).toList(),
      'hp': player.health,
      'rw': rangedWeapon.name,
      'mw': meleeWeapon.name,
      'um': usingMelee,
      'pc': playerClass.name,
      'diff': difficulty.name,
      'name': playerName,
      'seconds': runSeconds,
    });
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final gs = GameSave(
      name: playerName,
      dateStr: dateStr,
      playerClass: playerClass.name,
      difficulty: difficulty.labelRu,
      floor: currentFloor,
      level: currentLevel,
      score: score,
      scraps: scraps,
      skillPoints: skillPoints,
      skills: skills.toJson(),
      mastery: mastery.toJson(),
      relics: relics.map((e) => e.name).toList(),
      loadout: loadout.toJson(),
      loreRanks: Map<String, int>.from(loreRanks),
      codex: codexUnlocked.map((e) => e.name).toList(),
      health: player.health.round(),
      ranged: rangedWeapon.name,
      melee: meleeWeapon.name,
      usingMelee: usingMelee,
      payload: payload,
    );
    saves.insert(0, gs);
    if (saves.length > 10) saves = saves.take(10).toList();
    await _saveMeta();
    spawnDamageNumber(player.position, 0, color: const Color(0xFF69F0AE), label: 'СОХРАНЕНО');
  }

  Future<void> deleteSave(int index) async {
    if (index < 0 || index >= saves.length) return;
    saves.removeAt(index);
    await _saveMeta();
  }

  Future<void> deleteAllSaves() async {
    saves.clear();
    await _saveMeta();
  }

  void loadSave(GameSave s) {
    try {
      final j = jsonDecode(s.payload) as Map<String, dynamic>;
      playerName = j['name'] as String? ?? s.name;
      playerClass = PlayerClass.values.firstWhere((e) => e.name == j['pc'], orElse: () => PlayerClass.xenos);
      difficulty = Difficulty.values.firstWhere((e) => e.name == j['diff'], orElse: () => Difficulty.normal);
      currentFloor = j['floor'] as int? ?? 1;
      currentLevel = j['level'] as int? ?? 1;
      pathIndex = j['pathIndex'] as int? ?? 0;
      score = j['score'] as int? ?? 0;
      scraps = j['scraps'] as int? ?? 0;
      skillPoints = j['sp'] as int? ?? 0;
      skills = SkillTree.fromJson(j['skills'] as Map<String, dynamic>?);
      mastery = WeaponMastery.fromJson(j['mastery'] as Map<String, dynamic>?);
      relics
        ..clear()
        ..addAll((j['relics'] as List? ?? []).map((e) => RelicId.values.firstWhere((r) => r.name == e, orElse: () => RelicId.crit)));
      loadout = WeaponLoadout.fromJson(j['loadout'] as Map<String, dynamic>?);
      loreRanks
        ..clear()
        ..addAll((j['lore'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {});
      codexUnlocked
        ..clear()
        ..addAll((j['codex'] as List? ?? []).map((e) => CodexId.values.firstWhere((c) => c.name == e, orElse: () => CodexId.shooter)));
      rangedWeapon = RangedWeapon.values.firstWhere((e) => e.name == j['rw'], orElse: () => RangedWeapon.bolter);
      meleeWeapon = MeleeWeapon.values.firstWhere((e) => e.name == j['mw'], orElse: () => MeleeWeapon.sword);
      usingMelee = j['um'] as bool? ?? false;
      runSeconds = j['seconds'] as int? ?? 0;
      _buildFloorPath();
      pathIndex = (currentLevel - 1).clamp(0, floorPath.length - 1);
      for (final o in overlays.activeOverlays.toList()) {
        overlays.remove(o);
      }
      _startLevel();
      player.health = (j['hp'] as num?)?.toDouble() ?? maxHealth.toDouble();
    } catch (_) {
      backToMenu();
    }
  }

  void resolveMerchantBuy(String id) {
    switch (id) {
      case 'heal':
        if (scraps >= 8) {
          scraps -= 8;
          player.heal(3);
        }
        break;
      case 'scraps_sp':
        if (scraps >= 12) {
          scraps -= 12;
          skillPoints++;
        }
        break;
      case 'relic':
        if (scraps >= 20) {
          scraps -= 20;
          _grantRandomRelic();
        }
        break;
      case 'gun_rapid':
        if (scraps >= 15 && playerClass == PlayerClass.xenos) {
          scraps -= 15;
          loadout.gunBarrel = GunBarrelMod.rapid;
        }
        break;
      case 'gun_heavy':
        if (scraps >= 15 && playerClass == PlayerClass.xenos) {
          scraps -= 15;
          loadout.gunBarrel = GunBarrelMod.heavy;
        }
        break;
      case 'gun_precision':
        if (scraps >= 12 && playerClass == PlayerClass.xenos) {
          scraps -= 12;
          loadout.gunSight = GunSightMod.precision;
        }
        break;
      case 'gun_explosive':
        if (scraps >= 18 && playerClass == PlayerClass.xenos) {
          scraps -= 18;
          loadout.gunAmmo = GunAmmoMod.explosive;
        }
        break;
      case 'staff_wide':
        if (scraps >= 15 && playerClass == PlayerClass.malleus) {
          scraps -= 15;
          loadout.staffFocus = StaffFocusMod.wideSphere;
        }
        break;
      case 'staff_focus':
        if (scraps >= 15 && playerClass == PlayerClass.malleus) {
          scraps -= 15;
          loadout.staffFocus = StaffFocusMod.focusCore;
        }
        break;
      case 'staff_dissipator':
        if (scraps >= 14 && playerClass == PlayerClass.malleus) {
          scraps -= 14;
          loadout.staffFocus = StaffFocusMod.dissipator;
        }
        break;
      case 'blade_serrated':
        if (scraps >= 14 && playerClass == PlayerClass.hereticus) {
          scraps -= 14;
          loadout.bladeEdge = BladeEdgeMod.serrated;
        }
        break;
      case 'blade_mono':
        if (scraps >= 16 && playerClass == PlayerClass.hereticus) {
          scraps -= 16;
          loadout.bladeEdge = BladeEdgeMod.monomolecular;
        }
        break;
    }
    recomputeStats();
  }

  void startNewRun({
    required String name,
    required Difficulty diff,
    required PlayerClass cls,
    RankChallenge challenge = RankChallenge.none,
  }) {
    playerName = name;
    difficulty = diff;
    playerClass = cls;
    activeChallenge = challenge;
    achievements.classesPlayed.add(cls.name);
    if (achievements.classesPlayed.length >= 3) unlockAchievement(AchievementId.allClasses);

    score = 0;
    scraps = rank.startScraps;
    skillPoints = rank.startSpBonus;
    skills = SkillTree();
    mastery = WeaponMastery();
    loadout = WeaponLoadout();
    relics.clear();
    currentFloor = 1;
    currentLevel = 1;
    pathIndex = 0;
    runSeconds = 0;
    isArena = false;
    lastBossEcho = EchoBossKind.none;

    rangedWeapon = switch (cls) {
      PlayerClass.xenos => RangedWeapon.bolter,
      PlayerClass.malleus => RangedWeapon.staff,
      PlayerClass.hereticus => RangedWeapon.daggers,
    };
    meleeWeapon = switch (cls) {
      PlayerClass.xenos => MeleeWeapon.sword,
      PlayerClass.malleus => MeleeWeapon.forceBlade,
      PlayerClass.hereticus => MeleeWeapon.katana,
    };
    usingMelee = false;
    activeArtifact = ActiveArtifact.fragGrenade;

    _buildFloorPath();
    for (final o in overlays.activeOverlays.toList()) {
      overlays.remove(o);
    }
    recomputeStats();
    _startLevel();
  }
}
// ─── WORLD PROPS ──────────────────────────────────────────────

class FloorLayer extends PositionComponent {
  FloorLayer({required Vector2 size})
      : super(position: Vector2.zero(), size: size, priority: 0);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF2A2A2E));
    final grid = Paint()
      ..color = const Color(0xFF3A3A40)
      ..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
    }
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  Wall({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.center, priority: 5);

  @override
  Future<void> onLoad() async => add(RectangleHitbox());

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF5D4037));
    canvas.drawRect(
      size.toRect().deflate(3),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({required Vector2 position})
      : super(position: position, size: Vector2(40, 40), anchor: Anchor.center, priority: 7);

  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 18));

  @override
  void render(Canvas canvas) {
    WHDraw.barrel(canvas, size.x / 2, size.y / 2);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 16, Paint()..color = const Color(0xFF6D4C41));
  }
}

class BreakableBarrel extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  int hp = 2;
  BreakableBarrel({required Vector2 position})
      : super(position: position, size: Vector2(36, 40), anchor: Anchor.center, priority: 8);

  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 16));

  void hit() {
    hp--;
    if (hp <= 0) {
      if (Random().nextDouble() < 0.4) {
        game.scraps += game.hasScavenger ? 3 : 1;
      }
      if (Random().nextDouble() < 0.08) {
        game.world.add(KillExplosion(position: position.clone(), radius: 55, damage: 5, applyBurn: true));
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    WHDraw.barrel(canvas, size.x / 2, size.y / 2);
  }
}

class Portal extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  double t = 0;
  Portal({required Vector2 position})
      : super(position: position, size: Vector2(70, 70), anchor: Anchor.center, priority: 9);

  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 28));

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final pulse = 0.6 + 0.4 * sin(t * 4);
    canvas.drawCircle(Offset(cx, cy), 30 * pulse, Paint()..color = const Color(0xFFE040FB).withOpacity(0.35));
    canvas.drawCircle(Offset(cx, cy), 18, Paint()..color = const Color(0xFF9C27B0));
    canvas.drawCircle(Offset(cx, cy), 10, Paint()..color = const Color(0xFFF3E5F5));
  }
}

class CorruptionPuddle extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  double life = 8;
  double tick = 0;
  CorruptionPuddle({required Vector2 position})
      : super(position: position, size: Vector2(90, 90), anchor: Anchor.center, priority: 5);

  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 40));

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    tick += dt;
    if (tick >= 0.5) {
      tick = 0;
      if (game.player.position.distanceTo(position) < 45 && game.invulnTimer <= 0) {
        game.player.applyStatus(StatusType.corruption, 1.2, tickDamage: 1);
      }
    }
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / 8).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 40, Paint()..color = Color.fromRGBO(156, 39, 176, 0.35 * a));
  }
}

class EventAltar extends PositionComponent with HasGameReference<InquisitorGame> {
  double t = 0;
  EventAltar({required Vector2 position})
      : super(position: position, size: Vector2(50, 50), anchor: Anchor.center, priority: 9);

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
  }

  @override
  void render(Canvas canvas) => WHDraw.altar(canvas, size.x / 2, size.y / 2, t);
}

class EventMerchant extends PositionComponent with HasGameReference<InquisitorGame> {
  double t = 0;
  EventMerchant({required Vector2 position})
      : super(position: position, size: Vector2(56, 48), anchor: Anchor.center, priority: 9);

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
  }

  @override
  void render(Canvas canvas) => WHDraw.merchantStall(canvas, size.x / 2, size.y / 2, t);
}

class ServoTurret extends PositionComponent with HasGameReference<InquisitorGame> {
  double life = 8;
  double fireCd = 0;
  ServoTurret({required Vector2 position})
      : super(position: position, size: Vector2(36, 36), anchor: Anchor.center, priority: 20);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    fireCd -= dt;
    if (life <= 0) {
      removeFromParent();
      return;
    }
    if (fireCd > 0) return;
    PositionComponent? target;
    double best = 400;
    void consider(PositionComponent c, double hpHint) {
      final d = position.distanceTo(c.position);
      if (d < best) {
        best = d;
        target = c;
      }
    }
    for (final e in game.world.children.whereType<Enemy>()) {
      consider(e, 1);
    }
    for (final e in game.world.children.whereType<MiniBoss>()) {
      consider(e, 1);
    }
    for (final e in game.world.children.whereType<Boss>()) {
      consider(e, 1);
    }
    for (final e in game.world.children.whereType<KnightBoss>()) {
      consider(e, 1);
    }
    for (final e in game.world.children.whereType<KingBoss>()) {
      consider(e, 1);
    }
    for (final e in game.world.children.whereType<PlagueLordBoss>()) {
      consider(e, 1);
    }
    for (final e in game.world.children.whereType<BloodChampionBoss>()) {
      consider(e, 1);
    }
    for (final e in game.world.children.whereType<TentacleBoss>()) {
      consider(e, 1);
    }
    for (final e in game.world.children.whereType<CyclopsBoss>()) {
      consider(e, 1);
    }
    if (target != null) {
      fireCd = 0.45;
      final dir = (target!.position - position).normalized();
      game.world.add(Bullet(
        position: position.clone(),
        direction: dir,
        damage: game.scaleDamage(5).toDouble(),
        color: const Color(0xFF90CAF9),
        speed: 420,
        radius: 4,
      )..priority = 16);
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = const Color(0xFF546E7A));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx + 10, cy), width: 16, height: 6), Paint()..color = const Color(0xFF90CAF9));
  }
}

// ─── MENUS ────────────────────────────────────────────────────

class MatrixBackground extends StatefulWidget {
  const MatrixBackground({super.key});
  @override
  State<MatrixBackground> createState() => _MatrixBackgroundState();
}

class _MatrixBackgroundState extends State<MatrixBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rnd = Random();
  final _chars = '01ИНКВИЗИТОРΞΨ†';

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return CustomPaint(
          painter: _MatrixPainter(_c.value, _rnd, _chars),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MatrixPainter extends CustomPainter {
  final double t;
  final Random rnd;
  final String chars;
  _MatrixPainter(this.t, this.rnd, this.chars);

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < 40; i++) {
      final x = (i * 37 + t * 20) % size.width;
      final y = (i * 53 + t * size.height * 0.5) % size.height;
      final ch = chars[i % chars.length];
      tp.text = TextSpan(
        text: ch,
        style: TextStyle(color: Color.fromRGBO(0, 255, 70, 0.15 + (i % 5) * 0.05), fontSize: 14),
      );
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixPainter old) => true;
}

Widget _goldBtn(String label, VoidCallback onTap, {double width = 260}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      width: width,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: const Color(0xFFFFD700),
          side: const BorderSide(color: Color(0xFFB8860B), width: 1.5),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    ),
  );
}

class MainMenu extends StatelessWidget {
  final InquisitorGame game;
  const MainMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const MatrixBackground(),
        Container(color: Colors.black.withOpacity(0.55)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SOUL OF THE\nINQUISITOR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  shadows: [Shadow(color: Color(0xFFB71C1C), blurRadius: 12)],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Инквизитор Данте', style: TextStyle(color: Color(0xFFB8860B), fontSize: 13)),
              const SizedBox(height: 28),
              _goldBtn('Начать игру', () {
                game.overlays.remove('mainMenu');
                game.overlays.add('nameInput');
              }),
              _goldBtn('Загрузить сохранение', () {
                game.overlays.remove('mainMenu');
                game.overlays.add('loadSave');
              }),
              _goldBtn('Рекорды', () {
                game.overlays.remove('mainMenu');
                game.overlays.add('records');
              }),
              _goldBtn('Достижения', () {
                game.overlays.remove('mainMenu');
                game.overlays.add('achievements');
              }),
              _goldBtn('Настройки', () {
                game.overlays.remove('mainMenu');
                game.overlays.add('settings');
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class NameInputMenu extends StatefulWidget {
  final InquisitorGame game;
  const NameInputMenu(this.game, {super.key});
  @override
  State<NameInputMenu> createState() => _NameInputMenuState();
}

class _NameInputMenuState extends State<NameInputMenu> {
  final ctrl = TextEditingController(text: 'Аколит');
  Difficulty diff = Difficulty.normal;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Имя инквизитора', style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF1A1A1A),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Сложность', style: TextStyle(color: Colors.white70)),
              Wrap(
                spacing: 8,
                children: Difficulty.values.map((d) {
                  final sel = diff == d;
                  return ChoiceChip(
                    label: Text(d.labelRu),
                    selected: sel,
                    onSelected: (_) => setState(() => diff = d),
                    selectedColor: const Color(0xFFB71C1C),
                    labelStyle: TextStyle(color: sel ? Colors.white : Colors.white70),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _goldBtn('Далее', () {
                widget.game.playerName = ctrl.text.trim().isEmpty ? 'Аколит' : ctrl.text.trim();
                widget.game.difficulty = diff;
                widget.game.overlays.remove('nameInput');
                widget.game.overlays.add('challengeSelect');
              }),
              _goldBtn('Назад', () {
                widget.game.overlays.remove('nameInput');
                widget.game.overlays.add('mainMenu');
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeSelectMenu extends StatelessWidget {
  final InquisitorGame game;
  const ChallengeSelectMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ранговое испытание', style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...RankChallenge.values.map((c) => _goldBtn('${c.title}\n${c.desc}', () {
                  game.activeChallenge = c;
                  game.overlays.remove('challengeSelect');
                  game.overlays.add('classSelect');
                }, width: 320)),
          ],
        ),
      ),
    );
  }
}

class ClassSelectMenu extends StatelessWidget {
  final InquisitorGame game;
  const ClassSelectMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выбор ордо', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...PlayerClass.values.map((cls) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                    child: ElevatedButton(
                      onPressed: () {
                        game.overlays.remove('classSelect');
                        game.startNewRun(
                          name: game.playerName,
                          diff: game.difficulty,
                          cls: cls,
                          challenge: game.activeChallenge,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(cls.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(cls.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  )),
              _goldBtn('Назад', () {
                game.overlays.remove('classSelect');
                game.overlays.add('challengeSelect');
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsMenu extends StatefulWidget {
  final InquisitorGame game;
  const SettingsMenu(this.game, {super.key});
  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final h = g.hud;
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Настройки', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Музыка ${(g.musicVol * 100).round()}%', style: const TextStyle(color: Colors.white70)),
              Slider(
                value: g.musicVol,
                onChanged: (v) => setState(() {
                  g.musicVol = v;
                  try {
                    FlameAudio.bgm.audioPlayer.setVolume(v);
                  } catch (_) {}
                }),
              ),
              Text('Звуки ${(g.sfxVol * 100).round()}%', style: const TextStyle(color: Colors.white70)),
              Slider(value: g.sfxVol, onChanged: (v) => setState(() => g.sfxVol = v)),
              const Divider(color: Colors.white24),
              Text('Размер джойстика ${h.joystickSize.round()}', style: const TextStyle(color: Colors.white70)),
              Slider(value: h.joystickSize, min: 60, max: 130, onChanged: (v) => setState(() => h.joystickSize = v)),
              Text('Размер кнопок ${h.buttonSize.round()}', style: const TextStyle(color: Colors.white70)),
              Slider(value: h.buttonSize, min: 32, max: 64, onChanged: (v) => setState(() => h.buttonSize = v)),
              const Text('Позиции (0..1)', style: TextStyle(color: Color(0xFFFFD700))),
              _posSlider('Move X', h.moveX, (v) => setState(() => h.moveX = v)),
              _posSlider('Move Y (снизу)', h.moveY, (v) => setState(() => h.moveY = v)),
              _posSlider('Attack X', h.atkX, (v) => setState(() => h.atkX = v)),
              _posSlider('Attack Y (снизу)', h.atkY, (v) => setState(() => h.atkY = v)),
              Row(
                children: [
                  Expanded(child: _goldBtn('Сброс HUD', () => setState(() => h.reset()), width: 140)),
                  Expanded(
                    child: _goldBtn('Применить', () {
                      if (g.isPlaying) g.rebuildHud();
                      g._saveMeta();
                      setState(() {});
                    }, width: 140),
                  ),
                ],
              ),
              if (g.isPlaying) ...[
                _goldBtn('Сохранить игру', () async {
                  await g.saveGame();
                }),
                _goldBtn('Выход из матча', () {
                  g.overlays.remove('settings');
                  g.backToMenu();
                }),
              ],
              _goldBtn('Закрыть', () {
                if (g.isPlaying) {
                  g.closeSettings();
                } else {
                  g.overlays.remove('settings');
                  g.overlays.add('mainMenu');
                  g._saveMeta();
                }
              }),
              const SizedBox(height: 12),
              const Text('1-5 left top 33s', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
              const Text('2-5 left top 33s', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _posSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Slider(value: value, min: 0.05, max: 0.95, onChanged: onChanged),
      ],
    );
  }
}

class RecordsMenu extends StatelessWidget {
  final InquisitorGame game;
  const RecordsMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final list = game.highScores;
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Рекорды', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Пусто', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return ListTile(
                          title: Text('${e.name} — ${e.score}', style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${e.progressStr} • ${e.timeStr} • ${e.playerClass}${e.keyRelics.isEmpty ? '' : ' • ${e.keyRelics.join(", ")}'}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        );
                      },
                    ),
            ),
            _goldBtn('Назад', () {
              game.overlays.remove('records');
              game.overlays.add('mainMenu');
            }),
          ],
        ),
      ),
    );
  }
}

class AchievementsMenu extends StatelessWidget {
  final InquisitorGame game;
  const AchievementsMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Достижения', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                children: AchievementId.values.map((id) {
                  final on = game.achievements.has(id);
                  return ListTile(
                    leading: Icon(on ? Icons.star : Icons.star_border, color: on ? const Color(0xFFFFD700) : Colors.white24),
                    title: Text(id.title, style: TextStyle(color: on ? Colors.white : Colors.white54)),
                    subtitle: Text(id.desc, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  );
                }).toList(),
              ),
            ),
            _goldBtn('Назад', () {
              game.overlays.remove('achievements');
              game.overlays.add('mainMenu');
            }),
          ],
        ),
      ),
    );
  }
}

class LoadSaveMenu extends StatelessWidget {
  final InquisitorGame game;
  const LoadSaveMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final list = game.saves;
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Сохранения', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Нет сохранений', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final s = list[i];
                        return ListTile(
                          title: Text('${s.name} — этаж ${s.floor}, ур.${s.level}', style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${s.dateStr} • ${s.difficulty} • ${s.playerClass}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              await game.deleteSave(i);
                              (context as Element).markNeedsBuild();
                            },
                          ),
                          onTap: () {
                            game.overlays.remove('loadSave');
                            game.loadSave(s);
                          },
                        );
                      },
                    ),
            ),
            if (list.isNotEmpty)
              _goldBtn('Удалить все', () async {
                await game.deleteAllSaves();
                (context as Element).markNeedsBuild();
              }),
            _goldBtn('Назад', () {
              game.overlays.remove('loadSave');
              game.overlays.add('mainMenu');
            }),
          ],
        ),
      ),
    );
  }
}
class RewardMenu extends StatelessWidget {
  final InquisitorGame game;
  const RewardMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final options = <Map<String, dynamic>>[
      {'id': 'skill', 'title': 'Очко навыка', 'desc': '+1 SP'},
      {'id': 'scraps', 'title': 'Обломки', 'desc': '+10 обломков'},
      {'id': 'heal', 'title': 'Аптечка', 'desc': '+3 HP'},
      {'id': 'relic', 'title': 'Реликвия', 'desc': 'Случайная пассивка'},
    ]..shuffle();
    final three = options.take(3).toList();

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Награда уровня', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...three.map((o) => _goldBtn('${o['title']}\n${o['desc']}', () {
                  switch (o['id']) {
                    case 'skill':
                      game.skillPoints++;
                      break;
                    case 'scraps':
                      game.scraps += 10;
                      break;
                    case 'heal':
                      game.player.heal(3);
                      break;
                    case 'relic':
                      game._grantRandomRelic();
                      break;
                  }
                  game.finishRewardThenShop();
                }, width: 300)),
          ],
        ),
      ),
    );
  }
}

class ShopMenu extends StatelessWidget {
  final InquisitorGame game;
  const ShopMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final g = game;
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Лавка • обломки: ${g.scraps}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _goldBtn('Хил +3 (8)', () => g.resolveMerchantBuy('heal')),
              _goldBtn('+1 SP (12)', () => g.resolveMerchantBuy('scraps_sp')),
              _goldBtn('Реликвия (20)', () => g.resolveMerchantBuy('relic')),
              if (g.playerClass == PlayerClass.xenos) ...[
                _goldBtn('Ствол: очередь (15)', () => g.resolveMerchantBuy('gun_rapid')),
                _goldBtn('Ствол: тяжёлый (15)', () => g.resolveMerchantBuy('gun_heavy')),
                _goldBtn('Прицел (12)', () => g.resolveMerchantBuy('gun_precision')),
                _goldBtn('Взрывной боезапас (18)', () => g.resolveMerchantBuy('gun_explosive')),
              ],
              if (g.playerClass == PlayerClass.malleus) ...[
                _goldBtn('Сфера (шире, −урон) (15)', () => g.resolveMerchantBuy('staff_wide')),
                _goldBtn('Фокус (15)', () => g.resolveMerchantBuy('staff_focus')),
                _goldBtn('Диссипатор Ψ (14)', () => g.resolveMerchantBuy('staff_dissipator')),
              ],
              if (g.playerClass == PlayerClass.hereticus) ...[
                _goldBtn('Зазубрины (bleed) (14)', () => g.resolveMerchantBuy('blade_serrated')),
                _goldBtn('Мономолекула (16)', () => g.resolveMerchantBuy('blade_mono')),
              ],
              const SizedBox(height: 8),
              _goldBtn('Далее → навыки', () => g.finishShopThenSkills()),
            ],
          ),
        ),
      ),
    );
  }
}

class SkillsMenu extends StatefulWidget {
  final InquisitorGame game;
  const SkillsMenu(this.game, {super.key});
  @override
  State<SkillsMenu> createState() => _SkillsMenuState();
}

class _SkillsMenuState extends State<SkillsMenu> {
  Widget _row(String name, int val, VoidCallback onAdd) {
    return ListTile(
      title: Text('$name: $val', style: const TextStyle(color: Colors.white)),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFFFFD700)),
        onPressed: widget.game.skillPoints > 0
            ? () {
                onAdd();
                setState(() {});
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final s = g.skills;
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Column(
          children: [
            Text('Навыки • SP: ${g.skillPoints}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
            _row('HP', s.hp, () => g.spendSkill('hp')),
            _row('Скорость', s.speed, () => g.spendSkill('speed')),
            _row('Скор. атаки', s.attackSpeed, () => g.spendSkill('attackSpeed')),
            _row('Защита', s.defense, () => g.spendSkill('defense')),
            _row('Урон', s.damage, () => g.spendSkill('damage')),
            _goldBtn('Продолжить', () => g.finishSkillsAndContinue()),
          ],
        ),
      ),
    );
  }
}

class BackpackMenu extends StatelessWidget {
  final InquisitorGame game;
  const BackpackMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final g = game;
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Рюкзак', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
              Text('${g.playerClass.title} • HP ${g.player.health.round()}/${g.maxHealth}', style: const TextStyle(color: Colors.white70)),
              Text('Урон R/M: ${g.rangedDamage}/${g.meleeDamage} • Скорость ${g.playerSpeed.round()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text('Обломки ${g.scraps} • SP ${g.skillPoints} • Очки ${g.score}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const Divider(color: Colors.white24),
              const Text('Оружие', style: TextStyle(color: Color(0xFFFFD700))),
              Text('Дальний: ${g.rangedWeapon.name} ${g.usingMelee ? '' : '◀'}', style: const TextStyle(color: Colors.white)),
              Text('Ближний: ${g.meleeWeapon.name} ${g.usingMelee ? '◀' : ''}', style: const TextStyle(color: Colors.white)),
              if (g.currentFloor >= 2)
                _goldBtn('Сменить тип (A)', () {
                  g.usingMelee = !g.usingMelee;
                }),
              const Divider(color: Colors.white24),
              const Text('Реликвии', style: TextStyle(color: Color(0xFFFFD700))),
              if (g.relics.isEmpty)
                const Text('—', style: TextStyle(color: Colors.white38))
              else
                ...g.relics.map((r) => Text('• ${r.title}', style: const TextStyle(color: Colors.white70))),
              const Divider(color: Colors.white24),
              const Text('Мастерство', style: TextStyle(color: Color(0xFFFFD700))),
              Text('bolter: ${g.mastery.getCount('bolter')} • staff: ${g.mastery.getCount('staff')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              _goldBtn('Закрыть', () => g.closeBackpack()),
            ],
          ),
        ),
      ),
    );
  }
}

class CodexMenu extends StatelessWidget {
  final InquisitorGame game;
  const CodexMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Column(
          children: [
            const Text('Кодекс Инквизиции', style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: CodexId.values.map((id) {
                  final open = game.codexUnlocked.contains(id);
                  final rank = game.loreRanks[id.name] ?? 0;
                  return ListTile(
                    title: Text(open ? id.title : '???', style: TextStyle(color: open ? Colors.white : Colors.white24)),
                    subtitle: open
                        ? Text('${id.knowledgeBonus} • знание $rank/2', style: const TextStyle(color: Colors.white54, fontSize: 12))
                        : null,
                  );
                }).toList(),
              ),
            ),
            _goldBtn('Назад', () => game.closeCodex()),
          ],
        ),
      ),
    );
  }
}

class LorePopupMenu extends StatelessWidget {
  final InquisitorGame game;
  const LorePopupMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final id = game.codexUnlocked.isEmpty ? CodexId.shooter : game.codexUnlocked.last;
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFFB8860B)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(id.title, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(id.lore, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(id.knowledgeBonus, style: const TextStyle(color: Color(0xFF69F0AE), fontSize: 12)),
              const SizedBox(height: 12),
              _goldBtn('Принять знание', () {
                final r = game.loreRanks[id.name] ?? 0;
                if (r < 2) {
                  final cost = r == 0 ? 0 : 1;
                  if (cost == 0 || game.skillPoints >= cost) {
                    if (cost > 0) game.skillPoints -= cost;
                    game.loreRanks[id.name] = r + 1;
                  }
                }
                if (game.codexUnlocked.length >= CodexId.values.length) {
                  game.unlockAchievement(AchievementId.fullCodex);
                }
                game.overlays.remove('lorePopup');
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class PathSelectMenu extends StatelessWidget {
  final InquisitorGame game;
  const PathSelectMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Этаж ${game.currentFloor} — путь', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(game.floorPath.length, (i) {
                final n = game.floorPath[i];
                final done = i < game.pathIndex;
                final cur = i == game.pathIndex;
                return Chip(
                  label: Text(n.label),
                  backgroundColor: cur
                      ? const Color(0xFFB71C1C)
                      : done
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF333333),
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }),
            ),
            const SizedBox(height: 16),
            _goldBtn('Вперёд', () {
              game.overlays.remove('pathSelect');
              game._startLevel();
            }),
          ],
        ),
      ),
    );
  }
}

class LevelCompleteMenu extends StatelessWidget {
  final InquisitorGame game;
  const LevelCompleteMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Уровень очищен', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            _goldBtn('Дальше', () => game.nextLevel()),
          ],
        ),
      ),
    );
  }
}

class VictoryMenu extends StatelessWidget {
  final InquisitorGame game;
  const VictoryMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Вы закончили прохождение\nиспытания ИНКВИЗИТОРА', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _goldBtn('Закончить', () => game.finishAfterVictory()),
            _goldBtn('Продолжить арену', () => game.startArena()),
          ],
        ),
      ),
    );
  }
}

class GameOverMenu extends StatelessWidget {
  final InquisitorGame game;
  const GameOverMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ГИБЕЛЬ', style: TextStyle(color: Color(0xFFB71C1C), fontSize: 28, fontWeight: FontWeight.w900)),
            Text('${game.playerName} • ${game.score} очков', style: const TextStyle(color: Colors.white70)),
            Text('Этаж ${game.currentFloor} • ${game.difficulty.labelRu}', style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            _goldBtn('Снова', () => game.openNameInput()),
            _goldBtn('Меню', () => game.backToMenu()),
          ],
        ),
      ),
    );
  }
}

class EventAltarMenu extends StatelessWidget {
  final InquisitorGame game;
  const EventAltarMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Алтарь', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('−2 HP → случайная реликвия', style: TextStyle(color: Colors.white70)),
            _goldBtn('Принести в жертву', () {
              game.player.takeDamage(2);
              game._grantRandomRelic();
              game.overlays.remove('eventAltar');
              game.isPaused = false;
              game.eventResolved = true;
              game._forceSpawnPortal();
            }),
            _goldBtn('Уйти', () {
              game.overlays.remove('eventAltar');
              game.isPaused = false;
              game.eventResolved = true;
              game._forceSpawnPortal();
            }),
          ],
        ),
      ),
    );
  }
}

class EventMerchantMenu extends StatelessWidget {
  final InquisitorGame game;
  const EventMerchantMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final g = game;
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Торговец • ${g.scraps} обломков', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
              _goldBtn('Хил (8)', () => g.resolveMerchantBuy('heal')),
              _goldBtn('SP (12)', () => g.resolveMerchantBuy('scraps_sp')),
              _goldBtn('Реликвия (20)', () => g.resolveMerchantBuy('relic')),
              if (g.playerClass == PlayerClass.xenos) ...[
                _goldBtn('Очередь (15)', () => g.resolveMerchantBuy('gun_rapid')),
                _goldBtn('Тяжёлый (15)', () => g.resolveMerchantBuy('gun_heavy')),
                _goldBtn('Прицел (12)', () => g.resolveMerchantBuy('gun_precision')),
                _goldBtn('Взрывной (18)', () => g.resolveMerchantBuy('gun_explosive')),
              ],
              if (g.playerClass == PlayerClass.malleus) ...[
                _goldBtn('Сфера (15)', () => g.resolveMerchantBuy('staff_wide')),
                _goldBtn('Фокус (15)', () => g.resolveMerchantBuy('staff_focus')),
                _goldBtn('Диссипатор (14)', () => g.resolveMerchantBuy('staff_dissipator')),
              ],
              if (g.playerClass == PlayerClass.hereticus) ...[
                _goldBtn('Зазубрины (14)', () => g.resolveMerchantBuy('blade_serrated')),
                _goldBtn('Мономолекула (16)', () => g.resolveMerchantBuy('blade_mono')),
              ],
              _goldBtn('Уйти', () {
                g.closeMerchant();
                g._forceSpawnPortal();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class RankPerkMenu extends StatelessWidget {
  final InquisitorGame game;
  const RankPerkMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Перк ранга', style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
            _goldBtn('+1 старт SP', () {
              game.rank.chosenPerk = RankPerk.startSp;
              game.overlays.remove('rankPerk');
              game._saveMeta();
            }),
            _goldBtn('+5% обломков', () {
              game.rank.chosenPerk = RankPerk.scrapBonus;
              game.overlays.remove('rankPerk');
              game._saveMeta();
            }),
          ],
        ),
      ),
    );
  }
}

// ─── ENTRY ────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SoulOfTheInquisitorApp());
}

class SoulOfTheInquisitorApp extends StatelessWidget {
  const SoulOfTheInquisitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soul of the Inquisitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFB71C1C),
        ),
      ),
      home: const GameHost(),
    );
  }
}

class GameHost extends StatefulWidget {
  const GameHost({super.key});
  @override
  State<GameHost> createState() => _GameHostState();
}

class _GameHostState extends State<GameHost> {
  late final InquisitorGame game;

  @override
  void initState() {
    super.initState();
    game = InquisitorGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          'mainMenu': (_, g) => MainMenu(g as InquisitorGame),
          'nameInput': (_, g) => NameInputMenu(g as InquisitorGame),
          'challengeSelect': (_, g) => ChallengeSelectMenu(g as InquisitorGame),
          'classSelect': (_, g) => ClassSelectMenu(g as InquisitorGame),
          'settings': (_, g) => SettingsMenu(g as InquisitorGame),
          'backpack': (_, g) => BackpackMenu(g as InquisitorGame),
          'loadSave': (_, g) => LoadSaveMenu(g as InquisitorGame),
          'records': (_, g) => RecordsMenu(g as InquisitorGame),
          'achievements': (_, g) => AchievementsMenu(g as InquisitorGame),
          'codex': (_, g) => CodexMenu(g as InquisitorGame),
          'reward': (_, g) => RewardMenu(g as InquisitorGame),
          'shop': (_, g) => ShopMenu(g as InquisitorGame),
          'skills': (_, g) => SkillsMenu(g as InquisitorGame),
          'levelComplete': (_, g) => LevelCompleteMenu(g as InquisitorGame),
          'victory': (_, g) => VictoryMenu(g as InquisitorGame),
          'gameOver': (_, g) => GameOverMenu(g as InquisitorGame),
          'pathSelect': (_, g) => PathSelectMenu(g as InquisitorGame),
          'lorePopup': (_, g) => LorePopupMenu(g as InquisitorGame),
          'eventAltar': (_, g) => EventAltarMenu(g as InquisitorGame),
          'eventMerchant': (_, g) => EventMerchantMenu(g as InquisitorGame),
          'rankPerk': (_, g) => RankPerkMenu(g as InquisitorGame),
        },
        initialActiveOverlays: const ['mainMenu'],
      ),
    );
  }
}
// ─── PLAYER ───────────────────────────────────────────────────

class Player extends PositionComponent
    with CollisionCallbacks, HasGameReference<InquisitorGame>, SmartMover {
  double health;
  final PlayerClass pClass;
  Vector2 velocity = Vector2.zero();
  Vector2 aimDir = Vector2(1, 0);
  bool facingRight = true;
  bool isDashing = false;
  double dashTimer = 0;
  double hurtFlash = 0;
  double animPhase = 0;
  final List<StatusEffect> statuses = [];

  Player({required Vector2 position, required this.pClass})
      : health = 6,
        super(position: position, size: Vector2(36, 48), anchor: Anchor.center, priority: 30);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: 14));
    health = game.maxHealth.toDouble();
  }

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void heal(double amount) {
    health = (health + amount).clamp(0, game.maxHealth.toDouble());
  }

  void takeDamage(double amount) {
    if (game.invulnTimer > 0 || game.shieldTimer > 0) return;
    var dmg = amount * (1 - game.skills.defense * 0.08);
    if (statuses.any((e) => e.type == StatusType.slow)) {
      // already slowed — no extra
    }
    health -= dmg;
    hurtFlash = 0.12;
    game.triggerShake(power: 5, time: 0.12);
    game.spawnDamageNumber(position, dmg.round(), color: Colors.redAccent);

    if (health <= 0) {
      if (game.hasIronWill && !game.ironWillUsedThisFloor) {
        game.ironWillUsedThisFloor = true;
        health = 1;
        game.invulnTimer = 1.2;
        game.unlockAchievement(AchievementId.ironWillProc);
        game.spawnDamageNumber(position, 0, color: const Color(0xFFFFD700), label: 'ВОЛЯ');
        return;
      }
      health = 0;
      game.showGameOver();
    }
  }

  void dash() {
    if (game.activeChallenge == RankChallenge.noDash) return;
    if (game.dashCooldown > 0 || isDashing) return;
    final cd = game.hasShadowStep ? 1.5 : 1.8;
    game.dashCooldown = cd;
    final dir = game.moveJoystick != null && game.moveJoystick!.delta.length2 > 0.01
        ? game.moveJoystick!.delta.normalized()
        : aimDir;
    isDashing = true;
    dashTimer = 0.22;
    velocity = dir * 520;
    game.invulnTimer = game.hasShadowStep ? 0.35 : 0.25;
    game.world.add(AfterImage(position: position.clone(), size: size.clone()));
  }

  void _tickStatuses(double dt) {
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage.toDouble());
      }
      if (e.remaining <= 0) statuses.remove(e);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    _tickStatuses(dt);

    // aim from attack stick, else move stick
    final atk = game.attackJoystick;
    final mov = game.moveJoystick;
    if (atk != null && atk.delta.length2 > 0.02) {
      aimDir = atk.delta.normalized();
      facingRight = aimDir.x >= 0;
    } else if (mov != null && mov.delta.length2 > 0.02) {
      aimDir = mov.delta.normalized();
      facingRight = aimDir.x >= 0;
    }

    final moveSpeed = game.playerSpeed * (game.hasteTimer > 0 ? 1.2 : 1.0) *
        (statuses.any((e) => e.type == StatusType.slow) ? 0.65 : 1.0);

    if (!isDashing) {
      if (mov != null && mov.delta.length2 > 0.01) {
        velocity = mov.delta.normalized() * moveSpeed;
      } else {
        velocity *= 0.78;
      }
    }

    smartMove(position + velocity * dt, moveSpeed, dt, radius: 14);
    // smartMove expects target; for player we apply velocity manually more carefully:
    final next = position + velocity * dt;
    next.x = next.x.clamp(30, game.mapWidth - 30);
    next.y = next.y.clamp(30, game.mapHeight - 30);
    // block walls
    var blocked = false;
    for (final o in game.world.children) {
      if (o is Wall || o is Obstacle) {
        if ((next - o.position).length < 28) {
          blocked = true;
          break;
        }
      }
    }
    if (!blocked) position.setFrom(next);
    pushOutOfWalls(14);

    if (dashTimer > 0) {
      dashTimer -= dt;
      if (dashTimer <= 0) isDashing = false;
    }

    animPhase += dt * (velocity.length > 40 ? 10 : 2);

    // attack while F stick held
    if (atk != null && atk.delta.length2 > 0.15) {
      _tryAttack();
    }
  }

  void _tryAttack() {
    if (game.usingMelee) {
      _melee();
    } else {
      _ranged();
    }
  }

  void _melee() {
    if (game.activeChallenge == RankChallenge.meleeBossOnly) {
      // always allowed for challenge
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - game.lastMeleeTime < game.meleeCooldownMs) return;
    game.lastMeleeTime = now;
    game.playSfx('melee.mp3');

    var reach = 52.0;
    var arc = 0.9;
    var dmg = game.scaleDamage(game.meleeDamage).toDouble();
    switch (game.meleeWeapon) {
      case MeleeWeapon.axe:
      case MeleeWeapon.forceSword:
        reach = 64;
        arc = 2.2;
        break;
      case MeleeWeapon.hammer:
      case MeleeWeapon.daemonHammer:
        reach = 72;
        dmg *= 1.35;
        break;
      case MeleeWeapon.katana:
      case MeleeWeapon.powerKatana:
        reach = 58;
        dmg *= 1.1;
        break;
      case MeleeWeapon.executioner:
        reach = 60;
        dmg *= 1.25;
        break;
      default:
        break;
    }
    dmg *= game.mastery.meleeMasteryMult(game.meleeWeapon.name);
    if (game.loadout.bladeEdge == BladeEdgeMod.weighted) dmg *= 1.15;
    if (game.loadout.bladeEdge == BladeEdgeMod.monomolecular) dmg *= 1.2;

    final hitPos = position + aimDir * (reach * 0.55);
    game.world.add(MeleeSlash(position: hitPos, dir: aimDir, radius: reach * 0.45)..priority = 28);

    void tryHit(PositionComponent other, void Function(int) apply) {
      final d = position.distanceTo(other.position);
      if (d > reach + 20) return;
      final to = (other.position - position).normalized();
      if (to.dot(aimDir) < cos(arc / 2) && d > 40) return;
      var finalDmg = dmg.round();
      if (game.hasExecutioner) {
        // low hp bonus handled inside enemy if possible — flat +20% here for bosses later
      }
      apply(finalDmg);
      if (game.loadout.bladeEdge == BladeEdgeMod.serrated && other is Enemy) {
        other.applyStatus(StatusType.bleed, 2.0, tickDamage: 1);
      }
      // jedi path: clear nearby bullets
      if (game.hasJediPath) {
        for (final b in game.world.children.whereType<EnemyBullet>().toList()) {
          if (b.position.distanceTo(position) < reach) b.removeFromParent();
        }
        for (final p in game.world.children.whereType<CorruptionPuddle>().toList()) {
          if (p.position.distanceTo(position) < reach) p.removeFromParent();
        }
      }
      for (final b in game.world.children.whereType<BreakableBarrel>()) {
        if (b.position.distanceTo(hitPos) < 40) b.hit();
      }
    }

    for (final e in game.world.children.whereType<Enemy>()) {
      tryHit(e, (d) => e.applyDamage(d));
    }
    for (final e in game.world.children.whereType<MiniBoss>()) {
      tryHit(e, (d) => e.takeDamage(d));
    }
    for (final e in game.world.children.whereType<Boss>()) {
      tryHit(e, (d) => e.takeDamage(d));
    }
    for (final e in game.world.children.whereType<KnightBoss>()) {
      tryHit(e, (d) => e.takeDamage(d));
    }
    for (final e in game.world.children.whereType<KingBoss>()) {
      tryHit(e, (d) => e.takeDamage(d));
    }
    for (final e in game.world.children.whereType<PlagueLordBoss>()) {
      tryHit(e, (d) => e.takeDamage(d));
    }
    for (final e in game.world.children.whereType<BloodChampionBoss>()) {
      tryHit(e, (d) => e.takeDamage(d));
    }
    for (final e in game.world.children.whereType<TentacleBoss>()) {
      tryHit(e, (d) => e.takeDamage(d));
    }
    for (final e in game.world.children.whereType<CyclopsBoss>()) {
      tryHit(e, (d) => e.takeDamage(d));
    }
  }

  void _ranged() {
    if (game.activeChallenge == RankChallenge.meleeBossOnly) {
      // still allow ranged on non-boss — challenge checked on boss HP elsewhere
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - game.lastShotTime < game.rangedCooldownMs) return;

    if (game.rangedWeapon == RangedWeapon.bolter ||
        game.rangedWeapon == RangedWeapon.rifle ||
        game.rangedWeapon == RangedWeapon.shotgun) {
      if (game.bolterHeat > 0.92) return;
      game.bolterHeat = (game.bolterHeat + (game.hasAmmoSavant ? 0.14 : 0.2)).clamp(0.0, 1.0);
    }
    if (game.rangedWeapon == RangedWeapon.staff ||
        game.rangedWeapon == RangedWeapon.stormStaff ||
        game.rangedWeapon == RangedWeapon.warpBeam) {
      if (game.staffWarpStress > 0.92) {
        takeDamage(1); // self-DoT on spam
        return;
      }
      game.staffWarpStress += game.hasWarpAnchor ? 0.12 : 0.18;
    }

    game.lastShotTime = now;
    game.playSfx('shoot.mp3');

    final dir = aimDir.length2 > 0.01 ? aimDir : Vector2(1, 0);
    final spawn = position + dir * 22;
    var shots = 1;
    var spread = 0.0;
    var speed = 480.0;
    var rad = 5.0;
    var dmg = game.scaleDamage(game.rangedDamage).toDouble();
    Color col = const Color(0xFFFF5722);

    switch (game.rangedWeapon) {
      case RangedWeapon.bolter:
        shots = game.mastery.bolterExtraShots(1, ammoSavant: game.hasAmmoSavant, xenosSynergy: game.playerClass == PlayerClass.xenos);
        col = const Color(0xFFFF5722);
        break;
      case RangedWeapon.rifle:
        dmg *= 1.45;
        speed = 560;
        game.lastShotTime = now + 80; // slower cadence already via cooldown
        col = const Color(0xFF00E5FF);
        break;
      case RangedWeapon.shotgun:
        shots = 3;
        spread = 0.28;
        speed = 420;
        dmg *= 0.7;
        col = const Color(0xFFFFAB40);
        break;
      case RangedWeapon.staff:
        col = const Color(0xFFB388FF);
        speed = 360;
        rad = 7;
        dmg *= 1.15 * game.mastery.staffRadiusMult();
        if (game.loadout.staffFocus == StaffFocusMod.wideSphere) {
          rad = 11;
          dmg *= 0.85;
        }
        if (game.loadout.staffFocus == StaffFocusMod.focusCore) {
          dmg *= 1.25;
          speed = 400;
        }
        break;
      case RangedWeapon.stormStaff:
        shots = 3;
        spread = 0.35;
        col = const Color(0xFF7C4DFF);
        break;
      case RangedWeapon.warpBeam:
        dmg *= 1.6;
        speed = 600;
        col = const Color(0xFFEA80FC);
        break;
      case RangedWeapon.daggers:
        shots = 2;
        spread = 0.15;
        col = const Color(0xFFE0E0E0);
        speed = 500;
        break;
      case RangedWeapon.needles:
        shots = 3;
        spread = 0.2;
        col = const Color(0xFFCE93D8);
        break;
      case RangedWeapon.sniperNeedle:
        dmg *= 1.7;
        speed = 620;
        col = const Color(0xFFE040FB);
        break;
    }

    if (game.loadout.gunAmmo == GunAmmoMod.explosive) dmg *= 1.1;

    for (int i = 0; i < shots; i++) {
      final ang = atan2(dir.y, dir.x) + (i - (shots - 1) / 2) * spread;
      final d = Vector2(cos(ang), sin(ang));
      game.world.add(Bullet(
        position: spawn.clone(),
        direction: d,
        damage: dmg,
        color: col,
        speed: speed,
        radius: rad,
        trail: true,
        fromPlayer: true,
      )..priority = 25);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is EnemyBullet || other is BossProjectile) {
      // damage handled in bullet
    }
    if (other is Portal) {
      game.nearPortal = true;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.inquisitor(
      canvas,
      cx: cx,
      cy: cy,
      s: 1.15,
      flash: hurtFlash / 0.12,
      custom: game.custom,
      cls: pClass,
    );
    // weapon oriented to aim
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(atan2(aimDir.y, aimDir.x));
    final accent = game.custom.weaponColor();
    if (game.usingMelee) {
      switch (game.meleeWeapon) {
        case MeleeWeapon.sword:
        case MeleeWeapon.forceBlade:
        case MeleeWeapon.forceSword:
          WHDraw.powerSword(canvas, 0, 0, 1.0, accent: accent);
          break;
        case MeleeWeapon.axe:
          WHDraw.chainAxe(canvas, 0, 0, 1.0, accent: accent);
          break;
        case MeleeWeapon.hammer:
        case MeleeWeapon.daemonHammer:
          WHDraw.thunderHammer(canvas, 0, 0, 1.0, accent: accent);
          break;
        case MeleeWeapon.katana:
        case MeleeWeapon.powerKatana:
          WHDraw.katana(canvas, 0, 0, 1.0, accent: accent);
          break;
        case MeleeWeapon.executioner:
          WHDraw.executioner(canvas, 0, 0, 1.0, accent: accent);
          break;
      }
    } else {
      switch (game.rangedWeapon) {
        case RangedWeapon.bolter:
          WHDraw.bolter(canvas, 0, 0, 1.0, accent: accent);
          break;
        case RangedWeapon.rifle:
          WHDraw.rifle(canvas, 0, 0, 1.0, accent: accent);
          break;
        case RangedWeapon.shotgun:
          WHDraw.shotgun(canvas, 0, 0, 1.0, accent: accent);
          break;
        case RangedWeapon.staff:
        case RangedWeapon.stormStaff:
          WHDraw.staff(canvas, 0, 0, 1.0, accent: accent);
          break;
        case RangedWeapon.warpBeam:
          WHDraw.warpBeamGun(canvas, 0, 0, 1.0, accent: accent);
          break;
        case RangedWeapon.daggers:
          WHDraw.daggers(canvas, 0, 0, 1.0, accent: accent);
          break;
        case RangedWeapon.needles:
          WHDraw.needles(canvas, 0, 0, 1.0, accent: accent);
          break;
        case RangedWeapon.sniperNeedle:
          WHDraw.sniperNeedle(canvas, 0, 0, 1.0, accent: accent);
          break;
      }
    }
    canvas.restore();

    // HP bar
    final ratio = (health / game.maxHealth).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 20, -28, 40, 5), Paint()..color = Colors.black54);
    canvas.drawRect(Rect.fromLTWH(cx - 20, -28, 40 * ratio, 5), Paint()..color = const Color(0xFF4CAF50));
    // heat
    if (game.bolterHeat > 0.05 && !game.usingMelee) {
      canvas.drawRect(Rect.fromLTWH(cx - 20, -22, 40 * game.bolterHeat, 3), Paint()..color = const Color(0xFFFF6D00));
    }
    if (game.staffWarpStress > 0.05 && !game.usingMelee) {
      canvas.drawRect(Rect.fromLTWH(cx - 20, -22, 40 * game.staffWarpStress, 3), Paint()..color = const Color(0xFFB388FF));
    }
    if (game.invulnTimer > 0) {
      canvas.drawCircle(Offset(cx, cy), 26, Paint()..color = const Color(0xFF81D4FA).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    WHDraw.statusIcons(canvas, cx, -36, statuses);
  }
}

class MeleeSlash extends PositionComponent {
  final Vector2 dir;
  final double radius;
  double life = 0.18;
  MeleeSlash({required Vector2 position, required this.dir, required this.radius})
      : super(position: position, size: Vector2.all(radius * 2), anchor: Anchor.center, priority: 28);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / 0.18).clamp(0.0, 1.0);
    final p = Paint()
      ..color = Color.fromRGBO(0, 229, 255, 0.55 * a)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(dir.x * radius, dir.y * radius), p);
  }
}

// ─── PROJECTILES ──────────────────────────────────────────────

class Bullet extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  final Vector2 direction;
  final double damage;
  final Color color;
  final double speed;
  final double radius;
  final bool trail;
  final bool fromPlayer;
  double life = 1.8;
  int ricochets = 0;

  Bullet({
    required Vector2 position,
    required this.direction,
    required this.damage,
    required this.color,
    required this.speed,
    required this.radius,
    this.trail = false,
    this.fromPlayer = false,
  }) : super(position: position, size: Vector2.all(radius * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    final prev = position.clone();
    position += direction.normalized() * speed * dt;
    if (trail) {
      game.world.add(BulletTrail(from: prev, to: position.clone(), color: color)..priority = 12);
    }
    life -= dt;
    if (life <= 0) removeFromParent();
    if (position.x < 0 || position.y < 0 || position.x > game.mapWidth || position.y > game.mapHeight) {
      removeFromParent();
    }
  }

  void _hitEnemy(void Function(int) apply, Vector2 at) {
    var dmg = damage.round();
    if (game.hasExecutioner) {
      // approximate
      dmg = (dmg * 1.0).round();
    }
    apply(dmg);
    if (game.loadout.gunAmmo == GunAmmoMod.explosive) {
      game.world.add(KillExplosion(position: at, radius: 45, damage: (damage * 0.4).round(), applyBurn: true));
    }
    if (game.loadout.gunAmmo != GunAmmoMod.pierce) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!fromPlayer) return;
    if (other is Enemy) {
      _hitEnemy((d) => other.applyDamage(d), other.position);
    } else if (other is MiniBoss) {
      _hitEnemy((d) => other.takeDamage(d), other.position);
    } else if (other is Boss) {
      _hitEnemy((d) => other.takeDamage(d), other.position);
    } else if (other is KnightBoss) {
      _hitEnemy((d) => other.takeDamage(d), other.position);
    } else if (other is KingBoss) {
      _hitEnemy((d) => other.takeDamage(d), other.position);
    } else if (other is PlagueLordBoss) {
      _hitEnemy((d) => other.takeDamage(d), other.position);
    } else if (other is BloodChampionBoss) {
      _hitEnemy((d) => other.takeDamage(d), other.position);
    } else if (other is TentacleBoss) {
      _hitEnemy((d) => other.takeDamage(d), other.position);
    } else if (other is CyclopsBoss) {
      _hitEnemy((d) => other.takeDamage(d), other.position);
    } else if (other is Wall || other is Obstacle) {
      if (game.loadout.gunAmmo == GunAmmoMod.ricochet && ricochets < 2) {
        ricochets++;
        // simple reflect
        direction.x *= -1;
      } else {
        removeFromParent();
      }
    } else if (other is BreakableBarrel) {
      other.hit();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(radius, radius), radius, Paint()..color = color);
  }
}

class EnemyBullet extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  Vector2 direction;
  final int damage;
  final double speed;
  final BulletMod mod;
  double life = 2.2;

  EnemyBullet({
    required Vector2 position,
    required this.direction,
    required this.damage,
    this.speed = 200,
    this.mod = BulletMod.normal,
  }) : super(position: position, size: Vector2(12, 12), anchor: Anchor.center);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  Color get _color {
    switch (mod) {
      case BulletMod.slow:
        return const Color(0xFF4FC3F7);
      case BulletMod.ricochet:
        return const Color(0xFFFFEB3B);
      case BulletMod.split:
        return const Color(0xFFE040FB);
      case BulletMod.normal:
        return const Color(0xFFFF8A65);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction.normalized() * speed * dt;
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.takeDamage(damage.toDouble());
      if (mod == BulletMod.slow) other.applyStatus(StatusType.slow, 1.5);
      removeFromParent();
    } else if (other is Wall || other is Obstacle) {
      if (mod == BulletMod.ricochet) {
        direction = Vector2(-direction.x, direction.y);
      } else {
        removeFromParent();
      }
    } else if (other is MeleeSlash && game.hasJediPath) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 5, Paint()..color = _color);
  }
}

class BossProjectile extends EnemyBullet {
  BossProjectile({
    required super.position,
    required super.direction,
    super.speed = 190,
    super.damage = 2,
  });
}

class CyclopsLaserBeam extends PositionComponent with HasGameReference<InquisitorGame> {
  final Vector2 direction;
  final int damage;
  double life = 0.35;

  CyclopsLaserBeam({required Vector2 position, required this.direction, required this.damage})
      : super(position: position, size: Vector2(320, 24), anchor: Anchor.centerLeft, priority: 22) {
    angle = atan2(direction.y, direction.x);
  }

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    // hit player if aligned
    final toP = game.player.position - position;
    final proj = toP.dot(direction.normalized());
    if (proj > 0 && proj < 300) {
      final lat = (toP - direction.normalized() * proj).length;
      if (lat < 22) {
        game.player.takeDamage(damage.toDouble());
      }
    }
    // damage enemies if from player laser
    for (final e in game.world.children.whereType<Enemy>()) {
      final to = e.position - position;
      final proj2 = to.dot(direction.normalized());
      if (proj2 > 0 && proj2 < 300 && (to - direction.normalized() * proj2).length < 24) {
        e.applyDamage(damage);
      }
    }
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / 0.35).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.25, size.x, size.y * 0.5),
      Paint()..color = Color.fromRGBO(255, 109, 0, 0.75 * a),
    );
  }
}

class FlamerCloud extends PositionComponent with HasGameReference<InquisitorGame> {
  double life = 1.4;
  double tick = 0;
  FlamerCloud({required Vector2 position})
      : super(position: position, size: Vector2(80, 80), anchor: Anchor.center, priority: 11);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    tick += dt;
    if (tick >= 0.4) {
      tick = 0;
      if (game.player.position.distanceTo(position) < 45) {
        game.player.takeDamage(1);
        game.player.applyStatus(StatusType.burn, 1.5, tickDamage: 1);
      }
    }
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / 1.4).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 36, Paint()..color = Color.fromRGBO(255, 109, 0, 0.35 * a));
  }
}
// ─── ENEMIES ──────────────────────────────────────────────────

class Enemy extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final EnemyType type;
  final bool isChampion;
  final EliteAffix affix;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  double hurtFlash = 0;
  double regenTimer = 0;
  bool summonerTriggered = false;
  final List<StatusEffect> statuses = [];

  Enemy({
    required this.floor,
    required this.type,
    this.isChampion = false,
    this.affix = EliteAffix.none,
  }) : super(size: Vector2(64, 72), anchor: Anchor.center, priority: 30);

  @override
  Future<void> onLoad() async {
    final base = switch (type) {
      EnemyType.shooter => 18.0,
      EnemyType.melee => 28.0,
      EnemyType.shielded => 40.0,
      EnemyType.dog => 16.0,
      EnemyType.shieldedShooter => 45.0,
      EnemyType.flamer => 24.0,
      EnemyType.sniper => 14.0,
      EnemyType.brute => 70.0,
      EnemyType.cultPsyker => 32.0,
      EnemyType.plagueBearer => 55.0,
      EnemyType.bloodletter => 36.0,
    };
    var hp = base * game.difficulty.hpMult * game.worldThreat * (1 + floor * 0.08);
    if (isChampion) hp *= 2.2;
    if (affix == EliteAffix.regenerating) hp *= 1.15;
    maxHp = hp.round().clamp(8, 9999);
    currentHp = maxHp;
    final r = type == EnemyType.brute || type == EnemyType.plagueBearer ? 28.0 : 22.0;
    add(CircleHitbox(radius: r));
  }

  double get moveSpeed {
    var s = switch (type) {
      EnemyType.dog => 195.0,
      EnemyType.melee => 125.0,
      EnemyType.bloodletter => 155.0,
      EnemyType.brute => 70.0,
      EnemyType.plagueBearer => 55.0,
      EnemyType.sniper => 90.0,
      EnemyType.cultPsyker => 85.0,
      EnemyType.flamer => 95.0,
      EnemyType.shielded || EnemyType.shieldedShooter => 80.0,
      EnemyType.shooter => 105.0,
    };
    if (isChampion) s *= 1.12;
    if (affix == EliteAffix.swift) s *= 1.35;
    if (statuses.any((e) => e.type == StatusType.slow || e.type == StatusType.plague)) s *= 0.6;
    return s;
  }

  bool get isShielded => type == EnemyType.shielded || type == EnemyType.shieldedShooter;

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void applyDamage(int amount, {bool fromStatus = false}) {
    var dmg = amount;
    if (isShielded && !fromStatus) {
      final pierce = game.hasShieldPierce || game.codexShieldBonus > 0;
      if (!pierce && !game.usingMelee) {
        dmg = max(1, (dmg * (0.25 + game.codexShieldBonus)).round());
      } else if (!game.usingMelee) {
        dmg = max(1, (dmg * (0.55 + game.codexShieldBonus)).round());
      }
    }
    if (game.hasExecutioner && currentHp / maxHp < 0.3) {
      dmg = (dmg * 1.2).round();
    }
    if (affix == EliteAffix.reflect && !fromStatus && Random().nextDouble() < 0.2) {
      game.player.takeDamage(1);
      game.spawnDamageNumber(position, 0, color: const Color(0xFFE040FB), label: 'F');
    }
    currentHp -= dmg;
    hurtFlash = 0.12;
    final fromDir = (position - game.player.position).normalized();
    game.spawnDamageNumber(position, dmg);
    if (currentHp <= 0) {
      _die(fromDir);
    } else if (affix == EliteAffix.summoner && !summonerTriggered && currentHp <= maxHp ~/ 2) {
      summonerTriggered = true;
      _summonAdds();
    }
  }

  void _summonAdds() {
    final points = game.getEnemySpawnPoints();
    for (int i = 0; i < 2; i++) {
      final pos = points.isNotEmpty
          ? points[Random().nextInt(points.length)].clone()
          : position + Vector2((Random().nextDouble() - 0.5) * 100, (Random().nextDouble() - 0.5) * 100);
      if (pos.distanceTo(game.player.position) < 80) continue;
      game.enemiesAlive++;
      game.enemiesToSpawn++;
      game.enemiesSpawned++;
      final add = Enemy(floor: floor, type: EnemyType.melee);
      add.position = pos;
      game.world.add(add);
      // weaker
      add.maxHp = max(6, (maxHp * 0.25).round());
      add.currentHp = add.maxHp;
    }
    game.spawnDamageNumber(position, 0, color: const Color(0xFFFFEB3B), label: 'ПРИЗЫВ');
  }

  void _die(Vector2 fromDir) {
    final pos = position.clone();
    if (affix == EliteAffix.explosive) {
      game.world.add(KillExplosion(position: pos, radius: 80, damage: 6 + floor * 2)..priority = 12);
      game.triggerShake(power: 6, time: 0.12);
    }
    removeFromParent();
    game.spawnBlood(pos, count: isChampion ? 22 : 12, fromDir: fromDir);
    game.onEnemyKilled(
      at: pos,
      isChampion: isChampion,
      type: type,
      meleeKill: game.usingMelee,
      affix: affix,
      fromDir: fromDir,
    );
  }

  void _tickStatuses(double dt) {
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) applyDamage(e.tickDamage, fromStatus: true);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    _tickStatuses(dt);

    if (affix == EliteAffix.regenerating) {
      regenTimer += dt;
      if (regenTimer >= 1.2 && currentHp < maxHp) {
        regenTimer = 0;
        currentHp = min(maxHp, currentHp + max(1, maxHp ~/ 25));
      }
    }

    final dist = position.distanceTo(game.player.position);
    final kite = type == EnemyType.shooter ||
        type == EnemyType.sniper ||
        type == EnemyType.shieldedShooter ||
        type == EnemyType.cultPsyker;
    final prefer = type == EnemyType.sniper
        ? 320.0
        : type == EnemyType.cultPsyker
            ? 260.0
            : 180.0;
    smartMove(game.player.position, moveSpeed, dt, radius: 22, kite: kite && dist < prefer + 40, preferDist: prefer);
    pushOutOfWalls(22);

    attackTimer += dt;
    final closeBonus = dist < 140 ? 0.65 : 1.0;
    final interval = switch (type) {
          EnemyType.dog => 0.55,
          EnemyType.melee => 0.7,
          EnemyType.bloodletter => 0.5,
          EnemyType.brute => 1.1,
          EnemyType.plagueBearer => 1.0,
          EnemyType.flamer => 1.3,
          EnemyType.sniper => 1.8,
          EnemyType.cultPsyker => 1.4,
          EnemyType.shieldedShooter => 1.0,
          EnemyType.shooter => 0.95,
          EnemyType.shielded => 0.85,
        } *
        closeBonus /
        (isChampion ? 1.15 : 1.0);

    if (attackTimer >= interval) {
      attackTimer = 0;
      _doAttack(dist);
    }
  }

  void _doAttack(double dist) {
    final toP = (game.player.position - position).normalized();
    final dmg = (1 * game.difficulty.dmgMult).ceil();
    switch (type) {
      case EnemyType.shooter:
      case EnemyType.shieldedShooter:
        if (dist < 420) {
          game.world.add(EnemyBullet(
            position: position.clone(),
            direction: toP,
            damage: dmg,
            mod: game.rollBulletMod(),
          )..priority = 16);
        }
        break;
      case EnemyType.sniper:
        if (dist < 520) {
          game.world.add(EnemyBullet(
            position: position.clone(),
            direction: toP,
            damage: dmg + 1,
            speed: 280,
            mod: BulletMod.slow,
          )..priority = 16);
        }
        break;
      case EnemyType.flamer:
        if (dist < 160) {
          game.world.add(FlamerCloud(position: position + toP * 40)..priority = 11);
          if (dist < 90) game.player.takeDamage(dmg.toDouble());
        }
        break;
      case EnemyType.cultPsyker:
        if (dist < 300) {
          for (final o in [-0.3, 0.0, 0.3]) {
            final a = atan2(toP.y, toP.x) + o;
            game.world.add(EnemyBullet(
              position: position.clone(),
              direction: Vector2(cos(a), sin(a)),
              damage: dmg,
              speed: 160,
              mod: BulletMod.slow,
            )..priority = 16);
          }
        }
        break;
      case EnemyType.plagueBearer:
        if (dist < 100) {
          game.player.takeDamage(dmg.toDouble());
          game.player.applyStatus(StatusType.plague, 2.5, tickDamage: 1);
        }
        break;
      case EnemyType.bloodletter:
      case EnemyType.melee:
      case EnemyType.dog:
      case EnemyType.brute:
      case EnemyType.shielded:
        if (dist < (type == EnemyType.brute ? 70 : 55)) {
          game.player.takeDamage((type == EnemyType.bloodletter || type == EnemyType.brute ? dmg + 1 : dmg).toDouble());
          if (type == EnemyType.bloodletter) {
            game.player.applyStatus(StatusType.bleed, 1.5, tickDamage: 1);
          }
        }
        break;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 12;
      stuckTimer = 0.6;
    }
    if (other is BreakableBarrel) {
      position += (position - other.position).normalized() * 10;
      stuckTimer = 0.4;
    }
    if (other is KillExplosion) {
      applyDamage(other.damage);
      if (other.applyBurn) applyStatus(StatusType.burn, 2.0, tickDamage: 1);
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final f = hurtFlash / 0.12;
    switch (type) {
      case EnemyType.shooter:
        WHDraw.cultistShooter(canvas, cx, cy, 1.0, flash: f);
        break;
      case EnemyType.melee:
        WHDraw.cultistMelee(canvas, cx, cy, 1.0, flash: f);
        break;
      case EnemyType.shielded:
        WHDraw.shieldedMarine(canvas, cx, cy, 1.0, flash: f);
        break;
      case EnemyType.shieldedShooter:
        WHDraw.shieldedMarine(canvas, cx, cy, 1.0, withGun: true, flash: f);
        break;
      case EnemyType.dog:
        WHDraw.chaosHound(canvas, cx, cy, flash: f);
        break;
      case EnemyType.flamer:
        WHDraw.flamerCultist(canvas, cx, cy, 1.0, flash: f);
        break;
      case EnemyType.sniper:
        WHDraw.sniperCultist(canvas, cx, cy, 1.0, flash: f);
        break;
      case EnemyType.brute:
        WHDraw.brute(canvas, cx, cy, 1.15, flash: f);
        break;
      case EnemyType.cultPsyker:
        WHDraw.cultPsyker(canvas, cx, cy, 1.05, flash: f);
        break;
      case EnemyType.plagueBearer:
        WHDraw.plagueBearer(canvas, cx, cy, 1.1, flash: f);
        break;
      case EnemyType.bloodletter:
        WHDraw.bloodletter(canvas, cx, cy, 1.05, flash: f);
        break;
    }
    if (isChampion) {
      WHDraw.championMark(canvas, cx, -10, affix: affix);
      final ratio = currentHp / maxHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - 22, -4, 44 * ratio, 5),
        Paint()..color = affix != EliteAffix.none ? affix.color : const Color(0xFFFFD700),
      );
    }
    WHDraw.statusIcons(canvas, cx, -18, statuses);
  }
}

class MiniBoss extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  MiniBoss({required this.floor, required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(100, 100), anchor: Anchor.center, priority: 24);

  @override
  Future<void> onLoad() async {
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((90 + floor * 25) * game.difficulty.bossHpMult * game.worldThreat * mult * 0.5).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 40));
    if (!isEcho) game.unlockCodex(CodexId.miniBoss);
  }

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (game.activeChallenge == RankChallenge.meleeBossOnly && !game.usingMelee) {
      game.spawnDamageNumber(position, 0, color: Colors.white54, label: 'ТОЛЬКО КЛИНОК');
      return;
    }
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF9800));
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 24, fromDir: (pos - game.player.position).normalized());
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.mini,
        fromDir: (pos - game.player.position).normalized(),
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.65;
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 200, angle: ang, life: 0.65)..priority = 6);
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    final base = atan2(toP.y, toP.x);
    for (final o in [-0.35, -0.15, 0.0, 0.15, 0.35]) {
      final a = base + o;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 220)..priority = 22);
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }

    final dist = position.distanceTo(game.player.position);
    var spd = 95.0 * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.4, dt, radius: 40, kite: true, preferDist: 200);
      pushOutOfWalls(40);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(game.player.position, spd, dt, radius: 40, kite: dist > 240, preferDist: 200);
    pushOutOfWalls(40);

    attackTimer += dt;
    final iv = (dist < 180 ? 1.1 : 1.6) * (isEcho ? 1.25 : 1.0);
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 14;
      stuckTimer = 0.7;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 40), width: 50, height: 12),
      Paint()..color = Colors.black.withOpacity(0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 8), width: 48, height: 52),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF4A1515),
    );
    canvas.drawCircle(Offset(cx, cy - 22), 16, Paint()..color = const Color(0xFF3E2723));
    WHDraw.shotgun(canvas, cx + 4, cy + 2, 1.1, accent: const Color(0xFF8D6E63));
    if (hurtFlash > 0) {
      canvas.drawCircle(Offset(cx, cy), 48, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * (hurtFlash / 0.12)));
    }
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        48,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(
      Rect.fromLTWH(cx - 40, -18, 80 * ratio, 8),
      Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF9800),
    );
    WHDraw.statusIcons(canvas, cx, -28, statuses);
  }
}
// ─── BOSSES ───────────────────────────────────────────────────

class Boss extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  String nextPattern = 'ring';
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  Boss({required this.floor, required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(120, 120), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((160 + floor * 45) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 48));
    if (!isEcho) game.unlockCodex(CodexId.boss);
  }

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (game.activeChallenge == RankChallenge.meleeBossOnly && !game.usingMelee) {
      game.spawnDamageNumber(position, 0, color: Colors.white54, label: 'ТОЛЬКО КЛИНОК');
      return;
    }
    final bonus = 1.0 + game.codexBossBonus;
    currentHp -= (amount * bonus).round();
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFE53935));
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 28, fromDir: (pos - game.player.position).normalized());
      game.spawnCorruptionZone(pos);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.ranged,
        fromDir: (pos - game.player.position).normalized(),
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7;
    final patterns = game.difficulty == Difficulty.hard
        ? ['ring', 'cone', 'cross', 'ring']
        : ['ring', 'cone', 'cross'];
    nextPattern = patterns[Random().nextInt(patterns.length)];
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (nextPattern) {
      case 'ring':
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 140, life: 0.7)..priority = 6);
        break;
      case 'cone':
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 240, angle: ang, life: 0.7)..priority = 6);
        break;
      case 'cross':
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 200, life: 0.7)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    switch (nextPattern) {
      case 'ring':
        for (int i = 0; i < 12; i++) {
          final a = i / 12 * pi * 2;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 190)..priority = 22);
        }
        break;
      case 'cone':
        final base = atan2(toP.y, toP.x);
        for (final o in [-0.4, -0.2, 0.0, 0.2, 0.4]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 230)..priority = 22);
        }
        break;
      case 'cross':
        for (final a in [0.0, pi / 2, pi, 3 * pi / 2]) {
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 210)..priority = 22);
        }
        break;
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }

    final dist = position.distanceTo(game.player.position);
    var spd = 85.0 * (isEcho ? 0.8 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;
    final kiteNow = game.bossRetreatTimer > 0 || telegraphing;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.35, dt, radius: 48, kite: true, preferDist: 220);
      pushOutOfWalls(48);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(game.player.position, spd, dt, radius: 48, kite: kiteNow || dist < 160, preferDist: 200);
    pushOutOfWalls(48);

    attackTimer += dt;
    final iv = (dist < 200 ? 1.4 : 2.0) * (isEcho ? 1.3 : 1.0) * (game.difficulty == Difficulty.hard ? 0.85 : 1.0);
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.8;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.hereticBoss(canvas, cx, cy, 1.35, flash: hurtFlash / 0.12);
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        55,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(
      Rect.fromLTWH(cx - 50, -24, 100 * ratio, 9),
      Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFE53935),
    );
    WHDraw.statusIcons(canvas, cx, -36, statuses);
  }
}

class KnightBoss extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  String nextPattern = 'dash';
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  KnightBoss({required this.floor, required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(110, 110), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((140 + floor * 40) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 44));
    if (!isEcho) game.unlockCodex(CodexId.knight);
  }

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (game.activeChallenge == RankChallenge.meleeBossOnly && !game.usingMelee) {
      game.spawnDamageNumber(position, 0, color: Colors.white54, label: 'ТОЛЬКО КЛИНОК');
      return;
    }
    final bonus = 1.0 + game.codexBossBonus;
    currentHp -= (amount * bonus).round();
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFF90CAF9));
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 26, fromDir: (pos - game.player.position).normalized());
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.knight,
        fromDir: (pos - game.player.position).normalized(),
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.6;
    nextPattern = Random().nextBool() ? 'dash' : 'slam';
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    if (nextPattern == 'dash') {
      game.world.add(TelegraphZone(position: position + toP * 80, shape: 'cone', radius: 160, angle: ang, life: 0.6)..priority = 6);
    } else {
      game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 110, life: 0.6)..priority = 6);
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    if (nextPattern == 'dash') {
      position += toP * 90;
      if (position.distanceTo(game.player.position) < 80) {
        game.player.takeDamage((2 * game.difficulty.dmgMult).ceil().toDouble());
      }
    } else {
      if (position.distanceTo(game.player.position) < 120) {
        game.player.takeDamage((3 * game.difficulty.dmgMult).ceil().toDouble());
        game.triggerShake(power: 8, time: 0.18);
      }
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }

    final dist = position.distanceTo(game.player.position);
    var spd = 120.0 * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.5, dt, radius: 44, kite: false, preferDist: 80);
      pushOutOfWalls(44);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(game.player.position, spd, dt, radius: 44, kite: game.bossRetreatTimer > 0, preferDist: 140);
    pushOutOfWalls(44);

    attackTimer += dt;
    final iv = (dist < 150 ? 1.0 : 1.5) * (isEcho ? 1.25 : 1.0);
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.8;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.knightBoss(canvas, cx, cy, 1.3, flash: hurtFlash / 0.12);
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        52,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(
      Rect.fromLTWH(cx - 48, -22, 96 * ratio, 9),
      Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFF90CAF9),
    );
    WHDraw.statusIcons(canvas, cx, -34, statuses);
  }
}

class KingBoss extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  late int phaseHp;
  int phase = 1;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  KingBoss({required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(140, 140), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    final mult = isEcho ? 0.55 : 1.0;
    maxHp = ((280 + game.currentFloor * 55) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    phaseHp = maxHp ~/ 2;
    add(CircleHitbox(radius: 55));
    if (!isEcho) game.unlockCodex(CodexId.king);
  }

  bool get invulnByRetinue => !isEcho && game.areOtherBossesAlive;

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    if (invulnByRetinue) return;
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (invulnByRetinue) {
      game.spawnDamageNumber(position, 0, color: const Color(0xFFFFD700), label: 'СВИТА');
      return;
    }
    if (game.activeChallenge == RankChallenge.meleeBossOnly && !game.usingMelee) {
      game.spawnDamageNumber(position, 0, color: Colors.white54, label: 'ТОЛЬКО КЛИНОК');
      return;
    }
    final bonus = 1.0 + game.codexBossBonus;
    currentHp -= (amount * bonus).round();
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFFD700));
    if (phase == 1 && currentHp <= phaseHp) {
      phase = 2;
      game.triggerCinemaZoom();
      game.triggerShake(power: 12, time: 0.35);
      game.spawnDamageNumber(position, 0, color: const Color(0xFFFFD700), label: 'ФАЗА 2');
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 36, fromDir: (pos - game.player.position).normalized());
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.king,
        fromDir: (pos - game.player.position).normalized(),
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.75;
    game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 160, life: 0.75)..priority = 6);
  }

  void _executeAttack() {
    if (phase == 1) {
      for (int i = 0; i < 10; i++) {
        final a = i / 10 * pi * 2;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 200)..priority = 22);
      }
      if (position.distanceTo(game.player.position) < 90) {
        game.player.takeDamage((3 * game.difficulty.dmgMult).ceil().toDouble());
      }
    } else {
      for (int salvo = 0; salvo < 3; salvo++) {
        Future.delayed(Duration(milliseconds: 180 * salvo), () {
          if (!isMounted) return;
          for (int i = 0; i < 14; i++) {
            final a = i / 14 * pi * 2 + salvo * 0.15;
            game.world.add(BossProjectile(
              position: position.clone(),
              direction: Vector2(cos(a), sin(a)),
              speed: 210 + salvo * 15,
            )..priority = 22);
          }
        });
      }
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }

    final dist = position.distanceTo(game.player.position);
    var spd = (phase == 1 ? 115.0 : 70.0) * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.4, dt, radius: 55, kite: phase == 2, preferDist: 180);
      pushOutOfWalls(55);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(
      game.player.position,
      spd,
      dt,
      radius: 55,
      kite: game.bossRetreatTimer > 0 || phase == 2,
      preferDist: phase == 1 ? 120 : 200,
    );
    pushOutOfWalls(55);

    attackTimer += dt;
    final iv = phase == 1 ? 1.6 : 3.0;
    if (attackTimer >= iv * (isEcho ? 1.2 : 1.0)) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 18;
      stuckTimer = 0.9;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.kingBossDraw(canvas, cx, cy, 1.55, flash: hurtFlash / 0.12);
    if (invulnByRetinue) {
      final pulse = 0.4 + 0.3 * sin(DateTime.now().millisecondsSinceEpoch / 200);
      canvas.drawCircle(
        Offset(cx, cy),
        62,
        Paint()
          ..color = Color.fromRGBO(255, 215, 0, pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      final tp = TextPainter(
        text: const TextSpan(
          text: 'СВИТА',
          style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, -48));
    }
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        60,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final ratio1 = (currentHp > phaseHp ? (currentHp - phaseHp) / (maxHp - phaseHp) : 0.0).clamp(0.0, 1.0);
    final ratio2 = (currentHp <= phaseHp ? currentHp / phaseHp : 1.0).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 55, -30, 110 * ratio1, 7), Paint()..color = const Color(0xFFFFD700));
    canvas.drawRect(Rect.fromLTWH(cx - 55, -20, 110 * ratio2, 7), Paint()..color = const Color(0xFFFF6D00));
    WHDraw.statusIcons(canvas, cx, -42, statuses);
  }
}
class PlagueLordBoss extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  double regenTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  PlagueLordBoss({required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(125, 125), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((200 + game.currentFloor * 40) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 50));
    if (!isEcho) game.unlockCodex(CodexId.plagueLord);
  }

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (game.activeChallenge == RankChallenge.meleeBossOnly && !game.usingMelee) {
      game.spawnDamageNumber(position, 0, color: Colors.white54, label: 'ТОЛЬКО КЛИНОК');
      return;
    }
    final bonus = 1.0 + game.codexBossBonus;
    currentHp -= (amount * bonus).round();
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFF8BC34A));
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 28, fromDir: (pos - game.player.position).normalized());
      game.spawnCorruptionZone(pos);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.plague,
        fromDir: (pos - game.player.position).normalized(),
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7;
    game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 130, life: 0.7)..priority = 6);
  }

  void _executeAttack() {
    for (int i = 0; i < 2; i++) {
      final a = Random().nextDouble() * pi * 2;
      final pos = position + Vector2(cos(a) * 90, sin(a) * 90);
      game.enemiesAlive++;
      game.enemiesToSpawn++;
      game.enemiesSpawned++;
      final e = Enemy(floor: game.currentFloor, type: EnemyType.plagueBearer);
      e.position = pos;
      game.world.add(e);
    }
    game.world.add(FlamerCloud(position: position.clone())..priority = 11);
    game.spawnCorruptionZone(position.clone());
    if (position.distanceTo(game.player.position) < 110) {
      game.player.takeDamage((2 * game.difficulty.dmgMult).ceil().toDouble());
      game.player.applyStatus(StatusType.plague, 2.5, tickDamage: 1);
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }

    regenTimer += dt;
    if (regenTimer >= 1.5 && currentHp < maxHp) {
      regenTimer = 0;
      currentHp = min(maxHp, currentHp + max(1, maxHp ~/ 40));
    }

    final dist = position.distanceTo(game.player.position);
    var spd = 65.0 * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.35, dt, radius: 50, kite: true, preferDist: 180);
      pushOutOfWalls(50);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(game.player.position, spd, dt, radius: 50, kite: dist < 140 || game.bossRetreatTimer > 0, preferDist: 160);
    pushOutOfWalls(50);

    attackTimer += dt;
    if (attackTimer >= 2.4 * (isEcho ? 1.2 : 1.0)) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.8;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.plagueLord(canvas, cx, cy, 1.4, flash: hurtFlash / 0.12);
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        55,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(
      Rect.fromLTWH(cx - 52, -26, 104 * ratio, 9),
      Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFF8BC34A),
    );
    WHDraw.statusIcons(canvas, cx, -38, statuses);
  }
}

class BloodChampionBoss extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  BloodChampionBoss({required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(118, 118), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((190 + game.currentFloor * 42) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 48));
    if (!isEcho) game.unlockCodex(CodexId.bloodChampion);
  }

  double get rage => (1 - currentHp / maxHp).clamp(0.0, 1.0);

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (game.activeChallenge == RankChallenge.meleeBossOnly && !game.usingMelee) {
      game.spawnDamageNumber(position, 0, color: Colors.white54, label: 'ТОЛЬКО КЛИНОК');
      return;
    }
    final bonus = 1.0 + game.codexBossBonus;
    currentHp -= (amount * bonus).round();
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF1744));
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 30, fromDir: (pos - game.player.position).normalized());
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.blood,
        fromDir: (pos - game.player.position).normalized(),
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.55;
    final toP = (game.player.position - position).normalized();
    game.world.add(TelegraphZone(
      position: position.clone(),
      shape: 'cone',
      radius: 150,
      angle: atan2(toP.y, toP.x),
      life: 0.55,
    )..priority = 6);
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    position += toP * (40 + rage * 40);
    final dmg = ((2 + rage * 2) * game.difficulty.dmgMult).ceil();
    if (position.distanceTo(game.player.position) < 85) {
      game.player.takeDamage(dmg.toDouble());
      game.player.applyStatus(StatusType.bleed, 2.0, tickDamage: 1);
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }

    final dist = position.distanceTo(game.player.position);
    var spd = (110 + rage * 50) * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.6, dt, radius: 48, kite: false, preferDist: 60);
      pushOutOfWalls(48);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(game.player.position, spd, dt, radius: 48, kite: game.bossRetreatTimer > 0, preferDist: 100);
    pushOutOfWalls(48);

    attackTimer += dt;
    final iv = (1.2 - rage * 0.4).clamp(0.6, 1.2) * (isEcho ? 1.2 : 1.0);
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.8;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.bloodChampion(canvas, cx, cy, 1.35, flash: hurtFlash / 0.12, rage: rage);
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        52,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(
      Rect.fromLTWH(cx - 50, -24, 100 * ratio, 9),
      Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF1744),
    );
    WHDraw.statusIcons(canvas, cx, -36, statuses);
  }
}

class TentacleBoss extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  late int maxHp;
  late int currentHp;
  late int phaseHp;
  int phase = 1;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  double hurtFlash = 0;
  double tentacleAnim = 0;
  final List<StatusEffect> statuses = [];

  TentacleBoss({required Vector2 position})
      : super(position: position, size: Vector2(150, 150), anchor: Anchor.center, priority: 28);

  @override
  Future<void> onLoad() async {
    maxHp = 6666;
    currentHp = maxHp;
    phaseHp = maxHp ~/ 2;
    add(CircleHitbox(radius: 58));
    game.unlockCodex(CodexId.tentacle);
  }

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFF9C27B0));
    if (phase == 1 && currentHp <= phaseHp) {
      phase = 2;
      game.triggerCinemaZoom();
      game.triggerShake(power: 14, time: 0.4);
      game.spawnDamageNumber(position, 0, color: const Color(0xFF9C27B0), label: 'ФАЗА 2');
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 40, fromDir: (pos - game.player.position).normalized());
      game.onSecretBossKilled(cyclops: false);
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7;
    if (phase == 1) {
      game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 150, life: 0.7)..priority = 6);
    } else {
      for (int i = 0; i < 6; i++) {
        final a = i / 6 * pi * 2 + tentacleAnim * 0.1;
        final p = position + Vector2(cos(a) * 100, sin(a) * 100);
        game.world.add(TelegraphZone(position: p, shape: 'circle', radius: 70, life: 0.7)..priority = 6);
      }
    }
  }

  void _executeAttack() {
    if (phase == 1) {
      for (int i = 0; i < 16; i++) {
        final a = i / 16 * pi * 2;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 170)..priority = 22);
      }
    } else {
      for (int i = 0; i < 6; i++) {
        final a = i / 6 * pi * 2 + tentacleAnim * 0.1;
        final p = position + Vector2(cos(a) * 100, sin(a) * 100);
        game.world.add(TentacleSlam(position: p)..priority = 14);
        if (p.distanceTo(game.player.position) < 90) {
          game.player.takeDamage((3 * game.difficulty.dmgMult).ceil().toDouble());
        }
      }
      game.triggerShake(power: 10, time: 0.25);
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    tentacleAnim += dt;
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }

    final dist = position.distanceTo(game.player.position);
    var spd = phase == 1 ? 80.0 : 55.0;
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.3, dt, radius: 58, kite: true, preferDist: 200);
      pushOutOfWalls(58);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(game.player.position, spd, dt, radius: 58, kite: game.bossRetreatTimer > 0 || dist < 130, preferDist: 180);
    pushOutOfWalls(58);

    attackTimer += dt;
    final iv = phase == 1 ? 2.0 : 1.5;
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 18;
      stuckTimer = 0.9;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 50), width: 70, height: 18),
      Paint()..color = Colors.black.withOpacity(0.25),
    );
    canvas.drawCircle(Offset(cx, cy), 42, Paint()..color = const Color(0xFF4A148C));
    canvas.drawCircle(Offset(cx, cy), 28, Paint()..color = const Color(0xFF7B1FA2));
    for (int i = 0; i < 8; i++) {
      final a = i / 8 * pi * 2 + tentacleAnim * (0.6 + i * 0.05);
      final len = 48 + 12 * sin(tentacleAnim * 2 + i);
      final x2 = cx + cos(a) * len;
      final y2 = cy + sin(a) * len;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(x2, y2),
        Paint()
          ..color = const Color(0xFF6A1B9A)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(Offset(x2, y2), 8, Paint()..color = const Color(0xFF9C27B0));
    }
    canvas.drawCircle(Offset(cx, cy - 6), 10, Paint()..color = const Color(0xFFE040FB));
    canvas.drawCircle(Offset(cx, cy - 6), 4, Paint()..color = Colors.white);
    if (hurtFlash > 0) {
      canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * (hurtFlash / 0.12)));
    }
    final ratio1 = (currentHp > phaseHp ? (currentHp - phaseHp) / (maxHp - phaseHp) : 0.0).clamp(0.0, 1.0);
    final ratio2 = (currentHp <= phaseHp ? currentHp / phaseHp : 1.0).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 55, -36, 110 * ratio1, 7), Paint()..color = const Color(0xFF9C27B0));
    canvas.drawRect(Rect.fromLTWH(cx - 55, -26, 110 * ratio2, 7), Paint()..color = const Color(0xFFE040FB));
    WHDraw.statusIcons(canvas, cx, -48, statuses);
  }
}

class TentacleSlam extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  double life = 0.35;
  TentacleSlam({required Vector2 position})
      : super(
          position: position,
          radius: 55,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF9C27B0).withOpacity(0.45),
          priority: 14,
        );

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    paint.color = Color.fromRGBO(156, 39, 176, (life / 0.35).clamp(0.0, 1.0) * 0.5);
    if (life <= 0) removeFromParent();
  }
}

class CyclopsBoss extends PositionComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  late int maxHp;
  late int currentHp;
  late int phaseHp;
  int phase = 1;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  double charge = 0;
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  CyclopsBoss({required Vector2 position})
      : super(position: position, size: Vector2(145, 145), anchor: Anchor.center, priority: 28);

  @override
  Future<void> onLoad() async {
    maxHp = 6666;
    currentHp = maxHp;
    phaseHp = maxHp ~/ 2;
    add(CircleHitbox(radius: 56));
    game.unlockCodex(CodexId.cyclops);
  }

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFFFF6D00));
    if (phase == 1 && currentHp <= phaseHp) {
      phase = 2;
      game.triggerCinemaZoom();
      game.triggerShake(power: 14, time: 0.4);
      game.spawnDamageNumber(position, 0, color: const Color(0xFFFF6D00), label: 'ФАЗА 2');
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 40, fromDir: (pos - game.player.position).normalized());
      game.onSecretBossKilled(cyclops: true);
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = phase == 1 ? 0.9 : 0.65;
    charge = 0;
    final toP = (game.player.position - position).normalized();
    if (phase == 1) {
      game.world.add(TelegraphZone(
        position: position.clone(),
        shape: 'cone',
        radius: 320,
        angle: atan2(toP.y, toP.x),
        life: telegraphTimer,
      )..priority = 6);
    } else {
      game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 140, life: telegraphTimer)..priority = 6);
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    if (phase == 1) {
      game.world.add(CyclopsLaserBeam(
        position: position.clone(),
        direction: toP,
        damage: (8 * game.difficulty.dmgMult).ceil(),
      )..priority = 14);
    } else {
      for (int i = 0; i < 12; i++) {
        final a = i / 12 * pi * 2;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 200)..priority = 22);
      }
      if (position.distanceTo(game.player.position) < 130) {
        game.player.takeDamage((4 * game.difficulty.dmgMult).ceil().toDouble());
      }
      game.triggerShake(power: 12, time: 0.3);
    }
    charge = 0;
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0) takeDamage(e.tickDamage);
      }
      if (e.remaining <= 0) statuses.remove(e);
    }

    final dist = position.distanceTo(game.player.position);
    var spd = phase == 1 ? 70.0 : 95.0;
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

    if (telegraphing) {
      charge = (1 - telegraphTimer / (phase == 1 ? 0.9 : 0.65)).clamp(0.0, 1.0);
      smartMove(game.player.position, spd * 0.25, dt, radius: 56, kite: phase == 1, preferDist: 220);
      pushOutOfWalls(56);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(
      game.player.position,
      spd,
      dt,
      radius: 56,
      kite: game.bossRetreatTimer > 0 || (phase == 1 && dist < 150),
      preferDist: 200,
    );
    pushOutOfWalls(56);

    attackTimer += dt;
    final iv = phase == 1 ? 2.5 : 1.7;
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 18;
      stuckTimer = 0.9;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.cyclops(canvas, cx, cy, 1.45, flash: hurtFlash / 0.12, charge: charge);
    final ratio1 = (currentHp > phaseHp ? (currentHp - phaseHp) / (maxHp - phaseHp) : 0.0).clamp(0.0, 1.0);
    final ratio2 = (currentHp <= phaseHp ? currentHp / phaseHp : 1.0).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 55, -36, 110 * ratio1, 7), Paint()..color = const Color(0xFFFF6D00));
    canvas.drawRect(Rect.fromLTWH(cx - 55, -26, 110 * ratio2, 7), Paint()..color = const Color(0xFFFFEA00));
    WHDraw.statusIcons(canvas, cx, -48, statuses);
  }
}
