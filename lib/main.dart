import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════

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
        return 1.0;
      case Difficulty.hard:
        return 1.45;
    }
  }

  double get dmgMult {
    switch (this) {
      case Difficulty.easy:
        return 0.8;
      case Difficulty.normal:
        return 1.0;
      case Difficulty.hard:
        return 1.35;
    }
  }

  double get bossHpMult {
    switch (this) {
      case Difficulty.easy:
        return 0.7;
      case Difficulty.normal:
        return 1.0;
      case Difficulty.hard:
        return 1.5;
    }
  }
}

enum PlayerClass { xenos, malleus, hereticus }

extension PlayerClassX on PlayerClass {
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
        return 'Болтер и стальной клинок';
      case PlayerClass.malleus:
        return 'Псайкер: посох и варп';
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

enum ActiveArtifact { none, fragGrenade, holyAura, servoTurret }

enum RelicId {
  critCharm,
  vampirism,
  shieldPierce,
  killExplosion,
  jediPath,
  ammoSavant,
  warpAnchor,
  shadowStep,
  ironWill,
  executionerMark,
  scavenger,
}

extension RelicX on RelicId {
  String get title {
    switch (this) {
      case RelicId.critCharm:
        return 'Талисман крита';
      case RelicId.vampirism:
        return 'Вампиризм';
      case RelicId.shieldPierce:
        return 'Пробитие щита';
      case RelicId.killExplosion:
        return 'Взрыв при убийстве';
      case RelicId.jediPath:
        return 'Путь Джедая';
      case RelicId.ammoSavant:
        return 'Мастер боезапаса';
      case RelicId.warpAnchor:
        return 'Якорь варпа';
      case RelicId.shadowStep:
        return 'Теневой шаг';
      case RelicId.ironWill:
        return 'Железная воля';
      case RelicId.executionerMark:
        return 'Метка палача';
      case RelicId.scavenger:
        return 'Падальщик';
    }
  }
}

enum CodexId {
  shooter,
  melee,
  shielded,
  dog,
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
  plagueLord,
  bloodChampion,
  tentacle,
  cyclops,
}

extension CodexX on CodexId {
  String get title {
    switch (this) {
      case CodexId.shooter:
        return 'Культист-стрелок';
      case CodexId.melee:
        return 'Культист ближнего боя';
      case CodexId.shielded:
        return 'Щитовик';
      case CodexId.dog:
        return 'Хаос-гончая';
      case CodexId.flamer:
        return 'Огнемётчик';
      case CodexId.sniper:
        return 'Снайпер культа';
      case CodexId.brute:
        return 'Громила';
      case CodexId.cultPsyker:
        return 'Псайкер культа';
      case CodexId.plagueBearer:
        return 'Носитель чумы';
      case CodexId.bloodletter:
        return 'Кровопускатель';
      case CodexId.miniBoss:
        return 'Мини-босс';
      case CodexId.boss:
        return 'Еретик-лорд';
      case CodexId.knight:
        return 'Рыцарь Хаоса';
      case CodexId.king:
        return 'Король боссов';
      case CodexId.plagueLord:
        return 'Повелитель чумы';
      case CodexId.bloodChampion:
        return 'Кровавый чемпион';
      case CodexId.tentacle:
        return 'Тентаклевый ужас';
      case CodexId.cyclops:
        return 'Циклоп';
    }
  }

  String get lore {
    switch (this) {
      case CodexId.shooter:
        return 'Пехота культа: медленные болты, держат дистанцию.';
      case CodexId.melee:
        return 'Фанатики с цепными клинками. Опасны вплотную.';
      case CodexId.shielded:
        return 'Болтер почти бесполезен — бей мечом.';
      case CodexId.dog:
        return 'Быстрые твари. Высокий урон, низкое HP.';
      case CodexId.flamer:
        return 'Облака огня. Не стой в лужах.';
      case CodexId.sniper:
        return 'Дальний выстрел с замедлением.';
      case CodexId.brute:
        return 'Толстая броня и тяжёлый удар.';
      case CodexId.cultPsyker:
        return 'Варп-залпы веером, замедление.';
      case CodexId.plagueBearer:
        return 'Чума: DoT при касании.';
      case CodexId.bloodletter:
        return 'Кровотечение при ударе.';
      case CodexId.miniBoss:
        return 'Дробовик-культист. Телеграф конусом.';
      case CodexId.boss:
        return 'Кольцо / конус / крест. Отступает после залпа.';
      case CodexId.knight:
        return 'Рывок и удар. Ближний фокус.';
      case CodexId.king:
        return 'Неуязвим, пока жива свита. Две фазы.';
      case CodexId.plagueLord:
        return 'Реген и призыв носителей чумы.';
      case CodexId.bloodChampion:
        return 'Ярость растёт с потерей HP.';
      case CodexId.tentacle:
        return 'Секрет 5 этажа. 6666 HP, кольцо и slam.';
      case CodexId.cyclops:
        return 'Секрет 10 этажа. Лазер из глаза.';
    }
  }

  String get knowledgeBonus {
    switch (this) {
      case CodexId.shooter:
      case CodexId.melee:
      case CodexId.dog:
        return '+1% урон по пехоте';
      case CodexId.shielded:
        return '+2% пробитие щита';
      case CodexId.flamer:
      case CodexId.sniper:
      case CodexId.brute:
        return '+1% урон';
      case CodexId.cultPsyker:
        return '+2% к варп-урону';
      case CodexId.plagueBearer:
        return '+5% сопротивление чуме';
      case CodexId.bloodletter:
        return '+5% сопротивление кровотечению';
      case CodexId.miniBoss:
      case CodexId.boss:
      case CodexId.knight:
        return '+2% урон боссам';
      case CodexId.king:
      case CodexId.plagueLord:
      case CodexId.bloodChampion:
        return '+3% урон боссам';
      case CodexId.tentacle:
      case CodexId.cyclops:
        return '+1% ко всему урону';
    }
  }
}

enum EliteAffix { none, swift, regenerating, explosive, reflect, summoner }

extension EliteAffixX on EliteAffix {
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
        return 'Σ';
    }
  }

  Color get color {
    switch (this) {
      case EliteAffix.none:
        return const Color(0xFFFFD700);
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
enum GunAmmoMod { none, explosive, ricochet, pierce }
enum StaffFocusMod { none, wideSphere, focused, dissipator }
enum BladeEdgeMod { none, serrated, mono, weighted }

enum RankPerk { none, startSp, scrapBonus }

enum RankChallenge { none, meleeOnlyBoss, noDash }

extension RankChallengeX on RankChallenge {
  String get title {
    switch (this) {
      case RankChallenge.none:
        return 'Без испытания';
      case RankChallenge.meleeOnlyBoss:
        return 'Только клинок';
      case RankChallenge.noDash:
        return 'Без рывка';
    }
  }

  String get desc {
    switch (this) {
      case RankChallenge.none:
        return 'Обычный забег';
      case RankChallenge.meleeOnlyBoss:
        return 'Босс этажа — только ближний бой';
      case RankChallenge.noDash:
        return 'Нельзя использовать рывок (U)';
    }
  }
}

enum RewardKind { skillPoint, scraps, heal, relic }

// ─── ACHIEVEMENTS (рынок: Soul Knight / Hades / Gungeon / VS) ───
enum AchievementId {
  firstBlood, // первое убийство
  noKills, // 5 мин на уровне без убийств + портал
  bossSlayer, // убить любого босса
  secretTentacle, // секрет 5
  secretCyclops, // секрет 10
  clearEasy, // пройти easy
  clearNormal,
  clearHard,
  arena50, // 50 убийств на арене
  arena100,
  combo15, // комбо x15
  fullCodex, // все записи кодекса
  allClasses, // сыграть всеми классами (хотя бы 1 забег каждый)
  ironWillProc, // сработала железная воля
  relicHunter, // 5 реликвий за один забег
  scrapHoarder, // 100 обломков за забег
  timedPortal, // воспользоваться порталом по таймеру 5 мин
  championHunter, // убить 10 чемпионов суммарно
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
        return '5 минут на уровне без убийств, уйдите порталом';
      case AchievementId.bossSlayer:
        return 'Победите любого босса этажа';
      case AchievementId.secretTentacle:
        return 'Убейте секретного босса (1–5, угол 33с)';
      case AchievementId.secretCyclops:
        return 'Убейте Циклопа (2–5, угол 33с)';
      case AchievementId.clearEasy:
        return 'Пройдите кампанию на Лёгком';
      case AchievementId.clearNormal:
        return 'Пройдите кампанию на Норме';
      case AchievementId.clearHard:
        return 'Пройдите кампанию на Харде';
      case AchievementId.arena50:
        return '50 убийств на арене за один заход';
      case AchievementId.arena100:
        return '100 убийств на арене за один заход';
      case AchievementId.combo15:
        return 'Достигните комбо x15';
      case AchievementId.fullCodex:
        return 'Откройте все записи кодекса';
      case AchievementId.allClasses:
        return 'Сыграйте за каждый ордо хотя бы раз';
      case AchievementId.ironWillProc:
        return 'Выживите благодаря Железной воле';
      case AchievementId.relicHunter:
        return 'Соберите 5 реликвий за один забег';
      case AchievementId.scrapHoarder:
        return 'Накопите 100 обломков за забег';
      case AchievementId.timedPortal:
        return 'Уйдите порталом, появившимся через 5 минут';
      case AchievementId.championHunter:
        return 'Убейте 10 элитных чемпионов (суммарно)';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// HUD LAYOUT — позиции и размеры (настройки + фикс в бою)
// ═══════════════════════════════════════════════════════════════

/// Нормализованные якоря 0..1 от краёв экрана (удобно под любой размер).
class HudLayout {
  double joystickSize;
  double buttonSize;

  // Move joystick: left-bottom
  double moveX; // от левого края
  double moveY; // от нижнего края

  // Attack joystick: right-bottom
  double atkX;
  double atkY;

  // Extra buttons (from right / from top or bottom)
  double settingsX, settingsY; // top-right area
  double backpackX, backpackY;
  double dashX, dashY; // near attack stick
  double laserX, laserY;
  double artifactX, artifactY;
  double warpX, warpY;
  double portalBtnX, portalBtnY;

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
}

// ═══════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════

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

class SkillTree {
  int hp = 0, speed = 0, attackSpeed = 0, defense = 0, damage = 0;
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
  Color armorColor([double s = 0.35]) => HSLColor.fromAHSL(1, armorHue.toDouble(), s, 0.35).toColor();
  Color capeColor([double s = 0.55]) => HSLColor.fromAHSL(1, capeHue.toDouble(), s, 0.4).toColor();
  Color weaponColor([double s = 0.5]) => HSLColor.fromAHSL(1, weaponHue.toDouble(), s, 0.55).toColor();
  Map<String, dynamic> toJson() => {'a': armorHue, 'c': capeHue, 'w': weaponHue};
  factory Customization.fromJson(Map<String, dynamic>? j) {
    if (j == null) return Customization();
    return Customization()
      ..armorHue = j['a'] as int? ?? 0
      ..capeHue = j['c'] as int? ?? 0
      ..weaponHue = j['w'] as int? ?? 200;
  }
}

class InquisitionRank {
  int wins;
  RankPerk chosenPerk;
  InquisitionRank({this.wins = 0, this.chosenPerk = RankPerk.none});
  int get rank => (wins ~/ 2).clamp(0, 20);
  double get critBonus => rank * 0.01;
  int get startScraps => rank * 3 + (chosenPerk == RankPerk.scrapBonus ? (rank * 0.05 * 20).round() : 0);
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
      chosenPerk: RankPerk.values.firstWhere((e) => e.name == j['perk'], orElse: () => RankPerk.none),
    );
  }
}

class WeaponMastery {
  final Map<String, int> kills = {};
  WeaponMastery(); // generative — обязателен при наличии factory

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
  StatusEffect(this.type, this.remaining, {this.tickEvery = 0.5, this.tickDamage = 1}) : tickAcc = 0;
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

  String get relicsStr => keyRelics.take(2).join(', ');

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
  final String payload; // full json blob for restore

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
        difficulty: j['diff'] as String? ?? 'normal',
        floor: j['floor'] as int? ?? 1,
        level: j['level'] as int? ?? 1,
        score: j['score'] as int? ?? 0,
        scraps: j['scraps'] as int? ?? 0,
        skillPoints: j['sp'] as int? ?? 0,
        skills: Map<String, dynamic>.from(j['skills'] as Map? ?? {}),
        mastery: Map<String, dynamic>.from(j['mastery'] as Map? ?? {}),
        relics: (j['relics'] as List?)?.map((e) => e.toString()).toList() ?? [],
        loadout: Map<String, dynamic>.from(j['loadout'] as Map? ?? {}),
        loreRanks: (j['lore'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
        codex: (j['codex'] as List?)?.map((e) => e.toString()).toList() ?? [],
        health: j['hp'] as int? ?? 6,
        ranged: j['rw'] as String? ?? 'bolter',
        melee: j['mw'] as String? ?? 'sword',
        usingMelee: j['um'] as bool? ?? false,
        payload: j['payload'] as String? ?? jsonEncode(j),
      );
}

// Meta progress for achievements (persisted)
class AchievementState {
  final Set<String> unlocked = {};
  final Set<String> classesPlayed = {};
  int championsKilledTotal = 0;

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

  bool has(AchievementId id) => unlocked.contains(id.name);
}
// ═══════════════════════════════════════════════════════════════
// VISUAL FX COMPONENTS
// ═══════════════════════════════════════════════════════════════

class DamageNumber extends PositionComponent {
  final int amount;
  final Color color;
  final String? label;
  double life = 0.85;
  DamageNumber({required Vector2 position, required this.amount, this.color = const Color(0xFFFFEB3B), this.label})
      : super(position: position.clone(), priority: 100);

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
      canvas.drawCircle(Offset(d.pos.x, d.pos.y), d.r, Paint()..color = Color.fromRGBO(180, 0, 0, a));
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
  KillExplosion({required Vector2 position, this.radius = 60, this.damage = 4, this.applyBurn = false})
      : super(position: position.clone(), size: Vector2.all(radius * 2), anchor: Anchor.center, priority: 12);

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
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), radius * (1.2 - a * 0.3), Paint()..color = Color.fromRGBO(255, 109, 0, 0.45 * a));
  }
}

class ComboBanner extends PositionComponent {
  final int combo;
  double life = 1.2;
  ComboBanner({required Vector2 position, required this.combo}) : super(position: position.clone(), priority: 110);

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
  AfterImage({required Vector2 position, required Vector2 size, this.tint = const Color(0xFF81D4FA)})
      : super(position: position.clone(), size: size.clone(), anchor: Anchor.center, priority: 18);

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
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: size.x * 0.7, height: size.y * 0.8), const Radius.circular(8)),
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
        super(position: position.clone(), size: Vector2.all(radius * 2), anchor: Anchor.center, priority: 6);

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

class CorruptionZone extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  double life = 8.0;
  bool purified = false;
  CorruptionZone({required Vector2 position})
      : super(position: position.clone(), size: Vector2(90, 90), anchor: Anchor.center, priority: 5);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  void purify() {
    purified = true;
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (purified) return;
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.applyStatus(StatusType.corruption, 1.2, tickDamage: 1);
    }
  }

  @override
  void render(Canvas canvas) {
    final a = (life / 8).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 40, Paint()..color = Color.fromRGBO(120, 0, 180, 0.3 * a));
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

// ═══════════════════════════════════════════════════════════════
// WHDraw — procedural Warhammer silhouettes (code only)
// ═══════════════════════════════════════════════════════════════

