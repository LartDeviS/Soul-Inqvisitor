import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/inquisitor_game.dart' as expansion;
import 'game/weapons/weapon_data.dart' as weapon_catalog;
import 'game/weapons/ordo_specialization.dart' as ordo;
import 'game/world/biome_data.dart' as world_catalog;
import 'game/world/arena_events.dart' as arena_catalog;
import 'ui/codex/weapon_catalog_panel.dart';
import 'ui/codex/world_codex_panel.dart';
import 'progression/inventory_state.dart' as gear_catalog;
import 'progression/progression_system.dart' as progression_catalog;
import 'game/missions/mission_events.dart' as mission_catalog;

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: InquisitorGame(),
        overlayBuilderMap: {
          'mainMenu': (c, g) => MainMenu(g as InquisitorGame),
          'nameInput': (c, g) => NameInputMenu(g as InquisitorGame),
          'classSelect': (c, g) => ClassSelectMenu(g as InquisitorGame),
          'oathSelect': (c, g) => OathSelectionMenu(g as InquisitorGame),
          'settings': (c, g) => SettingsMenu(g as InquisitorGame),
          'gameOver': (c, g) => GameOverMenu(g as InquisitorGame),
          'levelComplete': (c, g) => LevelCompleteMenu(g as InquisitorGame),
          'skills': (c, g) => SkillsMenu(g as InquisitorGame),
          'reward': (c, g) => RewardMenu(g as InquisitorGame),
          'shop': (c, g) => ShopMenu(g as InquisitorGame),
          'victory': (c, g) => VictoryMenu(g as InquisitorGame),
          'records': (c, g) => RecordsMenu(g as InquisitorGame),
          'achievements': (c, g) => AchievementsMenu(g as InquisitorGame),
          'backpack': (c, g) => BackpackMenu(g as InquisitorGame),
          'loadSave': (c, g) => LoadSaveMenu(g as InquisitorGame),
          'codex': (c, g) => CodexMenu(g as InquisitorGame),
          'chronicle': (c, g) => CampaignChronicleMenu(g as InquisitorGame),
          'eventAltar': (c, g) => EventAltarMenu(g as InquisitorGame),
          'eventMerchant': (c, g) => EventMerchantMenu(g as InquisitorGame),
          'pathSelect': (c, g) => PathSelectMenu(g as InquisitorGame),
          'lorePopup': (c, g) => LorePopupMenu(g as InquisitorGame),
          'challengeSelect': (c, g) => ChallengeSelectMenu(g as InquisitorGame),
          'rankPerk': (c, g) => RankPerkMenu(g as InquisitorGame),
          'inquisitionHub': (c, g) => InquisitionHubMenu(g as InquisitorGame),
        },
        initialActiveOverlays: const ['mainMenu'],
      ),
    ),
  );
}

// Expansion systems are deliberately additive: legacy saves remain readable, existing route nodes stay authoritative, and all new visuals use Canvas geometry.
// ─── Enums ───────────────────────────────────────────────
enum RangedWeapon {
  bolter, rifle, shotgun, plasmaGun,
  staff, stormStaff, warpBeam,
  daggers, needles, sniperNeedle,
  meltaGun, flamer, heavyBolter,
  // Ordo Malleus: daemon-hunting ranged arsenal
  psycannon, exorcistIncinerator, daemonbanePistol,
  // Ordo Hereticus: witch-hunter ranged arsenal
  condemnorBoltgun, sanctifiedStakeCrossbow, infernoPistol,
}
enum MeleeWeapon {
  sword, axe, hammer,
  forceBlade, forceSword, daemonHammer,
  katana, powerKatana, executioner,
}
enum EnemyType {
  shooter, melee, shielded, dog, shieldedShooter, flamer, sniper, brute,
  cultPsyker, plagueBearer, bloodletter,
  orkBoy, tyranidGaunt, necronWarrior,
  genestealer, chaosSpawn, necronImmortal,
}
enum Difficulty { easy, normal, hard, hell }
enum PlayerClass { xenos, malleus, hereticus }
enum RelicId {
  crit, lifesteal, shieldPierce, killExplosion, haste, jediPath,
  // new
  ammoSavant, warpAnchor, shadowStep, ironWill, executionerMark, scavenger,
}
enum StatusType { burn, bleed, slow, corruption, plague }
enum ActiveArtifact { fragGrenade, holyAura, servoTurret }
enum EchoBossKind { none, mini, ranged, knight, king, plague, blood }
enum EventRoomType { none, altar, merchant, trap }
enum EliteAffix { none, swift, regenerating, explosive, reflect, summoner }
enum PathNodeKind { combat, event, elite, rest, boss, hunt, defense, ritual, survival }
enum RankChallenge { none, meleeBossOnly, noDash }
enum BulletMod { normal, slow, ricochet, split }
enum RankPerk { none, startSp, scrapBonus }

/// Permanent tactical doctrine selected before deployment.
enum CombatDoctrine { balanced, mobile, heavy, melee, bossHunter, control }
/// Endless-arena challenge rules. All arena visuals are drawn procedurally.
enum ArenaModifier { none, swift, armored, swarm, unstable }
/// Deathwatch ammunition profile.
enum AmmoDoctrine { standard, armorPiercing, incendiary, suppressive, antiWarp }

/// Damage channels used by Combat 2.0. Kept separate from legacy weapon enums
/// so existing save files and weapon unlocks remain compatible.
enum CombatDamageType { kinetic, plasma, flame, warp, melee, explosive }

enum LootRarity { common, uncommon, rare, epic, legendary }
enum LootKind { ammunition, medicae, requisition, weaponPart, evidence, keycard, relicShard, stim, grenade, mod }
enum TacticalConsumable { fragGrenade, stim, smoke, auspexPulse }
enum MapLayout { cruciform, ring, corridors, chambers, openYard }
enum InquisitionFaction { imperium, chaos, ork, tyranid, necron, daemon }
enum BiomeId { manufactorum, hive, shrine, deathWorld, warpRuin, voidship, necronTomb }
enum InventoryLocation { backpack, equipment, vault }
enum InvestigationDecision { preserveEvidence, destroyEvidence, bargainWithInformant }

extension InquisitionFactionMeta on InquisitionFaction {
  String get labelRu => switch (this) {
    InquisitionFaction.imperium => 'Империум', InquisitionFaction.chaos => 'Хаос',
    InquisitionFaction.ork => 'Орки', InquisitionFaction.tyranid => 'Тираниды',
    InquisitionFaction.necron => 'Некроны', InquisitionFaction.daemon => 'Демоны',
  };
  String get tacticalNote => switch (this) {
    InquisitionFaction.imperium => 'Дисциплина и броня: подавление эффективно.',
    InquisitionFaction.chaos => 'Культисты уязвимы к точному огню; псайкеры опасны на дистанции.',
    InquisitionFaction.ork => 'Высокий натиск в ближнем бою; держать дистанцию.',
    InquisitionFaction.tyranid => 'Скорость и численность; огонь по площади и контроль.',
    InquisitionFaction.necron => 'Прочные цели; бронебойные боеприпасы предпочтительны.',
    InquisitionFaction.daemon => 'Варп-угроза; антиварповые боеприпасы и стабильность критичны.',
  };
}

/// Procedural armor patterns inspired by broad 40K silhouettes; all markings are drawn with Canvas.
enum ArmorPattern { flak, carapace, mk3Iron, mk6Corvus, mk7Aquila, artificer, terminator, voidSealed, inquisitorial }
extension ArmorPatternMeta on ArmorPattern {
  String get labelRu => switch (this) {
    ArmorPattern.flak => 'Флак-бронирование', ArmorPattern.carapace => 'Кираса карапас',
    ArmorPattern.mk3Iron => 'Силовая броня Mk III «Железная»', ArmorPattern.mk6Corvus => 'Силовая броня Mk VI «Корвус»',
    ArmorPattern.mk7Aquila => 'Силовая броня Mk VII «Аквила»', ArmorPattern.artificer => 'Артефакторная броня',
    ArmorPattern.terminator => 'Терминаторская броня', ArmorPattern.voidSealed => 'Герметичный штурмовой комплект',
    ArmorPattern.inquisitorial => 'Инквизиторский панцирь',
  };
  int get price => switch (this) { ArmorPattern.flak => 0, ArmorPattern.carapace => 45, ArmorPattern.mk3Iron => 85, ArmorPattern.mk6Corvus => 95, ArmorPattern.mk7Aquila => 110, ArmorPattern.artificer => 180, ArmorPattern.terminator => 240, ArmorPattern.voidSealed => 135, ArmorPattern.inquisitorial => 160 };
  double get defense => switch (this) { ArmorPattern.flak => 0, ArmorPattern.carapace => .05, ArmorPattern.mk3Iron => .12, ArmorPattern.mk6Corvus => .08, ArmorPattern.mk7Aquila => .10, ArmorPattern.artificer => .15, ArmorPattern.terminator => .22, ArmorPattern.voidSealed => .11, ArmorPattern.inquisitorial => .13 };
}

/// Item storage category. Existing field loot stays backward compatible.
class StoredInventoryItem {
  final FieldLootItem item;
  InventoryLocation location;
  StoredInventoryItem(this.item, {this.location = InventoryLocation.backpack});
  Map<String, dynamic> toJson() => {'item': item.toJson(), 'location': location.name};
  factory StoredInventoryItem.fromJson(Map<String, dynamic> j) => StoredInventoryItem(
    FieldLootItem.fromJson(Map<String, dynamic>.from(j['item'] as Map)),
    location: InventoryLocation.values.firstWhere((e) => e.name == j['location'], orElse: () => InventoryLocation.backpack),
  );
}

/// Weapon parts are independently configurable; each slot contributes a small, bounded modifier.
class ModularWeaponBuild {
  String receiver = 'standard';
  String barrel = 'balanced';
  String sight = 'iron';
  String feed = 'standard';
  String underbarrel = 'none';
  String core = 'standard';
  Map<String, dynamic> toJson() => {'receiver': receiver, 'barrel': barrel, 'sight': sight, 'feed': feed, 'underbarrel': underbarrel, 'core': core};
  void load(Map<String, dynamic>? j) {
    if (j == null) return;
    receiver = j['receiver']?.toString() ?? receiver; barrel = j['barrel']?.toString() ?? barrel;
    sight = j['sight']?.toString() ?? sight; feed = j['feed']?.toString() ?? feed;
    underbarrel = j['underbarrel']?.toString() ?? underbarrel; core = j['core']?.toString() ?? core;
  }
  double get damageMultiplier => (receiver == 'heavy' ? 1.12 : receiver == 'light' ? 0.92 : 1.0) * (barrel == 'long' ? 1.08 : barrel == 'vented' ? 0.96 : 1.0) * (core == 'sanctified' ? 1.08 : core == 'unstable' ? 1.18 : 1.0);
  double get rateMultiplier => (receiver == 'light' ? 1.12 : receiver == 'heavy' ? 0.90 : 1.0) * (barrel == 'vented' ? 1.08 : 1.0) * (feed == 'rapid' ? 1.12 : feed == 'heavy' ? 0.92 : 1.0);
  double get precisionMultiplier => (sight == 'auspex' ? 1.12 : sight == 'scope' ? 1.18 : sight == 'wide' ? 0.92 : 1.0) * (barrel == 'long' ? 1.05 : 1.0);
}


extension LootRarityMeta on LootRarity {
  String get labelRu => switch (this) {
    LootRarity.common => 'Обычный', LootRarity.uncommon => 'Необычный',
    LootRarity.rare => 'Редкий', LootRarity.epic => 'Эпический', LootRarity.legendary => 'Легендарный',
  };
  Color get color => switch (this) {
    LootRarity.common => const Color(0xFFB0BEC5), LootRarity.uncommon => const Color(0xFF66BB6A),
    LootRarity.rare => const Color(0xFF42A5F5), LootRarity.epic => const Color(0xFFAB47BC),
    LootRarity.legendary => const Color(0xFFFFB300),
  };
}

class FieldLootItem {
  final String id;
  final LootKind kind;
  final LootRarity rarity;
  final String name;
  final int value;
  final int floorFound;
  final String mark;
  FieldLootItem({required this.id, required this.kind, required this.rarity, required this.name, required this.value, required this.floorFound, this.mark = 'AQUILA'});
  Map<String, dynamic> toJson() => {'id': id, 'kind': kind.name, 'rarity': rarity.name, 'name': name, 'value': value, 'floorFound': floorFound, 'mark': mark};
  factory FieldLootItem.fromJson(Map<String, dynamic> j) => FieldLootItem(
    id: j['id']?.toString() ?? 'loot-${DateTime.now().microsecondsSinceEpoch}',
    kind: LootKind.values.firstWhere((e) => e.name == j['kind'], orElse: () => LootKind.weaponPart),
    rarity: LootRarity.values.firstWhere((e) => e.name == j['rarity'], orElse: () => LootRarity.common),
    name: j['name']?.toString() ?? 'Полевой предмет', value: (j['value'] as num?)?.toInt() ?? 1,
    floorFound: (j['floorFound'] as num?)?.toInt() ?? 1, mark: j['mark']?.toString() ?? 'AQUILA',
  );
}

/// Short tactical orders layered over existing campaign nodes; these never replace the path system.
enum TacticalContract { purge, hunter, ritual, survivor, champion }
extension TacticalContractMeta on TacticalContract {
  String get labelRu => switch (this) {
    TacticalContract.purge => 'Зачистка сектора',
    TacticalContract.hunter => 'Охота на цель',
    TacticalContract.ritual => 'Срыв ритуала',
    TacticalContract.survivor => 'Удержать позицию',
    TacticalContract.champion => 'Ликвидация чемпиона',
  };
  String get detailRu => switch (this) {
    TacticalContract.purge => 'Уничтожьте противников в секторе',
    TacticalContract.hunter => 'Уничтожьте усиленных врагов и босса',
    TacticalContract.ritual => 'Прервите варп-ритуал, уничтожая культистов',
    TacticalContract.survivor => 'Переживите волну и зачистите сектор',
    TacticalContract.champion => 'Уничтожьте чемпиона Хаоса',
  };
}

/// Class-specific weapon mods (Gungeon / VS style loadout)
enum GunBarrelMod { none, rapid, heavy }       // Xenos guns
enum GunSightMod { none, precision, wide }
enum GunAmmoMod { none, ricochet, explosive, pierce }
enum StaffFocusMod { none, wideSphere, focusCore, dissipator } // Malleus
enum BladeEdgeMod { none, serrated, monomolecular, weighted }  // Hereticus / melee

enum CodexId {
  shooter, melee, shielded, dog, shieldedShooter, flamer, sniper, brute,
  cultPsyker, plagueBearer, bloodletter,
  miniBoss, boss, knight, king, tentacle, cyclops, champion,
  plagueLord, bloodChampion,
  genestealer, chaosSpawn, necronImmortal, orkBoy, tyranidGaunt, necronWarrior,
}

extension DiffLabel on Difficulty {
  String get labelRu {
    switch (this) {
      case Difficulty.easy: return 'Легко';
      case Difficulty.normal: return 'Норма';
      case Difficulty.hard: return 'Хард';
      case Difficulty.hell: return 'АДСКИЙ';
    }
  }
  /// Floors in a full campaign
  int get maxFloors {
    switch (this) {
      case Difficulty.easy: return 5;   // 25 nodes
      case Difficulty.normal: return 7; // 35
      case Difficulty.hard: return 10;  // 50
      case Difficulty.hell: return 13;  // +3 этажа к Хард
    }
  }
  int get levelsPerFloor => this == Difficulty.hell ? 8 : 5;
  int get maxOverallLevels => maxFloors * levelsPerFloor;

  double get hpMult {
    switch (this) {
      case Difficulty.easy: return 0.75;
      case Difficulty.normal: return 1.15;
      case Difficulty.hard: return 1.70;
      case Difficulty.hell: return 1.95; // Адский: повышенная угроза без тройного множителя
    }
  }
  double get dmgMult {
    switch (this) {
      case Difficulty.easy: return 0.70;
      case Difficulty.normal: return 1.05;
      case Difficulty.hard: return 1.45;
      case Difficulty.hell: return 1.38; // Адский: опасно, но без тройного множителя
    }
  }
  double get bossHpMult {
    switch (this) {
      case Difficulty.easy: return 0.80;
      case Difficulty.normal: return 1.20;
      case Difficulty.hard: return 1.85;
      case Difficulty.hell: return 2.10; // босс-множитель применяется только к отдельным боссам
    }
  }
}

extension ClassLabel on PlayerClass {
  String get title {
    switch (this) {
      case PlayerClass.xenos: return 'Ordo Xenos';
      case PlayerClass.malleus: return 'Ordo Malleus';
      case PlayerClass.hereticus: return 'Ordo Hereticus';
    }
  }
  String get subtitle {
    switch (this) {
      case PlayerClass.xenos: return 'Охотник на ксеносов. Болтер, винтовка, дробовик. Моды: ствол/прицел/боезапас.';
      case PlayerClass.malleus: return 'Псайкер. Посох и варп. Моды: сфера/фокус/диссипатор. Варп-стабильность Ψ.';
      case PlayerClass.hereticus: return 'Ассасин. Катана и кинжалы. Моды клинка: зазубрины/мономолекула/утяжеление.';
    }
  }
  int get hpMod {
    switch (this) {
      case PlayerClass.xenos: return 0;
      case PlayerClass.malleus: return -1;
      case PlayerClass.hereticus: return -1;
    }
  }
  double get speedMod {
    switch (this) {
      case PlayerClass.xenos: return 0;
      case PlayerClass.malleus: return -18;
      case PlayerClass.hereticus: return 28;
    }
  }
  double get dmgMod {
    switch (this) {
      case PlayerClass.xenos: return 1.0;
      case PlayerClass.malleus: return 1.12;
      case PlayerClass.hereticus: return 1.06;
    }
  }
}

extension RelicMeta on RelicId {
  String get title {
    switch (this) {
      case RelicId.crit: return 'Око Императора';
      case RelicId.lifesteal: return 'Кровавая печать';
      case RelicId.shieldPierce: return 'Иглы веры';
      case RelicId.killExplosion: return 'Разряд очищения';
      case RelicId.haste: return 'Шаги святого';
      case RelicId.jediPath: return 'Путь клинка';
      case RelicId.ammoSavant: return 'Арсенал Адептус';
      case RelicId.warpAnchor: return 'Якорь Варпа';
      case RelicId.shadowStep: return 'Тень аколита';
      case RelicId.ironWill: return 'Железная воля';
      case RelicId.executionerMark: return 'Метка палача';
      case RelicId.scavenger: return 'Сборщик трофеев';
    }
  }
  String get desc {
    switch (this) {
      case RelicId.crit: return '15% крит ×2';
      case RelicId.lifesteal: return '15% +1 HP при убийстве';
      case RelicId.shieldPierce: return 'Частичное пробитие щитов';
      case RelicId.killExplosion: return 'Взрыв при убийстве';
      case RelicId.haste: return '+12% скорость 3с после килла';
      case RelicId.jediPath: return 'Клинок сбивает пули и очищает зоны';
      case RelicId.ammoSavant: return '−25% перегрев болтера / +1 снаряд каждые 80 киллов';
      case RelicId.warpAnchor: return '−30% рост Ψ; сброс Ψ бесплатно раз в 12с';
      case RelicId.shadowStep: return 'Рывок U −1.5с кулдаун; +0.1с i-frame';
      case RelicId.ironWill: return '+1 макс HP; первый смертельный удар → 1 HP (1 раз за этаж)';
      case RelicId.executionerMark: return '+20% урон целям <30% HP';
      case RelicId.scavenger: return '+35% обломков с чемпионов и бочек';
    }
  }
}

extension AffixMeta on EliteAffix {
  String get letter {
    switch (this) {
      case EliteAffix.none: return '';
      case EliteAffix.swift: return 'S';
      case EliteAffix.regenerating: return 'R';
      case EliteAffix.explosive: return 'E';
      case EliteAffix.reflect: return 'F';
      case EliteAffix.summoner: return 'N';
    }
  }
  Color get color {
    switch (this) {
      case EliteAffix.none: return Colors.transparent;
      case EliteAffix.swift: return const Color(0xFF00E5FF);
      case EliteAffix.regenerating: return const Color(0xFF69F0AE);
      case EliteAffix.explosive: return const Color(0xFFFF6D00);
      case EliteAffix.reflect: return const Color(0xFFE040FB);
      case EliteAffix.summoner: return const Color(0xFFFFEB3B);
    }
  }
  String get title {
    switch (this) {
      case EliteAffix.none: return '';
      case EliteAffix.swift: return 'Swift';
      case EliteAffix.regenerating: return 'Regenerating';
      case EliteAffix.explosive: return 'Explosive';
      case EliteAffix.reflect: return 'Reflect';
      case EliteAffix.summoner: return 'Summoner';
    }
  }
}

extension ArtifactMeta on ActiveArtifact {
  String get title {
    switch (this) {
      case ActiveArtifact.fragGrenade: return 'Осколочная граната';
      case ActiveArtifact.holyAura: return 'Святая аура';
      case ActiveArtifact.servoTurret: return 'Серво-турель';
    }
  }
  double get cooldown {
    switch (this) {
      case ActiveArtifact.fragGrenade: return 14;
      case ActiveArtifact.holyAura: return 18;
      case ActiveArtifact.servoTurret: return 16;
    }
  }
}

extension ChallengeMeta on RankChallenge {
  String get title {
    switch (this) {
      case RankChallenge.none: return 'Без испытания';
      case RankChallenge.meleeBossOnly: return 'Клинок Императора';
      case RankChallenge.noDash: return 'Стоять насмерть';
    }
  }
  String get desc {
    switch (this) {
      case RankChallenge.none: return 'Обычный забег';
      case RankChallenge.meleeBossOnly: return 'Боссов — только ближний. +1 ранг при победе.';
      case RankChallenge.noDash: return 'Рывок U запрещён. +1 ранг при победе.';
    }
  }
}

extension CodexMeta on CodexId {
  String get title {
    switch (this) {
      case CodexId.shooter: return 'Культист-стрелок';
      case CodexId.melee: return 'Культист-клинок';
      case CodexId.shielded: return 'Еретик со щитом';
      case CodexId.dog: return 'Хаос-гончая';
      case CodexId.shieldedShooter: return 'Щитовой стрелок';
      case CodexId.flamer: return 'Огнемётчик культа';
      case CodexId.sniper: return 'Снайпер-отступник';
      case CodexId.brute: return 'Зверь культа';
      case CodexId.cultPsyker: return 'Культист-псайкер';
      case CodexId.plagueBearer: return 'Носитель чумы';
      case CodexId.bloodletter: return 'Кровопускатель';
      case CodexId.miniBoss: return 'Мини-босс культа';
      case CodexId.boss: return 'Чемпион ереси';
      case CodexId.knight: return 'Рыцарь-отступник';
      case CodexId.king: return 'Король еретиков';
      case CodexId.tentacle: return 'Тентаклевый ужас';
      case CodexId.cyclops: return 'Циклоп Варпа';
      case CodexId.champion: return 'Чемпион-элита';
      case CodexId.plagueLord: return 'Повелитель чумы';
      case CodexId.bloodChampion: return 'Кровавый чемпион';
      case CodexId.genestealer: return 'Генокрад';
      case CodexId.chaosSpawn: return 'Отродье Хаоса';
      case CodexId.necronImmortal: return 'Бессмертный некронов';
      case CodexId.orkBoy: return 'Орк-парень';
      case CodexId.tyranidGaunt: return 'Тиранид-гаунт';
      case CodexId.necronWarrior: return 'Воин некронов';
    }
  }
  String get lore {
    switch (this) {
      case CodexId.shooter:
        return 'В сегментуме Обскурус полки пали под шёпот Тёмных Богов. Их болтеры — кустарные копии, смазанные кровью. Один выстрел — одна душа, потерянная для Императора.';
      case CodexId.melee:
        return 'Клинок для культиста — молитва Кхорну. Они идут в упор. Ордо Херетикус учит: не дай им коснуться.';
      case CodexId.shielded:
        return 'Щиты из обломков Леман Русс. Пуля рикошетит; только освящённый клинок пробивает ересь.';
      case CodexId.dog:
        return 'Мутанты из подземелий ульев. Быстрее мысли, голоднее Пустоты.';
      case CodexId.shieldedShooter:
        return 'Дисциплина предавших Адептус. Щит и очередь — тактика, обращённая против Трона.';
      case CodexId.flamer:
        return 'Прометий и молитвы Нурглу. Тот же огонь, другая молитва.';
      case CodexId.sniper:
        return 'Один выстрел — один труп. Не стой на открытом месте дольше трёх ударов сердца.';
      case CodexId.brute:
        return 'Плоть, раздутая варп-энергией. Удары крушат силовую броню.';
      case CodexId.cultPsyker:
        return 'Необузданный псайкер культа. Волны варпа рвут плоть и разум. Ордо Маллеус помечает их красной печатью: приоритет ликвидации — немедленный.';
      case CodexId.plagueBearer:
        return 'Слуги Нургла. Их касание — чума. Медленные, но упрямые; каждый шаг оставляет гниль. Огонь и вера — единственное лекарство.';
      case CodexId.bloodletter:
        return 'Демоны Кхорна в оболочке смертных. Жаждут только ближнего боя. Отступление для них — ересь; для тебя — тактика.';
      case CodexId.miniBoss:
        return 'Лейтенант культа. Дробовик — приговор для аколитов.';
      case CodexId.boss:
        return 'Чемпион ереси. Залпы во все стороны — ритуал. Пока он жив, вера слабеет.';
      case CodexId.knight:
        return 'Падший брат. Сближение смертельно. Ордо Маллеус знает цену такой встречи.';
      case CodexId.king:
        return 'Владыка этажа. Пока жива свита — он неуязвим. Сломай свиту — сломай короля.';
      case CodexId.tentacle:
        return 'Порождение Варпа. Тысячи щупалец, один глаз. Стой в углу тридцать три секунды.';
      case CodexId.cyclops:
        return 'Демон с одним оком. Луч прожигает танк и душу.';
      case CodexId.champion:
        return 'Элита культа. Золотая печать — знак избранности. Убей — и реликвия может пасть.';
      case CodexId.plagueLord:
        return 'Аватар Нургла на поле боя. Облака чумы, регенерация, призыв носителей. Сожги его, пока гниль не поглотила этаж.';
      case CodexId.bloodChampion:
        return 'Избранник Кхорна. Чем больше крови пролито — тем сильнее его удар. Не дай комбо врага расти.';
      case CodexId.genestealer:
        return 'Генокрады — быстрые засадные хищники, чьи когти разрывают броню. Их опасность — резкое сближение и серия ударов.';
      case CodexId.chaosSpawn:
        return 'Отродье Хаоса — нестабильная масса мутаций. Регенерирует в бою и атакует непредсказуемыми конечностями.';
      case CodexId.necronImmortal:
        return 'Бессмертные некронов — тяжёлая пехота древней машинной династии. Их гаусс-оружие истончает материю, а самовосстановление делает их опасными на дистанции.';
      case CodexId.orkBoy:
        return 'Орк-парень идёт в лобовую атаку, полагаясь на грубую силу и численное превосходство. Держи дистанцию и не позволяй ему зажать себя у стены.';
      case CodexId.tyranidGaunt:
        return 'Гаунты — передовой рой тиранидов. Поодиночке они уязвимы, но быстрый натиск опасен; огонь по площади помогает сдерживать стаю.';
      case CodexId.necronWarrior:
        return 'Воин некронов медлителен, но защищён металлическим панцирем. Бронебойные боеприпасы эффективнее обычных попаданий.';
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
        return '+1с к DoT (огонь/чума)';
      case CodexId.cultPsyker:
        return '+5% сопротивление варп-урону';
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
        return '+1 SP при убийстве секрета';
      case CodexId.genestealer:
        return '+2% урон по генокрадам';
      case CodexId.chaosSpawn:
        return '+2% урон по отродьям Хаоса';
      case CodexId.necronImmortal:
        return '+2% урон по некронам';
      case CodexId.orkBoy:
        return '+2% урон по оркам';
      case CodexId.tyranidGaunt:
        return '+2% урон по тиранидам';
      case CodexId.necronWarrior:
        return '+2% урон по некронам';
    }
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
  WeaponMastery();
  int getCount(String key) => kills[key] ?? 0;
  void addKill(String key) => kills[key] = getCount(key) + 1;

  int bolterExtraShots(int base, {bool ammoSavant = false, bool xenosSynergy = false}) {
    final k = getCount('bolter');
    var extra = (k ~/ 50).clamp(0, 3);
    if (ammoSavant) extra += (k ~/ 80).clamp(0, 1);
    if (xenosSynergy && k >= 50) extra = extra < 1 ? 1 : extra;
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

extension CombatDoctrineLabel on CombatDoctrine {
  String get labelRu => switch (this) {
    CombatDoctrine.balanced => 'Сбалансированная',
    CombatDoctrine.mobile => 'Мобильность',
    CombatDoctrine.heavy => 'Тяжёлое оружие',
    CombatDoctrine.melee => 'Ближний бой',
    CombatDoctrine.bossHunter => 'Охотник на боссов',
    CombatDoctrine.control => 'Контроль толпы',
  };
  String get descriptionRu => switch (this) {
    CombatDoctrine.balanced => 'Без штрафов и специальных бонусов.',
    CombatDoctrine.mobile => '+12% скорость, -6% урон.',
    CombatDoctrine.heavy => '+12% урон, -8% скорость.',
    CombatDoctrine.melee => '+15% ближний бой, -8% дальний бой.',
    CombatDoctrine.bossHunter => '+8% урон всегда, +10% по боссам.',
    CombatDoctrine.control => 'Контрольные эффекты дольше на 35%.',
  };
}

extension ArenaModifierLabel on ArenaModifier {
  String get labelRu => switch (this) {
    ArenaModifier.none => 'Стандартная арена',
    ArenaModifier.swift => 'Быстрые враги',
    ArenaModifier.armored => 'Бронированные враги',
    ArenaModifier.swarm => 'Рой',
    ArenaModifier.unstable => 'Нестабильный Варп',
  };
}

extension AmmoDoctrineLabel on AmmoDoctrine {
  String get labelRu => switch (this) {
    AmmoDoctrine.standard => 'Стандартные',
    AmmoDoctrine.armorPiercing => 'Бронебойные',
    AmmoDoctrine.incendiary => 'Зажигательные',
    AmmoDoctrine.suppressive => 'Подавляющие',
    AmmoDoctrine.antiWarp => 'Антиварповые',
  };
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
      case StatusType.burn: return const Color(0xFFFF6D00);
      case StatusType.bleed: return const Color(0xFFE53935);
      case StatusType.slow: return const Color(0xFF4FC3F7);
      case StatusType.corruption: return const Color(0xFF9C27B0);
      case StatusType.plague: return const Color(0xFF8BC34A);
    }
  }
}

class SkillTree {
  int hp, speed, attackSpeed, defense, damage;
  SkillTree({this.hp = 0, this.speed = 0, this.attackSpeed = 0, this.defense = 0, this.damage = 0});
  int get totalSpent => hp + speed + attackSpeed + defense + damage;
  Map<String, dynamic> toJson() => {'hp': hp, 'speed': speed, 'attackSpeed': attackSpeed, 'defense': defense, 'damage': damage};
  factory SkillTree.fromJson(Map<String, dynamic>? j) {
    if (j == null) return SkillTree();
    return SkillTree(
      hp: j['hp'] as int? ?? 0,
      speed: j['speed'] as int? ?? 0,
      attackSpeed: j['attackSpeed'] as int? ?? 0,
      defense: j['defense'] as int? ?? 0,
      damage: j['damage'] as int? ?? 0,
    );
  }
}

class Customization {
  int armorHue, capeHue, weaponHue, trimHue;
  Customization({this.armorHue = 210, this.capeHue = 0, this.weaponHue = 45, this.trimHue = 45});
  Color armorColor([double l = 0.28]) => HSLColor.fromAHSL(1, armorHue.toDouble(), 0.18, l).toColor();
  Color capeColor([double l = 0.28]) => HSLColor.fromAHSL(1, capeHue.toDouble(), 0.75, l).toColor();
  Color weaponColor([double l = 0.45]) => HSLColor.fromAHSL(1, weaponHue.toDouble(), 0.65, l).toColor();
  Color trimColor([double l = 0.55]) => HSLColor.fromAHSL(1, trimHue.toDouble(), 0.70, l).toColor();
  Map<String, dynamic> toJson() => {'armorHue': armorHue, 'capeHue': capeHue, 'weaponHue': weaponHue, 'trimHue': trimHue};
  factory Customization.fromJson(Map<String, dynamic>? j) {
    if (j == null) return Customization();
    return Customization(
      armorHue: j['armorHue'] as int? ?? 210,
      capeHue: j['capeHue'] as int? ?? 0,
      weaponHue: j['weaponHue'] as int? ?? 45,
      trimHue: j['trimHue'] as int? ?? 45,
    );
  }
}

/// Unified loadout — only relevant slots apply per class
class WeaponLoadout {
  // Xenos gun
  GunBarrelMod gunBarrel;
  GunSightMod gunSight;
  GunAmmoMod gunAmmo;
  // Malleus staff
  StaffFocusMod staffFocus;
  // Hereticus / general melee
  BladeEdgeMod bladeEdge;

  WeaponLoadout({
    this.gunBarrel = GunBarrelMod.none,
    this.gunSight = GunSightMod.none,
    this.gunAmmo = GunAmmoMod.none,
    this.staffFocus = StaffFocusMod.none,
    this.bladeEdge = BladeEdgeMod.none,
  });

  Map<String, dynamic> toJson() => {
        'gunBarrel': gunBarrel.name,
        'gunSight': gunSight.name,
        'gunAmmo': gunAmmo.name,
        'staffFocus': staffFocus.name,
        'bladeEdge': bladeEdge.name,
      };

  factory WeaponLoadout.fromJson(Map<String, dynamic>? j) {
    if (j == null) return WeaponLoadout();
    return WeaponLoadout(
      gunBarrel: GunBarrelMod.values.firstWhere((e) => e.name == j['gunBarrel'], orElse: () => GunBarrelMod.none),
      gunSight: GunSightMod.values.firstWhere((e) => e.name == j['gunSight'], orElse: () => GunSightMod.none),
      gunAmmo: GunAmmoMod.values.firstWhere((e) => e.name == j['gunAmmo'], orElse: () => GunAmmoMod.none),
      staffFocus: StaffFocusMod.values.firstWhere((e) => e.name == j['staffFocus'], orElse: () => StaffFocusMod.none),
      bladeEdge: BladeEdgeMod.values.firstWhere((e) => e.name == j['bladeEdge'], orElse: () => BladeEdgeMod.none),
    );
  }
}

class HighScoreEntry {
  final String name;
  final int score, seconds, floor, level;
  final bool completed, arena;
  final String difficulty, playerClass;
  final List<String> topRelics;
  HighScoreEntry(
    this.name,
    this.score,
    this.seconds, {
    this.floor = 1,
    this.level = 1,
    this.completed = false,
    this.difficulty = 'normal',
    this.arena = false,
    this.playerClass = 'xenos',
    this.topRelics = const [],
  });
  String get timeStr => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  String get progressStr {
    if (arena) return 'АРЕНА • ${difficulty.toUpperCase()} • $playerClass';
    if (completed) return 'ВСЁ • ${difficulty.toUpperCase()} • $playerClass';
    return 'Этаж $floor / Ур. $level';
  }
  String get relicsStr => topRelics.isEmpty ? '' : topRelics.take(2).join(', ');
  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'seconds': seconds,
        'floor': floor,
        'level': level,
        'completed': completed,
        'difficulty': difficulty,
        'arena': arena,
        'playerClass': playerClass,
        'topRelics': topRelics,
      };
  factory HighScoreEntry.fromJson(Map<String, dynamic> j) => HighScoreEntry(
        j['name'] as String? ?? '?',
        j['score'] as int? ?? 0,
        j['seconds'] as int? ?? 0,
        floor: j['floor'] as int? ?? 1,
        level: j['level'] as int? ?? 1,
        completed: j['completed'] as bool? ?? false,
        difficulty: j['difficulty'] as String? ?? 'normal',
        arena: j['arena'] as bool? ?? false,
        playerClass: j['playerClass'] as String? ?? 'xenos',
        topRelics: (j['topRelics'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

/// Run-local narrative state. Optional fields are stored inside the existing custom JSON map,
/// so older saves remain readable without a schema migration.
class CampaignState {
  int suspicion = 0; // scrutiny from the conclave (0..100)
  int evidence = 0;
  int fieldWounds = 0;
  int operationsCompleted = 0;
  int cluesFound = 0;
  int alarm = 0;
  int oathIntegrity = 100;
  int alliesRecruited = 0;
  String lastReport = 'Досье ожидает первого полевого отчёта.';
  String missionApproach = 'balanced';
  int evidencePreserved = 0;
  int evidenceDestroyed = 0;
  int informantDebt = 0;
  int consequenceScore = 0;

  Map<String, dynamic> toJson() => {
    'suspicion': suspicion, 'evidence': evidence, 'fieldWounds': fieldWounds,
    'operationsCompleted': operationsCompleted, 'cluesFound': cluesFound,
    'alarm': alarm, 'oathIntegrity': oathIntegrity, 'alliesRecruited': alliesRecruited,
    'lastReport': lastReport, 'missionApproach': missionApproach,
    'evidencePreserved': evidencePreserved, 'evidenceDestroyed': evidenceDestroyed,
    'informantDebt': informantDebt, 'consequenceScore': consequenceScore,
  };

  void load(Map<String, dynamic>? data) {
    if (data == null) return;
    suspicion = ((data['suspicion'] as num?)?.toInt() ?? 0).clamp(0, 100).toInt();
    evidence = max(0, (data['evidence'] as num?)?.toInt() ?? 0);
    fieldWounds = ((data['fieldWounds'] as num?)?.toInt() ?? 0).clamp(0, 3).toInt();
    operationsCompleted = max(0, (data['operationsCompleted'] as num?)?.toInt() ?? 0);
    cluesFound = max(0, (data['cluesFound'] as num?)?.toInt() ?? 0);
    alarm = ((data['alarm'] as num?)?.toInt() ?? 0).clamp(0, 100).toInt();
    oathIntegrity = ((data['oathIntegrity'] as num?)?.toInt() ?? 100).clamp(0, 100).toInt();
    alliesRecruited = max(0, (data['alliesRecruited'] as num?)?.toInt() ?? 0);
    lastReport = data['lastReport'] as String? ?? 'Досье ожидает первого полевого отчёта.';
    missionApproach = data['missionApproach'] as String? ?? 'balanced';
    evidencePreserved = max(0, (data['evidencePreserved'] as num?)?.toInt() ?? 0);
    evidenceDestroyed = max(0, (data['evidenceDestroyed'] as num?)?.toInt() ?? 0);
    informantDebt = max(0, (data['informantDebt'] as num?)?.toInt() ?? 0);
    consequenceScore = (data['consequenceScore'] as num?)?.toInt() ?? 0;
  }

  void resetForNewRun() {
    suspicion = 0;
    evidence = 0;
    fieldWounds = 0;
    operationsCompleted = 0;
    cluesFound = 0;
    alarm = 0;
    oathIntegrity = 100;
    alliesRecruited = 0;
    lastReport = 'Клятва принята. Первичная разведка не завершена.';
    missionApproach = 'balanced';
    evidencePreserved = 0; evidenceDestroyed = 0; informantDebt = 0; consequenceScore = 0;
  }
}

class OrdoOath {
  final String title;
  final String threat;
  final String dogma;
  final String oath;
  final String fieldDoctrine;
  final String bonus;
  const OrdoOath(this.title, this.threat, this.dogma, this.oath, this.fieldDoctrine, this.bonus);

  static OrdoOath forClass(PlayerClass cls) {
    switch (cls) {
      case PlayerClass.malleus:
        return const OrdoOath(
          'ORDO MALLEUS — ВРАГ ЗА ЗАВЕСОЙ', 'Демоны, варп-разломы и ритуалы призыва',
          'Не доверяй шёпоту из-за Завесы. Изучи угрозу, укрепи печать и не дай врагу закрепиться в реальности.',
          'Клянусь не склоняться перед ужасом Варпа. Я разорву круги призыва, запечатаю разломы и уничтожу сущность, посягнувшую на владения Императора. Если моя воля дрогнет, пусть меня судят той же мерой, что и врага.',
          'ЭКЗОРЦИЗМ: при высокой порче варпа временно усиливается защита; опасные варп-цели раскрывают больше улик.',
          'Полевой бонус: +8% урона демоническим и варп-целям; стабильность варпа важнее жадности.'
        );
      case PlayerClass.hereticus:
        return const OrdoOath(
          'ORDO HERETICUS — ВРАГ ВНУТРИ', 'Культы, ересь, мутации и опасные псайкеры',
          'Ересь не всегда носит знамя. Сверяй свидетельства, ищи скрытые связи и не позволяй ложной добродетели прикрывать угрозу Империуму.',
          'Клянусь оберегать веру Императора и вскрывать гниль под маской лояльности. Я разоблачу культ, пресеку распространение ереси и не позволю предательству укорениться среди тех, кого обязан защищать.',
          'ДОПРОС: культисты и псайкеры чаще оставляют улики; чистое завершение операции снижает подозрение конклава.',
          'Полевой бонус: +8% урона культистам и псайкерам; улики ценнее грубой силы.'
        );
      case PlayerClass.xenos:
        return const OrdoOath(
          'ORDO XENOS — ВРАГ СНАРУЖИ', 'Ксеносы, инфильтрация и чуждая технология',
          'Изучай противника, чтобы предвидеть его действия, но не путай знание с верностью. Чуждая технология всегда требует контроля.',
          'Клянусь защищать человечество от чуждых видов и их скрытого влияния. Я выявлю проникновение ксеносов, изучу тактику врага и обращу знание против него. Ни любопытство, ни выгода не станут оправданием гибели Империума.',
          'КСЕНОПРОФИЛЬ: элитные и необычные враги чаще раскрывают тактические данные; знание противника помогает подготовке.',
          'Полевой бонус: +8% урона элитным и бронированным целям; анализ врага открывает тактические награды.'
        );
    }
  }
}

class GameSave {
  final String name;
  final int floor, level, score, health, maxHealth, scraps;
  final int bolterDamage, rifleDamage, shotgunDamage, swordDamage, axeDamage, hammerDamage;
  final double playerSpeed, defenseChance;
  final String ranged, melee;
  final bool usingMelee, hasDash, hasLaser, ever11, ever21;
  final int playSeconds;
  final String dateIso, difficulty, playerClass, artifact, lastEcho, challenge;
  final bool arenaMode;
  final int arenaKills, skillPoints, pathIndex;
  final Map<String, dynamic> skills, custom, loadout, mastery;
  final List<String> relics, codex;
  final Map<String, int> loreRanks; // id -> times accepted (0..2)

  GameSave({
    required this.name,
    required this.floor,
    required this.level,
    required this.score,
    required this.health,
    required this.maxHealth,
    required this.scraps,
    required this.bolterDamage,
    required this.rifleDamage,
    required this.shotgunDamage,
    required this.swordDamage,
    required this.axeDamage,
    required this.hammerDamage,
    required this.playerSpeed,
    required this.defenseChance,
    required this.ranged,
    required this.melee,
    required this.usingMelee,
    required this.hasDash,
    required this.hasLaser,
    required this.ever11,
    required this.ever21,
    required this.playSeconds,
    required this.dateIso,
    this.difficulty = 'normal',
    this.arenaMode = false,
    this.arenaKills = 0,
    this.skillPoints = 0,
    this.skills = const {},
    this.custom = const {},
    this.playerClass = 'xenos',
    this.relics = const [],
    this.artifact = 'fragGrenade',
    this.loadout = const {},
    this.codex = const [],
    this.lastEcho = 'none',
    this.mastery = const {},
    this.challenge = 'none',
    this.pathIndex = 0,
    this.loreRanks = const {},
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'floor': floor,
        'level': level,
        'score': score,
        'health': health,
        'maxHealth': maxHealth,
        'scraps': scraps,
        'bolterDamage': bolterDamage,
        'rifleDamage': rifleDamage,
        'shotgunDamage': shotgunDamage,
        'swordDamage': swordDamage,
        'axeDamage': axeDamage,
        'hammerDamage': hammerDamage,
        'playerSpeed': playerSpeed,
        'defenseChance': defenseChance,
        'ranged': ranged,
        'melee': melee,
        'usingMelee': usingMelee,
        'hasDash': hasDash,
        'hasLaser': hasLaser,
        'ever11': ever11,
        'ever21': ever21,
        'playSeconds': playSeconds,
        'dateIso': dateIso,
        'difficulty': difficulty,
        'arenaMode': arenaMode,
        'arenaKills': arenaKills,
        'skillPoints': skillPoints,
        'skills': skills,
        'custom': custom,
        'playerClass': playerClass,
        'relics': relics,
        'artifact': artifact,
        'loadout': loadout,
        'codex': codex,
        'lastEcho': lastEcho,
        'mastery': mastery,
        'challenge': challenge,
        'pathIndex': pathIndex,
        'loreRanks': loreRanks,
      };

  factory GameSave.fromJson(Map<String, dynamic> j) => GameSave(
        name: j['name'] as String? ?? 'Inquisitor',
        floor: j['floor'] as int? ?? 1,
        level: j['level'] as int? ?? 1,
        score: j['score'] as int? ?? 0,
        health: j['health'] as int? ?? 6,
        maxHealth: j['maxHealth'] as int? ?? 6,
        scraps: j['scraps'] as int? ?? 0,
        bolterDamage: j['bolterDamage'] as int? ?? 8,
        rifleDamage: j['rifleDamage'] as int? ?? 18,
        shotgunDamage: j['shotgunDamage'] as int? ?? 10,
        swordDamage: j['swordDamage'] as int? ?? 12,
        axeDamage: j['axeDamage'] as int? ?? 14,
        hammerDamage: j['hammerDamage'] as int? ?? 28,
        playerSpeed: (j['playerSpeed'] as num?)?.toDouble() ?? 210,
        defenseChance: (j['defenseChance'] as num?)?.toDouble() ?? 0,
        ranged: j['ranged'] as String? ?? 'bolter',
        melee: j['melee'] as String? ?? 'sword',
        usingMelee: j['usingMelee'] as bool? ?? false,
        hasDash: j['hasDash'] as bool? ?? false,
        hasLaser: j['hasLaser'] as bool? ?? false,
        ever11: j['ever11'] as bool? ?? false,
        ever21: j['ever21'] as bool? ?? false,
        playSeconds: j['playSeconds'] as int? ?? 0,
        dateIso: j['dateIso'] as String? ?? '',
        difficulty: j['difficulty'] as String? ?? 'normal',
        arenaMode: j['arenaMode'] as bool? ?? false,
        arenaKills: j['arenaKills'] as int? ?? 0,
        skillPoints: j['skillPoints'] as int? ?? 0,
        skills: Map<String, dynamic>.from(j['skills'] as Map? ?? {}),
        custom: Map<String, dynamic>.from(j['custom'] as Map? ?? {}),
        playerClass: j['playerClass'] as String? ?? 'xenos',
        relics: (j['relics'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        artifact: j['artifact'] as String? ?? 'fragGrenade',
        loadout: Map<String, dynamic>.from(j['loadout'] as Map? ?? {}),
        codex: (j['codex'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        lastEcho: j['lastEcho'] as String? ?? 'none',
        mastery: Map<String, dynamic>.from(j['mastery'] as Map? ?? {}),
        challenge: j['challenge'] as String? ?? 'none',
        pathIndex: j['pathIndex'] as int? ?? 0,
        loreRanks: Map<String, int>.from(
          (j['loreRanks'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
        ),
      );

  String get dateStr {
    try {
      final d = DateTime.parse(dateIso);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateIso;
    }
  }
}

/// Expanding class-colored pulse used by active Ordo abilities and skill unlocks.
class OrdoPulseEffect extends PositionComponent {
  final Color color;
  final double maxRadius;
  final double life;
  double age = 0;
  OrdoPulseEffect({required Vector2 position, required this.color, this.maxRadius = 180, this.life = 0.8})
      : super(position: position.clone(), priority: 40);
  @override
  void update(double dt) { super.update(dt); age += dt; if (age >= life) removeFromParent(); }
  @override
  void render(Canvas canvas) {
    final t = (age / life).clamp(0.0, 1.0);
    final radius = maxRadius * Curves.easeOutCubic.transform(t);
    final alpha = (1.0 - t).clamp(0.0, 1.0);
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color.withOpacity(0.10 * alpha)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color.withOpacity(0.9 * alpha)..style = PaintingStyle.stroke..strokeWidth = 3.0 * (1.0 - t * 0.55));
    canvas.drawCircle(Offset.zero, radius * 0.68, Paint()..color = color.withOpacity(0.35 * alpha)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }
}

/// Soft periodic halo around the player when an Ordo passive is unlocked.
class OrdoPassivePulse extends PositionComponent {
  final Color color;
  double age = 0;
  OrdoPassivePulse({required Vector2 position, required this.color}) : super(position: position, priority: 21);
  @override
  void update(double dt) { super.update(dt); age += dt; if (age > 0.62) removeFromParent(); }
  @override
  void render(Canvas canvas) {
    final t = (age / 0.62).clamp(0.0, 1.0);
    final radius = 26 + 42 * t;
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color.withOpacity(0.34 * (1 - t))..style = PaintingStyle.stroke..strokeWidth = 2.0);
  }
}

/// A brief red targeting slash from the Inquisitor to the selected target.
class OrdoJudgmentEffect extends PositionComponent {
  final Vector2 targetOffset;
  final Color color;
  final double life;
  double age = 0;
  OrdoJudgmentEffect({required Vector2 position, required this.targetOffset, required this.color, this.life = 0.42}) : super(position: position.clone(), priority: 42);
  @override
  void update(double dt) { super.update(dt); age += dt; if (age >= life) removeFromParent(); }
  @override
  void render(Canvas canvas) {
    final t = (age / life).clamp(0.0, 1.0);
    final alpha = (1 - t).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withOpacity(alpha)..strokeWidth = 5 * (1 - t * 0.65)..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(targetOffset.x, targetOffset.y), paint);
    canvas.drawCircle(Offset(targetOffset.x, targetOffset.y), 15 + t * 24, Paint()..color = color.withOpacity(alpha * 0.65)..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }
}

/// Draws the active Ordo ability cooldown directly over its HUD button.
class OrdoAbilityCooldownHud extends PositionComponent with HasGameReference<InquisitorGame> {
  OrdoAbilityCooldownHud() : super(priority: 201);
  @override
  void update(double dt) {
    super.update(dt);
    position = Vector2(game.abilityClusterLeft + game.buttonSize * 5.4 + game.buttonSize * 0.45,
      game.size.y - game.abilityClusterBottom - game.buttonSize * 0.45);
  }
  @override
  void render(Canvas canvas) {
    final cooldown = game.ordoAbilityCooldown;
    if (cooldown <= 0) return;
    final total = game.playerClass == PlayerClass.malleus ? 13.0 : 11.0;
    final progress = (cooldown / total).clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: game.buttonSize * 0.49), -pi / 2, 2 * pi * progress, false,
      Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round);
    final tp = TextPainter(text: TextSpan(text: cooldown.ceil().toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 3)])), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

class DamageNumber extends PositionComponent {
  final int amount;
  final Color color;
  double life = 0.85;
  double vy = -55;
  final String? label;
  DamageNumber({required Vector2 position, required this.amount, this.color = const Color(0xFFFFEB3B), this.label})
      : super(position: position.clone(), priority: 100);
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position.y += vy * dt;
    vy *= 0.98;
    if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 0.85).clamp(0.0, 1.0);
    final text = label ?? (amount > 0 ? '-$amount' : '');
    if (text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(a),
          fontSize: label != null ? 14 : 18,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black.withOpacity(a), blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

class BloodSplash extends PositionComponent {
  final List<_Drop> drops = [];
  double life = 1.4;
  BloodSplash({required Vector2 position, int count = 14, Vector2? fromDir})
      : super(position: position.clone(), priority: 8) {
    final rnd = Random();
    final baseAng = fromDir != null && fromDir.length2 > 0.01 ? atan2(fromDir.y, fromDir.x) : rnd.nextDouble() * 2 * pi;
    for (int i = 0; i < count; i++) {
      final a = baseAng + (rnd.nextDouble() - 0.5) * 1.4;
      final sp = 40 + rnd.nextDouble() * 120;
      drops.add(_Drop(
        offset: Vector2.zero(),
        vel: Vector2(cos(a), sin(a)) * sp,
        radius: 2 + rnd.nextDouble() * 4.5,
        dark: rnd.nextBool(),
      ));
    }
  }
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    for (final d in drops) {
      d.vel.y += 280 * dt;
      d.offset += d.vel * dt;
      d.vel *= 0.92;
    }
    if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 1.4).clamp(0.0, 1.0);
    for (final d in drops) {
      canvas.drawCircle(
        Offset(d.offset.x, d.offset.y),
        d.radius * (0.6 + 0.4 * a),
        Paint()..color = d.dark ? Color.fromRGBO(120, 0, 0, 0.85 * a) : Color.fromRGBO(200, 16, 16, 0.9 * a),
      );
    }
  }
}

class _Drop {
  Vector2 offset, vel;
  double radius;
  bool dark;
  _Drop({required this.offset, required this.vel, required this.radius, required this.dark});
}

class KillExplosion extends CircleComponent {
  double life = 0.35;
  final int damage;
  final bool applyBurn;
  KillExplosion({required Vector2 position, required double radius, required this.damage, this.applyBurn = false})
      : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFFFF6D00).withOpacity(0.45),
          priority: 12,
        );
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    paint.color = Color.fromRGBO(255, 109, 0, (life / 0.35 * 0.45).clamp(0.0, 0.45));
    if (life <= 0) removeFromParent();
  }
}

class ComboBanner extends PositionComponent with HasGameReference<InquisitorGame> {
  double life = 1.2;
  final int combo;
  ComboBanner({required this.combo}) : super(priority: 200);
  @override
  void onMount() {
    super.onMount();
    position = Vector2(game.size.x / 2 - 40, 120);
  }
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position.y -= 20 * dt;
    if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 1.2).clamp(0.0, 1.0);
    final tp = TextPainter(
      text: TextSpan(text: 'COMBO x$combo', style: TextStyle(color: Color.fromRGBO(255, 215, 0, a), fontSize: 22, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset.zero);
  }
}

class AfterImage extends PositionComponent {
  double life = 0.28;
  final double maxLife = 0.28;
  final PlayerClass cls;
  final Customization? custom;
  AfterImage({required Vector2 position, required this.cls, this.custom})
      : super(position: position.clone(), size: Vector2(76, 86), anchor: Anchor.center, priority: 14);
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / maxLife).clamp(0.0, 1.0) * 0.45;
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, a));
    WHDraw.inquisitor(canvas, cx: size.x / 2, cy: size.y / 2, s: 1.25, custom: custom, cls: cls);
    canvas.restore();
  }
}

enum BossHitZoneKind { core, head, limb, armor }

class BossHitZoneOutcome {
  final BossHitZoneKind zone;
  final double multiplier;
  final String label;
  const BossHitZoneOutcome(this.zone, this.multiplier, this.label);
}

/// Resolves a projectile/melee contact against normalized boss-local coordinates.
/// The core is only a high-damage target while the boss is in its exposed phase.
BossHitZoneOutcome resolveBossHitZone({
  required Vector2 impact,
  required Vector2 center,
  required Vector2 size,
  bool exposed = false,
}) {
  final w = max(1.0, size.x), h = max(1.0, size.y);
  final x = ((impact.x - (center.x - w / 2)) / w).clamp(0.0, 1.0);
  final y = ((impact.y - (center.y - h / 2)) / h).clamp(0.0, 1.0);
  if ((x - 0.5).abs() <= 0.15 && y >= 0.30 && y <= 0.57) {
    return exposed
        ? const BossHitZoneOutcome(BossHitZoneKind.core, 1.8, 'ЯДРО • КРИТИЧЕСКОЕ ПОПАДАНИЕ')
        : const BossHitZoneOutcome(BossHitZoneKind.armor, 0.72, 'ЯДРО ЗАКРЫТО');
  }
  if ((x - 0.5).abs() <= 0.13 && y < 0.30) {
    return const BossHitZoneOutcome(BossHitZoneKind.head, 1.4, 'ГОЛОВА • ТОЧНОЕ ПОПАДАНИЕ');
  }
  if ((x < 0.24 || x > 0.76) && y > 0.42) {
    return const BossHitZoneOutcome(BossHitZoneKind.limb, 0.9, 'КОНЕЧНОСТЬ');
  }
  return const BossHitZoneOutcome(BossHitZoneKind.armor, 0.72, 'БРОНЯ');
}

void drawBossHitZones(Canvas canvas, Vector2 size, {bool exposed = false}) {
  final cx = size.x / 2, cy = size.y / 2;
  final pulse = 0.55 + 0.45 * sin(DateTime.now().millisecondsSinceEpoch / 170).abs();
  final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.7;
  canvas.drawCircle(Offset(cx, cy - size.y * 0.30), size.x * 0.105,
      outline..color = const Color(0xFFFFD180).withOpacity(0.38));
  canvas.drawCircle(Offset(cx - size.x * 0.30, cy + size.y * 0.12), size.x * 0.075,
      outline..color = const Color(0xFF80DEEA).withOpacity(0.32));
  canvas.drawCircle(Offset(cx + size.x * 0.30, cy + size.y * 0.12), size.x * 0.075,
      outline..color = const Color(0xFF80DEEA).withOpacity(0.32));
  canvas.drawCircle(Offset(cx, cy - size.y * 0.05), size.x * 0.13,
      outline..color = (exposed ? const Color(0xFFFF1744) : const Color(0xFFFFD54F)).withOpacity(exposed ? pulse : 0.24));
  if (exposed) {
    canvas.drawCircle(Offset(cx, cy - size.y * 0.05), size.x * 0.18,
        outline..color = const Color(0xFFFF1744).withOpacity(0.55));
  }
}

class TelegraphZone extends PositionComponent {
  final String shape;
  final double radius;
  final double angle;
  final Color color;
  double life;
  final double maxLife;
  TelegraphZone({required Vector2 position, required this.shape, required this.radius, this.angle = 0, this.life = 0.75, this.color = const Color(0xFFFF3030)})
      : maxLife = life,
        super(position: position.clone(), anchor: Anchor.center, priority: 6);
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final t = (1 - life / maxLife).clamp(0.0, 1.0);
    final a = 0.25 + 0.45 * t;
    final p = Paint()
      ..color = Color.fromRGBO(color.red, color.green, color.blue, a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fill = Paint()..color = Color.fromRGBO(color.red, color.green, color.blue, a * 0.25);
    if (shape == 'circle') {
      canvas.drawCircle(Offset.zero, radius, fill);
      canvas.drawCircle(Offset.zero, radius, p);
    } else if (shape == 'cone') {
      final path = Path()..moveTo(0, 0);
      path.arcTo(Rect.fromCircle(center: Offset.zero, radius: radius), angle - 0.55, 1.1, false);
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, p);
    } else if (shape == 'cross') {
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: radius * 2, height: 28), fill);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 28, height: radius * 2), fill);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: radius * 2, height: 28), p);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 28, height: radius * 2), p);
    }
    // Canvas-rendered telegraph label remains readable without Flutter overlays.
    final painter = TextPainter(
      text: const TextSpan(text: 'УКЛОНИСЬ!', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 110);
    painter.paint(canvas, Offset(-painter.width / 2, -max(28.0, radius * 0.62)));
    canvas.drawCircle(Offset.zero, 10 + 2 * t, Paint()..color = color.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }
}

/// Telegraphed, fully procedural Warp anomaly. It never uses image assets and is easy to avoid.
class WarpRift extends PositionComponent with HasGameReference<InquisitorGame> {
  double age = 0;
  double pulse = 0;
  double damageClock = 1.2;
  WarpRift({required Vector2 position})
      : super(position: position, size: Vector2(116, 116), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    age += dt;
    pulse += dt;
    damageClock -= dt;
    final distance = position.distanceTo(game.player.position);
    if (distance < 68 && damageClock <= 0) {
      damageClock = 2.4;
      game.player.takeDamage(1);
      game.player.applyStatus(StatusType.corruption, 1.6, tickDamage: 0);
      game.spawnDamageNumber(game.player.position, 0, color: const Color(0xFFCE93D8), label: 'ВАРП');
    }
    // Rift is temporary; old hazards collapse to prevent clutter/performance degradation.
    if (age > 24) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final beat = (sin(pulse * 3.2) + 1) / 2;
    final outer = 30 + beat * 5;
    final glow = Paint()..color = const Color(0xFFAB47BC).withOpacity(0.10 + beat * 0.10);
    canvas.drawCircle(c, outer + 12, glow);
    for (int i = 0; i < 3; i++) {
      final r = outer - i * 8.0;
      canvas.drawCircle(c, r, Paint()..color = Color.lerp(const Color(0xFF6A1B9A), const Color(0xFFE1BEE7), (beat + i * 0.18).clamp(0.0, 1.0).toDouble())!.withOpacity(0.65 - i * 0.12)..style = PaintingStyle.stroke..strokeWidth = 2.2 - i * 0.35);
    }
    final tear = Path()
      ..moveTo(c.dx, c.dy - 24)
      ..quadraticBezierTo(c.dx + 18 * sin(pulse), c.dy - 4, c.dx + 3, c.dy + 20)
      ..quadraticBezierTo(c.dx - 18 * cos(pulse * 0.7), c.dy + 4, c.dx, c.dy - 24)
      ..close();
    canvas.drawPath(tear, Paint()..color = const Color(0xFF311B92).withOpacity(0.85));
    canvas.drawPath(tear, Paint()..color = const Color(0xFFE1BEE7).withOpacity(0.75)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    // Warning ticks communicate the danger radius before the player enters it.
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4 + pulse * 0.15;
      canvas.drawLine(Offset(c.dx + cos(a) * 42, c.dy + sin(a) * 42), Offset(c.dx + cos(a) * 48, c.dy + sin(a) * 48), Paint()..color = const Color(0xFFE1BEE7).withOpacity(0.55)..strokeWidth = 1.5);
    }
  }
}

class CorruptionZone extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  double life = 12.0;
  double tickAcc = 0;
  CorruptionZone({required Vector2 position})
      : super(position: position.clone(), size: Vector2(90, 90), anchor: Anchor.center, priority: 4);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 40));
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) {
      removeFromParent();
      return;
    }
    tickAcc += dt;
    if (tickAcc >= 0.6) {
      tickAcc = 0;
      if (game.isPlaying && !game.isPaused && position.distanceTo(game.player.position) < 48) {
        game.player.applyStatus(StatusType.corruption, 1.2, tickDamage: 1);
        game.player.takeDamage(1);
      }
    }
  }
  void purify() {
    game.spawnDamageNumber(position, 0, color: const Color(0xFF81D4FA), label: 'ОЧИЩЕНО');
    removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 12.0).clamp(0.2, 1.0);
    final cx = size.x / 2, cy = size.y / 2;
    canvas.drawCircle(Offset(cx, cy), 40, Paint()..color = Color.fromRGBO(156, 39, 176, 0.35 * a));
    canvas.drawCircle(Offset(cx, cy), 40, Paint()
      ..color = Color.fromRGBO(186, 104, 200, 0.6 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawCircle(Offset(cx, cy), 12 + 6 * sin(life * 3), Paint()..color = Color.fromRGBO(224, 64, 251, 0.5 * a));
  }
}

/// Bullet trail segment (visual only)
class BulletTrail extends PositionComponent {
  double life = 0.12;
  final Color color;
  final Vector2 from;
  final Vector2 to;
  BulletTrail({required this.from, required this.to, required this.color})
      : super(position: from.clone(), priority: 12);
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 0.12).clamp(0.0, 1.0);
    canvas.drawLine(
      Offset.zero,
      Offset(to.x - from.x, to.y - from.y),
      Paint()
        ..color = color.withOpacity(0.55 * a)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }
}
class WHDraw {
  static void _rivets(Canvas c, double cx, double cy, double w, double h, Color col, double s) {
    final p = Paint()..color = col;
    for (final dx in [-w * 0.35, w * 0.35]) {
      for (final dy in [-h * 0.3, h * 0.3]) {
        c.drawCircle(Offset(cx + dx * s, cy + dy * s), 1.6 * s, p);
      }
    }
  }

  static void _armorPlate(Canvas c, Rect r, Color col, Color edge) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = col);
    c.drawRRect(
      RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(2)),
      Paint()
        ..color = edge.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    c.drawLine(
      Offset(r.left + 4, r.top + 3),
      Offset(r.right - 4, r.top + 3),
      Paint()..color = Colors.white.withOpacity(0.12)..strokeWidth = 1.2,
    );
  }

  /// Procedural engraving, purity stamp and energy detail helpers; no image assets required.
  static void puritySeal(Canvas c, Offset anchor, double scale, Color wax, Color parchment) {
    final paper = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..lineTo(anchor.dx + 5 * scale, anchor.dy + 15 * scale)
      ..lineTo(anchor.dx + 1 * scale, anchor.dy + 25 * scale)
      ..lineTo(anchor.dx - 4 * scale, anchor.dy + 13 * scale)
      ..close();
    c.drawPath(paper, Paint()..color = parchment.withOpacity(0.95));
    c.drawPath(paper, Paint()..color = const Color(0xFF6D4C41).withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = scale);
    c.drawCircle(anchor, 4.2 * scale, Paint()..color = wax);
    c.drawCircle(anchor, 2.1 * scale, Paint()..color = const Color(0xFFFFD54F));
    c.drawLine(anchor + Offset(0, 5 * scale), anchor + Offset(0, 11 * scale), Paint()..color = const Color(0xFF4E342E)..strokeWidth = scale);
  }

  static void engravedRunes(Canvas c, Offset center, double radius, Color color, double scale, {int count = 7}) {
    final p = Paint()..color = color.withOpacity(0.75)..strokeWidth = 1.1 * scale..strokeCap = StrokeCap.square;
    for (var i = 0; i < count; i++) {
      final a = (i / count) * pi * 2;
      final inner = radius * 0.72;
      final outer = radius;
      final start = center + Offset(cos(a) * inner, sin(a) * inner);
      final end = center + Offset(cos(a) * outer, sin(a) * outer);
      c.drawLine(start, end, p);
      c.drawLine(end, end + Offset(cos(a + 0.25) * 3 * scale, sin(a + 0.25) * 3 * scale), p);
    }
  }

  static void energyArc(Canvas c, Offset center, double radius, Color color, double phase, double scale) {
    final path = Path();
    for (var i = 0; i <= 12; i++) {
      final a = phase + i / 12 * pi * 1.65;
      final jitter = (i.isEven ? 1.0 : 0.82) * radius;
      final pt = center + Offset(cos(a) * jitter, sin(a) * jitter);
      if (i == 0) { path.moveTo(pt.dx, pt.dy); } else { path.lineTo(pt.dx, pt.dy); }
    }
    c.drawPath(path, Paint()..color = color.withOpacity(0.24)..style = PaintingStyle.stroke..strokeWidth = 5 * scale..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    c.drawPath(path, Paint()..color = color.withOpacity(0.9)..style = PaintingStyle.stroke..strokeWidth = 1.4 * scale..strokeCap = StrokeCap.round);
  }

  static void inquisitor(Canvas c, {required double cx, required double cy, double s = 1.32, double flash = 0, Customization? custom, PlayerClass cls = PlayerClass.xenos, double healthRatio = 1.0}) {
    Color armor = custom?.armorColor(0.30) ?? const Color(0xFF3A4A55);
    Color armorLite = custom?.armorColor(0.42) ?? const Color(0xFF4A5A68);
    Color dark = custom?.armorColor(0.16) ?? const Color(0xFF1E2830);
    Color gold = custom?.trimColor(0.55) ?? const Color(0xFFC9A227);
    Color capeCol = custom?.capeColor(0.28) ?? const Color(0xFF8B0000);
    Color visor = const Color(0xFFFF1744);
    switch (cls) {
      case PlayerClass.xenos:
        armor = custom?.armorColor(0.28) ?? const Color(0xFF37474F);
        armorLite = custom?.armorColor(0.40) ?? const Color(0xFF546E7A);
        dark = custom?.armorColor(0.14) ?? const Color(0xFF1C2830);
        capeCol = custom?.capeColor(0.30) ?? const Color(0xFFB71C1C);
        visor = const Color(0xFFFF1744);
        gold = custom?.trimColor(0.55) ?? const Color(0xFFFFD700);
        break;
      case PlayerClass.malleus:
        armor = custom?.armorColor(0.26) ?? const Color(0xFF1A237E);
        armorLite = const Color(0xFF283593);
        dark = const Color(0xFF0D1333);
        capeCol = const Color(0xFF311B92);
        visor = const Color(0xFFB388FF);
        gold = const Color(0xFFE1BEE7);
        break;
      case PlayerClass.hereticus:
        armor = custom?.armorColor(0.22) ?? const Color(0xFF1A1A1A);
        armorLite = const Color(0xFF2D2D2D);
        dark = const Color(0xFF0A0A0A);
        capeCol = const Color(0xFF4A148C);
        visor = const Color(0xFFE040FB);
        gold = const Color(0xFFCE93D8);
        break;
    }
    final capeBack = Path()
      ..moveTo(cx - 12 * s, cy + 2 * s)
      ..quadraticBezierTo(cx - 56 * s, cy + 28 * s, cx - 20 * s, cy + 62 * s)
      ..lineTo(cx + 20 * s, cy + 62 * s)
      ..quadraticBezierTo(cx + 56 * s, cy + 28 * s, cx + 12 * s, cy + 2 * s)
      ..close();
    c.drawPath(capeBack, Paint()..color = capeCol.withOpacity(0.55));
    final cape = Path()
      ..moveTo(cx - 14 * s, cy)
      ..quadraticBezierTo(cx - 50 * s, cy + 30 * s, cx - 16 * s, cy + 56 * s)
      ..lineTo(cx + 16 * s, cy + 56 * s)
      ..quadraticBezierTo(cx + 50 * s, cy + 30 * s, cx + 14 * s, cy)
      ..close();
    c.drawPath(cape, Paint()..color = capeCol.withOpacity(0.92));
    c.drawPath(cape, Paint()..color = gold.withOpacity(0.28)..style = PaintingStyle.stroke..strokeWidth = 1.6 * s);
    for (final lx in [-11.0, 11.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + lx * s, cy + 32 * s), width: 14 * s, height: 28 * s), Radius.circular(2 * s)), Paint()..color = armor);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + lx * s, cy + 28 * s), width: 16 * s, height: 8 * s), Radius.circular(2 * s)), Paint()..color = armorLite);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + lx * s, cy + 44 * s), width: 16 * s, height: 8 * s), Radius.circular(2 * s)), Paint()..color = dark);
    }
    _armorPlate(c, Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 40 * s, height: 38 * s), armor, gold);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 26 * s, height: 24 * s), Radius.circular(4 * s)), Paint()..color = armorLite);
    _rivets(c, cx, cy + 4 * s, 36, 30, gold.withOpacity(0.7), s);
    c.drawCircle(Offset(cx, cy + 4 * s), 8 * s, Paint()..color = gold);
    c.drawCircle(Offset(cx, cy + 4 * s), 4 * s, Paint()..color = dark);
    // Deathwatch/Inquisition-inspired cross insignia, assembled from vector strokes.
    final sigil = Paint()..color = gold.withOpacity(0.9)..strokeWidth = 1.8 * s..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - 5 * s, cy + 4 * s), Offset(cx + 5 * s, cy + 4 * s), sigil);
    c.drawLine(Offset(cx, cy - 1 * s), Offset(cx, cy + 9 * s), sigil);
    if (cls == PlayerClass.malleus) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 30 * s), width: 30 * s, height: 16 * s), Radius.circular(6 * s)), Paint()..color = const Color(0xFF4527A0));
      c.drawCircle(Offset(cx, cy - 32 * s), 6 * s, Paint()..color = visor.withOpacity(0.75));
    }
    if (cls == PlayerClass.hereticus) {
      final hood = Path()
        ..moveTo(cx - 14 * s, cy - 14 * s)
        ..lineTo(cx, cy - 28 * s)
        ..lineTo(cx + 14 * s, cy - 14 * s)
        ..close();
      c.drawPath(hood, Paint()..color = dark);
    }
    if (cls == PlayerClass.xenos) {
      c.drawLine(Offset(cx + 16 * s, cy + 10 * s), Offset(cx + 22 * s, cy + 28 * s), Paint()..color = const Color(0xFFFFF8E1)..strokeWidth = 2 * s);
      c.drawCircle(Offset(cx + 16 * s, cy + 10 * s), 3 * s, Paint()..color = gold);
    }
    c.drawCircle(Offset(cx - 24 * s, cy - 4 * s), 15 * s, Paint()..color = armor);
    c.drawCircle(Offset(cx + 24 * s, cy - 4 * s), 15 * s, Paint()..color = armor);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 28 * s, cy + 16 * s), width: 12 * s, height: 24 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 28 * s, cy + 16 * s), width: 12 * s, height: 24 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawCircle(Offset(cx, cy - 18 * s), 13 * s, Paint()..color = const Color(0xFFC4A484));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 22 * s), width: 26 * s, height: 12 * s), Radius.circular(2 * s)), Paint()..color = dark);
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 19 * s), width: 16 * s, height: 4 * s), Paint()..color = visor.withOpacity(0.95));
    // Procedural purity seal, stamped armor markings and tiny engraved scratches.
    final sealX = cx + 13 * s, sealY = cy + 17 * s;
    c.drawLine(Offset(sealX, sealY), Offset(sealX + 3 * s, sealY + 10 * s), Paint()..color = const Color(0xFFFFE0B2)..strokeWidth = 2.2 * s);
    c.drawLine(Offset(sealX + 3 * s, sealY + 10 * s), Offset(sealX + 7 * s, sealY + 7 * s), Paint()..color = const Color(0xFFFFE0B2)..strokeWidth = 1.4 * s);
    c.drawCircle(Offset(sealX, sealY), 3.2 * s, Paint()..color = const Color(0xFFB71C1C));
    c.drawCircle(Offset(sealX, sealY), 1.4 * s, Paint()..color = gold);
    puritySeal(c, Offset(cx - 17 * s, cy + 10 * s), 0.62 * s, const Color(0xFF8E1515), const Color(0xFFFFE0B2));
    engravedRunes(c, Offset(cx, cy + 4 * s), 11 * s, gold, 0.65 * s, count: cls == PlayerClass.malleus ? 9 : 6);
    // Damage grows with missing health; all marks are vector strokes, not image textures.
    final wear = (1.0 - healthRatio.clamp(0.0, 1.0)).clamp(0.0, 1.0).toDouble();
    if (wear > 0.12) {
      final scratchPaint = Paint()..color = const Color(0xFF101820).withOpacity(0.25 + wear * 0.5)..strokeWidth = 1.2 * s..strokeCap = StrokeCap.round;
      c.drawLine(Offset(cx - 18 * s, cy - 1 * s), Offset(cx - (13 - wear * 4) * s, cy + 5 * s), scratchPaint);
      c.drawLine(Offset(cx + 8 * s, cy - 4 * s), Offset(cx + 13 * s, cy + 1 * s), scratchPaint);
      if (wear > 0.45) {
        c.drawLine(Offset(cx - 9 * s, cy + 13 * s), Offset(cx - 3 * s, cy + 19 * s), scratchPaint);
        c.drawLine(Offset(cx + 17 * s, cy + 8 * s), Offset(cx + 12 * s, cy + 14 * s), scratchPaint);
      }
    }
    // ground shadow
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 48 * s), width: 36 * s, height: 10 * s), Paint()..color = Colors.black.withOpacity(0.22));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 48 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void bolter(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final body = accent ?? const Color(0xFFC62828);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 4 * s, cy - 3 * s, 14 * s, 12 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF4E342E));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, cy - 2 * s, 11 * s, 16 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF6D4C41));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy - 12 * s, 34 * s, 16 * s), Radius.circular(2 * s)), Paint()..color = body);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 18 * s, cy + 4 * s, 11 * s, 16 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF546E7A));
    for (int i = 0; i < 3; i++) {
      c.drawCircle(Offset(cx + 16 * s + i * 6 * s, cy - 4 * s), 2 * s, Paint()..color = const Color(0xFF212121));
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 40 * s, cy - 7 * s, 22 * s, 7 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF546E7A));
    // Layered procedural receiver, sight, rivets and heat vents.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 8 * s, cy - 5 * s, 24 * s, 10 * s), Radius.circular(1.5 * s)), Paint()..color = const Color(0xFF263238));
    c.drawLine(Offset(cx - 5 * s, cy - 2 * s), Offset(cx + 12 * s, cy - 2 * s), Paint()..color = Colors.white.withOpacity(0.18)..strokeWidth = 1.0 * s);
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(cx + (13 + i * 3) * s, cy - 3 * s), Offset(cx + (13 + i * 3) * s, cy + 3 * s), Paint()..color = const Color(0xFF90A4AE).withOpacity(0.65)..strokeWidth = 1.1 * s);
    }
    c.drawCircle(Offset(cx - 7 * s, cy + 1 * s), 1.4 * s, Paint()..color = const Color(0xFFFFD54F));
  }

  static void rifle(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final glow = accent ?? const Color(0xFF00E5FF);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 7 * s, 48 * s, 12 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFFA1887F));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 50 * s, cy - 5 * s, 18 * s, 6 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF78909C));
    for (int i = 0; i < 6; i++) {
      c.drawCircle(Offset(cx + 22 * s + i * 5.5 * s, cy), 2.8 * s, Paint()..color = glow.withOpacity(0.85));
    }
  }

  static void shotgun(Canvas c, double cx, double cy, double s, {Color? accent}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 10 * s, cy - 6 * s, 28 * s, 12 * s), Radius.circular(2 * s)), Paint()..color = accent ?? const Color(0xFF546E7A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 48 * s, cy - 7 * s, 16 * s, 4 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF455A64));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 48 * s, cy - 1 * s, 16 * s, 4 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF455A64));
  }

  static void staff(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final glow = accent ?? const Color(0xFF7C4DFF);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 6 * s, 9 * s, 64 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF4A148C));
    c.drawCircle(Offset(cx + 9 * s, cy - 18 * s), 13 * s, Paint()..color = glow.withOpacity(0.35));
    c.drawCircle(Offset(cx + 9 * s, cy - 18 * s), 10 * s, Paint()..color = glow.withOpacity(0.9));
    c.drawCircle(Offset(cx + 9 * s, cy - 18 * s), 4.5 * s, Paint()..color = Colors.white70);
  }

  static void stormStaff(Canvas c, double cx, double cy, double s, {Color? accent}) {
    staff(c, cx, cy, s * 1.05, accent: accent ?? const Color(0xFFEA80FC));
    c.drawCircle(Offset(cx + 9 * s, cy - 18 * s), 20 * s, Paint()..color = const Color(0xFFEA80FC).withOpacity(0.22)..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
  }

  static void warpBeamGun(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final g = accent ?? const Color(0xFF651FFF);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, cy - 10 * s, 40 * s, 16 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF311B92));
    c.drawCircle(Offset(cx + 46 * s, cy), 10 * s, Paint()..color = g.withOpacity(0.5));
    c.drawCircle(Offset(cx + 46 * s, cy), 7 * s, Paint()..color = g);
  }

  static void daggers(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFFE0E0E0);
    for (final ox in [-7.0, 7.0]) {
      final p = Path()
        ..moveTo(cx + ox * s, cy + 5 * s)
        ..lineTo(cx + ox * s + 3 * s, cy - 30 * s)
        ..lineTo(cx + ox * s + 7 * s, cy + 5 * s)
        ..close();
      c.drawPath(p, Paint()..color = blade);
    }
  }

  static void needles(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final col = accent ?? const Color(0xFFCE93D8);
    for (int i = 0; i < 3; i++) {
      c.drawLine(Offset(cx + 4 * s, cy - 2 * s + i * 5 * s), Offset(cx + 40 * s, cy - 20 * s + i * 5 * s), Paint()..color = col..strokeWidth = 2.2 * s);
    }
  }

  static void sniperNeedle(Canvas c, double cx, double cy, double s, {Color? accent}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, cy - 5 * s, 52 * s, 7 * s), Radius.circular(1 * s)), Paint()..color = accent ?? const Color(0xFF9C27B0));
  }

  static void powerSword(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFF4DD0E1);
    final p = Path()
      ..moveTo(cx + 10 * s, cy - 2 * s)
      ..lineTo(cx + 14 * s, cy - 46 * s)
      ..lineTo(cx + 18 * s, cy - 2 * s)
      ..close();
    c.drawPath(p, Paint()..color = blade);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 10 * s, cy), width: 18 * s, height: 7 * s), Paint()..color = const Color(0xFFB8860B));
  }

  static void chainAxe(Canvas c, double cx, double cy, double s, {Color? accent}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 2.5 * s, 32 * s, 5 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF8D4E3A));
    final head = Offset(cx + 40 * s, cy);
    final top = Path()
      ..moveTo(head.dx, head.dy - 3 * s)
      ..lineTo(head.dx + 10 * s, head.dy - 26 * s)
      ..lineTo(head.dx + 20 * s, head.dy - 8 * s)
      ..close();
    c.drawPath(top, Paint()..color = accent ?? const Color(0xFF78909C));
    c.drawCircle(head, 7 * s, Paint()..color = const Color(0xFF546E7A));
  }

  static void thunderHammer(Canvas c, double cx, double cy, double s, {Color? accent}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 2 * s, 38 * s, 5 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 50 * s, cy), width: 20 * s, height: 26 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF455A64));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 50 * s, cy), width: 14 * s, height: 18 * s), Radius.circular(1 * s)), Paint()..color = accent ?? const Color(0xFFB8860B));
  }

  static void forceBlade(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFFB388FF);
    final p = Path()
      ..moveTo(cx + 8 * s, cy)
      ..lineTo(cx + 16 * s, cy - 56 * s)
      ..lineTo(cx + 24 * s, cy)
      ..close();
    c.drawPath(p, Paint()..color = blade);
    c.drawCircle(Offset(cx + 16 * s, cy), 7 * s, Paint()..color = const Color(0xFF4A148C));
  }

  static void forceSword(Canvas c, double cx, double cy, double s, {Color? accent}) {
    forceBlade(c, cx, cy, s * 1.12, accent: accent ?? const Color(0xFFEA80FC));
  }

  static void daemonHammer(Canvas c, double cx, double cy, double s, {Color? accent}) {
    thunderHammer(c, cx, cy, s * 1.08, accent: accent ?? const Color(0xFF7C4DFF));
  }

  static void katana(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFFECEFF1);
    c.drawLine(Offset(cx + 8 * s, cy + 2 * s), Offset(cx + 14 * s, cy - 52 * s), Paint()..color = blade..strokeWidth = 3.2 * s..strokeCap = StrokeCap.round);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 8 * s, cy + 4 * s), width: 16 * s, height: 5 * s), Paint()..color = const Color(0xFF4A148C));
  }

  static void powerKatana(Canvas c, double cx, double cy, double s, {Color? accent}) {
    katana(c, cx, cy, s, accent: accent ?? const Color(0xFFE040FB));
  }

  static void executioner(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFFF3E5F5);
    c.drawLine(Offset(cx + 6 * s, cy + 4 * s), Offset(cx + 20 * s, cy - 58 * s), Paint()..color = blade..strokeWidth = 4.8 * s..strokeCap = StrokeCap.round);
  }

  static void chaosHound(Canvas c, double cx, double cy, {double flash = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 18), width: 40, height: 12), Paint()..color = Colors.black.withOpacity(0.2));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 2), width: 54, height: 30), Paint()..color = const Color(0xFF2D1F14));
    c.drawOval(Rect.fromCenter(center: Offset(cx - 4, cy), width: 40, height: 22), Paint()..color = const Color(0xFF3E2723));
    c.drawOval(Rect.fromCenter(center: Offset(cx + 24, cy - 8), width: 30, height: 24), Paint()..color = const Color(0xFF3E2723));
    c.drawOval(Rect.fromCenter(center: Offset(cx + 30, cy - 2), width: 16, height: 10), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx + 28, cy - 12), 4.5, Paint()..color = const Color(0xFFFFFDE7));
    c.drawCircle(Offset(cx + 28, cy - 12), 2, Paint()..color = const Color(0xFFB71C1C));
    for (final lx in [-16.0, -4.0, 8.0, 18.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + lx, cy + 16), width: 6, height: 14), const Radius.circular(2)), Paint()..color = const Color(0xFF2D1F14));
    }
    for (int i = 0; i < 4; i++) {
      c.drawLine(Offset(cx - 12.0 + i * 8, cy - 8), Offset(cx - 10.0 + i * 8, cy - 18), Paint()..color = const Color(0xFF5D4037)..strokeWidth = 2);
    }
    if (flash > 0) c.drawCircle(Offset(cx, cy), 32, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void cultistShooter(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 34 * s), width: 28 * s, height: 8 * s), Paint()..color = Colors.black.withOpacity(0.2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 7 * s, cy + 22 * s), width: 10 * s, height: 18 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 7 * s, cy + 22 * s), width: 10 * s, height: 18 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 26 * s, height: 28 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 14 * s), 11 * s, Paint()..color = const Color(0xFF37474F));
    c.drawArc(Rect.fromCircle(center: Offset(cx, cy - 14 * s), radius: 12 * s), pi, pi, false, Paint()..color = const Color(0xFF2E7D32));
    bolter(c, cx + 2 * s, cy + 2 * s, s * 0.78);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void cultistMelee(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 38 * s), width: 30 * s, height: 8 * s), Paint()..color = Colors.black.withOpacity(0.2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 8 * s, cy + 26 * s), width: 11 * s, height: 18 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF4A1515));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 8 * s, cy + 26 * s), width: 11 * s, height: 18 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF4A1515));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 10 * s), width: 32 * s, height: 40 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF6B1B1B));
    c.drawCircle(Offset(cx, cy - 18 * s), 12 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawLine(Offset(cx + 16 * s, cy + 2 * s), Offset(cx + 36 * s, cy - 24 * s), Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 3.8 * s);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void shieldedMarine(Canvas c, double cx, double cy, double s, {bool withGun = false, double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 34 * s, height: 32 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF2A2A2A));
    c.drawCircle(Offset(cx, cy - 16 * s), 13 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 16 * s), width: 14 * s, height: 4 * s), Paint()..color = const Color(0xFF1565C0));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 10 * s, cy + 6 * s), width: 42 * s, height: 56 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF37474F));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 10 * s, cy + 6 * s), width: 34 * s, height: 48 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF455A64));
    c.drawLine(Offset(cx + 10 * s, cy - 16 * s), Offset(cx + 10 * s, cy + 28 * s), Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 2 * s);
    if (withGun) bolter(c, cx - 10 * s, cy + 2 * s, s * 0.7);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 36 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void flamerCultist(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 28 * s, height: 30 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFFBF360C));
    c.drawCircle(Offset(cx, cy - 14 * s), 11 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 4 * s, 28 * s, 12 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF5D4037));
    c.drawCircle(Offset(cx + 36 * s, cy), 9 * s, Paint()..color = const Color(0xFFFF6D00).withOpacity(0.85));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void sniperCultist(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 22 * s, height: 28 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF33691E));
    c.drawCircle(Offset(cx, cy - 12 * s), 10 * s, Paint()..color = const Color(0xFF1B5E20));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 6 * s, 46 * s, 6 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF558B2F));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 32 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void brute(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 48 * s, height: 44 * s), Radius.circular(6 * s)), Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 20 * s), 15 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx - 5 * s, cy - 20 * s), 3.5 * s, Paint()..color = const Color(0xFFFF6D00));
    c.drawCircle(Offset(cx + 5 * s, cy - 20 * s), 3.5 * s, Paint()..color = const Color(0xFFFF6D00));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 42 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  /// Cult psyker — robed, glowing hands, warp aura
  static void cultPsyker(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 36 * s), width: 28 * s, height: 8 * s), Paint()..color = Colors.black.withOpacity(0.2));
    final robe = Path()
      ..moveTo(cx - 18 * s, cy - 4 * s)
      ..lineTo(cx - 22 * s, cy + 36 * s)
      ..lineTo(cx + 22 * s, cy + 36 * s)
      ..lineTo(cx + 18 * s, cy - 4 * s)
      ..close();
    c.drawPath(robe, Paint()..color = const Color(0xFF4A148C));
    c.drawPath(robe, Paint()..color = const Color(0xFF7C4DFF).withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    c.drawCircle(Offset(cx, cy - 16 * s), 12 * s, Paint()..color = const Color(0xFF311B92));
    c.drawCircle(Offset(cx, cy - 16 * s), 6 * s, Paint()..color = const Color(0xFFEA80FC).withOpacity(0.9));
    c.drawCircle(Offset(cx - 22 * s, cy + 4 * s), 8 * s, Paint()..color = const Color(0xFFB388FF).withOpacity(0.7));
    c.drawCircle(Offset(cx + 22 * s, cy + 4 * s), 8 * s, Paint()..color = const Color(0xFFB388FF).withOpacity(0.7));
    c.drawCircle(Offset(cx, cy), 28 * s, Paint()..color = const Color(0xFF7C4DFF).withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 36 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  /// Plague bearer — bloated, green pustules
  static void plagueBearer(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 38 * s), width: 40 * s, height: 10 * s), Paint()..color = Colors.black.withOpacity(0.2));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 44 * s, height: 48 * s), Paint()..color = const Color(0xFF33691E));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 36 * s, height: 40 * s), Paint()..color = const Color(0xFF558B2F));
    c.drawCircle(Offset(cx, cy - 18 * s), 14 * s, Paint()..color = const Color(0xFF1B5E20));
    c.drawCircle(Offset(cx - 4 * s, cy - 18 * s), 3 * s, Paint()..color = const Color(0xFF8BC34A));
    c.drawCircle(Offset(cx + 5 * s, cy - 16 * s), 2.5 * s, Paint()..color = const Color(0xFF8BC34A));
    for (final o in [Offset(-12, 8), Offset(10, 12), Offset(-6, 20), Offset(14, 0)]) {
      c.drawCircle(Offset(cx + o.dx * s, cy + o.dy * s), 4 * s, Paint()..color = const Color(0xFF9CCC65).withOpacity(0.85));
    }
    if (flash > 0) c.drawCircle(Offset(cx, cy), 38 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  /// Bloodletter — red sinewy melee demon-cultist
  static void bloodletter(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 36 * s), width: 28 * s, height: 8 * s), Paint()..color = Colors.black.withOpacity(0.2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 30 * s, height: 36 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFFB71C1C));
    c.drawCircle(Offset(cx, cy - 16 * s), 12 * s, Paint()..color = const Color(0xFF8B0000));
    c.drawCircle(Offset(cx - 3 * s, cy - 16 * s), 2.5 * s, Paint()..color = const Color(0xFFFFEB3B));
    c.drawCircle(Offset(cx + 4 * s, cy - 16 * s), 2.5 * s, Paint()..color = const Color(0xFFFFEB3B));
    // horns
    c.drawLine(Offset(cx - 8 * s, cy - 22 * s), Offset(cx - 14 * s, cy - 36 * s), Paint()..color = const Color(0xFF3E2723)..strokeWidth = 3 * s);
    c.drawLine(Offset(cx + 8 * s, cy - 22 * s), Offset(cx + 14 * s, cy - 36 * s), Paint()..color = const Color(0xFF3E2723)..strokeWidth = 3 * s);
    // blade
    c.drawLine(Offset(cx + 16 * s, cy + 2 * s), Offset(cx + 40 * s, cy - 28 * s), Paint()..color = const Color(0xFFE0E0E0)..strokeWidth = 4 * s);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 36 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void hereticBoss(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 14 * s), width: 34 * s, height: 46 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 16 * s), 13 * s, Paint()..color = const Color(0xFFC4A484));
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 16 * s), width: 14 * s, height: 3.5 * s), Paint()..color = const Color(0xFFFF1744));
    for (final dx in [-10.0, 0.0, 10.0]) {
      c.drawLine(Offset(cx + dx * s, cy - 24 * s), Offset(cx + dx * s, cy - 36 * s), Paint()..color = const Color(0xFFB71C1C)..strokeWidth = 3 * s);
    }
    if (flash > 0) c.drawCircle(Offset(cx, cy), 54 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void knightBoss(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 44 * s, height: 38 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 22 * s), 14 * s, Paint()..color = const Color(0xFF212121));
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 22 * s), width: 16 * s, height: 4 * s), Paint()..color = const Color(0xFF90CAF9));
    powerSword(c, cx + 12 * s, cy + 4 * s, s * 1.1);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 52 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void kingBossDraw(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 50 * s, height: 42 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 22 * s), 13 * s, Paint()..color = const Color(0xFFC4A484));
    for (final dx in [-12.0, -4.0, 4.0, 12.0]) {
      c.drawLine(Offset(cx + dx * s, cy - 30 * s), Offset(cx + dx * s, cy - 42 * s), Paint()..color = const Color(0xFFFFD700)..strokeWidth = 3 * s);
    }
    thunderHammer(c, cx + 10 * s, cy + 4 * s, s * 0.95);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 60 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  /// Plague Lord boss — massive bloated Nurgle champion
  static void plagueLord(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 50 * s), width: 70 * s, height: 16 * s), Paint()..color = Colors.black.withOpacity(0.25));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 90 * s, height: 100 * s), Paint()..color = const Color(0xFF1B5E20));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 72 * s, height: 84 * s), Paint()..color = const Color(0xFF33691E));
    c.drawCircle(Offset(cx, cy - 36 * s), 28 * s, Paint()..color = const Color(0xFF1B5E20));
    c.drawCircle(Offset(cx - 8 * s, cy - 36 * s), 6 * s, Paint()..color = const Color(0xFF8BC34A));
    c.drawCircle(Offset(cx + 10 * s, cy - 34 * s), 5 * s, Paint()..color = const Color(0xFF8BC34A));
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      c.drawCircle(Offset(cx + cos(a) * 30 * s, cy + sin(a) * 28 * s), 6 * s, Paint()..color = const Color(0xFF9CCC65).withOpacity(0.8));
    }
    // fly cloud hint
    c.drawCircle(Offset(cx + 20 * s, cy - 50 * s), 4 * s, Paint()..color = const Color(0xFF212121).withOpacity(0.5));
    c.drawCircle(Offset(cx - 16 * s, cy - 48 * s), 3 * s, Paint()..color = const Color(0xFF212121).withOpacity(0.4));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 70 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.3 * flash));
  }

  /// Blood Champion boss — Khorne elite, dual blades, blood aura
  static void bloodChampion(Canvas c, double cx, double cy, double s, {double flash = 0, double rage = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 48 * s), width: 50 * s, height: 12 * s), Paint()..color = Colors.black.withOpacity(0.25));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 52 * s, height: 56 * s), Radius.circular(6 * s)), Paint()..color = Color.lerp(const Color(0xFFB71C1C), const Color(0xFFFF1744), rage)!);
    c.drawCircle(Offset(cx, cy - 28 * s), 16 * s, Paint()..color = const Color(0xFF8B0000));
    c.drawCircle(Offset(cx - 5 * s, cy - 28 * s), 3 * s, Paint()..color = const Color(0xFFFFEB3B));
    c.drawCircle(Offset(cx + 6 * s, cy - 28 * s), 3 * s, Paint()..color = const Color(0xFFFFEB3B));
    c.drawLine(Offset(cx - 10 * s, cy - 36 * s), Offset(cx - 18 * s, cy - 52 * s), Paint()..color = const Color(0xFF3E2723)..strokeWidth = 4 * s);
    c.drawLine(Offset(cx + 10 * s, cy - 36 * s), Offset(cx + 18 * s, cy - 52 * s), Paint()..color = const Color(0xFF3E2723)..strokeWidth = 4 * s);
    // dual blades
    c.drawLine(Offset(cx - 20 * s, cy), Offset(cx - 48 * s, cy - 40 * s), Paint()..color = const Color(0xFFE0E0E0)..strokeWidth = 5 * s);
    c.drawLine(Offset(cx + 20 * s, cy), Offset(cx + 48 * s, cy - 40 * s), Paint()..color = const Color(0xFFE0E0E0)..strokeWidth = 5 * s);
    if (rage > 0.3) {
      c.drawCircle(Offset(cx, cy), 55 * s, Paint()..color = Color.fromRGBO(255, 23, 68, 0.15 * rage)..style = PaintingStyle.stroke..strokeWidth = 4 * s);
    }
    if (flash > 0) c.drawCircle(Offset(cx, cy), 60 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void cyclops(Canvas c, double cx, double cy, double s, {double flash = 0, double charge = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10 * s), width: 74 * s, height: 84 * s), Paint()..color = const Color(0xFF3E2723));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 56 * s, height: 64 * s), Paint()..color = const Color(0xFF5D4037));
    c.drawCircle(Offset(cx, cy - 22 * s), 30 * s, Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 24 * s), 16 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 24 * s), 12 * s, Paint()..color = Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFF1744), charge)!);
    c.drawCircle(Offset(cx, cy - 24 * s), 5 * s, Paint()..color = Colors.white);
    c.drawLine(Offset(cx - 18 * s, cy - 38 * s), Offset(cx + 32 * s, cy - 60 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 6 * s);
    c.drawLine(Offset(cx + 18 * s, cy - 38 * s), Offset(cx + 32 * s, cy - 60 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 6 * s);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 62 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void statusIcons(Canvas c, double cx, double topY, List<StatusEffect> effects) {
    double x = cx - effects.length * 7.0;
    for (final e in effects) {
      c.drawCircle(Offset(x, topY), 6, Paint()..color = e.color);
      x += 14;
    }
  }

  static void championMark(Canvas c, double cx, double topY, {EliteAffix affix = EliteAffix.none}) {
    final path = Path()
      ..moveTo(cx, topY - 10)
      ..lineTo(cx + 7, topY)
      ..lineTo(cx, topY + 4)
      ..lineTo(cx - 7, topY)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFFFFD700));
    c.drawPath(path, Paint()..color = const Color(0xFFFF8F00)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    if (affix != EliteAffix.none) {
      final tp = TextPainter(
        text: TextSpan(text: affix.letter, style: TextStyle(color: affix.color, fontSize: 11, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(cx - tp.width / 2, topY - 24));
      c.drawCircle(Offset(cx, topY - 4), 22, Paint()..color = affix.color.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  static void altar(Canvas c, double cx, double cy, {double flicker = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 10), width: 50, height: 28), const Radius.circular(4)), Paint()..color = const Color(0xFF5D4037));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 4), width: 36, height: 20), const Radius.circular(3)), Paint()..color = const Color(0xFF8D6E63));
    final pulse = 0.7 + 0.3 * sin(flicker * 4);
    c.drawCircle(Offset(cx, cy - 18), 10 * pulse, Paint()..color = const Color(0xFFFFD700).withOpacity(0.55 + 0.35 * pulse));
    c.drawCircle(Offset(cx, cy - 22), 4, Paint()..color = const Color(0xFFFFF8E1).withOpacity(0.9 * pulse));
  }

  static void merchantStall(Canvas c, double cx, double cy, {double flicker = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 56, height: 32), const Radius.circular(3)), Paint()..color = const Color(0xFF4E342E));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 10), width: 48, height: 16), const Radius.circular(2)), Paint()..color = const Color(0xFFB8860B));
    c.drawCircle(Offset(cx - 10, cy + 4), 5, Paint()..color = const Color(0xFFFFD700));
    c.drawCircle(Offset(cx + 10, cy + 4), 5, Paint()..color = const Color(0xFF90CAF9));
    // torch spark
    final pulse = 0.6 + 0.4 * sin(flicker * 5);
    c.drawCircle(Offset(cx + 28, cy - 18), 5 * pulse, Paint()..color = const Color(0xFFFF6D00).withOpacity(0.7 * pulse));
  }

  static void barrel(Canvas c, double cx, double cy, {int kind = 0}) {
    // kind 0 normal, 1 explosive (red), 2 heal (green), 3 scrap (gold)
    final body = kind == 1
        ? const Color(0xFFB71C1C)
        : kind == 2
            ? const Color(0xFF2E7D32)
            : kind == 3
                ? const Color(0xFFB8860B)
                : const Color(0xFF6D4C41);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 36, height: 44), const Radius.circular(4)), Paint()..color = body);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 4), width: 30, height: 8), const Radius.circular(2)), Paint()..color = const Color(0xFF8D6E63));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 10), width: 30, height: 8), const Radius.circular(2)), Paint()..color = const Color(0xFF5D4037));
  }
}
class InquisitorGame extends FlameGame with HasCollisionDetection {
  final expansion.InquisitorExpansionSystems expansionSystems = expansion.InquisitorExpansionSystems();
  final arena_catalog.WorldDirector worldDirector = arena_catalog.WorldDirector();
  final mission_catalog.MissionEventDirector missionEvents = mission_catalog.MissionEventDirector();
  final progression_catalog.ProgressionTrack progressionTrack = progression_catalog.ProgressionTrack();
  final gear_catalog.EquipmentInventory equipmentInventory = gear_catalog.EquipmentInventory();
  world_catalog.BiomeId expansionBiome = world_catalog.BiomeId.manufactorum;
  arena_catalog.WorldEvent? currentWorldEvent;
  arena_catalog.WorldEventEffects? currentWorldEventEffects;
  mission_catalog.MissionEvent? currentMissionEvent;
  /// Additive expansion state; legacy campaign and save fields remain untouched.
  late Player player;
  late JoystickComponent moveJoystick;
  late JoystickComponent attackJoystick;
  late HudButtonComponent switchWeaponButton;
  late HudButtonComponent settingsButton;
  late HudButtonComponent backpackButton;
  late HudButtonComponent zoomInButton;
  late HudButtonComponent zoomOutButton;
  HudButtonComponent? portalButton;
  HudButtonComponent? dashButton;
  HudButtonComponent? laserButton;
  HudButtonComponent? artifactButton;
  HudButtonComponent? warpResetButton;
  HudButtonComponent? ordoAbilityButton;
  OrdoAbilityCooldownHud? ordoAbilityCooldownHud;

  int score = 0;
  int scraps = 0;
  bool isPlaying = false;
  bool isPaused = false;
  String playerName = 'Inquisitor';
  DateTime? playStartTime;
  int playSeconds = 0;
  int _savedPlaySeconds = 0;

  Difficulty difficulty = Difficulty.normal;
  PlayerClass playerClass = PlayerClass.xenos;
  SkillTree skills = SkillTree();
  int skillPoints = 0;
  Customization custom = Customization();
  final Set<RelicId> relics = {};
  final Set<CodexId> codexUnlocked = {};
  /// times accepted knowledge (0..2)
  final Map<CodexId, int> loreRanks = {};
  final CampaignState campaign = CampaignState();
  bool oathAcceptedThisRun = false;
  String activeOathName = '';
  double missionAlarmClock = 0;
  double fieldMedkitCooldown = 0;
  WeaponLoadout loadout = WeaponLoadout();
  ActiveArtifact activeArtifact = ActiveArtifact.fragGrenade;
  double artifactCooldown = 0;
  double holyAuraTimer = 0;
  double _holyAuraDamageTick = 0;
  double ordoAbilityCooldown = 0;
  double ordoWardTimer = 0;
  double _ordoAuraClock = 0;
  final ModularWeaponBuild modularWeapon = ModularWeaponBuild();
  final List<StoredInventoryItem> storedItems = [];
  ArmorPattern activeArmor = ArmorPattern.inquisitorial;
  final Set<ArmorPattern> ownedArmor = {ArmorPattern.flak, ArmorPattern.inquisitorial};
  final List<String> campaignChronicle = <String>[];
  double combatAnimClock = 0;
  double hitPulse = 0;
  int armorForgePurchases = 0;
  double warpStability = 100.0;
  double _warpStabilityClock = 0;
  BiomeId get activeBiome => BiomeId.values[(currentFloor - 1 + (warpCorruption >= 60 ? 2 : 0)) % BiomeId.values.length];
  String get activeBiomeLabel => switch (activeBiome) {
    BiomeId.manufactorum => 'Манyфакторум', BiomeId.hive => 'Улей', BiomeId.shrine => 'Храмовый комплекс',
    BiomeId.deathWorld => 'Мир смерти', BiomeId.warpRuin => 'Руины Варпа',
    BiomeId.voidship => 'Пустотный корабль', BiomeId.necronTomb => 'Гробница некронов',
  };
  String get activeRoomSet => switch (activeBiome) {
    BiomeId.manufactorum => 'цеха, конвейеры, силовые узлы', BiomeId.hive => 'жилые блоки, мостки, узкие коридоры',
    BiomeId.shrine => 'часовни, алтари, колоннады', BiomeId.deathWorld => 'укрытия, обломки, открытые площадки',
    BiomeId.warpRuin => 'осквернённые залы, разломы, рунические круги',
    BiomeId.voidship => 'гермодвери, переборки, аварийные палубы', BiomeId.necronTomb => 'монолитные камеры, зелёные энергетические каналы',
  };


  InquisitionRank inquisitionRank = InquisitionRank();
  WeaponMastery mastery = WeaponMastery();
  RankChallenge activeChallenge = RankChallenge.none;
  bool challengeBossMeleeOk = true;
  bool ironWillUsedThisFloor = false;

  List<PathNode> floorPath = [];
  int pathIndex = 0;
  List<PathNode> pendingPathChoices = [];

  double bolterHeat = 0;
  double staffWarpStress = 0;
  double warpResetCooldown = 0;

  double cinemaZoomTimer = 0;
  double cinemaZoomFrom = 0.85;
  double cinemaZoomTo = 1.1;

  CodexId? pendingLoreId;

  EventRoomType currentEvent = EventRoomType.none;
  bool eventResolved = false;
  int levelsSinceEvent = 0;

  int combo = 0;
  double comboTimer = 0;
  static const double comboWindow = 2.4;
  final Set<int> _comboMilestonesClaimed = {};

  double tempDmgMult = 1.0;
  double tempDmgTimer = 0;
  double shieldTimer = 0;
  double _hasteTimer = 0;
  double invulnTimer = 0;
  double hereticusDashBoost = 0;
  EchoBossKind pendingEcho = EchoBossKind.none;

  /// Boss retreat after volley
  double bossRetreatTimer = 0;

  bool arenaMode = false;
  int arenaKills = 0;
  int arenaWave = 1;
  double _corruptionClock = 0;
  int warpCorruption = 0;
  int arsenalUpgrade = 0;
  int shrineUpgrade = 0;
  int archiveUpgrade = 0;
  int medicaeUpgrade = 0;
  String inquisitionAlignment = 'puritan';
  String specialization = 'balanced';
  String legendaryWeapon = 'none';
  int legendaryWeaponRank = 0;
  int investigationsResolved = 0;
  int legendaryKillCounter = 0;
  int requisition = 120;
  int permanentSkillBonus = 0;
  bool artifactInvestigationResolved = false;
  bool showSecretSignals = true;
  CombatDoctrine combatDoctrine = CombatDoctrine.balanced;
  AmmoDoctrine ammoDoctrine = AmmoDoctrine.standard;
  ArenaModifier arenaModifier = ArenaModifier.none;
  int servoSkullLevel = 0;
  int secretBossesDefeatedTotal = 0;
  int tacticalAchievements = 0;
  double _servoSkullPulse = 0;

  // Unified campaign-systems layer. These values are run-local except the completed count.
  TacticalContract activeContract = TacticalContract.purge;
  int contractProgress = 0;
  int contractTarget = 5;
  bool contractClaimed = false;
  int contractsCompleted = 0;

  // Additive field-operations layer. Missing keys in old saves are intentionally optional.
  final List<FieldLootItem> fieldInventory = [];
  final Set<String> discoveredCacheIds = {};
  final Set<String> collectedLootIds = {};
  final Map<TacticalConsumable, int> consumables = {
    TacticalConsumable.fragGrenade: 2, TacticalConsumable.stim: 1,
    TacticalConsumable.smoke: 1, TacticalConsumable.auspexPulse: 1,
  };
  final List<String> tacticalMods = ['Armor-Seal', 'Auspex Lens', 'Recoil Servo'];
  int backpackCapacity = 16;
  int backpackUpgradeLevel = 0;
  int fieldFloorIndex = 1;
  int operationSerial = 0;
  int operationThreatLevel = 0;
  bool highThreatOperation = false;
  /// Career achievements are monotonic: once unlocked, they remain unlocked.
  final Set<String> unlockedAchievementIds = <String>{};
  int careerOperationsCompleted = 0;
  int careerFloorsReached = 1;
  int careerKills = 0;
  int careerEvidenceFound = 0;
  int evacuationRoute = 0; // 0 safe, 1 rapid, 2 covert
  int terminalsActivated = 0;
  int supplyCachesOpened = 0;
  int randomMissionEvents = 0;
  double _fieldEventClock = 0;
  MapLayout get activeMapLayout => MapLayout.values[(currentFloor * 3 + currentLevel + pathIndex) % MapLayout.values.length];
  String get activeOrdoContract => switch (playerClass) {
    PlayerClass.malleus => 'Ордо Маллеус: сорвать варп-ритуал и подавить демоническую угрозу',
    PlayerClass.hereticus => 'Ордо Еретикус: выявить культистов и собрать доказательства',
    PlayerClass.xenos => 'Ордо Ксенос: ликвидировать ксеноугрозу и добыть образцы',
  };
  int rangedPressure = 0;
  int meleePressure = 0;
  double _riftSpawnClock = 0;
  String get adaptiveBossTactic => meleePressure > rangedPressure * 1.25
      ? 'Дистанция'
      : rangedPressure > meleePressure * 1.25 ? 'Сближение' : 'Смешанная тактика';

  /// In the endless arena, every 20 kills add another threat tier.
  int get arenaThreatTier => arenaMode ? arenaKills ~/ 20 : 0;
  double get arenaThreatMultiplier => 1.0 + arenaThreatTier * 0.12;

  int currentFloor = 1;
  int currentLevel = 1;
  int enemiesAlive = 0;
  int enemiesToSpawn = 0;
  int enemiesSpawned = 0;

  bool portalSpawned = false;
  bool isBossLevel = false;
  bool isMiniBossLevel = false;
  bool isEliteNode = false;
  bool isSurvivalNode = false;
  bool nearPortal = false;

  double spawnTimer = 0;
  double spawnInterval = 1.2;

  int baseBolter = 8, baseRifle = 18, baseShotgun = 10;
  int baseStaff = 14, baseStorm = 18, baseWarp = 26;
  int baseDagger = 7, baseNeedle = 9, baseSniperNeedle = 20;
  int baseSword = 12, baseAxe = 14, baseHammer = 28;
  int baseForce = 16, baseForceSword = 20, baseDaemon = 30;
  int baseKatana = 15, basePowerKatana = 18, baseExec = 24;
  int baseMaxHealth = 6;
  double baseSpeed = 210;

  int bolterDamage = 8, rifleDamage = 18, shotgunDamage = 10;
  int staffDamage = 14, stormDamage = 18, warpDamage = 26;
  int daggerDamage = 7, needleDamage = 9, sniperNeedleDamage = 20;
  int swordDamage = 12, axeDamage = 14, hammerDamage = 28;
  int forceDamage = 16, forceSwordDamage = 20, daemonDamage = 30;
  int katanaDamage = 15, powerKatanaDamage = 18, execDamage = 24;
  int maxHealth = 6;
  double playerSpeed = 210;
  double defenseChance = 0.0;
  double attackSpeedMult = 1.0;

  RangedWeapon rangedWeapon = RangedWeapon.bolter;
  MeleeWeapon meleeWeapon = MeleeWeapon.sword;
  bool usingMelee = false;

  double joystickSize = 80;
  double buttonSize = 42;
  double currentZoom = 0.85;

  // User-configurable mobile control layout. Values are logical-pixel edge margins.
  double moveJoystickLeft = 52;
  double moveJoystickBottom = 52;
  double attackJoystickRight = 52;
  double attackJoystickBottom = 52;
  double abilityClusterLeft = 32;
  double abilityClusterBottom = 160;
  double weaponButtonRight = 52;
  double weaponButtonBottom = 160;
  final List<HudLabel> _controlHudLabels = [];

  bool soundEnabled = true;
  bool musicEnabled = true;
  double soundVolume = 0.8;
  double musicVolume = 0.45;

  double shakeTime = 0;
  double shakePower = 0;

  List<HighScoreEntry> highScores = [];
  List<GameSave> saves = [];
  List<RewardOption> pendingRewards = [];

  final double mapWidth = 1200;
  final double mapHeight = 2000;
  final double cellSize = 60;
  double get safeRadius => cellSize * 5.5;
  Vector2 get playerSpawnPos => Vector2(mapWidth / 2, mapHeight / 2 + 360);

  bool secretBossUnlockedThisLevel = false;
  bool secretBossSpawned = false;
  bool secretBossDefeated = false;
  double cornerStandTimer = 0;
  bool hasDashAbility = false;
  bool hasLaserAbility = false;
  double dashCooldown = 0;
  double dashActive = 0;
  double laserCooldown = 0;
  bool _everReached11 = false;
  bool _everReached21 = false;

  bool get unlockedGunMods => playerClass == PlayerClass.xenos && (currentFloor >= 2 || _everReached11);
  bool get unlockedStaffMods => playerClass == PlayerClass.malleus && (currentFloor >= 2 || _everReached11);
  bool get unlockedBladeMods => playerClass == PlayerClass.hereticus && (currentFloor >= 2 || _everReached11);

  AudioPlayer? _bgmPlayer;
  final List<AudioPlayer> _sfxPool = [];
  static const int _sfxPoolSize = 8;
  int _sfxIdx = 0;

  final TextPaint hudPaint = TextPaint(style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));

  int get maxFloors => difficulty.maxFloors;
  int get overallLevel => (currentFloor - 1) * 5 + currentLevel;
  bool get unlockTier11 => overallLevel >= 11 || _everReached11;
  bool get unlockTier21 => overallLevel >= 21 || _everReached21;
  bool get unlockedRifle => playerClass == PlayerClass.xenos && unlockTier11;
  bool get unlockedShotgun => playerClass == PlayerClass.xenos && unlockTier21;
  bool get unlockedAxe => playerClass == PlayerClass.xenos && unlockTier11;
  bool get unlockedHammer => playerClass == PlayerClass.xenos && unlockTier21;
  bool get unlockedStormStaff => playerClass == PlayerClass.malleus && unlockTier11;
  bool get unlockedWarpBeam => playerClass == PlayerClass.malleus && unlockTier21;
  bool get unlockedForceSword => playerClass == PlayerClass.malleus && unlockTier11;
  bool get unlockedDaemonHammer => playerClass == PlayerClass.malleus && unlockTier21;
  bool get unlockedNeedles => playerClass == PlayerClass.hereticus && unlockTier11;
  bool get unlockedSniperNeedle => playerClass == PlayerClass.hereticus && unlockTier21;
  bool get unlockedPowerKatana => playerClass == PlayerClass.hereticus && unlockTier11;
  bool get unlockedExecutioner => playerClass == PlayerClass.hereticus && unlockTier21;

  double get worldThreat => (1.0 + (highThreatOperation ? operationThreatLevel * 0.045 : 0) + overallLevel * 0.055 + skills.totalSpent * 0.02 + (currentFloor - 1) * 0.04 + (arenaMode ? arenaThreatTier * 0.12 : 0) + (warpCorruption >= 60 ? 0.08 : 0) + (warpCorruption >= 90 ? 0.12 : 0) + (arenaMode && arenaModifier == ArenaModifier.armored ? 0.25 : 0) + (arenaMode && arenaModifier == ArenaModifier.unstable ? 0.10 : 0)) * (currentWorldEventEffects?.enemyThreatMultiplier ?? 1.0);
  double get comboMult => (1.0 + (combo.clamp(0, 12) * 0.08)).clamp(1.0, 2.0);
  bool get hasCrit => relics.contains(RelicId.crit);
  bool get hasLifesteal => relics.contains(RelicId.lifesteal);
  bool get hasShieldPierce => relics.contains(RelicId.shieldPierce);
  bool get hasKillExplosion => relics.contains(RelicId.killExplosion);
  bool get hasHaste => relics.contains(RelicId.haste);
  bool get hasJediPath => relics.contains(RelicId.jediPath);
  bool get hasAmmoSavant => relics.contains(RelicId.ammoSavant);
  bool get hasWarpAnchor => relics.contains(RelicId.warpAnchor);
  bool get hasShadowStep => relics.contains(RelicId.shadowStep);
  bool get hasIronWill => relics.contains(RelicId.ironWill);
  bool get hasExecutionerMark => relics.contains(RelicId.executionerMark);
  bool get hasScavenger => relics.contains(RelicId.scavenger);

  bool get setFullInquisitor => hasCrit && hasLifesteal && hasKillExplosion;
  bool get setPurge => hasKillExplosion && hasJediPath;
  double get setBonusDmg {
    var m = 1.0;
    if (setFullInquisitor) m += 0.12;
    if (setPurge) m += 0.06;
    return m;
  }

  bool get synergyFireCrits => hasCrit && hasKillExplosion;
  bool get synergyBloodRush => hasLifesteal && hasHaste;
  bool get synergyTrueFaith => hasShieldPierce && hasCrit;
  bool get synergyXenosBlast =>
      playerClass == PlayerClass.xenos &&
      rangedWeapon == RangedWeapon.shotgun &&
      loadout.gunAmmo == GunAmmoMod.explosive &&
      !usingMelee;
  bool get synergyHereticusBleedDash =>
      playerClass == PlayerClass.hereticus &&
      usingMelee &&
      (meleeWeapon == MeleeWeapon.katana ||
          meleeWeapon == MeleeWeapon.powerKatana ||
          meleeWeapon == MeleeWeapon.executioner);
  bool get synergyXenosMastery =>
      playerClass == PlayerClass.xenos && mastery.getCount('bolter') >= 50;

  String? get activeSynergyLabel {
    final parts = <String>[];
    if (setFullInquisitor) parts.add('Сет Инквизитора +12%');
    if (synergyFireCrits) parts.add('Огненный крит');
    if (synergyBloodRush) parts.add('Кровавый рывок');
    if (synergyTrueFaith) parts.add('Истинная вера');
    if (setPurge) parts.add('Очищение');
    if (synergyXenosBlast) parts.add('Прометий-конус');
    if (synergyHereticusBleedDash) parts.add('Кровавый след');
    if (synergyXenosMastery) parts.add('Мастер болтера');
    if (hasJediPath) parts.add('Путь Джедая');
    return parts.isEmpty ? null : parts.join(' • ');
  }

  double _loreBonus(CodexId id, double perRank) => (loreRanks[id] ?? 0) * perRank;

  double get codexRangedBonus {
    var b = (codexUnlocked.contains(CodexId.shooter) ? 0.02 : 0) + (codexUnlocked.contains(CodexId.sniper) ? 0.02 : 0);
    b += _loreBonus(CodexId.shooter, 0.01) + _loreBonus(CodexId.sniper, 0.01);
    return b.toDouble();
  }

  double get codexMeleeBonus {
    var b = [CodexId.melee, CodexId.dog, CodexId.brute, CodexId.bloodletter].where(codexUnlocked.contains).length * 0.02;
    for (final id in [CodexId.melee, CodexId.dog, CodexId.brute, CodexId.bloodletter]) {
      b += _loreBonus(id, 0.01);
    }
    return b.toDouble();
  }

  double get codexShieldBonus {
    var b = [CodexId.shielded, CodexId.shieldedShooter].where(codexUnlocked.contains).length * 0.03;
    b += _loreBonus(CodexId.shielded, 0.01) + _loreBonus(CodexId.shieldedShooter, 0.01);
    return b.toDouble();
  }

  double get codexBossBonus {
    var b = [
      CodexId.miniBoss, CodexId.boss, CodexId.knight, CodexId.king,
      CodexId.plagueLord, CodexId.bloodChampion,
    ].where(codexUnlocked.contains).length * 0.03;
    for (final id in [
      CodexId.miniBoss, CodexId.boss, CodexId.knight, CodexId.king,
      CodexId.plagueLord, CodexId.bloodChampion,
    ]) {
      b += _loreBonus(id, 0.01);
    }
    return b.toDouble();
  }

  double get codexEliteScrapBonus =>
      (codexUnlocked.contains(CodexId.champion) ? 0.05 : 0) + _loreBonus(CodexId.champion, 0.02);
  double get codexBurnBonus =>
      (codexUnlocked.contains(CodexId.flamer) ? 1.0 : 0.0) +
      (codexUnlocked.contains(CodexId.plagueBearer) ? 0.5 : 0) +
      _loreBonus(CodexId.flamer, 0.5);

  void recordChronicle(String event) {
    final stamp = 'Этаж $currentFloor • ${DateTime.now().toIso8601String().substring(11, 16)}';
    campaignChronicle.insert(0, '$stamp — $event');
    if (campaignChronicle.length > 80) campaignChronicle.removeRange(80, campaignChronicle.length);
    persistExpansion();
  }

  bool purchaseArmorAtForge(ArmorPattern pattern) {
    if (ownedArmor.contains(pattern)) { activeArmor = pattern; persistExpansion(); return true; }
    if (requisition < pattern.price) return false;
    requisition -= pattern.price; ownedArmor.add(pattern); activeArmor = pattern; armorForgePurchases++;
    recordChronicle('Кузня: получен комплект «${pattern.labelRu}» за ${pattern.price} реквизиции.');
    return true;
  }

  double get armorDamageReduction => activeArmor.defense.clamp(0.0, 0.30).toDouble();

  void unlockCodex(CodexId id) {
    final wasNew = codexUnlocked.add(id);
    if (wasNew) {
      recordChronicle('Запись Кодекса открыта: ${id.title}.');
      if (codexUnlocked.length == 1) { unlockedAchievementIds.add('first_codex'); }
      persistExpansion();
    }
    if (wasNew && isPlaying) {
      world.add(DamageNumber(position: player.position + Vector2(0, -40), amount: 0, color: const Color(0xFFFFD700), label: 'CODEX'));
      pendingLoreId = id;
      isPaused = true;
      overlays.add('lorePopup');
    }
  }

  int loreRankOf(CodexId id) => loreRanks[id] ?? 0;

  /// Accept knowledge: rank 1 free on unlock popup; rank 2 costs 1 SP
  void acceptLore(CodexId id, {bool fromPopup = true}) {
    final rank = loreRankOf(id);
    if (rank >= 2) {
      if (fromPopup) skipLore();
      return;
    }
    if (rank == 1) {
      if (skillPoints < 1) return;
      skillPoints--;
    }
    loreRanks[id] = rank + 1;
    if (fromPopup) {
      pendingLoreId = null;
      overlays.remove('lorePopup');
      isPaused = false;
    }
    playClick();
  }

  void skipLore() {
    pendingLoreId = null;
    overlays.remove('lorePopup');
    isPaused = false;
  }

  void applyClassDefaults() {
    switch (playerClass) {
      case PlayerClass.xenos:
        rangedWeapon = RangedWeapon.bolter;
        meleeWeapon = MeleeWeapon.sword;
        hasDashAbility = false;
        break;
      case PlayerClass.malleus:
        rangedWeapon = RangedWeapon.staff;
        meleeWeapon = MeleeWeapon.forceBlade;
        hasDashAbility = false;
        break;
      case PlayerClass.hereticus:
        rangedWeapon = RangedWeapon.daggers;
        meleeWeapon = MeleeWeapon.katana;
        hasDashAbility = true;
        break;
    }
    usingMelee = false;
  }

  void recomputeStats() {
    final gear = <String,double>{...equipmentInventory.totalModifiers};
    equipmentInventory.activeSetModifiers.forEach((k,v) => gear[k] = (gear[k] ?? 0) + v);
    var hpBonus = skills.hp + playerClass.hpMod + (hasIronWill ? 1 : 0) + medicaeUpgrade ~/ 2 + (gear['health'] ?? 0).floor();
    if (specialization == 'sentinel' && playerClass == PlayerClass.xenos) hpBonus += 1;
    if (specialization == 'seer' && playerClass == PlayerClass.malleus) hpBonus += 1;
    maxHealth = (baseMaxHealth + hpBonus).clamp(3, 99);
    playerSpeed = (baseSpeed + skills.speed * 12.0 + playerClass.speedMod) * (1 + (gear['speed'] ?? 0));
    if (combatDoctrine == CombatDoctrine.mobile) playerSpeed *= 1.12;
    if (combatDoctrine == CombatDoctrine.heavy) playerSpeed *= 0.92;
    if (specialization == 'assassin' && playerClass == PlayerClass.hereticus) playerSpeed += 24;
    defenseChance = min(0.55, skills.defense * 0.03 + (tacticalMods.contains('Armor-Seal') ? 0.025 : 0) + (gear['defense'] ?? 0));
    if (specialization == 'duelist' && playerClass == PlayerClass.hereticus) defenseChance = min(0.50, defenseChance + 0.04);
    if (specialization == 'sentinel' && playerClass == PlayerClass.xenos) defenseChance = min(0.50, defenseChance + 0.05);
    var aspd = max(0.55, 1.0 - skills.attackSpeed * 0.04);

    // Class-specific mod effects — only for relevant class
    if (playerClass == PlayerClass.xenos) {
      if (loadout.gunBarrel == GunBarrelMod.rapid) aspd *= 0.88;
      if (loadout.gunBarrel == GunBarrelMod.heavy) aspd *= 1.12;
    }

    // Overheat slows ONLY bolter ranged (not melee)
    if (!usingMelee &&
        playerClass == PlayerClass.xenos &&
        (rangedWeapon == RangedWeapon.bolter || rangedWeapon == RangedWeapon.rifle) &&
        bolterHeat > 0.7) {
      aspd *= 1.0 + bolterHeat * 0.5;
    }
    if (tacticalMods.contains('Recoil Servo')) aspd *= 0.96;
    attackSpeedMult = aspd * (1 + (gear['attackSpeed'] ?? 0));

    var doctrineDamage = 1.0;
    if (combatDoctrine == CombatDoctrine.heavy) doctrineDamage = 1.12;
    if (combatDoctrine == CombatDoctrine.mobile) doctrineDamage = 0.94;
    if (combatDoctrine == CombatDoctrine.bossHunter) doctrineDamage = 1.08;
    var specializationDamage = 1.0;
    if (specialization == 'executioner' && playerClass == PlayerClass.xenos) specializationDamage = 1.12;
    if (specialization == 'exorcist' && playerClass == PlayerClass.malleus) specializationDamage = 1.12;
    if (specialization == 'duelist' && playerClass == PlayerClass.hereticus) specializationDamage = 1.12;
    var legendaryDamage = 1.0;
    if (legendaryWeapon == 'emperor') legendaryDamage = 1.10;
    if (legendaryWeapon == 'sanctified') legendaryDamage = 1.08;
    if (legendaryWeapon == 'executionerBlade') legendaryDamage = 1.12;
    if (legendaryWeapon == 'warp') legendaryDamage = 1.18;
    final legendaryRankDamage = legendaryWeapon == 'none' ? 1.0 : 1.0 + legendaryWeaponRank * 0.04;
    final oathDamage = oathAcceptedThisRun ? 1.04 : 1.0;
    final woundSpeedPenalty = campaign.fieldWounds > 0 ? max(0.82, 1.0 - campaign.fieldWounds * 0.04) : 1.0;
    playerSpeed *= woundSpeedPenalty;
    final dmgM = (1.0 + skills.damage * 0.06) * playerClass.dmgMod * setBonusDmg * specializationDamage * legendaryDamage * doctrineDamage * legendaryRankDamage * oathDamage * (1 + (gear['damage'] ?? 0));
    double rangedM = dmgM * (1 + (gear['rangedDamage'] ?? 0)) * (1 + codexRangedBonus) * (tacticalMods.contains('Auspex Lens') ? 1.05 : 1.0) * modularWeapon.damageMultiplier;
    double meleeM = dmgM * (1 + (gear['meleeDamage'] ?? 0)) * (1 + codexMeleeBonus) * (modularWeapon.underbarrel == 'bayonet' ? 1.08 : 1.0);
    if (combatDoctrine == CombatDoctrine.melee) { rangedM *= 0.92; meleeM *= 1.15; }

    if (playerClass == PlayerClass.xenos) {
      if (loadout.gunBarrel == GunBarrelMod.heavy) rangedM *= 1.18;
      if (loadout.gunSight == GunSightMod.precision) rangedM *= 1.10;
    }
    if (playerClass == PlayerClass.malleus) {
      // Staff focus: wideSphere = +radius -dmg; focusCore = +dmg -radius; dissipator = -warp stress
      if (loadout.staffFocus == StaffFocusMod.wideSphere) rangedM *= 0.88;
      if (loadout.staffFocus == StaffFocusMod.focusCore) rangedM *= 1.18;
    }
    if (playerClass == PlayerClass.hereticus || usingMelee) {
      if (loadout.bladeEdge == BladeEdgeMod.serrated) meleeM *= 1.08;
      if (loadout.bladeEdge == BladeEdgeMod.monomolecular) meleeM *= 1.12;
      if (loadout.bladeEdge == BladeEdgeMod.weighted) meleeM *= 1.15;
    }

    bolterDamage = (baseBolter * rangedM).round();
    rifleDamage = (baseRifle * rangedM).round();
    shotgunDamage = (baseShotgun * rangedM).round();
    staffDamage = (baseStaff * rangedM).round();
    stormDamage = (baseStorm * rangedM).round();
    warpDamage = (baseWarp * rangedM).round();
    daggerDamage = (baseDagger * rangedM).round();
    needleDamage = (baseNeedle * rangedM).round();
    sniperNeedleDamage = (baseSniperNeedle * rangedM).round();

    final swordM = meleeM * mastery.meleeMasteryMult('sword');
    final axeM = meleeM * mastery.meleeMasteryMult('axe');
    final hammerM = meleeM * mastery.meleeMasteryMult('hammer');
    final katanaM = meleeM * mastery.meleeMasteryMult('katana');
    swordDamage = (baseSword * swordM).round();
    axeDamage = (baseAxe * axeM).round();
    hammerDamage = (baseHammer * hammerM).round();
    forceDamage = (baseForce * meleeM).round();
    forceSwordDamage = (baseForceSword * meleeM).round();
    daemonDamage = (baseDaemon * meleeM).round();
    katanaDamage = (baseKatana * katanaM).round();
    powerKatanaDamage = (basePowerKatana * katanaM).round();
    execDamage = (baseExec * meleeM).round();
  }

  double staffRadiusMult() {
    var m = mastery.staffRadiusMult();
    if (playerClass == PlayerClass.malleus) {
      if (loadout.staffFocus == StaffFocusMod.wideSphere) m *= 1.35;
      if (loadout.staffFocus == StaffFocusMod.focusCore) m *= 0.75;
    }
    return m;
  }

  void spendSkill(String id) {
    if (skillPoints <= 0) return;
    switch (id) {
      case 'hp': skills.hp++; break;
      case 'speed': skills.speed++; break;
      case 'attackSpeed': if (skills.attackSpeed >= 11) return; skills.attackSpeed++; break;
      case 'defense': if (skills.defense >= 15) return; skills.defense++; break;
      case 'damage': skills.damage++; break;
      default: return;
    }
    skillPoints--;
    recomputeStats();
    if (isPlaying) {
      player.maxHealth = maxHealth;
      if (id == 'hp') player.health = min(player.health + 1, maxHealth);
    }
  }

  void grantRelic(RelicId id) {
    relics.add(id);
    if (relics.isNotEmpty) { unlockedAchievementIds.add('first_relic'); }
    persistExpansion();
    recomputeStats();
  }

  bool tryCrit() {
    final chance = (hasCrit ? (synergyTrueFaith ? 0.18 : 0.15) : 0.0) + inquisitionRank.critBonus;
    return chance > 0 && Random().nextDouble() < chance;
  }

  int scaleDamage(int base, {bool isBoss = false, double targetHpRatio = 1.0}) {
    var d = (base * tempDmgMult).round();
    if (isBoss) d = (d * (1 + codexBossBonus)).round();
    if (isBoss && combatDoctrine == CombatDoctrine.bossHunter) d = (d * 1.18).round();
    if (ammoDoctrine == AmmoDoctrine.armorPiercing) d = (d * (isBoss ? 1.12 : 1.06)).round();
    if (ammoDoctrine == AmmoDoctrine.incendiary) d = (d * 1.08).round();
    if (ammoDoctrine == AmmoDoctrine.antiWarp) d = (d * 1.12).round();
    if (hasExecutionerMark && targetHpRatio < 0.30) d = (d * 1.20).round();
    if (tryCrit()) d *= 2;
    return d;
  }

  /// Ordo doctrine is applied at the hit resolution point, so it affects the real
  /// Flame combat loop rather than only the catalogue preview.
  bool unlockOrdoSkill(ordo.OrdoSkill id) {
    final definition = ordo.ordoSkillCatalog.firstWhere((s) => s.id == id);
    final requiredOrdo = switch (playerClass) {
      PlayerClass.malleus => weapon_catalog.WeaponOrdo.malleus,
      PlayerClass.hereticus => weapon_catalog.WeaponOrdo.hereticus,
      PlayerClass.xenos => weapon_catalog.WeaponOrdo.xenos,
    };
    if (definition.ordo != requiredOrdo || expansionSystems.ordoDoctrine.has(id) || skillPoints < definition.cost) return false;
    // Three-step specialization trees: the second and third skill require the
    // previous node, preserving a readable progression path.
    final prerequisites = switch (id) {
      ordo.OrdoSkill.wardingSeal => <ordo.OrdoSkill>[],
      ordo.OrdoSkill.daemonology => <ordo.OrdoSkill>[ordo.OrdoSkill.wardingSeal],
      ordo.OrdoSkill.banishment => <ordo.OrdoSkill>[ordo.OrdoSkill.daemonology],
      ordo.OrdoSkill.witchHunter => <ordo.OrdoSkill>[],
      ordo.OrdoSkill.nullRounds => <ordo.OrdoSkill>[ordo.OrdoSkill.witchHunter],
      ordo.OrdoSkill.interrogator => <ordo.OrdoSkill>[ordo.OrdoSkill.nullRounds],
    };
    if (prerequisites.any((skill) => !expansionSystems.ordoDoctrine.has(skill))) return false;
    skillPoints -= definition.cost;
    final unlocked = <ordo.OrdoSkill>{...expansionSystems.ordoDoctrine.unlockedSkills, id};
    expansionSystems.ordoDoctrine = ordo.OrdoDoctrine(unlockedSkills: unlocked);
    recordChronicle('Доктрина Ордо разблокирована: ${definition.nameRu}.');
    if (isPlaying) {
      world.add(OrdoPulseEffect(position: player.position.clone(), color: definition.ordo == weapon_catalog.WeaponOrdo.malleus ? const Color(0xFFB388FF) : const Color(0xFFFF5252), maxRadius: 115, life: 0.72)..priority = 45);
      spawnDamageNumber(player.position, 0, color: definition.ordo == weapon_catalog.WeaponOrdo.malleus ? const Color(0xFFB388FF) : const Color(0xFFFF5252), label: 'ДОКТРИНА: ${definition.nameRu.toUpperCase()}');
    }
    recomputeStats();
    persistExpansion();
    return true;
  }

  double ordoDamageMultiplierForEnemy(Enemy enemy) {
    final weaponOrdo = switch (rangedWeapon) {
      RangedWeapon.psycannon || RangedWeapon.exorcistIncinerator || RangedWeapon.daemonbanePistol || RangedWeapon.staff || RangedWeapon.stormStaff || RangedWeapon.warpBeam => weapon_catalog.WeaponOrdo.malleus,
      RangedWeapon.condemnorBoltgun || RangedWeapon.sanctifiedStakeCrossbow || RangedWeapon.infernoPistol || RangedWeapon.daggers || RangedWeapon.needles || RangedWeapon.sniperNeedle => weapon_catalog.WeaponOrdo.hereticus,
      _ => playerClass == PlayerClass.malleus ? weapon_catalog.WeaponOrdo.malleus : playerClass == PlayerClass.hereticus ? weapon_catalog.WeaponOrdo.hereticus : weapon_catalog.WeaponOrdo.common,
    };
    final faction = switch (enemy.type) {
      EnemyType.cultPsyker => 'psyker',
      EnemyType.bloodletter || EnemyType.chaosSpawn => 'daemon',
      EnemyType.plagueBearer => 'chaos',
      EnemyType.shooter || EnemyType.melee || EnemyType.shielded || EnemyType.dog || EnemyType.shieldedShooter || EnemyType.flamer || EnemyType.sniper || EnemyType.brute => 'human',
      _ => 'xenos',
    };
    return expansionSystems.ordoDoctrine.damageMultiplier(weaponOrdo: weaponOrdo, targetFaction: faction, damageType: switch (rangedWeapon) {
      RangedWeapon.psycannon || RangedWeapon.daemonbanePistol || RangedWeapon.staff || RangedWeapon.stormStaff || RangedWeapon.warpBeam => weapon_catalog.DamageType.warp,
      RangedWeapon.exorcistIncinerator => weapon_catalog.DamageType.flame,
      RangedWeapon.infernoPistol => weapon_catalog.DamageType.melta,
      _ => weapon_catalog.DamageType.kinetic,
    });
  }

  double get ordoIncomingDamageMultiplier => (1.0 - expansionSystems.ordoDoctrine.warpDefenseBonus).clamp(0.0, 1.0).toDouble();

  void _checkUnlocks() {
    if (overallLevel >= 11) _everReached11 = true;
    if (overallLevel >= 21) _everReached21 = true;
  }

  void spawnDamageNumber(Vector2 pos, int amount, {Color color = const Color(0xFFFFEB3B), String? label}) {
    if (amount <= 0 && label == null) return;
    world.add(DamageNumber(position: pos + Vector2(0, -20), amount: amount, color: color, label: label));
  }

  void spawnBlood(Vector2 pos, {int count = 14, Vector2? fromDir}) =>
      world.add(BloodSplash(position: pos, count: count, fromDir: fromDir));

  void spawnCorruptionZone(Vector2 pos) {
    if (arenaMode) return;
    world.add(CorruptionZone(position: pos.clone())..priority = 4);
  }

  void triggerShake({double power = 6, double time = 0.18}) {
    shakePower = max(shakePower, power);
    shakeTime = max(shakeTime, time);
  }

  void triggerCinemaZoom() {
    cinemaZoomFrom = currentZoom;
    cinemaZoomTo = (currentZoom + 0.22).clamp(0.7, 1.35);
    cinemaZoomTimer = 0.45;
    triggerShake(power: 14, time: 0.35);
  }

  void grantInvuln(double t) {
    invulnTimer = max(invulnTimer, t);
    if (isPlaying) {
      for (int i = 0; i < 3; i++) {
        final offset = player.aimDir * (-18.0 * (i + 1));
        world.add(AfterImage(position: player.position + offset, cls: playerClass, custom: custom)..priority = 14);
      }
    }
  }

  void resetWarpStress({bool free = false}) {
    if (playerClass != PlayerClass.malleus) return;
    if (!free && warpResetCooldown > 0) return;
    if (!free && !hasWarpAnchor && skillPoints < 1 && warpResetCooldown > 0) return;
    if (!free && !hasWarpAnchor) {
      // costs 1 SP if no anchor and not on free cooldown path
      if (skillPoints >= 1) {
        skillPoints--;
      } else if (warpResetCooldown > 0) {
        return;
      }
    }
    staffWarpStress = 0;
    warpStability = min(100.0, warpStability + (free ? 4 : 10)).toDouble();
    warpResetCooldown = hasWarpAnchor ? 12.0 : 8.0;
    spawnDamageNumber(player.position, 0, color: const Color(0xFFB388FF), label: 'Ψ СБРОС');
    playClick();
  }

  String _masteryKeyForKill() {
    if (usingMelee) return meleeWeapon.name;
    return rangedWeapon.name;
  }

  void registerKill({Vector2? at, bool isBoss = false, bool isChampion = false, bool meleeKill = false, Vector2? fromDir}) {
    combo++;
    comboTimer = comboWindow;
    mastery.addKill(_masteryKeyForKill());
    for (final m in [5, 10, 15]) {
      if (combo >= m && !_comboMilestonesClaimed.contains(m)) {
        _comboMilestonesClaimed.add(m);
        scraps += 1;
        if (at != null) spawnDamageNumber(at + Vector2(0, -36), 0, color: const Color(0xFFFFD700), label: 'COMBO +1');
      }
    }
    if (combo >= 3 && combo % 3 == 0) camera.viewport.add(ComboBanner(combo: combo));
    if (at != null) {
      spawnBlood(at, count: isBoss || isChampion ? 28 : 14, fromDir: fromDir);
      if (isBoss) spawnCorruptionZone(at);
      if (hasKillExplosion) {
        world.add(KillExplosion(
          position: at.clone(),
          radius: isBoss ? 90 : (isChampion ? 70 : 55),
          damage: 8 + overallLevel,
          applyBurn: synergyFireCrits,
        )..priority = 12);
      }
    }
    if (hasLifesteal) {
      final chance = synergyBloodRush ? 0.28 : 0.15;
      final heal = synergyBloodRush ? 2 : 1;
      if (Random().nextDouble() < chance) {
        player.health = min(player.maxHealth, player.health + heal);
      }
    }
    if (hasHaste) _hasteTimer = synergyBloodRush ? 4.5 : 3.0;
    if (meleeKill && synergyHereticusBleedDash) {
      hereticusDashBoost = 2.5;
      if (activeChallenge != RankChallenge.noDash) {
        hasDashAbility = true;
        _ensureDashButton();
      }
      dashCooldown = min(dashCooldown, 1.0);
    }
    var gain = isBoss ? (8 + Random().nextInt(8)) : (isChampion ? (5 + Random().nextInt(5)) : (1 + Random().nextInt(3)));
    if (isChampion) gain = (gain * (1 + codexEliteScrapBonus)).round();
    if (hasScavenger && (isChampion || isBoss)) gain = (gain * 1.35).round();
    gain = (gain * inquisitionRank.scrapMult).round();
    scraps += gain;
    if (isChampion && Random().nextDouble() < 0.22) {
      final missing = RelicId.values.where((r) => !relics.contains(r)).toList();
      if (missing.isNotEmpty) grantRelic(missing[Random().nextInt(missing.length)]);
    }
  }

  void rememberBossEcho(EchoBossKind kind) => pendingEcho = kind;

  void noteBossDamagedByRanged() {
    if (activeChallenge == RankChallenge.meleeBossOnly) {
      challengeBossMeleeOk = false;
    }
  }

  void markBossRetreat() => bossRetreatTimer = 0.8;

  EliteAffix rollAffix() {
    final r = Random().nextDouble();
    if (r < 0.18) return EliteAffix.swift;
    if (r < 0.36) return EliteAffix.regenerating;
    if (r < 0.52) return EliteAffix.explosive;
    if (r < 0.68) return EliteAffix.reflect;
    if (r < 0.85) return EliteAffix.summoner;
    return EliteAffix.swift;
  }

  BulletMod rollBulletMod() {
    if (overallLevel < 6) return BulletMod.normal;
    final r = Random().nextDouble();
    if (r < 0.08) return BulletMod.slow;
    if (r < 0.14) return BulletMod.ricochet;
    if (r < 0.18 && overallLevel >= 12) return BulletMod.split;
    return BulletMod.normal;
  }

  /// Path: always ends with boss; length = 5 nodes per floor (synced with currentLevel 1..5)
  void generateFloorPath() {
    floorPath = [];
    pathIndex = 0;
    // Five nodes per floor; the fifth is always the floor boss.
    for (int i = 0; i < 5; i++) {
      if (i == 4) {
        floorPath.add(PathNode(PathNodeKind.boss, 'Босс'));
      } else if (i == 0) {
        floorPath.add(PathNode(PathNodeKind.combat, 'Бой'));
      } else if (i == 2) {
        final r = Random().nextDouble();
        if (r < 0.22) {
          floorPath.add(PathNode(PathNodeKind.elite, 'Элита'));
        } else if (r < 0.42) {
          floorPath.add(PathNode(PathNodeKind.hunt, 'Охота'));
        } else if (r < 0.62) {
          floorPath.add(PathNode(PathNodeKind.combat, 'Бой'));
        } else if (r < 0.82) {
          floorPath.add(PathNode(PathNodeKind.event, 'Событие'));
        } else {
          floorPath.add(PathNode(PathNodeKind.survival, 'Выживание'));
        }
      } else {
        final r = Random().nextDouble();
        if (r < 0.22) {
          floorPath.add(PathNode(PathNodeKind.event, 'Событие'));
        } else if (r < 0.34) {
          floorPath.add(PathNode(PathNodeKind.elite, 'Элита'));
        } else if (r < 0.45) {
          floorPath.add(PathNode(PathNodeKind.rest, 'Отдых'));
        } else if (r < 0.56) {
          floorPath.add(PathNode(PathNodeKind.defense, 'Оборона'));
        } else if (r < 0.66) {
          floorPath.add(PathNode(PathNodeKind.ritual, 'Ритуал'));
        } else if (r < 0.76) {
          floorPath.add(PathNode(PathNodeKind.survival, 'Выживание'));
        } else {
          floorPath.add(PathNode(PathNodeKind.combat, 'Бой'));
        }
      }
    }
  }

  void syncLevelFromPath() {
    currentLevel = (pathIndex + 1).clamp(1, 5);
    final kind = pathIndex < floorPath.length ? floorPath[pathIndex].kind : PathNodeKind.combat;
    isBossLevel = kind == PathNodeKind.boss;
    isMiniBossLevel = !isBossLevel && (currentLevel == 3 || kind == PathNodeKind.hunt) && kind != PathNodeKind.survival;
    isEliteNode = kind == PathNodeKind.elite;
    isSurvivalNode = kind == PathNodeKind.survival;
  }

  EventRoomType _rollEvent() {
    levelsSinceEvent++;
    if (isBossLevel || isMiniBossLevel || arenaMode) return EventRoomType.none;
    if (levelsSinceEvent < 2) return EventRoomType.none;
    if (levelsSinceEvent >= 3 || Random().nextDouble() < 0.62) {
      levelsSinceEvent = 0;
      final r = Random().nextDouble();
      if (r < 0.38) return EventRoomType.altar;
      if (r < 0.70) return EventRoomType.merchant;
      return EventRoomType.trap;
    }
    return EventRoomType.none;
  }

  void _spawnEventProps() {
    if (currentEvent == EventRoomType.none) return;
    final pos = Vector2(mapWidth / 2, mapHeight / 2 - 80);
    switch (currentEvent) {
      case EventRoomType.altar:
        world.add(EventAltarProp(position: pos)..priority = 8);
        break;
      case EventRoomType.merchant:
        world.add(EventMerchantProp(position: pos)..priority = 8);
        break;
      case EventRoomType.trap:
      case EventRoomType.none:
        break;
    }
  }

  void openEventAltar() {
    if (eventResolved || currentEvent != EventRoomType.altar) return;
    isPaused = true;
    overlays.add('eventAltar');
  }

  void openEventMerchant() {
    if (eventResolved || currentEvent != EventRoomType.merchant) return;
    isPaused = true;
    overlays.add('eventMerchant');
  }

  void resolveAltar({required bool accept}) {
    overlays.remove('eventAltar');
    isPaused = false;
    eventResolved = true;
    if (accept && player.health > 1) {
      player.health = max(1, player.health - 1);
      final missing = RelicId.values.where((r) => !relics.contains(r)).toList();
      if (missing.isNotEmpty) {
        grantRelic(missing[Random().nextInt(missing.length)]);
        spawnDamageNumber(player.position, 0, color: const Color(0xFFFFD700), label: 'РЕЛИКВИЯ');
      } else {
        scraps += 15;
        skillPoints += 1;
      }
    }
    playClick();
  }

  void resolveMerchantBuy(String id) {
    switch (id) {
      case 'heal':
        if (scraps < 10) return;
        scraps -= 10;
        player.health = min(player.maxHealth, player.health + 2);
        break;
      case 'scraps_sp':
        if (scraps < 18) return;
        scraps -= 18;
        skillPoints += 1;
        break;
      case 'relic':
        if (scraps < 25) return;
        final missing = RelicId.values.where((r) => !relics.contains(r)).toList();
        if (missing.isEmpty) return;
        scraps -= 25;
        grantRelic(missing[Random().nextInt(missing.length)]);
        break;
      // Class weapon mods
      case 'gun_rapid':
        if (playerClass != PlayerClass.xenos || scraps < 14) return;
        scraps -= 14;
        loadout.gunBarrel = GunBarrelMod.rapid;
        recomputeStats();
        break;
      case 'gun_heavy':
        if (playerClass != PlayerClass.xenos || scraps < 14) return;
        scraps -= 14;
        loadout.gunBarrel = GunBarrelMod.heavy;
        recomputeStats();
        break;
      case 'gun_precision':
        if (playerClass != PlayerClass.xenos || scraps < 12) return;
        scraps -= 12;
        loadout.gunSight = GunSightMod.precision;
        recomputeStats();
        break;
      case 'gun_wide':
        if (playerClass != PlayerClass.xenos || scraps < 12) return;
        scraps -= 12;
        loadout.gunSight = GunSightMod.wide;
        recomputeStats();
        break;
      case 'gun_explosive':
        if (playerClass != PlayerClass.xenos || scraps < 16) return;
        scraps -= 16;
        loadout.gunAmmo = GunAmmoMod.explosive;
        recomputeStats();
        break;
      case 'staff_wide':
        if (playerClass != PlayerClass.malleus || scraps < 14) return;
        scraps -= 14;
        loadout.staffFocus = StaffFocusMod.wideSphere;
        recomputeStats();
        break;
      case 'staff_focus':
        if (playerClass != PlayerClass.malleus || scraps < 14) return;
        scraps -= 14;
        loadout.staffFocus = StaffFocusMod.focusCore;
        recomputeStats();
        break;
      case 'staff_dissipator':
        if (playerClass != PlayerClass.malleus || scraps < 12) return;
        scraps -= 12;
        loadout.staffFocus = StaffFocusMod.dissipator;
        recomputeStats();
        break;
      case 'blade_serrated':
        if (playerClass != PlayerClass.hereticus || scraps < 12) return;
        scraps -= 12;
        loadout.bladeEdge = BladeEdgeMod.serrated;
        recomputeStats();
        break;
      case 'blade_mono':
        if (playerClass != PlayerClass.hereticus || scraps < 14) return;
        scraps -= 14;
        loadout.bladeEdge = BladeEdgeMod.monomolecular;
        recomputeStats();
        break;
      case 'blade_weighted':
        if (playerClass != PlayerClass.hereticus || scraps < 14) return;
        scraps -= 14;
        loadout.bladeEdge = BladeEdgeMod.weighted;
        recomputeStats();
        break;
      default:
        return;
    }
    playClick();
  }

  void closeMerchant() {
    overlays.remove('eventMerchant');
    isPaused = false;
    eventResolved = true;
    playClick();
  }

  void _startTrapWave() {
    eventResolved = true;
    // Trap rooms now become biome-specific ambush events instead of identical generic waves.
    final biome = activeBiome;
    final n = 4 + currentFloor + (biome == BiomeId.voidship || biome == BiomeId.necronTomb ? 1 : 0);
    String eventLabel = 'ЗАСАДА!';
    for (int i = 0; i < n; i++) {
      enemiesToSpawn++;
      enemiesAlive++;
      enemiesSpawned++;
      final points = getEnemySpawnPoints();
      if (points.isEmpty) continue;
      final EnemyType type = switch (biome) {
        BiomeId.voidship => i % 3 == 0 ? EnemyType.shieldedShooter : EnemyType.shooter,
        BiomeId.necronTomb => i % 4 == 0 && currentFloor >= 7 ? EnemyType.necronImmortal : EnemyType.necronWarrior,
        BiomeId.deathWorld => i % 3 == 0 ? EnemyType.genestealer : EnemyType.tyranidGaunt,
        BiomeId.warpRuin => i % 3 == 0 ? EnemyType.bloodletter : EnemyType.cultPsyker,
        BiomeId.hive => i % 3 == 0 ? EnemyType.dog : EnemyType.melee,
        BiomeId.shrine => i % 3 == 0 ? EnemyType.cultPsyker : EnemyType.bloodletter,
        BiomeId.manufactorum => i % 3 == 0 ? EnemyType.orkBoy : EnemyType.shooter,
      };
      final e = Enemy(
        floor: currentFloor,
        type: type,
        isChampion: i == 0 && overallLevel >= 5,
        affix: i == 0 && overallLevel >= 5 ? rollAffix() : EliteAffix.none,
      );
      e.position = points[Random().nextInt(points.length)].clone();
      e.priority = 30;
      world.add(e);
    }
    if (biome == BiomeId.voidship) eventLabel = 'АБОРДАЖНАЯ ТРЕВОГА!';
    if (biome == BiomeId.necronTomb) eventLabel = 'ПРОБУЖДЕНИЕ ГРОБНИЦЫ!';
    if (biome == BiomeId.deathWorld) eventLabel = 'ЗАСАДА РОЯ!';
    if (biome == BiomeId.warpRuin) eventLabel = 'ВАРП-РАЗЛОМ!';
    spawnDamageNumber(player.position, 0, color: const Color(0xFFFF1744), label: eventLabel);
    triggerShake(power: 8, time: 0.25);
  }

  Future<void> recordVictoryRank() async {
    final prevWins = inquisitionRank.wins;
    inquisitionRank.wins++;
    if (activeChallenge != RankChallenge.none) {
      if (activeChallenge == RankChallenge.meleeBossOnly && challengeBossMeleeOk) {
        inquisitionRank.wins++;
      } else if (activeChallenge == RankChallenge.noDash) {
        inquisitionRank.wins++;
      }
    }
    // Every 2 wins → offer perk choice once
    if (inquisitionRank.wins ~/ 2 > prevWins ~/ 2 && inquisitionRank.chosenPerk == RankPerk.none) {
      // will show rank perk menu from victory if needed
    }
    await persistRank();
  }

  weapon_catalog.WeaponData get activeWeaponData => weapon_catalog.WeaponData.forLegacyName(rangedWeapon.name);

  void rollWorldAndMissionEvents({int? seed}) {
    currentWorldEvent = worldDirector.rollEvent(expansionBiome, floor: currentFloor, seed: seed);
    currentMissionEvent = missionEvents.roll(floor: currentFloor, alarm: campaign.alarm, seed: seed == null ? null : seed + 17);
    if (currentWorldEvent != null) {
      currentWorldEventEffects = worldDirector.applyEventModifiers(currentWorldEvent!, this);
      requisition += currentWorldEventEffects!.bonusRequisition;
      campaignChronicle.insert(0, 'Событие мира: ${currentWorldEvent!.title} — ${currentWorldEvent!.description}');
    }
    if (currentMissionEvent != null) {
      campaignChronicle.insert(0, 'Событие расследования: ${currentMissionEvent!.title}');
    }
    if (campaignChronicle.length > 80) campaignChronicle.removeRange(80, campaignChronicle.length);
  }

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2(mapWidth, mapHeight);
    camera.viewfinder.zoom = currentZoom;
    for (int i = 0; i < _sfxPoolSize; i++) {
      _sfxPool.add(AudioPlayer());
    }
    await loadPersistedData();
  }

  Future<void> _playSfx(String file) async {
    if (!soundEnabled) return;
    try {
      final p = _sfxPool[_sfxIdx % _sfxPoolSize];
      _sfxIdx++;
      await p.stop();
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setVolume(soundVolume);
      await p.play(AssetSource('sounds/$file'));
    } catch (_) {
      try {
        final p = AudioPlayer();
        await p.setVolume(soundVolume);
        await p.play(AssetSource('sounds/$file'));
      } catch (_) {}
    }
  }

  void playShoot() => _playSfx('shoot.mp3');
  void playMelee() => _playSfx('melee.mp3');
  void playClick() => _playSfx('click.mp3');

  Future<void> startMusic() async {
    if (!musicEnabled) return;
    try {
      if (_bgmPlayer != null) {
        final st = _bgmPlayer!.state;
        if (st == PlayerState.playing || st == PlayerState.paused) {
          await _bgmPlayer!.setVolume(musicVolume);
          if (st == PlayerState.paused) await _bgmPlayer!.resume();
          return;
        }
      }
      await stopMusic();
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setPlayerMode(PlayerMode.mediaPlayer);
      await p.setVolume(musicVolume);
      await p.play(AssetSource('sounds/bgm.mp3'));
      _bgmPlayer = p;
    } catch (_) {
      try {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setPlayerMode(PlayerMode.mediaPlayer);
        await p.setVolume(musicVolume);
        await p.play(AssetSource('bgm.mp3'));
        _bgmPlayer = p;
      } catch (_) {}
    }
  }

  Future<void> stopMusic() async {
    try {
      await _bgmPlayer?.stop();
      await _bgmPlayer?.dispose();
    } catch (_) {}
    _bgmPlayer = null;
  }

  void applyMusicSetting() {
    if (musicEnabled && isPlaying) {
      startMusic();
    } else if (!musicEnabled) {
      stopMusic();
    }
  }

  Future<void> loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // A damaged control-layout preference must never prevent campaign saves from loading.
      try {
        final layoutJson = prefs.getString('control_layout');
        if (layoutJson != null) {
          final layout = Map<String, dynamic>.from(jsonDecode(layoutJson) as Map);
          moveJoystickLeft = ((layout['moveLeft'] as num?)?.toDouble() ?? 52).clamp(0, 220).toDouble();
          moveJoystickBottom = ((layout['moveBottom'] as num?)?.toDouble() ?? 52).clamp(0, 260).toDouble();
          attackJoystickRight = ((layout['attackRight'] as num?)?.toDouble() ?? 52).clamp(0, 220).toDouble();
          attackJoystickBottom = ((layout['attackBottom'] as num?)?.toDouble() ?? 52).clamp(0, 260).toDouble();
          abilityClusterLeft = ((layout['abilityLeft'] as num?)?.toDouble() ?? 32).clamp(0, 240).toDouble();
          abilityClusterBottom = ((layout['abilityBottom'] as num?)?.toDouble() ?? 160).clamp(100, 360).toDouble();
          weaponButtonRight = ((layout['weaponRight'] as num?)?.toDouble() ?? 52).clamp(0, 220).toDouble();
          weaponButtonBottom = ((layout['weaponBottom'] as num?)?.toDouble() ?? 160).clamp(100, 360).toDouble();
        }
      } catch (_) {}
      final hs = prefs.getString('high_scores');
      if (hs != null) {
        highScores = (jsonDecode(hs) as List)
            .map((e) => HighScoreEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final sv = prefs.getString('game_saves');
      if (sv != null) {
        saves = (jsonDecode(sv) as List)
            .map((e) => GameSave.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final cu = prefs.getString('customization');
      if (cu != null) custom = Customization.fromJson(Map<String, dynamic>.from(jsonDecode(cu) as Map));
      final cx = prefs.getString('codex');
      if (cx != null) {
        final list = (jsonDecode(cx) as List).map((e) => e.toString());
        codexUnlocked.addAll(list.map((n) => CodexId.values.firstWhere((e) => e.name == n, orElse: () => CodexId.shooter)));
      }
      final lr = prefs.getString('lore_ranks');
      if (lr != null) {
        final map = Map<String, dynamic>.from(jsonDecode(lr) as Map);
        map.forEach((k, v) {
          final id = CodexId.values.firstWhere((e) => e.name == k, orElse: () => CodexId.shooter);
          loreRanks[id] = (v as num?)?.toInt() ?? 0;
        });
      }
      final rk = prefs.getString('inquisition_rank');
      if (rk != null) inquisitionRank = InquisitionRank.fromJson(Map<String, dynamic>.from(jsonDecode(rk) as Map));
      final wm = prefs.getString('weapon_mastery');
      if (wm != null) mastery = WeaponMastery.fromJson(Map<String, dynamic>.from(jsonDecode(wm) as Map));
      final ex = prefs.getString('inquisition_expansion');
      if (ex != null) {
        final data = Map<String, dynamic>.from(jsonDecode(ex) as Map);
        if (data['ordoSkillPoints'] is num) skillPoints = max(0, (data['ordoSkillPoints'] as num).toInt());
        if (data['expansionSystems'] is Map) {
          expansionSystems.loadJson(data['expansionSystems']);
          equipmentInventory.state.loadJson(data['equipmentInventory'] ?? (data['expansionSystems'] is Map ? (data['expansionSystems'] as Map)['inventory'] : null));
          progressionTrack.loadJson((data['expansionSystems'] as Map)['progression']);
        }
        arsenalUpgrade = ((data['arsenal'] as num?)?.toInt() ?? 0).clamp(0, 5);
        shrineUpgrade = ((data['shrine'] as num?)?.toInt() ?? 0).clamp(0, 5);
        archiveUpgrade = ((data['archive'] as num?)?.toInt() ?? 0).clamp(0, 5);
        medicaeUpgrade = ((data['medicae'] as num?)?.toInt() ?? 0).clamp(0, 5);
        inquisitionAlignment = data['alignment'] as String? ?? 'puritan';
        specialization = data['specialization'] as String? ?? 'balanced';
        legendaryWeapon = data['legendary'] as String? ?? 'none';
        legendaryWeaponRank = ((data['legendaryWeaponRank'] as num?)?.toInt() ?? 0).clamp(0, 3);
        investigationsResolved = (data['investigations'] as num?)?.toInt() ?? 0;
        warpStability = ((data['warpStability'] as num?)?.toDouble() ?? 100.0).clamp(0.0, 100.0).toDouble();
        activeArmor = ArmorPattern.values.firstWhere((e) => e.name == data['activeArmor'], orElse: () => ArmorPattern.inquisitorial);
        ownedArmor.clear();
        ownedArmor.addAll(((data['ownedArmor'] as List?) ?? ['flak', 'inquisitorial']).map((e) => ArmorPattern.values.firstWhere((a) => a.name == e.toString(), orElse: () => ArmorPattern.flak)));
        campaignChronicle.clear();
        campaignChronicle.addAll(((data['campaignChronicle'] as List?) ?? const []).map((e) => e.toString()).take(80));
        armorForgePurchases = (data['armorForgePurchases'] as num?)?.toInt() ?? 0;
        modularWeapon.load(data['modularWeapon'] is Map ? Map<String, dynamic>.from(data['modularWeapon'] as Map) : null);
        storedItems.clear();
        if (data['storedItems'] is List) { for (final e in data['storedItems'] as List) { if (e is Map) { try { storedItems.add(StoredInventoryItem.fromJson(Map<String, dynamic>.from(e))); } catch (_) {} } } }
        requisition = (data['requisition'] as num?)?.toInt() ?? 120;
        permanentSkillBonus = (data['permanentSkillBonus'] as num?)?.toInt() ?? 0;
        artifactInvestigationResolved = data['artifactInvestigationResolved'] as bool? ?? false;
        showSecretSignals = data['showSecretSignals'] as bool? ?? true;
        combatDoctrine = CombatDoctrine.values.firstWhere((e) => e.name == data['combatDoctrine'], orElse: () => CombatDoctrine.balanced);
        ammoDoctrine = AmmoDoctrine.values.firstWhere((e) => e.name == data['ammoDoctrine'], orElse: () => AmmoDoctrine.standard);
        arenaModifier = ArenaModifier.values.firstWhere((e) => e.name == data['arenaModifier'], orElse: () => ArenaModifier.none);
        servoSkullLevel = ((data['servoSkullLevel'] as num?)?.toInt() ?? 0).clamp(0, 3);
        secretBossesDefeatedTotal = (data['secretBossesDefeatedTotal'] as num?)?.toInt() ?? 0;
        tacticalAchievements = (data['tacticalAchievements'] as num?)?.toInt() ?? 0;
        contractsCompleted = (data['contractsCompleted'] as num?)?.toInt() ?? 0;
        if (data['campaignState'] is Map) campaign.load(Map<String, dynamic>.from(data['campaignState'] as Map));
        fieldInventory.clear();
        if (data['fieldInventory'] is List) {
          for (final e in data['fieldInventory'] as List) { if (e is Map) fieldInventory.add(FieldLootItem.fromJson(Map<String, dynamic>.from(e))); }
        }
        collectedLootIds.clear();
        if (data['collectedLootIds'] is List) collectedLootIds.addAll((data['collectedLootIds'] as List).map((e) => e.toString()));
        discoveredCacheIds.clear();
        if (data['discoveredCacheIds'] is List) discoveredCacheIds.addAll((data['discoveredCacheIds'] as List).map((e) => e.toString()));
        backpackUpgradeLevel = ((data['backpackUpgradeLevel'] as num?)?.toInt() ?? 0).clamp(0, 3).toInt();
        operationSerial = (data['operationSerial'] as num?)?.toInt() ?? 0;
        if (data['tacticalMods'] is List) { tacticalMods..clear()..addAll((data['tacticalMods'] as List).map((e) => e.toString()).take(3)); }
        backpackCapacity = 16 + backpackUpgradeLevel * 4;
        highThreatOperation = data['highThreatOperation'] as bool? ?? false;
        if (data['unlockedAchievementIds'] is List) {
          unlockedAchievementIds..clear()..addAll((data['unlockedAchievementIds'] as List).map((e) => e.toString()));
        }
        careerOperationsCompleted = ((data['careerOperationsCompleted'] as num?)?.toInt() ?? 0).clamp(0, 1000000);
        careerFloorsReached = ((data['careerFloorsReached'] as num?)?.toInt() ?? 1).clamp(1, 1000000);
        careerKills = ((data['careerKills'] as num?)?.toInt() ?? 0).clamp(0, 100000000);
        careerEvidenceFound = ((data['careerEvidenceFound'] as num?)?.toInt() ?? 0).clamp(0, 1000000);
        operationThreatLevel = ((data['operationThreatLevel'] as num?)?.toInt() ?? 0).clamp(0, 5);
        evacuationRoute = ((data['evacuationRoute'] as num?)?.toInt() ?? 0).clamp(0, 2).toInt();
        terminalsActivated = (data['terminalsActivated'] as num?)?.toInt() ?? 0;
        supplyCachesOpened = (data['supplyCachesOpened'] as num?)?.toInt() ?? 0;
        randomMissionEvents = (data['randomMissionEvents'] as num?)?.toInt() ?? 0;
        if (data['consumables'] is Map) {
          final cm = Map<String, dynamic>.from(data['consumables'] as Map);
          for (final c in TacticalConsumable.values) { consumables[c] = ((cm[c.name] as num?)?.toInt() ?? consumables[c] ?? 0).clamp(0, 99); }
        }
      }
    } catch (_) {}
  }

  Future<void> persistRank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inquisition_rank', jsonEncode(inquisitionRank.toJson()));
      await prefs.setString('weapon_mastery', jsonEncode(mastery.toJson()));
      await prefs.setString(
        'lore_ranks',
        jsonEncode(loreRanks.map((k, v) => MapEntry(k.name, v))),
      );
    } catch (_) {}
  }

  LootRarity _rollLootRarity(Random rng) {
    final roll = rng.nextDouble();
    if (roll > 0.992) return LootRarity.legendary;
    if (roll > 0.955) return LootRarity.epic;
    if (roll > 0.84) return LootRarity.rare;
    if (roll > 0.58) return LootRarity.uncommon;
    return LootRarity.common;
  }

  void spawnFieldLoot(Vector2 pos, {bool secret = false, Random? random}) {
    final rng = random ?? Random();
    final kind = secret ? LootKind.relicShard : LootKind.values[rng.nextInt(LootKind.values.length)];
    final rarity = secret ? (rng.nextBool() ? LootRarity.rare : LootRarity.epic) : _rollLootRarity(rng);
    final names = <LootKind, List<String>>{
      LootKind.ammunition: ['Болт-патроны', 'Энергокассета', 'Прометиевый заряд'],
      LootKind.medicae: ['Медикаментозный пакет', 'Гель-аутопласт', 'Набор стабилизации'],
      LootKind.requisition: ['Жетоны реквизиции', 'Имперские кредиты'],
      LootKind.weaponPart: ['Деталь оружия', 'Сервопривод', 'Усиленный затвор'],
      LootKind.evidence: ['Запись допроса', 'Культовый шифр', 'Ксенос-образец'],
      LootKind.keycard: ['Ключ-карта доступа'], LootKind.relicShard: ['Осколок реликвии'],
      LootKind.stim: ['Боевой стимулятор'], LootKind.grenade: ['Осколочная граната'], LootKind.mod: ['Тактический модуль'],
    };
    final nameList = names[kind] ?? ['Полевой предмет'];
    final id = 'op$operationSerial-f${currentFloor}-n${pathIndex}-${pos.x.round()}-${pos.y.round()}-${kind.name}';
    if (collectedLootIds.contains(id)) return;
    world.add(FieldLootPickup(position: pos, item: FieldLootItem(
      id: id, kind: kind, rarity: rarity, name: nameList[rng.nextInt(nameList.length)],
      value: (1 + rng.nextInt(3)) * (rarity.index + 1), floorFound: currentFloor,
      mark: playerClass == PlayerClass.malleus ? 'MALLEUS' : playerClass == PlayerClass.hereticus ? 'HERETICUS' : 'XENOS',
    ), secret: secret)..priority = 7);
  }

  /// Keep a clear deployment-to-objective corridor plus a central north/south lane.
  bool isInGuaranteedPath(Vector2 p, {double halfWidth = 76}) {
    final centerX = mapWidth / 2;
    final centerY = mapHeight / 2;
    final verticalLane = (p.x - centerX).abs() < halfWidth;
    final spawnLane = (p.y - playerSpawnPos.y).abs() < halfWidth && p.x > centerX - 260 && p.x < centerX + 260;
    final objectiveLane = (p.y - centerY).abs() < halfWidth && p.x > 90 && p.x < mapWidth - 90;
    return verticalLane || spawnLane || objectiveLane;
  }

  bool collectFieldLoot(FieldLootItem item, {bool secret = false}) {
    if (collectedLootIds.contains(item.id)) return false;
    if (fieldInventory.length >= backpackCapacity) {
      spawnDamageNumber(player.position, 0, color: const Color(0xFFFF7043), label: 'РЮКЗАК ПОЛОН');
      return false;
    }
    collectedLootIds.add(item.id);
    fieldInventory.add(item);
    if (secret) { discoveredCacheIds.add(item.id); supplyCachesOpened++; }
    spawnDamageNumber(player.position, 0, color: item.rarity.color, label: '+ ${item.name}');
    persistExpansion();
    return true;
  }

  void salvageFieldItem(FieldLootItem item) {
    if (!fieldInventory.remove(item)) return;
    final gain = max(1, item.value * (item.rarity.index + 1));
    scraps += gain;
    requisition += item.rarity.index >= 3 ? 1 : 0;
    spawnDamageNumber(player.position, 0, color: item.rarity.color, label: 'РАЗБОР +$gain ОБЛОМКОВ');
    persistExpansion();
  }

  void useFieldConsumable(TacticalConsumable item) {
    final count = consumables[item] ?? 0;
    if (count <= 0 || !isPlaying) return;
    consumables[item] = count - 1;
    switch (item) {
      case TacticalConsumable.fragGrenade:
        world.add(KillExplosion(position: player.position.clone(), radius: 150, damage: 18 + currentFloor * 3)..priority = 12);
        triggerShake(power: 5, time: 0.18);
        break;
      case TacticalConsumable.stim:
        player.health = min(player.maxHealth, player.health + 2);
        _hasteTimer = max(_hasteTimer, 4.0);
        spawnDamageNumber(player.position, 0, color: const Color(0xFF80CBC4), label: 'СТИМ');
        break;
      case TacticalConsumable.smoke:
        for (final e in world.children.whereType<Enemy>()) {
          if (e.position.distanceTo(player.position) < 250) e.applyStatus(StatusType.slow, 3.0, tickDamage: 0);
        }
        spawnDamageNumber(player.position, 0, color: const Color(0xFFB0BEC5), label: 'ДЫМОВАЯ ЗАВЕСА');
        break;
      case TacticalConsumable.auspexPulse:
        for (final e in world.children.whereType<Enemy>()) {
          if (e.position.distanceTo(player.position) < 420) { e.suppression = min(100, e.suppression + 35); e.applyStatus(StatusType.slow, 1.5, tickDamage: 0); }
        }
        spawnDamageNumber(player.position, 0, color: const Color(0xFF4FC3F7), label: 'АУСПЕКС: ЦЕЛИ ПОМЕЧЕНЫ');
        break;
    }
    persistExpansion();
  }

  /// Resolve a field investigation. Every choice has immediate and persistent consequences.
  Future<void> resolveFieldDecision(InvestigationDecision decision) async {
    switch (decision) {
      case InvestigationDecision.preserveEvidence:
        campaign.evidencePreserved++;
        campaign.evidence++;
        campaign.cluesFound++;
        campaign.alarm = min(100, campaign.alarm + 8);
        campaign.suspicion = max(0, campaign.suspicion - 4);
        campaign.consequenceScore += 2;
        requisition += 6;
        campaign.lastReport = 'Улики сохранены: досье усилено, но противник заметил вмешательство.';
        break;
      case InvestigationDecision.destroyEvidence:
        campaign.evidenceDestroyed++;
        campaign.evidence = max(0, campaign.evidence - 1);
        campaign.alarm = max(0, campaign.alarm - 12);
        campaign.suspicion = min(100, campaign.suspicion + 8);
        campaign.consequenceScore -= 1;
        warpStability = min(100.0, warpStability + 8).toDouble();
        campaign.lastReport = 'Улики уничтожены: давление на поле боя снизилось, но доказательства утрачены.';
        break;
      case InvestigationDecision.bargainWithInformant:
        campaign.informantDebt++;
        campaign.evidence++;
        campaign.cluesFound++;
        campaign.suspicion = min(100, campaign.suspicion + 5);
        campaign.alarm = max(0, campaign.alarm - 5);
        requisition += 10;
        warpStability = max(0.0, warpStability - 5).toDouble();
        campaign.consequenceScore += 1;
        campaign.lastReport = 'Информатор помог за цену: получены сведения и снабжение, долг остался в досье.';
        break;
    }
    recordCareerProgress(evidence: decision == InvestigationDecision.destroyEvidence ? 0 : 1, save: false);
    await persistExpansion();
    spawnDamageNumber(player.position, 0, color: const Color(0xFF80CBC4), label: switch (decision) {
      InvestigationDecision.preserveEvidence => 'УЛИКИ СОХРАНЕНЫ',
      InvestigationDecision.destroyEvidence => 'УЛИКИ УНИЧТОЖЕНЫ',
      InvestigationDecision.bargainWithInformant => 'СДЕЛКА ЗАКЛЮЧЕНА',
    });
  }

  void cycleModularWeaponPart(String slot) {
    const choices = <String, List<String>>{
      'receiver': ['standard', 'heavy', 'light'], 'barrel': ['balanced', 'long', 'vented'],
      'sight': ['iron', 'auspex', 'scope', 'wide'], 'feed': ['standard', 'rapid', 'heavy'],
      'underbarrel': ['none', 'bayonet', 'suppressor'], 'core': ['standard', 'sanctified', 'unstable'],
    };
    final list = choices[slot];
    if (list == null) return;
    final current = switch (slot) {
      'receiver' => modularWeapon.receiver, 'barrel' => modularWeapon.barrel, 'sight' => modularWeapon.sight,
      'feed' => modularWeapon.feed, 'underbarrel' => modularWeapon.underbarrel, _ => modularWeapon.core,
    };
    final next = list[(list.indexOf(current) + 1) % list.length];
    switch (slot) {
      case 'receiver': modularWeapon.receiver = next; break; case 'barrel': modularWeapon.barrel = next; break;
      case 'sight': modularWeapon.sight = next; break; case 'feed': modularWeapon.feed = next; break;
      case 'underbarrel': modularWeapon.underbarrel = next; break; case 'core': modularWeapon.core = next; break;
    }
    recomputeStats();
    persistExpansion();
  }

  void grantStarterGear() {
    if (equipmentInventory.state.backpack.isNotEmpty || equipmentInventory.state.equipped.isNotEmpty || equipmentInventory.state.vault.isNotEmpty) return;
    final items = <gear_catalog.GearItem>[
      const gear_catalog.GearItem(id:'gear-flak-vest',name:'Панцирь караула',slot:'armor',rarity:0,power:5,modifiers:{'health':1,'defense':0.025},setId:'inquisitorial'),
      const gear_catalog.GearItem(id:'gear-auspex-seal',name:'Печать ауспекса',slot:'relic',rarity:0,power:4,modifiers:{'rangedDamage':0.04},setId:'inquisitorial'),
      const gear_catalog.GearItem(id:'gear-servo-greaves',name:'Сервоприводные поножи',slot:'boots',rarity:0,power:3,modifiers:{'speed':0.04},setId:'inquisitorial'),
    ];
    equipmentInventory.state.backpack.addAll(items);
    equipmentInventory.state.shards = max(equipmentInventory.state.shards, 8);
    persistExpansion();
  }

  bool forgeGearFromLoot(FieldLootItem loot) {
    if (!fieldInventory.any((e) => e.id == loot.id) || equipmentInventory.state.backpack.length >= equipmentInventory.state.capacity) return false;
    final rarity = loot.rarity.index;
    final slot = switch (loot.kind) {
      LootKind.medicae => 'armor',
      LootKind.relicShard || LootKind.evidence => 'relic',
      LootKind.ammunition || LootKind.weaponPart => 'weapon',
      LootKind.stim => 'boots',
      LootKind.grenade => 'gloves',
      _ => 'armor',
    };
    final base = 0.025 + rarity * 0.015 + loot.floorFound * 0.001;
    final mods = <String, double>{
      if (slot == 'armor') 'health': 1.0 + rarity * 0.35,
      if (slot == 'armor') 'defense': base / 2,
      if (slot == 'weapon') 'damage': base,
      if (slot == 'relic') 'rangedDamage': base,
      if (slot == 'relic') 'meleeDamage': base * 0.7,
      if (slot == 'boots') 'speed': base,
      if (slot == 'gloves') 'attackSpeed': base,
    };
    final setId = switch (playerClass) { PlayerClass.xenos => 'deathwatch', PlayerClass.malleus => 'ordo_malleus', PlayerClass.hereticus => 'inquisitorial' };
    final legendaryPower = rarity >= 4 ? switch (slot) { 'armor' => 'unyielding_aegis', 'weapon' => 'executioner_oath', 'relic' => 'auspex_omniscience', 'boots' => 'shadow_stride', _ => 'sanctified_grip' } : null;
    final legendaryBonus = rarity >= 4 ? switch (legendaryPower) {
      'unyielding_aegis' => <String,double>{'health':2.0,'defense':0.06},
      'executioner_oath' => <String,double>{'damage':0.14,'meleeDamage':0.08},
      'auspex_omniscience' => <String,double>{'rangedDamage':0.10,'attackSpeed':0.05},
      'shadow_stride' => <String,double>{'speed':0.10,'defense':0.02},
      _ => <String,double>{'attackSpeed':0.08},
    } : const <String,double>{};
    legendaryBonus.forEach((k,v)=>mods[k]=(mods[k]??0)+v);
    final gear = gear_catalog.GearItem(
      id: 'gear-${loot.id}', name: '${loot.name} • ${rarity >= 4 ? 'Легендарный артефакт' : switch (rarity) {0 => 'Полевой', 1 => 'Усиленный', 2 => 'Редкий', 3 => 'Реликтовый', _ => 'Священный'}}',
      slot: slot, rarity: rarity, power: loot.value + loot.floorFound * 2, modifiers: mods, setId: setId, uniquePower: legendaryPower,
    );
    if (!equipmentInventory.state.add(gear)) return false;
    fieldInventory.removeWhere((e) => e.id == loot.id);
    spawnDamageNumber(player.position, 0, color: loot.rarity.color, label: 'СОЗДАНО: ${gear.name}');
    persistExpansion();
    return true;
  }

  void grantBossRelic({bool guaranteed = false}) {
    final inv = equipmentInventory.state;
    final ownedIds = <String>{...inv.backpack.map((e) => e.id), ...inv.vault.map((e) => e.id), ...inv.equipped.values.map((e) => e.id)};
    final available = List<int>.generate(5, (i) => i).where((i) => !ownedIds.contains(_createBossRelic(i).id)).toList();
    if (available.isEmpty) {
      inv.shards += 8;
      spawnDamageNumber(player.position, 0, color: const Color(0xFFFFC107), label: 'ДУБЛИКАТ РЕЛИКВИИ: +8 ОСКОЛКОВ');
    } else {
      final item = _createBossRelic(available[Random().nextInt(available.length)]);
      if (inv.backpack.length < inv.capacity) {
        inv.backpack.add(item);
        spawnDamageNumber(player.position, 0, color: const Color(0xFFFFC107), label: 'ЛЕГЕНДАРНАЯ РЕЛИКВИЯ');
      } else {
        inv.vault.add(item);
        spawnDamageNumber(player.position, 0, color: const Color(0xFFFFC107), label: 'РЕЛИКВИЯ В ХРАНИЛИЩЕ');
      }
    }
    recomputeStats();
    persistExpansion();
  }

  gear_catalog.GearItem _createBossRelic(int index) {
    final catalog = <gear_catalog.GearItem>[
      const gear_catalog.GearItem(id:'relic-emperors-aegis',name:'Реликвия: Эгида Императора',slot:'armor',rarity:4,power:35,modifiers:{'health':3,'defense':0.08},setId:'inquisitorial',uniquePower:'unyielding_aegis'),
      const gear_catalog.GearItem(id:'relic-deathwatch-round',name:'Реликвия: Патрон Deathwatch',slot:'weapon',rarity:4,power:38,modifiers:{'rangedDamage':0.16,'damage':0.04},setId:'deathwatch',uniquePower:'executioner_oath'),
      const gear_catalog.GearItem(id:'relic-ordo-malleus-seal',name:'Реликвия: Печать Ордо Маллеус',slot:'relic',rarity:4,power:34,modifiers:{'damage':0.10,'health':2},setId:'ordo_malleus',uniquePower:'warp_ward'),
      const gear_catalog.GearItem(id:'relic-auspex-omnissiah',name:'Реликвия: Всевидящий ауспекс',slot:'relic',rarity:4,power:32,modifiers:{'rangedDamage':0.10,'attackSpeed':0.07},setId:'deathwatch',uniquePower:'auspex_omniscience'),
      const gear_catalog.GearItem(id:'relic-shadow-greaves',name:'Реликвия: Поножи Тени',slot:'boots',rarity:4,power:31,modifiers:{'speed':0.12,'defense':0.025},setId:'inquisitorial',uniquePower:'shadow_stride'),
    ];
    return catalog[index.clamp(0,catalog.length-1).toInt()];
  }

  bool equipGear(String id) {
    final ok = equipmentInventory.equipById(id);
    if (ok) { recomputeStats(); if (isPlaying) { player.maxHealth=maxHealth; player.health=min(player.health,maxHealth); } persistExpansion(); }
    return ok;
  }

  bool upgradeGear(String id) {
    final ok = equipmentInventory.upgrade(id);
    if (ok) { recomputeStats(); if (isPlaying) player.maxHealth=maxHealth; persistExpansion(); }
    return ok;
  }

  bool dismantleGear(String id) {
    final ok = equipmentInventory.dismantle(id);
    if (ok) persistExpansion();
    return ok;
  }

  void moveInventoryItem(FieldLootItem item, InventoryLocation target) {
    final existing = storedItems.where((e) => e.item.id == item.id).toList();
    if (existing.isEmpty) storedItems.add(StoredInventoryItem(item, location: target));
    else existing.first.location = target;
    if (target != InventoryLocation.backpack) fieldInventory.removeWhere((e) => e.id == item.id);
    else if (!fieldInventory.any((e) => e.id == item.id) && fieldInventory.length < backpackCapacity) fieldInventory.add(item);
    persistExpansion();
  }

  InquisitionFaction factionForEnemy(EnemyType type) => switch (type) {
    EnemyType.orkBoy => InquisitionFaction.ork,
    EnemyType.tyranidGaunt => InquisitionFaction.tyranid,
    EnemyType.necronWarrior => InquisitionFaction.necron,
    EnemyType.bloodletter || EnemyType.plagueBearer => InquisitionFaction.daemon,
    EnemyType.cultPsyker || EnemyType.flamer => InquisitionFaction.chaos,
    _ => InquisitionFaction.imperium,
  };

  void activateFieldTerminal() {
    if (!isPlaying || isPaused) return;
    terminalsActivated++;
    requisition += 2 + currentFloor;
    campaign.evidence++;
    campaign.cluesFound++;
    recordCareerProgress(evidence: 1);
    campaign.alarm = max(0, campaign.alarm - 5);
    spawnDamageNumber(player.position, 0, color: const Color(0xFF4FC3F7), label: 'ТЕРМИНАЛ: ДАННЫЕ +РЕКВ.');
    persistExpansion();
  }

  void chooseEvacuationRoute(int route) {
    evacuationRoute = route.clamp(0, 2);
    spawnDamageNumber(player.position, 0, color: const Color(0xFFFFD54F), label: 'МАРШРУТ ЭВАКУАЦИИ ВЫБРАН');
    persistExpansion();
  }

  void cycleTacticalMod(int slot) {
    const choices = ['Armor-Seal', 'Auspex Lens', 'Recoil Servo', 'Purity Seal', 'Suspensor Rig', 'Null-Field Coil'];
    if (slot < 0 || slot >= 3) return;
    while (tacticalMods.length < 3) { tacticalMods.add('Armor-Seal'); }
    final current = tacticalMods[slot];
    final idx = choices.indexOf(current);
    tacticalMods[slot] = choices[(idx + 1) % choices.length];
    recomputeStats();
    persistExpansion();
  }

  void upgradeBackpack() {
    if (backpackUpgradeLevel >= 3 || requisition < 25 + backpackUpgradeLevel * 20) return;
    requisition -= 25 + backpackUpgradeLevel * 20;
    backpackUpgradeLevel++;
    backpackCapacity = 16 + backpackUpgradeLevel * 4;
    persistExpansion();
  }

  void triggerRandomMissionEvent() {
    randomMissionEvents++;
    final rng = Random(currentFloor * 997 + pathIndex * 71 + randomMissionEvents);
    switch (rng.nextInt(4)) {
      case 0:
        requisition += 4 + currentFloor;
        spawnDamageNumber(player.position, 0, color: const Color(0xFFFFD54F), label: 'СБРОС СНАБЖЕНИЯ');
        break;
      case 1:
        campaign.alarm = min(100, campaign.alarm + 6);
        spawnDamageNumber(player.position, 0, color: const Color(0xFFFF7043), label: 'СИГНАЛ ТРЕВОГИ');
        break;
      case 2:
        player.health = min(player.maxHealth, player.health + 1);
        spawnDamageNumber(player.position, 0, color: const Color(0xFF80CBC4), label: 'МЕДИЦИНСКИЙ МАЯК');
        break;
      default:
        spawnFieldLoot(player.position + Vector2(70, -50), random: rng);
        spawnDamageNumber(player.position, 0, color: const Color(0xFF4FC3F7), label: 'СЛУЧАЙНАЯ НАХОДКА');
    }
    persistExpansion();
  }

  /// Records a career achievement without ever revoking an unlocked one.
  Future<void> unlockCareerAchievement(String id) async {
    if (id.trim().isEmpty || !unlockedAchievementIds.add(id)) return;
    await persistExpansion();
  }

  /// Updates lifetime counters; call this from mission/kill/evidence events.
  Future<void> recordCareerProgress({int operations = 0, int floors = 0, int kills = 0, int evidence = 0, bool save = true}) async {
    final beforeAchievements = unlockedAchievementIds.length;
    careerOperationsCompleted = (careerOperationsCompleted + operations).clamp(0, 1000000).toInt();
    careerFloorsReached = max(careerFloorsReached, floors);
    careerKills = (careerKills + kills).clamp(0, 100000000).toInt();
    careerEvidenceFound = (careerEvidenceFound + evidence).clamp(0, 1000000).toInt();
    if (careerOperationsCompleted >= 1) unlockedAchievementIds.add('career_first_operation');
    if (careerOperationsCompleted >= 10) unlockedAchievementIds.add('career_ten_operations');
    if (careerFloorsReached >= 5) unlockedAchievementIds.add('career_floor_five');
    if (careerKills >= 100) unlockedAchievementIds.add('career_hundred_kills');
    if (careerEvidenceFound >= 10) unlockedAchievementIds.add('career_ten_evidence');
    if (save || unlockedAchievementIds.length != beforeAchievements) await persistExpansion();
  }

  Future<void> persistExpansion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previousExpansion = prefs.getString('inquisition_expansion');
      if (previousExpansion != null && previousExpansion.isNotEmpty) {
        await prefs.setString('inquisition_expansion_backup', previousExpansion);
      }
      await prefs.setString('inquisition_expansion', jsonEncode({
        'arsenal': arsenalUpgrade, 'shrine': shrineUpgrade, 'archive': archiveUpgrade, 'medicae': medicaeUpgrade,
        'ordoSkillPoints': skillPoints,
        'alignment': inquisitionAlignment, 'specialization': specialization, 'legendary': legendaryWeapon, 'legendaryWeaponRank': legendaryWeaponRank,
        'investigations': investigationsResolved, 'requisition': requisition,
        'warpStability': warpStability, 'modularWeapon': modularWeapon.toJson(),
        'activeArmor': activeArmor.name, 'ownedArmor': ownedArmor.map((e) => e.name).toList(),
        'campaignChronicle': campaignChronicle, 'armorForgePurchases': armorForgePurchases,
        'storedItems': storedItems.map((e) => e.toJson()).toList(),
        'permanentSkillBonus': permanentSkillBonus, 'artifactInvestigationResolved': artifactInvestigationResolved,
        'showSecretSignals': showSecretSignals, 'combatDoctrine': combatDoctrine.name, 'ammoDoctrine': ammoDoctrine.name,
        'arenaModifier': arenaModifier.name, 'servoSkullLevel': servoSkullLevel,
        'secretBossesDefeatedTotal': secretBossesDefeatedTotal, 'tacticalAchievements': tacticalAchievements,
        'contractsCompleted': contractsCompleted,
        'fieldInventory': fieldInventory.map((e) => e.toJson()).toList(),
        'collectedLootIds': collectedLootIds.toList(), 'discoveredCacheIds': discoveredCacheIds.toList(),
        'backpackUpgradeLevel': backpackUpgradeLevel, 'operationSerial': operationSerial, 'tacticalMods': tacticalMods, 'highThreatOperation': highThreatOperation,
        'operationThreatLevel': operationThreatLevel, 'evacuationRoute': evacuationRoute,
        'terminalsActivated': terminalsActivated, 'supplyCachesOpened': supplyCachesOpened,
        'randomMissionEvents': randomMissionEvents, 'consumables': consumables.map((k, v) => MapEntry(k.name, v)),
        'campaignState': campaign.toJson(),
        'expansionSystems': expansionSystems.toJson(),
        'equipmentInventory': equipmentInventory.state.toJson(),
        'progressionTrack': progressionTrack.toJson(),
        'worldEventType': currentWorldEvent?.type.name,
        'worldEventFloor': currentFloor,
        'unlockedAchievementIds': unlockedAchievementIds.toList(),
        'careerOperationsCompleted': careerOperationsCompleted, 'careerFloorsReached': careerFloorsReached,
        'careerKills': careerKills, 'careerEvidenceFound': careerEvidenceFound,
      }));
    } catch (_) {}
  }

  Future<void> persistCustomization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customization', jsonEncode(custom.toJson()));
      await prefs.setString('codex', jsonEncode(codexUnlocked.map((e) => e.name).toList()));
      await prefs.setString('lore_ranks', jsonEncode(loreRanks.map((k, v) => MapEntry(k.name, v))));
      await prefs.setString('inquisition_rank', jsonEncode(inquisitionRank.toJson()));
      await prefs.setString('weapon_mastery', jsonEncode(mastery.toJson()));
      final previousExpansion = prefs.getString('inquisition_expansion');
      if (previousExpansion != null && previousExpansion.isNotEmpty) {
        await prefs.setString('inquisition_expansion_backup', previousExpansion);
      }
      await prefs.setString('inquisition_expansion', jsonEncode({
        'arsenal': arsenalUpgrade, 'shrine': shrineUpgrade, 'archive': archiveUpgrade, 'medicae': medicaeUpgrade,
        'alignment': inquisitionAlignment, 'specialization': specialization, 'legendary': legendaryWeapon, 'legendaryWeaponRank': legendaryWeaponRank,
        'investigations': investigationsResolved, 'requisition': requisition,
        'warpStability': warpStability, 'modularWeapon': modularWeapon.toJson(),
        'activeArmor': activeArmor.name, 'ownedArmor': ownedArmor.map((e) => e.name).toList(),
        'campaignChronicle': campaignChronicle, 'armorForgePurchases': armorForgePurchases,
        'storedItems': storedItems.map((e) => e.toJson()).toList(),
        'permanentSkillBonus': permanentSkillBonus, 'artifactInvestigationResolved': artifactInvestigationResolved,
        'showSecretSignals': showSecretSignals, 'combatDoctrine': combatDoctrine.name, 'ammoDoctrine': ammoDoctrine.name,
        'arenaModifier': arenaModifier.name, 'servoSkullLevel': servoSkullLevel,
        'secretBossesDefeatedTotal': secretBossesDefeatedTotal, 'tacticalAchievements': tacticalAchievements,
        'contractsCompleted': contractsCompleted,
        'fieldInventory': fieldInventory.map((e) => e.toJson()).toList(),
        'collectedLootIds': collectedLootIds.toList(), 'discoveredCacheIds': discoveredCacheIds.toList(),
        'backpackUpgradeLevel': backpackUpgradeLevel, 'operationSerial': operationSerial, 'tacticalMods': tacticalMods, 'highThreatOperation': highThreatOperation,
        'operationThreatLevel': operationThreatLevel, 'evacuationRoute': evacuationRoute,
        'terminalsActivated': terminalsActivated, 'supplyCachesOpened': supplyCachesOpened,
        'randomMissionEvents': randomMissionEvents, 'consumables': consumables.map((k, v) => MapEntry(k.name, v)),
        'campaignState': campaign.toJson(),
        'expansionSystems': expansionSystems.toJson(),
        'equipmentInventory': equipmentInventory.state.toJson(),
        'progressionTrack': progressionTrack.toJson(),
        'worldEventType': currentWorldEvent?.type.name,
        'worldEventFloor': currentFloor,
        'unlockedAchievementIds': unlockedAchievementIds.toList(),
        'careerOperationsCompleted': careerOperationsCompleted, 'careerFloorsReached': careerFloorsReached,
        'careerKills': careerKills, 'careerEvidenceFound': careerEvidenceFound,
      }));
    } catch (_) {}
  }

  Future<void> _persistScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('high_scores', jsonEncode(highScores.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _persistSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('game_saves', jsonEncode(saves.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> deleteSave(GameSave save) async {
    saves.remove(save);
    await _persistSaves();
  }

  Future<void> persistControlLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('control_layout', jsonEncode({
        'moveLeft': moveJoystickLeft,
        'moveBottom': moveJoystickBottom,
        'attackRight': attackJoystickRight,
        'attackBottom': attackJoystickBottom,
        'abilityLeft': abilityClusterLeft,
        'abilityBottom': abilityClusterBottom,
        'weaponRight': weaponButtonRight,
        'weaponBottom': weaponButtonBottom,
      }));
    } catch (_) {}
  }

  void applyControlLayout() {
    // Settings can also be opened from the main menu, before HUD components exist.
    if (!isPlaying) return;
    // Flame HUD components read margins when laying out; update them live where possible.
    if (moveJoystick.isMounted) {
      moveJoystick.margin = EdgeInsets.only(left: moveJoystickLeft, bottom: moveJoystickBottom);
    }
    if (attackJoystick.isMounted) {
      attackJoystick.margin = EdgeInsets.only(right: attackJoystickRight, bottom: attackJoystickBottom);
    }
    if (switchWeaponButton.isMounted) {
      switchWeaponButton.margin = EdgeInsets.only(right: weaponButtonRight, bottom: weaponButtonBottom);
    }
    if (dashButton != null && dashButton!.isMounted) {
      dashButton!.margin = EdgeInsets.only(left: abilityClusterLeft, bottom: abilityClusterBottom);
    }
    if (laserButton != null && laserButton!.isMounted) {
      laserButton!.margin = EdgeInsets.only(left: abilityClusterLeft + buttonSize * 1.35, bottom: abilityClusterBottom);
    }
    if (artifactButton != null && artifactButton!.isMounted) {
      artifactButton!.margin = EdgeInsets.only(left: abilityClusterLeft + buttonSize * 2.7, bottom: abilityClusterBottom);
    }
    if (warpResetButton != null && warpResetButton!.isMounted) {
      warpResetButton!.margin = EdgeInsets.only(left: abilityClusterLeft + buttonSize * 4.05, bottom: abilityClusterBottom);
    }
    if (ordoAbilityButton != null && ordoAbilityButton!.isMounted) {
      ordoAbilityButton!.margin = EdgeInsets.only(left: abilityClusterLeft + buttonSize * 5.4, bottom: abilityClusterBottom);
    }
    for (final label in _controlHudLabels) {
      switch (label.text) {
        case 'M': label.updateMargin(EdgeInsets.only(left: moveJoystickLeft + 30, bottom: moveJoystickBottom + 30)); break;
        case 'F': label.updateMargin(EdgeInsets.only(right: attackJoystickRight + 30, bottom: attackJoystickBottom + 30)); break;
        case 'A': label.updateMargin(EdgeInsets.only(right: weaponButtonRight + 10, bottom: weaponButtonBottom + 10)); break;
        case 'U': label.updateMargin(EdgeInsets.only(left: abilityClusterLeft + 10, bottom: abilityClusterBottom + 10)); break;
        case 'L': label.updateMargin(EdgeInsets.only(left: abilityClusterLeft + buttonSize * 1.35 + 10, bottom: abilityClusterBottom + 10)); break;
        case 'R': label.updateMargin(EdgeInsets.only(left: abilityClusterLeft + buttonSize * 2.7 + 10, bottom: abilityClusterBottom + 10)); break;
        case 'Ψ': label.updateMargin(EdgeInsets.only(left: abilityClusterLeft + buttonSize * 4.05 + 10, bottom: abilityClusterBottom + 10)); break;
        case 'O': label.updateMargin(EdgeInsets.only(left: abilityClusterLeft + buttonSize * 5.4 + 10, bottom: abilityClusterBottom + 10)); break;
      }
    }
  }

  void _addControlLabel(HudLabel label) {
    _controlHudLabels.add(label);
    camera.viewport.add(label);
  }

  int _currentPlaySeconds() {
    if (playStartTime == null) return _savedPlaySeconds;
    return _savedPlaySeconds + DateTime.now().difference(playStartTime!).inSeconds;
  }

  Future<void> saveGame() async {
    if (!isPlaying) return;
    final save = GameSave(
      name: playerName,
      floor: currentFloor,
      level: currentLevel,
      score: score,
      health: player.health,
      maxHealth: maxHealth,
      scraps: scraps,
      bolterDamage: bolterDamage,
      rifleDamage: rifleDamage,
      shotgunDamage: shotgunDamage,
      swordDamage: swordDamage,
      axeDamage: axeDamage,
      hammerDamage: hammerDamage,
      playerSpeed: playerSpeed,
      defenseChance: defenseChance,
      ranged: rangedWeapon.name,
      melee: meleeWeapon.name,
      usingMelee: usingMelee,
      hasDash: hasDashAbility,
      hasLaser: hasLaserAbility,
      ever11: _everReached11,
      ever21: _everReached21,
      playSeconds: _currentPlaySeconds(),
      dateIso: DateTime.now().toIso8601String(),
      difficulty: difficulty.name,
      arenaMode: arenaMode,
      arenaKills: arenaKills,
      skillPoints: skillPoints,
      skills: skills.toJson(),
      custom: {...custom.toJson(), '_campaignState': campaign.toJson(), '_oathAccepted': oathAcceptedThisRun, '_activeOathName': activeOathName},
      playerClass: playerClass.name,
      relics: relics.map((e) => e.name).toList(),
      artifact: activeArtifact.name,
      loadout: loadout.toJson(),
      codex: codexUnlocked.map((e) => e.name).toList(),
      lastEcho: pendingEcho.name,
      mastery: mastery.toJson(),
      challenge: activeChallenge.name,
      pathIndex: pathIndex,
      loreRanks: loreRanks.map((k, v) => MapEntry(k.name, v)),
    );
    saves.insert(0, save);
    if (saves.length > 8) saves = saves.take(8).toList();
    await _persistSaves();
    await persistCustomization();
    playClick();
  }

  void loadSave(GameSave s) {
    playerName = s.name;
    currentFloor = s.floor;
    currentLevel = s.level;
    pathIndex = s.pathIndex.clamp(0, 4);
    score = s.score;
    scraps = s.scraps;
    skills = SkillTree.fromJson(s.skills);
    skillPoints = s.skillPoints;
    custom = Customization.fromJson(s.custom);
    campaign.load(s.custom['_campaignState'] is Map ? Map<String, dynamic>.from(s.custom['_campaignState'] as Map) : null);
    oathAcceptedThisRun = s.custom['_oathAccepted'] as bool? ?? false;
    activeOathName = s.custom['_activeOathName'] as String? ?? OrdoOath.forClass(PlayerClass.values.firstWhere((e) => e.name == s.playerClass, orElse: () => PlayerClass.xenos)).title;
    playerClass = PlayerClass.values.firstWhere((e) => e.name == s.playerClass, orElse: () => PlayerClass.xenos);
    relics
      ..clear()
      ..addAll(s.relics.map((n) => RelicId.values.firstWhere((e) => e.name == n, orElse: () => RelicId.crit)));
    codexUnlocked
      ..clear()
      ..addAll(s.codex.map((n) => CodexId.values.firstWhere((e) => e.name == n, orElse: () => CodexId.shooter)));
    loreRanks.clear();
    s.loreRanks.forEach((k, v) {
      final id = CodexId.values.firstWhere((e) => e.name == k, orElse: () => CodexId.shooter);
      loreRanks[id] = v;
    });
    loadout = WeaponLoadout.fromJson(s.loadout);
    mastery = WeaponMastery.fromJson(s.mastery);
    activeArtifact = ActiveArtifact.values.firstWhere((e) => e.name == s.artifact, orElse: () => ActiveArtifact.fragGrenade);
    pendingEcho = EchoBossKind.values.firstWhere((e) => e.name == s.lastEcho, orElse: () => EchoBossKind.none);
    activeChallenge = RankChallenge.values.firstWhere((e) => e.name == s.challenge, orElse: () => RankChallenge.none);
    recomputeStats();
    rangedWeapon = RangedWeapon.values.firstWhere((e) => e.name == s.ranged, orElse: () => RangedWeapon.bolter);
    meleeWeapon = MeleeWeapon.values.firstWhere((e) => e.name == s.melee, orElse: () => MeleeWeapon.sword);
    usingMelee = s.usingMelee;
    hasDashAbility = (s.hasDash || playerClass == PlayerClass.hereticus) && activeChallenge != RankChallenge.noDash;
    hasLaserAbility = s.hasLaser;
    _everReached11 = s.ever11;
    _everReached21 = s.ever21;
    _savedPlaySeconds = s.playSeconds;
    difficulty = Difficulty.values.firstWhere((e) => e.name == s.difficulty, orElse: () => Difficulty.normal);
    arenaMode = s.arenaMode;
    arenaKills = s.arenaKills;
    playStartTime = DateTime.now();
    isPlaying = true;
    isPaused = false;
    generateFloorPath();
    if (pathIndex >= floorPath.length) pathIndex = floorPath.length - 1;
    syncLevelFromPath();
    _clearEverything();
    if (arenaMode) {
      _startArenaLevel();
    } else {
      _startLevel();
    }
    player.health = s.health.clamp(1, maxHealth);
    player.maxHealth = maxHealth;
    for (final o in [
      'mainMenu', 'loadSave', 'settings', 'nameInput', 'classSelect', 'oathSelect', 'gameOver',
      'levelComplete', 'skills', 'reward', 'shop', 'victory', 'records', 'backpack',
      'codex', 'eventAltar', 'eventMerchant', 'pathSelect', 'lorePopup', 'challengeSelect', 'rankPerk', 'inquisitionHub',
    ]) {
      overlays.remove(o);
    }
    startMusic();
  }

  void addScoreEntry({bool completed = false, bool fromArena = false}) {
    playSeconds = _currentPlaySeconds();
    final top = relics.take(2).map((e) => e.title).toList();
    highScores.add(HighScoreEntry(
      playerName,
      score,
      playSeconds,
      floor: currentFloor,
      level: currentLevel,
      completed: completed,
      difficulty: difficulty.name,
      arena: fromArena || arenaMode,
      playerClass: playerClass.name,
      topRelics: top,
    ));
    highScores.sort((a, b) => b.score.compareTo(a.score));
    if (highScores.length > 15) highScores = highScores.take(15).toList();
    _persistScores();
  }
  List<Vector2> getEnemySpawnPointsRaw() {
    final cx = mapWidth / 2, cy = mapHeight / 2;
    switch (((currentFloor - 1) % 5) + 1) {
      case 1:
        return [
          Vector2(cx - 280, cy - 520), Vector2(cx + 280, cy - 520), Vector2(cx, cy - 620),
          Vector2(cx - 340, cy - 200), Vector2(cx + 340, cy - 200), Vector2(cx, cy - 280),
          Vector2(cx - 260, cy + 80), Vector2(cx + 260, cy + 80),
        ];
      case 2:
        return [
          Vector2(cx - 360, cy - 560), Vector2(cx + 360, cy - 560), Vector2(cx, cy - 660),
          Vector2(cx - 420, cy - 100), Vector2(cx + 420, cy - 100), Vector2(cx - 200, cy - 360),
          Vector2(cx + 200, cy - 360), Vector2(cx, cy + 40),
        ];
      case 3:
        return [
          Vector2(cx - 300, cy - 600), Vector2(cx + 300, cy - 600), Vector2(cx - 380, cy - 320),
          Vector2(cx + 380, cy - 320), Vector2(cx - 160, cy - 160), Vector2(cx + 160, cy - 160),
          Vector2(cx - 320, cy + 60), Vector2(cx + 320, cy + 60),
        ];
      case 4:
        return [
          Vector2(cx - 400, cy - 580), Vector2(cx + 400, cy - 580), Vector2(cx, cy - 680),
          Vector2(cx - 360, cy - 240), Vector2(cx + 360, cy - 240), Vector2(cx - 220, cy + 20),
          Vector2(cx + 220, cy + 20), Vector2(cx, cy - 400),
        ];
      default:
        return [
          Vector2(cx - 340, cy - 600), Vector2(cx + 340, cy - 600), Vector2(cx, cy - 700),
          Vector2(cx - 400, cy - 280), Vector2(cx + 400, cy - 280), Vector2(cx - 180, cy - 80),
          Vector2(cx + 180, cy - 80), Vector2(cx, cy + 60), Vector2(cx - 300, cy + 120), Vector2(cx + 300, cy + 120),
        ];
    }
  }

  List<Vector2> getEnemySpawnPoints() {
    final origin = playerSpawnPos;
    return getEnemySpawnPointsRaw().where((p) => p.distanceTo(origin) >= safeRadius + 40).toList();
  }

  PathNodeKind get _currentNodeKind {
    if (floorPath.isEmpty || pathIndex >= floorPath.length) {
      return currentLevel >= 5 ? PathNodeKind.boss : PathNodeKind.combat;
    }
    return floorPath[pathIndex].kind;
  }

  void _startLevel() {
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
    ordoAbilityButton?.removeFromParent();
    ordoAbilityButton = null;
    ordoAbilityCooldownHud?.removeFromParent();
    ordoAbilityCooldownHud = null;

    syncLevelFromPath();
    _checkUnlocks();
    recomputeStats();
    ironWillUsedThisFloor = false;

    final node = _currentNodeKind;
    // Contract is an additional objective, not a replacement for the selected route node.
    activeContract = switch (node) {
      PathNodeKind.hunt => TacticalContract.hunter,
      PathNodeKind.ritual => TacticalContract.ritual,
      PathNodeKind.survival || PathNodeKind.defense => TacticalContract.survivor,
      PathNodeKind.elite || PathNodeKind.boss => TacticalContract.champion,
      _ => TacticalContract.purge,
    };
    contractProgress = 0;
    contractTarget = switch (activeContract) {
      TacticalContract.purge => 5 + currentFloor.clamp(1, 5).toInt(),
      TacticalContract.hunter => 2 + currentFloor.clamp(1, 4).toInt(),
      TacticalContract.ritual => 4 + currentFloor.clamp(1, 3).toInt(),
      TacticalContract.survivor => 6 + currentFloor.clamp(1, 5).toInt(),
      TacticalContract.champion => 1,
    };
    contractClaimed = false;
    rangedPressure = 0;
    meleePressure = 0;
    _riftSpawnClock = 0;
    isBossLevel = node == PathNodeKind.boss;
    isMiniBossLevel = !isBossLevel && (currentLevel == 3 || node == PathNodeKind.hunt) && node != PathNodeKind.survival;
    isEliteNode = node == PathNodeKind.elite;
    isSurvivalNode = node == PathNodeKind.survival;
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

    if (node == PathNodeKind.event) {
      currentEvent = [EventRoomType.altar, EventRoomType.merchant, EventRoomType.trap][Random().nextInt(3)];
      eventResolved = false;
    } else if (node == PathNodeKind.ritual) {
      currentEvent = EventRoomType.altar;
      eventResolved = false;
    } else if (node == PathNodeKind.defense) {
      currentEvent = EventRoomType.trap;
      eventResolved = false;
    } else if (node == PathNodeKind.rest) {
      currentEvent = EventRoomType.none;
      eventResolved = true;
    } else {
      currentEvent = _rollEvent();
      eventResolved = currentEvent == EventRoomType.none;
    }

    final wallColor = Color.lerp(const Color(0xFF5D4037), const Color(0xFF3E2723), ((currentFloor - 1) % 5) / 4)!;
    world.add(Floor(size: Vector2(mapWidth, mapHeight), biome: activeBiome.index, layout: activeMapLayout));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, mapHeight - 70), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(Wall(position: Vector2(mapWidth - 70, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(PlayerSpawnPoint(position: playerSpawnPos));

    final rng = Random(currentFloor * 100 + currentLevel * 13 + pathIndex * 7);
    final obstacleCount = 4 + (currentFloor.clamp(1, 10)) + currentLevel;
    int placed = 0, attempts = 0;
    while (placed < obstacleCount && attempts < 120) {
      attempts++;
      final x = 140.0 + rng.nextDouble() * (mapWidth - 280);
      final y = 140.0 + rng.nextDouble() * (mapHeight - 280);
      final pos = Vector2(x.toDouble(), y.toDouble());
      if (pos.distanceTo(playerSpawnPos) < safeRadius + 40 || isInGuaranteedPath(pos)) continue;
      if (getEnemySpawnPointsRaw().any((s) => s.distanceTo(pos) < 90)) continue;
      world.add(Obstacle(position: pos));
      placed++;
    }

    // Breakable barrels (typed)
    final barrels = 2 + rng.nextInt(3);
    int bPlaced = 0, bAttempts = 0;
    while (bPlaced < barrels && bAttempts < 80) {
      bAttempts++;
      final pos = Vector2(140 + rng.nextDouble() * (mapWidth - 280), 140 + rng.nextDouble() * (mapHeight - 280));
      if (pos.distanceTo(playerSpawnPos) < 160) continue;
      final kind = rng.nextInt(4); // 0 normal, 1 explosive, 2 heal, 3 scrap
      world.add(BreakableBarrel(position: pos, kind: kind)..priority = 6);
      bPlaced++;
    }

    // Warp rifts are telegraphed, avoidable hazards. Ritual sectors and high corruption are more unstable.
    final riftCount = node == PathNodeKind.ritual ? 2 : (warpCorruption >= 50 && node != PathNodeKind.rest ? 1 : 0);
    for (int i = 0; i < riftCount; i++) {
      final p = Vector2(180 + rng.nextDouble() * (mapWidth - 360), 180 + rng.nextDouble() * (mapHeight - 360));
      if (p.distanceTo(playerSpawnPos) > 220) world.add(WarpRift(position: p)..priority = 5);
    }

    if (!isBossLevel && node != PathNodeKind.rest) {
      for (int i = 0; i < 1 + rng.nextInt(2); i++) {
        final p = Vector2(140 + rng.nextDouble() * (mapWidth - 280), 140 + rng.nextDouble() * (mapHeight - 280));
        if (p.distanceTo(playerSpawnPos) > 150) world.add(MedkitPickup(position: p));
      }
      if (rng.nextDouble() < 0.35) {
        final p = Vector2(140 + rng.nextDouble() * (mapWidth - 280), 140 + rng.nextDouble() * (mapHeight - 280));
        if (p.distanceTo(playerSpawnPos) > 150) world.add(ShieldPickup(position: p));
      }
    }

    // Field loot is deterministic per mission node; the same coordinates keep stable IDs on revisits.
    if (node != PathNodeKind.rest) {
      final lootCount = 3 + rng.nextInt(3) + (currentFloor >= 3 ? 1 : 0);
      for (int i = 0; i < lootCount; i++) {
        final pos = Vector2(120 + rng.nextDouble() * (mapWidth - 240), 120 + rng.nextDouble() * (mapHeight - 240));
        if (pos.distanceTo(playerSpawnPos) > 170) spawnFieldLoot(pos, random: rng);
      }
      // A rare hidden cache is placed away from the deployment zone. Its seal is procedural geometry.
      if (rng.nextDouble() < 0.30) {
        final pos = Vector2(180 + rng.nextDouble() * (mapWidth - 360), 180 + rng.nextDouble() * (mapHeight - 360));
        if (pos.distanceTo(playerSpawnPos) > 280) spawnFieldLoot(pos, secret: true, random: rng);
      }
      // Field terminal / supply point: small rewards, no change to the existing win condition.
      if (rng.nextDouble() < 0.38) {
        final pos = Vector2(160 + rng.nextDouble() * (mapWidth - 320), 160 + rng.nextDouble() * (mapHeight - 320));
        if (pos.distanceTo(playerSpawnPos) > 200) world.add(FieldTerminal(position: pos)..priority = 8);
      }
      if (highThreatOperation && rng.nextDouble() < 0.35) spawnFieldLoot(Vector2(mapWidth - 180, 180), secret: true, random: rng);
    }

    // Procedural layout motifs vary room density while preserving the safe spawn radius and exits.
    final layout = activeMapLayout;
    if (layout == MapLayout.cruciform || layout == MapLayout.ring) {
      for (int i = 0; i < 5; i++) {
        final x = (layout == MapLayout.cruciform ? mapWidth / 2 + (i - 2) * 105 : 170 + i * 215).toDouble();
        final y = (layout == MapLayout.cruciform ? 280 + i * 285 : (i.isEven ? 340.0 : mapHeight - 340.0)).toDouble();
        final pos = Vector2(x.toDouble(), y.toDouble());
        if (pos.distanceTo(playerSpawnPos) > 210 && !isInGuaranteedPath(pos)) world.add(Obstacle(position: pos)..priority = 5);
      }
    } else if (layout == MapLayout.corridors) {
      for (int row = 0; row < 5; row++) {
        final y = (240.0 + row * 300).toDouble();
        for (int col = 0; col < 3; col++) {
          final x = (220.0 + col * 380).toDouble();
          final pos = Vector2(x.toDouble(), y.toDouble());
          if (pos.distanceTo(playerSpawnPos) > 190 && !isInGuaranteedPath(pos)) world.add(Obstacle(position: pos)..priority = 5);
        }
      }
    }

    // Rest node: heal + portal immediately
    if (node == PathNodeKind.rest) {
      enemiesToSpawn = 0;
      enemiesAlive = 0;
      enemiesSpawned = 0;
      _forceSpawnPortal();
    } else if (isBossLevel) {
      _spawnFloorBosses();
    } else if (isMiniBossLevel) {
      final baseCount = (2 + currentFloor.clamp(1, 8)).ceil();
      enemiesToSpawn = baseCount;
      enemiesAlive = baseCount;
      enemiesSpawned = 0;
      spawnTimer = 0.4;
      world.add(MiniBoss(floor: currentFloor, position: Vector2(mapWidth / 2, mapHeight / 2 - 280))..priority = 24);
      enemiesAlive++;
      enemiesToSpawn++;
      enemiesSpawned++;
    } else {
      final baseCount = 3 + currentFloor.clamp(1, 10) + currentLevel + (overallLevel ~/ 6) + (isEliteNode ? 2 : 0) + (highThreatOperation ? 1 : 0);
      final missionCount = baseCount * (isSurvivalNode ? 2 : 1);
      enemiesToSpawn = (missionCount * (difficulty == Difficulty.hard ? 1.2 : 1.0)).ceil();
      enemiesAlive = enemiesToSpawn;
      enemiesSpawned = 0;
      spawnTimer = 0.4;
      spawnInterval = max(0.28, 1.15 - currentFloor * 0.06 - currentLevel * 0.04 - (isSurvivalNode ? 0.15 : 0));
    }

    // Elite sectors may contain a rival agent of the Inquisition: a dangerous mirror-build encounter.
    if (isEliteNode && currentFloor >= 2 && !arenaMode) {
      final rivalPos = Vector2(mapWidth * 0.72, mapHeight * 0.48);
      world.add(RivalInquisitor(floor: currentFloor, position: rivalPos)..priority = 27);
      enemiesToSpawn++;
      enemiesAlive++;
      enemiesSpawned++;
    }

    _maybeSpawnEcho();
    _spawnEventProps();
    _setupHudAndPlayer(node == PathNodeKind.rest);

    if (currentEvent == EventRoomType.trap) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (isPlaying && !eventResolved && currentEvent == EventRoomType.trap) {
          _startTrapWave();
        }
      });
    }
  }

  /// Floor boss roster scales with floor index (1..maxFloors)
  void _spawnFloorBosses() {
    final bossPos = Vector2(mapWidth / 2, mapHeight / 2 - 260);
    final f = currentFloor;

    if (f >= maxFloors) {
      // Final floor: King + Knight + Boss (or Plague/Blood on hard)
      if (difficulty == Difficulty.hard && f >= 8) {
        enemiesAlive = 2;
        enemiesToSpawn = 2;
        enemiesSpawned = 2;
        world.add(PlagueLordBoss(position: bossPos + Vector2(-150, 0))..priority = 26);
        world.add(BloodChampionBoss(position: bossPos + Vector2(150, 0))..priority = 26);
      } else {
        enemiesAlive = 3;
        enemiesToSpawn = 3;
        enemiesSpawned = 3;
        world.add(Boss(floor: f, position: bossPos + Vector2(-170, 0))..priority = 25);
        world.add(KnightBoss(floor: f, position: bossPos + Vector2(170, 0))..priority = 25);
        world.add(KingBoss(position: bossPos)..priority = 26);
      }
    } else if (f % 5 == 0 || f == 5) {
      enemiesAlive = 2;
      enemiesToSpawn = 2;
      enemiesSpawned = 2;
      world.add(Boss(floor: f, position: bossPos + Vector2(-120, 0))..priority = 25);
      world.add(KnightBoss(floor: f, position: bossPos + Vector2(120, 0))..priority = 25);
    } else if (f >= 7 && difficulty != Difficulty.easy) {
      enemiesAlive = 1;
      enemiesToSpawn = 1;
      enemiesSpawned = 1;
      if (Random().nextBool()) {
        world.add(PlagueLordBoss(position: bossPos)..priority = 26);
      } else {
        world.add(BloodChampionBoss(position: bossPos)..priority = 26);
      }
    } else if (f >= 3) {
      enemiesAlive = 2;
      enemiesToSpawn = 2;
      enemiesSpawned = 2;
      world.add(Boss(floor: f, position: bossPos + Vector2(-120, 0))..priority = 25);
      world.add(KnightBoss(floor: f, position: bossPos + Vector2(120, 0))..priority = 25);
    } else {
      enemiesAlive = 1;
      enemiesToSpawn = 1;
      enemiesSpawned = 1;
      world.add(Boss(floor: f, position: bossPos)..priority = 25);
    }
  }

  void _setupHudAndPlayer(bool restHeal) {
    moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.35, paint: Paint()..color = Colors.white54),
      background: CircleComponent(radius: joystickSize * 0.55, paint: Paint()..color = Colors.white24),
      margin: EdgeInsets.only(left: moveJoystickLeft, bottom: moveJoystickBottom),
    );
    attackJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.35, paint: Paint()..color = const Color(0xFFFF5252).withOpacity(0.8)),
      background: CircleComponent(radius: joystickSize * 0.55, paint: Paint()..color = const Color(0xFFFF5252).withOpacity(0.25)),
      margin: EdgeInsets.only(right: attackJoystickRight, bottom: attackJoystickBottom),
    );
    switchWeaponButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.55, paint: Paint()..color = const Color(0xFFB8860B)),
      buttonDown: CircleComponent(radius: buttonSize * 0.55, paint: Paint()..color = const Color(0xFFFFD700)),
      margin: EdgeInsets.only(right: weaponButtonRight, bottom: weaponButtonBottom),
      onPressed: () {
        usingMelee = !usingMelee;
        recomputeStats();
        playClick();
      },
    );
    settingsButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = const Color(0xFF455A64)),
      margin: const EdgeInsets.only(right: 12, top: 12),
      onPressed: openSettings,
    );
    backpackButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = const Color(0xFF6A1B9A)),
      margin: const EdgeInsets.only(right: 64, top: 12),
      onPressed: openBackpack,
    );
    zoomInButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.4, paint: Paint()..color = const Color(0xFF2E7D32)),
      margin: const EdgeInsets.only(left: 12, top: 12),
      onPressed: () {
        currentZoom = (currentZoom + 0.08).clamp(0.55, 1.35);
        camera.viewfinder.zoom = currentZoom;
      },
    );
    zoomOutButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.4, paint: Paint()..color = const Color(0xFFC62828)),
      margin: const EdgeInsets.only(left: 56, top: 12),
      onPressed: () {
        currentZoom = (currentZoom - 0.08).clamp(0.55, 1.35);
        camera.viewfinder.zoom = currentZoom;
      },
    );

    player = Player(moveJoystick)..priority = 20;
    player.maxHealth = maxHealth;
    player.health = maxHealth;
    if (shrineUpgrade > 0) player.health = min(maxHealth, player.health + (shrineUpgrade ~/ 2));
    if (restHeal) player.health = min(maxHealth, player.health + 2);
    world.add(player);
    camera.follow(player);

    camera.viewport.add(moveJoystick);
    camera.viewport.add(attackJoystick);
    camera.viewport.add(switchWeaponButton);
    camera.viewport.add(settingsButton);
    camera.viewport.add(backpackButton);
    camera.viewport.add(zoomInButton);
    camera.viewport.add(zoomOutButton);
    _addControlLabel(HudLabel(text: 'M', margin: EdgeInsets.only(left: moveJoystickLeft + 30, bottom: moveJoystickBottom + 30)));
    _addControlLabel(HudLabel(text: 'F', margin: EdgeInsets.only(right: attackJoystickRight + 30, bottom: attackJoystickBottom + 30)));
    _addControlLabel(HudLabel(text: 'A', margin: EdgeInsets.only(right: weaponButtonRight + 10, bottom: weaponButtonBottom + 10)));
    _addControlLabel(HudLabel(text: 'S', margin: const EdgeInsets.only(right: 22, top: 22)));
    _addControlLabel(HudLabel(text: 'B', margin: const EdgeInsets.only(right: 74, top: 22)));
    _addControlLabel(HudLabel(text: '+', margin: const EdgeInsets.only(left: 22, top: 22)));
    _addControlLabel(HudLabel(text: '-', margin: const EdgeInsets.only(left: 66, top: 22)));
    // Attack joystick cooldown ring overlay
    camera.viewport.add(AttackCooldownRing()..priority = 199);
    _ensureDashButton();
    _ensureLaserButton();
    _ensureArtifactButton();
    _ensureWarpResetButton();
    _ensureOrdoAbilityButton();
  }

  void _forceSpawnPortal() {
    if (portalSpawned) return;
    portalSpawned = true;
    // Remove any existing portals first
    for (final p in world.children.whereType<Portal>().toList()) {
      p.removeFromParent();
    }
    world.add(Portal(position: Vector2(mapWidth / 2, 160))..priority = 9);
    spawnDamageNumber(Vector2(mapWidth / 2, 200), 0, color: const Color(0xFFE91E63), label: 'ПОРТАЛ');
  }

  void _maybeSpawnEcho() {
    if (pendingEcho == EchoBossKind.none) return;
    if (Random().nextDouble() > 0.10) {
      pendingEcho = EchoBossKind.none;
      return;
    }
    final pos = Vector2(mapWidth / 2 + (Random().nextDouble() - 0.5) * 180, mapHeight / 2 - 280);
    enemiesAlive++;
    enemiesToSpawn++;
    enemiesSpawned++;
    switch (pendingEcho) {
      case EchoBossKind.mini:
        world.add(MiniBoss(floor: currentFloor, position: pos, isEcho: true)..priority = 24);
        break;
      case EchoBossKind.ranged:
        world.add(Boss(floor: currentFloor, position: pos, isEcho: true)..priority = 25);
        break;
      case EchoBossKind.knight:
        world.add(KnightBoss(floor: currentFloor, position: pos, isEcho: true)..priority = 25);
        break;
      case EchoBossKind.king:
        world.add(KingBoss(position: pos, isEcho: true)..priority = 26);
        break;
      case EchoBossKind.plague:
        world.add(PlagueLordBoss(position: pos, isEcho: true)..priority = 26);
        break;
      case EchoBossKind.blood:
        world.add(BloodChampionBoss(position: pos, isEcho: true)..priority = 26);
        break;
      case EchoBossKind.none:
        break;
    }
    spawnDamageNumber(pos, 0, color: const Color(0xFF9C27B0), label: 'ЭХО');
    pendingEcho = EchoBossKind.none;
  }

  void _startArenaLevel() {
    world.removeAll(world.children.toList());
    camera.viewport.children.whereType<HudLabel>().toList().forEach((c) => c.removeFromParent());
    ordoAbilityButton?.removeFromParent();
    ordoAbilityButton = null;
    ordoAbilityCooldownHud?.removeFromParent();
    ordoAbilityCooldownHud = null;
    portalButton?.removeFromParent();
    portalButton = null;
    currentEvent = EventRoomType.none;
    eventResolved = true;
    portalSpawned = false;
    isBossLevel = false;
    isMiniBossLevel = false;
    world.add(Floor(size: Vector2(mapWidth, mapHeight), biome: 4));
    final wallColor = const Color(0xFF4A148C);
    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, mapHeight - 70), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(Wall(position: Vector2(mapWidth - 70, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(PlayerSpawnPoint(position: playerSpawnPos));
    enemiesToSpawn = 6 + arenaWave + (difficulty == Difficulty.hard ? 2 : 0);
    if (arenaModifier == ArenaModifier.swarm) enemiesToSpawn = (enemiesToSpawn * 1.45).round();
    enemiesAlive = enemiesToSpawn;
    enemiesSpawned = 0;
    spawnTimer = 0.3;
    spawnInterval = max(0.18, 0.9 - arenaWave * 0.02 - arenaThreatTier * 0.006);
    recomputeStats();
    _setupHudAndPlayer(false);
  }

  void _ensureDashButton() {
    if (activeChallenge == RankChallenge.noDash) return;
    if (!hasDashAbility || dashButton != null) return;
    dashButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = const Color(0xFF00838F)),
      margin: EdgeInsets.only(left: abilityClusterLeft, bottom: abilityClusterBottom),
      onPressed: activateDash,
    );
    camera.viewport.add(dashButton!);
    _addControlLabel(HudLabel(text: 'U', margin: EdgeInsets.only(left: abilityClusterLeft + 10, bottom: abilityClusterBottom + 10)));
  }

  void _ensureLaserButton() {
    if (!hasLaserAbility || laserButton != null) return;
    laserButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = const Color(0xFFE65100)),
      margin: EdgeInsets.only(left: abilityClusterLeft + buttonSize * 1.35, bottom: abilityClusterBottom),
      onPressed: activateLaser,
    );
    camera.viewport.add(laserButton!);
    _addControlLabel(HudLabel(text: 'L', margin: EdgeInsets.only(left: abilityClusterLeft + buttonSize * 1.35 + 10, bottom: abilityClusterBottom + 10)));
  }

  void _ensureArtifactButton() {
    if (artifactButton != null) return;
    artifactButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = const Color(0xFFBF360C)),
      margin: EdgeInsets.only(left: abilityClusterLeft + buttonSize * 2.7, bottom: abilityClusterBottom),
      onPressed: activateArtifact,
    );
    camera.viewport.add(artifactButton!);
    _addControlLabel(HudLabel(text: 'R', margin: EdgeInsets.only(left: abilityClusterLeft + buttonSize * 2.7 + 10, bottom: abilityClusterBottom + 10)));
  }

  void _ensureWarpResetButton() {
    if (playerClass != PlayerClass.malleus || warpResetButton != null) return;
    warpResetButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.42, paint: Paint()..color = const Color(0xFF7C4DFF)),
      margin: EdgeInsets.only(left: abilityClusterLeft + buttonSize * 4.05, bottom: abilityClusterBottom),
      onPressed: () => resetWarpStress(),
    );
    camera.viewport.add(warpResetButton!);
    _addControlLabel(HudLabel(text: 'Ψ', margin: EdgeInsets.only(left: abilityClusterLeft + buttonSize * 4.05 + 10, bottom: abilityClusterBottom + 10)));
  }

  void _ensureOrdoAbilityButton() {
    if (playerClass == PlayerClass.xenos || ordoAbilityButton != null) return;
    final malleus = playerClass == PlayerClass.malleus;
    ordoAbilityButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = malleus ? const Color(0xFF7E57C2) : const Color(0xFFC62828)),
      margin: EdgeInsets.only(left: abilityClusterLeft + buttonSize * 5.4, bottom: abilityClusterBottom),
      onPressed: activateOrdoAbility,
    );
    camera.viewport.add(ordoAbilityButton!);
    ordoAbilityCooldownHud?.removeFromParent();
    ordoAbilityCooldownHud = OrdoAbilityCooldownHud()..priority = 201;
    camera.viewport.add(ordoAbilityCooldownHud!);
    _addControlLabel(HudLabel(text: 'O', margin: EdgeInsets.only(left: abilityClusterLeft + buttonSize * 5.4 + 10, bottom: abilityClusterBottom + 10)));
  }

  /// Class-specific active ability. Effects are applied to live Enemy components,
  /// not just shown as a visual or catalogue description.
  void activateOrdoAbility() {
    if (!isPlaying || isPaused || playerClass == PlayerClass.xenos || ordoAbilityCooldown > 0) return;
    final malleus = playerClass == PlayerClass.malleus;
    final center = player.position.clone();
    if (malleus) {
      ordoAbilityCooldown = 13.0;
      ordoWardTimer = 4.0;
      world.add(OrdoPulseEffect(position: center, color: const Color(0xFFB388FF), maxRadius: 190, life: 0.85)..priority = 40);
      var hitCount = 0;
      for (final enemy in world.children.whereType<Enemy>().toList()) {
        final distance = enemy.position.distanceTo(center);
        if (distance > 190) continue;
        final daemon = enemy.type == EnemyType.bloodletter || enemy.type == EnemyType.chaosSpawn;
        final damage = (12 + overallLevel * 2) * (daemon ? 1.75 : 1.0);
        enemy.applyDamage(damage.round());
        enemy.applyStatus(StatusType.slow, daemon ? 2.8 : 1.4, tickDamage: 0);
        hitCount++;
        spawnDamageNumber(enemy.position, (damage.round()), color: const Color(0xFFD1C4E9), label: daemon ? 'ИЗГНАНИЕ' : null);
      }
      spawnDamageNumber(center, 0, color: const Color(0xFFB388FF), label: 'ЭКЗОРЦИЗМ • ЩИТ 4с');
      playClick();
      triggerShake(power: hitCount > 0 ? 4.0 : 1.5, time: 0.16);
    } else {
      ordoAbilityCooldown = 11.0;
      Enemy? target;
      var bestDistance = 360.0;
      for (final enemy in world.children.whereType<Enemy>()) {
        final distance = enemy.position.distanceTo(center);
        if (distance < bestDistance) { bestDistance = distance; target = enemy; }
      }
      final aim = target?.position.clone() ?? (center + (player.aimDir.length2 > 0.01 ? player.aimDir.normalized() * 300 : Vector2(0, -300)));
      world.add(OrdoJudgmentEffect(position: center, targetOffset: aim - center, color: const Color(0xFFFF5252), life: 0.42)..priority = 42);
      if (target != null) {
        final cultOrPsyker = target.type == EnemyType.cultPsyker || target.type == EnemyType.shooter || target.type == EnemyType.melee || target.type == EnemyType.shielded || target.type == EnemyType.shieldedShooter || target.type == EnemyType.sniper || target.type == EnemyType.flamer;
        final damage = (20 + overallLevel * 2) * (cultOrPsyker ? 1.55 : 1.0);
        target.applyDamage(damage.round());
        target.applyStatus(StatusType.slow, 2.4, tickDamage: 0);
        spawnDamageNumber(target.position, damage.round(), color: const Color(0xFFFF8A80), label: cultOrPsyker ? 'ПРИГОВОР' : null);
      }
      spawnDamageNumber(center, 0, color: const Color(0xFFFF5252), label: 'ПРИГОВОР ИНКВИЗИТОРА');
      playShoot();
      triggerShake(power: 3.0, time: 0.12);
    }
  }

  void activateDash() {
    if (activeChallenge == RankChallenge.noDash) return;
    if (!hasDashAbility || dashCooldown > 0 || dashActive > 0 || !isPlaying || isPaused) return;
    final boost = hereticusDashBoost > 0;
    dashActive = (playerClass == PlayerClass.hereticus ? 2.6 : 2.0) + (boost ? 0.8 : 0);
    var cd = (playerClass == PlayerClass.hereticus ? 5.0 : 6.0) - (boost ? 1.5 : 0);
    if (hasShadowStep) cd = max(2.0, cd - 1.5);
    dashCooldown = cd;
    if (boost) hereticusDashBoost = 0;
    grantInvuln(0.25 + (hasShadowStep ? 0.1 : 0));
    final dir = player.aimDir.length2 > 0.01
        ? player.aimDir
        : (moveJoystick.relativeDelta.length2 > 0.01 ? moveJoystick.relativeDelta.normalized() : Vector2(0, -1));
    player.position += dir * 55;
    player.priority = 21;
    playClick();
  }

  void activateLaser() {
    if (!hasLaserAbility || laserCooldown > 0 || !isPlaying || isPaused) return;
    laserCooldown = 20;
    grantInvuln(0.25);
    final dir = player.aimDir.length2 > 0.01 ? player.aimDir : Vector2(0, -1);
    world.add(CyclopsLaserBeam(position: player.position.clone(), direction: dir, damage: scaleDamage(40 + overallLevel))..priority = 22);
    triggerShake(power: 8, time: 0.2);
    playShoot();
  }

  void activateArtifact() {
    if (!isPlaying || isPaused || artifactCooldown > 0) return;
    artifactCooldown = activeArtifact.cooldown;
    final dir = player.aimDir.length2 > 0.01 ? player.aimDir : Vector2(0, -1);
    switch (activeArtifact) {
      case ActiveArtifact.fragGrenade:
        world.add(FragGrenade(position: player.position + dir * 20, direction: dir, damage: scaleDamage(22 + overallLevel))..priority = 14);
        playShoot();
        break;
      case ActiveArtifact.holyAura:
        holyAuraTimer = 8;
        playClick();
        break;
      case ActiveArtifact.servoTurret:
        world.add(ServoTurret(position: player.position + dir * 40)..priority = 14);
        playClick();
        break;
    }
  }

  EnemyType _chooseEnemyType() {
    // Disjoint cumulative bands: no late condition can silently shadow another enemy.
    final r = Random().nextDouble();
    final f = currentFloor;
    final level = overallLevel;
    if (f >= 7 && r < 0.055) return EnemyType.necronImmortal;
    if (f >= 6 && r < 0.105) return EnemyType.chaosSpawn;
    if (f >= 6 && r < 0.155) return EnemyType.plagueBearer;
    if (f >= 5 && r < 0.205) return EnemyType.genestealer;
    if (f >= 5 && r < 0.250) return EnemyType.bloodletter;
    if (f >= 4 && r < 0.300) return EnemyType.cultPsyker;
    if (f >= 3 && r < 0.365) return EnemyType.necronWarrior;
    if (f >= 2 && r < 0.430) return EnemyType.tyranidGaunt;
    if (f >= 2 && r < 0.490) return EnemyType.orkBoy;
    if (level >= 20 && r < 0.555) return EnemyType.shieldedShooter;
    if (level >= 18 && r < 0.615) return EnemyType.brute;
    if (level >= 14 && r < 0.675) return EnemyType.sniper;
    if (level >= 12 && r < 0.735) return EnemyType.flamer;
    if (level >= 11 && r < 0.795) return EnemyType.dog;
    if (r < 0.865) return EnemyType.shooter;
    if (r < 0.940) return EnemyType.melee;
    return EnemyType.shielded;
  }

  void _spawnOneEnemy() {
    if (enemiesSpawned >= enemiesToSpawn) return;
    final points = getEnemySpawnPoints();
    if (points.isEmpty) return;
    final pos = points[Random().nextInt(points.length)].clone();
    world.add(EnemySpawnPortal(position: pos)..priority = 3);
    final forceChamp = isEliteNode && enemiesSpawned < 2;
    final isChamp = forceChamp || (overallLevel >= 5 && Random().nextDouble() < (0.08 + currentFloor * 0.015 + (highThreatOperation ? 0.08 : 0)));
    final type = _chooseEnemyType();
    // Warp summoners now occur as a deliberate battlefield role, not only as a
    // random champion affix. They keep the existing cult-psyker combat/visual
    // implementation and trigger their add-spawn at 50% HP.
    final affix = isChamp
        ? rollAffix()
        : (type == EnemyType.cultPsyker && currentFloor >= 4 && Random().nextDouble() < 0.24
            ? EliteAffix.summoner
            : EliteAffix.none);
    final e = Enemy(floor: currentFloor, type: type, isChampion: isChamp, affix: affix);
    e.position = pos;
    e.priority = 30;
    world.add(e);
    enemiesSpawned++;
    if (isChamp) unlockCodex(CodexId.champion);
  }

  /// Count all living hostiles (enemies + bosses)
  int countLivingHostiles() {
    int n = 0;
    for (final c in world.children) {
      if (c is Enemy ||
          c is MiniBoss ||
          c is Boss ||
          c is KnightBoss ||
          c is KingBoss ||
          c is TentacleBoss ||
          c is CyclopsBoss ||
          c is PlagueLordBoss ||
          c is BloodChampionBoss) {
        n++;
      }
    }
    return n;
  }

  void onEnemyKilled({
    bool isBoss = false,
    Vector2? at,
    bool isChampion = false,
    EnemyType? type,
    bool meleeKill = false,
    EchoBossKind? echoKind,
    EliteAffix affix = EliteAffix.none,
    Vector2? fromDir,
  }) {
    // Lifetime kill statistics are updated from the actual death callback, not inferred from score.
    final nextCareerKillCount = careerKills + 1;
    recordCareerProgress(kills: 1, save: nextCareerKillCount % 10 == 0 || nextCareerKillCount == 100);
    // Recalculate from actual world state — fixes portal not appearing
    enemiesAlive = countLivingHostiles();
    // Also account for not-yet-spawned
    final pending = (enemiesToSpawn - enemiesSpawned).clamp(0, 999);
    final stillExpected = enemiesAlive + pending;

    if (arenaMode) {
      arenaKills++;
      if (arenaKills % 20 == 0) {
        tacticalAchievements++;
        persistExpansion();
        spawnDamageNumber(at ?? player.position, 0, color: const Color(0xFFFF5252), label: 'УГРОЗА ${arenaThreatTier + 1}');
        triggerShake(power: 5, time: 0.18);
      }
      if (arenaKills % 100 == 0) _spawnArenaBoss();
    }
    if (type != null) {
      switch (type) {
        case EnemyType.shooter: unlockCodex(CodexId.shooter); break;
        case EnemyType.melee: unlockCodex(CodexId.melee); break;
        case EnemyType.shielded: unlockCodex(CodexId.shielded); break;
        case EnemyType.dog: unlockCodex(CodexId.dog); break;
        case EnemyType.shieldedShooter: unlockCodex(CodexId.shieldedShooter); break;
        case EnemyType.flamer: unlockCodex(CodexId.flamer); break;
        case EnemyType.sniper: unlockCodex(CodexId.sniper); break;
        case EnemyType.brute: unlockCodex(CodexId.brute); break;
        case EnemyType.cultPsyker: unlockCodex(CodexId.cultPsyker); break;
        case EnemyType.plagueBearer: unlockCodex(CodexId.plagueBearer); break;
        case EnemyType.bloodletter: unlockCodex(CodexId.bloodletter); break;
        case EnemyType.orkBoy: unlockCodex(CodexId.orkBoy); break;
        case EnemyType.tyranidGaunt: unlockCodex(CodexId.tyranidGaunt); break;
        case EnemyType.necronWarrior: unlockCodex(CodexId.necronWarrior); break;
        case EnemyType.genestealer: unlockCodex(CodexId.genestealer); break;
        case EnemyType.chaosSpawn: unlockCodex(CodexId.chaosSpawn); break;
        case EnemyType.necronImmortal: unlockCodex(CodexId.necronImmortal); break;
      }
    }
    if (isBoss) { tacticalAchievements++; if (tacticalAchievements % 3 == 0) requisition += 5; grantBossRelic(guaranteed: true); persistExpansion(); }

    // Tactical contract progress is event-driven and guarded so a multi-hit death cannot double-claim.
    final countsForContract = switch (activeContract) {
      TacticalContract.purge => true,
      TacticalContract.hunter => isChampion || isBoss || type == EnemyType.sniper || type == EnemyType.brute,
      TacticalContract.ritual => type == EnemyType.cultPsyker || type == EnemyType.plagueBearer || type == EnemyType.bloodletter || type == EnemyType.orkBoy || type == EnemyType.tyranidGaunt || type == EnemyType.necronWarrior || isBoss,
      TacticalContract.survivor => true,
      TacticalContract.champion => isChampion || isBoss,
    };
    final ordoContractTarget = switch (playerClass) {
      PlayerClass.malleus => type == EnemyType.bloodletter || type == EnemyType.plagueBearer || type == EnemyType.cultPsyker || isBoss,
      PlayerClass.hereticus => type == EnemyType.cultPsyker || type == EnemyType.shooter || type == EnemyType.flamer || type == EnemyType.sniper,
      PlayerClass.xenos => type == EnemyType.orkBoy || type == EnemyType.tyranidGaunt || type == EnemyType.necronWarrior || type == EnemyType.brute,
    };
    if (!contractClaimed && (countsForContract || ordoContractTarget)) {
      contractProgress = min(contractTarget, contractProgress + 1);
      if (contractProgress >= contractTarget) {
        contractClaimed = true;
        contractsCompleted++;
        requisition += 8 + currentFloor;
        scraps += 12 + currentFloor * 2;
        tacticalAchievements++;
        spawnDamageNumber(at ?? player.position, 0, color: const Color(0xFFFFD54F), label: 'ПРИКАЗ ВЫПОЛНЕН +РЕКВ.');
        persistExpansion();
      }
    }
    // Investigation loop: unusual enemies, champions and bosses can leave actionable evidence.
    if (!arenaMode && (isChampion || isBoss || type == EnemyType.cultPsyker || type == EnemyType.plagueBearer || type == EnemyType.bloodletter || type == EnemyType.orkBoy || type == EnemyType.tyranidGaunt || type == EnemyType.necronWarrior) && Random().nextDouble() < 0.34) {
      campaign.evidence++;
      campaign.cluesFound++;
      recordCareerProgress(evidence: 1);
      if (campaign.cluesFound % 3 == 0) {
        campaign.suspicion = max(0, campaign.suspicion - 2);
        spawnDamageNumber(at ?? player.position, 0, color: const Color(0xFF80CBC4), label: 'УЛИКА +${campaign.evidence}');
      }
    }
    if (!arenaMode && isChampion && Random().nextDouble() < 0.18) campaign.alarm = max(0, campaign.alarm - 6);
    score += ((isBoss ? 200 : (isChampion ? 80 : 20)) * comboMult).round();
    if (legendaryWeapon != 'none') {
      legendaryKillCounter++;
      if (legendaryWeapon == 'sanctified' && legendaryKillCounter % 10 == 0 && isPlaying) {
        player.health = min(player.maxHealth, player.health + 1);
        spawnDamageNumber(player.position, 0, color: const Color(0xFF80CBC4), label: 'ОСВЯЩЕНИЕ +HP');
      }
      if (legendaryWeapon == 'executionerBlade' && meleeKill && Random().nextDouble() < 0.12 && isPlaying) {
        player.health = min(player.maxHealth, player.health + 1);
        spawnDamageNumber(player.position, 0, color: const Color(0xFFE57373), label: 'КРОВОЖАДНОСТЬ +HP');
      }
      if (legendaryWeapon == 'emperor' && (isBoss || isChampion)) scraps += 5;
      if (legendaryWeapon == 'warp' && warpCorruption < 100 && legendaryKillCounter % 8 == 0) {
        warpCorruption = min(100, warpCorruption + 1);
      }
    }
    registerKill(at: at, isBoss: isBoss, isChampion: isChampion, meleeKill: meleeKill, fromDir: fromDir);
    if (echoKind != null && echoKind != EchoBossKind.none) rememberBossEcho(echoKind);

    // Force portal when room is clear
    if (!arenaMode && stillExpected <= 0) {
      _forceSpawnPortal();
    }
  }

  void _spawnArenaBoss() {
    final pos = Vector2(mapWidth / 2, mapHeight / 2 - 200);
    enemiesAlive++;
    enemiesToSpawn++;
    enemiesSpawned++;
    final pick = Random().nextInt(6);
    if (pick == 0) {
      world.add(Boss(floor: maxFloors, position: pos)..priority = 25);
    } else if (pick == 1) {
      world.add(KnightBoss(floor: maxFloors, position: pos)..priority = 25);
    } else if (pick == 2) {
      world.add(KingBoss(position: pos)..priority = 26);
    } else if (pick == 3) {
      world.add(MiniBoss(floor: maxFloors, position: pos)..priority = 24);
    } else if (pick == 4) {
      world.add(PlagueLordBoss(position: pos)..priority = 26);
    } else {
      world.add(BloodChampionBoss(position: pos)..priority = 26);
    }
  }

  void _checkPortal() {
    if (arenaMode) {
      if (enemiesAlive <= 0 && enemiesSpawned >= enemiesToSpawn) {
        arenaWave++;
        enemiesToSpawn = 6 + arenaWave + (difficulty == Difficulty.hard ? 2 : 0);
        if (arenaModifier == ArenaModifier.swarm) enemiesToSpawn = (enemiesToSpawn * 1.45).round();
        enemiesAlive = enemiesToSpawn;
        spawnInterval = max(0.18, 0.9 - arenaWave * 0.02 - arenaThreatTier * 0.006);
        spawnTimer = 0.15;
        enemiesSpawned = 0;
      }
      return;
    }
    if (portalSpawned) return;
    final living = countLivingHostiles();
    final pending = (enemiesToSpawn - enemiesSpawned).clamp(0, 999);
    if (living <= 0 && pending <= 0) {
      _forceSpawnPortal();
    }
  }

  void _spawnSecretBoss({required bool cyclops}) {
    secretBossSpawned = true;
    secretBossUnlockedThisLevel = true;
    enemiesAlive++;
    enemiesToSpawn++;
    enemiesSpawned++;
    final pos = Vector2(mapWidth / 2, mapHeight / 2 - 200);
    if (cyclops) {
      world.add(CyclopsBoss(position: pos)..priority = 28);
    } else {
      world.add(TentacleBoss(position: pos)..priority = 28);
    }
    triggerShake(power: 14, time: 0.4);
  }

  void onSecretBossKilled({required bool cyclops}) {
    secretBossDefeated = true;
    secretBossesDefeatedTotal++;
    tacticalAchievements++;
    persistExpansion();
    score += 6666;
    scraps += 20;
    skillPoints += 1;
    if (cyclops) {
      hasLaserAbility = true;
      _ensureLaserButton();
      unlockCodex(CodexId.cyclops);
    } else {
      if (activeChallenge != RankChallenge.noDash) {
        hasDashAbility = true;
        _ensureDashButton();
      }
      unlockCodex(CodexId.tentacle);
    }
    enemiesAlive = countLivingHostiles();
    if (enemiesAlive <= 0 && (enemiesToSpawn - enemiesSpawned) <= 0) {
      _forceSpawnPortal();
    }
  }

  bool get areOtherBossesAlive {
    for (final c in world.children) {
      if (c is Boss || c is KnightBoss || c is PlagueLordBoss || c is BloodChampionBoss) return true;
    }
    return false;
  }
    @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying || isPaused) return;

    combatAnimClock += dt;
    hitPulse = max(0, hitPulse - dt * 2.8);
    bolterHeat = max(0, bolterHeat - dt * 0.18);
    missionAlarmClock += dt;
    _fieldEventClock += dt;
    if (!arenaMode && _fieldEventClock >= 72) { _fieldEventClock = 0; if (Random().nextDouble() < 0.48) triggerRandomMissionEvent(); }
    if (fieldMedkitCooldown > 0) fieldMedkitCooldown = max(0, fieldMedkitCooldown - dt);
    // Alarm is a soft pressure system, not a forced spawn: it raises enemy alert and is capped.
    if (!arenaMode && missionAlarmClock >= 45) {
      missionAlarmClock = 0;
      campaign.alarm = min(100, campaign.alarm + (campaign.missionApproach == 'investigate' ? 8 : 5));
      if (campaign.alarm == 25 || campaign.alarm == 50 || campaign.alarm == 75) {
        spawnDamageNumber(player.position, 0, color: const Color(0xFFFF7043), label: 'ТРЕВОГА ${campaign.alarm}%');
      }
    }
    // Dissipator / Warp Anchor reduce stress growth; always decay
    final stressDecay = 0.14 * (loadout.staffFocus == StaffFocusMod.dissipator ? 1.6 : 1.0) * (hasWarpAnchor ? 1.3 : 1.0);
    staffWarpStress = max(0, staffWarpStress - dt * stressDecay);
    if (warpResetCooldown > 0) warpResetCooldown = max(0, warpResetCooldown - dt);
    if (bossRetreatTimer > 0) bossRetreatTimer = max(0, bossRetreatTimer - dt);
    if (!arenaMode) {
      _corruptionClock += dt;
      _warpStabilityClock += dt;
      if (_warpStabilityClock >= 20.0) {
        _warpStabilityClock = 0;
        warpStability = max(0.0, warpStability - (activeBiome == BiomeId.warpRuin ? 3.0 : 1.0)).toDouble();
        if (warpStability <= 20 && warpStability > 0) spawnDamageNumber(player.position, 0, color: const Color(0xFFCE93D8), label: 'СТАБИЛЬНОСТЬ ВАРПА НИЗКАЯ');
        if (warpStability <= 0) { warpCorruption = min(100, warpCorruption + 2); if (Random().nextDouble() < 0.18) player.takeDamage(1); }
      }
      final corruptionInterval = inquisitionAlignment == 'radical' ? 32.0 : 48.0;
      if (_corruptionClock >= corruptionInterval) {
        _corruptionClock = 0;
        warpCorruption = min(100, warpCorruption + 1);
        if (warpCorruption == 60 || warpCorruption == 90) {
          spawnDamageNumber(player.position, 0, color: const Color(0xFFCE93D8), label: 'ВАРП: $warpCorruption%');
        }
      }
    }

    if (servoSkullLevel > 0 && isPlaying && !isPaused) {
      _servoSkullPulse += dt;
      if (_servoSkullPulse >= max(0.55, 1.65 - servoSkullLevel * 0.25)) {
        _servoSkullPulse = 0;
        Enemy? target;
        var best = 250.0 + servoSkullLevel * 55.0;
        for (final e in world.children.whereType<Enemy>()) {
          final d = e.position.distanceTo(player.position);
          if (d < best) { best = d; target = e; }
        }
        if (target != null) {
          target.applyDamage(1 + servoSkullLevel);
          if (servoSkullLevel >= 2) target.applyStatus(StatusType.slow, 0.45, tickDamage: 0);
          spawnDamageNumber(target.position, 1 + servoSkullLevel, color: const Color(0xFF80DEEA), label: 'ЧЕРЕП');
        }
      }
    }

    if (dashCooldown > 0) dashCooldown = max(0, dashCooldown - dt);
    if (dashActive > 0) {
      dashActive = max(0, dashActive - dt);
      if (dashActive <= 0) player.priority = 20;
    }
    if (laserCooldown > 0) laserCooldown = max(0, laserCooldown - dt);
    if (artifactCooldown > 0) artifactCooldown = max(0, artifactCooldown - dt);
    if (ordoAbilityCooldown > 0) ordoAbilityCooldown = max(0, ordoAbilityCooldown - dt);
    if (ordoWardTimer > 0) ordoWardTimer = max(0, ordoWardTimer - dt);
    if (expansionSystems.ordoDoctrine.unlockedSkills.isNotEmpty) {
      _ordoAuraClock += dt;
      if (_ordoAuraClock >= 1.6) {
        _ordoAuraClock = 0;
        final malleus = playerClass == PlayerClass.malleus;
        world.add(OrdoPassivePulse(position: player.position.clone(), color: malleus ? const Color(0xFF9575CD) : const Color(0xFFEF5350))..priority = 21);
      }
    }
    if (holyAuraTimer > 0) {
      holyAuraTimer = max(0, holyAuraTimer - dt);
      _holyAuraDamageTick -= dt;
      // Damage is applied at a fixed interval, not once per rendered frame.
      // This keeps the aura balanced on 30/60/120 Hz devices alike.
      if (holyAuraTimer > 0 && _holyAuraDamageTick <= 0) {
        _holyAuraDamageTick = 0.5;
        for (final e in world.children.whereType<Enemy>().toList()) {
          if (e.position.distanceTo(player.position) < 110) {
            e.applyDamage(1);
            e.applyStatus(StatusType.burn, 0.8, tickDamage: 1);
          }
        }
      }
    } else {
      _holyAuraDamageTick = 0;
    }
    if (tempDmgTimer > 0) {
      tempDmgTimer -= dt;
      if (tempDmgTimer <= 0) tempDmgMult = 1.0;
    }
    if (shieldTimer > 0) shieldTimer = max(0, shieldTimer - dt);
    if (_hasteTimer > 0) _hasteTimer = max(0, _hasteTimer - dt);
    if (invulnTimer > 0) invulnTimer = max(0, invulnTimer - dt);
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        combo = 0;
        _comboMilestonesClaimed.clear();
      }
    }

    if (cinemaZoomTimer > 0) {
      cinemaZoomTimer -= dt;
      final t = 1 - (cinemaZoomTimer / 0.45).clamp(0.0, 1.0);
      final z = cinemaZoomFrom + (cinemaZoomTo - cinemaZoomFrom) * sin(t * pi);
      camera.viewfinder.zoom = z;
      if (cinemaZoomTimer <= 0) camera.viewfinder.zoom = currentZoom;
    }

    if (shakeTime > 0) {
      shakeTime -= dt;
      final ox = (Random().nextDouble() - 0.5) * shakePower * 2;
      final oy = (Random().nextDouble() - 0.5) * shakePower * 2;
      camera.viewfinder.position = player.position + Vector2(ox, oy);
    } else {
      camera.follow(player);
    }

    if (!isBossLevel && enemiesSpawned < enemiesToSpawn) {
      spawnTimer -= dt;
      if (spawnTimer <= 0) {
        spawnTimer = spawnInterval;
        _spawnOneEnemy();
      }
    }

    _checkPortal();

    if (!secretBossSpawned && !secretBossUnlockedThisLevel) {
      final inCorner = player.position.x < 140 && player.position.y < 140;
      final needLevel = overallLevel == 5 || overallLevel == 10;
      if (needLevel && inCorner && countLivingHostiles() <= 0) {
        cornerStandTimer += dt;
        if (cornerStandTimer >= 33) _spawnSecretBoss(cyclops: overallLevel == 10);
      } else {
        cornerStandTimer = 0;
      }
    }

    nearPortal = false;
    for (final p in world.children.whereType<Portal>()) {
      if (player.position.distanceTo(p.position) < 70) {
        nearPortal = true;
        break;
      }
    }
    if (nearPortal && portalButton == null) {
      portalButton = HudButtonComponent(
        button: CircleComponent(radius: buttonSize * 0.5, paint: Paint()..color = const Color(0xFFE91E63)),
        margin: const EdgeInsets.only(bottom: 200),
        onPressed: goNextLevel,
      );
      camera.viewport.add(portalButton!);
      _addControlLabel(HudLabel(text: 'P', margin: const EdgeInsets.only(bottom: 210)));
    } else if (!nearPortal && portalButton != null) {
      portalButton!.removeFromParent();
      portalButton = null;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isPlaying) return;
    final hp = '${player.health}/${player.maxHealth}';
    final double hpRatio = player.maxHealth <= 0 ? 0.0 : (player.health / player.maxHealth).clamp(0.0, 1.0).toDouble();
    final hpColor = hpRatio <= 0.25 ? const Color(0xFFFF5252) : hpRatio <= 0.5 ? const Color(0xFFFFC107) : const Color(0xFF76FF03);
    final hpText = TextPainter(
      text: TextSpan(text: 'ЖИЗНЬ  $hp', style: TextStyle(color: hpColor, fontSize: 16, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black, blurRadius: 5)])),
      textDirection: TextDirection.ltr,
    )..layout();
    final hpCenterX = (size.x - hpText.width) / 2;
    final hpY = size.y - 54;
    final hpBarWidth = min(190.0, max(112.0, size.x * 0.34));
    final hpBarRect = Rect.fromLTWH((size.x - hpBarWidth) / 2, size.y - 29, hpBarWidth, 7);
    canvas.drawRRect(RRect.fromRectAndRadius(hpBarRect, const Radius.circular(4)), Paint()..color = const Color(0xCC151515));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(hpBarRect.left, hpBarRect.top, hpBarWidth * hpRatio, hpBarRect.height), const Radius.circular(4)), Paint()..color = hpColor);
    hpText.paint(canvas, Offset(hpCenterX, hpY));
    final nodeLabel = floorPath.isNotEmpty && pathIndex < floorPath.length
        ? floorPath[pathIndex].label
        : 'Ур.$currentLevel';
    final heatBar = (!usingMelee && bolterHeat > 0.05 && playerClass == PlayerClass.xenos)
        ? ' 🔥${(bolterHeat * 100).toInt()}%'
        : '';
    final warpBar = (!usingMelee && staffWarpStress > 0.05 && playerClass == PlayerClass.malleus)
        ? ' Ψ${(staffWarpStress * 100).toInt()}%'
        : '';
    final lines = [
      'Этаж $currentFloor/$maxFloors • $activeBiomeLabel • ${activeMapLayout.name} • Ψ${warpStability.round()}% • $nodeLabel  Очки:$score  Обл:$scraps$heatBar$warpBar',
      if (arenaMode) 'АРЕНА W$arenaWave • Убито:$arenaKills • Угроза ${arenaThreatTier + 1} • ${difficulty.labelRu} • ${arenaModifier.labelRu}',
      'Доктрина: ${combatDoctrine.labelRu} • Боеприпасы: ${ammoDoctrine.labelRu}',
      if (oathAcceptedThisRun && !arenaMode) 'КЛЯТВА: ${playerClass.title} • Тревога ${campaign.alarm}% • Улики ${campaign.evidence} • Подозрение ${campaign.suspicion}%',
      if (!arenaMode) 'ПРИКАЗ: ${activeContract.labelRu} • ${contractProgress.clamp(0, contractTarget)}/$contractTarget${contractClaimed ? ' ✓' : ''}',
      if (isBossLevel || isMiniBossLevel) 'Адаптация противника: $adaptiveBossTactic',
      if (isSurvivalNode && !arenaMode) 'ЗАДАНИЕ: ВЫЖИВАНИЕ • ВОЛНА x2',
      if (!arenaMode && warpCorruption >= 25) 'Порча Варпа: $warpCorruption%${warpCorruption >= 60 ? ' • Враги усилены' : ''}',
      if (combo >= 2) 'COMBO x$combo',
      if (activeSynergyLabel != null) activeSynergyLabel!,
      if (activeChallenge != RankChallenge.none) 'Испытание: ${activeChallenge.title}',
    ];
    double y = 48;
    for (final line in lines) {
      hudPaint.render(canvas, line, Vector2(12, y));
      y += 16;
    }
  }

  void goNextLevel() {
    recordChronicle('Переход к следующему узлу кампании: этаж $currentFloor, уровень $currentLevel.');
    if (!nearPortal || !portalSpawned) return;
    playClick();
    // Auto-save on portal
    saveGame();
    isPaused = true;
    overlays.add('levelComplete');
  }

  void nextLevel() {
    overlays.remove('levelComplete');
    campaign.operationsCompleted++;
    campaign.alarm = max(0, campaign.alarm - 12);
    if (campaign.evidence >= 3) {
      campaign.suspicion = max(0, campaign.suspicion - 4);
      campaign.lastReport = 'Операция ${campaign.operationsCompleted}: улики сопоставлены; подозрение конклава снижено.';
    } else {
      campaign.suspicion = min(100, campaign.suspicion + (campaign.missionApproach == 'purge' ? 1 : 3));
      campaign.lastReport = 'Операция ${campaign.operationsCompleted}: цель устранена; доказательств для полного отчёта недостаточно.';
    }
    campaign.evidence = max(0, campaign.evidence - 1);
    persistExpansion();
    pathIndex++;
    // End of floor (after boss node) or path exhausted
    if (pathIndex >= floorPath.length || isBossLevel) {
      if (isBossLevel && currentFloor >= maxFloors) {
        showVictory();
        return;
      }
      if (isBossLevel) {
        currentFloor++;
        recordCareerProgress(floors: currentFloor);
        rollWorldAndMissionEvents(seed: operationSerial + currentFloor * 101);
        pathIndex = 0;
        generateFloorPath();
        syncLevelFromPath();
      } else if (pathIndex >= floorPath.length) {
        pathIndex = 0;
        currentFloor++;
        recordCareerProgress(floors: currentFloor);
        rollWorldAndMissionEvents(seed: operationSerial + currentFloor * 101);
        if (currentFloor > maxFloors) {
          showVictory();
          return;
        }
        generateFloorPath();
        syncLevelFromPath();
      }
      skillPoints += 1;
      pendingRewards = _rollRewards();
      overlays.add('reward');
      isPaused = true;
      return;
    }
    syncLevelFromPath();
    skillPoints += 1;
    if (pathIndex < floorPath.length - 1 && Random().nextDouble() < 0.4) {
      pendingPathChoices = [
        floorPath[pathIndex],
        PathNode(
          [PathNodeKind.combat, PathNodeKind.event, PathNodeKind.elite, PathNodeKind.rest, PathNodeKind.hunt, PathNodeKind.defense, PathNodeKind.ritual, PathNodeKind.survival][Random().nextInt(8)],
          'Альтернатива',
        ),
      ];
      overlays.add('pathSelect');
      isPaused = true;
      return;
    }
    pendingRewards = _rollRewards();
    overlays.add('reward');
    isPaused = true;
  }

  void choosePathNode(int index) {
    if (index >= 0 && index < pendingPathChoices.length) {
      if (pathIndex < floorPath.length) {
        floorPath[pathIndex] = pendingPathChoices[index];
      }
    }
    syncLevelFromPath();
    overlays.remove('pathSelect');
    pendingRewards = _rollRewards();
    overlays.add('reward');
  }

  List<RewardOption> _rollRewards() {
    final opts = <RewardOption>[];
    final pool = <RewardOption>[
      RewardOption('Навык +1 SP', 'Очко навыка', RewardKind.skillPoint),
      RewardOption('Обломки +12', 'Валюта', RewardKind.scraps),
      RewardOption('Хил +2', 'Восстановить HP', RewardKind.heal),
    ];
    final missing = RelicId.values.where((r) => !relics.contains(r)).toList();
    if (missing.isNotEmpty) {
      final r = missing[Random().nextInt(missing.length)];
      pool.add(RewardOption(r.title, r.desc, RewardKind.relic, relic: r));
    }
    pool.shuffle();
    for (int i = 0; i < 3 && i < pool.length; i++) {
      opts.add(pool[i]);
    }
    return opts;
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

  void showVictory() {
    // A completed campaign counts as one career operation; individual rooms do not.
    if (highThreatOperation) unlockedAchievementIds.add('career_high_threat_completed');
    recordCareerProgress(operations: 1);
    final evacReward = evacuationRoute == 0 ? 8 : evacuationRoute == 1 ? 14 : 5;
    requisition += evacReward;
    if (evacuationRoute == 2) campaign.suspicion = max(0, campaign.suspicion - 4);
    if (evacuationRoute == 1) campaign.alarm = min(100, campaign.alarm + 8);
    persistExpansion();
    isPlaying = false;
    isPaused = true;
    stopMusic();
    addScoreEntry(completed: true);
    recordVictoryRank();
    overlays.add('victory');
  }

  void finishAfterVictory() {
    overlays.remove('victory');
    if (inquisitionRank.wins >= 2 && inquisitionRank.wins % 2 == 0 && inquisitionRank.chosenPerk == RankPerk.none) {
      overlays.add('rankPerk');
    } else {
      backToMenu();
    }
  }

  void chooseRankPerk(RankPerk p) {
    inquisitionRank.chosenPerk = p;
    persistRank();
    overlays.remove('rankPerk');
    backToMenu();
  }

  void startArena() {
    overlays.remove('victory');
    arenaMode = true;
    arenaKills = 0;
    arenaWave = 1;
    isPlaying = true;
    isPaused = false;
    playStartTime = DateTime.now();
    startMusic();
    _startArenaLevel();
  }

  void showGameOver() {
    isPlaying = false;
    isPaused = true;
    stopMusic();
    addScoreEntry();
    overlays.add('gameOver');
  }

  void openInquisitionHub() {
    if (isPlaying) {
      isPaused = true;
    }
    overlays.remove('mainMenu');
    overlays.remove('victory');
    overlays.add('inquisitionHub');
  }

  int get _baseUpgradeCost => 35;

  void upgradeBase(String area) {
    if (isPlaying) return;
    int level;
    switch (area) {
      case 'arsenal': level = arsenalUpgrade; break;
      case 'shrine': level = shrineUpgrade; break;
      case 'archive': level = archiveUpgrade; break;
      case 'medicae': level = medicaeUpgrade; break;
      default: return;
    }
    if (level >= 5) return;
    final cost = _baseUpgradeCost * (level + 1);
    if (requisition < cost) return;
    requisition -= cost;
    switch (area) {
      case 'arsenal': arsenalUpgrade++; break;
      case 'shrine': shrineUpgrade++; break;
      case 'archive': archiveUpgrade++; break;
      case 'medicae': medicaeUpgrade++; break;
    }
    persistExpansion();
    persistCustomization();
  }

  Future<void> resolveInvestigation(bool radical) async {
    investigationsResolved++;
    recordChronicle('Расследование завершено: ${radical ? 'радикальный подход' : 'пуританский подход'}; тревога ${campaign.alarm}%, подозрение ${campaign.suspicion}%.');
    if (radical) {
      inquisitionAlignment = 'radical';
      if (!artifactInvestigationResolved) requisition += 35;
      warpCorruption = min(100, warpCorruption + 12);
      legendaryWeapon = legendaryWeapon == 'none' ? 'warp' : legendaryWeapon;
    } else {
      inquisitionAlignment = 'puritan';
      if (!artifactInvestigationResolved) permanentSkillBonus += 1;
      warpCorruption = max(0, warpCorruption - 18);
      if (playerClass == PlayerClass.hereticus) legendaryWeapon = 'executionerBlade';
      else if (playerClass == PlayerClass.malleus) legendaryWeapon = 'sanctified';
      else legendaryWeapon = 'emperor';
    }
    artifactInvestigationResolved = true;
    await persistExpansion();
    await persistCustomization();
    recomputeStats();
  }

  void selectSpecialization(String value) {
    specialization = value;
    recomputeStats();
    persistExpansion();
  }

  void selectLegendaryWeapon(String value) {
    legendaryWeapon = value;
    recomputeStats();
    persistExpansion();
  }

  void purifyCorruption() {
    warpCorruption = 0;
    scraps = max(0, scraps - 15);
    persistExpansion();
    recomputeStats();
  }

  void openNameInput() {
    for (final o in [
      'mainMenu', 'gameOver', 'victory', 'records', 'settings', 'loadSave',
      'classSelect', 'oathSelect', 'codex', 'eventAltar', 'eventMerchant', 'pathSelect', 'lorePopup', 'challengeSelect', 'rankPerk', 'inquisitionHub',
    ]) {
      overlays.remove(o);
    }
    overlays.add('nameInput');
  }

  void confirmName(String name, Difficulty diff) {
    playerName = name.trim().isEmpty ? 'Inquisitor' : name.trim();
    difficulty = diff;
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
    oathAcceptedThisRun = false;
    playerClass = cls;
    applyClassDefaults();
    if (activeChallenge == RankChallenge.noDash) hasDashAbility = false;
    activeOathName = OrdoOath.forClass(cls).title;
    oathAcceptedThisRun = false;
    overlays.remove('classSelect');
    overlays.add('oathSelect');
    isPaused = true;
  }

  void confirmOath(String approach) {
    campaign.resetForNewRun();
    campaign.missionApproach = approach;
    if (approach == 'investigate') {
      campaign.evidence += 1;
      campaign.alarm = 10;
    } else if (approach == 'purge') {
      campaign.suspicion = max(0, campaign.suspicion - 5);
      campaign.alarm = 20;
    } else {
      campaign.alarm = 0;
    }
    oathAcceptedThisRun = true;
    activeOathName = OrdoOath.forClass(playerClass).title;
    overlays.remove('oathSelect');
    isPaused = false;
    startNewRun();
  }

  void startNewRun() {
    operationSerial++;
    consumables[TacticalConsumable.fragGrenade] = 2;
    consumables[TacticalConsumable.stim] = 1;
    consumables[TacticalConsumable.smoke] = 1;
    consumables[TacticalConsumable.auspexPulse] = 1;
    score = 0;
    missionAlarmClock = 0;
    _fieldEventClock = 0;
    fieldMedkitCooldown = 0;
    scraps = inquisitionRank.startScraps + arsenalUpgrade * 5;
    warpCorruption = 0;
    _corruptionClock = 0;
    currentFloor = 1;
    currentLevel = 1;
    pathIndex = 0;
    skills = SkillTree();
    skillPoints = inquisitionRank.startSpBonus + permanentSkillBonus + archiveUpgrade ~/ 2;
    relics.clear();
    loadout = WeaponLoadout();
    activeArtifact = ActiveArtifact.fragGrenade;
    ordoAbilityCooldown = 0;
    ordoWardTimer = 0;
    arenaMode = false;
    arenaKills = 0;
    legendaryKillCounter = 0;
    _savedPlaySeconds = 0;
    playStartTime = DateTime.now();
    hasDashAbility = playerClass == PlayerClass.hereticus && activeChallenge != RankChallenge.noDash;
    hasLaserAbility = false;
    _everReached11 = false;
    _everReached21 = false;
    secretBossDefeated = false;
    pendingEcho = EchoBossKind.none;
    levelsSinceEvent = 0;
    bolterHeat = 0;
    staffWarpStress = 0;
    warpResetCooldown = 0;
    challengeBossMeleeOk = true;
    ironWillUsedThisFloor = false;
    generateFloorPath();
    syncLevelFromPath();
    rollWorldAndMissionEvents(seed: operationSerial + currentFloor * 101);
    recomputeStats();
    isPlaying = true;
    isPaused = false;
    currentZoom = 0.85;
    camera.viewfinder.zoom = currentZoom;
    _clearEverything();
    _startLevel();
    persistExpansion();
    startMusic();
  }

  void _clearEverything() {
    world.removeAll(world.children.toList());
    camera.viewport.children.toList().forEach((c) {
      if (c is! CameraComponent) c.removeFromParent();
    });
    _controlHudLabels.clear();
  }

  void openSettings() {
    isPaused = true;
    overlays.add('settings');
  }

  void closeSettings() {
    overlays.remove('settings');
    isPaused = false;
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
    _clearEverything();
    for (final o in [
      'gameOver', 'victory', 'levelComplete', 'skills', 'reward', 'shop',
      'settings', 'backpack', 'nameInput', 'classSelect', 'records', 'loadSave',
      'codex', 'eventAltar', 'eventMerchant', 'pathSelect', 'lorePopup', 'challengeSelect', 'rankPerk', 'inquisitionHub',
    ]) {
      overlays.remove(o);
    }
    overlays.add('mainMenu');
  }
}

enum RewardKind { skillPoint, scraps, heal, relic }

class RewardOption {
  final String title, subtitle;
  final RewardKind kind;
  final RelicId? relic;
  RewardOption(this.title, this.subtitle, this.kind, {this.relic});
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
          g.player.health = min(g.player.maxHealth, g.player.health + 2);
        }
        break;
      case RewardKind.relic:
        if (relic != null) g.grantRelic(relic!);
        break;
    }
  }
}

/// Cooldown ring on attack joystick (F)
class AttackCooldownRing extends PositionComponent with HasGameReference<InquisitorGame> {
  AttackCooldownRing() : super(priority: 199);

  @override
  void onMount() {
    super.onMount();
    final size = game.size;
    position = Vector2(size.x - 28 - game.joystickSize * 0.55, size.y - 28 - game.joystickSize * 0.55);
  }

  @override
  void render(Canvas canvas) {
    if (!game.isPlaying || game.isPaused) return;
    final r = game.joystickSize * 0.55;
    // Only show heat ring when using bolter and heat > 0
    if (!game.usingMelee && game.playerClass == PlayerClass.xenos && game.bolterHeat > 0.05) {
      final sweep = game.bolterHeat * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r, r), radius: r + 4),
        -pi / 2,
        sweep,
        false,
        Paint()
          ..color = Color.lerp(const Color(0xFFFFEB3B), const Color(0xFFFF1744), game.bolterHeat)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    if (!game.usingMelee && game.playerClass == PlayerClass.malleus && game.staffWarpStress > 0.05) {
      final sweep = game.staffWarpStress * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r, r), radius: r + 8),
        -pi / 2,
        sweep,
        false,
        Paint()
          ..color = const Color(0xFF9C27B0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}

class BreakableBarrel extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  int hp = 2;
  final int kind; // 0 normal, 1 explosive, 2 heal, 3 scrap
  BreakableBarrel({required Vector2 position, this.kind = 0})
      : super(position: position, size: Vector2(44, 52), anchor: Anchor.center, priority: 6);

  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 20));

  void hit() {
    hp--;
    if (hp <= 0) {
      final r = Random().nextDouble();
      final scav = game.hasScavenger ? 1.35 : 1.0;
      if (kind == 1 || (kind == 0 && r < 0.25)) {
        game.world.add(KillExplosion(position: position.clone(), radius: 70, damage: 8 + game.overallLevel)..priority = 12);
        game.triggerShake(power: 5, time: 0.12);
      } else if (kind == 2 || (kind == 0 && r < 0.45)) {
        game.world.add(MedkitPickup(position: position.clone()));
      } else if (kind == 3 || (kind == 0 && r < 0.70)) {
        final gain = ((3 + Random().nextInt(4)) * scav).round();
        game.scraps += gain;
        game.spawnDamageNumber(position, 0, color: const Color(0xFFFFD700), label: '+$gain');
      } else {
        game.scraps += (2 * scav).round();
      }
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is MeleeAttack || other is Bullet || other is PsyWave) hit();
  }

  @override
  void render(Canvas canvas) {
    WHDraw.barrel(canvas, size.x / 2, size.y / 2, kind: kind);
  }
}

class EventAltarProp extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  double flicker = 0;
  EventAltarProp({required Vector2 position})
      : super(position: position, size: Vector2(64, 64), anchor: Anchor.center, priority: 8);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 32));
  @override
  void update(double dt) {
    super.update(dt);
    flicker += dt;
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player && !game.eventResolved) game.openEventAltar();
  }
  @override
  void render(Canvas canvas) => WHDraw.altar(canvas, size.x / 2, size.y / 2, flicker: flicker);
}

class EventMerchantProp extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  double flicker = 0;
  EventMerchantProp({required Vector2 position})
      : super(position: position, size: Vector2(70, 70), anchor: Anchor.center, priority: 8);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 34));
  @override
  void update(double dt) {
    super.update(dt);
    flicker += dt;
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player && !game.eventResolved) game.openEventMerchant();
  }
  @override
  void render(Canvas canvas) => WHDraw.merchantStall(canvas, size.x / 2, size.y / 2, flicker: flicker);
}

class HudLabel extends PositionComponent with HasGameReference<InquisitorGame> {
  final String text;
  EdgeInsets margin;
  HudLabel({required this.text, required this.margin}) : super(priority: 200);

  void updateMargin(EdgeInsets value) {
    margin = value;
    final screen = game.size;
    double x = margin.left, y = margin.top;
    if (margin.right > 0) x = screen.x - margin.right - 12;
    if (margin.bottom > 0) y = screen.y - margin.bottom - 12;
    if (margin.left == 0 && margin.right == 0) x = screen.x / 2 - 6;
    position = Vector2(x.toDouble(), y.toDouble());
  }

  @override
  void onMount() {
    super.onMount();
    updateMargin(margin);
  }
  @override
  void render(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset.zero);
  }
}

mixin SmartMover on PositionComponent, HasGameReference<InquisitorGame> {
  double stuckTimer = 0;
  Vector2? avoidDir;
  double strafeSign = 1;
  double rethinkTimer = 0;

  void smartMove(Vector2 target, double speed, double dt, {double radius = 30, bool kite = false, double preferDist = 0}) {
    // Boss retreat after volley
    if (game.bossRetreatTimer > 0 && (this is Boss || this is KnightBoss || this is KingBoss || this is PlagueLordBoss || this is BloodChampionBoss)) {
      kite = true;
      preferDist = max(preferDist, 280);
    }
    rethinkTimer -= dt;
    if (rethinkTimer <= 0) {
      rethinkTimer = 0.4 + Random().nextDouble() * 0.5;
      strafeSign = Random().nextBool() ? 1.0 : -1.0;
    }
    var toTarget = target - position;
    final dist = toTarget.length;
    if (dist < 1) return;
    var desired = toTarget / dist;
    if (kite && preferDist > 0) {
      if (dist < preferDist * 0.75) {
        desired = -desired;
      } else if (dist < preferDist * 1.15) {
        desired = Vector2(-desired.y, desired.x) * strafeSign;
      }
    }
    Vector2 sep = Vector2.zero();
    for (final e in game.world.children.whereType<Enemy>()) {
      if (identical(e, this)) continue;
      final d = position.distanceTo(e.position);
      if (d > 0 && d < radius * 2.4) {
        sep += (position - e.position).normalized() * ((radius * 2.4 - d) / (radius * 2.4));
      }
    }
    if (sep.length2 > 0.01) desired = (desired + sep.normalized() * 0.55).normalized();
    if (avoidDir != null) {
      stuckTimer -= dt;
      if (stuckTimer <= 0) {
        avoidDir = null;
      } else {
        desired = (desired * 0.35 + avoidDir! * 0.65).normalized();
      }
    }
    final next = position + desired * speed * dt;
    if (_canStand(next, radius)) {
      position = next;
    } else {
      final slide1 = Vector2(-desired.y, desired.x);
      final slide2 = Vector2(desired.y, -desired.x);
      final n1 = position + slide1 * speed * dt;
      final n2 = position + slide2 * speed * dt;
      if (_canStand(n1, radius)) {
        position = n1;
        avoidDir = slide1;
        stuckTimer = 0.55;
      } else if (_canStand(n2, radius)) {
        position = n2;
        avoidDir = slide2;
        stuckTimer = 0.55;
      } else {
        final back = position - desired * speed * dt * 0.6;
        if (_canStand(back, radius)) position = back;
        position.x = position.x.clamp(80, game.mapWidth - 80);
        position.y = position.y.clamp(80, game.mapHeight - 80);
        avoidDir = Vector2(Random().nextDouble() - 0.5, Random().nextDouble() - 0.5).normalized();
        stuckTimer = 0.7;
      }
    }
  }

  bool _canStand(Vector2 pos, double radius) {
    if (pos.x < 70 + radius || pos.x > game.mapWidth - 70 - radius) return false;
    if (pos.y < 70 + radius || pos.y > game.mapHeight - 70 - radius) return false;
    for (final w in game.world.children.whereType<Wall>()) {
      final r = w.toAbsoluteRect();
      if (Rect.fromLTRB(r.left - radius, r.top - radius, r.right + radius, r.bottom + radius).contains(pos.toOffset())) {
        return false;
      }
    }
    for (final o in game.world.children.whereType<Obstacle>()) {
      if (pos.distanceTo(o.position) < radius + 32) return false;
    }
    // Slightly larger clearance so enemies don't stick to barrels
    for (final b in game.world.children.whereType<BreakableBarrel>()) {
      if (pos.distanceTo(b.position) < radius + 28) return false;
    }
    return true;
  }

  void pushOutOfWalls(double radius) {
    for (final w in game.world.children.whereType<Wall>()) {
      final r = w.toAbsoluteRect();
      if (Rect.fromLTRB(r.left - radius, r.top - radius, r.right + radius, r.bottom + radius).contains(position.toOffset())) {
        final dx = position.x - r.center.dx;
        final dy = position.y - r.center.dy;
        if (dx.abs() > dy.abs()) {
          position.x += dx > 0 ? 14 : -14;
        } else {
          position.y += dy > 0 ? 14 : -14;
        }
      }
    }
    for (final b in game.world.children.whereType<BreakableBarrel>()) {
      final d = position.distanceTo(b.position);
      if (d < radius + 24 && d > 0.1) {
        position += (position - b.position).normalized() * 10;
      }
    }
  }
}

class EnemySpawnPortal extends PositionComponent {
  double flicker = 0;
  EnemySpawnPortal({required Vector2 position})
      : super(position: position, size: Vector2(48, 48), anchor: Anchor.center, priority: 3);
  @override
  void update(double dt) {
    super.update(dt);
    flicker += dt * 4;
  }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 18, Paint()..color = Color.fromRGBO(255, 140, 0, 0.45 + 0.4 * sin(flicker)));
  }
}

class PlayerSpawnPoint extends PositionComponent {
  PlayerSpawnPoint({required Vector2 position})
      : super(position: position, size: Vector2(56, 56), anchor: Anchor.center, priority: 3);
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 22, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.75));
  }
}

class FieldLootPickup extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final FieldLootItem item;
  final bool secret;
  double pulse = 0;
  FieldLootPickup({required Vector2 position, required this.item, this.secret = false})
      : super(position: position, size: Vector2(38, 38), anchor: Anchor.center, priority: 7);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: secret ? 22 : 16));
  @override
  void update(double dt) { super.update(dt); pulse += dt; }
  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is Player) {
      if (secret && !game.discoveredCacheIds.contains(item.id) && game.scraps < 5) {
        game.spawnDamageNumber(position, 0, color: const Color(0xFFFF7043), label: 'ЗАПЕРТО: НУЖНО 5 ОБЛОМКОВ');
        return;
      }
      if (secret && !game.discoveredCacheIds.contains(item.id) && game.fieldInventory.length >= game.backpackCapacity) {
        game.spawnDamageNumber(position, 0, color: const Color(0xFFFF7043), label: 'СНАЧАЛА ОСВОБОДИ МЕСТО');
        return;
      }
      if (secret && !game.discoveredCacheIds.contains(item.id)) game.scraps -= 5;
      if (game.collectFieldLoot(item, secret: secret)) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final glow = 0.55 + sin(pulse * 3) * 0.18;
    final color = secret ? const Color(0xFFFFB300) : item.rarity.color;
    canvas.drawCircle(Offset(cx, cy), secret ? 15 : 11, Paint()..color = color.withOpacity(glow * 0.24));
    final path = Path()..moveTo(cx, cy - 11)..lineTo(cx + 10, cy)..lineTo(cx, cy + 11)..lineTo(cx - 10, cy)..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF101820));
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = color);
    if (secret) {
      canvas.drawLine(Offset(cx - 5, cy - 15), Offset(cx + 5, cy - 15), Paint()..color = color..strokeWidth = 2);
      canvas.drawLine(Offset(cx, cy - 20), Offset(cx, cy - 10), Paint()..color = color..strokeWidth = 2);
    }
  }
}

class FieldTerminal extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  double pulse = 0;
  FieldTerminal({required Vector2 position}) : super(position: position, size: Vector2(46, 54), anchor: Anchor.center, priority: 8);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 22));
  @override
  void update(double dt) { super.update(dt); pulse += dt; }
  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is Player) { game.activateFieldTerminal(); removeFromParent(); }
  }
  @override
  void render(Canvas canvas) {
    final c = const Color(0xFF4FC3F7);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, 4, 30, 44), const Radius.circular(4)), Paint()..color = const Color(0xFF263238));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(11, 7, 24, 24), const Radius.circular(2)), Paint()..color = c.withOpacity(0.18 + sin(pulse * 4).abs() * 0.25));
    canvas.drawRect(Rect.fromLTWH(14, 10, 18, 3), Paint()..color = c);
    canvas.drawRect(Rect.fromLTWH(14, 16, 13, 2), Paint()..color = c.withOpacity(0.8));
    canvas.drawRect(Rect.fromLTWH(14, 21, 16, 2), Paint()..color = c.withOpacity(0.6));
    canvas.drawLine(const Offset(23, 32), const Offset(23, 43), Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 3);
  }
}

class Floor extends PositionComponent {
  final int biome;
  final MapLayout layout;
  Floor({required Vector2 size, this.biome = 0, this.layout = MapLayout.chambers}) : super(size: size, position: Vector2.zero(), priority: 0);
  @override
  void render(Canvas canvas) {
    final base = switch (biome % 7) {
      0 => const Color(0xFFB0BEC5),
      1 => const Color(0xFF263238),
      2 => const Color(0xFF3E2723),
      3 => const Color(0xFF1B2635),
      5 => const Color(0xFF17232B),
      6 => const Color(0xFF142A22),
      _ => const Color(0xFF30243A),
    };
    final gridColor = switch (biome % 7) {
      0 => const Color(0xFF90A4AE),
      1 => const Color(0xFF455A64),
      2 => const Color(0xFF5D4037),
      3 => const Color(0xFF37474F),
      5 => const Color(0xFF607D8B),
      6 => const Color(0xFF00BFA5),
      _ => const Color(0xFF5E35B1),
    };
    canvas.drawRect(size.toRect(), Paint()..color = base);
    final grid = Paint()..color = gridColor..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
    }
    // Architectural floor inlays are vector-only: every layout remains readable without texture assets.
    final inlay = Paint()..color = gridColor.withOpacity(0.42)..style = PaintingStyle.stroke..strokeWidth = 3;
    // Biome-specific room motifs are generated with vector geometry only.
    final motif = Paint()..color = gridColor.withOpacity(0.28)..style = PaintingStyle.stroke..strokeWidth = 5;
    switch (biome % 7) {
      case 0: // Manufactorum: conveyor rails and service bays
        for (double y = 170; y < size.y; y += 360) {
          canvas.drawLine(Offset(90, y), Offset(size.x - 90, y), motif);
          canvas.drawRect(Rect.fromLTWH(size.x * 0.18, y - 38, size.x * 0.64, 76), motif);
        }
        break;
      case 1: // Hive: dense stacked habitation blocks
        for (double x = 130; x < size.x - 100; x += 220) {
          for (double y = 150; y < size.y - 100; y += 250) {
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 120, 150), const Radius.circular(8)), motif);
          }
        }
        break;
      case 2: // Shrine: apses, chapels and processional circles
        for (double y = 250; y < size.y - 100; y += 420) {
          canvas.drawCircle(Offset(size.x / 2, y), 95, motif);
          canvas.drawCircle(Offset(size.x / 2, y), 58, motif);
          canvas.drawLine(Offset(size.x / 2 - 145, y), Offset(size.x / 2 + 145, y), motif);
        }
        break;
      case 3: // Death world: broken terrain plates
        for (int i = 0; i < 14; i++) {
          final x = 90.0 + ((i * 173) % (size.x - 180));
          final y = 120.0 + ((i * 257) % (size.y - 240));
          final path = Path()..moveTo(x, y)..lineTo(x + 32, y - 18)..lineTo(x + 78, y + 12)..lineTo(x + 54, y + 54)..close();
          canvas.drawPath(path, motif);
        }
        break;
      case 5: // Voidship: bulkheads, hatches and deck markings
        for (double y = 120; y < size.y - 80; y += 300) {
          canvas.drawLine(Offset(80, y), Offset(size.x - 80, y), motif);
          for (double x = 130; x < size.x - 100; x += 260) {
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y - 42, 92, 84), const Radius.circular(10)), motif);
          }
        }
        break;
      case 6: // Necron tomb: obelisks and concentric dynastic seals
        for (double x = 140; x < size.x - 100; x += 280) {
          for (double y = 160; y < size.y - 100; y += 300) {
            canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 42, height: 100), motif);
            canvas.drawCircle(Offset(x, y), 66, motif);
          }
        }
        break;
      default: // Warp ruins: fractured sigils and concentric seals
        for (double y = 220; y < size.y - 120; y += 390) {
          final x = y % 2 == 0 ? size.x * 0.32 : size.x * 0.68;
          canvas.drawCircle(Offset(x, y), 70, motif);
          canvas.drawLine(Offset(x - 88, y - 88), Offset(x + 88, y + 88), motif);
          canvas.drawLine(Offset(x + 88, y - 88), Offset(x - 88, y + 88), motif);
        }
        break;
    }
    switch (layout) {
      case MapLayout.cruciform:
        canvas.drawRect(Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: size.x * 0.24, height: size.y * 0.78), inlay);
        canvas.drawRect(Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: size.x * 0.76, height: size.y * 0.18), inlay);
        break;
      case MapLayout.ring:
        canvas.drawOval(Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: size.x * 0.72, height: size.y * 0.62), inlay);
        canvas.drawOval(Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: size.x * 0.48, height: size.y * 0.42), inlay);
        break;
      case MapLayout.corridors:
        for (int i = 1; i < 5; i++) {
          final x = size.x * i / 5;
          canvas.drawLine(Offset(x, 80), Offset(x, size.y - 80), inlay);
        }
        break;
      case MapLayout.chambers:
        for (int y = 0; y < 4; y++) {
          for (int x = 0; x < 3; x++) {
            final r = Rect.fromLTWH(100 + x * (size.x - 300) / 3, 120 + y * (size.y - 360) / 4, size.x * 0.17, size.y * 0.11);
            canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), inlay);
          }
        }
        break;
      case MapLayout.openYard:
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), min(size.x, size.y) * 0.18, inlay);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), min(size.x, size.y) * 0.29, inlay);
        break;
    }
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  final Color color;
  Wall({required Vector2 position, required Vector2 size, required this.color})
      : super(position: position, size: size, priority: 5);
  @override
  Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void render(Canvas canvas) => canvas.drawRect(size.toRect(), Paint()..color = color);
}

class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({required Vector2 position})
      : super(position: position, size: Vector2(56, 56), anchor: Anchor.center, priority: 5);
  @override
  Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)), Paint()..color = const Color(0xFF6D4C41));
  }
}

class Portal extends PositionComponent with CollisionCallbacks {
  Portal({required Vector2 position})
      : super(position: position, size: Vector2(88, 88), anchor: Anchor.center, priority: 9);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawCircle((size / 2).toOffset(), 38, Paint()..color = const Color(0xFFE91E63).withOpacity(0.85));
  }
}

class MedkitPickup extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  MedkitPickup({required Vector2 position})
      : super(position: position, size: Vector2(36, 36), anchor: Anchor.center, priority: 7);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      other.health = min(other.maxHealth, other.health + 2);
      removeFromParent();
    }
  }
  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = const Color(0xFFE53935));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 5), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 5, height: 16), Paint()..color = Colors.white);
  }
}

class ShieldPickup extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  ShieldPickup({required Vector2 position})
      : super(position: position, size: Vector2(36, 36), anchor: Anchor.center, priority: 7);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      game.shieldTimer = max(game.shieldTimer, 6.0);
      removeFromParent();
    }
  }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14, Paint()..color = const Color(0xFF1E88E5).withOpacity(0.85));
  }
}

class FragGrenade extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 velocity;
  final int damage;
  double life = 0.9;
  FragGrenade({required Vector2 position, required Vector2 direction, required this.damage})
      : velocity = direction.normalized() * 320,
        super(position: position.clone(), size: Vector2(20, 20), anchor: Anchor.center, priority: 14);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 10));
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position += velocity * dt;
    if (life <= 0) _explode();
  }
  void _explode() {
    for (final e in game.world.children.whereType<Enemy>().toList()) {
      if (e.position.distanceTo(position) < 110) {
        e.applyDamage(damage);
        e.applyStatus(StatusType.burn, 2.5 + game.codexBurnBonus, tickDamage: 1);
      }
    }
    game.world.add(KillExplosion(position: position.clone(), radius: 100, damage: damage ~/ 2)..priority = 12);
    game.triggerShake(power: 7, time: 0.15);
    removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is Enemy || other is BreakableBarrel) _explode();
  }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 8, Paint()..color = const Color(0xFF5D4037));
    canvas.drawCircle(Offset(size.x / 2, size.y / 2 - 4), 3, Paint()..color = const Color(0xFFFF6D00));
  }
}

class ServoTurret extends PositionComponent with HasGameReference<InquisitorGame> {
  double life = 8.0;
  double shootTimer = 0;
  ServoTurret({required Vector2 position})
      : super(position: position.clone(), size: Vector2(40, 40), anchor: Anchor.center, priority: 14);

  PositionComponent? _nearestHostile() {
    PositionComponent? best;
    double bestD = 460;
    void consider(PositionComponent c) {
      final d = c.position.distanceTo(position);
      if (d < bestD) {
        bestD = d;
        best = c;
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
    for (final e in game.world.children.whereType<TentacleBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<CyclopsBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<PlagueLordBoss>()) {
      consider(e);
    }
    for (final e in game.world.children.whereType<BloodChampionBoss>()) {
      consider(e);
    }
    return best;
  }

  void _damageTarget(PositionComponent t, int dmg) {
    if (t is Enemy) {
      t.applyDamage(dmg);
    } else if (t is MiniBoss) {
      t.takeDamage(dmg);
    } else if (t is Boss) {
      t.takeDamage(dmg);
    } else if (t is KnightBoss) {
      t.takeDamage(dmg);
    } else if (t is KingBoss) {
      t.takeDamage(dmg);
    } else if (t is TentacleBoss) {
      t.takeDamage(dmg);
    } else if (t is CyclopsBoss) {
      t.takeDamage(dmg);
    } else if (t is PlagueLordBoss) {
      t.takeDamage(dmg);
    } else if (t is BloodChampionBoss) {
      t.takeDamage(dmg);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) {
      removeFromParent();
      return;
    }
    shootTimer += dt;
    if (shootTimer >= 0.42) {
      shootTimer = 0;
      final target = _nearestHostile();
      if (target != null) {
        final dir = (target.position - position).normalized();
        final dmg = game.scaleDamage(6 + game.overallLevel ~/ 2);
        game.world.add(Bullet(
          position: position.clone(),
          direction: dir,
          damage: dmg,
          color: const Color(0xFFFFAB40),
          speed: 500,
          radius: 5,
        )..priority = 13);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    canvas.drawCircle(Offset(cx, cy), 16, Paint()..color = const Color(0xFF455A64));
    canvas.drawCircle(Offset(cx, cy), 8, Paint()..color = const Color(0xFFFF6D00));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 2), width: 6, height: 18), Paint()..color = const Color(0xFF78909C));
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
              const Text('Выберите постоянный бонус (раз в мета)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1A1A1A),
                child: ListTile(
                  title: const Text('+1 стартовое SP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Каждый забег начинается с лишним очком навыка', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                  subtitle: const Text('Больше валюты с врагов и бочек навсегда', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    game.playClick();
                    game.chooseRankPerk(RankPerk.scrapBonus);
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  game.playClick();
                  game.chooseRankPerk(RankPerk.none);
                },
                child: const Text('ПРОПУСТИТЬ', style: TextStyle(color: Colors.white38)),
              ),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ИСПЫТАНИЕ РАНГА', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              Text(
                'Кампания: ${game.difficulty.labelRu} — ${game.difficulty.maxFloors} этажей (${game.difficulty.maxOverallLevels} узлов)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
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
              const SizedBox(height: 8),
              if (game.floorPath.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  children: List.generate(game.floorPath.length, (i) {
                    final n = game.floorPath[i];
                    final done = i < game.pathIndex;
                    final cur = i == game.pathIndex;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cur ? const Color(0xFFB8860B) : (done ? const Color(0xFF2E7D32) : const Color(0xFF333333)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(n.label, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    );
                  }),
                ),
              const SizedBox(height: 16),
              ...List.generate(game.pendingPathChoices.length, (i) {
                final n = game.pendingPathChoices[i];
                return Card(
                  color: const Color(0xFF1A1A1A),
                  child: ListTile(
                    title: Text(n.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(_kindHint(n.kind), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
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

  String _kindHint(PathNodeKind k) {
    switch (k) {
      case PathNodeKind.combat: return 'Обычный бой';
      case PathNodeKind.event: return 'Событие (алтарь / торговец / засада)';
      case PathNodeKind.elite: return 'Элитный узел — больше чемпионов';
      case PathNodeKind.rest: return 'Отдых — +2 HP, портал сразу';
      case PathNodeKind.boss: return 'Босс этажа';
      case PathNodeKind.hunt: return 'Охота — мини-босс и усиленная группа';
      case PathNodeKind.defense: return 'Оборона — засада и дополнительная волна';
      case PathNodeKind.ritual: return 'Ритуал — алтарь и выбор награды';
      case PathNodeKind.survival: return 'Выживание — двойная волна врагов и ускоренный спавн';
    }
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
              Expanded(
                child: SingleChildScrollView(
                  child: Text(id.lore, style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),
              Text(id.knowledgeBonus, textAlign: TextAlign.center, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: () => game.acceptLore(id),
                child: Text(rank == 0 ? 'ПРИНЯТЬ ЗНАНИЕ (+1%)' : 'УГЛУБИТЬ (1 SP, +1%)'),
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
              const SizedBox(height: 12),
              const Text('Пожертвуй 1 HP — получи случайную реликвию.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              Text('HP: ${game.player.health}/${game.player.maxHealth}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
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
              Text('Обломки: ${g.scraps} • ${g.playerClass.title}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              Expanded(
                child: ListView(
                  children: [
                    _item('+2 HP', 10, () { g.resolveMerchantBuy('heal'); setState(() {}); }),
                    _item('+1 SP', 18, () { g.resolveMerchantBuy('scraps_sp'); setState(() {}); }),
                    _item('Реликвия', 25, () { g.resolveMerchantBuy('relic'); setState(() {}); }),
                    if (g.playerClass == PlayerClass.xenos) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text('Моды болтера', style: TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
                      ),
                      _item('Ствол: очередь (−интервал)', 14, () { g.resolveMerchantBuy('gun_rapid'); setState(() {}); }),
                      _item('Ствол: тяжёлый (+урон, +интервал)', 14, () { g.resolveMerchantBuy('gun_heavy'); setState(() {}); }),
                      _item('Прицел: точность (+10% урон)', 12, () { g.resolveMerchantBuy('gun_precision'); setState(() {}); }),
                      _item('Прицел: широкий (дробовик +spread)', 12, () { g.resolveMerchantBuy('gun_wide'); setState(() {}); }),
                      _item('Боезапас: взрывной', 16, () { g.resolveMerchantBuy('gun_explosive'); setState(() {}); }),
                    ],
                    if (g.playerClass == PlayerClass.malleus) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text('Моды посоха', style: TextStyle(color: Color(0xFFB388FF), fontSize: 13)),
                      ),
                      _item('Сфера: +радиус / −урон', 14, () { g.resolveMerchantBuy('staff_wide'); setState(() {}); }),
                      _item('Фокус: +урон / −радиус', 14, () { g.resolveMerchantBuy('staff_focus'); setState(() {}); }),
                      _item('Диссипатор: −рост Ψ', 12, () { g.resolveMerchantBuy('staff_dissipator'); setState(() {}); }),
                    ],
                    if (g.playerClass == PlayerClass.hereticus) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text('Моды клинка', style: TextStyle(color: Color(0xFFE040FB), fontSize: 13)),
                      ),
                      _item('Зазубрины: +8% урон ближнего', 12, () { g.resolveMerchantBuy('blade_serrated'); setState(() {}); }),
                      _item('Мономолекула: +12% урон', 14, () { g.resolveMerchantBuy('blade_mono'); setState(() {}); }),
                      _item('Утяжеление: +15% урон', 14, () { g.resolveMerchantBuy('blade_weighted'); setState(() {}); }),
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
              Text(
                '${game.difficulty.labelRu}: ${game.difficulty.maxFloors} этажей',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              if (game.activeChallenge != RankChallenge.none)
                Text('Испытание: ${game.activeChallenge.title}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 12)),
              if (game.inquisitionRank.rank > 0)
                Text(
                  '${game.inquisitionRank.title} • +${(game.inquisitionRank.critBonus * 100).toStringAsFixed(0)}% крит',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 12),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _card(PlayerClass.xenos, const Color(0xFFB71C1C), 'HP 6 • Болтер • моды ствола'),
                    _card(PlayerClass.malleus, const Color(0xFF1A237E), 'HP 5 • Посох Ψ • сброс варпа'),
                    _card(PlayerClass.hereticus, const Color(0xFF4A148C), 'HP 5 • Рывок U • моды клинка'),
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

class OathSelectionMenu extends StatefulWidget {
  final InquisitorGame game;
  const OathSelectionMenu(this.game, {super.key});
  @override
  State<OathSelectionMenu> createState() => _OathSelectionMenuState();
}

class _OathSelectionMenuState extends State<OathSelectionMenu> {
  String _approach = 'balanced';
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final oath = OrdoOath.forClass(widget.game.playerClass);
    final accent = switch (widget.game.playerClass) {
      PlayerClass.malleus => const Color(0xFFB39DDB),
      PlayerClass.hereticus => const Color(0xFFE57373),
      PlayerClass.xenos => const Color(0xFF80CBC4),
    };
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: Padding(
        padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('РИТУАЛ ПРИНЯТИЯ КЛЯТВЫ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
          const SizedBox(height: 12),
          Expanded(child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF151515), border: Border.all(color: accent.withOpacity(0.7), width: 1.5), borderRadius: BorderRadius.circular(8)), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(oath.title, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8), Text('УГРОЗА: ${oath.threat}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const Divider(color: Colors.white24, height: 22),
            const Text('ДОГМА ОРДО', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            const SizedBox(height: 5), Text(oath.dogma, style: const TextStyle(color: Colors.white, height: 1.35)),
            const SizedBox(height: 14), const Text('КЛЯТВА', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            const SizedBox(height: 5), Text('«${oath.oath}»', style: const TextStyle(color: Colors.white, height: 1.45, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12), Text(oath.fieldDoctrine, style: TextStyle(color: accent, fontSize: 12, height: 1.35)),
            const SizedBox(height: 6), Text(oath.bonus, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ])))),
          const SizedBox(height: 12),
          const Text('ПОДХОД К ПЕРВОЙ ОПЕРАЦИИ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(value: _approach, dropdownColor: const Color(0xFF171717), decoration: const InputDecoration(labelText: 'Выбери доктрину операции', labelStyle: TextStyle(color: Colors.white70)), items: const [
            DropdownMenuItem(value: 'balanced', child: Text('Сбалансированный подход', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'investigate', child: Text('Разведка: начать с дополнительной уликой', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'purge', child: Text('Зачистка: снизить подозрение конклава', style: TextStyle(color: Colors.white))),
          ], onChanged: (v) => setState(() => _approach = v ?? 'balanced')),
          CheckboxListTile(value: _accepted, activeColor: accent, contentPadding: EdgeInsets.zero, title: const Text('Я принимаю клятву и последствия выбранного пути.', style: TextStyle(color: Colors.white70, fontSize: 12)), onChanged: (v) => setState(() => _accepted = v ?? false)),
          Row(children: [Expanded(child: OutlinedButton(onPressed: () { widget.game.overlays.remove('oathSelect'); widget.game.overlays.add('classSelect'); widget.game.isPaused = false; }, child: const Text('НАЗАД'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: accent), onPressed: _accepted ? () { widget.game.playClick(); widget.game.confirmOath(_approach); } : null, child: const Text('ПРИНЯТЬ КЛЯТВУ И НАЧАТЬ')))]),
        ]),
      )))),
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
                if (g.world.children.whereType<Player>().isNotEmpty) {
                  g.player.health = min(g.player.maxHealth, g.player.health + 2);
                }
                setState(() {});
              }),
              _item('+1 SP', 15, () {
                if (g.scraps < 15) return;
                g.scraps -= 15;
                g.skillPoints++;
                setState(() {});
              }),
              _item('Урон ×1.3 (этаж)', 12, () {
                if (g.scraps < 12) return;
                g.scraps -= 12;
                g.tempDmgMult = 1.3;
                g.tempDmgTimer = 9999;
                setState(() {});
              }),
              _item('Щит 8с', 10, () {
                if (g.scraps < 10) return;
                g.scraps -= 10;
                g.shieldTimer = max(g.shieldTimer, 8);
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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 22, 8, 8),
                      child: Text('ДОКТРИНА ОРДО', style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        g.playerClass == PlayerClass.malleus
                          ? 'Маллеус • защита от Варпа и охота на демонов'
                          : g.playerClass == PlayerClass.hereticus
                            ? 'Еретикус • охота на культистов и псайкеров'
                            : 'Ксенос • доктрины Ордо недоступны для этого класса',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    if (g.playerClass == PlayerClass.malleus || g.playerClass == PlayerClass.hereticus)
                      Card(
                        color: g.playerClass == PlayerClass.malleus ? const Color(0xFF211638) : const Color(0xFF351717),
                        child: ListTile(
                          leading: Icon(g.playerClass == PlayerClass.malleus ? Icons.auto_awesome : Icons.gavel, color: g.playerClass == PlayerClass.malleus ? const Color(0xFFB388FF) : const Color(0xFFFF5252)),
                          title: Text(g.playerClass == PlayerClass.malleus ? 'АКТИВНАЯ СПОСОБНОСТЬ: ЭКЗОРЦИЗМ' : 'АКТИВНАЯ СПОСОБНОСТЬ: ПРИГОВОР', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(g.playerClass == PlayerClass.malleus ? 'Кнопка O в бою • импульс радиусом 190 • повышенный урон демонам • защита на 4 с • перезарядка 13 с.' : 'Кнопка O в бою • поражает ближайшую цель до 360 • повышенный урон культистам и псайкерам • замедление • перезарядка 11 с.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ),
                    ...ordo.ordoSkillCatalog
                      .where((skill) => skill.ordo == (g.playerClass == PlayerClass.malleus ? weapon_catalog.WeaponOrdo.malleus : g.playerClass == PlayerClass.hereticus ? weapon_catalog.WeaponOrdo.hereticus : weapon_catalog.WeaponOrdo.xenos))
                      .map((skill) {
                        final doctrine = g.expansionSystems.ordoDoctrine;
                        final unlocked = doctrine.has(skill.id);
                        final prerequisites = switch (skill.id) {
                          ordo.OrdoSkill.wardingSeal => <ordo.OrdoSkill>[],
                          ordo.OrdoSkill.daemonology => <ordo.OrdoSkill>[ordo.OrdoSkill.wardingSeal],
                          ordo.OrdoSkill.banishment => <ordo.OrdoSkill>[ordo.OrdoSkill.daemonology],
                          ordo.OrdoSkill.witchHunter => <ordo.OrdoSkill>[],
                          ordo.OrdoSkill.nullRounds => <ordo.OrdoSkill>[ordo.OrdoSkill.witchHunter],
                          ordo.OrdoSkill.interrogator => <ordo.OrdoSkill>[ordo.OrdoSkill.nullRounds],
                        };
                        final prereqMet = prerequisites.every(doctrine.has);
                        final canUnlock = !unlocked && prereqMet && g.skillPoints >= skill.cost;
                        return Card(
                          color: const Color(0xFF171717),
                          child: ListTile(
                            title: Text(skill.nameRu, style: TextStyle(color: unlocked ? const Color(0xFF81C784) : Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('${skill.description}\n${unlocked ? 'РАЗБЛОКИРОВАНО' : prereqMet ? 'Стоимость: ${skill.cost} SP' : 'Требуется предыдущий навык в ветке'}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            isThreeLine: true,
                            trailing: unlocked ? const Icon(Icons.check_circle, color: Color(0xFF81C784)) : ElevatedButton(
                              onPressed: canUnlock ? () => setState(() { g.playClick(); g.unlockOrdoSkill(skill.id); }) : null,
                              child: const Text('ОТКРЫТЬ'),
                            ),
                          ),
                        );
                      }),
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
    final m = g.mastery;
    final lo = g.loadout;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text('РЮКЗАК', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
              Text('${g.playerName} • ${g.playerClass.title}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              if (g.activeSynergyLabel != null)
                Text(g.activeSynergyLabel!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 12)),
              const SizedBox(height: 8),
              const Text('Мастерство', style: TextStyle(color: Color(0xFFFFD700))),
              _m('Болтер', m.getCount('bolter'), '50 → +снаряд'),
              _m('Посох', m.getCount('staff'), '40 → +радиус'),
              _m('Меч', m.getCount('sword'), '40 → +5%'),
              _m('Катана', m.getCount('katana'), '40 → +5%'),
              const SizedBox(height: 6),
              const Text('Активные моды', style: TextStyle(color: Color(0xFFFFD700))),
              if (g.playerClass == PlayerClass.xenos)
                Text('Ствол: ${lo.gunBarrel.name} • Прицел: ${lo.gunSight.name} • Боезапас: ${lo.gunAmmo.name}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              if (g.playerClass == PlayerClass.malleus)
                Text('Фокус: ${lo.staffFocus.name}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              if (g.playerClass == PlayerClass.hereticus)
                Text('Клинок: ${lo.bladeEdge.name}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 8),
              const Text('КУЗНЯ БРОНИ • ПРОЦЕДУРНЫЕ КЕРАМИТНЫЕ КОМПЛЕКТЫ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              Text('Надето: ${g.activeArmor.labelRu} • снижение входящего урона ${(g.armorDamageReduction * 100).round()}% • реквизиция ${g.requisition}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Wrap(spacing: 5, runSpacing: 5, children: ArmorPattern.values.map((a) => OutlinedButton(
                onPressed: () { final ok = g.purchaseArmorAtForge(a); setState(() {}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Экипировано: ${a.labelRu}' : 'Недостаточно реквизиции: нужно ${a.price}'))); },
                child: Text('${g.ownedArmor.contains(a) ? 'НАДЕТЬ' : 'КУПИТЬ'} ${a.labelRu} • ${a.price}', style: const TextStyle(fontSize: 10)),
              )).toList()),
              const Text('ПОЛЕВОЙ ИНВЕНТАРЬ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              Text('Вместимость: ${g.fieldInventory.length}/${g.backpackCapacity} • Улучшение: ${g.backpackUpgradeLevel}/3', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(g.activeOrdoContract, style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 11)),
              const Text('ДОСЬЕ УГРОЗ • КОДЕКС ИНКВИЗИЦИИ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Профиль угрозы: ${g.factionForEnemy(EnemyType.orkBoy).labelRu} — ${g.factionForEnemy(EnemyType.orkBoy).tacticalNote} ${g.factionForEnemy(EnemyType.tyranidGaunt).labelRu} — ${g.factionForEnemy(EnemyType.tyranidGaunt).tacticalNote} ${g.factionForEnemy(EnemyType.necronWarrior).labelRu} — ${g.factionForEnemy(EnemyType.necronWarrior).tacticalNote} ${g.factionForEnemy(EnemyType.bloodletter).labelRu} — ${g.factionForEnemy(EnemyType.bloodletter).tacticalNote}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Text('Карта: ${g.activeMapLayout.name} • Терминалы: ${g.terminalsActivated} • Тайники: ${g.supplyCachesOpened}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Wrap(spacing: 6, runSpacing: 6, children: [
                OutlinedButton(onPressed: g.isPlaying ? () => setState(() => g.useFieldConsumable(TacticalConsumable.fragGrenade)) : null, child: Text('Граната (${g.consumables[TacticalConsumable.fragGrenade] ?? 0})')),
                OutlinedButton(onPressed: g.isPlaying ? () => setState(() => g.useFieldConsumable(TacticalConsumable.stim)) : null, child: Text('Стим (${g.consumables[TacticalConsumable.stim] ?? 0})')),
                OutlinedButton(onPressed: g.isPlaying ? () => setState(() => g.useFieldConsumable(TacticalConsumable.smoke)) : null, child: Text('Дым (${g.consumables[TacticalConsumable.smoke] ?? 0})')),
                OutlinedButton(onPressed: g.isPlaying ? () => setState(() => g.useFieldConsumable(TacticalConsumable.auspexPulse)) : null, child: Text('Ауспекс (${g.consumables[TacticalConsumable.auspexPulse] ?? 0})')),
              ]),
              if (g.fieldInventory.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...g.fieldInventory.toList().map((item) => Card(
                  color: const Color(0xFF15191D),
                  child: ListTile(dense: true, leading: Icon(Icons.inventory_2, color: item.rarity.color),
                    title: Text(item.name, style: TextStyle(color: item.rarity.color, fontSize: 12)),
                    subtitle: Text('${item.rarity.labelRu} • этаж ${item.floorFound} • ${item.kind.name}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    trailing: Wrap(children: [IconButton(tooltip: 'Создать предмет экипировки', icon: const Icon(Icons.auto_fix_high, color: Colors.purpleAccent), onPressed: () { final ok = g.forgeGearFromLoot(item); setState(() {}); if (!ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не хватает места или предмет уже использован'))); }), IconButton(tooltip: 'В экипировку', icon: const Icon(Icons.shield, color: Colors.lightBlueAccent), onPressed: () => setState(() => g.moveInventoryItem(item, InventoryLocation.equipment))), IconButton(tooltip: 'В хранилище', icon: const Icon(Icons.inventory, color: Colors.amber), onPressed: () => setState(() => g.moveInventoryItem(item, InventoryLocation.vault))), IconButton(tooltip: 'Разобрать', icon: const Icon(Icons.build, color: Colors.orangeAccent), onPressed: () => setState(() => g.salvageFieldItem(item)))]),
                  ),
                )),
              ] else const Text('Пока ничего не найдено. Ищи контейнеры и предметы на этажах.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Wrap(spacing: 6, children: [
                OutlinedButton(onPressed: (!g.isPlaying || g.isPaused) ? () async { g.upgradeBackpack(); setState(() {}); } : null, child: Text('Расширить рюкзак (${25 + g.backpackUpgradeLevel * 20} рекв.)')),
                OutlinedButton(onPressed: g.isPlaying ? () => setState(() => g.activateFieldTerminal()) : null, child: const Text('Использовать терминал')),
              ]),
              const Divider(color: Colors.white24),
              const Text('ЭКИПИРОВКА И УЛУЧШЕНИЯ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              Text('Осколки: ${g.equipmentInventory.state.shards} • Бонусы: здоровье +${g.equipmentInventory.totalModifiers['health']?.floor() ?? 0}, урон +${(((g.equipmentInventory.totalModifiers['damage'] ?? 0)+(g.equipmentInventory.totalModifiers['rangedDamage'] ?? 0))*100).round()}%, защита +${((g.equipmentInventory.totalModifiers['defense'] ?? 0)*100).round()}%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ...gear_catalog.gearSetCatalog.map((set) => Card(
                color: const Color(0xFF15191D),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.shield_moon, color: (g.equipmentInventory.equippedSetCounts[set.id] ?? 0) >= set.piecesForFull ? Colors.amber : (g.equipmentInventory.equippedSetCounts[set.id] ?? 0) >= set.piecesForTwo ? Colors.lightBlueAccent : Colors.white38),
                  title: Text('${set.name} • ${g.equipmentInventory.equippedSetCounts[set.id] ?? 0} предмет(а)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text(set.description, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  trailing: Text((g.equipmentInventory.equippedSetCounts[set.id] ?? 0) >= set.piecesForFull ? 'ПОЛНЫЙ' : (g.equipmentInventory.equippedSetCounts[set.id] ?? 0) >= set.piecesForTwo ? '2/4+' : '${g.equipmentInventory.equippedSetCounts[set.id] ?? 0}/${set.piecesForFull}', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                ),
              )),
              if (g.equipmentInventory.state.backpack.isEmpty && g.equipmentInventory.state.equipped.isEmpty && g.equipmentInventory.state.vault.isEmpty)
                OutlinedButton.icon(onPressed: () { g.grantStarterGear(); setState(() {}); }, icon: const Icon(Icons.shield), label: const Text('Получить стартовый комплект')),
              if (g.equipmentInventory.state.equipped.isNotEmpty) ...[
                const Text('НАДЕТО', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ...g.equipmentInventory.state.equipped.values.map((item) => ListTile(
                  dense: true,
                  leading: Icon(Icons.verified, color: item.rarity >= 3 ? Colors.amber : Colors.lightBlueAccent),
                  title: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text('${item.slot} • мощность ${item.power} • редкость ${item.rarity + 1}/5', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  trailing: IconButton(
                    tooltip: 'Улучшить', icon: const Icon(Icons.upgrade, color: Colors.amber),
                    onPressed: item.rarity >= 4 || g.equipmentInventory.state.shards < 2 + item.rarity * 2 + item.power ~/ 5 ? null : () {
                      final ok = g.upgradeGear(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Снаряжение улучшено' : 'Не удалось улучшить предмет')));
                      setState(() {});
                    },
                  ),
                )),
              ],
              if (g.equipmentInventory.state.backpack.isNotEmpty) ...[
                const Text('В РЮКЗАКЕ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                ...g.equipmentInventory.state.backpack.map((item) => Card(
                  color: const Color(0xFF15191D),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.shield_outlined, color: item.rarity >= 3 ? Colors.amber : Colors.white70),
                    title: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    subtitle: Text('${item.slot} • мощность ${item.power} • редкость ${item.rarity + 1}/5 • ${item.modifiers.entries.map((e) => '${e.key} +${(e.value * 100).round()}%').join(', ')}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(tooltip: 'Надеть', icon: const Icon(Icons.check_circle, color: Colors.lightBlueAccent), onPressed: () => setState(() => g.equipGear(item.id))),
                      IconButton(tooltip: 'Улучшить', icon: const Icon(Icons.upgrade, color: Colors.amber), onPressed: item.rarity >= 4 || g.equipmentInventory.state.shards < 2 + item.rarity * 2 + item.power ~/ 5 ? null : () => setState(() => g.upgradeGear(item.id))),
                      IconButton(tooltip: 'Разобрать', icon: const Icon(Icons.build, color: Colors.orangeAccent), onPressed: () => setState(() => g.dismantleGear(item.id))),
                    ]),
                  ),
                )),
              ],
              if (g.equipmentInventory.state.vault.isNotEmpty) ...[
                const Text('ХРАНИЛИЩЕ СНАРЯЖЕНИЯ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                ...g.equipmentInventory.state.vault.map((item) => ListTile(
                  dense: true,
                  title: Text(item.name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  subtitle: Text('${item.slot} • мощность ${item.power}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  trailing: TextButton(onPressed: () => setState(() => g.equipmentInventory.state.toBackpack(item)), child: const Text('Вернуть')),
                )),
              ],
              const Text('МОДУЛЬНАЯ СБОРКА ОРУЖИЯ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              Text('Урон ×${g.modularWeapon.damageMultiplier.toStringAsFixed(2)} • Темп ×${g.modularWeapon.rateMultiplier.toStringAsFixed(2)} • Точность ×${g.modularWeapon.precisionMultiplier.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Wrap(spacing: 4, runSpacing: 4, children: [
                OutlinedButton(onPressed: () => setState(() => g.cycleModularWeaponPart('receiver')), child: Text('Корпус: ${g.modularWeapon.receiver}')),
                OutlinedButton(onPressed: () => setState(() => g.cycleModularWeaponPart('barrel')), child: Text('Ствол: ${g.modularWeapon.barrel}')),
                OutlinedButton(onPressed: () => setState(() => g.cycleModularWeaponPart('sight')), child: Text('Прицел: ${g.modularWeapon.sight}')),
                OutlinedButton(onPressed: () => setState(() => g.cycleModularWeaponPart('feed')), child: Text('Подача: ${g.modularWeapon.feed}')),
                OutlinedButton(onPressed: () => setState(() => g.cycleModularWeaponPart('underbarrel')), child: Text('Подствольник: ${g.modularWeapon.underbarrel}')),
                OutlinedButton(onPressed: () => setState(() => g.cycleModularWeaponPart('core')), child: Text('Ядро: ${g.modularWeapon.core}')),
              ]),
              const SizedBox(height: 8),
              const Text('РАЗВЕДКА И ПОСЛЕДСТВИЯ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              Text('Биом: ${g.activeBiomeLabel} • помещения: ${g.activeRoomSet}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Text('Стабильность Варпа: ${g.warpStability.round()}% • сохранено улик: ${g.campaign.evidencePreserved} • уничтожено: ${g.campaign.evidenceDestroyed} • долг информатора: ${g.campaign.informantDebt}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Text(g.campaign.lastReport, style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 11)),
              Wrap(spacing: 4, runSpacing: 4, children: [
                OutlinedButton(onPressed: () async { await g.resolveFieldDecision(InvestigationDecision.preserveEvidence); setState(() {}); }, child: const Text('Сохранить улики')),
                OutlinedButton(onPressed: () async { await g.resolveFieldDecision(InvestigationDecision.destroyEvidence); setState(() {}); }, child: const Text('Уничтожить улики')),
                OutlinedButton(onPressed: () async { await g.resolveFieldDecision(InvestigationDecision.bargainWithInformant); setState(() {}); }, child: const Text('Сделка с информатором')),
              ]),
              if (g.storedItems.isNotEmpty) ...[
                const Text('ХРАНИЛИЩЕ / ЭКИПИРОВКА', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                ...g.storedItems.map((entry) => ListTile(dense: true, title: Text(entry.item.name, style: const TextStyle(color: Colors.white70, fontSize: 11)), subtitle: Text(entry.location.name, style: const TextStyle(color: Colors.white38, fontSize: 10)), trailing: Wrap(children: [IconButton(tooltip: 'В экипировку', icon: const Icon(Icons.shield, color: Colors.lightBlueAccent), onPressed: () => setState(() => g.moveInventoryItem(entry.item, InventoryLocation.equipment))), IconButton(tooltip: 'В хранилище', icon: const Icon(Icons.inventory, color: Colors.amber), onPressed: () => setState(() => g.moveInventoryItem(entry.item, InventoryLocation.vault))), IconButton(tooltip: 'В рюкзак', icon: const Icon(Icons.backpack, color: Colors.greenAccent), onPressed: () => setState(() => g.moveInventoryItem(entry.item, InventoryLocation.backpack))) ]))),
              ],
              const Text('Тактические модули', style: TextStyle(color: Color(0xFFFFD700))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: List.generate(3, (i) => TextButton.icon(onPressed: () => setState(() => g.cycleTacticalMod(i)), icon: const Icon(Icons.tune, size: 16), label: Text('Слот ${i + 1}: ${i < g.tacticalMods.length ? g.tacticalMods[i] : 'пусто'}'), style: TextButton.styleFrom(foregroundColor: const Color(0xFF80CBC4))))),
              const Text('Эвакуация (вне боя)', style: TextStyle(color: Color(0xFFFFD700))),
              Wrap(spacing: 5, children: [
                OutlinedButton(onPressed: () { g.chooseEvacuationRoute(0); setState(() {}); }, child: Text(g.evacuationRoute == 0 ? '✓ Безопасная' : 'Безопасная')),
                OutlinedButton(onPressed: () { g.chooseEvacuationRoute(1); setState(() {}); }, child: Text(g.evacuationRoute == 1 ? '✓ Быстрая' : 'Быстрая')),
                OutlinedButton(onPressed: () { g.chooseEvacuationRoute(2); setState(() {}); }, child: Text(g.evacuationRoute == 2 ? '✓ Скрытная' : 'Скрытная')),
              ]),
              if (g.relics.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Text('Реликвии', style: TextStyle(color: Color(0xFFFFD700))),
                ...g.relics.map((r) => Text('• ${r.title}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
              const SizedBox(height: 8),
              const Text('Дальний', style: TextStyle(color: Color(0xFFFFD700))),
              Wrap(spacing: 6, runSpacing: 6, children: _ranged()),
              const Text('Ближний', style: TextStyle(color: Color(0xFFFFD700))),
              Wrap(spacing: 6, runSpacing: 6, children: _melee()),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: g.closeBackpack, child: const Text('ЗАКРЫТЬ')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _m(String name, int k, String hint) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text('$name: $k', style: const TextStyle(color: Colors.white70, fontSize: 12))),
            Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      );

  List<Widget> _ranged() {
    final g = widget.game;
    final list = <Widget>[];
    void add(String n, RangedWeapon w, bool u) {
      final sel = !g.usingMelee && g.rangedWeapon == w;
      list.add(ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: sel ? const Color(0xFFB8860B) : const Color(0xFF2A2A2A),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: u
            ? () => setState(() {
                  g.rangedWeapon = w;
                  g.usingMelee = false;
                  g.recomputeStats();
                })
            : null,
        child: Text(u ? n : '🔒$n', style: const TextStyle(fontSize: 12)),
      ));
    }
    switch (g.playerClass) {
      case PlayerClass.xenos:
        add('Болтер', RangedWeapon.bolter, true);
        add('Винтовка', RangedWeapon.rifle, g.unlockedRifle);
        add('Дробовик', RangedWeapon.shotgun, g.unlockedShotgun);
        add('Мельтаган', RangedWeapon.meltaGun, g.currentFloor >= 3 || g._everReached11);
        add('Огнемёт', RangedWeapon.flamer, g.currentFloor >= 4 || g.overallLevel >= 21);
        add('Тяжёлый болтер', RangedWeapon.heavyBolter, g.currentFloor >= 5 || g.overallLevel >= 31);
        break;
      case PlayerClass.malleus:
        add('Посох', RangedWeapon.staff, true);
        add('Шторм', RangedWeapon.stormStaff, g.unlockedStormStaff);
        add('Варп', RangedWeapon.warpBeam, g.unlockedWarpBeam);
        add('Психопушка', RangedWeapon.psycannon, g.currentFloor >= 2 || g.overallLevel >= 11);
        add('Экзорцистский инцинератор', RangedWeapon.exorcistIncinerator, g.currentFloor >= 4 || g.overallLevel >= 21);
        add('Пистолет «Губитель демонов»', RangedWeapon.daemonbanePistol, g.currentFloor >= 5 || g.overallLevel >= 26);
        break;
      case PlayerClass.hereticus:
        add('Кинжалы', RangedWeapon.daggers, true);
        add('Иглы', RangedWeapon.needles, g.unlockedNeedles);
        add('Снайпер', RangedWeapon.sniperNeedle, g.unlockedSniperNeedle);
        add('Осудительный болтер', RangedWeapon.condemnorBoltgun, g.currentFloor >= 2 || g.overallLevel >= 11);
        add('Арбалет кольев', RangedWeapon.sanctifiedStakeCrossbow, g.currentFloor >= 4 || g.overallLevel >= 21);
        add('Инферно-пистолет', RangedWeapon.infernoPistol, g.currentFloor >= 5 || g.overallLevel >= 26);
        break;
    }
    return list;
  }

  List<Widget> _melee() {
    final g = widget.game;
    final list = <Widget>[];
    void add(String n, MeleeWeapon w, bool u) {
      final sel = g.usingMelee && g.meleeWeapon == w;
      list.add(ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: sel ? const Color(0xFFB8860B) : const Color(0xFF2A2A2A),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: u
            ? () => setState(() {
                  g.meleeWeapon = w;
                  g.usingMelee = true;
                  g.recomputeStats();
                })
            : null,
        child: Text(u ? n : '🔒$n', style: const TextStyle(fontSize: 12)),
      ));
    }
    switch (g.playerClass) {
      case PlayerClass.xenos:
        add('Меч', MeleeWeapon.sword, true);
        add('Топор', MeleeWeapon.axe, g.unlockedAxe);
        add('Молот', MeleeWeapon.hammer, g.unlockedHammer);
        break;
      case PlayerClass.malleus:
        add('Лезвие', MeleeWeapon.forceBlade, true);
        add('Силовой', MeleeWeapon.forceSword, g.unlockedForceSword);
        add('Демон', MeleeWeapon.daemonHammer, g.unlockedDaemonHammer);
        break;
      case PlayerClass.hereticus:
        add('Катана', MeleeWeapon.katana, true);
        add('Пауэр', MeleeWeapon.powerKatana, g.unlockedPowerKatana);
        add('Палач', MeleeWeapon.executioner, g.unlockedExecutioner);
        break;
    }
    return list;
  }
}

class CampaignChronicleMenu extends StatelessWidget {
  final InquisitorGame game;
  const CampaignChronicleMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF090909),
    appBar: AppBar(backgroundColor: const Color(0xFF211A14), title: const Text('ХРОНИКА КАМПАНИИ', style: TextStyle(color: Color(0xFFFFD700))), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { game.playClick(); game.overlays.remove('chronicle'); })),
    body: game.campaignChronicle.isEmpty
      ? const Center(child: Text('Записей пока нет. События расследования и открытия Кодекса появятся здесь.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
      : ListView.builder(itemCount: game.campaignChronicle.length, itemBuilder: (_, i) => Card(color: const Color(0xFF171717), child: ListTile(leading: const Icon(Icons.menu_book, color: Color(0xFFFFD700)), title: Text(game.campaignChronicle[i], style: const TextStyle(color: Colors.white70, fontSize: 13))))),
  );
}

class CodexMenu extends StatelessWidget {
  final InquisitorGame game;
  const CodexMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text('КОДЕКС ИНКВИЗИЦИИ', textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Text('${game.codexUnlocked.length} / ${CodexId.values.length}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > constraints.maxHeight * 1.25;
            return ListView(padding: const EdgeInsets.only(bottom: 8), children: [
              Align(alignment: Alignment.center, child: TextButton.icon(
                onPressed: () { game.playClick(); game.overlays.add('chronicle'); },
                icon: const Icon(Icons.menu_book, color: Color(0xFFFFD700)),
                label: const Text('Хроника событий кампании', style: TextStyle(color: Color(0xFFFFD700))),
              )),
              if (wide) ...[
                const WeaponCatalogPanel(), const WorldCodexPanel(),
              ] else ...[
                const WeaponCatalogPanel(), const WorldCodexPanel(),
              ],
              const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text('ДОПОЛНИТЕЛЬНЫЕ ДОСЬЕ УГРОЗ', style: TextStyle(color: Color(0xFFBCAAA4), fontSize: 11, letterSpacing: 1.4))),
              const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Орочьи бойцы: штурмовые налёты и грубая броня.\nТиранидские гаунты: быстрые прыжки, когти и хитиновый панцирь.\nНекронские воины: металлические пластины и дисциплинированный дальний огонь.\nПсайкеры культа: варп-атаки и давление на дистанции.\nНосители чумы: тяжёлый шаг, заражение и высокая живучесть.', style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.35))),
              ...CodexId.values.map((id) {
                final open = game.codexUnlocked.contains(id);
                final rank = game.loreRankOf(id);
                return Card(color: const Color(0xFF1A1A1A), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ExpansionTile(
                    title: Text(open ? id.title : '???', style: TextStyle(color: open ? const Color(0xFFFFD700) : Colors.white38)),
                    subtitle: open ? Text('${id.knowledgeBonus} • знание $rank/2', style: TextStyle(color: rank > 0 ? Colors.greenAccent : Colors.white54, fontSize: 11)) : null,
                    children: open ? [
                      Padding(padding: const EdgeInsets.all(12), child: Text(id.lore, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35))),
                      if (rank < 2) TextButton(onPressed: () { game.playClick(); game.acceptLore(id, fromPopup: false); }, child: Text(rank == 0 ? 'Принять знание' : 'Углубить (1 SP)')),
                    ] : [const Padding(padding: EdgeInsets.all(12), child: Text('Убейте цель, чтобы открыть.', style: TextStyle(color: Colors.white38)))],
                  ));
              }),
            ]);
          })),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: SizedBox(width: double.infinity,
            child: ElevatedButton(onPressed: () { game.playClick(); game.closeCodex(); }, child: const Text('НАЗАД')))),
        ]),
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
              TextField(
                controller: c,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Имя...', hintStyle: TextStyle(color: Colors.white38)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _d(Difficulty.easy, Colors.green, '5 эт.'),
                  const SizedBox(width: 8),
                  _d(Difficulty.normal, const Color(0xFFB8860B), '7 эт.'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _d(Difficulty.hard, Colors.redAccent, '10 эт.'),
                  const SizedBox(width: 8),
                  _d(Difficulty.hell, const Color(0xFF6A1B9A), '13 эт. ×3'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => widget.game.confirmName(c.text, diff),
                child: const Text('ДАЛЕЕ — ИСПЫТАНИЕ'),
              ),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: sel ? color : const Color(0xFF1A1A1A),
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
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


class InquisitionHubMenu extends StatefulWidget {
  final InquisitorGame game;
  const InquisitionHubMenu(this.game, {super.key});
  @override
  State<InquisitionHubMenu> createState() => _InquisitionHubMenuState();
}

class _InquisitionHubMenuState extends State<InquisitionHubMenu> {
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final inRun = g.isPlaying;
    return Scaffold(
      backgroundColor: const Color(0xF20A090C),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('БАЗА ИНКВИЗИЦИИ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Реквизиция: ${g.requisition} • Порча Варпа: ${g.warpCorruption}% • ${g.inquisitionAlignment == 'radical' ? 'Радикалы' : 'Пуритане'}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            const Text('ОТДЕЛЫ БАЗЫ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            _upgradeTile('Арсенал', 'Уровень ${g.arsenalUpgrade}/5 • +5 стартовых обломков за уровень', 'arsenal', g.arsenalUpgrade, inRun),
            _upgradeTile('Святилище', 'Уровень ${g.shrineUpgrade}/5 • лечение в начале забега', 'shrine', g.shrineUpgrade, inRun),
            _upgradeTile('Архив дознаний', 'Уровень ${g.archiveUpgrade}/5 • дополнительные очки навыка', 'archive', g.archiveUpgrade, inRun),
            _upgradeTile('Медикаэ', 'Уровень ${g.medicaeUpgrade}/5 • дополнительный максимум здоровья', 'medicae', g.medicaeUpgrade, inRun),
            Card(color: const Color(0xFF171717), child: ListTile(
              title: const Text('Сервочереп-разведчик', style: TextStyle(color: Colors.white)),
              subtitle: Text('Уровень ${g.servoSkullLevel}/3 • каждый уровень усиливает автоматическую поддержку. Стоимость следующего: ${(g.servoSkullLevel + 1) * 45} реквизиции.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: inRun || g.servoSkullLevel >= 3 || g.requisition < (g.servoSkullLevel + 1) * 45 ? null : () async {
                  final cost = (g.servoSkullLevel + 1) * 45;
                  g.requisition -= cost; g.servoSkullLevel++; await g.persistExpansion(); if (mounted) setState(() {});
                },
                child: const Text('УЛУЧШИТЬ'),
              ),
            )),
            const Divider(color: Colors.white24),
            const Text('СПЕЦИАЛИЗАЦИЯ ОРДО', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _choice('Сбалансированная', 'balanced', g.specialization),
              _choice('Каратель', 'executioner', g.specialization),
              _choice('Страж', 'sentinel', g.specialization),
              _choice('Экзорцист', 'exorcist', g.specialization),
              _choice('Провидец', 'seer', g.specialization),
              _choice('Ассасин', 'assassin', g.specialization),
              _choice('Дуэлянт', 'duelist', g.specialization),
            ]),
            const SizedBox(height: 12),
            const Text('ТАКТИЧЕСКАЯ ДОКТРИНА', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            Wrap(spacing: 6, runSpacing: 6, children: CombatDoctrine.values.map((d) => ChoiceChip(
              label: Text(d.labelRu, style: const TextStyle(fontSize: 11)), selected: g.combatDoctrine == d,
              onSelected: inRun ? null : (_) async { g.combatDoctrine = d; g.recomputeStats(); await g.persistExpansion(); if (mounted) setState(() {}); },
            )).toList()),
            const SizedBox(height: 12),
            const Text('ЛЕГЕНДАРНОЕ ОРУЖИЕ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            const Text('Выбери реликтовую настройку. Бонус урона действует на все оружие; это мета-прогрессия, не замена существующим модам.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _choice('Без реликвии', 'none', g.legendaryWeapon),
              _choice('Гнев Императора', 'emperor', g.legendaryWeapon),
              _choice('Освящённый арсенал', 'sanctified', g.legendaryWeapon),
              _choice('Клинок палача', 'executionerBlade', g.legendaryWeapon),
              _choice('Варп-резонатор', 'warp', g.legendaryWeapon),
            ]),
            Card(color: const Color(0xFF171717), child: ListTile(
              title: Text('Пробуждение реликвии ${g.legendaryWeaponRank}/3', style: const TextStyle(color: Colors.white)),
              subtitle: Text(g.legendaryWeapon == 'none' ? 'Сначала выбери легендарное оружие.' : 'Каждый ранг даёт +4% урона. Стоимость: ${(g.legendaryWeaponRank + 1) * 80} реквизиции.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: inRun || g.legendaryWeapon == 'none' || g.legendaryWeaponRank >= 3 || g.requisition < (g.legendaryWeaponRank + 1) * 80 ? null : () async {
                  final cost = (g.legendaryWeaponRank + 1) * 80;
                  g.requisition -= cost; g.legendaryWeaponRank++; g.recomputeStats(); await g.persistExpansion(); if (mounted) setState(() {});
                },
                child: const Text('ПРОБУДИТЬ'),
              ),
            )),
            const Divider(color: Colors.white24),
            const Text('ДОЗНАНИЕ: КСЕНО-АРТЕФАКТ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            Text(g.artifactInvestigationResolved ? 'Артефакт уже исследован. Решение сохранено между забегами.' : 'Пуританский путь: уничтожить артефакт — снизить порчу и получить постоянное очко навыка. Радикальный путь: изучить его — получить реквизицию и рискнуть разумом.', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: inRun || g.artifactInvestigationResolved ? null : () async { await g.resolveInvestigation(false); if (mounted) setState(() {}); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF37474F)), child: const Text('УНИЧТОЖИТЬ'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: inRun || g.artifactInvestigationResolved ? null : () async { await g.resolveInvestigation(true); if (mounted) setState(() {}); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)), child: const Text('ИЗУЧИТЬ'))),
            ]),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: inRun || g.warpCorruption == 0 ? null : () { g.purifyCorruption(); setState(() {}); }, child: const Text('ОЧИСТИТЬ ВАРП (15)'))),
              Expanded(child: Text('Дознаний: ${g.investigationsResolved}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12))),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async {
              await g.persistExpansion();
              await g.persistCustomization();
              g.overlays.remove('inquisitionHub');
              if (inRun) { g.isPaused = false; } else { g.overlays.add('mainMenu'); }
            }, child: Text(inRun ? 'ВЕРНУТЬСЯ В БОЙ' : 'НАЗАД В МЕНЮ')),
          ],
        ),
      ),
    );
  }

  Widget _upgradeTile(String title, String subtitle, String key, int level, bool inRun) {
    final g = widget.game;
    final cost = 35 * (level + 1);
    return Card(
      color: const Color(0xFF19171B),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('$subtitle\nСледующий уровень: $cost обломков', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        isThreeLine: true,
        trailing: IconButton(icon: Icon(level >= 5 ? Icons.check_circle : Icons.upgrade, color: level >= 5 ? Colors.greenAccent : const Color(0xFFFFD700)), onPressed: inRun || level >= 5 ? null : () { g.upgradeBase(key); setState(() {}); }),
      ),
    );
  }

  Widget _choice(String label, String value, String selected) => ChoiceChip(
    label: Text(label, style: const TextStyle(fontSize: 11)),
    selected: value == selected,
    selectedColor: const Color(0xFF8D6E63),
    backgroundColor: const Color(0xFF252329),
    labelStyle: TextStyle(color: value == selected ? Colors.white : Colors.white70),
    onSelected: (on) { if (!on || widget.game.isPlaying) return; setState(() { if (['balanced','executioner','sentinel','exorcist','seer','assassin','duelist'].contains(value)) widget.game.selectSpecialization(value); else widget.game.selectLegendaryWeapon(value); }); },
  );
}

class AchievementsMenu extends StatefulWidget {
  final InquisitorGame game;
  const AchievementsMenu(this.game, {super.key});
  @override
  State<AchievementsMenu> createState() => _AchievementsMenuState();
}

class _AchievementsMenuState extends State<AchievementsMenu> {
  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final wins = g.inquisitionRank.wins;
    final achievements = <_AchievementEntry>[
      _AchievementEntry('Первое досье', 'Открыть хотя бы одну запись Кодекса.', Icons.menu_book, g.unlockedAchievementIds.contains('first_codex') || g.codexUnlocked.isNotEmpty, 'ЗНАНИЕ'),
      _AchievementEntry('Охотник за реликвиями', 'Получить первую реликвию.', Icons.auto_awesome, g.unlockedAchievementIds.contains('first_relic') || g.relics.isNotEmpty, 'РЕЛИКВИЯ'),
      _AchievementEntry('Полевой специалист', 'Найти или сохранить предмет в полевом инвентаре.', Icons.backpack, g.unlockedAchievementIds.contains('field_specialist') || g.fieldInventory.isNotEmpty, 'СНАБЖЕНИЕ'),
      _AchievementEntry('Мастер оружия', 'Достичь 10 отметок мастерства хотя бы с одним типом оружия.', Icons.gps_fixed, ['bolter','staff','sword','katana'].any((k) => g.mastery.getCount(k) >= 10), 'МАСТЕРСТВО'),
      _AchievementEntry('Инквизиторский чин', 'Одержать первую победу в операции.', Icons.military_tech, g.unlockedAchievementIds.contains('career_first_operation') || wins >= 1, 'СЛУЖБА'),
      _AchievementEntry('Ветеран крестового похода', 'Одержать 10 побед.', Icons.shield, g.unlockedAchievementIds.contains('career_ten_operations') || g.careerOperationsCompleted >= 10, 'СЛУЖБА'),
      _AchievementEntry('Глубокое проникновение', 'Достичь третьего этажа операции.', Icons.stairs, g.unlockedAchievementIds.contains('floor_three') || g.careerFloorsReached >= 3 || g.currentFloor >= 3, 'ИССЛЕДОВАНИЕ'),
      _AchievementEntry('Архивариус', 'Открыть пять записей Кодекса.', Icons.library_books, g.codexUnlocked.length >= 5, 'ЗНАНИЕ'),
      _AchievementEntry('Реликварий', 'Собрать три разные реликвии.', Icons.workspace_premium, g.relics.length >= 3, 'РЕЛИКВИЯ'),
      _AchievementEntry('Служитель трёх Ордо', 'Испытать все три доктрины персонажа.', Icons.account_balance, g.inquisitionRank.rank >= 3, 'ДОКТРИНА'),
      _AchievementEntry('Операция повышенной угрозы', 'Завершить операцию повышенной угрозы.', Icons.warning_amber, g.unlockedAchievementIds.contains('career_high_threat_completed'), 'ИСПЫТАНИЕ'),
      _AchievementEntry('Кузнец арсенала', 'Накопить 100 обломков.', Icons.build, g.scraps >= 100, 'АРСЕНАЛ'),
      _AchievementEntry('Голос снабжения', 'Активировать полевой терминал.', Icons.terminal, g.terminalsActivated >= 1, 'ОПЕРАЦИЯ'),
      _AchievementEntry('Снабженец', 'Открыть три тайника снабжения.', Icons.inventory_2, g.supplyCachesOpened >= 3, 'ОПЕРАЦИЯ'),
      _AchievementEntry('Контракт исполнен', 'Завершить первый тактический контракт.', Icons.assignment_turned_in, g.contractsCompleted >= 1, 'СЛУЖБА'),
      _AchievementEntry('Контрактор', 'Завершить пять тактических контрактов.', Icons.fact_check, g.contractsCompleted >= 5, 'СЛУЖБА'),
      _AchievementEntry('Следопыт глубин', 'Добраться до пятого этажа операции.', Icons.travel_explore, g.unlockedAchievementIds.contains('career_floor_five') || g.careerFloorsReached >= 5 || g.currentFloor >= 5, 'ИССЛЕДОВАНИЕ'),
      _AchievementEntry('Охотник на секреты', 'Победить секретного босса.', Icons.visibility, g.secretBossesDefeatedTotal >= 1, 'ИСПЫТАНИЕ'),
      _AchievementEntry('Арена очищена', 'Устранить 100 противников на арене.', Icons.sports_martial_arts, g.unlockedAchievementIds.contains('career_hundred_kills') || g.arenaKills >= 100, 'ИСПЫТАНИЕ'),
      _AchievementEntry('Тактический арсенал', 'Установить три тактических модификации.', Icons.tune, g.tacticalMods.length >= 3, 'АРСЕНАЛ'),
      _AchievementEntry('Проверка на прочность', 'Начать операцию повышенной угрозы.', Icons.warning, g.highThreatOperation && g.operationThreatLevel >= 1, 'ИСПЫТАНИЕ'),
      _AchievementEntry('Свидетель Варпа', 'Достичь 50 очков варп-порчи.', Icons.blur_on, g.warpCorruption >= 50, 'РИСК'),
      _AchievementEntry('Полный рюкзак', 'Увеличить вместимость рюкзака до 24 ячеек.', Icons.backpack, g.backpackCapacity >= 24, 'СНАБЖЕНИЕ'),
    ];
    final unlocked = achievements.where((a) => a.unlocked).length;
    return Scaffold(
      backgroundColor: const Color(0xFF07090C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11161B),
        foregroundColor: const Color(0xFFFFD700),
        title: const Text('ДОСТИЖЕНИЯ ИНКВИЗИЦИИ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { g.playClick(); g.overlays.remove('achievements'); g.overlays.add('mainMenu'); }),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF121B23), Color(0xFF050607)])),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Column(children: [
            const Icon(Icons.workspace_premium, size: 42, color: Color(0xFFFFD700)),
            const SizedBox(height: 6),
            Text('ПРОТОКОЛ ЗАСЛУГ: $unlocked / ${achievements.length}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: unlocked / achievements.length, minHeight: 7, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(Color(0xFFB8860B)))),
            const SizedBox(height: 6),
            const Text('Карьерные заслуги сохраняются между операциями. Существующие сохранения не сбрасываются.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
          Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12, 4, 12, 18), itemCount: achievements.length, itemBuilder: (context, index) {
            final a = achievements[index];
            final color = a.unlocked ? const Color(0xFFFFD700) : const Color(0xFF59616A);
            return Card(
              color: a.unlocked ? const Color(0xFF1B1B16) : const Color(0xFF101317),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: a.unlocked ? const Color(0xFF8D7424) : const Color(0xFF293039))),
              child: ListTile(
                leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(0.10), border: Border.all(color: color.withOpacity(0.7)), borderRadius: BorderRadius.circular(6)), child: Icon(a.unlocked ? a.icon : Icons.lock, color: color)),
                title: Text(a.title, style: TextStyle(color: a.unlocked ? Colors.white : Colors.white60, fontWeight: FontWeight.bold)),
                subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text('${a.description}\n${a.category}', style: TextStyle(color: a.unlocked ? Colors.white70 : Colors.white38, fontSize: 11, height: 1.35))),
                isThreeLine: true,
                trailing: Icon(a.unlocked ? Icons.verified : Icons.lock_outline, color: color, size: 20),
              ),
            );
          })),
          SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { g.playClick(); g.overlays.remove('achievements'); g.overlays.add('mainMenu'); }, icon: const Icon(Icons.arrow_back), label: const Text('ВЕРНУТЬСЯ В ГЛАВНОЕ МЕНЮ'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFD700), side: const BorderSide(color: Color(0xFF8D7424))))))),
        ]),
      ),
    );
  }
}

class _AchievementEntry {
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final String category;
  const _AchievementEntry(this.title, this.description, this.icon, this.unlocked, this.category);
}

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
    // Обновляем только данные фонового эффекта. CustomPainter подписан на
    // AnimationController и перерисовывается без перестроения всего меню.
    _controller.addListener(() {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.game.inquisitionRank;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MP(symbols, repaint: _controller))),
          LayoutBuilder(builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: landscape ? 8 : 18, horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                const Text(
                  'SOUL OF THE\nINQUISITOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 32, fontWeight: FontWeight.w900, height: 1.15, shadows: [Shadow(color: Colors.redAccent, blurRadius: 14)]),
                ),
                const Text('by Инквизитор Данте', style: TextStyle(color: Color(0xFFB8860B), fontSize: 14)),
                if (rank.rank > 0)
                  Text('${rank.title} • побед ${rank.wins}', style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 12)),
                const SizedBox(height: 24),
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
                _btn('БАЗА ИНКВИЗИЦИИ', () {
                  widget.game.playClick();
                  widget.game.openInquisitionHub();
                }),
                const SizedBox(height: 8),
                _btn('КОДЕКС', () {
                  widget.game.playClick();
                  widget.game.openCodex();
                }),
                const SizedBox(height: 8),
                _btn('ДОСТИЖЕНИЯ', () {
                  widget.game.playClick();
                  widget.game.overlays.remove('mainMenu');
                  widget.game.overlays.add('achievements');
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
              ),
            );
          }),
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
  _MP(this.symbols, {super.repaint});
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

class LoadSaveMenu extends StatefulWidget {
  final InquisitorGame game;
  const LoadSaveMenu(this.game, {super.key});

  @override
  State<LoadSaveMenu> createState() => _LoadSaveMenuState();
}

class _LoadSaveMenuState extends State<LoadSaveMenu> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('ЗАГРУЗИТЬ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold))),
            Expanded(
              child: game.saves.isEmpty
                  ? const Center(child: Text('Нет сохранений', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: game.saves.length,
                      itemBuilder: (_, i) {
                        final save = game.saves[i];
                        return Card(
                          color: const Color(0xFF1A1A1A),
                          child: ListTile(
                            title: Text(save.name, style: const TextStyle(color: Color(0xFFFFD700))),
                            subtitle: Text('${save.playerClass} • F${save.floor}/${save.difficulty} • ${save.dateStr}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            onTap: _busy ? null : () {
                              game.playClick();
                              game.loadSave(save);
                            },
                            trailing: IconButton(
                              tooltip: 'Удалить сохранение',
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                              onPressed: _busy ? null : () => _confirmDelete(save),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (game.saves.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Сохранений: ${game.saves.length}/8. Удаление не затрагивает рекорды и постоянные улучшения.', style: const TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
              ),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('loadSave');
                game.overlays.add('mainMenu');
              },
              child: const Text('НАЗАД'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(GameSave save) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text('Удалить сохранение?', style: TextStyle(color: Color(0xFFFFD700))),
        content: Text('Будет удалён забег «${save.name}» (этаж ${save.floor}, уровень ${save.level}). Это действие нельзя отменить.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('ОТМЕНА')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('УДАЛИТЬ', style: TextStyle(color: Color(0xFFFF5252)))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await widget.game.deleteSave(save);
    if (mounted) setState(() => _busy = false);
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
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('НАСТРОЙКИ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
            Text('Джойстик ${g.joystickSize.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.joystickSize, min: 55, max: 120, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.joystickSize = v)),
            Text('Кнопки ${g.buttonSize.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.buttonSize, min: 28, max: 65, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.buttonSize = v)),
            const Divider(color: Colors.white24),
            const Text('РАСКЛАДКА УПРАВЛЕНИЯ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            const Text('Положение джойстиков и ряда способностей сохраняется для следующих матчей.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text('Движение: отступ слева ${g.moveJoystickLeft.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.moveJoystickLeft, min: 0, max: 180, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() => g.moveJoystickLeft = v); g.applyControlLayout(); }, onChangeEnd: (_) => g.persistControlLayout()),
            Text('Движение: отступ снизу ${g.moveJoystickBottom.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.moveJoystickBottom, min: 0, max: 180, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() => g.moveJoystickBottom = v); g.applyControlLayout(); }, onChangeEnd: (_) => g.persistControlLayout()),
            Text('Стрельба: отступ справа ${g.attackJoystickRight.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.attackJoystickRight, min: 0, max: 180, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() => g.attackJoystickRight = v); g.applyControlLayout(); }, onChangeEnd: (_) => g.persistControlLayout()),
            Text('Стрельба: отступ снизу ${g.attackJoystickBottom.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.attackJoystickBottom, min: 0, max: 180, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() => g.attackJoystickBottom = v); g.applyControlLayout(); }, onChangeEnd: (_) => g.persistControlLayout()),
            Text('Способности: отступ слева ${g.abilityClusterLeft.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.abilityClusterLeft, min: 0, max: 160, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() => g.abilityClusterLeft = v); g.applyControlLayout(); }, onChangeEnd: (_) => g.persistControlLayout()),
            Text('Способности: высота ${g.abilityClusterBottom.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.abilityClusterBottom, min: 100, max: 320, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() => g.abilityClusterBottom = v); g.applyControlLayout(); }, onChangeEnd: (_) => g.persistControlLayout()),
            Text('Смена оружия: отступ справа ${g.weaponButtonRight.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.weaponButtonRight, min: 0, max: 180, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() => g.weaponButtonRight = v); g.applyControlLayout(); }, onChangeEnd: (_) => g.persistControlLayout()),
            Text('Смена оружия: высота ${g.weaponButtonBottom.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.weaponButtonBottom, min: 100, max: 320, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() => g.weaponButtonBottom = v); g.applyControlLayout(); }, onChangeEnd: (_) => g.persistControlLayout()),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () { setState(() { g.moveJoystickLeft = 52; g.moveJoystickBottom = 52; g.attackJoystickRight = 52; g.attackJoystickBottom = 52; g.abilityClusterLeft = 32; g.abilityClusterBottom = 160; g.weaponButtonRight = 52; g.weaponButtonBottom = 160; }); g.applyControlLayout(); g.persistControlLayout(); }, child: const Text('СБРОСИТЬ РАСКЛАДКУ'))),
            SwitchListTile(title: const Text('Звуки', style: TextStyle(color: Colors.white)), value: g.soundEnabled, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.soundEnabled = v)),
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
                      setState(() {
                        g.musicVolume = v;
                        g._bgmPlayer?.setVolume(v);
                      });
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
                  setState(() => _saveMsg = 'OK');
                },
                child: const Text('СОХРАНИТЬ'),
              ),
              if (_saveMsg != null) Text(_saveMsg!, style: const TextStyle(color: Colors.greenAccent)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                onPressed: () {
                  g.playClick();
                  g.exitMatch();
                },
                child: const Text('ВЫХОД'),
              ),
            ],
            const Divider(color: Colors.white24),
            const Divider(color: Colors.white24),
            const Text('ИНКВИЗИТОРСКОЕ ДОСЬЕ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            Text('Операции: ${g.campaign.operationsCompleted} • Улики: ${g.campaign.cluesFound} • Подозрение: ${g.campaign.suspicion}% • Ранения: ${g.campaign.fieldWounds}/3', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(g.campaign.lastReport, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            SwitchListTile(title: const Text('Операция повышенной угрозы', style: TextStyle(color: Colors.white)), subtitle: Text('Больше элитных угроз и редких тайников; награды выше.', style: TextStyle(color: Colors.white54)), value: g.highThreatOperation, onChanged: g.isPlaying ? null : (v) { setState(() { g.highThreatOperation = v; g.operationThreatLevel = v ? 2 : 0; }); g.persistExpansion(); }),
            DropdownButtonFormField<String>(
              value: g.campaign.missionApproach,
              dropdownColor: const Color(0xFF171717),
              decoration: const InputDecoration(labelText: 'Подход к операции', labelStyle: TextStyle(color: Colors.white70)),
              items: const [
                DropdownMenuItem(value: 'balanced', child: Text('Сбалансированный', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'investigate', child: Text('Сначала разведка: больше улик, выше тревога', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'purge', child: Text('Немедленная зачистка: меньше подозрений', style: TextStyle(color: Colors.white))),
              ],
              onChanged: g.isPlaying ? null : (v) { if (v == null) return; setState(() => g.campaign.missionApproach = v); g.persistExpansion(); },
            ),
            ElevatedButton(onPressed: (!g.isPlaying && g.requisition >= 10 && g.campaign.fieldWounds > 0) ? () { setState(() { g.requisition -= 10; g.campaign.fieldWounds = 0; g.recomputeStats(); }); g.persistExpansion(); } : null, child: const Text('МЕДИЦИНСКАЯ СТАБИЛИЗАЦИЯ — 10 РЕКВИЗИЦИИ')),
            const SizedBox(height: 8),
            const Text('БОЕВАЯ ДОКТРИНА', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            DropdownButtonFormField<CombatDoctrine>(
              value: g.combatDoctrine,
              dropdownColor: const Color(0xFF171717),
              decoration: const InputDecoration(labelText: 'Тактическая подготовка', labelStyle: TextStyle(color: Colors.white70)),
              items: CombatDoctrine.values.map((d) => DropdownMenuItem(value: d, child: Text('${d.labelRu} — ${d.descriptionRu}', style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
              onChanged: g.isPlaying ? null : (v) { if (v == null) return; setState(() { g.combatDoctrine = v; g.recomputeStats(); }); g.persistExpansion(); },
            ),
            DropdownButtonFormField<AmmoDoctrine>(
              value: g.ammoDoctrine,
              dropdownColor: const Color(0xFF171717),
              decoration: const InputDecoration(labelText: 'Боеприпасы Deathwatch', labelStyle: TextStyle(color: Colors.white70)),
              items: AmmoDoctrine.values.map((a) => DropdownMenuItem(value: a, child: Text(a.labelRu, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: g.isPlaying ? null : (v) { if (v == null) return; setState(() => g.ammoDoctrine = v); g.persistExpansion(); },
            ),
            DropdownButtonFormField<ArenaModifier>(
              value: g.arenaModifier,
              dropdownColor: const Color(0xFF171717),
              decoration: const InputDecoration(labelText: 'Модификатор бесконечной арены', labelStyle: TextStyle(color: Colors.white70)),
              items: ArenaModifier.values.map((a) => DropdownMenuItem(value: a, child: Text(a.labelRu, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: g.isPlaying ? null : (v) { if (v == null) return; setState(() => g.arenaModifier = v); g.persistExpansion(); },
            ),
            ListTile(
              title: const Text('Сервочереп-разведчик', style: TextStyle(color: Colors.white)),
              subtitle: Text('Уровень ${g.servoSkullLevel}/3 • автоматические выстрелы по ближайшим врагам. Улучшается за реквизицию на базе Инквизиции.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: Text('${g.servoSkullLevel}/3', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Colors.white24),
            SwitchListTile(
              title: const Text('Показывать секретные сигналы', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Подсказки не раскрывают условия полностью.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: g.showSecretSignals,
              activeColor: const Color(0xFFFFD700),
              onChanged: (v) { setState(() => g.showSecretSignals = v); g.persistExpansion(); },
            ),
            if (g.showSecretSignals)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(color: const Color(0xFF101411), border: Border.all(color: const Color(0xFF536B50)), borderRadius: BorderRadius.circular(6)),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('1-5 left top 33s', style: TextStyle(color: Color(0xFF9DBB91), fontFamily: 'monospace', fontSize: 14, letterSpacing: 1.0)),
                  SizedBox(height: 5),
                  Text('2-5 left top 33s', style: TextStyle(color: Color(0xFF9DBB91), fontFamily: 'monospace', fontSize: 14, letterSpacing: 1.0)),
                ]),
              ),
            const SizedBox(height: 8),
            Text('Секретные боссы побеждены: ${g.secretBossesDefeatedTotal} • Тактические достижения: ${g.tacticalAchievements}', style: const TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: () {
                g.playClick();
                if (g.isPlaying) {
                  g.closeSettings();
                } else {
                  g.persistCustomization();
                  g.backToMenu();
                }
              },
              child: Text(g.isPlaying ? 'В БОЙ' : 'НАЗАД'),
            ),
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
            Text('Очки ${game.score} • Обломки ${game.scraps}', style: const TextStyle(color: Colors.white)),
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
            Text('${game.playerName} • ${game.difficulty.labelRu} (${game.maxFloors} эт.)', style: const TextStyle(color: Colors.white)),
            Text(game.inquisitionRank.title, style: const TextStyle(color: Color(0xFF81D4FA))),
            if (game.activeChallenge != RankChallenge.none)
              Text(
                game.challengeBossMeleeOk || game.activeChallenge == RankChallenge.noDash ? 'Испытание выполнено (+ранг)' : 'Испытание провалено',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            const SizedBox(height: 12),
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
            Text('Этаж ${game.currentFloor}/${game.maxFloors}', style: const TextStyle(color: Colors.white54)),
            ElevatedButton(onPressed: game.openNameInput, child: const Text('СНОВА')),
            ElevatedButton(onPressed: game.backToMenu, child: const Text('МЕНЮ')),
          ],
        ),
      ),
    );
  }
}
class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent moveJoystick;
  late int health;
  late int maxHealth;
  double attackTimer = 0;
  double hurtFlash = 0;
  bool emperorAegisSpent = false;
  double shadowStrideSurge = 0;
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
    if (shadowStrideSurge > 0) s *= 1.22;
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
        final wardedCorruption = e.type == StatusType.corruption &&
            game.equipmentInventory.containsUniquePower('warp_ward');
        if (e.tickDamage > 0 && !wardedCorruption &&
            (e.type == StatusType.burn ||
                e.type == StatusType.bleed ||
                e.type == StatusType.corruption ||
                e.type == StatusType.plague)) {
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
      return;
    }
    game.showGameOver();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (shadowStrideSurge > 0) shadowStrideSurge = max(0, shadowStrideSurge - dt);
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
    // Melee never affected by heat/warp
    if (game.usingMelee) {
      final base = (game.meleeWeapon == MeleeWeapon.hammer || game.meleeWeapon == MeleeWeapon.daemonHammer) ? 0.78 : 0.42;
      final weighted = game.loadout.bladeEdge == BladeEdgeMod.weighted ? 1.08 : 1.0;
      return base * weighted * game.attackSpeedMult / game.modularWeapon.rateMultiplier;
    }
    final base = switch (game.rangedWeapon) {
      RangedWeapon.bolter => 0.28 + (game.playerClass == PlayerClass.xenos ? game.bolterHeat * 0.35 : 0),
      RangedWeapon.rifle => 0.55,
      // Plasma has a deliberate charge/recovery cadence to offset its piercing explosive shot.
      RangedWeapon.plasmaGun => 0.82,
      RangedWeapon.shotgun => 0.72,
      RangedWeapon.staff => 0.48 + game.staffWarpStress * 0.25,
      RangedWeapon.stormStaff => 0.55 + game.staffWarpStress * 0.3,
      RangedWeapon.warpBeam => 0.70,
      RangedWeapon.daggers => 0.22,
      RangedWeapon.needles => 0.32,
      RangedWeapon.sniperNeedle => 0.85,
      RangedWeapon.meltaGun => 1.05,
      RangedWeapon.flamer => 0.12,
      RangedWeapon.heavyBolter => 0.20,
      RangedWeapon.psycannon => 0.68,
      RangedWeapon.exorcistIncinerator => 0.18,
      RangedWeapon.daemonbanePistol => 0.48,
      RangedWeapon.condemnorBoltgun => 0.72,
      RangedWeapon.sanctifiedStakeCrossbow => 0.82,
      RangedWeapon.infernoPistol => 0.95,
    };
    return base * game.attackSpeedMult / game.modularWeapon.rateMultiplier;
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
      // Overheat: bolter only for Xenos guns
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
      // Warp stress: staff only
      if (game.playerClass == PlayerClass.malleus &&
          (game.rangedWeapon == RangedWeapon.staff ||
              game.rangedWeapon == RangedWeapon.stormStaff ||
              game.rangedWeapon == RangedWeapon.warpBeam ||
              game.rangedWeapon == RangedWeapon.psycannon ||
              game.rangedWeapon == RangedWeapon.daemonbanePistol)) {
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
        final extra = game.mastery.bolterExtraShots(
          1,
          ammoSavant: game.hasAmmoSavant,
          xenosSynergy: game.synergyXenosMastery,
        );
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
      case RangedWeapon.plasmaGun:
        game.world.add(Bullet(
          position: origin.clone(), direction: dir,
          damage: game.scaleDamage((game.rifleDamage * 1.75).round()),
          color: const Color(0xFF80D8FF), speed: 430, radius: 8,
          pierce: true, explosive: true, applyBurn: true,
          damageType: CombatDamageType.plasma, armorPenetration: 0.45,
        )..priority = 13);
        break;
      case RangedWeapon.shotgun:
        final n = game.loadout.gunSight == GunSightMod.wide ? 5 : 3;
        final spread = game.loadout.gunSight == GunSightMod.wide ? 0.32 : 0.22;
        for (int i = 0; i < n; i++) {
          final a = atan2(dir.y, dir.x) + (i - (n - 1) / 2) * spread;
          _bullet(origin, Vector2(cos(a), sin(a)), game.shotgunDamage, const Color(0xFFFFAB40), 480, 5);
        }
        if (game.synergyXenosBlast) {
          for (int i = 0; i < 5; i++) {
            final a = atan2(dir.y, dir.x) + (i - 2) * 0.28;
            final d = Vector2(cos(a), sin(a));
            game.world.add(Bullet(
              position: origin.clone(),
              direction: d,
              damage: game.scaleDamage((game.shotgunDamage * 0.6).round()),
              color: const Color(0xFFFF6D00),
              speed: 400,
              radius: 7,
              explosive: true,
              applyBurn: true,
            )..priority = 13);
          }
        }
        break;
      case RangedWeapon.meltaGun:
        // Short-range anti-armour weapon: slow, heavy projectile with strong penetration.
        game.world.add(Bullet(
          position: origin.clone(), direction: dir,
          damage: game.scaleDamage((game.shotgunDamage * 4.2).round()),
          color: const Color(0xFFFF7043), speed: 330, radius: 10,
          pierce: true, explosive: true,
          damageType: CombatDamageType.plasma, armorPenetration: 0.72,
        )..priority = 13);
        break;
      case RangedWeapon.flamer:
        // A short cone of burning projectiles; visually distinct and useful against swarms.
        for (int i = 0; i < 7; i++) {
          final a = atan2(dir.y, dir.x) + (i - 3) * 0.105;
          game.world.add(Bullet(
            position: origin.clone(), direction: Vector2(cos(a), sin(a)),
            damage: game.scaleDamage(max(2, (game.bolterDamage * 0.42).round())),
            color: i.isEven ? const Color(0xFFFF6D00) : const Color(0xFFFFD54F),
            speed: 260 + (i % 3) * 18, radius: 5.5,
            applyBurn: true, damageType: CombatDamageType.flame,
          )..priority = 13);
        }
        break;
      case RangedWeapon.heavyBolter:
        // Three-round burst with modest spread, high sustained damage and recoil cadence.
        for (int i = 0; i < 3; i++) {
          final a = atan2(dir.y, dir.x) + (i - 1) * 0.035;
          _bullet(origin, Vector2(cos(a), sin(a)), (game.bolterDamage * 0.82).round(),
              const Color(0xFFFFB74D), 470, 6.5);
        }
        break;
      case RangedWeapon.psycannon:
        game.world.add(Bullet(position: origin.clone(), direction: dir,
          damage: game.scaleDamage((game.rifleDamage * 1.55).round()),
          color: const Color(0xFFB388FF), speed: 660, radius: 7,
          pierce: true, damageType: CombatDamageType.warp, armorPenetration: 0.38)..priority = 13);
        break;
      case RangedWeapon.exorcistIncinerator:
        for (int i = 0; i < 5; i++) {
          final a = atan2(dir.y, dir.x) + (i - 2) * 0.12;
          game.world.add(Bullet(position: origin.clone(), direction: Vector2(cos(a), sin(a)),
            damage: game.scaleDamage(max(2, (game.bolterDamage * 0.68).round())),
            color: i.isEven ? const Color(0xFFFF7043) : const Color(0xFFFFD180),
            speed: 300, radius: 6, applyBurn: true, damageType: CombatDamageType.flame)..priority = 13);
        }
        break;
      case RangedWeapon.daemonbanePistol:
        game.world.add(Bullet(position: origin.clone(), direction: dir,
          damage: game.scaleDamage((game.rifleDamage * 1.35).round()),
          color: const Color(0xFFCE93D8), speed: 560, radius: 5,
          pierce: true, damageType: CombatDamageType.warp, armorPenetration: 0.28)..priority = 13);
        break;
      case RangedWeapon.condemnorBoltgun:
        game.world.add(Bullet(position: origin.clone(), direction: dir,
          damage: game.scaleDamage((game.rifleDamage * 1.3).round()),
          color: const Color(0xFFFFD54F), speed: 650, radius: 5.5,
          pierce: true, damageType: CombatDamageType.kinetic, armorPenetration: 0.20)..priority = 13);
        break;
      case RangedWeapon.sanctifiedStakeCrossbow:
        game.world.add(Bullet(position: origin.clone(), direction: dir,
          damage: game.scaleDamage((game.rifleDamage * 1.25).round()),
          color: const Color(0xFF80CBC4), speed: 740, radius: 4,
          pierce: true, damageType: CombatDamageType.kinetic, armorPenetration: 0.32)..priority = 13);
        break;
      case RangedWeapon.infernoPistol:
        game.world.add(Bullet(position: origin.clone(), direction: dir,
          damage: game.scaleDamage((game.shotgunDamage * 3.8).round()),
          color: const Color(0xFFFF5722), speed: 380, radius: 8,
          pierce: true, explosive: true, damageType: CombatDamageType.plasma, armorPenetration: 0.65)..priority = 13);
        break;
      case RangedWeapon.staff:
        final rad = 160.0 * game.staffRadiusMult();
        game.world.add(PsyWave(
          position: origin.clone(),
          direction: dir,
          damage: game.scaleDamage(game.staffDamage),
          maxRadius: rad,
        )..priority = 13);
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
      damageType: switch (game.rangedWeapon) {
        RangedWeapon.plasmaGun => CombatDamageType.plasma,
        RangedWeapon.warpBeam || RangedWeapon.staff || RangedWeapon.stormStaff => CombatDamageType.warp,
        RangedWeapon.daggers || RangedWeapon.needles || RangedWeapon.sniperNeedle || RangedWeapon.heavyBolter || RangedWeapon.condemnorBoltgun || RangedWeapon.sanctifiedStakeCrossbow => CombatDamageType.kinetic,
        RangedWeapon.psycannon || RangedWeapon.daemonbanePistol => CombatDamageType.warp,
        RangedWeapon.exorcistIncinerator => CombatDamageType.flame,
        RangedWeapon.infernoPistol => CombatDamageType.plasma,
        RangedWeapon.flamer => CombatDamageType.flame,
        RangedWeapon.meltaGun => CombatDamageType.plasma,
        RangedWeapon.shotgun => exp ? CombatDamageType.explosive : CombatDamageType.kinetic,
        _ => exp ? CombatDamageType.explosive : CombatDamageType.kinetic,
      },
      armorPenetration: switch (game.rangedWeapon) {
        RangedWeapon.sniperNeedle => 0.30,
        RangedWeapon.plasmaGun => 0.45,
        RangedWeapon.warpBeam => 0.18,
        RangedWeapon.meltaGun => 0.72,
        RangedWeapon.heavyBolter => 0.12,
        RangedWeapon.psycannon => 0.38,
        RangedWeapon.daemonbanePistol => 0.28,
        RangedWeapon.condemnorBoltgun => 0.20,
        RangedWeapon.sanctifiedStakeCrossbow => 0.32,
        RangedWeapon.infernoPistol => 0.65,
        _ => game.ammoDoctrine == AmmoDoctrine.armorPiercing ? 0.25 : 0.0,
      },
    )..priority = 13);
  }

  void takeDamage(int amount) {
    if (game.invulnTimer > 0 || game.dashActive > 0) return;
    if (game.equipmentInventory.containsUniquePower('shadow_stride') && Random().nextDouble() < 0.12) {
      shadowStrideSurge = 1.6;
      game.grantInvuln(0.28);
      game.spawnDamageNumber(position, 0, color: const Color(0xFF80DEEA), label: 'ШАГ ТЕНИ');
      return;
    }
    if (game.shieldTimer > 0) {
      game.shieldTimer = 0;
      return;
    }
    if (game.holyAuraTimer > 0) amount = max(1, (amount * 0.7).round());
    if (game.ordoWardTimer > 0) amount = max(1, (amount * 0.55).round());
    amount = max(1, (amount * (1.0 - game.armorDamageReduction)).round());
    // Warding Seal is a persistent, small mitigation bonus against incoming damage.
    amount = max(1, (amount * game.ordoIncomingDamageMultiplier).round());
    if (game.defenseChance > 0 && Random().nextDouble() < game.defenseChance) {
      game.spawnDamageNumber(position, 0, color: const Color(0xFF90CAF9), label: 'BLOCK');
      return;
    }
    if (health - amount <= 0 && !emperorAegisSpent && game.equipmentInventory.containsUniquePower('unyielding_aegis')) {
      emperorAegisSpent = true;
      health = 1;
      game.grantInvuln(1.5);
      hurtFlash = 0;
      game.spawnDamageNumber(position, 0, color: const Color(0xFFFFD54F), label: 'ЭГИДА ИМПЕРАТОРА');
      game.triggerShake(power: 8, time: 0.2);
      return;
    }
    health = max(0, health - amount);
    if (game.isPlaying && amount >= 2 && health > 0 && health <= maxHealth ~/ 2 && game.campaign.fieldWounds < 3 && Random().nextDouble() < 0.10) {
      game.campaign.fieldWounds++;
      game.recomputeStats();
      game.spawnDamageNumber(position, 0, color: const Color(0xFFFF8A65), label: 'РАНЕНИЕ ${game.campaign.fieldWounds}/3');
      game.persistExpansion();
    }
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

  void _drawProceduralArmor(Canvas canvas, double cx, double cy, ArmorPattern pattern, Color base, Color trim) {
    final dark = Color.lerp(base, Colors.black, .42)!;
    final light = Color.lerp(base, Colors.white, .22)!;
    final plate = Paint()..style = PaintingStyle.fill;
    // Breastplate lamination, rivets and heraldic markings. Pattern changes geometry, not only tint.
    final chest = Path()..moveTo(cx - 16, cy - 9)..lineTo(cx - 20, cy + 7)..lineTo(cx - 12, cy + 20)..lineTo(cx + 12, cy + 20)..lineTo(cx + 20, cy + 7)..lineTo(cx + 16, cy - 9)..lineTo(cx, cy - 15)..close();
    plate.color = pattern == ArmorPattern.terminator ? dark : base;
    canvas.drawPath(chest, plate);
    canvas.drawPath(chest, Paint()..color = trim.withOpacity(.85)..style = PaintingStyle.stroke..strokeWidth = pattern == ArmorPattern.artificer ? 2.4 : 1.2);
    for (final side in [-1.0, 1.0]) {
      final shoulder = Path()..moveTo(cx + side * 13, cy - 11)..quadraticBezierTo(cx + side * 27, cy - 18, cx + side * 28, cy - 2)..lineTo(cx + side * 20, cy + 5)..lineTo(cx + side * 13, cy + 1)..close();
      canvas.drawPath(shoulder, Paint()..color = pattern == ArmorPattern.terminator ? light : dark);
      canvas.drawPath(shoulder, Paint()..color = trim.withOpacity(.8)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      for (int rivet = 0; rivet < (pattern == ArmorPattern.artificer ? 4 : 2); rivet++) {
        canvas.drawCircle(Offset(cx + side * (18 + rivet * 2.0), cy - 6 + rivet * 2.0), 0.9, Paint()..color = trim);
      }
    }
    // Distinct silhouette cues for selected armor patterns.
    if (pattern == ArmorPattern.mk3Iron || pattern == ArmorPattern.terminator) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2), width: 15, height: 8), const Radius.circular(2)), Paint()..color = light);
      canvas.drawLine(Offset(cx - 7, cy + 2), Offset(cx + 7, cy + 2), Paint()..color = trim..strokeWidth = 1.4);
    }
    if (pattern == ArmorPattern.mk6Corvus) {
      final beak = Path()..moveTo(cx - 5, cy - 18)..lineTo(cx + 5, cy - 18)..lineTo(cx + 2, cy - 25)..lineTo(cx - 2, cy - 25)..close();
      canvas.drawPath(beak, Paint()..color = light);
    }
    if (pattern == ArmorPattern.artificer || pattern == ArmorPattern.inquisitorial) {
      canvas.drawCircle(Offset(cx, cy + 3), 5.0, Paint()..color = trim);
      canvas.drawCircle(Offset(cx, cy + 3), 2.2, Paint()..color = dark);
      canvas.drawLine(Offset(cx - 4, cy + 3), Offset(cx + 4, cy + 3), Paint()..color = trim..strokeWidth = 1.0);
    }
    if (pattern == ArmorPattern.voidSealed) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 18), width: 22, height: 6), const Radius.circular(3)), Paint()..color = const Color(0xFF80DEEA).withOpacity(.8));
    }
    if (pattern == ArmorPattern.terminator) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 24), width: 33, height: 8), const Radius.circular(2)), Paint()..color = dark);
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 24), width: 21, height: 2), Paint()..color = trim);
    }
    // Scratches and ceramic edge highlights vary with active pattern for material depth.
    final scratchCount = pattern == ArmorPattern.artificer ? 5 : pattern == ArmorPattern.flak ? 1 : 3;
    for (int i = 0; i < scratchCount; i++) {
      final x = cx - 10 + i * (20 / max(1, scratchCount - 1));
      canvas.drawLine(Offset(x, cy + 8 + (i.isEven ? 0 : 2)), Offset(x + 2, cy + 11 + (i.isEven ? 2 : 0)), Paint()..color = light.withOpacity(.35)..strokeWidth = .8);
    }
  }


  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final ang = atan2(aimDir.y, aimDir.x);
    WHDraw.inquisitor(canvas, cx: cx, cy: cy, s: 1.28, flash: hurtFlash / 0.15, custom: game.custom, cls: game.playerClass, healthRatio: maxHealth <= 0 ? 1 : health / maxHealth);
    _drawProceduralArmor(canvas, cx, cy, game.activeArmor, game.custom.armorColor(0.45), game.custom.trimColor(0.65));
    // Stage 13: equipped items are visibly layered onto the live character, using Canvas only.
    final wornArmor = game.equipmentInventory.state.equipped['armor'];
    final wornBoots = game.equipmentInventory.state.equipped['boots'];
    final wornRelic = game.equipmentInventory.state.equipped['relic'];
    final wornWeapon = game.equipmentInventory.state.equipped['weapon'];
    final setId = wornArmor?.setId ?? wornBoots?.setId ?? wornRelic?.setId ?? wornWeapon?.setId;
    final setTrim = setId == 'deathwatch'
        ? const Color(0xFF80DEEA)
        : setId == 'ordo_malleus'
            ? const Color(0xFFCE93D8)
            : setId == 'inquisitorial'
                ? const Color(0xFFFFD54F)
                : game.custom.trimColor(0.65);
    if (wornArmor != null) {
      // Extra shoulder plates and central item badge make equipped armor distinct from the base pattern.
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 22, cy - 6), width: 15, height: 17), const Radius.circular(4)), Paint()..color = Color.lerp(game.custom.armorColor(0.45), setTrim, .38)!);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 22, cy - 6), width: 15, height: 17), const Radius.circular(4)), Paint()..color = Color.lerp(game.custom.armorColor(0.45), setTrim, .38)!);
      canvas.drawCircle(Offset(cx, cy + 4), wornArmor.rarity >= 4 ? 6.0 : 4.0, Paint()..color = setTrim);
      canvas.drawCircle(Offset(cx, cy + 4), 2.0, Paint()..color = const Color(0xFF211D20));
      if (wornArmor.rarity >= 4) {
        canvas.drawCircle(Offset(cx, cy + 4), 9.0 + sin(game.combatAnimClock * 3).abs() * 1.5, Paint()..color = setTrim.withOpacity(.45)..style = PaintingStyle.stroke..strokeWidth = 1.4);
      }
    }
    if (wornBoots != null) {
      for (final side in [-1.0, 1.0]) {
        final greave = Rect.fromCenter(center: Offset(cx + side * 10, cy + 28), width: 8, height: 10);
        canvas.drawRRect(RRect.fromRectAndRadius(greave, const Radius.circular(2)), Paint()..color = Color.lerp(game.custom.armorColor(0.35), setTrim, .32)!);
        canvas.drawLine(Offset(greave.left + 1, greave.center.dy), Offset(greave.right - 1, greave.center.dy), Paint()..color = setTrim..strokeWidth = 1.2);
      }
    }
    if (wornRelic != null) {
      final relicColor = wornRelic.uniquePower == 'warp_ward' ? const Color(0xFFCE93D8) : setTrim;
      canvas.drawCircle(Offset(cx + 17, cy + 8), 5.0, Paint()..color = relicColor.withOpacity(.9));
      canvas.drawCircle(Offset(cx + 17, cy + 8), 8.0, Paint()..color = relicColor.withOpacity(.35)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }
    // Animated targeting servo and shoulder beacon are vector-only; phase follows game time.
    final servoPhase = sin(game.combatAnimClock * 5.0);
    canvas.drawCircle(Offset(cx + 21, cy - 14 + servoPhase * 1.2), 3.0, Paint()..color = const Color(0xFF80DEEA).withOpacity(0.55 + 0.35 * servoPhase.abs()));
    if (hurtFlash > 0) {
      canvas.drawLine(Offset(cx - 18, cy - 3), Offset(cx + 18, cy + 6), Paint()..color = const Color(0xFFFF5252).withOpacity(hurtFlash * 2)..strokeWidth = 2.0);
    }
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
        case RangedWeapon.plasmaGun:
          WHDraw.bolter(canvas, 0, 0, 1.05, accent: const Color(0xFF80D8FF));
          canvas.drawCircle(const Offset(39, -7), 5, Paint()..color = const Color(0xFF80D8FF));
          canvas.drawCircle(const Offset(39, -7), 8, Paint()..color = const Color(0xFF80D8FF).withOpacity(0.22));
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
        case RangedWeapon.meltaGun:
          WHDraw.bolter(canvas, 0, 0, 1.22, accent: const Color(0xFFFF7043));
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, -14, 19, 13), const Radius.circular(3)), Paint()..color = const Color(0xFF4E342E));
          canvas.drawCircle(const Offset(42, -7), 5, Paint()..color = const Color(0xFFFF7043));
          canvas.drawCircle(const Offset(42, -7), 9, Paint()..color = const Color(0xFFFF7043).withOpacity(0.20));
          break;
        case RangedWeapon.flamer:
          WHDraw.shotgun(canvas, 0, 0, 1.05, accent: const Color(0xFFFF6D00));
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, -18, 16, 10), const Radius.circular(3)), Paint()..color = const Color(0xFF8D4B20));
          canvas.drawCircle(const Offset(38, -7), 5, Paint()..color = const Color(0xFFFFD54F));
          break;
        case RangedWeapon.heavyBolter:
          WHDraw.bolter(canvas, 0, 0, 1.32, accent: const Color(0xFFFFB74D));
          canvas.drawRect(const Rect.fromLTWH(20, 3, 22, 7), Paint()..color = const Color(0xFF5D4037));
          canvas.drawLine(const Offset(43, -7), const Offset(53, -7), Paint()..color = const Color(0xFFFFCC80)..strokeWidth = 4);
          break;
        case RangedWeapon.psycannon:
          WHDraw.bolter(canvas, 0, 0, 1.30, accent: const Color(0xFFB388FF));
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, -18, 25, 12), const Radius.circular(3)), Paint()..color = const Color(0xFF4527A0));
          canvas.drawCircle(const Offset(43, -7), 6, Paint()..color = const Color(0xFFB388FF));
          canvas.drawCircle(const Offset(43, -7), 10, Paint()..color = const Color(0xFFB388FF).withOpacity(.18));
          break;
        case RangedWeapon.exorcistIncinerator:
          WHDraw.shotgun(canvas, 0, 0, 1.18, accent: const Color(0xFFFF7043));
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(13, -19, 20, 12), const Radius.circular(3)), Paint()..color = const Color(0xFF6D3426));
          canvas.drawCircle(const Offset(39, -7), 5, Paint()..color = const Color(0xFFFFD180));
          break;
        case RangedWeapon.daemonbanePistol:
          WHDraw.bolter(canvas, 0, 0, .78, accent: const Color(0xFFCE93D8));
          canvas.drawCircle(const Offset(35, -7), 4, Paint()..color = const Color(0xFFCE93D8));
          break;
        case RangedWeapon.condemnorBoltgun:
          WHDraw.bolter(canvas, 0, 0, 1.12, accent: const Color(0xFFFFD54F));
          canvas.drawLine(const Offset(19, -17), const Offset(42, -17), Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 2);
          break;
        case RangedWeapon.sanctifiedStakeCrossbow:
          WHDraw.rifle(canvas, 0, 0, 1.05, accent: const Color(0xFF80CBC4));
          canvas.drawLine(const Offset(28, -20), const Offset(28, 8), Paint()..color = const Color(0xFF80CBC4)..strokeWidth = 3);
          canvas.drawLine(const Offset(18, -15), const Offset(38, -15), Paint()..color = const Color(0xFF80CBC4)..strokeWidth = 2);
          break;
        case RangedWeapon.infernoPistol:
          WHDraw.bolter(canvas, 0, 0, .90, accent: const Color(0xFFFF5722));
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(19, -16, 16, 11), const Radius.circular(3)), Paint()..color = const Color(0xFF4E342E));
          canvas.drawCircle(const Offset(39, -7), 5, Paint()..color = const Color(0xFFFF5722));
          break;
      }
    }
    // Equipment weapon relic overlays the currently selected weapon, without replacing its geometry.
    if (wornWeapon != null) {
      final relicWeaponColor = wornWeapon.uniquePower == 'executioner_oath' ? const Color(0xFF80DEEA) : setTrim;
      canvas.drawLine(const Offset(18, -15), const Offset(46, -15), Paint()..color = relicWeaponColor.withOpacity(.85)..strokeWidth = 2.0..strokeCap = StrokeCap.round);
      if (wornWeapon.rarity >= 4) {
        for (int rune = 0; rune < 3; rune++) {
          canvas.drawCircle(Offset(22 + rune * 9.0, -20), 1.7, Paint()..color = relicWeaponColor);
        }
      }
    }
    // Legendary weapon evolution: procedural edge-light, runic ticks and rank rings.
    if (game.legendaryWeapon != 'none') {
      final evoColor = game.legendaryWeapon == 'warp'
          ? const Color(0xFFCE93D8)
          : game.legendaryWeapon == 'sanctified' || game.legendaryWeapon == 'emperor'
              ? const Color(0xFFFFD54F)
              : const Color(0xFFFF5252);
      final rank = game.legendaryWeaponRank.clamp(0, 3).toInt();
      canvas.drawLine(Offset(12, -9), Offset(48 + rank * 2.0, -9), Paint()..color = evoColor.withOpacity(0.5 + rank * 0.12)..strokeWidth = 2.0 + rank * 0.55..strokeCap = StrokeCap.round);
      for (int rune = 0; rune < rank + 1; rune++) {
        canvas.drawCircle(Offset(18 + rune * 7.0, 9), 1.4 + rank * 0.25, Paint()..color = evoColor.withOpacity(0.85));
      }
      if (rank >= 2) {
        canvas.drawCircle(Offset(32, 0), 18 + rank * 2.0, Paint()..color = evoColor.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 1.4);
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
    if (game.bolterHeat > 0.05 && !game.usingMelee && game.playerClass == PlayerClass.xenos) {
      canvas.drawRect(
        Rect.fromLTWH(cx - 24, size.y - 4, 48 * game.bolterHeat, 4),
        Paint()..color = Color.lerp(const Color(0xFFFFEB3B), const Color(0xFFFF1744), game.bolterHeat)!,
      );
    }
    if (game.staffWarpStress > 0.05 && !game.usingMelee && game.playerClass == PlayerClass.malleus) {
      canvas.drawRect(Rect.fromLTWH(cx - 24, size.y, 48 * game.staffWarpStress, 4), Paint()..color = const Color(0xFF9C27B0));
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
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius,
      Paint()
        ..color = Color.fromRGBO(124, 77, 255, 0.35 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
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
    canvas.drawRect(Rect.fromLTWH(0, size.y * 0.35, size.x, size.y * 0.3), Paint()..color = Color.fromRGBO(255, 255, 200, 0.6 * a));
  }
}

class Bullet extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 velocity;
  final int damage;
  final Color color;
  final bool pierce, ricochet, explosive, applyBurn;
  final CombatDamageType damageType;
  final double armorPenetration;
  double life = 2.2;
  int bounces = 0;
  final Set<int> hitIds = {};
  Vector2 _prev = Vector2.zero();

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
    this.damageType = CombatDamageType.kinetic,
    this.armorPenetration = 0,
  })  : velocity = direction.normalized() * speed,
        super(position: position.clone(), size: Vector2.all(radius * 2), anchor: Anchor.center, priority: 13);

  @override
  Future<void> onLoad() async {
    _prev = position.clone();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    final old = position.clone();
    position += velocity * dt;
    // Trail
    if (old.distanceTo(position) > 4) {
      game.world.add(BulletTrail(from: old, to: position.clone(), color: color)..priority = 12);
    }
    _prev = position.clone();
    if (life <= 0 || position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) {
      removeFromParent();
    }
  }

  int _adjustBossDamage(Object boss) {
    // Shared typed-damage handling for legacy boss classes that still expose
    // takeDamage(int). The primary Boss class has its own richer handler.
    double armor = 0.12;
    double matchup = 1.0;
    if (boss is KnightBoss || boss is KingBoss || boss is BloodChampionBoss) {
      armor = 0.24;
    } else if (boss is TentacleBoss || boss is CyclopsBoss || boss is PlagueLordBoss) {
      armor = 0.18;
    } else if (boss is MiniBoss) {
      armor = 0.14;
    }
    switch (damageType) {
      case CombatDamageType.plasma:
        matchup = 1.22;
        break;
      case CombatDamageType.explosive:
        matchup = 1.15;
        break;
      case CombatDamageType.warp:
        matchup = (boss is TentacleBoss || boss is CyclopsBoss || boss is PlagueLordBoss) ? 1.25 : 1.0;
        break;
      case CombatDamageType.flame:
        matchup = (boss is PlagueLordBoss) ? 0.82 : 1.05;
        break;
      case CombatDamageType.kinetic:
        matchup = 0.94;
        break;
      case CombatDamageType.melee:
        matchup = 1.0;
        break;
    }
    final effectiveArmor = (armor - armorPenetration).clamp(0.0, 0.8);
    return max(1, (damage * matchup * (1.0 - effectiveArmor)).round());
  }

  void _hitEnemy(Enemy e) {
    if (!hitIds.add(e.hashCode)) return;
    if (e.affix == EliteAffix.reflect && Random().nextDouble() < 0.25) {
      game.world.add(EnemyBullet(position: e.position.clone(), direction: (game.player.position - e.position).normalized(), damage: 1)..priority = 16);
      game.spawnDamageNumber(e.position, 0, color: const Color(0xFFE040FB), label: 'ОТРАЖ');
    }
    final ratio = e.maxHp > 0 ? e.currentHp / e.maxHp : 1.0;
    var dmg = game.hasExecutionerMark && ratio < 0.3 ? (damage * 1.2).round() : damage;
    final ordoMultiplier = game.ordoDamageMultiplierForEnemy(e);
    if (ordoMultiplier > 1.0) dmg = (dmg * ordoMultiplier).round();
    if (game.equipmentInventory.containsUniquePower('executioner_oath') && ratio < 0.35) dmg = (dmg * 1.25).round();
    if (game.equipmentInventory.containsUniquePower('auspex_omniscience') && Random().nextDouble() < 0.10) {
      dmg *= 2;
      game.spawnDamageNumber(e.position, dmg, color: const Color(0xFF80DEEA), label: 'АУСПЕКС • КРИТ');
    }
    e.applyCombatDamage(dmg, damageType: damageType, armorPenetration: armorPenetration);
    if (applyBurn || explosive || damageType == CombatDamageType.flame) e.applyStatus(StatusType.burn, 2.0 + game.codexBurnBonus, tickDamage: 1);
    if (explosive) {
      game.world.add(KillExplosion(position: position.clone(), radius: 55, damage: damage ~/ 3)..priority = 12);
    }
    if (!pierce && !ricochet) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) _hitEnemy(other);
    final impact = intersectionPoints.isNotEmpty ? intersectionPoints.first : position;
    if (other is MiniBoss) {
      final zone = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (_adjustBossDamage(other) * zone.multiplier).round());
      other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -48), dealt, color: zone.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: zone.label);
      if (!pierce) removeFromParent();
    }
    if (other is Boss) {
      final zone = resolveBossHitZone(impact: impact, center: other.position, size: other.size, exposed: other.weakSpotExposed);
      final scaledDamage = max(1, (damage * zone.multiplier).round());
      other.takeCombatDamage(scaledDamage, damageType: damageType, armorPenetration: armorPenetration);
      game.spawnDamageNumber(other.position + Vector2(0, -48), scaledDamage, color: zone.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: zone.label);
      game.noteBossDamagedByRanged();
      if (!pierce) removeFromParent();
    }
    if (other is KnightBoss) {
      final zone = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (_adjustBossDamage(other) * zone.multiplier).round());
      other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -48), dealt, color: zone.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: zone.label);
      game.noteBossDamagedByRanged();
      if (!pierce) removeFromParent();
    }
    if (other is KingBoss) {
      final zone = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (_adjustBossDamage(other) * zone.multiplier).round());
      other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -48), dealt, color: zone.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: zone.label);
      game.noteBossDamagedByRanged();
      if (!pierce) removeFromParent();
    }
    if (other is TentacleBoss) {
      final zone = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (_adjustBossDamage(other) * zone.multiplier).round());
      other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -48), dealt, color: zone.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: zone.label);
      if (!pierce) removeFromParent();
    }
    if (other is CyclopsBoss) {
      final zone = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (_adjustBossDamage(other) * zone.multiplier).round());
      other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -48), dealt, color: zone.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: zone.label);
      if (!pierce) removeFromParent();
    }
    if (other is PlagueLordBoss) {
      final zone = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (_adjustBossDamage(other) * zone.multiplier).round());
      other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -48), dealt, color: zone.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: zone.label);
      if (!pierce) removeFromParent();
    }
    if (other is BloodChampionBoss) {
      final zone = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (_adjustBossDamage(other) * zone.multiplier).round());
      other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -48), dealt, color: zone.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: zone.label);
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
        if (explosive) {
          game.world.add(KillExplosion(position: position.clone(), radius: 50, damage: damage ~/ 3)..priority = 12);
        }
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
      final doctrineDamage = game.ordoDamageMultiplierForEnemy(other);
      other.applyDamage((damage * doctrineDamage).round());
      if (game.synergyHereticusBleedDash || game.loadout.bladeEdge == BladeEdgeMod.serrated) {
        other.applyStatus(StatusType.bleed, 2.5, tickDamage: 1);
      }
    }
    final impact = intersectionPoints.isNotEmpty ? intersectionPoints.first : other.position;
    if (other is MiniBoss && hit.add(other.hashCode)) {
      final z = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (damage * z.multiplier).round()); other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -46), dealt, color: const Color(0xFFFFD54F), label: z.label);
    }
    if (other is Boss && hit.add(other.hashCode)) {
      final z = resolveBossHitZone(impact: impact, center: other.position, size: other.size, exposed: other.weakSpotExposed);
      final dealt = max(1, (damage * z.multiplier).round()); other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -46), dealt, color: z.zone == BossHitZoneKind.core ? const Color(0xFFFF1744) : const Color(0xFFFFD54F), label: z.label);
    }
    if (other is KnightBoss && hit.add(other.hashCode)) {
      final z = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (damage * z.multiplier).round()); other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -46), dealt, color: const Color(0xFFFFD54F), label: z.label);
    }
    if (other is KingBoss && hit.add(other.hashCode)) {
      final z = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (damage * z.multiplier).round()); other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -46), dealt, color: const Color(0xFFFFD54F), label: z.label);
    }
    if (other is TentacleBoss && hit.add(other.hashCode)) {
      final z = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (damage * z.multiplier).round()); other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -46), dealt, color: const Color(0xFFFFD54F), label: z.label);
    }
    if (other is CyclopsBoss && hit.add(other.hashCode)) {
      final z = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (damage * z.multiplier).round()); other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -46), dealt, color: const Color(0xFFFFD54F), label: z.label);
    }
    if (other is PlagueLordBoss && hit.add(other.hashCode)) {
      final z = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (damage * z.multiplier).round()); other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -46), dealt, color: const Color(0xFFFFD54F), label: z.label);
    }
    if (other is BloodChampionBoss && hit.add(other.hashCode)) {
      final z = resolveBossHitZone(impact: impact, center: other.position, size: other.size);
      final dealt = max(1, (damage * z.multiplier).round()); other.takeDamage(dealt);
      game.spawnDamageNumber(other.position + Vector2(0, -46), dealt, color: const Color(0xFFFFD54F), label: z.label);
    }
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
  final StatusType? statusOnHit;
  final double statusDuration;
  double life = 3.5;
  int bounces = 0;
  bool didSplit = false;

  EnemyBullet({
    required Vector2 position,
    required Vector2 direction,
    required this.damage,
    double speed = 180,
    this.mod = BulletMod.normal,
    this.statusOnHit,
    this.statusDuration = 1.4,
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
      if (statusOnHit != null) {
        other.applyStatus(statusOnHit!, statusDuration, tickDamage: statusOnHit == StatusType.corruption ? 1 : 0);
      }
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
      final wasDodging = game.dashActive > 0;
      other.takeDamage((1 * game.difficulty.dmgMult).ceil());
      if (wasDodging) {
        game.spawnDamageNumber(other.position + Vector2(0, -42), 0, color: const Color(0xFF80DEEA), label: 'УКЛОНЕНИЕ');
      }
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
  FlamerCloud({required Vector2 position})
      : super(position: position.clone(), size: Vector2(70, 70), anchor: Anchor.center, priority: 11);
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
class Enemy extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final EnemyType type;
  final bool isChampion;
  final EliteAffix affix;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  double attackWindup = 0;
  // Combat 2.0 stage 4: lock the aim direction when the warning starts,
  // so the player can dodge the announced attack instead of being tracked unfairly.
  Vector2 attackDirection = Vector2(1, 0);
  double hurtFlash = 0;
  double hitReactTimer = 0;
  double animationClock = 0;
  final int visualVariant = Random().nextInt(5);
  double regenTimer = 0;
  bool summonerTriggered = false;
  double suppression = 0;
  int morale = 100;
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
      EnemyType.orkBoy => 48.0,
      EnemyType.tyranidGaunt => 22.0,
      EnemyType.necronWarrior => 52.0,
      EnemyType.genestealer => 44.0,
      EnemyType.chaosSpawn => 92.0,
      EnemyType.necronImmortal => 68.0,
    };
    // Veteran-grade tuning: ordinary hostiles gain roughly two threat steps per difficulty.
    // Boss classes are separate components and are deliberately not modified here.
    final veteranScale = switch (game.difficulty) {
      Difficulty.easy => 1.28,
      Difficulty.normal => 1.42,
      Difficulty.hard => 1.58,
      Difficulty.hell => 1.55,
    };
    // Enemy-only scaling. Bosses are separate components and do not pass through this path.
    final floorScale = 1 + floor * (game.difficulty == Difficulty.hell ? 0.055 : 0.08);
    var hp = base * game.difficulty.hpMult * veteranScale * game.worldThreat * floorScale;
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
      EnemyType.orkBoy => 112.0,
      EnemyType.tyranidGaunt => 178.0,
      EnemyType.necronWarrior => 72.0,
      EnemyType.genestealer => 220.0,
      EnemyType.chaosSpawn => 88.0,
      EnemyType.necronImmortal => 68.0,
    };
    if (isChampion) s *= 1.12;
    if (suppression >= 65) s *= 0.78;
    if (morale <= 0) s *= 0.62;
    if (!game.arenaMode) s *= 1.0 + game.campaign.alarm / 500.0 + (game.campaign.suspicion >= 75 ? 0.04 : 0.0);
    if (game.arenaMode) s *= min(1.8, 1.0 + game.arenaThreatTier * 0.025);
    if (game.arenaMode && game.arenaModifier == ArenaModifier.swift) s *= 1.22;
    if (affix == EliteAffix.swift) s *= 1.35;
    if (game.difficulty == Difficulty.hell) s *= 1.18;
    if (statuses.any((e) => e.type == StatusType.slow || e.type == StatusType.plague)) s *= 0.6;
    return s;
  }

  bool get isShielded => type == EnemyType.shielded || type == EnemyType.shieldedShooter;

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    if (game.combatDoctrine == CombatDoctrine.control && (t == StatusType.slow || t == StatusType.burn || t == StatusType.plague)) dur *= 1.35;
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  /// Applies typed damage before routing through the established damage pipeline.
  /// Armor penetration bypasses a portion of physical protection; faction matchups
  /// reward choosing the right weapon without making any enemy immune.
  void applyCombatDamage(
    int amount, {
    required CombatDamageType damageType,
    double armorPenetration = 0,
  }) {
    if (amount <= 0) return;
    final penetration = armorPenetration.clamp(0.0, 0.85).toDouble();
    var armor = switch (type) {
      EnemyType.shielded || EnemyType.shieldedShooter => 0.28,
      EnemyType.brute || EnemyType.chaosSpawn || EnemyType.plagueBearer => 0.22,
      EnemyType.necronWarrior || EnemyType.necronImmortal => 0.25,
      EnemyType.orkBoy => 0.16,
      EnemyType.genestealer => 0.08,
      _ => 0.04,
    };
    if (isChampion) armor += 0.06;
    var multiplier = 1.0;
    switch (type) {
      case EnemyType.necronWarrior:
      case EnemyType.necronImmortal:
        if (damageType == CombatDamageType.kinetic) multiplier = 0.82;
        if (damageType == CombatDamageType.plasma || damageType == CombatDamageType.explosive) multiplier = 1.18;
        break;
      case EnemyType.orkBoy:
      case EnemyType.brute:
      case EnemyType.chaosSpawn:
        if (damageType == CombatDamageType.kinetic) multiplier = 0.92;
        if (damageType == CombatDamageType.flame || damageType == CombatDamageType.plasma) multiplier = 1.12;
        break;
      case EnemyType.tyranidGaunt:
      case EnemyType.genestealer:
        if (damageType == CombatDamageType.flame) multiplier = 1.30;
        if (damageType == CombatDamageType.explosive) multiplier = 1.12;
        break;
      case EnemyType.bloodletter:
      case EnemyType.plagueBearer:
        if (damageType == CombatDamageType.kinetic) multiplier = 0.84;
        if (damageType == CombatDamageType.warp || damageType == CombatDamageType.plasma) multiplier = 1.18;
        if (damageType == CombatDamageType.flame && type == EnemyType.plagueBearer) multiplier = 1.15;
        break;
      case EnemyType.cultPsyker:
        if (damageType == CombatDamageType.warp) multiplier = 0.82;
        if (damageType == CombatDamageType.kinetic || damageType == CombatDamageType.plasma) multiplier = 1.12;
        break;
      default:
        break;
    }
    final armorFactor = 1.0 - armor * (1.0 - penetration);
    final adjusted = max(1, (amount * armorFactor * multiplier).round());
    applyDamage(adjusted);
  }

  void applyDamage(int amount, {bool fromStatus = false}) {
    if (!fromStatus && amount > 0) {
      if (game.usingMelee) { game.meleePressure = min(10000, game.meleePressure + 1); }
      else { game.rangedPressure = min(10000, game.rangedPressure + 1); }
    }
    var dmg = amount;
    if (!fromStatus) {
      final faction = game.factionForEnemy(type);
      if (faction == InquisitionFaction.daemon && game.warpStability < 25 && game.ammoDoctrine != AmmoDoctrine.antiWarp) dmg = (dmg * 0.88).round();
      if (faction == InquisitionFaction.necron && game.ammoDoctrine == AmmoDoctrine.armorPiercing) dmg = (dmg * 1.12).round();
      if (faction == InquisitionFaction.tyranid && game.ammoDoctrine == AmmoDoctrine.incendiary) dmg = (dmg * 1.12).round();
      if (faction == InquisitionFaction.ork && game.usingMelee) dmg = (dmg * 1.08).round();
      suppression = min(100, suppression + max(5, amount * 0.8));
      if (suppression >= 100) morale = 0;
      else if (suppression >= 65) morale = min(morale, 35);
      if ((type == EnemyType.necronWarrior || type == EnemyType.necronImmortal) && game.ammoDoctrine == AmmoDoctrine.armorPiercing) dmg = (dmg * 1.2).round();
      if (type == EnemyType.orkBoy && game.usingMelee) dmg = (dmg * 1.08).round();
      if ((type == EnemyType.tyranidGaunt || type == EnemyType.genestealer) && game.ammoDoctrine == AmmoDoctrine.incendiary) dmg = (dmg * 1.15).round();
    }
    if (!fromStatus && game.ammoDoctrine == AmmoDoctrine.antiWarp &&
        (type == EnemyType.cultPsyker || type == EnemyType.plagueBearer || type == EnemyType.bloodletter)) {
      dmg = (dmg * 1.25).round();
    }
    if (isShielded && !fromStatus && game.ammoDoctrine != AmmoDoctrine.armorPiercing) {
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
    if (!fromStatus && game.oathAcceptedThisRun) {
      if (game.playerClass == PlayerClass.malleus && (type == EnemyType.bloodletter || type == EnemyType.plagueBearer || type == EnemyType.cultPsyker)) dmg = (dmg * 1.08).round();
      if (game.playerClass == PlayerClass.hereticus && (type == EnemyType.cultPsyker || type == EnemyType.sniper)) dmg = (dmg * 1.08).round();
      if (game.playerClass == PlayerClass.xenos && (isChampion || isShielded || type == EnemyType.brute)) dmg = (dmg * 1.08).round();
    }
    currentHp -= dmg;
    if (!fromStatus && game.ammoDoctrine == AmmoDoctrine.incendiary) applyStatus(StatusType.burn, 2.0, tickDamage: 1);
    if (!fromStatus && game.ammoDoctrine == AmmoDoctrine.suppressive) applyStatus(StatusType.slow, game.combatDoctrine == CombatDoctrine.control ? 2.1 : 1.55, tickDamage: 0);
    hurtFlash = 0.12;
    hitReactTimer = 0.16;
    game.triggerShake(power: min(2.4, 0.65 + amount * 0.025), time: 0.045);
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
      final add = Enemy(floor: floor, type: EnemyType.melee, isChampion: false, affix: EliteAffix.none);
      add.position = pos;
      add.maxHp = max(6, (maxHp * 0.25).round());
      add.currentHp = add.maxHp;
      add.priority = 30;
      game.world.add(add);
    }
    game.spawnDamageNumber(position, 0, color: const Color(0xFFFFEB3B), label: 'ПРИЗЫВ');
  }

  void _die(Vector2 fromDir) {
    game.progressionTrack.grantExperience(isChampion ? 24 : 12);
    game.expansionSystems.progression.grantExperience(isChampion ? 24 : 12);
    game.expansionSystems.contracts.recordKill(elite: isChampion || type == EnemyType.brute || type == EnemyType.necronImmortal);
    game.expansionSystems.campaign.recordKill(type.name);
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
    if (hitReactTimer > 0) hitReactTimer = max(0, hitReactTimer - dt);
    animationClock += dt;
    if (!game.isPlaying || game.isPaused) return;
    _tickStatuses(dt);

    if (affix == EliteAffix.regenerating || type == EnemyType.chaosSpawn) {
      regenTimer += dt;
      if (regenTimer >= 1.2 && currentHp < maxHp) {
        regenTimer = 0;
        currentHp = min(maxHp, currentHp + max(1, maxHp ~/ (type == EnemyType.chaosSpawn ? 45 : 25)));
      }
    }

    final dist = position.distanceTo(game.player.position);
    final kite = type == EnemyType.shooter ||
        type == EnemyType.sniper ||
        type == EnemyType.shieldedShooter ||
        type == EnemyType.cultPsyker ||
        type == EnemyType.necronImmortal;
    final prefer = type == EnemyType.sniper
        ? 320.0
        : type == EnemyType.cultPsyker
            ? 260.0
            : 180.0;
    // Genestealer pounce: short, readable acceleration windows rather than permanent extreme speed.
    final pounce = type == EnemyType.genestealer && (animationClock % 3.8) < 0.62;
    final movementSpeed = pounce ? moveSpeed * 1.28 : moveSpeed;
    smartMove(game.player.position, movementSpeed, dt, radius: 22, kite: kite && dist < prefer + 40, preferDist: prefer);
    pushOutOfWalls(22);

    // Combat 2.0: ordinary enemies telegraph attacks before damage/projectiles resolve.
    // While winding up, the enemy cannot start another attack.
    if (attackWindup > 0) {
      attackWindup = max(0, attackWindup - dt);
      if (attackWindup <= 0) _doAttack(dist);
      return;
    }
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
          EnemyType.orkBoy => 0.82,
          EnemyType.tyranidGaunt => 0.48,
          EnemyType.necronWarrior => 1.05,
          EnemyType.genestealer => 0.42,
          EnemyType.chaosSpawn => 0.92,
          EnemyType.necronImmortal => 1.15,
        } *
        closeBonus /
        (isChampion ? 1.15 : 1.0) /
        (game.difficulty == Difficulty.hell ? 0.88 : 1.0);

    if (attackTimer >= interval) {
      attackTimer = 0;
      attackDirection = (game.player.position - position).normalized();
      attackWindup = _attackWindupDuration;
      if (attackWindup <= 0) _doAttack(dist);
    }
  }

  double get _attackWindupDuration {
    if (type == EnemyType.sniper || type == EnemyType.necronImmortal) return 0.52;
    if (type == EnemyType.brute || type == EnemyType.chaosSpawn || type == EnemyType.plagueBearer) return 0.42;
    if (type == EnemyType.cultPsyker || type == EnemyType.flamer) return 0.38;
    if (type == EnemyType.genestealer || type == EnemyType.dog || type == EnemyType.tyranidGaunt) return 0.20;
    if (type == EnemyType.shooter || type == EnemyType.shieldedShooter || type == EnemyType.necronWarrior) return 0.30;
    return 0.24;
  }

  void _doAttack(double dist) {
    // Use the direction shown during the telegraph. A player who moves sideways
    // during the wind-up can now genuinely evade aimed projectiles and cones.
    final toP = attackDirection.length2 > 0.001
        ? attackDirection.normalized()
        : (game.player.position - position).normalized();
    var incomingMult = game.arenaMode ? (1.0 + game.arenaThreatTier * 0.08) : 1.0;
    if (game.arenaMode && game.arenaModifier == ArenaModifier.unstable) incomingMult *= 1.15;
    final veteranDamage = switch (game.difficulty) {
      Difficulty.easy => 1.10,
      Difficulty.normal => 1.22,
      Difficulty.hard => 1.34,
      Difficulty.hell => 1.28,
    };
    final hellBehavior = game.difficulty == Difficulty.hell ? 1.18 : 1.0;
    final dmg = (1 * game.difficulty.dmgMult * veteranDamage * incomingMult * hellBehavior).ceil();
    switch (type) {
      case EnemyType.shooter:
      case EnemyType.shieldedShooter:
        if (dist < 420) {
          if (isChampion) {
            // Combat 2.0 stage 6: elite shooters use a readable three-round fan.
            // Each round is slightly weaker than a normal shot to keep the burst fair.
            final baseAngle = atan2(toP.y, toP.x);
            for (final offset in [-0.13, 0.0, 0.13]) {
              final angle = baseAngle + offset;
              game.world.add(EnemyBullet(
                position: position.clone(),
                direction: Vector2(cos(angle), sin(angle)),
                damage: max(1, dmg - 1),
                speed: 188,
                mod: game.rollBulletMod(),
              )..priority = 16);
            }
          } else {
            game.world.add(EnemyBullet(
              position: position.clone(),
              direction: toP,
              damage: dmg,
              mod: game.rollBulletMod(),
            )..priority = 16);
          }
        }
        break;
      case EnemyType.necronImmortal:
        if (dist < 460) {
          // Three-shot gauss fan: dangerous, but spread gives the player a dodge lane.
          final baseAngle = atan2(toP.y, toP.x);
          for (final offset in [-0.16, 0.0, 0.16]) {
            final angle = baseAngle + offset;
            game.world.add(EnemyBullet(
              position: position.clone(), direction: Vector2(cos(angle), sin(angle)),
              damage: max(1, dmg - 1), speed: 215, mod: BulletMod.ricochet,
              statusOnHit: StatusType.slow, statusDuration: 0.9,
            )..priority = 16);
          }
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
          if (dist < 90) game.player.takeDamage(dmg);
        }
        break;
      case EnemyType.cultPsyker:
        if (dist < 300) {
          // Warp pulse — slow + damage in cone
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
      case EnemyType.genestealer:
        if (dist < 64) {
          game.player.takeDamage(dmg + 1);
          game.player.applyStatus(StatusType.bleed, 2.2, tickDamage: 1);
          game.triggerShake(power: 2.2, time: 0.07);
        }
        break;
      case EnemyType.chaosSpawn:
        if (dist < 82) {
          game.player.takeDamage(dmg + 1);
          if (Random().nextDouble() < 0.25) game.player.applyStatus(StatusType.corruption, 2.0, tickDamage: 1);
        }
        break;
      case EnemyType.bloodletter:
      case EnemyType.melee:
      case EnemyType.dog:
      case EnemyType.brute:
      case EnemyType.shielded:
      case EnemyType.orkBoy:
      case EnemyType.tyranidGaunt:
      case EnemyType.necronWarrior:
        if (dist < (type == EnemyType.brute ? 70 : 55)) {
          game.player.takeDamage(type == EnemyType.bloodletter || type == EnemyType.brute ? dmg + 1 : dmg);
          if (type == EnemyType.bloodletter) {
            game.player.applyStatus(StatusType.bleed, 1.5, tickDamage: 1);
          } else if (type == EnemyType.tyranidGaunt) {
            // Tyranid claws cause a short, low-intensity bleed.
            game.player.applyStatus(StatusType.bleed, 1.2, tickDamage: 1);
          } else if (type == EnemyType.orkBoy) {
            // Heavy Ork melee has a small shove, making space management matter.
            game.player.position += toP * 14;
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
    if (other is KillExplosion && other.applyBurn) {
      applyDamage(other.damage);
      applyStatus(StatusType.burn, 2.0, tickDamage: 1);
    } else if (other is KillExplosion) {
      applyDamage(other.damage);
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
      case EnemyType.orkBoy:
        WHDraw.brute(canvas, cx, cy, 1.02, flash: f);
        canvas.drawCircle(Offset(cx + 9, cy - 8), 5, Paint()..color = const Color(0xFF4CAF50));
        break;
      case EnemyType.tyranidGaunt:
        WHDraw.chaosHound(canvas, cx, cy, flash: f);
        canvas.drawCircle(Offset(cx - 8, cy - 8), 4, Paint()..color = const Color(0xFF8BC34A));
        break;
      case EnemyType.necronWarrior:
        WHDraw.shieldedMarine(canvas, cx, cy, 1.0, withGun: true, flash: f);
        canvas.drawLine(Offset(cx - 10, cy + 4), Offset(cx + 10, cy + 4), Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 3);
        break;
      case EnemyType.genestealer:
        WHDraw.chaosHound(canvas, cx, cy, flash: f);
        final claw = Paint()..color = const Color(0xFFB39DDB)..strokeWidth = 3..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - 13, cy + 4), Offset(cx - 20, cy + 15), claw);
        canvas.drawLine(Offset(cx + 13, cy + 4), Offset(cx + 20, cy + 15), claw);
        canvas.drawLine(Offset(cx - 20, cy + 15), Offset(cx - 24, cy + 19), claw);
        canvas.drawLine(Offset(cx + 20, cy + 15), Offset(cx + 24, cy + 19), claw);
        canvas.drawCircle(Offset(cx - 5, cy - 11), 2.4, Paint()..color = const Color(0xFFFF1744));
        canvas.drawCircle(Offset(cx + 5, cy - 11), 2.4, Paint()..color = const Color(0xFFFF1744));
        break;
      case EnemyType.chaosSpawn:
        WHDraw.brute(canvas, cx, cy, 1.22, flash: f);
        final mutation = Paint()..color = const Color(0xFF8E24AA)..strokeWidth = 4..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - 15, cy - 3), Offset(cx - 24, cy - 17), mutation);
        canvas.drawLine(Offset(cx + 14, cy - 1), Offset(cx + 23, cy - 14), mutation);
        canvas.drawCircle(Offset(cx + 3, cy - 13), 4 + 1.5 * sin(animationClock * 5).abs(), Paint()..color = const Color(0xFFCE93D8));
        break;
      case EnemyType.necronImmortal:
        WHDraw.shieldedMarine(canvas, cx, cy, 1.12, withGun: true, flash: f);
        final gauss = Paint()..color = Color.lerp(const Color(0xFF00E5FF), const Color(0xFF76FF03), 0.5 + 0.5 * sin(animationClock * 7))!..strokeWidth = 3..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - 16, cy - 7), Offset(cx + 16, cy - 7), gauss);
        canvas.drawLine(Offset(cx - 8, cy - 17), Offset(cx + 8, cy - 17), gauss..strokeWidth = 2);
        break;
    }
    // Procedural detail pass: chipped plates, rivets, bio-chitin ridges and energy seams.
    // Everything is drawn with Canvas; no external sprites or texture assets are required.
    final pulse = 0.5 + 0.5 * sin(animationClock * (type == EnemyType.tyranidGaunt || type == EnemyType.dog ? 8 : 3));
    final detail = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final plate = Paint()..style = PaintingStyle.fill;
    final isBio = type == EnemyType.tyranidGaunt || type == EnemyType.dog || type == EnemyType.plagueBearer;
    final isMetal = type == EnemyType.necronWarrior || type == EnemyType.shielded || type == EnemyType.shieldedShooter;
    final accent = isBio ? const Color(0xFF9AAE42) : isMetal ? const Color(0xFF00C9C9) : const Color(0xFF9E2635);
    for (int i = 0; i < 5; i++) {
      final dx = (i - 2) * 7.0;
      final y = -11.0 + (i % 2) * 5.0;
      canvas.drawCircle(Offset(cx + dx, cy + y), 1.1 + pulse * 0.35, plate..color = accent.withOpacity(0.75));
    }
    if (isBio) {
      for (int i = 0; i < 3; i++) {
        final x = cx + (i - 1) * 8.0;
        final path = Path()..moveTo(x - 3, cy - 13)..lineTo(x, cy - 20 - (i % 2) * 3)..lineTo(x + 3, cy - 13);
        canvas.drawPath(path, detail..color = const Color(0xFF4D5A25)..strokeWidth = 2.0);
      }
    } else {
      for (int i = 0; i < 4; i++) {
        final x = cx - 13 + i * 8.5;
        canvas.drawCircle(Offset(x, cy + 9), 1.35, plate..color = const Color(0xFFC4B8A0));
      }
      canvas.drawLine(Offset(cx - 12, cy + 1), Offset(cx + 12, cy + 1), detail..color = accent.withOpacity(0.65 + pulse * 0.3));
    }
    if (hitReactTimer > 0) {
      final reaction = Paint()..color = const Color(0xFFFFF3D0).withOpacity(((hitReactTimer / 0.16).clamp(0.0, 1.0) * 0.7).toDouble())..blendMode = BlendMode.screen;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: size.x * 0.72, height: size.y * 0.78), reaction);
      // Small directional impact sparks are procedurally placed around the torso.
      for (int i = 0; i < 4; i++) {
        final a = animationClock * 9 + i * pi / 2;
        final start = Offset(cx + cos(a) * 12, cy + sin(a) * 14);
        final end = Offset(cx + cos(a) * (18 + 4 * pulse), cy + sin(a) * (20 + 4 * pulse));
        canvas.drawLine(start, end, Paint()..color = const Color(0xFFFFD180)..strokeWidth = 1.8);
      }
    }
    if (isChampion) {
      WHDraw.championMark(canvas, cx, -10, affix: affix);
      final ratio = currentHp / maxHp;
      canvas.drawRect(Rect.fromLTWH(cx - 22, -4, 44 * ratio, 5), Paint()..color = affix != EliteAffix.none ? affix.color : const Color(0xFFFFD700));
    }
    if (attackWindup > 0) {
      final progress = (attackWindup / _attackWindupDuration).clamp(0.0, 1.0);
      final warningColor = affix == EliteAffix.summoner
          ? const Color(0xFFB388FF)
          : type == EnemyType.cultPsyker || type == EnemyType.bloodletter
              ? const Color(0xFFCE93D8)
              : type == EnemyType.necronWarrior || type == EnemyType.necronImmortal
                  ? const Color(0xFF00E5FF)
                  : type == EnemyType.sniper
                      ? const Color(0xFFFFB74D)
                      : const Color(0xFFFF5252);
      final warningPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (1.0 - progress) * 2.0
        ..color = warningColor.withOpacity(0.45 + (1.0 - progress) * 0.5);
      canvas.drawCircle(Offset(cx, cy + 5), 25 + (1.0 - progress) * 8, warningPaint);
      canvas.drawCircle(Offset(cx, cy + 5), 7 + (1.0 - progress) * 4,
          Paint()..color = warningColor.withOpacity(0.45));
      // Directional lane for ranged/warp attacks. Its angle matches the locked
      // attackDirection used when the wind-up resolves.
      final isRangedTelegraph = type == EnemyType.shooter ||
          type == EnemyType.shieldedShooter || type == EnemyType.sniper ||
          type == EnemyType.necronImmortal || type == EnemyType.cultPsyker;
      if (isRangedTelegraph) {
        final start = Offset(cx + attackDirection.x * 10, cy + attackDirection.y * 10);
        final end = Offset(cx + attackDirection.x * (48 + (1.0 - progress) * 12),
            cy + attackDirection.y * (48 + (1.0 - progress) * 12));
        canvas.drawLine(start, end, warningPaint..strokeWidth = 2.5);
        canvas.drawCircle(end, 3.0, Paint()..color = warningColor.withOpacity(0.75));
        // Elite cultists and shielded gunners signal the wider spread before firing.
        if (isChampion && (type == EnemyType.shooter || type == EnemyType.shieldedShooter)) {
          for (final side in [-1.0, 1.0]) {
            final a = atan2(attackDirection.y, attackDirection.x) + side * 0.13;
            final fanEnd = Offset(cx + cos(a) * (48 + (1.0 - progress) * 12),
                cy + sin(a) * (48 + (1.0 - progress) * 12));
            canvas.drawLine(Offset(cx + cos(a) * 10, cy + sin(a) * 10), fanEnd,
                warningPaint..strokeWidth = 1.4);
          }
        }
      }
    }
    if (affix == EliteAffix.summoner && currentHp > 0) {
      final warpPulse = 0.5 + 0.5 * sin(animationClock * 5.5);
      canvas.drawCircle(Offset(cx, cy), 31 + warpPulse * 4,
        Paint()..color = const Color(0xFFB388FF).withOpacity(0.35 + warpPulse * 0.25)
          ..style = PaintingStyle.stroke..strokeWidth = 2.2);
      canvas.drawCircle(Offset(cx, cy - 24), 4 + warpPulse * 2,
        Paint()..color = const Color(0xFFE1BEE7).withOpacity(0.8));
    }
    WHDraw.statusIcons(canvas, cx, -18, statuses);
    if (suppression > 2) {
      canvas.drawRect(Rect.fromLTWH(cx - 18, 5, 36, 3), Paint()..color = const Color(0xFF263238));
      canvas.drawRect(Rect.fromLTWH(cx - 18, 5, 36 * suppression / 100, 3), Paint()..color = morale <= 0 ? const Color(0xFFEF5350) : const Color(0xFF4FC3F7));
    }
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
    // Shotgun volley
    for (final o in [-0.35, -0.15, 0.0, 0.15, 0.35]) {
      final a = base + o;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 220)..priority = 22);
    }
    // Weak-point timing is handled by the phased Boss class, not MiniBoss.
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
    // Mini-boss silhouette: bulky cultist with shotgun
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 40), width: 50, height: 12), Paint()..color = Colors.black.withOpacity(0.22));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 48, height: 52), const Radius.circular(6)),
      Paint()..color = const Color(0xFF4A1515),
    );
    canvas.drawCircle(Offset(cx, cy - 22), 16, Paint()..color = const Color(0xFF3E2723));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 22), width: 14, height: 4), Paint()..color = const Color(0xFFFF9800));
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
    drawBossHitZones(canvas, size, exposed: false);
    WHDraw.statusIcons(canvas, cx, -28, statuses);
  }
}
int _bossPhaseForHealth(int currentHp, int maxHp) {
  if (currentHp <= max(1, maxHp ~/ 3)) return 3;
  if (currentHp <= max(1, (maxHp * 2) ~/ 3)) return 2;
  return 1;
}

void _announceBossPhase(InquisitorGame game, Vector2 position, int phase) {
  game.spawnDamageNumber(
    position,
    0,
    color: phase >= 3 ? const Color(0xFFFF1744) : const Color(0xFFFFD54F),
    label: phase >= 3 ? 'ФАЗА III' : 'ФАЗА II',
  );
  game.triggerCinemaZoom();
  game.triggerShake(power: phase >= 3 ? 15 : 11, time: 0.35);
}

/// Rival Inquisitor encounter. Reuses MiniBoss combat/collision plumbing to keep it compatible
/// with every existing projectile and save; only its vector appearance and durability differ.
class RivalInquisitor extends MiniBoss {
  RivalInquisitor({required int floor, required Vector2 position}) : super(floor: floor, position: position, isEcho: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    maxHp = (maxHp * 1.45).round();
    currentHp = maxHp;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    canvas.drawCircle(Offset(cx, cy), 49, Paint()..color = const Color(0xFFB71C1C).withOpacity(0.12));
    WHDraw.inquisitor(canvas, cx: cx, cy: cy, s: 1.12, flash: hurtFlash / 0.12, cls: PlayerClass.hereticus, healthRatio: maxHp <= 0 ? 1 : currentHp / maxHp);
    // Distinct red rosette identifies the rival without importing a sprite.
    canvas.drawCircle(Offset(cx, cy - 28), 8, Paint()..color = const Color(0xFFB71C1C));
    canvas.drawCircle(Offset(cx, cy - 28), 8, Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    for (int i = 0; i < 4; i++) {
      final a = i * pi / 2;
      canvas.drawLine(Offset(cx + cos(a) * 10, cy - 28 + sin(a) * 10), Offset(cx + cos(a) * 14, cy - 28 + sin(a) * 14), Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 1.5);
    }
    canvas.drawRect(Rect.fromLTWH(cx - 32, -16, 64 * (currentHp / max(1, maxHp)), 5), Paint()..color = const Color(0xFFB71C1C));
    canvas.drawRect(Rect.fromLTWH(cx - 32, -16, 64, 5), Paint()..color = const Color(0xFFFFD54F).withOpacity(0.7)..style = PaintingStyle.stroke..strokeWidth = 1);
  }
}

class Boss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final bool isEcho;
  int phase = 1;
  late int maxHp;
  late int currentHp;
  int hardBars = 1;
  int _lastBar = 0;
  double attackTimer = 0;
  double telegraphTimer = 0;
  double weakSpotTimer = 0;
  bool telegraphing = false;
  int attackMode = 0;
  // The boss remains vulnerable briefly after a telegraphed attack resolves,
  // creating a readable punish window instead of a one-frame opening.
  bool get weakSpotExposed => phase >= 2 && (telegraphing || weakSpotTimer > 0);
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  Boss({required this.floor, required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(120, 120), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    hardBars = (!isEcho && game.difficulty == Difficulty.hard) ? 2 : 1;
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((160 + floor * 40) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    _lastBar = hardBars;
    add(CircleHitbox(radius: 50));
    if (!isEcho) game.unlockCodex(CodexId.boss);
  }

  int get _barHp => max(1, maxHp ~/ hardBars);
  int get _barsLeft => ((currentHp - 1) ~/ _barHp) + 1;

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeCombatDamage(int amount, {required CombatDamageType damageType, double armorPenetration = 0}) {
    // Bosses have layered armor: kinetic fire is reliable, plasma breaks armor,
    // warp harms echoes more efficiently, and flame is less effective against armored targets.
    var multiplier = 1.0;
    final armor = (isEcho ? 0.08 : (floor >= 8 ? 0.28 : floor >= 4 ? 0.20 : 0.12));
    final effectiveArmor = (armor - armorPenetration).clamp(0.0, 0.6);
    multiplier *= 1.0 - effectiveArmor;
    if (damageType == CombatDamageType.plasma) multiplier *= 1.22;
    if (damageType == CombatDamageType.warp) multiplier *= isEcho ? 1.30 : 1.08;
    if (damageType == CombatDamageType.flame) multiplier *= 0.88;
    if (damageType == CombatDamageType.explosive) multiplier *= 1.08;
    takeDamage(max(1, (amount * multiplier).round()));
  }

  void takeDamage(int amount) {
    if (currentHp <= 0) return;
    if (weakSpotExposed && amount > 0) {
      amount = (amount * 1.22).round();
      game.spawnDamageNumber(position + Vector2(0, -48), amount, color: const Color(0xFFFFD54F), label: 'УЯЗВИМОСТЬ');
    }
    if (amount > 0) {
      if (game.usingMelee) { game.meleePressure = min(10000, game.meleePressure + 1); }
      else { game.rangedPressure = min(10000, game.rangedPressure + 1); }
    }
    currentHp = max(0, currentHp - amount);
    final nextPhase = _bossPhaseForHealth(currentHp, maxHp);
    if (nextPhase > phase && currentHp > 0) {
      phase = nextPhase;
      attackTimer = 0;
      telegraphing = false;
      weakSpotTimer = 0;
      _announceBossPhase(game, position, phase);
    }
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF5252));
    if (hardBars > 1 && _barsLeft < _lastBar) {
      _lastBar = _barsLeft;
      game.triggerCinemaZoom();
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      final fromDir = (pos - game.player.position).normalized();
      removeFromParent();
      game.spawnBlood(pos, count: 28, fromDir: fromDir);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.ranged,
        fromDir: fromDir,
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.75;
    attackMode = Random().nextInt(phase == 1 ? 3 : phase == 2 ? 4 : 5);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    final warningColor = switch (attackMode) {
      0 => const Color(0xFFFF5252), // radial burst
      1 => const Color(0xFFFFA726), // aimed cone
      2 => const Color(0xFF26C6DA), // cross volley
      3 => const Color(0xFFAB47BC), // heavy radial burst
      _ => const Color(0xFFFF1744), // focused barrage
    };
    switch (attackMode) {
      case 0:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 130, life: 0.75, color: warningColor)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 220, angle: ang, life: 0.75, color: warningColor)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 150, life: 0.75, color: warningColor)..priority = 6);
        break;
      case 3:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 180, life: 0.75, color: warningColor)..priority = 6);
        break;
      case 4:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 270, angle: ang, life: 0.75, color: warningColor)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    final base = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0:
        final n = game.difficulty == Difficulty.hard ? 12 : 8;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 1:
        for (final o in [-0.4, -0.2, 0.0, 0.2, 0.4]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 2:
        for (final a in [0.0, pi / 2, pi, 3 * pi / 2]) {
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        for (final a in [pi / 4, 3 * pi / 4, 5 * pi / 4, 7 * pi / 4]) {
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 160)..priority = 22);
        }
        break;
      case 3:
        final n = game.difficulty == Difficulty.hard ? 18 : 14;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 175)..priority = 22);
        }
        break;
      case 4:
        for (final o in [-0.6, -0.4, -0.2, 0.0, 0.2, 0.4, 0.6]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 230)..priority = 22);
        }
        break;
    }
    // After phase II, completing a telegraphed attack briefly exposes the boss's weak point.
    if (phase >= 2) weakSpotTimer = phase >= 3 ? 1.8 : 1.4;
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (weakSpotTimer > 0) weakSpotTimer = max(0.0, weakSpotTimer - dt);
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
    var spd = 85.0 * (phase == 1 ? 1.0 : phase == 2 ? 1.08 : 1.16) * (isEcho ? 0.8 : 1.0);
    // Adaptation is intentionally bounded: bosses react to repeated player habits without becoming unfair.
    final meleeDominant = game.meleePressure > game.rangedPressure * 1.25;
    final rangedDominant = game.rangedPressure > game.meleePressure * 1.25;
    if (meleeDominant) spd *= 1.08; // kite and reposition against melee-heavy builds
    if (rangedDominant) spd *= 1.12; // close distance against stationary ranged builds
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.45, dt, radius: 50, kite: true, preferDist: 200);
      pushOutOfWalls(50);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    // After volley — retreat (bossRetreatTimer set by markBossRetreat)
    final retreating = game.bossRetreatTimer > 0;
    smartMove(
      game.player.position,
      spd * (retreating ? 1.15 : 1.0),
      dt,
      radius: 50,
      kite: retreating || dist > 280,
      preferDist: retreating ? 300 : 220,
    );
    pushOutOfWalls(50);

    attackTimer += dt;
    final phaseSpeed = phase == 1 ? 1.0 : phase == 2 ? 0.84 : 0.70;
    final adaptiveTempo = rangedDominant ? 0.92 : meleeDominant ? 0.96 : 1.0;
    final iv = (dist < 160 ? 1.2 : 1.7) * phaseSpeed * adaptiveTempo * (isEcho ? 1.25 : 1.0) / (game.difficulty == Difficulty.hard ? 1.15 : 1.0);
    if (attackTimer >= iv && !retreating) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.75;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.hereticBoss(canvas, cx, cy, 1.35, flash: hurtFlash / 0.12);
    if (weakSpotExposed) {
      final pulse = 0.65 + sin(game.missionAlarmClock * 9).abs() * 0.35;
      canvas.drawCircle(Offset(cx, cy - 20), 13, Paint()..color = const Color(0xFFFF1744).withOpacity(0.18 + pulse * 0.22));
      canvas.drawCircle(Offset(cx, cy - 20), 7, Paint()..color = const Color(0xFFFFD54F).withOpacity(pulse));
      canvas.drawCircle(Offset(cx, cy - 20), 11, Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
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
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - 50, -22 - i * 10.0, 100 * remain, 8),
        Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFE53935),
      );
    }
    drawBossHitZones(canvas, size, exposed: weakSpotExposed);
    WHDraw.statusIcons(canvas, cx, -34, statuses);
  }
}

class KnightBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final bool isEcho;
  int phase = 1;
  late int maxHp;
  late int currentHp;
  int hardBars = 1;
  int _lastBar = 0;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0;
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  KnightBoss({required this.floor, required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(115, 115), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    hardBars = (!isEcho && game.difficulty == Difficulty.hard) ? 2 : 1;
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((180 + floor * 45) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    _lastBar = hardBars;
    add(CircleHitbox(radius: 48));
    if (!isEcho) game.unlockCodex(CodexId.knight);
  }

  int get _barHp => max(1, maxHp ~/ hardBars);
  int get _barsLeft => ((currentHp - 1) ~/ _barHp) + 1;

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (currentHp <= 0) return;
    currentHp = max(0, currentHp - amount);
    final nextPhase = _bossPhaseForHealth(currentHp, maxHp);
    if (nextPhase > phase && currentHp > 0) {
      phase = nextPhase;
      attackTimer = 0;
      telegraphing = false;
      _announceBossPhase(game, position, phase);
    }
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFF90CAF9));
    if (hardBars > 1 && _barsLeft < _lastBar) {
      _lastBar = _barsLeft;
      game.triggerCinemaZoom();
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      final fromDir = (pos - game.player.position).normalized();
      removeFromParent();
      game.spawnBlood(pos, count: 30, fromDir: fromDir);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.knight,
        fromDir: fromDir,
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7;
    attackMode = Random().nextInt(phase == 1 ? 3 : phase == 2 ? 4 : 5);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 200, angle: ang, life: 0.7)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 100, life: 0.7)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 140, life: 0.7)..priority = 6);
        break;
      case 3:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 170, life: 0.7)..priority = 6);
        break;
      case 4:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: game.cellSize * 2.0, life: 0.7)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final dist = position.distanceTo(game.player.position);
    final toP = (game.player.position - position).normalized();
    switch (attackMode) {
      case 0:
        // Charge
        position += toP * 90;
        if (dist < 120) game.player.takeDamage((2 * game.difficulty.dmgMult).ceil());
        break;
      case 1:
        game.world.add(TentacleSlam(position: position.clone(), radius: game.cellSize * 1.8)..priority = 27);
        if (dist < game.cellSize * 1.8 + 30) {
          game.player.takeDamage((2 * game.difficulty.dmgMult).ceil());
          game.player.applyStatus(StatusType.slow, 1.2);
        }
        break;
      case 2:
        for (final a in [0.0, pi / 2, pi, 3 * pi / 2]) {
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 3:
        final n = game.difficulty == Difficulty.hard ? 12 : 8;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 185)..priority = 22);
        }
        break;
      case 4:
        final slamRadius = game.cellSize * 2.0;
        game.world.add(TentacleSlam(position: position.clone(), radius: slamRadius)..priority = 27);
        if (position.distanceTo(game.player.position) < slamRadius + 30) {
          game.player.takeDamage((2 * game.difficulty.dmgMult).ceil());
          game.player.applyStatus(StatusType.slow, 1.0);
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
    var spd = 110.0 * (phase == 1 ? 1.0 : phase == 2 ? 1.08 : 1.16) * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;
    final retreating = game.bossRetreatTimer > 0;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.4, dt, radius: 48);
      pushOutOfWalls(48);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(
      game.player.position,
      spd * (retreating ? 1.1 : 1.0),
      dt,
      radius: 48,
      kite: retreating,
      preferDist: retreating ? 260 : 0,
    );
    pushOutOfWalls(48);

    attackTimer += dt;
    final iv = (dist < 120 ? 0.9 : 1.4) * (phase == 1 ? 1.0 : phase == 2 ? 0.84 : 0.70) * (isEcho ? 1.2 : 1.0);
    if (attackTimer >= iv && !retreating) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.75;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.knightBoss(canvas, cx, cy, 1.35, flash: hurtFlash / 0.12);
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
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - 48, -20 - i * 10.0, 96 * remain, 8),
        Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFF90CAF9),
      );
    }
    drawBossHitZones(canvas, size, exposed: false);
    WHDraw.statusIcons(canvas, cx, -32, statuses);
  }
}
class KingBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  late int phaseHp;
  int phase = 1;
  int hardBars = 1;
  double meleeTimer = 0;
  double phase2Timer = 0;
  int phase2VolleyCount = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0;
  double hurtFlash = 0;
  double invPulse = 0;
  final List<StatusEffect> statuses = [];

  KingBoss({required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(140, 140), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    hardBars = (!isEcho && game.difficulty == Difficulty.hard) ? 3 : 2;
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = (420 * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    phaseHp = maxHp ~/ 2;
    add(CircleHitbox(radius: 60));
    if (!isEcho) game.unlockCodex(CodexId.king);
  }

  int get _barHp => max(1, maxHp ~/ hardBars);

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.75;
    attackMode = Random().nextInt(phase == 1 ? 2 : phase == 2 ? 3 : 4);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 120, life: 0.75)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 240, angle: ang, life: 0.75)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 160, life: 0.75)..priority = 6);
        break;
      case 3:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 190, life: 0.75)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    final base = atan2(toP.y, toP.x);
    final dist = position.distanceTo(game.player.position);
    switch (attackMode) {
      case 0:
        if (dist < 130) game.player.takeDamage((2 * game.difficulty.dmgMult).ceil());
        for (final o in [-0.25, 0.0, 0.25]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 1:
        for (final o in [-0.55, -0.35, -0.15, 0.0, 0.15, 0.35, 0.55]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 2:
        for (final a in [0.0, pi / 4, pi / 2, 3 * pi / 4, pi, 5 * pi / 4, 3 * pi / 2, 7 * pi / 4]) {
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 3:
        final n = game.difficulty == Difficulty.hard ? 20 : 16;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 185)..priority = 22);
        }
        break;
    }
    game.markBossRetreat();
  }

  void _volley() {
    final n = game.difficulty == Difficulty.hard ? 16 : 12;
    for (int i = 0; i < n; i++) {
      final a = (i / n) * 2 * pi;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    invPulse += dt * 4;
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
    final hardBoost = game.difficulty == Difficulty.hard
        ? 1.0 + ((maxHp - currentHp) / maxHp) * 0.4
        : 1.0;
    final retreating = game.bossRetreatTimer > 0;

    if (telegraphing) {
      smartMove(
        game.player.position,
        (phase == 1 ? 40.0 : 20.0) * hardBoost * (isEcho ? 0.85 : 1.0),
        dt,
        radius: 60,
      );
      pushOutOfWalls(60);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(
      game.player.position,
      (phase == 1 ? 100.0 : 38.0) * hardBoost * (isEcho ? 0.85 : 1.0) * (retreating ? 1.1 : 1.0),
      dt,
      radius: 60,
      kite: retreating,
      preferDist: retreating ? 320 : 0,
    );
    pushOutOfWalls(60);

    if (phase == 1) {
      final interval = (dist < 140 ? 0.55 : 0.9) / hardBoost * (isEcho ? 1.2 : 1.0);
      meleeTimer += dt;
      if (meleeTimer >= interval && !retreating) {
        meleeTimer = 0;
        _startTelegraph();
      }
    } else {
      phase2Timer += dt;
      final phase3 = phase >= 3;
      final volleyGap = (game.difficulty == Difficulty.hard ? 0.28 : 0.35) * (phase3 ? 0.8 : 1.0);
      final cycle = (game.difficulty == Difficulty.hard ? 2.4 : 3.0) * (phase3 ? 0.78 : 1.0);
      if (phase2VolleyCount > 0) {
        if (phase2Timer >= volleyGap) {
          phase2Timer = 0;
          game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 100, life: 0.35)..priority = 6);
          _volley();
          phase2VolleyCount--;
        }
      } else if (phase2Timer >= cycle && !retreating) {
        phase2Timer = 0;
        phase2VolleyCount = phase3 ? (game.difficulty == Difficulty.hard ? 4 : 3) : (game.difficulty == Difficulty.hard ? 3 : 2);
        _startTelegraph();
      }
    }
  }

  void takeDamage(int amount) {
    // Invulnerable while escort (Boss/Knight/Plague/Blood) alive
    if (!isEcho && game.areOtherBossesAlive) return;
    if (currentHp <= 0) return;
    currentHp = max(0, currentHp - amount);
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFFD700));
    final nextPhase = _bossPhaseForHealth(currentHp, maxHp);
    if (nextPhase > phase && currentHp > 0) {
      phase = nextPhase;
      phase2Timer = 0;
      phase2VolleyCount = 0;
      telegraphing = false;
      _announceBossPhase(game, position, phase);
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      final fromDir = (pos - game.player.position).normalized();
      removeFromParent();
      game.spawnBlood(pos, count: 36, fromDir: fromDir);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.king,
        fromDir: fromDir,
      );
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 20;
      stuckTimer = 0.85;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final inv = !isEcho && game.areOtherBossesAlive;
    WHDraw.kingBossDraw(canvas, cx, cy, 1.6, flash: hurtFlash / 0.12);
    if (inv) {
      final pulse = 0.25 + 0.2 * sin(invPulse);
      canvas.drawCircle(
        Offset(cx, cy),
        68 + 4 * sin(invPulse),
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.25 + pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      final tp = TextPainter(
        text: const TextSpan(
          text: 'СВИТА',
          style: TextStyle(color: Color(0xFFE040FB), fontSize: 14, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 3)]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, -78));
    }
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        62,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      final colors = isEcho
          ? [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)]
          : [const Color(0xFFE53935), const Color(0xFFFF9800), const Color(0xFFFFEB3B), const Color(0xFFFFD700)];
      canvas.drawRect(
        Rect.fromLTWH(cx - 55, -56 - i * 11.0, 110 * remain, 8),
        Paint()..color = colors[i % colors.length],
      );
    }
    drawBossHitZones(canvas, size, exposed: false);
    WHDraw.statusIcons(canvas, cx, -68, statuses);
  }
}

/// Plague Lord — Nurgle champion: regen, plague clouds, summons
class PlagueLordBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  int phase = 1;
  int hardBars = 1;
  int _lastBar = 0;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0;
  double hurtFlash = 0;
  double regenAcc = 0;
  final List<StatusEffect> statuses = [];

  PlagueLordBoss({required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(150, 160), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    hardBars = (!isEcho && game.difficulty == Difficulty.hard) ? 3 : 2;
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((380 + game.currentFloor * 30) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    _lastBar = hardBars;
    add(CircleHitbox(radius: 58));
    if (!isEcho) game.unlockCodex(CodexId.plagueLord);
  }

  int get _barHp => max(1, maxHp ~/ hardBars);
  int get _barsLeft => ((currentHp - 1) ~/ _barHp) + 1;

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (currentHp <= 0) return;
    currentHp = max(0, currentHp - amount);
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFF8BC34A));
    if (hardBars > 1 && _barsLeft < _lastBar) {
      _lastBar = _barsLeft;
      game.triggerCinemaZoom();
    }
    final nextPhase = _bossPhaseForHealth(currentHp, maxHp);
    if (nextPhase > phase && currentHp > 0) {
      phase = nextPhase;
      attackTimer = 0;
      telegraphing = false;
      _announceBossPhase(game, position, phase);
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      final fromDir = (pos - game.player.position).normalized();
      removeFromParent();
      game.spawnBlood(pos, count: 32, fromDir: fromDir);
      game.spawnCorruptionZone(pos);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.plague,
        fromDir: fromDir,
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.8;
    attackMode = Random().nextInt(phase == 1 ? 2 : phase == 2 ? 3 : 4);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 140, life: 0.8)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 200, angle: ang, life: 0.8)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 150, life: 0.8)..priority = 6);
        break;
      case 3:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 190, life: 0.8)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    final dist = position.distanceTo(game.player.position);
    switch (attackMode) {
      case 0:
        // Plague cloud ring
        for (int i = 0; i < 6; i++) {
          final a = (i / 6) * 2 * pi;
          final cloudPos = position + Vector2(cos(a), sin(a)) * 70;
          game.world.add(FlamerCloud(position: cloudPos)..priority = 11);
          // recolor via plague — use FlamerCloud + status
        }
        if (dist < 150) {
          game.player.takeDamage((1 * game.difficulty.dmgMult).ceil());
          game.player.applyStatus(StatusType.plague, 3.0, tickDamage: 1);
        }
        break;
      case 1:
        for (final o in [-0.3, 0.0, 0.3]) {
          final a = atan2(toP.y, toP.x) + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 160)..priority = 22);
        }
        break;
      case 2:
        // Summon 2 plague bearers
        for (int i = 0; i < (phase >= 3 ? 3 : 2); i++) {
          final offset = Vector2(i == 0 ? -80.0 : i == 1 ? 80.0 : 0.0, 40);
          final pos = position + offset;
          if (pos.x < 100 || pos.x > game.mapWidth - 100) continue;
          game.enemiesAlive++;
          game.enemiesToSpawn++;
          game.enemiesSpawned++;
          final e = Enemy(floor: game.currentFloor, type: EnemyType.plagueBearer);
          e.position = pos;
          e.maxHp = max(10, (e.maxHp * 0.4).round());
          e.currentHp = e.maxHp;
          e.priority = 30;
          game.world.add(e);
        }
        game.spawnDamageNumber(position, 0, color: const Color(0xFF8BC34A), label: 'ГНИЛЬ');
        break;
      case 3:
        final n = game.difficulty == Difficulty.hard ? 16 : 12;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 150)..priority = 22);
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

    // Passive regen
    regenAcc += dt;
    if (regenAcc >= 2.0 && currentHp < maxHp) {
      regenAcc = 0;
      currentHp = min(maxHp, currentHp + max(1, maxHp ~/ 40));
    }

    final dist = position.distanceTo(game.player.position);
    var spd = 50.0 * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;
    final retreating = game.bossRetreatTimer > 0;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.4, dt, radius: 58, kite: true, preferDist: 200);
      pushOutOfWalls(58);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(game.player.position, spd, dt, radius: 58, kite: retreating || dist < 160, preferDist: 200);
    pushOutOfWalls(58);

    attackTimer += dt;
    final iv = (phase == 1 ? 1.9 : phase == 2 ? 1.4 : 1.05) * (isEcho ? 1.2 : 1.0);
    if (attackTimer >= iv && !retreating) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 18;
      stuckTimer = 0.8;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.plagueLord(canvas, cx, cy, 1.25, flash: hurtFlash / 0.12);
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        70,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - 55, -50 - i * 11.0, 110 * remain, 8),
        Paint()..color = phase == 1 ? const Color(0xFF8BC34A) : const Color(0xFF558B2F),
      );
    }
    drawBossHitZones(canvas, size, exposed: false);
    WHDraw.statusIcons(canvas, cx, -62, statuses);
  }
}

/// Blood Champion — Khorne elite: rage scales with missing HP, aggressive melee
class BloodChampionBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final bool isEcho;
  int phase = 1;
  late int maxHp;
  late int currentHp;
  int hardBars = 1;
  int _lastBar = 0;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0;
  double hurtFlash = 0;
  int killStacks = 0; // grows when player is hurt nearby
  final List<StatusEffect> statuses = [];

  BloodChampionBoss({required Vector2 position, this.isEcho = false})
      : super(position: position, size: Vector2(130, 140), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    hardBars = (!isEcho && game.difficulty == Difficulty.hard) ? 3 : 2;
    final mult = isEcho ? 0.6 : 1.0;
    maxHp = ((350 + game.currentFloor * 35) * game.difficulty.bossHpMult * game.worldThreat * mult).round();
    currentHp = maxHp;
    _lastBar = hardBars;
    add(CircleHitbox(radius: 52));
    if (!isEcho) game.unlockCodex(CodexId.bloodChampion);
  }

  int get _barHp => max(1, maxHp ~/ hardBars);
  int get _barsLeft => ((currentHp - 1) ~/ _barHp) + 1;
  double get rage => ((maxHp - currentHp) / maxHp).clamp(0.0, 1.0);

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
  }

  void takeDamage(int amount) {
    if (currentHp <= 0) return;
    currentHp = max(0, currentHp - amount);
    final nextPhase = _bossPhaseForHealth(currentHp, maxHp);
    if (nextPhase > phase && currentHp > 0) {
      phase = nextPhase;
      attackTimer = 0;
      telegraphing = false;
      _announceBossPhase(game, position, phase);
    }
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF1744));
    if (hardBars > 1 && _barsLeft < _lastBar) {
      _lastBar = _barsLeft;
      game.triggerCinemaZoom();
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      final fromDir = (pos - game.player.position).normalized();
      removeFromParent();
      game.spawnBlood(pos, count: 40, fromDir: fromDir);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.blood,
        fromDir: fromDir,
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.55 - rage * 0.15;
    attackMode = Random().nextInt(phase == 1 ? 3 : phase == 2 ? 4 : 5);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 180 + rage * 40, angle: ang, life: telegraphTimer)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 90 + rage * 30, life: telegraphTimer)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 130, life: telegraphTimer)..priority = 6);
        break;
      case 3:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 175, life: telegraphTimer)..priority = 6);
        break;
      case 4:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 260, angle: ang, life: telegraphTimer)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final dist = position.distanceTo(game.player.position);
    final toP = (game.player.position - position).normalized();
    final dmg = ((2 + (rage * 2).round()) * game.difficulty.dmgMult).ceil();
    switch (attackMode) {
      case 0:
        // Dash slash
        position += toP * (70 + rage * 40);
        if (dist < 140) {
          game.player.takeDamage(dmg);
          game.player.applyStatus(StatusType.bleed, 2.0, tickDamage: 1);
        }
        break;
      case 1:
        // Spin
        game.world.add(TentacleSlam(position: position.clone(), radius: game.cellSize * (1.6 + rage * 0.5))..priority = 27);
        if (dist < game.cellSize * 2.2) {
          game.player.takeDamage(dmg);
          game.player.applyStatus(StatusType.bleed, 1.5, tickDamage: 1);
        }
        break;
      case 2:
        for (final a in [0.0, pi / 2, pi, 3 * pi / 2]) {
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 240)..priority = 22);
        }
        break;
      case 3:
        final n = game.difficulty == Difficulty.hard ? 16 : 12;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 210)..priority = 22);
        }
        break;
      case 4:
        for (final o in [-0.55, -0.35, -0.15, 0.0, 0.15, 0.35, 0.55]) {
          final a = atan2(toP.y, toP.x) + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)), speed: 250)..priority = 22);
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
    var spd = (120.0 + rage * 50) * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;
    final retreating = game.bossRetreatTimer > 0;

    if (telegraphing) {
      smartMove(game.player.position, spd * 0.5, dt, radius: 52);
      pushOutOfWalls(52);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    // Blood Champion prefers aggressive approach unless retreating
    smartMove(
      game.player.position,
      spd,
      dt,
      radius: 52,
      kite: retreating,
      preferDist: retreating ? 200 : 0,
    );
    pushOutOfWalls(52);

    attackTimer += dt;
    final iv = (0.7 - rage * 0.25) * (phase == 1 ? 1.0 : phase == 2 ? 0.86 : 0.72) * (isEcho ? 1.2 : 1.0);
    if (attackTimer >= iv && !retreating) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.7;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.bloodChampion(canvas, cx, cy, 1.3, flash: hurtFlash / 0.12, rage: rage);
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        58,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - 50, -48 - i * 11.0, 100 * remain, 8),
        Paint()..color = Color.lerp(const Color(0xFFB71C1C), const Color(0xFFFF1744), rage)!,
      );
    }
    drawBossHitZones(canvas, size, exposed: false);
    WHDraw.statusIcons(canvas, cx, -60, statuses);
  }
}
class TentacleBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  static const int maxHpConst = 6666;
  late int maxHp;
  late int currentHp;
  int phase = 1;
  double phaseTimer = 0, anim = 0;
  int meleeHitsLeft = 0;
  double meleeGap = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  double hurtFlash = 0;
  int hardBars = 1;

  TentacleBoss({required Vector2 position})
      : super(position: position, size: Vector2(155, 155), anchor: Anchor.center, priority: 28);

  @override
  Future<void> onLoad() async {
    hardBars = game.difficulty == Difficulty.hard ? 3 : 1;
    maxHp = (maxHpConst * game.difficulty.bossHpMult * game.worldThreat * (game.difficulty == Difficulty.hard ? 1.15 : 1.0)).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 60));
    game.unlockCodex(CodexId.tentacle);
  }

  int get _barHp => max(1, maxHp ~/ hardBars);

  void _startRingTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7;
    game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 150, life: 0.7)..priority = 6);
  }

  void _fireRing() {
    final n = game.difficulty == Difficulty.hard ? 16 : 12;
    for (int i = 0; i < n; i++) {
      final a = (i / n) * 2 * pi + anim * 0.3;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
    }
    game.markBossRetreat();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    anim += dt;
    final dist = position.distanceTo(game.player.position);
    final hardBoost = game.difficulty == Difficulty.hard ? 1.2 : 1.0;
    final retreating = game.bossRetreatTimer > 0;

    if (telegraphing) {
      smartMove(game.player.position, 20 * hardBoost, dt, radius: 60);
      pushOutOfWalls(60);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _fireRing();
      }
      return;
    }

    smartMove(
      game.player.position,
      (phase == 1 ? 45.0 : phase == 2 ? 30.0 : 38.0) * hardBoost * (retreating ? 1.1 : 1.0),
      dt,
      radius: 60,
      kite: retreating,
      preferDist: retreating ? 250 : 0,
    );
    pushOutOfWalls(60);

    if (phase == 1) {
      phaseTimer += dt;
      final iv = game.difficulty == Difficulty.hard ? 1.4 : 1.8;
      if (phaseTimer >= iv && !retreating) {
        phaseTimer = 0;
        _startRingTelegraph();
      }
    } else {
      if (meleeHitsLeft > 0) {
        meleeGap += dt;
        final gap = (game.difficulty == Difficulty.hard ? 0.42 : 0.55) * (phase >= 3 ? 0.78 : 1.0);
        if (meleeGap >= gap) {
          meleeGap = 0;
          meleeHitsLeft--;
          game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: game.cellSize * 2.4, life: 0.35)..priority = 6);
          game.world.add(TentacleSlam(position: position.clone(), radius: game.cellSize * 2.4)..priority = 27);
          if (dist < game.cellSize * 2.4 + 35) {
            game.player.takeDamage(2);
            game.player.applyStatus(StatusType.corruption, 2.0, tickDamage: 1);
          }
        }
      } else {
        phaseTimer += dt;
        if (phaseTimer >= 2.2) {
          phaseTimer = 0;
          meleeHitsLeft = phase >= 3 ? (game.difficulty == Difficulty.hard ? 12 : 9) : (game.difficulty == Difficulty.hard ? 8 : 6);
          meleeGap = 0;
        }
      }
    }
  }

  void takeDamage(int amount) {
    if (currentHp <= 0) return;
    currentHp = max(0, currentHp - amount);
    final nextPhase = _bossPhaseForHealth(currentHp, maxHp);
    if (nextPhase > phase && currentHp > 0) {
      phase = nextPhase;
      phaseTimer = 0;
      meleeHitsLeft = phase == 2 ? (game.difficulty == Difficulty.hard ? 8 : 6) : (game.difficulty == Difficulty.hard ? 12 : 9);
      meleeGap = 0;
      _announceBossPhase(game, position, phase);
    }
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFF9C27B0));
    if (currentHp <= 0) {
      currentHp = 0;
      final pos = position.clone();
      final fromDir = (pos - game.player.position).normalized();
      removeFromParent();
      game.spawnBlood(pos, count: 36, fromDir: fromDir);
      game.spawnCorruptionZone(pos);
      game.onSecretBossKilled(cyclops: false);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 20;
      stuckTimer = 0.85;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2, t = anim;
    // Procedural tentacle mass
    for (int i = 0; i < 8; i++) {
      final baseA = (i / 8) * 2 * pi + t * 0.6;
      final wave = sin(t * 3 + i) * 22;
      final path = Path()..moveTo(cx, cy);
      for (int s = 1; s <= 6; s++) {
        final f = s / 6;
        final ang = baseA + sin(t * 2 + s * 0.4 + i) * 0.35;
        path.lineTo(cx + cos(ang) * (32 + f * 64 + wave * f), cy + sin(ang) * (32 + f * 64 + wave * f));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(const Color(0xFF1A0033), const Color(0xFF4A148C), 0.4 + 0.3 * sin(t + i))!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 80, height: 72), Paint()..color = const Color(0xFF12001F));
    canvas.drawCircle(Offset(cx, cy - 6), 16, Paint()..color = const Color(0xFF0D0D0D));
    canvas.drawCircle(Offset(cx, cy - 6), 11, Paint()..color = const Color(0xFFFF1744));
    // Shadow
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 55), width: 70, height: 16), Paint()..color = Colors.black.withOpacity(0.25));
    if (hurtFlash > 0) {
      canvas.drawCircle(Offset(cx, cy), 72, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * (hurtFlash / 0.12)));
    }
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - 58, -38 - i * 12.0, 116 * remain, 10),
        Paint()..color = phase == 1 ? const Color(0xFF9C27B0) : const Color(0xFFFF1744),
      );
    }
      drawBossHitZones(canvas, size, exposed: false);
  }
}

class CyclopsBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  static const int maxHpConst = 6666;
  late int maxHp;
  late int currentHp;
  int phase = 1;
  double phaseTimer = 0;
  double charge = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0;
  double hurtFlash = 0;
  int hardBars = 1;
  bool chargingLaser = false;

  CyclopsBoss({required Vector2 position})
      : super(position: position, size: Vector2(160, 170), anchor: Anchor.center, priority: 28);

  @override
  Future<void> onLoad() async {
    hardBars = game.difficulty == Difficulty.hard ? 3 : 1;
    maxHp = (maxHpConst * game.difficulty.bossHpMult * game.worldThreat * (game.difficulty == Difficulty.hard ? 1.2 : 1.0)).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 62));
    game.unlockCodex(CodexId.cyclops);
  }

  int get _barHp => max(1, maxHp ~/ hardBars);

  void _startTelegraph(int mode) {
    telegraphing = true;
    telegraphTimer = 0.75;
    attackMode = mode;
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (mode) {
      case 0:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 140, life: 0.75)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 240, angle: ang, life: 0.75)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 160, life: 0.75)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    final base = atan2(toP.y, toP.x);
    final dist = position.distanceTo(game.player.position);
    switch (attackMode) {
      case 0:
        final n = game.difficulty == Difficulty.hard ? 14 : 10;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 1:
        for (final o in [-0.35, -0.18, 0.0, 0.18, 0.35]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position + Vector2(0, -30), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 2:
        game.world.add(TentacleSlam(position: position.clone(), radius: game.cellSize * 2.6)..priority = 27);
        if (dist < game.cellSize * 2.6 + 40) {
          game.player.takeDamage(2);
          game.player.applyStatus(StatusType.slow, 1.8);
        }
        for (int i = 0; i < 8; i++) {
          final a = (i / 8) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
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
    final hardBoost = game.difficulty == Difficulty.hard ? 1.15 : 1.0;
    final retreating = game.bossRetreatTimer > 0;

    if (chargingLaser) {
      charge = min(1.0, charge + dt * 0.7);
      if (charge > 0.15 && charge < 0.2) {
        final toP = (game.player.position - position).normalized();
        final ang = atan2(toP.y, toP.x);
        game.world.add(TelegraphZone(position: position + Vector2(0, -20), shape: 'cone', radius: 280, angle: ang, life: 0.85)..priority = 6);
      }
      if (charge >= 1.0) {
        chargingLaser = false;
        charge = 0;
        final dir = (game.player.position - position).normalized();
        for (final o in [-0.12, 0.0, 0.12]) {
          final a = atan2(dir.y, dir.x) + o;
          game.world.add(BossProjectile(position: position + Vector2(0, -30), direction: Vector2(cos(a), sin(a)))..priority = 22);
          game.world.add(CyclopsLaserBeam(
            position: position + Vector2(0, -30),
            direction: Vector2(cos(a), sin(a)),
            damage: 12,
          )..priority = 22);
        }
        game.triggerShake(power: 10, time: 0.25);
        game.markBossRetreat();
      }
      return;
    }

    if (telegraphing) {
      smartMove(game.player.position, 25 * hardBoost, dt, radius: 62);
      pushOutOfWalls(62);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(
      game.player.position,
      (phase == 1 ? 55.0 : 70.0) * hardBoost * (retreating ? 1.1 : 1.0),
      dt,
      radius: 62,
      kite: retreating,
      preferDist: retreating ? 280 : 0,
    );
    pushOutOfWalls(62);
    phaseTimer += dt;

    if (phase == 1) {
      if (phaseTimer >= (game.difficulty == Difficulty.hard ? 1.5 : 2.0) && !retreating) {
        phaseTimer = 0;
        if (Random().nextDouble() < 0.35) {
          chargingLaser = true;
          charge = 0;
        } else {
          _startTelegraph(Random().nextInt(2));
        }
      }
    } else {
      final phaseThreeInterval = phase >= 3 ? 0.78 : 1.0;
      if (phaseTimer >= (game.difficulty == Difficulty.hard ? 1.1 : 1.4) * phaseThreeInterval && !retreating) {
        phaseTimer = 0;
        if (Random().nextDouble() < (phase >= 3 ? 0.68 : 0.5)) {
          chargingLaser = true;
          charge = 0;
        } else {
          _startTelegraph(Random().nextInt(3));
        }
      }
    }
  }

  void takeDamage(int amount) {
    if (currentHp <= 0) return;
    if (chargingLaser && charge > 0.3) amount = (amount * 0.7).round();
    currentHp = max(0, currentHp - amount);
    final nextPhase = _bossPhaseForHealth(currentHp, maxHp);
    if (nextPhase > phase && currentHp > 0) {
      phase = nextPhase;
      phaseTimer = 0;
      telegraphing = false;
      _announceBossPhase(game, position, phase);
    }
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFFFF6D00));
    if (currentHp <= 0) {
      currentHp = 0;
      final pos = position.clone();
      final fromDir = (pos - game.player.position).normalized();
      removeFromParent();
      game.spawnBlood(pos, count: 40, fromDir: fromDir);
      game.spawnCorruptionZone(pos);
      game.onSecretBossKilled(cyclops: true);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle || other is BreakableBarrel) {
      position += (position - intersectionPoints.first).normalized() * 20;
      stuckTimer = 0.85;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.cyclops(canvas, cx, cy, 1.45, flash: hurtFlash / 0.12, charge: charge);
    if (chargingLaser) {
      canvas.drawCircle(
        Offset(cx, cy - 30),
        40 + charge * 20,
        Paint()
          ..color = Color.fromRGBO(255, 109, 0, 0.25 + charge * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - 58, -42 - i * 12.0, 116 * remain, 10),
        Paint()..color = phase == 1 ? const Color(0xFFFF6D00) : const Color(0xFFFF1744),
      );
    }
      drawBossHitZones(canvas, size, exposed: false);
  }
}
class TentacleSlam extends CircleComponent {
  double life = 0.35;
  TentacleSlam({required Vector2 position, required double radius})
      : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35),
          priority: 27,
        );

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    paint.color = Color.fromRGBO(156, 39, 176, (life / 0.35 * 0.4).clamp(0.0, 0.4));
    if (life <= 0) removeFromParent();
  }
}