class WHDraw {
  static void _shadow(Canvas c, double cx, double cy, double w, double h) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + h * 0.55), width: w, height: h * 0.18), Paint()..color = Colors.black.withOpacity(0.25));
  }

  static void _flash(Canvas c, double cx, double cy, double r, double flash) {
    if (flash > 0) {
      c.drawCircle(Offset(cx, cy), r, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
    }
  }

  static void inquisitor(Canvas canvas, {required double cx, required double cy, double s = 1.2, double flash = 0, Customization? custom, PlayerClass cls = PlayerClass.xenos}) {
    final armor = custom?.armorColor(0.4) ?? const Color(0xFF2A2A2A);
    final cape = custom?.capeColor(0.55) ?? const Color(0xFFB71C1C);
    final accent = switch (cls) {
      PlayerClass.xenos => const Color(0xFFB71C1C),
      PlayerClass.malleus => const Color(0xFF5C6BC0),
      PlayerClass.hereticus => const Color(0xFF8E24AA),
    };
    _shadow(canvas, cx, cy, 50 * s, 70 * s);
    // cape
    final capePath = Path()
      ..moveTo(cx - 18 * s, cy - 8 * s)
      ..quadraticBezierTo(cx - 28 * s, cy + 20 * s, cx - 16 * s, cy + 38 * s)
      ..lineTo(cx + 16 * s, cy + 38 * s)
      ..quadraticBezierTo(cx + 28 * s, cy + 20 * s, cx + 18 * s, cy - 8 * s)
      ..close();
    canvas.drawPath(capePath, Paint()..color = cape);
    // legs
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 8 * s, cy + 28 * s), width: 12 * s, height: 22 * s), Radius.circular(3 * s)), Paint()..color = armor);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 8 * s, cy + 28 * s), width: 12 * s, height: 22 * s), Radius.circular(3 * s)), Paint()..color = armor);
    // torso
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 34 * s, height: 36 * s), Radius.circular(5 * s)), Paint()..color = armor);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 2 * s), width: 28 * s, height: 6 * s), Paint()..color = accent);
    // pauldrons
    canvas.drawCircle(Offset(cx - 18 * s, cy - 4 * s), 9 * s, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(Offset(cx + 18 * s, cy - 4 * s), 9 * s, Paint()..color = const Color(0xFF1A1A1A));
    // head / helmet
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 22 * s), width: 22 * s, height: 24 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 22 * s), width: 14 * s, height: 5 * s), Paint()..color = accent);
    // purity seals
    canvas.drawLine(Offset(cx + 10 * s, cy + 10 * s), Offset(cx + 14 * s, cy + 22 * s), Paint()..color = const Color(0xFFFFF8E1)..strokeWidth = 2);
    _flash(canvas, cx, cy, 40 * s, flash);
  }

  static void bolter(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFF6D00)}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 4 * s, 28 * s, 8 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF37474F));
    c.drawRect(Rect.fromLTWH(cx + 28 * s, cy - 2 * s, 10 * s, 4 * s), Paint()..color = accent);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy + 4 * s, 10 * s, 12 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF263238));
    c.drawCircle(Offset(cx + 12 * s, cy - 6 * s), 3 * s, Paint()..color = accent);
  }

  static void rifle(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF00E5FF)}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, cy - 3 * s, 36 * s, 6 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF455A64));
    c.drawRect(Rect.fromLTWH(cx + 34 * s, cy - 2 * s, 8 * s, 3 * s), Paint()..color = accent);
    c.drawRect(Rect.fromLTWH(cx + 16 * s, cy - 8 * s, 6 * s, 5 * s), Paint()..color = const Color(0xFF78909C));
  }

  static void shotgun(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFFAB40)}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 5 * s, 24 * s, 10 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF5D4037));
    c.drawRect(Rect.fromLTWH(cx + 24 * s, cy - 3 * s, 8 * s, 6 * s), Paint()..color = accent);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy + 5 * s, 8 * s, 10 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF3E2723));
  }

  static void staff(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFB388FF)}) {
    c.drawLine(Offset(cx + 6 * s, cy + 20 * s), Offset(cx + 10 * s, cy - 22 * s), Paint()..color = const Color(0xFF5D4E37)..strokeWidth = 4 * s);
    c.drawCircle(Offset(cx + 10 * s, cy - 26 * s), 8 * s, Paint()..color = accent.withOpacity(0.85));
    c.drawCircle(Offset(cx + 10 * s, cy - 26 * s), 4 * s, Paint()..color = Colors.white.withOpacity(0.7));
  }

  static void stormStaff(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF7C4DFF)}) {
    staff(c, cx, cy, s, accent: accent);
    for (int i = 0; i < 3; i++) {
      final a = i * 2.1;
      c.drawLine(Offset(cx + 10 * s + cos(a) * 10 * s, cy - 26 * s + sin(a) * 10 * s), Offset(cx + 10 * s + cos(a) * 16 * s, cy - 26 * s + sin(a) * 16 * s),
          Paint()..color = accent..strokeWidth = 1.5);
    }
  }

  static void warpBeamGun(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFEA80FC)}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 6 * s, 26 * s, 12 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF4A148C));
    c.drawCircle(Offset(cx + 30 * s, cy), 6 * s, Paint()..color = accent);
  }

  static void daggers(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE0E0E0)}) {
    c.drawLine(Offset(cx + 8 * s, cy + 8 * s), Offset(cx + 22 * s, cy - 12 * s), Paint()..color = accent..strokeWidth = 3 * s);
    c.drawLine(Offset(cx + 4 * s, cy + 10 * s), Offset(cx + 16 * s, cy - 8 * s), Paint()..color = const Color(0xFFBDBDBD)..strokeWidth = 2.5 * s);
  }

  static void needles(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFCE93D8)}) {
    for (int i = 0; i < 3; i++) {
      c.drawLine(Offset(cx + 6 * s, cy - 4 * s + i * 4 * s), Offset(cx + 26 * s, cy - 10 * s + i * 4 * s), Paint()..color = accent..strokeWidth = 1.5 * s);
    }
  }

  static void sniperNeedle(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE040FB)}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, cy - 2 * s, 34 * s, 4 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF6A1B9A));
    c.drawRect(Rect.fromLTWH(cx + 14 * s, cy - 8 * s, 5 * s, 5 * s), Paint()..color = accent);
  }

  static void powerSword(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF00BCD4)}) {
    c.drawLine(Offset(cx + 6 * s, cy + 12 * s), Offset(cx + 28 * s, cy - 18 * s), Paint()..color = accent..strokeWidth = 4 * s);
    c.drawLine(Offset(cx + 6 * s, cy + 12 * s), Offset(cx + 28 * s, cy - 18 * s), Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.5 * s);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 8 * s, cy + 10 * s), width: 10 * s, height: 4 * s), Paint()..color = const Color(0xFF37474F));
  }

  static void chainAxe(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFF6D00)}) {
    c.drawLine(Offset(cx + 6 * s, cy + 10 * s), Offset(cx + 18 * s, cy - 6 * s), Paint()..color = const Color(0xFF5D4037)..strokeWidth = 4 * s);
    c.drawOval(Rect.fromCenter(center: Offset(cx + 24 * s, cy - 12 * s), width: 18 * s, height: 14 * s), Paint()..color = accent);
    c.drawOval(Rect.fromCenter(center: Offset(cx + 24 * s, cy - 12 * s), width: 10 * s, height: 8 * s), Paint()..color = const Color(0xFF212121));
  }

  static void thunderHammer(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFFD700)}) {
    c.drawLine(Offset(cx + 6 * s, cy + 14 * s), Offset(cx + 16 * s, cy - 8 * s), Paint()..color = const Color(0xFF455A64)..strokeWidth = 5 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 20 * s, cy - 14 * s), width: 20 * s, height: 14 * s), Radius.circular(2 * s)), Paint()..color = accent);
  }

  static void forceBlade(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF7C4DFF)}) {
    powerSword(c, cx, cy, s * 1.1, accent: accent);
  }

  static void forceSword(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFB388FF)}) {
    powerSword(c, cx, cy, s * 1.15, accent: accent);
    c.drawCircle(Offset(cx + 18 * s, cy - 4 * s), 4 * s, Paint()..color = accent.withOpacity(0.5));
  }

  static void daemonHammer(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE040FB)}) {
    thunderHammer(c, cx, cy, s * 1.05, accent: accent);
  }

  static void katana(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE0E0E0)}) {
    c.drawLine(Offset(cx + 4 * s, cy + 14 * s), Offset(cx + 32 * s, cy - 16 * s), Paint()..color = accent..strokeWidth = 2.5 * s);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 6 * s, cy + 12 * s), width: 8 * s, height: 3 * s), Paint()..color = const Color(0xFF6A1B9A));
  }

  static void powerKatana(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFE040FB)}) {
    katana(c, cx, cy, s, accent: accent);
    c.drawLine(Offset(cx + 6 * s, cy + 12 * s), Offset(cx + 30 * s, cy - 14 * s), Paint()..color = accent.withOpacity(0.4)..strokeWidth = 5 * s);
  }

  static void executioner(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFFFF1744)}) {
    c.drawLine(Offset(cx + 6 * s, cy + 12 * s), Offset(cx + 26 * s, cy - 14 * s), Paint()..color = accent..strokeWidth = 5 * s);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 28 * s, cy - 16 * s), width: 8 * s, height: 12 * s), Paint()..color = const Color(0xFF212121));
  }

  static void cultistShooter(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 40 * s, 55 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 26 * s, height: 30 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF1B5E20));
    c.drawCircle(Offset(cx, cy - 16 * s), 11 * s, Paint()..color = const Color(0xFF2E7D32));
    bolter(c, cx, cy, s * 0.85, accent: const Color(0xFF76FF03));
    _flash(c, cx, cy, 30 * s, flash);
  }

  static void cultistMelee(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 40 * s, 55 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 28 * s, height: 32 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFFF9A825));
    c.drawCircle(Offset(cx, cy - 16 * s), 11 * s, Paint()..color = const Color(0xFFF57F17));
    powerSword(c, cx, cy, s * 0.9, accent: const Color(0xFFFFF176));
    _flash(c, cx, cy, 30 * s, flash);
  }

  static void shieldedMarine(Canvas c, double cx, double cy, double s, {bool withGun = false, double flash = 0}) {
    _shadow(c, cx, cy, 48 * s, 60 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 32 * s, height: 36 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF1565C0));
    c.drawCircle(Offset(cx, cy - 18 * s), 12 * s, Paint()..color = const Color(0xFF0D47A1));
    // shield
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 16 * s, cy + 4 * s), width: 14 * s, height: 28 * s), Radius.circular(3 * s)),
        Paint()..color = const Color(0xFF90CAF9).withOpacity(0.85));
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
    c.drawLine(Offset(cx - 18, cy + 8), Offset(cx - 14, cy + 18), Paint()..color = const Color(0xFF3E2723)..strokeWidth = 3);
    c.drawLine(Offset(cx + 6, cy + 10), Offset(cx + 10, cy + 18), Paint()..color = const Color(0xFF3E2723)..strokeWidth = 3);
    _flash(c, cx, cy, 28, flash);
  }

  static void flamerCultist(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    cultistShooter(c, cx, cy, s, flash: flash);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy - 2 * s, 18 * s, 10 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFFFF6D00));
  }

  static void sniperCultist(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    cultistShooter(c, cx, cy, s, flash: flash);
    rifle(c, cx, cy, s * 0.9, accent: const Color(0xFF4FC3F7));
  }

  static void brute(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 60 * s, 70 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 44 * s, height: 48 * s), Radius.circular(6 * s)), Paint()..color = const Color(0xFF5D4037));
    c.drawCircle(Offset(cx, cy - 22 * s), 16 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx - 5 * s, cy - 24 * s), 3 * s, Paint()..color = const Color(0xFFFF1744));
    c.drawCircle(Offset(cx + 5 * s, cy - 24 * s), 3 * s, Paint()..color = const Color(0xFFFF1744));
    _flash(c, cx, cy, 40 * s, flash);
  }

  static void cultPsyker(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 42 * s, 58 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 28 * s, height: 34 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF6A1B9A));
    c.drawCircle(Offset(cx, cy - 18 * s), 12 * s, Paint()..color = const Color(0xFF4A148C));
    c.drawCircle(Offset(cx, cy - 28 * s), 7 * s, Paint()..color = const Color(0xFFEA80FC).withOpacity(0.8));
    _flash(c, cx, cy, 32 * s, flash);
  }

  static void plagueBearer(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 48 * s, 60 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 36 * s, height: 40 * s), Radius.circular(8 * s)), Paint()..color = const Color(0xFF558B2F));
    c.drawCircle(Offset(cx, cy - 20 * s), 14 * s, Paint()..color = const Color(0xFF33691E));
    c.drawCircle(Offset(cx - 4 * s, cy - 18 * s), 3 * s, Paint()..color = const Color(0xFFCCFF90));
    c.drawCircle(Offset(cx + 6 * s, cy - 22 * s), 2.5 * s, Paint()..color = const Color(0xFFCCFF90));
    _flash(c, cx, cy, 34 * s, flash);
  }

  static void bloodletter(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 44 * s, 58 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 30 * s, height: 36 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFFB71C1C));
    c.drawCircle(Offset(cx, cy - 18 * s), 12 * s, Paint()..color = const Color(0xFF7F0000));
    // horns
    c.drawLine(Offset(cx - 8 * s, cy - 24 * s), Offset(cx - 14 * s, cy - 36 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 3 * s);
    c.drawLine(Offset(cx + 8 * s, cy - 24 * s), Offset(cx + 14 * s, cy - 36 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 3 * s);
    powerSword(c, cx, cy, s, accent: const Color(0xFFFF1744));
    _flash(c, cx, cy, 32 * s, flash);
  }

  static void hereticBoss(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 70 * s, 80 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 50 * s, height: 56 * s), Radius.circular(6 * s)), Paint()..color = const Color(0xFF4A0000));
    c.drawCircle(Offset(cx, cy - 28 * s), 18 * s, Paint()..color = const Color(0xFF1A0000));
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 28 * s), width: 12 * s, height: 5 * s), Paint()..color = const Color(0xFFFF1744));
    bolter(c, cx + 6 * s, cy, s * 1.1, accent: const Color(0xFFFF5252));
    _flash(c, cx, cy, 48 * s, flash);
  }

  static void knightBoss(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 68 * s, 80 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 48 * s, height: 54 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF263238));
    c.drawCircle(Offset(cx, cy - 26 * s), 16 * s, Paint()..color = const Color(0xFF102027));
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 26 * s), width: 14 * s, height: 4 * s), Paint()..color = const Color(0xFF90CAF9));
    powerSword(c, cx, cy, s * 1.2, accent: const Color(0xFF90CAF9));
    _flash(c, cx, cy, 46 * s, flash);
  }

  static void kingBossDraw(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 80 * s, 90 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 58 * s, height: 64 * s), Radius.circular(7 * s)), Paint()..color = const Color(0xFF3E2723));
    // crown
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
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 28 * s), width: 12 * s, height: 5 * s), Paint()..color = const Color(0xFFFFD700));
    _flash(c, cx, cy, 55 * s, flash);
  }

  static void plagueLord(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    _shadow(c, cx, cy, 75 * s, 85 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 54 * s, height: 58 * s), Radius.circular(10 * s)), Paint()..color = const Color(0xFF33691E));
    c.drawCircle(Offset(cx, cy - 26 * s), 18 * s, Paint()..color = const Color(0xFF1B5E20));
    for (int i = 0; i < 5; i++) {
      final a = i * 1.2;
      c.drawCircle(Offset(cx + cos(a) * 16 * s, cy + sin(a) * 14 * s), 4 * s, Paint()..color = const Color(0xFF8BC34A).withOpacity(0.7));
    }
    _flash(c, cx, cy, 50 * s, flash);
  }

  static void bloodChampion(Canvas c, double cx, double cy, double s, {double flash = 0, double rage = 0}) {
    _shadow(c, cx, cy, 70 * s, 80 * s);
    final body = Color.lerp(const Color(0xFFB71C1C), const Color(0xFFFF1744), rage)!;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 48 * s, height: 54 * s), Radius.circular(5 * s)), Paint()..color = body);
    c.drawCircle(Offset(cx, cy - 26 * s), 16 * s, Paint()..color = const Color(0xFF7F0000));
    c.drawLine(Offset(cx - 10 * s, cy - 32 * s), Offset(cx - 18 * s, cy - 46 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 4 * s);
    c.drawLine(Offset(cx + 10 * s, cy - 32 * s), Offset(cx + 18 * s, cy - 46 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 4 * s);
    powerSword(c, cx, cy, s * 1.15, accent: const Color(0xFFFF1744));
    _flash(c, cx, cy, 48 * s, flash);
  }

  static void cyclops(Canvas c, double cx, double cy, double s, {double flash = 0, double charge = 0}) {
    _shadow(c, cx, cy, 78 * s, 90 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 56 * s, height: 62 * s), Radius.circular(8 * s)), Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 28 * s), 20 * s, Paint()..color = const Color(0xFF3E2723));
    final eyeR = 8 * s + charge * 6 * s;
    c.drawCircle(Offset(cx, cy - 30 * s), eyeR, Paint()..color = Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFFEA00), charge)!);
    c.drawCircle(Offset(cx, cy - 30 * s), eyeR * 0.4, Paint()..color = Colors.white.withOpacity(0.8));
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
        text: TextSpan(text: affix.letter, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(cx - tp.width / 2, topY - tp.height / 2));
    }
  }

  static void altar(Canvas c, double cx, double cy, double t) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 28), const Radius.circular(4)), Paint()..color = const Color(0xFF5D4037));
    final pulse = 0.5 + 0.5 * sin(t * 3);
    c.drawCircle(Offset(cx, cy - 18), 10 + pulse * 3, Paint()..color = Color.fromRGBO(255, 215, 0, 0.4 + pulse * 0.3));
  }

  static void merchantStall(Canvas c, double cx, double cy, double t) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 48, height: 32), const Radius.circular(4)), Paint()..color = const Color(0xFF6D4C41));
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 20), width: 52, height: 8), Paint()..color = const Color(0xFFB8860B));
    final spark = 0.5 + 0.5 * sin(t * 4);
    c.drawCircle(Offset(cx + 16, cy - 8), 3 + spark, Paint()..color = Color.fromRGBO(255, 235, 59, 0.5 + spark * 0.4));
  }

  static void barrel(Canvas c, double cx, double cy) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 28, height: 34), const Radius.circular(4)), Paint()..color = const Color(0xFF8D6E63));
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 4), width: 28, height: 3), Paint()..color = const Color(0xFF5D4037));
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 6), width: 28, height: 3), Paint()..color = const Color(0xFF5D4037));
  }
}
// ═══════════════════════════════════════════════════════════════
// MAIN GAME
// ═══════════════════════════════════════════════════════════════

class InquisitorGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  // ── world ──
  static const double cellSize = 64;
  double mapWidth = 1280;
  double mapHeight = 1280;
  final Vector2 playerSpawnPos = Vector2(200, 200);
  final double safeRadius = cellSize * 5;

  // ── run state ──
  bool isPlaying = false;
  bool isPaused = false;
  bool isArena = false;
  Difficulty difficulty = Difficulty.normal;
  PlayerClass playerClass = PlayerClass.xenos;
  String playerName = 'Inquisitor';
  int currentFloor = 1;
  int currentLevel = 1;
  int pathIndex = 0;
  int maxFloors = 5;
  List<PathNode> floorPath = [];
  List<PathNode> pendingPathChoices = [];
  bool isBossLevel = false;
  bool isMiniBossLevel = false;
  bool isEliteNode = false;
  EventRoomType currentEvent = EventRoomType.none;
  bool eventResolved = true;
  int levelsSinceEvent = 0;

  // ── combat counters ──
  int score = 0;
  int scraps = 0;
  int skillPoints = 0;
  int enemiesAlive = 0;
  int enemiesToSpawn = 0;
  int enemiesSpawned = 0;
  double spawnTimer = 0;
  double spawnInterval = 1.0;
  int combo = 0;
  double comboTimer = 0;
  final Set<int> _comboMilestonesClaimed = {};
  int arenaKills = 0;

  // ── portal / no-kill timer ──
  bool portalSpawned = false;
  bool nearPortal = false;
  double levelElapsed = 0; // seconds on current node
  static const double timedPortalSec = 300; // 5 minutes
  bool timedPortalUsed = false;
  int killsThisLevel = 0;

  // ── secrets ──
  bool secretBossUnlockedThisLevel = false;
  bool secretBossSpawned = false;
  double cornerStandTimer = 0;
  bool tentacleDefeated = false;
  bool cyclopsDefeated = false;

  // ── player combat ──
  late Player player;
  bool usingMelee = false;
  RangedWeapon rangedWeapon = RangedWeapon.bolter;
  MeleeWeapon meleeWeapon = MeleeWeapon.sword;
  int maxHealth = 6;
  double playerSpeed = 160;
  double attackSpeedMult = 1.0;
  double defenseChance = 0;
  double dmgMult = 1.0;
  double tempDmgMult = 1.0;
  double tempDmgTimer = 0;
  double shieldTimer = 0;
  double invulnTimer = 0;
  double dashCooldown = 0;
  double dashActive = 0;
  double laserCooldown = 0;
  double holyAuraTimer = 0;
  double _hasteTimer = 0;
  double bolterHeat = 0;
  double staffWarpStress = 0;
  double warpResetCooldown = 0;
  double hereticusDashBoost = 0;
  double bossRetreatTimer = 0;
  double cinemaZoomTimer = 0;
  double shakeTime = 0;
  double shakePower = 0;
  double currentZoom = 0.85;
  ActiveArtifact activeArtifact = ActiveArtifact.none;
  double artifactCooldown = 0;
  bool ironWillUsedThisFloor = false;
  EchoBossKind pendingEcho = EchoBossKind.none;

  // unlocks
  bool unlockedRifle = false, unlockedShotgun = false;
  bool unlockedAxe = false, unlockedHammer = false;
  bool unlockedStormStaff = false, unlockedWarpBeam = false;
  bool unlockedForceSword = false, unlockedDaemonHammer = false;
  bool unlockedNeedles = false, unlockedSniperNeedle = false;
  bool unlockedPowerKatana = false, unlockedExecutioner = false;
  bool unlockedDash = true, unlockedLaser = false, unlockedArtifact = false;

  // damage baselines (recomputed)
  int bolterDamage = 8, rifleDamage = 16, shotgunDamage = 7;
  int staffDamage = 12, stormDamage = 10, warpDamage = 22;
  int daggerDamage = 6, needleDamage = 5, sniperNeedleDamage = 20;
  int swordDamage = 14, axeDamage = 18, hammerDamage = 28;
  int forceDamage = 16, forceSwordDamage = 20, daemonDamage = 30;
  int katanaDamage = 15, powerKatanaDamage = 19, execDamage = 26;

  // ── systems ──
  SkillTree skills = SkillTree();
  Customization custom = Customization();
  WeaponLoadout loadout = WeaponLoadout();
  WeaponMastery mastery = WeaponMastery();
  InquisitionRank inquisitionRank = InquisitionRank();
  RankChallenge activeChallenge = RankChallenge.none;
  bool challengeBossMeleeOk = true;
  final List<RelicId> relics = [];
  final Set<CodexId> codexUnlocked = {};
  final Map<String, int> loreRanks = {};
  CodexId? pendingLoreId;
  AchievementState achievements = AchievementState();
  final List<HighScoreEntry> highScores = [];
  final List<GameSave> saves = [];
  List<RewardOption> pendingRewards = [];

  // ── audio ──
  bool soundEnabled = true;
  bool musicEnabled = true;
  double musicVolume = 0.45;
  ui.AudioPlayer? _bgmPlayer; // ignore if using flame_audio only

  // ── HUD layout (sizes + positions) ──
  HudLayout hud = HudLayout();
  // legacy aliases used by settings UI
  double get joystickSize => hud.joystickSize;
  set joystickSize(double v) => hud.joystickSize = v;
  double get buttonSize => hud.buttonSize;
  set buttonSize(double v) => hud.buttonSize = v;

  late JoystickComponent moveJoystick;
  late JoystickComponent attackJoystick;
  HudButtonComponent? settingsBtn;
  HudButtonComponent? backpackBtn;
  HudButtonComponent? dashButton;
  HudButtonComponent? laserButton;
  HudButtonComponent? artifactButton;
  HudButtonComponent? warpResetButton;
  HudButtonComponent? portalButton;
  AttackCooldownRing? cooldownRing;

  // synergies flags
  bool get hasJediPath => relics.contains(RelicId.jediPath);
  bool get hasAmmoSavant => relics.contains(RelicId.ammoSavant);
  bool get hasWarpAnchor => relics.contains(RelicId.warpAnchor);
  bool get hasIronWill => relics.contains(RelicId.ironWill);
  bool get hasExecutionerMark => relics.contains(RelicId.executionerMark);
  bool get hasShieldPierce => relics.contains(RelicId.shieldPierce);
  bool get synergyXenosMastery => playerClass == PlayerClass.xenos && mastery.getCount('bolter') >= 50;
  bool get synergyXenosBlast => playerClass == PlayerClass.xenos && loadout.gunAmmo == GunAmmoMod.explosive && rangedWeapon == RangedWeapon.shotgun;
  bool get synergyHereticusBleedDash => playerClass == PlayerClass.hereticus && relics.contains(RelicId.critCharm);
  bool get synergyBloodRush => relics.contains(RelicId.vampirism) && relics.contains(RelicId.killExplosion);
  String? get activeSynergyLabel {
    final parts = <String>[];
    if (synergyXenosMastery) parts.add('Xenos Mastery');
    if (synergyXenosBlast) parts.add('Blast Cone');
    if (synergyHereticusBleedDash) parts.add('Bleed Dash');
    if (synergyBloodRush) parts.add('Blood Rush');
    return parts.isEmpty ? null : parts.join(' • ');
  }

  double get worldThreat => 1.0 + (currentFloor - 1) * 0.12 + (isArena ? arenaKills * 0.01 : 0);

  double get codexRangedBonus {
    double b = 0;
    for (final id in codexUnlocked) {
      final r = loreRankOf(id);
      if (r <= 0) continue;
      if (id == CodexId.shooter || id == CodexId.flamer || id == CodexId.sniper) b += 0.01 * r;
    }
    return b;
  }

  double get codexMeleeBonus {
    double b = 0;
    for (final id in codexUnlocked) {
      final r = loreRankOf(id);
      if (r <= 0) continue;
      if (id == CodexId.melee || id == CodexId.bloodletter || id == CodexId.dog) b += 0.01 * r;
    }
    return b;
  }

  double get codexShieldBonus {
    double b = 0;
    if (codexUnlocked.contains(CodexId.shielded)) b += 0.02 * loreRankOf(CodexId.shielded);
    return b;
  }

  double get codexBossBonus {
    double b = 0;
    for (final id in [CodexId.boss, CodexId.knight, CodexId.king, CodexId.miniBoss, CodexId.plagueLord, CodexId.bloodChampion]) {
      if (codexUnlocked.contains(id)) b += 0.02 * loreRankOf(id);
    }
    return b;
  }

  double get codexBurnBonus => codexUnlocked.contains(CodexId.flamer) ? 0.3 * loreRankOf(CodexId.flamer) : 0;

  int loreRankOf(CodexId id) => loreRanks[id.name] ?? 0;

  bool get areOtherBossesAlive {
    final w = world;
    return w.children.whereType<Boss>().any((b) => !b.isEcho) ||
        w.children.whereType<KnightBoss>().any((b) => !b.isEcho) ||
        w.children.whereType<PlagueLordBoss>().any((b) => !b.isEcho) ||
        w.children.whereType<BloodChampionBoss>().any((b) => !b.isEcho);
  }

  // ── lifecycle ──
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadMeta();
    camera.viewfinder.zoom = currentZoom;
    overlays.add('mainMenu');
  }

  Future<void> _loadMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final hs = prefs.getStringList('highScores') ?? [];
    highScores.clear();
    for (final s in hs) {
      try {
        highScores.add(HighScoreEntry.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    final sv = prefs.getStringList('saves') ?? [];
    saves.clear();
    for (final s in sv) {
      try {
        saves.add(GameSave.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    final rankRaw = prefs.getString('rank');
    if (rankRaw != null) {
      try {
        inquisitionRank = InquisitionRank.fromJson(jsonDecode(rankRaw) as Map<String, dynamic>);
      } catch (_) {}
    }
    final cust = prefs.getString('custom');
    if (cust != null) {
      try {
        custom = Customization.fromJson(jsonDecode(cust) as Map<String, dynamic>);
      } catch (_) {}
    }
    final hudRaw = prefs.getString('hudLayout');
    if (hudRaw != null) {
      try {
        hud = HudLayout.fromJson(jsonDecode(hudRaw) as Map<String, dynamic>);
      } catch (_) {}
    }
    final achRaw = prefs.getString('achievements');
    if (achRaw != null) {
      try {
        achievements = AchievementState.fromJson(jsonDecode(achRaw) as Map<String, dynamic>);
      } catch (_) {}
    }
    soundEnabled = prefs.getBool('sound') ?? true;
    musicEnabled = prefs.getBool('music') ?? true;
    musicVolume = prefs.getDouble('musicVol') ?? 0.45;
  }

  Future<void> persistMeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('highScores', highScores.map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setStringList('saves', saves.map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setString('rank', jsonEncode(inquisitionRank.toJson()));
    await prefs.setString('custom', jsonEncode(custom.toJson()));
    await prefs.setString('hudLayout', jsonEncode(hud.toJson()));
    await prefs.setString('achievements', jsonEncode(achievements.toJson()));
    await prefs.setBool('sound', soundEnabled);
    await prefs.setBool('music', musicEnabled);
    await prefs.setDouble('musicVol', musicVolume);
  }

  Future<void> persistCustomization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom', jsonEncode(custom.toJson()));
    await prefs.setString('hudLayout', jsonEncode(hud.toJson()));
  }

  // ── achievements ──
  Future<void> unlockAchievement(AchievementId id) async {
    if (achievements.has(id)) return;
    achievements.unlocked.add(id.name);
    await persistMeta();
    if (isPlaying) {
      spawnDamageNumber(player.position.clone() + Vector2(0, -50), 0, color: const Color(0xFFFFD700), label: '★ ${id.title}');
    }
  }

  void noteClassPlayed(PlayerClass c) {
    achievements.classesPlayed.add(c.name);
    if (achievements.classesPlayed.length >= 3) {
      unlockAchievement(AchievementId.allClasses);
    }
    persistMeta();
  }

  // ── audio stubs (flame_audio assets/sounds/) ──
  void playClick() {
    if (!soundEnabled) return;
    try {
      FlameAudio.play('click.mp3', volume: 0.4);
    } catch (_) {}
  }

  void playShoot() {
    if (!soundEnabled) return;
    try {
      FlameAudio.play('shoot.mp3', volume: 0.35);
    } catch (_) {}
  }

  void playMelee() {
    if (!soundEnabled) return;
    try {
      FlameAudio.play('melee.mp3', volume: 0.4);
    } catch (_) {}
  }

  void startMusic() {
    if (!musicEnabled) return;
    try {
      FlameAudio.bgm.play('bgm.mp3', volume: musicVolume);
    } catch (_) {}
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  void applyMusicSetting() {
    if (musicEnabled) {
      startMusic();
    } else {
      stopMusic();
    }
  }

  // ── stats ──
  void recomputeStats() {
    maxHealth = (playerClass == PlayerClass.xenos ? 6 : 5) + skills.hp;
    playerSpeed = (playerClass == PlayerClass.hereticus ? 175.0 : 155.0) + skills.speed * 8;
    attackSpeedMult = 1.0 / (1.0 + skills.attackSpeed * 0.06);
    defenseChance = skills.defense * 0.04;
    dmgMult = 1.0 + skills.damage * 0.07 + inquisitionRank.critBonus + codexRangedBonus + codexMeleeBonus;

    bolterDamage = (8 * dmgMult).round();
    rifleDamage = (16 * dmgMult).round();
    shotgunDamage = (7 * dmgMult).round();
    staffDamage = (14 * dmgMult * (loadout.staffFocus == StaffFocusMod.focused ? 1.2 : loadout.staffFocus == StaffFocusMod.wideSphere ? 0.85 : 1.0)).round();
    stormDamage = (11 * dmgMult).round();
    warpDamage = (22 * dmgMult).round();
    daggerDamage = (6 * dmgMult).round();
    needleDamage = (5 * dmgMult).round();
    sniperNeedleDamage = (20 * dmgMult).round();

    final blade = loadout.bladeEdge == BladeEdgeMod.mono
        ? 1.12
        : loadout.bladeEdge == BladeEdgeMod.serrated
            ? 1.08
            : loadout.bladeEdge == BladeEdgeMod.weighted
                ? 1.15
                : 1.0;
    swordDamage = (14 * dmgMult * blade * mastery.meleeMasteryMult('sword')).round();
    axeDamage = (18 * dmgMult * blade * mastery.meleeMasteryMult('axe')).round();
    hammerDamage = (28 * dmgMult * blade * mastery.meleeMasteryMult('hammer')).round();
    forceDamage = (16 * dmgMult * blade).round();
    forceSwordDamage = (20 * dmgMult * blade).round();
    daemonDamage = (30 * dmgMult * blade).round();
    katanaDamage = (15 * dmgMult * blade * mastery.meleeMasteryMult('katana')).round();
    powerKatanaDamage = (19 * dmgMult * blade).round();
    execDamage = (26 * dmgMult * blade).round();

    if (loadout.gunSight == GunSightMod.precision) {
      bolterDamage = (bolterDamage * 1.1).round();
      rifleDamage = (rifleDamage * 1.1).round();
    }
    if (loadout.gunBarrel == GunBarrelMod.heavy) {
      bolterDamage = (bolterDamage * 1.25).round();
      rifleDamage = (rifleDamage * 1.2).round();
    }
  }

  double staffRadiusMult() {
    var m = mastery.staffRadiusMult();
    if (loadout.staffFocus == StaffFocusMod.wideSphere) m *= 1.35;
    if (loadout.staffFocus == StaffFocusMod.focused) m *= 0.8;
    return m;
  }

  int scaleDamage(int base) {
    var d = base * tempDmgMult;
    if (relics.contains(RelicId.critCharm) && Random().nextDouble() < 0.12 + inquisitionRank.critBonus) {
      d *= 1.75;
    }
    return d.round().clamp(1, 9999);
  }

  // ── HUD rebuild (FIX: sizes & positions apply in combat) ──
  Vector2 _hudPos(double nx, double ny, {bool fromBottom = true}) {
    final sz = size;
    final x = nx * sz.x;
    final y = fromBottom ? sz.y - ny * sz.y : ny * sz.y;
    return Vector2(x, y);
  }

  void rebuildHud() {
    // remove old controls
    moveJoystick.removeFromParent();
    attackJoystick.removeFromParent();
    settingsBtn?.removeFromParent();
    backpackBtn?.removeFromParent();
    dashButton?.removeFromParent();
    laserButton?.removeFromParent();
    artifactButton?.removeFromParent();
    warpResetButton?.removeFromParent();
    portalButton?.removeFromParent();
    cooldownRing?.removeFromParent();

    final js = hud.joystickSize;
    final bs = hud.buttonSize;

    moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: js * 0.35, paint: Paint()..color = const Color(0xFFB8860B).withOpacity(0.85)),
      background: CircleComponent(radius: js * 0.5, paint: Paint()..color = const Color(0xFF1A1A1A).withOpacity(0.55)),
      margin: EdgeInsets.only(left: hud.moveX * size.x - js * 0.5, bottom: hud.moveY * size.y - js * 0.5),
    );
    attackJoystick = JoystickComponent(
      knob: CircleComponent(radius: js * 0.35, paint: Paint()..color = const Color(0xFFE53935).withOpacity(0.85)),
      background: CircleComponent(radius: js * 0.5, paint: Paint()..color = const Color(0xFF1A1A1A).withOpacity(0.55)),
      margin: EdgeInsets.only(right: (1 - hud.atkX) * size.x - js * 0.5, bottom: hud.atkY * size.y - js * 0.5),
    );

    camera.viewport.add(moveJoystick);
    camera.viewport.add(attackJoystick);

    settingsBtn = HudButtonComponent(
      button: CircleComponent(radius: bs * 0.5, paint: Paint()..color = const Color(0xFF37474F)),
      position: _hudPos(hud.settingsX, hud.settingsY, fromBottom: false),
      onPressed: openSettings,
    )..priority = 200;
    backpackBtn = HudButtonComponent(
      button: CircleComponent(radius: bs * 0.5, paint: Paint()..color = const Color(0xFF4E342E)),
      position: _hudPos(hud.backpackX, hud.backpackY, fromBottom: false),
      onPressed: openBackpack,
    )..priority = 200;
    camera.viewport.add(settingsBtn!);
    camera.viewport.add(backpackBtn!);
    camera.viewport.add(HudLabel(text: 'S', target: settingsBtn!)..priority = 201);
    camera.viewport.add(HudLabel(text: 'B', target: backpackBtn!)..priority = 201);

    if (playerClass == PlayerClass.hereticus || unlockedDash) {
      dashButton = HudButtonComponent(
        button: CircleComponent(radius: bs * 0.5, paint: Paint()..color = const Color(0xFF6A1B9A)),
        position: _hudPos(hud.dashX, hud.dashY),
        onPressed: activateDash,
      )..priority = 200;
      camera.viewport.add(dashButton!);
      camera.viewport.add(HudLabel(text: 'U', target: dashButton!)..priority = 201);
    }
    if (unlockedLaser) {
      laserButton = HudButtonComponent(
        button: CircleComponent(radius: bs * 0.5, paint: Paint()..color = const Color(0xFFFF6D00)),
        position: _hudPos(hud.laserX, hud.laserY),
        onPressed: activateLaser,
      )..priority = 200;
      camera.viewport.add(laserButton!);
      camera.viewport.add(HudLabel(text: 'L', target: laserButton!)..priority = 201);
    }
    if (unlockedArtifact && activeArtifact != ActiveArtifact.none) {
      artifactButton = HudButtonComponent(
        button: CircleComponent(radius: bs * 0.5, paint: Paint()..color = const Color(0xFF1B5E20)),
        position: _hudPos(hud.artifactX, hud.artifactY),
        onPressed: activateArtifact,
      )..priority = 200;
      camera.viewport.add(artifactButton!);
      camera.viewport.add(HudLabel(text: 'R', target: artifactButton!)..priority = 201);
    }
    if (playerClass == PlayerClass.malleus) {
      warpResetButton = HudButtonComponent(
        button: CircleComponent(radius: bs * 0.5, paint: Paint()..color = const Color(0xFF7C4DFF)),
        position: _hudPos(hud.warpX, hud.warpY),
        onPressed: resetWarpStress,
      )..priority = 200;
      camera.viewport.add(warpResetButton!);
      camera.viewport.add(HudLabel(text: 'Ψ', target: warpResetButton!)..priority = 201);
    }

    cooldownRing = AttackCooldownRing(game: this, joystick: attackJoystick)..priority = 199;
    camera.viewport.add(cooldownRing!);
  }

  void grantInvuln(double t) => invulnTimer = max(invulnTimer, t);

  void triggerShake({double power = 6, double time = 0.15}) {
    shakePower = power;
    shakeTime = time;
  }

  void triggerCinemaZoom() {
    cinemaZoomTimer = 0.45;
  }

  void markBossRetreat() => bossRetreatTimer = 0.8;

  void noteBossDamagedByRanged() {
    if (activeChallenge == RankChallenge.meleeOnlyBoss && isBossLevel) {
      challengeBossMeleeOk = false;
    }
  }

  void spawnDamageNumber(Vector2 pos, int amount, {Color color = const Color(0xFFFFEB3B), String? label}) {
    world.add(DamageNumber(position: pos.clone(), amount: amount, color: color, label: label));
  }

  void spawnBlood(Vector2 pos, {int count = 12, Vector2? fromDir}) {
    world.add(BloodSplash(position: pos.clone(), count: count, fromDir: fromDir));
  }

  void spawnCorruptionZone(Vector2 pos) {
    world.add(CorruptionZone(position: pos.clone()));
  }

  BulletMod rollBulletMod() {
    final r = Random().nextDouble();
    if (r < 0.08) return BulletMod.slow;
    if (r < 0.14) return BulletMod.ricochet;
    if (r < 0.18) return BulletMod.split;
    return BulletMod.normal;
  }

  // ── path / floors ──
  void generateFloorPath() {
    floorPath = [];
    // 5 nodes per floor: combat, event/elite, combat, rest/elite, boss
    floorPath.add(PathNode(PathNodeKind.combat, 'Бой'));
    floorPath.add(PathNode(Random().nextBool() ? PathNodeKind.event : PathNodeKind.elite, Random().nextBool() ? 'Событие' : 'Элита'));
    floorPath.add(PathNode(PathNodeKind.combat, 'Бой'));
    floorPath.add(PathNode(Random().nextBool() ? PathNodeKind.rest : PathNodeKind.elite, Random().nextBool() ? 'Отдых' : 'Элита'));
    floorPath.add(PathNode(PathNodeKind.boss, 'Босс'));
    pathIndex = 0;
    syncLevelFromPath();
  }

  void syncLevelFromPath() {
    currentLevel = pathIndex + 1;
    if (floorPath.isNotEmpty && pathIndex < floorPath.length) {
      isBossLevel = floorPath[pathIndex].kind == PathNodeKind.boss;
    }
  }

  PathNodeKind get currentNodeKind {
    if (floorPath.isEmpty || pathIndex >= floorPath.length) {
      return currentLevel >= 5 ? PathNodeKind.boss : PathNodeKind.combat;
    }
    return floorPath[pathIndex].kind;
  }

  int get maxFloorsForDiff => difficulty.maxFloors;

  // ── unlocks by overall progress ──
  void _checkUnlocks() {
    final overall = (currentFloor - 1) * 5 + currentLevel;
    if (overall >= 11) {
      unlockedRifle = true;
      unlockedAxe = true;
      unlockedStormStaff = true;
      unlockedForceSword = true;
      unlockedNeedles = true;
      unlockedPowerKatana = true;
    }
    if (overall >= 21) {
      unlockedShotgun = true;
      unlockedHammer = true;
      unlockedWarpBeam = true;
      unlockedDaemonHammer = true;
      unlockedSniperNeedle = true;
      unlockedExecutioner = true;
    }
    if (tentacleDefeated) unlockedDash = true;
    if (cyclopsDefeated) unlockedLaser = true;
  }
}
  // ── spawn points ──
  List<Vector2> getEnemySpawnPointsRaw() {
    final cx = mapWidth / 2, cy = mapHeight / 2;
    final pts = <Vector2>[];
    switch (((currentFloor - 1) % 5) + 1) {
      case 1: // cross hall
        for (final o in [-320.0, -160.0, 160.0, 320.0]) {
          pts.add(Vector2(cx + o, cy - 280));
          pts.add(Vector2(cx + o, cy + 280));
          pts.add(Vector2(cx - 320, cy + o * 0.5));
          pts.add(Vector2(cx + 320, cy + o * 0.5));
        }
        break;
      case 2: // ring
        for (int i = 0; i < 12; i++) {
          final a = i / 12 * pi * 2;
          pts.add(Vector2(cx + cos(a) * 340, cy + sin(a) * 300));
        }
        break;
      case 3: // corners + mid
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
      case 4: // lanes
        for (double y = 160; y < mapHeight - 160; y += 140) {
          pts.add(Vector2(160, y));
          pts.add(Vector2(mapWidth - 160, y));
        }
        break;
      default: // dense grid
        for (double x = 160; x < mapWidth - 160; x += 180) {
          for (double y = 160; y < mapHeight - 160; y += 180) {
            if ((x - cx).abs() < 100 && (y - cy).abs() < 100) continue;
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
      return [EventRoomType.altar, EventRoomType.merchant, EventRoomType.trap][Random().nextInt(3)];
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
      color: const Color(0xFFE91E63),
      label: fromTimer ? 'ПОРТАЛ (5 мин)' : 'ПОРТАЛ',
    );
  }

  int countLivingHostiles() {
    var n = 0;
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
    // clear room
    if (countLivingHostiles() <= 0 && enemiesSpawned >= enemiesToSpawn && !isBossLevel) {
      _forceSpawnPortal();
      return;
    }
    // boss clear
    if (isBossLevel && countLivingHostiles() <= 0 && secretBossSpawned == false) {
      // allow secret window; portal still after small delay via living count
      _forceSpawnPortal();
    }
  }

  void _spawnEventProps() {
    if (currentEvent == EventRoomType.altar) {
      world.add(EventAltarProp(position: Vector2(mapWidth / 2, mapHeight / 2 - 40))..priority = 10);
    } else if (currentEvent == EventRoomType.merchant) {
      world.add(EventMerchantProp(position: Vector2(mapWidth / 2, mapHeight / 2 - 40))..priority = 10);
    }
  }

  void _startTrapWave() {
    eventResolved = true;
    final pts = getEnemySpawnPoints();
    final n = 6 + currentFloor;
    enemiesToSpawn += n;
    for (int i = 0; i < n; i++) {
      final pos = pts.isEmpty ? Vector2(mapWidth / 2, mapHeight / 2) : pts[Random().nextInt(pts.length)].clone();
      _spawnOneEnemy(pos, forceChampion: i == 0);
    }
  }

  EnemyType _rollEnemyType() {
    final overall = (currentFloor - 1) * 5 + currentLevel;
    final r = Random().nextDouble();
    if (overall >= 20 && r < 0.12) return EnemyType.shieldedShooter;
    if (overall >= 11 && r < 0.18) return EnemyType.dog;
    if (overall >= 13 && r < 0.12) return EnemyType.cultPsyker;
    if (overall >= 15 && r < 0.10) return EnemyType.plagueBearer;
    if (overall >= 16 && r < 0.10) return EnemyType.bloodletter;
    if (overall >= 8 && r < 0.12) return EnemyType.flamer;
    if (overall >= 9 && r < 0.10) return EnemyType.sniper;
    if (overall >= 10 && r < 0.08) return EnemyType.brute;
    if (r < 0.34) return EnemyType.shooter;
    if (r < 0.62) return EnemyType.melee;
    if (r < 0.78) return EnemyType.shielded;
    return EnemyType.shooter;
  }

  EliteAffix _rollAffix() {
    final r = Random().nextDouble();
    if (r < 0.20) return EliteAffix.swift;
    if (r < 0.40) return EliteAffix.regenerating;
    if (r < 0.58) return EliteAffix.explosive;
    if (r < 0.74) return EliteAffix.reflect;
    if (r < 0.90) return EliteAffix.summoner;
    return EliteAffix.none;
  }

  void _spawnOneEnemy(Vector2 pos, {bool forceChampion = false}) {
    final type = _rollEnemyType();
    final champ = forceChampion || isEliteNode || Random().nextDouble() < (isArena ? 0.12 : 0.08);
    final affix = champ ? _rollAffix() : EliteAffix.none;
    final e = Enemy(floor: currentFloor, type: type, isChampion: champ, affix: affix);
    e.position = pos;
    e.priority = 30;
    world.add(e);
    enemiesAlive++;
    enemiesSpawned++;
    // spawn portal marker
    world.add(SpawnPortalMarker(position: pos.clone())..priority = 7);
  }

  void _spawnFloorBosses() {
    final bossPos = Vector2(mapWidth / 2, mapHeight / 2 - 260);
    final floor = currentFloor;

    // main ranged boss
    world.add(Boss(floor: floor, position: bossPos.clone())..priority = 25);
    enemiesAlive++;
    enemiesToSpawn++;
    enemiesSpawned++;

    // knight + specials on higher floors
    if (floor >= 3) {
      world.add(KnightBoss(floor: floor, position: bossPos + Vector2(-180, 40))..priority = 25);
      enemiesAlive++;
      enemiesToSpawn++;
      enemiesSpawned++;
    }
    if (floor >= 4) {
      world.add(PlagueLordBoss(position: bossPos + Vector2(180, 60))..priority = 26);
      enemiesAlive++;
      enemiesToSpawn++;
      enemiesSpawned++;
    }
    if (floor >= 5) {
      world.add(BloodChampionBoss(position: bossPos + Vector2(0, 120))..priority = 26);
      enemiesAlive++;
      enemiesToSpawn++;
      enemiesSpawned++;
    }
    // king on last floors
    if (floor >= maxFloorsForDiff || floor >= 5) {
      world.add(KingBoss(position: Vector2(mapWidth / 2, mapHeight / 2))..priority = 26);
      enemiesAlive++;
      enemiesToSpawn++;
      enemiesSpawned++;
    }

    // echo
    if (pendingEcho != EchoBossKind.none && Random().nextDouble() < 0.10) {
      final echoPos = bossPos + Vector2(0, 200);
      switch (pendingEcho) {
        case EchoBossKind.mini:
          world.add(MiniBoss(floor: floor, position: echoPos, isEcho: true));
          break;
        case EchoBossKind.ranged:
          world.add(Boss(floor: floor, position: echoPos, isEcho: true));
          break;
        case EchoBossKind.knight:
          world.add(KnightBoss(floor: floor, position: echoPos, isEcho: true));
          break;
        case EchoBossKind.king:
          world.add(KingBoss(position: echoPos, isEcho: true));
          break;
        case EchoBossKind.plague:
          world.add(PlagueLordBoss(position: echoPos, isEcho: true));
          break;
        case EchoBossKind.blood:
          world.add(BloodChampionBoss(position: echoPos, isEcho: true));
          break;
        case EchoBossKind.none:
          break;
      }
      enemiesAlive++;
      enemiesToSpawn++;
      enemiesSpawned++;
    }
    pendingEcho = EchoBossKind.none;
  }

  void _startLevel() {
    // clear world entities except we rebuild fully
    world.removeAll(world.children.toList());
    camera.viewport.children.whereType<HudLabel>().toList().forEach((c) => c.removeFromParent());
    portalButton?.removeFromParent();
    portalButton = null;
    dashButton?.removeFromParent();
    dashButton = null;
    laserButton?.removeFromParent();
    laserButton = null;
    artifactButton?.removeFromParent();
    artifactButton = null;
    warpResetButton?.removeFromParent();
    warpResetButton = null;

    syncLevelFromPath();
    _checkUnlocks();
    recomputeStats();
    ironWillUsedThisFloor = false;

    final node = currentNodeKind;
    isBossLevel = node == PathNodeKind.boss;
    isMiniBossLevel = !isBossLevel && currentLevel == 3;
    isEliteNode = node == PathNodeKind.elite;
    portalSpawned = false;
    nearPortal = false;
    secretBossUnlockedThisLevel = false;
    secretBossSpawned = false;
    cornerStandTimer = 0;
    combo = 0;
    comboTimer = 0;
    _comboMilestonesClaimed.clear();
    invulnTimer = 0;
    hereticusDashBoost = 0;
    bossRetreatTimer = 0;
    bolterHeat = max(0, bolterHeat - 0.35);
    staffWarpStress = max(0, staffWarpStress - 0.35);
    levelElapsed = 0;
    killsThisLevel = 0;
    timedPortalUsed = false;

    if (node == PathNodeKind.event) {
      currentEvent = [EventRoomType.altar, EventRoomType.merchant, EventRoomType.trap][Random().nextInt(3)];
      eventResolved = false;
    } else if (node == PathNodeKind.rest) {
      currentEvent = EventRoomType.none;
      eventResolved = true;
    } else {
      currentEvent = _rollEvent();
      eventResolved = currentEvent == EventRoomType.none;
    }

    final wallColor = Color.lerp(const Color(0xFF5D4037), const Color(0xFF3E2723), ((currentFloor - 1) % 5) / 4)!;
    world.add(Floor(size: Vector2(mapWidth, mapHeight)));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, mapHeight - 70), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(Wall(position: Vector2(mapWidth - 70, 0), size: Vector2(70, mapHeight), color: wallColor));

    // inner obstacles — keep clear near player spawn
    final rnd = Random();
    for (int i = 0; i < 10 + currentFloor; i++) {
      final p = Vector2(120 + rnd.nextDouble() * (mapWidth - 240), 120 + rnd.nextDouble() * (mapHeight - 240));
      if (p.distanceTo(playerSpawnPos) < safeRadius) continue;
      if (rnd.nextBool()) {
        world.add(Obstacle(position: p)..priority = 8);
      } else {
        world.add(BreakableBarrel(position: p)..priority = 8);
      }
    }

    // player
    player = Player(moveJoystick);
    player.position = playerSpawnPos.clone();
    player.health = min(player.health > 0 ? player.health : maxHealth, maxHealth);
    if (node == PathNodeKind.rest) {
      player.health = min(maxHealth, player.health + 2);
    }
    world.add(player);
    camera.follow(player);

    // purple spawn marker
    world.add(PlayerSpawnMarker(position: playerSpawnPos.clone())..priority = 6);

    enemiesAlive = 0;
    enemiesSpawned = 0;
    enemiesToSpawn = 0;

    if (isArena) {
      enemiesToSpawn = 999999; // endless
      spawnInterval = 0.85;
    } else if (isBossLevel) {
      _spawnFloorBosses();
    } else if (isMiniBossLevel) {
      final pts = getEnemySpawnPoints();
      final pos = pts.isNotEmpty ? pts[rnd.nextInt(pts.length)] : Vector2(mapWidth / 2, mapHeight / 2 - 200);
      world.add(MiniBoss(floor: currentFloor, position: pos)..priority = 24);
      enemiesAlive++;
      enemiesToSpawn = 1 + 4 + currentFloor;
      enemiesSpawned = 1;
      // also small pack
      for (int i = 0; i < 3; i++) {
        if (pts.isEmpty) break;
        _spawnOneEnemy(pts[rnd.nextInt(pts.length)].clone());
      }
    } else if (node == PathNodeKind.rest) {
      enemiesToSpawn = 0;
      _forceSpawnPortal();
    } else {
      enemiesToSpawn = (6 + currentFloor * 2 + currentLevel + (isEliteNode ? 4 : 0) * (difficulty == Difficulty.hard ? 1.3 : 1.0)).round();
      spawnInterval = max(0.4, 1.15 - currentFloor * 0.06 - currentLevel * 0.04);
      // initial burst
      final pts = getEnemySpawnPoints();
      final burst = min(4, enemiesToSpawn);
      for (int i = 0; i < burst; i++) {
        if (pts.isEmpty) break;
        _spawnOneEnemy(pts[rnd.nextInt(pts.length)].clone(), forceChampion: isEliteNode && i == 0);
      }
    }

    _spawnEventProps();
    rebuildHud();

    if (currentEvent == EventRoomType.trap) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (isPlaying && !eventResolved && currentEvent == EventRoomType.trap) {
          _startTrapWave();
        }
      });
    }

    if (currentEvent == EventRoomType.altar) {
      overlays.add('eventAltar');
      isPaused = true;
    } else if (currentEvent == EventRoomType.merchant) {
      overlays.add('eventMerchant');
      isPaused = true;
    }
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
    enemiesAlive = max(0, enemiesAlive - 1);
    killsThisLevel++;
    if (isArena) arenaKills++;

    final pos = at ?? player.position.clone();
    var pts = 10 + currentFloor * 2;
    if (isChampion) pts *= 3;
    if (isBoss) pts *= 8;
    if (affix != EliteAffix.none) pts = (pts * 1.4).round();
    score += (pts * (1 + combo * 0.05)).round();

    // scraps
    var scrapGain = isChampion ? 4 : (isBoss ? 12 : 1 + Random().nextInt(2));
    if (relics.contains(RelicId.scavenger)) scrapGain = (scrapGain * 1.4).round();
    scrapGain = (scrapGain * inquisitionRank.scrapMult).round();
    scraps += scrapGain;

    // combo
    combo++;
    comboTimer = 3.0;
    if (combo >= 15) unlockAchievement(AchievementId.combo15);
    if (combo == 5 || combo == 10 || combo == 15) {
      if (_comboMilestonesClaimed.add(combo)) {
        scraps += 1;
        world.add(ComboBanner(position: pos.clone(), combo: combo));
      }
    }

    // mastery
    if (meleeKill) {
      final key = switch (meleeWeapon) {
        MeleeWeapon.sword => 'sword',
        MeleeWeapon.axe => 'axe',
        MeleeWeapon.hammer => 'hammer',
        MeleeWeapon.katana || MeleeWeapon.powerKatana || MeleeWeapon.executioner => 'katana',
        _ => 'sword',
      };
      mastery.addKill(key);
    } else {
      final key = switch (rangedWeapon) {
        RangedWeapon.bolter || RangedWeapon.rifle || RangedWeapon.shotgun => 'bolter',
        RangedWeapon.staff || RangedWeapon.stormStaff || RangedWeapon.warpBeam => 'staff',
        _ => 'bolter',
      };
      mastery.addKill(key);
    }

    // relics procs
    if (relics.contains(RelicId.vampirism) && Random().nextDouble() < 0.12) {
      player.health = min(maxHealth, player.health + 1);
    }
    if (relics.contains(RelicId.killExplosion) && at != null) {
      world.add(KillExplosion(position: at.clone(), radius: 55, damage: 5 + currentFloor, applyBurn: synergyBloodRush)..priority = 12);
    }

    // codex
    if (type != null) {
      final id = switch (type) {
        EnemyType.shooter => CodexId.shooter,
        EnemyType.melee => CodexId.melee,
        EnemyType.shielded || EnemyType.shieldedShooter => CodexId.shielded,
        EnemyType.dog => CodexId.dog,
        EnemyType.flamer => CodexId.flamer,
        EnemyType.sniper => CodexId.sniper,
        EnemyType.brute => CodexId.brute,
        EnemyType.cultPsyker => CodexId.cultPsyker,
        EnemyType.plagueBearer => CodexId.plagueBearer,
        EnemyType.bloodletter => CodexId.bloodletter,
      };
      unlockCodex(id);
    }

    if (isChampion) {
      achievements.championsKilledTotal++;
      if (achievements.championsKilledTotal >= 10) unlockAchievement(AchievementId.championHunter);
      if (Random().nextDouble() < 0.25) {
        _grantRandomRelic();
      }
    }

    if (isBoss) {
      unlockAchievement(AchievementId.bossSlayer);
      if (echoKind != EchoBossKind.none) {
        pendingEcho = echoKind;
      }
      triggerShake(power: 10, time: 0.25);
    }

    unlockAchievement(AchievementId.firstBlood);
    if (isArena && arenaKills >= 50) unlockAchievement(AchievementId.arena50);
    if (isArena && arenaKills >= 100) unlockAchievement(AchievementId.arena100);
    if (scraps >= 100) unlockAchievement(AchievementId.scrapHoarder);
    if (relics.length >= 5) unlockAchievement(AchievementId.relicHunter);

    // arena: never stop — keep quota high
    if (isArena) {
      enemiesToSpawn = enemiesSpawned + 20;
      spawnInterval = max(0.35, 0.9 - arenaKills * 0.002);
    }

    _checkPortal();
  }

  void unlockCodex(CodexId id) {
    if (codexUnlocked.add(id)) {
      pendingLoreId = id;
      if (!overlays.isActive('lorePopup')) {
        isPaused = true;
        overlays.add('lorePopup');
      }
      if (codexUnlocked.length >= CodexId.values.length) {
        unlockAchievement(AchievementId.fullCodex);
      }
    }
  }

  void acceptLore(CodexId id, {bool fromPopup = true}) {
    final rank = loreRankOf(id);
    if (rank >= 2) {
      if (fromPopup) skipLore();
      return;
    }
    if (rank == 1) {
      if (skillPoints < 1) return;
      skillPoints -= 1;
    }
    loreRanks[id.name] = rank + 1;
    recomputeStats();
    if (fromPopup) skipLore();
  }

  void skipLore() {
    pendingLoreId = null;
    overlays.remove('lorePopup');
    isPaused = false;
  }

  void _grantRandomRelic() {
    final pool = RelicId.values.where((r) => !relics.contains(r)).toList();
    if (pool.isEmpty) return;
    final r = pool[Random().nextInt(pool.length)];
    relics.add(r);
    spawnDamageNumber(player.position, 0, color: const Color(0xFFFFD700), label: r.title);
    if (relics.length >= 5) unlockAchievement(AchievementId.relicHunter);
  }

  void onSecretBossKilled({required bool cyclops}) {
    score += 6666;
    scraps += 30;
    if (cyclops) {
      cyclopsDefeated = true;
      unlockedLaser = true;
      unlockAchievement(AchievementId.secretCyclops);
      unlockCodex(CodexId.cyclops);
    } else {
      tentacleDefeated = true;
      unlockedDash = true;
      unlockAchievement(AchievementId.secretTentacle);
      unlockCodex(CodexId.tentacle);
    }
    spawnDamageNumber(player.position, 6666, color: const Color(0xFFE040FB), label: '+6666');
    rebuildHud();
    _checkPortal();
  }

  // abilities
  void activateDash() {
    if (dashCooldown > 0 || activeChallenge == RankChallenge.noDash) return;
    dashCooldown = 6.0 * (relics.contains(RelicId.shadowStep) ? 0.75 : 1.0);
    dashActive = 2.0;
    grantInvuln(0.25);
    // afterimages
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 50 * i), () {
        if (!isPlaying) return;
        world.add(AfterImage(position: player.position.clone(), size: player.size.clone())..priority = 18);
      });
    }
    if (synergyHereticusBleedDash) hereticusDashBoost = 1.5;
  }

  void activateLaser() {
    if (laserCooldown > 0 || !unlockedLaser) return;
    laserCooldown = 20;
    final dir = player.aimDir.length2 < 0.01 ? Vector2(0, -1) : player.aimDir.normalized();
    world.add(CyclopsLaserBeam(position: player.position.clone(), direction: dir, damage: scaleDamage(40))..priority = 14);
  }

  void activateArtifact() {
    if (artifactCooldown > 0 || activeArtifact == ActiveArtifact.none) return;
    artifactCooldown = 14;
    switch (activeArtifact) {
      case ActiveArtifact.fragGrenade:
        world.add(FragGrenade(position: player.position.clone(), direction: player.aimDir)..priority = 15);
        break;
      case ActiveArtifact.holyAura:
        holyAuraTimer = 8;
        break;
      case ActiveArtifact.servoTurret:
        world.add(ServoTurret(position: player.position + Vector2(40, 0))..priority = 12);
        break;
      case ActiveArtifact.none:
        break;
    }
  }

  void resetWarpStress() {
    if (playerClass != PlayerClass.malleus) return;
    if (warpResetCooldown > 0) return;
    if (staffWarpStress < 0.05) return;
    if (skillPoints > 0) {
      skillPoints -= 1;
      staffWarpStress = 0;
      warpResetCooldown = 8;
      spawnDamageNumber(player.position, 0, color: const Color(0xFFB388FF), label: 'Ψ СБРОС');
    } else {
      warpResetCooldown = 12;
      staffWarpStress = max(0, staffWarpStress - 0.5);
      spawnDamageNumber(player.position, 0, color: const Color(0xFFB388FF), label: 'Ψ');
    }
  }

  void usePortal() {
    if (!portalSpawned || !nearPortal) return;
    // no-kills achievement
    if (killsThisLevel == 0 && levelElapsed >= timedPortalSec * 0.9) {
      unlockAchievement(AchievementId.noKills);
    }
    if (timedPortalUsed) {
      unlockAchievement(AchievementId.timedPortal);
    }
    portalButton?.removeFromParent();
    portalButton = null;
    nearPortal = false;
    goNextLevel();
  }
  // ── update loop ──
  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying || isPaused) return;

    levelElapsed += dt;
    // Timed portal (5 min) — for no-kill achievement
    if (!portalSpawned && !isArena && levelElapsed >= timedPortalSec) {
      _forceSpawnPortal(fromTimer: true);
    }

    bolterHeat = max(0, bolterHeat - dt * 0.18);
    staffWarpStress = max(0, staffWarpStress - dt * 0.12);
    if (dashCooldown > 0) dashCooldown = max(0, dashCooldown - dt);
    if (dashActive > 0) dashActive = max(0, dashActive - dt);
    if (laserCooldown > 0) laserCooldown = max(0, laserCooldown - dt);
    if (artifactCooldown > 0) artifactCooldown = max(0, artifactCooldown - dt);
    if (warpResetCooldown > 0) warpResetCooldown = max(0, warpResetCooldown - dt);
    if (holyAuraTimer > 0) holyAuraTimer = max(0, holyAuraTimer - dt);
    if (_hasteTimer > 0) _hasteTimer = max(0, _hasteTimer - dt);
    if (shieldTimer > 0) shieldTimer = max(0, shieldTimer - dt);
    if (invulnTimer > 0) invulnTimer = max(0, invulnTimer - dt);
    if (bossRetreatTimer > 0) bossRetreatTimer = max(0, bossRetreatTimer - dt);
    if (tempDmgTimer > 0) {
      tempDmgTimer -= dt;
      if (tempDmgTimer <= 0) tempDmgMult = 1.0;
    }
    if (hereticusDashBoost > 0) hereticusDashBoost = max(0, hereticusDashBoost - dt);

    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 0;
    }

    // camera shake
    if (shakeTime > 0) {
      shakeTime -= dt;
      final ox = (Random().nextDouble() - 0.5) * shakePower;
      final oy = (Random().nextDouble() - 0.5) * shakePower;
      camera.viewfinder.position = player.position + Vector2(ox, oy);
    }

    // cinema zoom
    if (cinemaZoomTimer > 0) {
      cinemaZoomTimer -= dt;
      camera.viewfinder.zoom = currentZoom + 0.12 * (cinemaZoomTimer / 0.45);
    } else {
      camera.viewfinder.zoom = currentZoom;
    }

    // spawn waves
    if (isArena || (!isBossLevel && enemiesSpawned < enemiesToSpawn)) {
      spawnTimer += dt;
      if (spawnTimer >= spawnInterval) {
        spawnTimer = 0;
        final pts = getEnemySpawnPoints();
        if (pts.isNotEmpty) {
          _spawnOneEnemy(pts[Random().nextInt(pts.length)].clone());
        }
        // arena: always keep buffer of enemies
        if (isArena && enemiesAlive < 8 + (arenaKills ~/ 30)) {
          enemiesToSpawn = enemiesSpawned + 15;
        }
      }
    }

    _checkPortal();

    // secret boss corner (left-top 33s) after boss kill on floors 1 (tentacle) / 2 (cyclops) boss nodes
    if (!secretBossSpawned && isBossLevel && countLivingHostiles() == 0) {
      final inCorner = player.position.x < 140 && player.position.y < 140;
      if (inCorner) {
        cornerStandTimer += dt;
        if (cornerStandTimer >= 33) {
          secretBossSpawned = true;
          final pos = Vector2(mapWidth / 2, mapHeight / 2);
          if (currentFloor == 1 || (currentFloor % 5 == 1 && currentFloor < 6)) {
            world.add(TentacleBoss(position: pos)..priority = 28);
          } else if (currentFloor == 2 || currentFloor == 10 || (currentFloor % 5 == 2)) {
            world.add(CyclopsBoss(position: pos)..priority = 28);
          } else {
            // other floors: still tentacle as rare secret
            world.add(TentacleBoss(position: pos)..priority = 28);
          }
          enemiesAlive++;
          enemiesToSpawn++;
          enemiesSpawned++;
          portalSpawned = false; // kill secret first
          for (final p in world.children.whereType<Portal>().toList()) {
            p.removeFromParent();
          }
          spawnDamageNumber(pos, 0, color: const Color(0xFF9C27B0), label: 'СЕКРЕТ');
        }
      } else {
        cornerStandTimer = 0;
      }
    }

    // near portal → show P button
    nearPortal = false;
    if (portalSpawned) {
      for (final p in world.children.whereType<Portal>()) {
        if (player.position.distanceTo(p.position) < 70) {
          nearPortal = true;
          break;
        }
      }
    }
    if (nearPortal && portalButton == null) {
      portalButton = HudButtonComponent(
        button: CircleComponent(radius: hud.buttonSize * 0.55, paint: Paint()..color = const Color(0xFFE91E63)),
        position: _hudPos(hud.portalBtnX, hud.portalBtnY),
        onPressed: usePortal,
      )..priority = 210;
      camera.viewport.add(portalButton!);
      camera.viewport.add(HudLabel(text: 'P', target: portalButton!)..priority = 211);
    } else if (!nearPortal && portalButton != null) {
      portalButton?.removeFromParent();
      portalButton = null;
    }
  }

  // ── navigation ──
  void goNextLevel() {
    isPaused = true;
    overlays.add('levelComplete');
  }

  void nextLevel() {
    overlays.remove('levelComplete');
    isPaused = false;

    if (isArena) {
      // should not happen via portal; arena has no portal clear win
      return;
    }

    pathIndex++;
    if (pathIndex >= floorPath.length) {
      // floor complete → path select or next floor
      currentFloor++;
      pathIndex = 0;
      if (currentFloor > maxFloorsForDiff) {
        showVictory();
        return;
      }
      // rank perk every 2 wins handled at victory
      generateFloorPath();
      _rollRewards();
      overlays.add('reward');
      isPaused = true;
      return;
    }

    // mid-floor: sometimes path choice
    if (pathIndex < floorPath.length - 1 && Random().nextDouble() < 0.35) {
      pendingPathChoices = [
        floorPath[pathIndex],
        PathNode(
          [PathNodeKind.combat, PathNodeKind.event, PathNodeKind.elite, PathNodeKind.rest][Random().nextInt(4)],
          'Альт.',
        ),
      ];
      overlays.add('pathSelect');
      isPaused = true;
      return;
    }

    _rollRewards();
    overlays.add('reward');
    isPaused = true;
  }

  void choosePathNode(int i) {
    if (i >= 0 && i < pendingPathChoices.length) {
      floorPath[pathIndex] = pendingPathChoices[i];
    }
    overlays.remove('pathSelect');
    pendingPathChoices = [];
    _rollRewards();
    overlays.add('reward');
  }

  void _rollRewards() {
    pendingRewards = [];
    final rnd = Random();
    final options = <RewardOption>[
      RewardOption(RewardKind.skillPoint, 'Очко навыка', '+1 SP'),
      RewardOption(RewardKind.scraps, 'Обломки', '+12 обломков'),
      RewardOption(RewardKind.heal, 'Медикаменты', '+3 HP'),
    ];
    if (rnd.nextDouble() < 0.55) {
      options.add(RewardOption(RewardKind.relic, 'Реликвия', 'Случайная пассивка'));
    }
    options.shuffle();
    pendingRewards = options.take(3).toList();
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
    if (world.children.whereType<Player>().isNotEmpty) {
      player.maxHealth = maxHealth;
      player.health = min(player.health, maxHealth);
    }
  }

  void showVictory() {
    isPlaying = false;
    isPaused = true;
    stopMusic();
    // achievements by difficulty
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
    // rank win
    final ok = activeChallenge == RankChallenge.none ||
        (activeChallenge == RankChallenge.meleeOnlyBoss && challengeBossMeleeOk) ||
        (activeChallenge == RankChallenge.noDash);
    if (ok) {
      inquisitionRank.wins++;
      persistMeta();
      if (inquisitionRank.wins % 2 == 0 && inquisitionRank.chosenPerk == RankPerk.none) {
        overlays.add('rankPerk');
        return;
      }
    }
    overlays.add('victory');
  }

  void chooseRankPerk(RankPerk p) {
    inquisitionRank.chosenPerk = p;
    persistMeta();
    overlays.remove('rankPerk');
    overlays.add('victory');
  }

  void finishAfterVictory() {
    addScoreEntry(completed: true);
    overlays.remove('victory');
    backToMenu();
  }

  void startArena() {
    overlays.remove('victory');
    isArena = true;
    isPlaying = true;
    isPaused = false;
    arenaKills = 0;
    enemiesToSpawn = 999999;
    enemiesSpawned = 0;
    enemiesAlive = 0;
    portalSpawned = false;
    currentFloor = maxFloorsForDiff;
    pathIndex = 0;
    floorPath = [PathNode(PathNodeKind.combat, 'Арена')];
    startMusic();
    _startLevel();
  }

  void showGameOver() {
    isPlaying = false;
    isPaused = true;
    stopMusic();
    addScoreEntry(completed: false, fromArena: isArena);
    overlays.add('gameOver');
  }

  void addScoreEntry({bool completed = false, bool fromArena = false}) {
    highScores.add(HighScoreEntry(
      name: playerName,
      score: score,
      seconds: levelElapsed.round() + currentFloor * 60, // rough playtime marker
      difficulty: difficulty.labelRu,
      playerClass: playerClass.title,
      floor: currentFloor,
      level: currentLevel,
      completed: completed && !fromArena,
      keyRelics: relics.take(2).map((e) => e.title).toList(),
    ));
    highScores.sort((a, b) => b.score.compareTo(a.score));
    if (highScores.length > 30) highScores.removeRange(30, highScores.length);
    persistMeta();
  }

  // ── run start flow ──
  void openNameInput() {
    for (final o in ['mainMenu', 'gameOver', 'victory', 'records', 'achievements']) {
      overlays.remove(o);
    }
    overlays.add('nameInput');
  }

  void confirmName(String name, Difficulty diff) {
    playerName = name.trim().isEmpty ? 'Inquisitor' : name.trim();
    difficulty = diff;
    maxFloors = diff.maxFloors;
    overlays.remove('nameInput');
    overlays.add('challengeSelect');
  }

  void confirmChallenge(RankChallenge ch) {
    activeChallenge = ch;
    challengeBossMeleeOk = true;
    overlays.remove('challengeSelect');
    overlays.add('classSelect');
  }

  void confirmClass(PlayerClass cls) {
    playerClass = cls;
    noteClassPlayed(cls);
    overlays.remove('classSelect');
    startNewRun();
  }

  void startNewRun() {
    isArena = false;
    score = 0;
    scraps = inquisitionRank.startScraps;
    skillPoints = 1 + inquisitionRank.startSpBonus;
    skills = SkillTree();
    loadout = WeaponLoadout();
    mastery = WeaponMastery();
    relics.clear();
    currentFloor = 1;
    pathIndex = 0;
    arenaKills = 0;
    tentacleDefeated = false;
    cyclopsDefeated = false;
    unlockedRifle = false;
    unlockedShotgun = false;
    unlockedAxe = false;
    unlockedHammer = false;
    unlockedStormStaff = false;
    unlockedWarpBeam = false;
    unlockedForceSword = false;
    unlockedDaemonHammer = false;
    unlockedNeedles = false;
    unlockedSniperNeedle = false;
    unlockedPowerKatana = false;
    unlockedExecutioner = false;
    unlockedLaser = false;
    unlockedArtifact = false;
    activeArtifact = ActiveArtifact.fragGrenade;
    unlockedArtifact = true;
    pendingEcho = EchoBossKind.none;
    levelsSinceEvent = 0;
    bolterHeat = 0;
    staffWarpStress = 0;
    warpResetCooldown = 0;
    ironWillUsedThisFloor = false;

    switch (playerClass) {
      case PlayerClass.xenos:
        rangedWeapon = RangedWeapon.bolter;
        meleeWeapon = MeleeWeapon.sword;
        usingMelee = false;
        break;
      case PlayerClass.malleus:
        rangedWeapon = RangedWeapon.staff;
        meleeWeapon = MeleeWeapon.forceBlade;
        usingMelee = false;
        break;
      case PlayerClass.hereticus:
        rangedWeapon = RangedWeapon.daggers;
        meleeWeapon = MeleeWeapon.katana;
        usingMelee = true;
        break;
    }

    generateFloorPath();
    syncLevelFromPath();
    recomputeStats();
    isPlaying = true;
    isPaused = false;
    currentZoom = 0.85;
    camera.viewfinder.zoom = currentZoom;
    startMusic();
    _startLevel();
  }

  // ── save / load / delete ──
  Future<void> saveGame() async {
    if (!isPlaying) return;
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
      'hp': world.children.whereType<Player>().isEmpty ? maxHealth : player.health,
      'rw': rangedWeapon.name,
      'mw': meleeWeapon.name,
      'um': usingMelee,
      'pc': playerClass.name,
      'diff': difficulty.name,
      'name': playerName,
    });
    final now = DateTime.now();
    final dateStr = '${now.day}.${now.month}.${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
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
      health: world.children.whereType<Player>().isEmpty ? maxHealth : player.health,
      ranged: rangedWeapon.name,
      melee: meleeWeapon.name,
      usingMelee: usingMelee,
      payload: payload,
    );
    saves.insert(0, gs);
    if (saves.length > 10) saves.removeLast();
    await persistMeta();
  }

  void loadSave(GameSave s) {
    try {
      final j = jsonDecode(s.payload) as Map<String, dynamic>;
      playerName = s.name;
      playerClass = PlayerClass.values.firstWhere((e) => e.name == s.playerClass, orElse: () => PlayerClass.xenos);
      difficulty = Difficulty.values.firstWhere((e) => e.labelRu == s.difficulty || e.name == (j['diff'] as String?), orElse: () => Difficulty.normal);
      maxFloors = difficulty.maxFloors;
      currentFloor = s.floor;
      currentLevel = s.level;
      pathIndex = (j['pathIndex'] as int?) ?? (currentLevel - 1);
      score = s.score;
      scraps = s.scraps;
      skillPoints = s.skillPoints;
      skills = SkillTree.fromJson(s.skills);
      mastery = WeaponMastery.fromJson(s.mastery);
      loadout = WeaponLoadout.fromJson(s.loadout);
      relics
        ..clear()
        ..addAll(s.relics.map((n) => RelicId.values.firstWhere((e) => e.name == n, orElse: () => RelicId.critCharm)));
      loreRanks
        ..clear()
        ..addAll(s.loreRanks);
      codexUnlocked
        ..clear()
        ..addAll(s.codex.map((n) => CodexId.values.firstWhere((e) => e.name == n, orElse: () => CodexId.shooter)));
      rangedWeapon = RangedWeapon.values.firstWhere((e) => e.name == s.ranged, orElse: () => RangedWeapon.bolter);
      meleeWeapon = MeleeWeapon.values.firstWhere((e) => e.name == s.melee, orElse: () => MeleeWeapon.sword);
      usingMelee = s.usingMelee;
      isArena = false;
      generateFloorPath();
      pathIndex = pathIndex.clamp(0, floorPath.length - 1);
      syncLevelFromPath();
      recomputeStats();
      isPlaying = true;
      isPaused = false;
      overlays.remove('loadSave');
      startMusic();
      _startLevel();
      if (world.children.whereType<Player>().isNotEmpty) {
        player.health = s.health.clamp(1, maxHealth);
      }
    } catch (_) {
      overlays.remove('loadSave');
      overlays.add('mainMenu');
    }
  }

  Future<void> deleteSaveAt(int index) async {
    if (index < 0 || index >= saves.length) return;
    saves.removeAt(index);
    await persistMeta();
  }

  Future<void> deleteAllSaves() async {
    saves.clear();
    await persistMeta();
  }

  // ── menus open/close ──
  void openSettings() {
    isPaused = true;
    overlays.add('settings');
  }

  void closeSettings() {
    overlays.remove('settings');
    // FIX: apply HUD sizes/positions while in combat
    if (isPlaying) {
      rebuildHud();
      isPaused = false;
    }
    persistCustomization();
  }

  void openBackpack() {
    isPaused = true;
    overlays.add('backpack');
  }

  void closeBackpack() {
    overlays.remove('backpack');
    isPaused = false;
  }

  void openLoadSave() {
    overlays.remove('mainMenu');
    overlays.add('loadSave');
  }

  void openCodex() {
    overlays.remove('mainMenu');
    overlays.add('codex');
  }

  void closeCodex() {
    overlays.remove('codex');
    overlays.add('mainMenu');
  }

  void openAchievements() {
    overlays.remove('mainMenu');
    overlays.add('achievements');
  }

  void closeAchievements() {
    overlays.remove('achievements');
    overlays.add('mainMenu');
  }

  void exitMatch() {
    overlays.remove('settings');
    isPlaying = false;
    isPaused = false;
    stopMusic();
    addScoreEntry();
    backToMenu();
  }

  void backToMenu() {
    isPlaying = false;
    isPaused = false;
    stopMusic();
    world.removeAll(world.children.toList());
    camera.viewport.children.toList().forEach((c) {
      if (c is! CameraComponent) c.removeFromParent();
    });
    for (final o in [
      'settings',
      'backpack',
      'reward',
      'shop',
      'skills',
      'levelComplete',
      'victory',
      'gameOver',
      'pathSelect',
      'lorePopup',
      'eventAltar',
      'eventMerchant',
      'rankPerk',
      'challengeSelect',
      'classSelect',
      'nameInput',
      'loadSave',
      'records',
      'codex',
      'achievements',
    ]) {
      overlays.remove(o);
    }
    overlays.add('mainMenu');
  }

  // event handlers
  void resolveAltar({required bool accept}) {
    overlays.remove('eventAltar');
    isPaused = false;
    eventResolved = true;
    if (accept && player.health > 1) {
      player.health -= 1;
      _grantRandomRelic();
    }
    if (countLivingHostiles() == 0 && enemiesToSpawn == 0) _forceSpawnPortal();
  }

  void resolveMerchantBuy(String id) {
    void pay(int cost, void Function() apply) {
      if (scraps < cost) return;
      scraps -= cost;
      apply();
      recomputeStats();
    }

    switch (id) {
      case 'heal':
        pay(10, () => player.health = min(maxHealth, player.health + 2));
        break;
      case 'scraps_sp':
        pay(18, () => skillPoints++);
        break;
      case 'relic':
        pay(25, _grantRandomRelic);
        break;
      case 'gun_rapid':
        pay(14, () => loadout.gunBarrel = GunBarrelMod.rapid);
        break;
      case 'gun_heavy':
        pay(14, () => loadout.gunBarrel = GunBarrelMod.heavy);
        break;
      case 'gun_precision':
        pay(12, () => loadout.gunSight = GunSightMod.precision);
        break;
      case 'gun_wide':
        pay(12, () => loadout.gunSight = GunSightMod.wide);
        break;
      case 'gun_explosive':
        pay(16, () => loadout.gunAmmo = GunAmmoMod.explosive);
        break;
      case 'staff_wide':
        pay(14, () => loadout.staffFocus = StaffFocusMod.wideSphere);
        break;
      case 'staff_focus':
        pay(14, () => loadout.staffFocus = StaffFocusMod.focused);
        break;
      case 'staff_dissipator':
        pay(12, () => loadout.staffFocus = StaffFocusMod.dissipator);
        break;
      case 'blade_serrated':
        pay(12, () => loadout.bladeEdge = BladeEdgeMod.serrated);
        break;
      case 'blade_mono':
        pay(14, () => loadout.bladeEdge = BladeEdgeMod.mono);
        break;
      case 'blade_weighted':
        pay(14, () => loadout.bladeEdge = BladeEdgeMod.weighted);
        break;
    }
  }

  void closeMerchant() {
    overlays.remove('eventMerchant');
    isPaused = false;
    eventResolved = true;
    if (countLivingHostiles() == 0 && enemiesToSpawn == 0) _forceSpawnPortal();
  }
} // ← ЕДИНСТВЕННОЕ закрытие InquisitorGame

// ═══════════════════════════════════════════════════════════════
// HELPER COMPONENTS
// ═══════════════════════════════════════════════════════════════

class RewardOption {
  final RewardKind kind;
  final String title;
  final String subtitle;
  RewardOption(this.kind, this.title, this.subtitle);
  void apply(InquisitorGame g) {
    switch (kind) {
      case RewardKind.skillPoint:
        g.skillPoints++;
        break;
      case RewardKind.scraps:
        g.scraps += 12;
        break;
      case RewardKind.heal:
        if (g.world.children.whereType<Player>().isNotEmpty) {
          g.player.health = min(g.maxHealth, g.player.health + 3);
        }
        break;
      case RewardKind.relic:
        g._grantRandomRelic();
        break;
    }
  }
}

class Floor extends PositionComponent {
  Floor({required Vector2 size}) : super(size: size, priority: 0);
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF3A3A3A));
    final grid = Paint()..color = const Color(0xFF4A4A4A)..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 64) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += 64) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
    }
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  final Color color;
  Wall({required Vector2 position, required Vector2 size, this.color = const Color(0xFF5D4037)})
      : super(position: position, size: size, priority: 2);
  @override
  Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = color);
  }
}

class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({required Vector2 position}) : super(position: position, size: Vector2(48, 48), anchor: Anchor.center, priority: 8);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)), Paint()..color = const Color(0xFF6D4C41));
  }
}

class Portal extends PositionComponent with CollisionCallbacks {
  double t = 0;
  Portal({required Vector2 position}) : super(position: position, size: Vector2(56, 56), anchor: Anchor.center, priority: 9);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
  }
  @override
  void render(Canvas canvas) {
    final pulse = 0.7 + 0.3 * sin(t * 4);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 24 * pulse, Paint()..color = const Color(0xFFE91E63).withOpacity(0.7));
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14, Paint()..color = const Color(0xFFF48FB1));
  }
}

class SpawnPortalMarker extends PositionComponent {
  double life = 0.8;
  SpawnPortalMarker({required Vector2 position}) : super(position: position, size: Vector2(40, 40), anchor: Anchor.center, priority: 7);
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 0.8).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 16, Paint()..color = Color.fromRGBO(255, 152, 0, 0.55 * a));
  }
}

class PlayerSpawnMarker extends PositionComponent {
  double t = 0;
  PlayerSpawnMarker({required Vector2 position}) : super(position: position, size: Vector2(36, 36), anchor: Anchor.center, priority: 6);
  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (t > 2.5) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (1 - t / 2.5).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14, Paint()..color = Color.fromRGBO(156, 39, 176, 0.5 * a));
  }
}

class HudLabel extends PositionComponent {
  final String text;
  final PositionComponent target;
  HudLabel({required this.text, required this.target}) : super(priority: 201);
  @override
  void update(double dt) {
    super.update(dt);
    if (!target.isMounted) {
      removeFromParent();
      return;
    }
    position = target.position.clone();
  }
  @override
  void render(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

class AttackCooldownRing extends PositionComponent {
  final InquisitorGame game;
  final JoystickComponent joystick;
  AttackCooldownRing({required this.game, required this.joystick}) : super(priority: 199);
  @override
  void update(double dt) {
    super.update(dt);
    position = joystick.position.clone();
  }
  @override
  void render(Canvas canvas) {
    final r = game.hud.joystickSize * 0.55;
    if (game.bolterHeat > 0.05 && game.playerClass == PlayerClass.xenos) {
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFFFEB3B), const Color(0xFFFF1744), game.bolterHeat)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), -pi / 2, game.bolterHeat * 2 * pi, false, paint);
    }
    if (game.staffWarpStress > 0.05 && game.playerClass == PlayerClass.malleus) {
      final paint = Paint()
        ..color = const Color(0xFF9C27B0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r + 4), -pi / 2, game.staffWarpStress * 2 * pi, false, paint);
    }
  }
}

mixin SmartMover on PositionComponent {
  double stuckTimer = 0;
  void smartMove(Vector2 target, double speed, double dt, {double radius = 22, bool kite = false, double preferDist = 180}) {
    final game = findGame() as InquisitorGame?;
    if (game == null) return;
    Vector2 desired;
    final dist = position.distanceTo(target);
    if (kite && dist < preferDist) {
      desired = (position - target).normalized();
    } else {
      desired = (target - position).normalized();
    }
    // separation
    for (final e in game.world.children.whereType<Enemy>()) {
      if (identical(e, this)) continue;
      final d = position.distanceTo(e.position);
      if (d > 0 && d < radius * 2.2) {
        desired += (position - e.position).normalized() * 0.6;
      }
    }
    if (desired.length2 > 0.001) desired = desired.normalized();
    final next = position + desired * speed * dt;
    if (_canStand(game, next, radius)) {
      position = next;
      stuckTimer = 0;
    } else {
      // slide axes
      final nx = Vector2(next.x, position.y);
      final ny = Vector2(position.x, next.y);
      if (_canStand(game, nx, radius)) {
        position = nx;
      } else if (_canStand(game, ny, radius)) {
        position = ny;
      } else {
        stuckTimer += dt;
        if (stuckTimer > 0.5) {
          position += Vector2(Random().nextDouble() - 0.5, Random().nextDouble() - 0.5).normalized() * 20;
          stuckTimer = 0;
        }
      }
    }
    position.x = position.x.clamp(80, game.mapWidth - 80);
    position.y = position.y.clamp(80, game.mapHeight - 80);
  }

  bool _canStand(InquisitorGame game, Vector2 p, double radius) {
    for (final w in game.world.children.whereType<Wall>()) {
      if (w.toAbsoluteRect().inflate(radius * 0.6).contains(p.toOffset())) return false;
    }
    for (final o in game.world.children.whereType<Obstacle>()) {
      if (p.distanceTo(o.position) < radius + 22) return false;
    }
    for (final b in game.world.children.whereType<BreakableBarrel>()) {
      if (p.distanceTo(b.position) < radius + 20) return false;
    }
    return true;
  }

  void pushOutOfWalls(double radius) {
    final game = findGame() as InquisitorGame?;
    if (game == null) return;
    for (final w in game.world.children.whereType<Wall>()) {
      final r = w.toAbsoluteRect().inflate(radius * 0.5);
      if (r.contains(position.toOffset())) {
        final cx = r.center.dx, cy = r.center.dy;
        position += (position - Vector2(cx, cy)).normalized() * 8;
      }
    }
  }
}

class BreakableBarrel extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  int hp = 2;
  BreakableBarrel({required Vector2 position}) : super(position: position, size: Vector2(36, 40), anchor: Anchor.center, priority: 8);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 16));
  void hit() {
    hp--;
    if (hp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.scraps += 1 + Random().nextInt(2);
      if (Random().nextDouble() < 0.15) {
        game.world.add(MedkitPickup(position: pos)..priority = 10);
      } else if (Random().nextDouble() < 0.1) {
        game.world.add(ShieldPickup(position: pos)..priority = 10);
      }
    }
  }
  @override
  void render(Canvas canvas) => WHDraw.barrel(canvas, size.x / 2, size.y / 2);
}

class EventAltarProp extends PositionComponent with HasGameReference<InquisitorGame> {
  double t = 0;
  EventAltarProp({required Vector2 position}) : super(position: position, size: Vector2(50, 50), anchor: Anchor.center, priority: 10);
  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
  }
  @override
  void render(Canvas canvas) => WHDraw.altar(canvas, size.x / 2, size.y / 2, t);
}

class EventMerchantProp extends PositionComponent {
  double t = 0;
  EventMerchantProp({required Vector2 position}) : super(position: position, size: Vector2(56, 50), anchor: Anchor.center, priority: 10);
  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
  }
  @override
  void render(Canvas canvas) => WHDraw.merchantStall(canvas, size.x / 2, size.y / 2, t);
}

class MedkitPickup extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  MedkitPickup({required Vector2 position}) : super(position: position, size: Vector2(28, 28), anchor: Anchor.center, priority: 10);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.health = min(game.maxHealth, other.health + 2);
      removeFromParent();
    }
  }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, Paint()..color = const Color(0xFFE53935));
    canvas.drawRect(Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: 12, height: 4), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: 4, height: 12), Paint()..color = Colors.white);
  }
}

class ShieldPickup extends PositionComponent with CollisionCallbacks, HasGameReference<InquisitorGame> {
  ShieldPickup({required Vector2 position}) : super(position: position, size: Vector2(28, 28), anchor: Anchor.center, priority: 10);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      game.shieldTimer = max(game.shieldTimer, 6);
      removeFromParent();
    }
  }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, Paint()..color = const Color(0xFF42A5F5).withOpacity(0.8));
  }
}

class FragGrenade extends PositionComponent with HasGameReference<InquisitorGame> {
  final Vector2 direction;
  double life = 0.7;
  FragGrenade({required Vector2 position, required this.direction})
      : super(position: position.clone(), size: Vector2(16, 16), anchor: Anchor.center, priority: 15);
  @override
  void update(double dt) {
    super.update(dt);
    position += direction.normalized() * 220 * dt;
    life -= dt;
    if (life <= 0) {
      game.world.add(KillExplosion(position: position.clone(), radius: 90, damage: 18 + game.currentFloor * 2, applyBurn: true)..priority = 12);
      removeFromParent();
    }
  }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6, Paint()..color = const Color(0xFF795548));
  }
}

class ServoTurret extends PositionComponent with HasGameReference<InquisitorGame> {
  double life = 8;
  double shootTimer = 0;
  ServoTurret({required Vector2 position}) : super(position: position.clone(), size: Vector2(36, 36), anchor: Anchor.center, priority: 12);
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) {
      removeFromParent();
      return;
    }
    shootTimer -= dt;
    if (shootTimer <= 0) {
      shootTimer = 0.45;
      final t = _nearestHostile();
      if (t != null) {
        final dir = (t - position).normalized();
        game.world.add(Bullet(
          position: position.clone(),
          direction: dir,
          damage: game.scaleDamage(6),
          color: const Color(0xFF90CAF9),
          speed: 480,
          radius: 4,
        )..priority = 13);
      }
    }
  }

  Vector2? _nearestHostile() {
    Vector2? best;
    double bestD = 400;
    void consider(PositionComponent c) {
      final d = position.distanceTo(c.position);
      if (d < bestD) {
        bestD = d;
        best = c.position.clone();
      }
    }
    for (final e in game.world.children.whereType<Enemy>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<MiniBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<Boss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<KnightBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<KingBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<PlagueLordBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<BloodChampionBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<TentacleBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<CyclopsBoss>()) {
      consider(e);
    }
    return best;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14, Paint()..color = const Color(0xFF546E7A));
    canvas.drawRect(Rect.fromCenter(center: Offset(size.x / 2 + 10, size.y / 2), width: 14, height: 5), Paint()..color = const Color(0xFF90CAF9));
  }
}
// ═══════════════════════════════════════════════════════════════
// MENUS
// ═══════════════════════════════════════════════════════════════

class MainMenu extends StatefulWidget {
  final InquisitorGame game;
  const MainMenu(this.game, {super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final symbols = <_MS>[];
  final _rnd = Random();
  static const _chars = '01アイウエオカキクケコABCDEFXYZ';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    for (int i = 0; i < 70; i++) {
      symbols.add(_MS(_rnd.nextDouble(), _rnd.nextDouble(), 0.25 + _rnd.nextDouble() * 1.2, _chars[_rnd.nextInt(_chars.length)], 0.2 + _rnd.nextDouble() * 0.7));
    }
    _controller.addListener(() {
      setState(() {
        for (final s in symbols) {
          s.y += s.speed * 0.013;
          if (s.y > 1.15) {
            s.y = -0.1;
            s.x = _rnd.nextDouble();
            s.char = _chars[_rnd.nextInt(_chars.length)];
            s.opacity = 0.2 + _rnd.nextDouble() * 0.7;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.game.inquisitionRank;
    final ach = widget.game.achievements.unlocked.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MP(symbols))),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'SOUL OF THE\nINQUISITOR',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 32, fontWeight: FontWeight.w900, height: 1.15, shadows: [Shadow(color: Colors.redAccent, blurRadius: 14)]),
                  ),
                  const Text('by Инквизитор Данте', style: TextStyle(color: Color(0xFFB8860B), fontSize: 14)),
                  if (rank.rank > 0) Text('${rank.title} • побед ${rank.wins}', style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 12)),
                  Text('Достижения: $ach / ${AchievementId.values.length}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 20),
                  _btn('НАЧАТЬ ИГРУ', () {
                    widget.game.playClick();
                    widget.game.openNameInput();
                  }),
                  const SizedBox(height: 8),
                  _btn('ЗАГРУЗИТЬ', () {
                    widget.game.playClick();
                    widget.game.openLoadSave();
                  }),
                  const SizedBox(height: 8),
                  _btn('ДОСТИЖЕНИЯ', () {
                    widget.game.playClick();
                    widget.game.openAchievements();
                  }),
                  const SizedBox(height: 8),
                  _btn('КОДЕКС', () {
                    widget.game.playClick();
                    widget.game.openCodex();
                  }),
                  const SizedBox(height: 8),
                  _btn('РЕКОРДЫ', () {
                    widget.game.playClick();
                    widget.game.overlays.remove('mainMenu');
                    widget.game.overlays.add('records');
                  }),
                  const SizedBox(height: 8),
                  _btn('НАСТРОЙКИ', () {
                    widget.game.playClick();
                    widget.game.openSettings();
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap) => SizedBox(
        width: 260,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            side: const BorderSide(color: Color(0xFFB8860B)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: onTap,
          child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
        ),
      );
}

class _MS {
  double x, y, speed, opacity;
  String char;
  _MS(this.x, this.y, this.speed, this.char, this.opacity);
}

class _MP extends CustomPainter {
  final List<_MS> symbols;
  _MP(this.symbols);
  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final s in symbols) {
      tp.text = TextSpan(text: s.char, style: TextStyle(color: Color.fromRGBO(0, 255, 70, s.opacity), fontSize: 14 + s.speed * 4, fontFamily: 'monospace'));
      tp.layout();
      tp.paint(canvas, Offset(s.x * size.width, s.y * size.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AchievementsMenu extends StatelessWidget {
  final InquisitorGame game;
  const AchievementsMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    final unlocked = game.achievements.unlocked;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('ДОСТИЖЕНИЯ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Text('${unlocked.length} / ${AchievementId.values.length}', style: const TextStyle(color: Colors.white54)),
            Expanded(
              child: ListView.builder(
                itemCount: AchievementId.values.length,
                itemBuilder: (_, i) {
                  final id = AchievementId.values[i];
                  final ok = unlocked.contains(id.name);
                  return Card(
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Icon(ok ? Icons.emoji_events : Icons.lock, color: ok ? const Color(0xFFFFD700) : Colors.white24),
                      title: Text(ok ? id.title : '???', style: TextStyle(color: ok ? const Color(0xFFFFD700) : Colors.white38, fontWeight: FontWeight.bold)),
                      subtitle: Text(ok ? id.desc : 'Скрыто', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                game.playClick();
                game.closeAchievements();
              },
              child: const Text('НАЗАД'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadSaveMenu extends StatefulWidget {
  final InquisitorGame game;
  const LoadSaveMenu(this.game, {super.key});
  @override
  State<LoadSaveMenu> createState() => _LoadSaveMenuState();
}

class _LoadSaveMenuState extends State<LoadSaveMenu> {
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('ЗАГРУЗИТЬ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold))),
            Expanded(
              child: g.saves.isEmpty
                  ? const Center(child: Text('Нет сохранений', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: g.saves.length,
                      itemBuilder: (_, i) {
                        final s = g.saves[i];
                        return Card(
                          color: const Color(0xFF1A1A1A),
                          child: ListTile(
                            title: Text(s.name, style: const TextStyle(color: Color(0xFFFFD700))),
                            subtitle: Text('${s.playerClass} • F${s.floor}/L${s.level} • ${s.difficulty}\n${s.dateStr}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            isThreeLine: true,
                            onTap: () {
                              g.playClick();
                              g.loadSave(s);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                g.playClick();
                                await g.deleteSaveAt(i);
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (g.saves.isNotEmpty)
              TextButton(
                onPressed: () async {
                  g.playClick();
                  await g.deleteAllSaves();
                  setState(() {});
                },
                child: const Text('УДАЛИТЬ ВСЕ СОХРАНЕНИЯ', style: TextStyle(color: Colors.redAccent)),
              ),
            ElevatedButton(
              onPressed: () {
                g.overlays.remove('loadSave');
                g.overlays.add('mainMenu');
              },
              child: const Text('НАЗАД'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordsMenu extends StatelessWidget {
  final InquisitorGame game;
  const RecordsMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Text('РЕКОРДЫ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold)),
            Expanded(
              child: game.highScores.isEmpty
                  ? const Center(child: Text('Пусто', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: game.highScores.length,
                      itemBuilder: (_, i) {
                        final e = game.highScores[i];
                        return ListTile(
                          title: Text('${i + 1}. ${e.name} • ${e.playerClass}', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            '${e.progressStr}${e.relicsStr.isNotEmpty ? "\n${e.relicsStr}" : ""}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          isThreeLine: e.relicsStr.isNotEmpty,
                          trailing: Text('${e.score}\n${e.timeStr}', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('records');
                game.overlays.add('mainMenu');
              },
              child: const Text('НАЗАД'),
            ),
          ],
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
  String? _saveMsg;
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final c = g.custom;
    final h = g.hud;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('НАСТРОЙКИ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('РАЗМЕРЫ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 14)),
            Text('Джойстик ${h.joystickSize.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(
              value: h.joystickSize,
              min: 55,
              max: 130,
              activeColor: const Color(0xFFFFD700),
              onChanged: (v) => setState(() => h.joystickSize = v),
            ),
            Text('Кнопки ${h.buttonSize.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(
              value: h.buttonSize,
              min: 28,
              max: 70,
              activeColor: const Color(0xFFFFD700),
              onChanged: (v) => setState(() => h.buttonSize = v),
            ),
            const Text('ПОЗИЦИИ (0–1 от краёв)', style: TextStyle(color: Color(0xFFFFD700), fontSize: 14)),
            _xy('Движение M', h.moveX, h.moveY, (x, y) => setState(() {
                  h.moveX = x;
                  h.moveY = y;
                })),
            _xy('Атака F', h.atkX, h.atkY, (x, y) => setState(() {
                  h.atkX = x;
                  h.atkY = y;
                })),
            _xy('Настройки S', h.settingsX, h.settingsY, (x, y) => setState(() {
                  h.settingsX = x;
                  h.settingsY = y;
                })),
            _xy('Рюкзак B', h.backpackX, h.backpackY, (x, y) => setState(() {
                  h.backpackX = x;
                  h.backpackY = y;
                })),
            _xy('Рывок U', h.dashX, h.dashY, (x, y) => setState(() {
                  h.dashX = x;
                  h.dashY = y;
                })),
            TextButton(
              onPressed: () => setState(() => h.reset()),
              child: const Text('СБРОС ПОЗИЦИЙ', style: TextStyle(color: Colors.white54)),
            ),
            SwitchListTile(
              title: const Text('Звуки', style: TextStyle(color: Colors.white)),
              value: g.soundEnabled,
              activeColor: const Color(0xFFFFD700),
              onChanged: (v) => setState(() => g.soundEnabled = v),
            ),
            SwitchListTile(
              title: const Text('Музыка', style: TextStyle(color: Colors.white)),
              value: g.musicEnabled,
              activeColor: const Color(0xFFFFD700),
              onChanged: (v) {
                setState(() {
                  g.musicEnabled = v;
                  g.applyMusicSetting();
                });
              },
            ),
            Slider(
              value: g.musicVolume,
              min: 0,
              max: 1,
              activeColor: const Color(0xFFFFD700),
              onChanged: g.musicEnabled
                  ? (v) {
                      setState(() => g.musicVolume = v);
                      try {
                        FlameAudio.bgm.play('bgm.mp3', volume: v);
                      } catch (_) {}
                    }
                  : null,
            ),
            const Text('ЦВЕТА', style: TextStyle(color: Color(0xFFFFD700))),
            Slider(value: c.armorHue.toDouble(), min: 0, max: 360, activeColor: c.armorColor(0.4), onChanged: (v) => setState(() => c.armorHue = v.round())),
            Slider(value: c.capeHue.toDouble(), min: 0, max: 360, activeColor: c.capeColor(0.4), onChanged: (v) => setState(() => c.capeHue = v.round())),
            Slider(value: c.weaponHue.toDouble(), min: 0, max: 360, activeColor: c.weaponColor(0.45), onChanged: (v) => setState(() => c.weaponHue = v.round())),
            if (g.isPlaying) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: () async {
                  await g.saveGame();
                  setState(() => _saveMsg = 'Сохранено');
                },
                child: const Text('СОХРАНИТЬ ИГРУ'),
              ),
              if (_saveMsg != null) Text(_saveMsg!, style: const TextStyle(color: Colors.greenAccent)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                onPressed: () {
                  g.playClick();
                  g.exitMatch();
                },
                child: const Text('ВЫХОД ИЗ МАТЧА'),
              ),
            ],
            ElevatedButton(
              onPressed: () {
                g.playClick();
                if (g.isPlaying) {
                  g.closeSettings(); // rebuildHud inside
                } else {
                  g.persistCustomization();
                  g.overlays.remove('settings');
                  g.overlays.add('mainMenu');
                }
              },
              child: Text(g.isPlaying ? 'В БОЙ (применить HUD)' : 'НАЗАД'),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const Text('1-5 left top 33s', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace')),
            const Text('2-5 left top 33s', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _xy(String label, double x, double y, void Function(double, double) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label  X=${x.toStringAsFixed(2)}  Y=${y.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Row(
            children: [
              const Text('X', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Expanded(
                child: Slider(value: x, min: 0.05, max: 0.95, activeColor: const Color(0xFFB8860B), onChanged: (v) => onChange(v, y)),
              ),
              const Text('Y', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Expanded(
                child: Slider(value: y, min: 0.05, max: 0.95, activeColor: const Color(0xFFB8860B), onChanged: (v) => onChange(x, v)),
              ),
            ],
          ),
        ],
      ),
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
  final c = TextEditingController();
  Difficulty diff = Difficulty.normal;
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ИМЯ ИНКВИЗИТОРА', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              TextField(controller: c, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Имя...', hintStyle: TextStyle(color: Colors.white38))),
              const SizedBox(height: 16),
              Row(
                children: [
                  _d(Difficulty.easy, Colors.green, '5 эт.'),
                  const SizedBox(width: 8),
                  _d(Difficulty.normal, const Color(0xFFB8860B), '7 эт.'),
                  const SizedBox(width: 8),
                  _d(Difficulty.hard, Colors.redAccent, '10 эт.'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => widget.game.confirmName(c.text, diff), child: const Text('ДАЛЕЕ — ИСПЫТАНИЕ')),
              TextButton(
                onPressed: () {
                  widget.game.overlays.remove('nameInput');
                  widget.game.overlays.add('mainMenu');
                },
                child: const Text('НАЗАД', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _d(Difficulty d, Color color, String sub) {
    final sel = diff == d;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: sel ? color : const Color(0xFF1A1A1A), side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: 10)),
        onPressed: () => setState(() => diff = d),
        child: Column(
          children: [
            Text(d.labelRu, style: TextStyle(color: sel ? Colors.white : color, fontSize: 13)),
            Text(sub, style: TextStyle(color: sel ? Colors.white70 : color.withOpacity(0.7), fontSize: 10)),
          ],
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ИСПЫТАНИЕ РАНГА', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              Text('${game.difficulty.labelRu} — ${game.difficulty.maxFloors} этажей', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: RankChallenge.values.map((ch) {
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      child: ListTile(
                        title: Text(ch.title, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        subtitle: Text(ch.desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        onTap: () {
                          game.playClick();
                          game.confirmChallenge(ch);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ВЫБОР ОРДО', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
              Text(game.playerName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              Expanded(
                child: ListView(
                  children: [
                    _card(PlayerClass.xenos, const Color(0xFFB71C1C), 'HP 6 • Болтер'),
                    _card(PlayerClass.malleus, const Color(0xFF1A237E), 'HP 5 • Посох Ψ'),
                    _card(PlayerClass.hereticus, const Color(0xFF4A148C), 'HP 5 • Рывок U'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(PlayerClass cls, Color accent, String stats) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(cls.title, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text('${cls.subtitle}\n$stats', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
        onTap: () {
          game.playClick();
          game.confirmClass(cls);
        },
      ),
    );
  }
}

class RankPerkMenu extends StatelessWidget {
  final InquisitorGame game;
  const RankPerkMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.94),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ПЕРК РАНГА', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              Card(
                color: const Color(0xFF1A1A1A),
                child: ListTile(
                  title: const Text('+1 стартовое SP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    game.playClick();
                    game.chooseRankPerk(RankPerk.startSp);
                  },
                ),
              ),
              Card(
                color: const Color(0xFF1A1A1A),
                child: ListTile(
                  title: const Text('+5% обломков', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    game.playClick();
                    game.chooseRankPerk(RankPerk.scrapBonus);
                  },
                ),
              ),
              TextButton(onPressed: () => game.chooseRankPerk(RankPerk.none), child: const Text('ПРОПУСТИТЬ', style: TextStyle(color: Colors.white38))),
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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.94),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ВЫБОР ПУТИ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              ...List.generate(game.pendingPathChoices.length, (i) {
                final n = game.pendingPathChoices[i];
                return Card(
                  color: const Color(0xFF1A1A1A),
                  child: ListTile(
                    title: Text(n.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onTap: () {
                      game.playClick();
                      game.choosePathNode(i);
                    },
                  ),
                );
              }),
            ],
          ),
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
    final id = game.pendingLoreId;
    if (id == null) return const SizedBox.shrink();
    final rank = game.loreRankOf(id);
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('КОДЕКС', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
              Text(id.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('Знание: $rank / 2', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              Expanded(child: SingleChildScrollView(child: Text(id.lore, style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 14)))),
              Text(id.knowledgeBonus, textAlign: TextAlign.center, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: () => game.acceptLore(id),
                child: Text(rank == 0 ? 'ПРИНЯТЬ ЗНАНИЕ' : 'УГЛУБИТЬ (1 SP)'),
              ),
              TextButton(onPressed: game.skipLore, child: const Text('ПОЗЖЕ', style: TextStyle(color: Colors.white54))),
            ],
          ),
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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('АЛТАРЬ КРОВИ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('Пожертвуй 1 HP — получи реликвию.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                onPressed: game.player.health > 1 ? () => game.resolveAltar(accept: true) : null,
                child: const Text('ПОЖЕРТВОВАТЬ'),
              ),
              TextButton(onPressed: () => game.resolveAltar(accept: false), child: const Text('ОТКАЗАТЬСЯ', style: TextStyle(color: Colors.white54))),
            ],
          ),
        ),
      ),
    );
  }
}

class EventMerchantMenu extends StatefulWidget {
  final InquisitorGame game;
  const EventMerchantMenu(this.game, {super.key});
  @override
  State<EventMerchantMenu> createState() => _EventMerchantMenuState();
}

class _EventMerchantMenuState extends State<EventMerchantMenu> {
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ТОРГОВЕЦ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Обломки: ${g.scraps}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              Expanded(
                child: ListView(
                  children: [
                    _item('+2 HP', 10, () {
                      g.resolveMerchantBuy('heal');
                      setState(() {});
                    }),
                    _item('+1 SP', 18, () {
                      g.resolveMerchantBuy('scraps_sp');
                      setState(() {});
                    }),
                    _item('Реликвия', 25, () {
                      g.resolveMerchantBuy('relic');
                      setState(() {});
                    }),
                    if (g.playerClass == PlayerClass.xenos) ...[
                      _item('Ствол: очередь', 14, () {
                        g.resolveMerchantBuy('gun_rapid');
                        setState(() {});
                      }),
                      _item('Ствол: тяжёлый', 14, () {
                        g.resolveMerchantBuy('gun_heavy');
                        setState(() {});
                      }),
                      _item('Прицел: точность', 12, () {
                        g.resolveMerchantBuy('gun_precision');
                        setState(() {});
                      }),
                      _item('Боезапас: взрывной', 16, () {
                        g.resolveMerchantBuy('gun_explosive');
                        setState(() {});
                      }),
                    ],
                    if (g.playerClass == PlayerClass.malleus) ...[
                      _item('Сфера: +радиус', 14, () {
                        g.resolveMerchantBuy('staff_wide');
                        setState(() {});
                      }),
                      _item('Фокус: +урон', 14, () {
                        g.resolveMerchantBuy('staff_focus');
                        setState(() {});
                      }),
                      _item('Диссипатор Ψ', 12, () {
                        g.resolveMerchantBuy('staff_dissipator');
                        setState(() {});
                      }),
                    ],
                    if (g.playerClass == PlayerClass.hereticus) ...[
                      _item('Зазубрины', 12, () {
                        g.resolveMerchantBuy('blade_serrated');
                        setState(() {});
                      }),
                      _item('Мономолекула', 14, () {
                        g.resolveMerchantBuy('blade_mono');
                        setState(() {});
                      }),
                    ],
                  ],
                ),
              ),
              ElevatedButton(onPressed: g.closeMerchant, child: const Text('УЙТИ')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String title, int cost, VoidCallback buy) {
    final can = widget.game.scraps >= cost;
    return Card(
      color: const Color(0xFF1A1A1A),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        trailing: Text('$cost', style: TextStyle(color: can ? const Color(0xFFFFD700) : Colors.white24)),
        onTap: can
            ? () {
                widget.game.playClick();
                buy();
              }
            : null,
      ),
    );
  }
}

class RewardMenu extends StatelessWidget {
  final InquisitorGame game;
  const RewardMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.94),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('НАГРАДА', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              ...game.pendingRewards.map(
                (o) => Card(
                  color: const Color(0xFF1A1A1A),
                  child: ListTile(
                    title: Text(o.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(o.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () {
                      game.playClick();
                      o.apply(game);
                      game.finishRewardThenShop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopMenu extends StatefulWidget {
  final InquisitorGame game;
  const ShopMenu(this.game, {super.key});
  @override
  State<ShopMenu> createState() => _ShopMenuState();
}

class _ShopMenuState extends State<ShopMenu> {
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.94),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('МАГАЗИН', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Обломки: ${g.scraps}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              _item('+2 HP', 8, () {
                if (g.scraps < 8) return;
                g.scraps -= 8;
                g.player.health = min(g.maxHealth, g.player.health + 2);
                setState(() {});
              }),
              _item('+1 SP', 15, () {
                if (g.scraps < 15) return;
                g.scraps -= 15;
                g.skillPoints++;
                setState(() {});
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  g.playClick();
                  g.finishShopThenSkills();
                },
                child: const Text('ДАЛЬШЕ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String title, int cost, VoidCallback buy) {
    final can = widget.game.scraps >= cost;
    return Card(
      color: const Color(0xFF1A1A1A),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text('$cost', style: TextStyle(color: can ? const Color(0xFFFFD700) : Colors.white24)),
        onTap: can
            ? () {
                widget.game.playClick();
                buy();
              }
            : null,
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
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final s = g.skills;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.94),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('НАВЫКИ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
              Text('SP: ${g.skillPoints}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              Expanded(
                child: ListView(
                  children: [
                    _row('HP', s.hp, () => setState(() => g.spendSkill('hp'))),
                    _row('Скорость', s.speed, () => setState(() => g.spendSkill('speed'))),
                    _row('Скор. атаки', s.attackSpeed, () => setState(() => g.spendSkill('attackSpeed'))),
                    _row('Защита', s.defense, () => setState(() => g.spendSkill('defense'))),
                    _row('Урон', s.damage, () => setState(() => g.spendSkill('damage'))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  g.playClick();
                  g.finishSkillsAndContinue();
                },
                child: const Text('ПРОДОЛЖИТЬ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String t, int rank, VoidCallback onAdd) {
    final can = widget.game.skillPoints > 0;
    return Card(
      color: const Color(0xFF1A1A1A),
      child: ListTile(
        title: Text(t, style: const TextStyle(color: Colors.white)),
        subtitle: Text('ранг $rank', style: const TextStyle(color: Colors.white54)),
        trailing: ElevatedButton(
          onPressed: can
              ? () {
                  widget.game.playClick();
                  onAdd();
                }
              : null,
          child: const Text('+1'),
        ),
      ),
    );
  }
}

class BackpackMenu extends StatefulWidget {
  final InquisitorGame game;
  const BackpackMenu(this.game, {super.key});
  @override
  State<BackpackMenu> createState() => _BackpackMenuState();
}

class _BackpackMenuState extends State<BackpackMenu> {
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text('РЮКЗАК', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
              Text('${g.playerName} • ${g.playerClass.title}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              if (g.relics.isNotEmpty) ...[
                const Text('Реликвии', style: TextStyle(color: Color(0xFFFFD700))),
                ...g.relics.map((r) => Text('• ${r.title}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
              const SizedBox(height: 12),
              ElevatedButton(onPressed: g.closeBackpack, child: const Text('ЗАКРЫТЬ')),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('КОДЕКС', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView.builder(
                itemCount: CodexId.values.length,
                itemBuilder: (_, i) {
                  final id = CodexId.values[i];
                  final open = game.codexUnlocked.contains(id);
                  return Card(
                    color: const Color(0xFF1A1A1A),
                    child: ExpansionTile(
                      title: Text(open ? id.title : '???', style: TextStyle(color: open ? const Color(0xFFFFD700) : Colors.white38)),
                      children: open
                          ? [Padding(padding: const EdgeInsets.all(12), child: Text(id.lore, style: const TextStyle(color: Colors.white70, fontSize: 13)))]
                          : const [Padding(padding: EdgeInsets.all(12), child: Text('Убейте цель.', style: TextStyle(color: Colors.white38)))],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(onPressed: game.closeCodex, child: const Text('НАЗАД')),
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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('УЗЕЛ ПРОЙДЕН', style: TextStyle(color: Colors.greenAccent, fontSize: 26, fontWeight: FontWeight.bold)),
            Text('Этаж ${game.currentFloor}/${game.maxFloors} • Ур.${game.currentLevel}', style: const TextStyle(color: Colors.white70)),
            ElevatedButton(onPressed: game.nextLevel, child: const Text('ДАЛЬШЕ')),
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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.93),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ИСПЫТАНИЕ ПРОЙДЕНО', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            Text('${game.playerName} • ${game.difficulty.labelRu}', style: const TextStyle(color: Colors.white)),
            ElevatedButton(
              onPressed: () {
                game.playClick();
                game.finishAfterVictory();
              },
              child: const Text('ЗАКОНЧИТЬ'),
            ),
            ElevatedButton(
              onPressed: () {
                game.playClick();
                game.startArena();
              },
              child: Text('АРЕНА (${game.difficulty.labelRu})'),
            ),
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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ИНКВИЗИТОР ПАЛ', style: TextStyle(color: Colors.redAccent, fontSize: 26, fontWeight: FontWeight.bold)),
            Text('${game.playerName}: ${game.score}', style: const TextStyle(color: Colors.white)),
            if (game.isArena) Text('Арена: ${game.arenaKills} убийств', style: const TextStyle(color: Colors.white54)),
            ElevatedButton(onPressed: game.openNameInput, child: const Text('СНОВА')),
            ElevatedButton(onPressed: game.backToMenu, child: const Text('МЕНЮ')),
          ],
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════
// PLAYER + COMBAT
// ═══════════════════════════════════════════════════════════════

class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent moveJoystick;
  late int health;
  late int maxHealth;
  double attackTimer = 0;
  double hurtFlash = 0;
  Vector2 aimDir = Vector2(0, -1);
  final List<StatusEffect> statuses = [];

  Player(this.moveJoystick) : super(size: Vector2(76, 86), anchor: Anchor.center, priority: 20);

  @override
  Future<void> onLoad() async {
    maxHealth = game.maxHealth;
    health = maxHealth;
    position = game.playerSpawnPos.clone();
    add(CircleHitbox(radius: 26));
  }

  double get effectiveSpeed {
    var s = game.playerSpeed;
    if (game.dashActive > 0) s *= 1.32;
    if (game._hasteTimer > 0) s *= game.synergyBloodRush ? 1.18 : 1.12;
    if (statuses.any((e) => e.type == StatusType.slow || e.type == StatusType.plague)) s *= 0.65;
    return s;
  }

  void applyStatus(StatusType type, double duration, {int tickDamage = 1}) {
    final existing = statuses.where((e) => e.type == type).toList();
    if (existing.isNotEmpty) {
      existing.first.remaining = max(existing.first.remaining, duration);
    } else {
      statuses.add(StatusEffect(type, duration, tickDamage: tickDamage));
    }
  }

  void _tickStatuses(double dt) {
    for (final e in statuses.toList()) {
      e.remaining -= dt;
      e.tickAcc += dt;
      if (e.tickAcc >= e.tickEvery) {
        e.tickAcc = 0;
        if (e.tickDamage > 0 &&
            (e.type == StatusType.burn || e.type == StatusType.bleed || e.type == StatusType.corruption || e.type == StatusType.plague)) {
          health = max(0, health - e.tickDamage);
          hurtFlash = 0.12;
          if (health <= 0) _tryDeath();
        }
      }
      if (e.remaining <= 0) statuses.remove(e);
    }
  }

  void _tryDeath() {
    if (game.hasIronWill && !game.ironWillUsedThisFloor) {
      game.ironWillUsedThisFloor = true;
      health = 1;
      game.grantInvuln(1.2);
      game.spawnDamageNumber(position, 0, color: const Color(0xFFFFD700), label: 'ЖЕЛЕЗНАЯ ВОЛЯ');
      game.triggerShake(power: 8, time: 0.2);
      game.unlockAchievement(AchievementId.ironWillProc);
      return;
    }
    game.showGameOver();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    _tickStatuses(dt);

    if (moveJoystick.relativeDelta.length2 > 0.01) {
      final next = position + moveJoystick.relativeDelta.normalized() * effectiveSpeed * dt;
      if (_canMoveTo(next)) position = next;
      position.x = position.x.clamp(70, game.mapWidth - 70);
      position.y = position.y.clamp(70, game.mapHeight - 70);
    }

    final atk = game.attackJoystick.relativeDelta;
    if (atk.length2 > 0.02) {
      aimDir = atk.normalized();
      attackTimer -= dt;
      if (attackTimer <= 0) {
        _attack();
        attackTimer = _interval();
      }
    } else {
      attackTimer = max(0, attackTimer - dt * 0.5);
    }
  }

  double _interval() {
    if (game.usingMelee) {
      final base = (game.meleeWeapon == MeleeWeapon.hammer || game.meleeWeapon == MeleeWeapon.daemonHammer) ? 0.78 : 0.42;
      final weighted = game.loadout.bladeEdge == BladeEdgeMod.weighted ? 1.08 : 1.0;
      return base * weighted * game.attackSpeedMult;
    }
    final base = switch (game.rangedWeapon) {
      RangedWeapon.bolter => 0.28 + (game.playerClass == PlayerClass.xenos ? game.bolterHeat * 0.35 : 0),
      RangedWeapon.rifle => 0.55,
      RangedWeapon.shotgun => 0.72,
      RangedWeapon.staff => 0.48 + game.staffWarpStress * 0.25,
      RangedWeapon.stormStaff => 0.55 + game.staffWarpStress * 0.3,
      RangedWeapon.warpBeam => 0.70,
      RangedWeapon.daggers => 0.22,
      RangedWeapon.needles => 0.32,
      RangedWeapon.sniperNeedle => 0.85,
    };
    return base * game.attackSpeedMult;
  }

  bool _canMoveTo(Vector2 next) {
    for (final w in game.world.children.whereType<Wall>()) {
      if (w.toAbsoluteRect().inflate(20).contains(next.toOffset())) return false;
    }
    for (final o in game.world.children.whereType<Obstacle>()) {
      if (next.distanceTo(o.position) < 40) return false;
    }
    for (final b in game.world.children.whereType<BreakableBarrel>()) {
      if (next.distanceTo(b.position) < 36) return false;
    }
    return true;
  }

  void _attack() {
    final dir = aimDir.length2 < 0.01 ? Vector2(0, -1) : aimDir;
    if (game.usingMelee) {
      game.playMelee();
      final (reach, arc, dmg) = _meleeParams();
      game.world.add(MeleeAttack(
        position: position + dir * (reach * 0.4),
        direction: dir,
        damage: game.scaleDamage(dmg),
        radius: reach,
        arc: arc,
        weapon: game.meleeWeapon,
      )..priority = 15);
    } else {
      if (game.playerClass == PlayerClass.xenos &&
          (game.rangedWeapon == RangedWeapon.bolter || game.rangedWeapon == RangedWeapon.rifle)) {
        final heatGain = game.hasAmmoSavant ? 0.055 : 0.08;
        game.bolterHeat = min(1.0, game.bolterHeat + heatGain);
        if (game.bolterHeat >= 0.95) {
          attackTimer = 0.8;
          game.spawnDamageNumber(position, 0, color: const Color(0xFFFF6D00), label: 'ПЕРЕГРЕВ');
          return;
        }
      }
      if (game.playerClass == PlayerClass.malleus &&
          (game.rangedWeapon == RangedWeapon.staff ||
              game.rangedWeapon == RangedWeapon.stormStaff ||
              game.rangedWeapon == RangedWeapon.warpBeam)) {
        var stressGain = 0.10;
        if (game.hasWarpAnchor) stressGain *= 0.7;
        if (game.loadout.staffFocus == StaffFocusMod.dissipator) stressGain *= 0.6;
        game.staffWarpStress = min(1.0, game.staffWarpStress + stressGain);
        if (game.staffWarpStress >= 0.85) {
          takeDamage(1);
          applyStatus(StatusType.corruption, 1.5, tickDamage: 1);
          game.spawnDamageNumber(position, 1, color: const Color(0xFF9C27B0), label: 'ВАРП');
        }
      }
      game.playShoot();
      _ranged(dir);
    }
  }

  (double, double, int) _meleeParams() {
    switch (game.meleeWeapon) {
      case MeleeWeapon.sword:
        return (78.0, 1.2, game.swordDamage);
      case MeleeWeapon.axe:
        return (100.0, 2.6, game.axeDamage);
      case MeleeWeapon.hammer:
        return (115.0, 2.0, game.hammerDamage);
      case MeleeWeapon.forceBlade:
        return (115.0, 1.5, game.forceDamage);
      case MeleeWeapon.forceSword:
        return (130.0, 1.7, game.forceSwordDamage);
      case MeleeWeapon.daemonHammer:
        return (140.0, 2.2, game.daemonDamage);
      case MeleeWeapon.katana:
        return (95.0, 1.4, game.katanaDamage);
      case MeleeWeapon.powerKatana:
        return (105.0, 1.5, game.powerKatanaDamage);
      case MeleeWeapon.executioner:
        return (120.0, 1.8, game.execDamage);
    }
  }

  void _ranged(Vector2 dir) {
    final origin = position + dir * 32;
    switch (game.rangedWeapon) {
      case RangedWeapon.bolter:
        final extra = game.mastery.bolterExtraShots(1, ammoSavant: game.hasAmmoSavant, xenosSynergy: game.synergyXenosMastery);
        for (int i = 0; i < extra; i++) {
          final spread = extra > 1 ? (i - (extra - 1) / 2) * 0.08 : 0.0;
          final a = atan2(dir.y, dir.x) + spread;
          _bullet(origin, Vector2(cos(a), sin(a)), game.bolterDamage, const Color(0xFFFF6D00), 520, 5);
        }
        if (game.loadout.gunBarrel == GunBarrelMod.rapid) {
          Future.delayed(const Duration(milliseconds: 70), () {
            if (isMounted) _bullet(origin, dir, game.bolterDamage, const Color(0xFFFF6D00), 520, 5);
          });
        }
        break;
      case RangedWeapon.rifle:
        _bullet(origin, dir, game.rifleDamage, const Color(0xFF00E5FF), 680, 4);
        break;
      case RangedWeapon.shotgun:
        final n = game.loadout.gunSight == GunSightMod.wide ? 5 : 3;
        final spread = game.loadout.gunSight == GunSightMod.wide ? 0.32 : 0.22;
        for (int i = 0; i < n; i++) {
          final a = atan2(dir.y, dir.x) + (i - (n - 1) / 2) * spread;
          _bullet(origin, Vector2(cos(a), sin(a)), game.shotgunDamage, const Color(0xFFFFAB40), 480, 5);
        }
        break;
      case RangedWeapon.staff:
        final rad = 160.0 * game.staffRadiusMult();
        game.world.add(PsyWave(position: origin.clone(), direction: dir, damage: game.scaleDamage(game.staffDamage), maxRadius: rad)..priority = 13);
        break;
      case RangedWeapon.stormStaff:
        final rad = 140.0 * game.staffRadiusMult();
        for (final o in [-0.35, 0.0, 0.35]) {
          final a = atan2(dir.y, dir.x) + o;
          game.world.add(PsyWave(
            position: origin.clone(),
            direction: Vector2(cos(a), sin(a)),
            damage: game.scaleDamage((game.stormDamage * 0.7).round()),
            maxRadius: rad,
          )..priority = 13);
        }
        break;
      case RangedWeapon.warpBeam:
        _bullet(origin, dir, game.warpDamage, const Color(0xFFEA80FC), 720, 7, pierce: true);
        break;
      case RangedWeapon.daggers:
        for (final o in [-0.18, 0.18]) {
          final a = atan2(dir.y, dir.x) + o;
          _bullet(origin, Vector2(cos(a), sin(a)), game.daggerDamage, const Color(0xFFE0E0E0), 560, 4);
        }
        break;
      case RangedWeapon.needles:
        for (int i = 0; i < 3; i++) {
          final a = atan2(dir.y, dir.x) + (i - 1) * 0.12;
          _bullet(origin, Vector2(cos(a), sin(a)), game.needleDamage, const Color(0xFFCE93D8), 600, 3);
        }
        break;
      case RangedWeapon.sniperNeedle:
        _bullet(origin, dir, game.sniperNeedleDamage, const Color(0xFFE040FB), 800, 3, pierce: true);
        break;
    }
  }

  void _bullet(Vector2 origin, Vector2 dir, int dmg, Color color, double speed, double radius, {bool pierce = false}) {
    final exp = game.loadout.gunAmmo == GunAmmoMod.explosive;
    final ric = game.loadout.gunAmmo == GunAmmoMod.ricochet;
    final prc = pierce || game.loadout.gunAmmo == GunAmmoMod.pierce;
    game.world.add(Bullet(
      position: origin.clone(),
      direction: dir,
      damage: game.scaleDamage(dmg),
      color: color,
      speed: speed,
      radius: radius,
      pierce: prc,
      ricochet: ric,
      explosive: exp,
    )..priority = 13);
  }

  void takeDamage(int amount) {
    if (game.invulnTimer > 0 || game.dashActive > 0) return;
    if (game.shieldTimer > 0) {
      game.shieldTimer = 0;
      return;
    }
    if (game.holyAuraTimer > 0) amount = max(1, (amount * 0.7).round());
    if (game.defenseChance > 0 && Random().nextDouble() < game.defenseChance) {
      game.spawnDamageNumber(position, 0, color: const Color(0xFF90CAF9), label: 'BLOCK');
      return;
    }
    health = max(0, health - amount);
    hurtFlash = 0.15;
    game.triggerShake(power: 5, time: 0.12);
    game.spawnDamageNumber(position, amount, color: const Color(0xFFFF5252));
    if (health <= 0) _tryDeath();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 8;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final ang = atan2(aimDir.y, aimDir.x);
    WHDraw.inquisitor(canvas, cx: cx, cy: cy, s: 1.28, flash: hurtFlash / 0.15, custom: game.custom, cls: game.playerClass);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);
    final wc = game.custom.weaponColor(0.5);
    if (game.usingMelee) {
      switch (game.meleeWeapon) {
        case MeleeWeapon.sword:
          WHDraw.powerSword(canvas, 0, 0, 1.05, accent: wc);
          break;
        case MeleeWeapon.axe:
          WHDraw.chainAxe(canvas, 0, 0, 1.05, accent: wc);
          break;
        case MeleeWeapon.hammer:
          WHDraw.thunderHammer(canvas, 0, 0, 1.0, accent: wc);
          break;
        case MeleeWeapon.forceBlade:
          WHDraw.forceBlade(canvas, 0, 0, 1.15, accent: wc);
          break;
        case MeleeWeapon.forceSword:
          WHDraw.forceSword(canvas, 0, 0, 1.15, accent: wc);
          break;
        case MeleeWeapon.daemonHammer:
          WHDraw.daemonHammer(canvas, 0, 0, 1.1, accent: wc);
          break;
        case MeleeWeapon.katana:
          WHDraw.katana(canvas, 0, 0, 1.05, accent: wc);
          break;
        case MeleeWeapon.powerKatana:
          WHDraw.powerKatana(canvas, 0, 0, 1.05, accent: wc);
          break;
        case MeleeWeapon.executioner:
          WHDraw.executioner(canvas, 0, 0, 1.05, accent: wc);
          break;
      }
    } else {
      switch (game.rangedWeapon) {
        case RangedWeapon.bolter:
          WHDraw.bolter(canvas, 0, 0, 1.0, accent: wc);
          break;
        case RangedWeapon.rifle:
          WHDraw.rifle(canvas, 0, 0, 1.0, accent: wc);
          break;
        case RangedWeapon.shotgun:
          WHDraw.shotgun(canvas, 0, 0, 1.0, accent: wc);
          break;
        case RangedWeapon.staff:
          WHDraw.staff(canvas, 0, 0, 1.15, accent: wc);
          break;
        case RangedWeapon.stormStaff:
          WHDraw.stormStaff(canvas, 0, 0, 1.15, accent: wc);
          break;
        case RangedWeapon.warpBeam:
          WHDraw.warpBeamGun(canvas, 0, 0, 1.05, accent: wc);
          break;
        case RangedWeapon.daggers:
          WHDraw.daggers(canvas, 0, 0, 1.0, accent: wc);
          break;
        case RangedWeapon.needles:
          WHDraw.needles(canvas, 0, 0, 1.0, accent: wc);
          break;
        case RangedWeapon.sniperNeedle:
          WHDraw.sniperNeedle(canvas, 0, 0, 1.0, accent: wc);
          break;
      }
    }
    canvas.restore();
    if (game.invulnTimer > 0) {
      canvas.drawCircle(Offset(cx, cy), 40, Paint()..color = const Color(0xFF81D4FA).withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    if (game.shieldTimer > 0 || game.holyAuraTimer > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        38,
        Paint()
          ..color = (game.holyAuraTimer > 0 ? const Color(0xFFFFD700) : const Color(0xFF42A5F5)).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    WHDraw.statusIcons(canvas, cx, -8, statuses);
  }
}

class PsyWave extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final int damage;
  double radius = 20;
  final double maxRadius;
  final Set<int> hit = {};
  PsyWave({required Vector2 position, required this.direction, required this.damage, this.maxRadius = 160})
      : super(position: position.clone(), size: Vector2(40, 40), anchor: Anchor.center, priority: 13);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    radius += 220 * dt;
    position += direction * 160 * dt;
    size = Vector2.all(radius * 2);
    if (radius >= maxRadius) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy && hit.add(other.hashCode)) {
      other.applyDamage(damage);
      other.applyStatus(StatusType.corruption, 1.5, tickDamage: 1);
    }
    if (other is MiniBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is Boss && hit.add(other.hashCode)) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
    }
    if (other is KnightBoss && hit.add(other.hashCode)) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
    }
    if (other is KingBoss && hit.add(other.hashCode)) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
    }
    if (other is TentacleBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is CyclopsBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is PlagueLordBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is BloodChampionBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is BreakableBarrel) other.hit();
  }
  @override
  void render(Canvas canvas) {
    final a = (1 - radius / maxRadius).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), radius, Paint()..color = Color.fromRGBO(124, 77, 255, 0.35 * a)..style = PaintingStyle.stroke..strokeWidth = 6);
  }
}

class CyclopsLaserBeam extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final int damage;
  double life = 0.45;
  final Set<int> hit = {};
  CyclopsLaserBeam({required Vector2 position, required this.direction, required this.damage})
      : super(position: position.clone(), size: Vector2(400, 24), anchor: Anchor.centerLeft, priority: 14) {
    angle = atan2(direction.y, direction.x);
  }
  @override
  Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy && hit.add(other.hashCode)) other.applyDamage(damage);
    if (other is MiniBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is Boss && hit.add(other.hashCode)) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
    }
    if (other is KnightBoss && hit.add(other.hashCode)) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
    }
    if (other is KingBoss && hit.add(other.hashCode)) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
    }
    if (other is TentacleBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is CyclopsBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is PlagueLordBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is BloodChampionBoss && hit.add(other.hashCode)) other.takeDamage(damage);
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 0.45).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(0, size.y * 0.25, size.x, size.y * 0.5), Paint()..color = Color.fromRGBO(255, 109, 0, 0.85 * a));
  }
}

class Bullet extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 velocity;
  final int damage;
  final Color color;
  final bool pierce, ricochet, explosive, applyBurn;
  double life = 2.2;
  int bounces = 0;
  final Set<int> hitIds = {};

  Bullet({
    required Vector2 position,
    required Vector2 direction,
    required this.damage,
    required this.color,
    double speed = 520,
    double radius = 5,
    this.pierce = false,
    this.ricochet = false,
    this.explosive = false,
    this.applyBurn = false,
  })  : velocity = direction.normalized() * speed,
        super(position: position.clone(), size: Vector2.all(radius * 2), anchor: Anchor.center, priority: 13);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    final old = position.clone();
    position += velocity * dt;
    if (old.distanceTo(position) > 4) {
      game.world.add(BulletTrail(from: old, to: position.clone(), color: color)..priority = 12);
    }
    if (life <= 0 || position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) {
      removeFromParent();
    }
  }

  void _hitEnemy(Enemy e) {
    if (!hitIds.add(e.hashCode)) return;
    if (e.affix == EliteAffix.reflect && Random().nextDouble() < 0.25) {
      game.world.add(EnemyBullet(position: e.position.clone(), direction: (game.player.position - e.position).normalized(), damage: 1)..priority = 16);
    }
    final ratio = e.maxHp > 0 ? e.currentHp / e.maxHp : 1.0;
    final dmg = game.hasExecutionerMark && ratio < 0.3 ? (damage * 1.2).round() : damage;
    e.applyDamage(dmg);
    if (applyBurn || explosive) e.applyStatus(StatusType.burn, 2.0 + game.codexBurnBonus, tickDamage: 1);
    if (explosive) game.world.add(KillExplosion(position: position.clone(), radius: 55, damage: damage ~/ 3)..priority = 12);
    if (!pierce && !ricochet) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) _hitEnemy(other);
    if (other is MiniBoss) {
      other.takeDamage(damage);
      if (!pierce) removeFromParent();
    }
    if (other is Boss) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
      if (!pierce) removeFromParent();
    }
    if (other is KnightBoss) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
      if (!pierce) removeFromParent();
    }
    if (other is KingBoss) {
      other.takeDamage(damage);
      game.noteBossDamagedByRanged();
      if (!pierce) removeFromParent();
    }
    if (other is TentacleBoss) {
      other.takeDamage(damage);
      if (!pierce) removeFromParent();
    }
    if (other is CyclopsBoss) {
      other.takeDamage(damage);
      if (!pierce) removeFromParent();
    }
    if (other is PlagueLordBoss) {
      other.takeDamage(damage);
      if (!pierce) removeFromParent();
    }
    if (other is BloodChampionBoss) {
      other.takeDamage(damage);
      if (!pierce) removeFromParent();
    }
    if (other is BreakableBarrel) {
      other.hit();
      if (!pierce) removeFromParent();
    }
    if (other is Wall || other is Obstacle) {
      if (ricochet && bounces < 2) {
        bounces++;
        velocity.setValues(-velocity.x, velocity.y);
      } else {
        if (explosive) game.world.add(KillExplosion(position: position.clone(), radius: 50, damage: damage ~/ 3)..priority = 12);
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, Paint()..color = color);
  }
}

class MeleeAttack extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final int damage;
  final double radius;
  final double arc;
  final MeleeWeapon weapon;
  double life = 0.22;
  final Set<int> hit = {};
  MeleeAttack({
    required Vector2 position,
    required this.direction,
    required this.damage,
    required this.radius,
    required this.arc,
    required this.weapon,
  }) : super(position: position.clone(), size: Vector2.all(radius * 2), anchor: Anchor.center, priority: 15);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  bool _inArc(Vector2 otherPos) {
    final to = otherPos - position;
    if (to.length > radius + 30) return false;
    final a = atan2(direction.y, direction.x);
    final b = atan2(to.y, to.x);
    var d = (b - a).abs();
    if (d > pi) d = 2 * pi - d;
    return d <= arc / 2 + 0.15;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (game.hasJediPath && (other is EnemyBullet || other is BossProjectile)) {
      other.removeFromParent();
      game.spawnDamageNumber(other.position, 0, color: const Color(0xFF81D4FA), label: '✦');
      return;
    }
    if (game.hasJediPath && other is CorruptionZone) {
      other.purify();
      return;
    }
    if (other is Enemy && hit.add(other.hashCode) && _inArc(other.position)) {
      other.applyDamage(damage);
      if (game.synergyHereticusBleedDash || game.loadout.bladeEdge == BladeEdgeMod.serrated) {
        other.applyStatus(StatusType.bleed, 2.5, tickDamage: 1);
      }
    }
    if (other is MiniBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is Boss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is KnightBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is KingBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is TentacleBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is CyclopsBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is PlagueLordBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is BloodChampionBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is Obstacle && hit.add(other.hashCode)) other.removeFromParent();
    if (other is BreakableBarrel) other.hit();
  }

  @override
  void render(Canvas canvas) {
    final a = (life / 0.22).clamp(0.0, 1.0);
    final ang = atan2(direction.y, direction.x);
    final path = Path()..moveTo(size.x / 2, size.y / 2);
    path.arcTo(Rect.fromCircle(center: Offset(size.x / 2, size.y / 2), radius: radius), ang - arc / 2, arc, false);
    path.close();
    canvas.drawPath(path, Paint()..color = Color.fromRGBO(0, 188, 212, 0.35 * a));
  }
}

class EnemyBullet extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  Vector2 velocity;
  final int damage;
  final BulletMod mod;
  double life = 3.5;
  int bounces = 0;
  bool didSplit = false;

  EnemyBullet({
    required Vector2 position,
    required Vector2 direction,
    required this.damage,
    double speed = 180,
    this.mod = BulletMod.normal,
  })  : velocity = direction.normalized() * speed,
        super(position: position.clone(), size: Vector2(14, 14), anchor: Anchor.center, priority: 16);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    final old = position.clone();
    position += velocity * dt;
    if (old.distanceTo(position) > 6) {
      Color trailCol = const Color(0xFF76FF03);
      if (mod == BulletMod.slow) trailCol = const Color(0xFF4FC3F7);
      if (mod == BulletMod.ricochet) trailCol = const Color(0xFFFFEB3B);
      if (mod == BulletMod.split) trailCol = const Color(0xFFFF8A65);
      game.world.add(BulletTrail(from: old, to: position.clone(), color: trailCol)..priority = 12);
    }
    if (life <= 0) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.takeDamage(damage);
      if (mod == BulletMod.slow) other.applyStatus(StatusType.slow, 1.8);
      if (mod == BulletMod.split && !didSplit) {
        didSplit = true;
        final base = atan2(velocity.y, velocity.x);
        for (final o in [-0.4, 0.4]) {
          game.world.add(EnemyBullet(
            position: position.clone(),
            direction: Vector2(cos(base + o), sin(base + o)),
            damage: max(1, damage - 1),
            speed: 160,
          )..priority = 16);
        }
      }
      removeFromParent();
    }
    if (other is Wall || other is Obstacle) {
      if (mod == BulletMod.ricochet && bounces < 2) {
        bounces++;
        velocity = Vector2(-velocity.x, velocity.y);
      } else {
        removeFromParent();
      }
    }
    if (other is MeleeAttack && game.hasJediPath) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    Color col = const Color(0xFF76FF03);
    if (mod == BulletMod.slow) col = const Color(0xFF4FC3F7);
    if (mod == BulletMod.ricochet) col = const Color(0xFFFFEB3B);
    if (mod == BulletMod.split) col = const Color(0xFFFF8A65);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6, Paint()..color = col);
  }
}

class BossProjectile extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 velocity;
  double life = 4.0;
  BossProjectile({required Vector2 position, required Vector2 direction, double speed = 200})
      : velocity = direction.normalized() * speed,
        super(position: position.clone(), size: Vector2(18, 18), anchor: Anchor.center, priority: 22);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position += velocity * dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.takeDamage((1 * game.difficulty.dmgMult).ceil());
      removeFromParent();
    }
    if (other is Wall) removeFromParent();
    if (other is MeleeAttack && game.hasJediPath) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 8, Paint()..color = const Color(0xFFE53935));
  }
}

class FlamerCloud extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  double life = 1.8;
  FlamerCloud({required Vector2 position}) : super(position: position.clone(), size: Vector2(70, 70), anchor: Anchor.center, priority: 11);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) other.applyStatus(StatusType.burn, 1.5, tickDamage: 1);
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 1.8).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 30, Paint()..color = Color.fromRGBO(255, 109, 0, 0.4 * a));
  }
}
// ═══════════════════════════════════════════════════════════════
// ENEMIES
// ═══════════════════════════════════════════════════════════════

class Enemy extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
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
      add.maxHp = max(6, (maxHp * 0.25).round());
      add.currentHp = add.maxHp;
      add.priority = 30;
      game.world.add(add);
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
          game.world.add(EnemyBullet(position: position.clone(), direction: toP, damage: dmg, mod: game.rollBulletMod())..priority = 16);
        }
        break;
      case EnemyType.sniper:
        if (dist < 520) {
          game.world.add(EnemyBullet(position: position.clone(), direction: toP, damage: dmg + 1, speed: 280, mod: BulletMod.slow)..priority = 16);
        }
        break;
      case EnemyType.flamer:
        if (dist < 160) {
          game.world.add(FlamerCloud(position: position + toP * 40)..priority = 11);
          if (dist < 90) game.player.takeDamage(dmg);
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
          game.player.takeDamage(dmg);
          game.player.applyStatus(StatusType.plague, 2.5, tickDamage: 1);
        }
        break;
      case EnemyType.bloodletter:
      case EnemyType.melee:
      case EnemyType.dog:
      case EnemyType.brute:
      case EnemyType.shielded:
        if (dist < (type == EnemyType.brute ? 70 : 55)) {
          game.player.takeDamage(type == EnemyType.bloodletter || type == EnemyType.brute ? dmg + 1 : dmg);
          if (type == EnemyType.bloodletter) game.player.applyStatus(StatusType.bleed, 1.5, tickDamage: 1);
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
      canvas.drawRect(Rect.fromLTWH(cx - 22, -4, 44 * ratio, 5), Paint()..color = affix != EliteAffix.none ? affix.color : const Color(0xFFFFD700));
    }
    WHDraw.statusIcons(canvas, cx, -18, statuses);
  }
}

class MiniBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
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
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 40), width: 50, height: 12), Paint()..color = Colors.black.withOpacity(0.22));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 48, height: 52), const Radius.circular(6)),
      Paint()..color = const Color(0xFF4A1515),
    );
    canvas.drawCircle(Offset(cx, cy - 22), 16, Paint()..color = const Color(0xFF3E2723));
    WHDraw.shotgun(canvas, cx + 4, cy + 2, 1.1, accent: const Color(0xFF8D6E63));
    if (hurtFlash > 0) {
      canvas.drawCircle(Offset(cx, cy), 48, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * (hurtFlash / 0.12)));
    }
    if (isEcho) {
      canvas.drawCircle(Offset(cx, cy), 48, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(Rect.fromLTWH(cx - 40, -18, 80 * ratio, 8), Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF9800));
    WHDraw.statusIcons(canvas, cx, -28, statuses);
  }
}
// ═══════════════════════════════════════════════════════════════
// BOSSES
// ═══════════════════════════════════════════════════════════════

class Boss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
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
    final patterns = game.difficulty == Difficulty.hard ? ['ring', 'cone', 'cross', 'ring'] : ['ring', 'cone', 'cross'];
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
      canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(Rect.fromLTWH(cx - 50, -24, 100 * ratio, 9), Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFE53935));
    WHDraw.statusIcons(canvas, cx, -36, statuses);
  }
}

class KnightBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
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
        game.player.takeDamage((2 * game.difficulty.dmgMult).ceil());
      }
    } else {
      if (position.distanceTo(game.player.position) < 120) {
        game.player.takeDamage((3 * game.difficulty.dmgMult).ceil());
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
      canvas.drawCircle(Offset(cx, cy), 52, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(Rect.fromLTWH(cx - 48, -22, 96 * ratio, 9), Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFF90CAF9));
    WHDraw.statusIcons(canvas, cx, -34, statuses);
  }
}
class KingBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  late int phaseHp;
  int phase = 1;
  double attackTimer = 0;
  double phase2Timer = 0;
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
    final bonus = 1.0 + game.codexBossBonus;
    currentHp -= (amount * bonus).round();
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFFD700));
    if (phase == 1 && currentHp <= phaseHp) {
      phase = 2;
      phase2Timer = 0;
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
      // melee + fast chase implied by move; ring volley
      for (int i = 0; i < 10; i++) {
        final a = i / 10 * pi * 2;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 200)..priority = 22);
      }
      if (position.distanceTo(game.player.position) < 90) {
        game.player.takeDamage((3 * game.difficulty.dmgMult).ceil());
      }
    } else {
      // massed 3-salvo rings
      for (int salvo = 0; salvo < 3; salvo++) {
        Future.delayed(Duration(milliseconds: 180 * salvo), () {
          if (!isMounted) return;
          for (int i = 0; i < 14; i++) {
            final a = i / 14 * pi * 2 + salvo * 0.15;
            game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 210 + salvo * 15)..priority = 22);
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
    // phase 1 faster, phase 2 slower
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

    smartMove(game.player.position, spd, dt, radius: 55, kite: game.bossRetreatTimer > 0 || phase == 2, preferDist: phase == 1 ? 120 : 200);
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
      canvas.drawCircle(Offset(cx, cy), 62, Paint()..color = Color.fromRGBO(255, 215, 0, pulse)..style = PaintingStyle.stroke..strokeWidth = 4);
      final tp = TextPainter(
        text: const TextSpan(text: 'СВИТА', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, -48));
    }
    if (isEcho) {
      canvas.drawCircle(Offset(cx, cy), 60, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    // two bars
    final ratio1 = (currentHp > phaseHp ? (currentHp - phaseHp) / (maxHp - phaseHp) : 0.0).clamp(0.0, 1.0);
    final ratio2 = (currentHp <= phaseHp ? currentHp / phaseHp : 1.0).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 55, -30, 110 * ratio1, 7), Paint()..color = const Color(0xFFFFD700));
    canvas.drawRect(Rect.fromLTWH(cx - 55, -20, 110 * ratio2, 7), Paint()..color = const Color(0xFFFF6D00));
    WHDraw.statusIcons(canvas, cx, -42, statuses);
  }
}

class PlagueLordBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
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
    // spawn 2 plague bearers + cloud
    for (int i = 0; i < 2; i++) {
      final a = Random().nextDouble() * pi * 2;
      final pos = position + Vector2(cos(a) * 90, sin(a) * 90);
      game.enemiesAlive++;
      game.enemiesToSpawn++;
      game.enemiesSpawned++;
      final e = Enemy(floor: game.currentFloor, type: EnemyType.plagueBearer);
      e.position = pos;
      e.maxHp = max(8, (e.maxHp * 0.5).round());
      e.currentHp = e.maxHp;
      game.world.add(e);
    }
    game.world.add(FlamerCloud(position: position.clone())..priority = 11); // reuse as toxic cloud visually ok
    game.spawnCorruptionZone(position.clone());
    if (position.distanceTo(game.player.position) < 110) {
      game.player.takeDamage((2 * game.difficulty.dmgMult).ceil());
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
      canvas.drawCircle(Offset(cx, cy), 55, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(Rect.fromLTWH(cx - 52, -26, 104 * ratio, 9), Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFF8BC34A));
    WHDraw.statusIcons(canvas, cx, -38, statuses);
  }
}

class BloodChampionBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
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
    game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 150, angle: atan2(toP.y, toP.x), life: 0.55)..priority = 6);
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    position += toP * (40 + rage * 40);
    final dmg = ((2 + rage * 2) * game.difficulty.dmgMult).ceil();
    if (position.distanceTo(game.player.position) < 85) {
      game.player.takeDamage(dmg);
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
      canvas.drawCircle(Offset(cx, cy), 52, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final ratio = currentHp / maxHp;
    canvas.drawRect(Rect.fromLTWH(cx - 50, -24, 100 * ratio, 9), Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF1744));
    WHDraw.statusIcons(canvas, cx, -36, statuses);
  }
}
class TentacleBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
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
      // 6 slam zones around
      for (int i = 0; i < 6; i++) {
        final a = i / 6 * pi * 2 + tentacleAnim * 0.1;
        final p = position + Vector2(cos(a) * 100, sin(a) * 100);
        game.world.add(TelegraphZone(position: p, shape: 'circle', radius: 70, life: 0.7)..priority = 6);
      }
    }
  }

  void _executeAttack() {
    if (phase == 1) {
      // ring of projectiles
      for (int i = 0; i < 16; i++) {
        final a = i / 16 * pi * 2;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 170)..priority = 22);
      }
    } else {
      // 6 melee slams
      for (int i = 0; i < 6; i++) {
        final a = i / 6 * pi * 2 + tentacleAnim * 0.1;
        final p = position + Vector2(cos(a) * 100, sin(a) * 100);
        game.world.add(TentacleSlam(position: p)..priority = 14);
        if (p.distanceTo(game.player.position) < 90) {
          game.player.takeDamage((3 * game.difficulty.dmgMult).ceil());
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
    // body core
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 50), width: 70, height: 18), Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(Offset(cx, cy), 42, Paint()..color = const Color(0xFF4A148C));
    canvas.drawCircle(Offset(cx, cy), 28, Paint()..color = const Color(0xFF7B1FA2));
    // tentacles
    for (int i = 0; i < 8; i++) {
      final a = i / 8 * pi * 2 + tentacleAnim * (0.6 + i * 0.05);
      final len = 48 + 12 * sin(tentacleAnim * 2 + i);
      final x2 = cx + cos(a) * len;
      final y2 = cy + sin(a) * len;
      canvas.drawLine(Offset(cx, cy), Offset(x2, y2), Paint()..color = const Color(0xFF6A1B9A)..strokeWidth = 8..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(x2, y2), 8, Paint()..color = const Color(0xFF9C27B0));
    }
    // eye
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

class CyclopsBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
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
      // laser line
      game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 320, angle: atan2(toP.y, toP.x), life: telegraphTimer)..priority = 6);
    } else {
      game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 140, life: telegraphTimer)..priority = 6);
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    if (phase == 1) {
      game.world.add(CyclopsLaserBeam(position: position.clone(), direction: toP, damage: (8 * game.difficulty.dmgMult).ceil())..priority = 14);
    } else {
      // stomp + ring
      for (int i = 0; i < 12; i++) {
        final a = i / 12 * pi * 2;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 200)..priority = 22);
      }
      if (position.distanceTo(game.player.position) < 130) {
        game.player.takeDamage((4 * game.difficulty.dmgMult).ceil());
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

    smartMove(game.player.position, spd, dt, radius: 56, kite: game.bossRetreatTimer > 0 || (phase == 1 && dist < 150), preferDist: 200);
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
// ═══════════════════════════════════════════════════════════════
// ENTRY
// ═══════════════════════════════════════════════════════════════

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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: const Color(0xFFFFD700),
            side: const BorderSide(color: Color(0xFFB8860B)),
          ),
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
