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
          'settings': (c, g) => SettingsMenu(g as InquisitorGame),
          'gameOver': (c, g) => GameOverMenu(g as InquisitorGame),
          'levelComplete': (c, g) => LevelCompleteMenu(g as InquisitorGame),
          'skills': (c, g) => SkillsMenu(g as InquisitorGame),
          'reward': (c, g) => RewardMenu(g as InquisitorGame),
          'shop': (c, g) => ShopMenu(g as InquisitorGame),
          'victory': (c, g) => VictoryMenu(g as InquisitorGame),
          'records': (c, g) => RecordsMenu(g as InquisitorGame),
          'backpack': (c, g) => BackpackMenu(g as InquisitorGame),
          'loadSave': (c, g) => LoadSaveMenu(g as InquisitorGame),
          'codex': (c, g) => CodexMenu(g as InquisitorGame),
          'eventAltar': (c, g) => EventAltarMenu(g as InquisitorGame),
          'eventMerchant': (c, g) => EventMerchantMenu(g as InquisitorGame),
        },
        initialActiveOverlays: const ['mainMenu'],
      ),
    ),
  );
}

// ─── Enums ───────────────────────────────────────────────
enum RangedWeapon {
  bolter, rifle, shotgun,
  staff, stormStaff, warpBeam,
  daggers, needles, sniperNeedle,
}
enum MeleeWeapon {
  sword, axe, hammer,
  forceBlade, forceSword, daemonHammer,
  katana, powerKatana, executioner,
}
enum EnemyType { shooter, melee, shielded, dog, shieldedShooter, flamer, sniper, brute }
enum Difficulty { easy, normal, hard }
enum PlayerClass { xenos, malleus, hereticus }
enum RelicId { crit, lifesteal, shieldPierce, killExplosion, haste, jediPath }

enum StatusType { burn, bleed, slow, corruption }
enum ActiveArtifact { fragGrenade, holyAura, servoTurret }
enum BarrelMod { none, rapid, heavy }
enum SightMod { none, precision, wide }
enum AmmoMod { none, ricochet, explosive, pierce }
enum EchoBossKind { none, mini, ranged, knight, king }

/// Room events every 2–3 levels (Hades/Isaac style)
enum EventRoomType { none, altar, merchant, trap }

enum CodexId {
  shooter, melee, shielded, dog, shieldedShooter, flamer, sniper, brute,
  miniBoss, boss, knight, king, tentacle, cyclops, champion,
}

extension DiffLabel on Difficulty {
  String get labelRu {
    switch (this) {
      case Difficulty.easy: return 'Легко';
      case Difficulty.normal: return 'Норма';
      case Difficulty.hard: return 'Хард';
    }
  }
  double get hpMult {
    switch (this) {
      case Difficulty.easy: return 0.75;
      case Difficulty.normal: return 1.15;
      case Difficulty.hard: return 1.70;
    }
  }
  double get dmgMult {
    switch (this) {
      case Difficulty.easy: return 0.70;
      case Difficulty.normal: return 1.05;
      case Difficulty.hard: return 1.45;
    }
  }
  double get bossHpMult {
    switch (this) {
      case Difficulty.easy: return 0.80;
      case Difficulty.normal: return 1.20;
      case Difficulty.hard: return 1.85;
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
      case PlayerClass.xenos: return 'Охотник на ксеносов. Баланс HP/урона. Болтер и силовое оружие.';
      case PlayerClass.malleus: return 'Псайкер. −1 HP, +пси-урон, медленнее. Посох-волна и варп. Увеличенная дальность.';
      case PlayerClass.hereticus: return 'Ассасин. −1 HP, +скорость, рывок. Катана и кинжалы.';
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
      case RelicId.jediPath: return 'Путь Джедая';
    }
  }
  String get desc {
    switch (this) {
      case RelicId.crit: return '15% крит ×2';
      case RelicId.lifesteal: return '15% +1 HP при убийстве';
      case RelicId.shieldPierce: return 'Частичное пробитие щитов';
      case RelicId.killExplosion: return 'Взрыв при убийстве';
      case RelicId.haste: return '+12% скорость 3с после килла';
      case RelicId.jediPath: return 'Клинок сбивает пули и очищает зоны осквернения';
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
  String get desc {
    switch (this) {
      case ActiveArtifact.fragGrenade: return 'Взрыв по направлению прицела. CD 14с';
      case ActiveArtifact.holyAura: return '8с: −30% входящего, лёгкий DoT вокруг. CD 18с';
      case ActiveArtifact.servoTurret: return 'Турель 8с, стреляет по врагам и боссам. CD 16с';
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
      case CodexId.miniBoss: return 'Мини-босс культа';
      case CodexId.boss: return 'Чемпион ереси';
      case CodexId.knight: return 'Рыцарь-отступник';
      case CodexId.king: return 'Король еретиков';
      case CodexId.tentacle: return 'Тентаклевый ужас';
      case CodexId.cyclops: return 'Циклоп Варпа';
      case CodexId.champion: return 'Чемпион-элита';
    }
  }
  String get lore {
    switch (this) {
      case CodexId.shooter:
        return 'Бывшие гвардейцы, павшие в культ. Их «болтеры» кустарны, но яд на патронах разъедает броню веры.';
      case CodexId.melee:
        return 'Клинок — молитва Кхорну. Они идут в упор, не зная страха: смерть для них — дар.';
      case CodexId.shielded:
        return 'Щиты из обломков танков. Пуля рикошетит; только клинок Императора пробивает ересь насквозь.';
      case CodexId.dog:
        return 'Мутанты, вскормленные кровью рабов. Быстрее мысли, голоднее пустоты.';
      case CodexId.shieldedShooter:
        return 'Дисциплина предавших Адептус. Щит и очередь — тактика, которую Инквизиция сама когда-то учила.';
      case CodexId.flamer:
        return 'Прометий и молитвы Нурглу. Огонь очищает… или оскверняет. Разница — в имени, на которое молятся.';
      case CodexId.sniper:
        return 'Один выстрел — один труп. Они ждут в руинах, как пауки Варпа.';
      case CodexId.brute:
        return 'Плоть, раздутая варп-энергией. Удары крушат стены. Убить — значит раздавить гору.';
      case CodexId.miniBoss:
        return 'Лейтенант культа. Дробовик — приговор. Инквизиция помечает таких в Кодексе красной печатью.';
      case CodexId.boss:
        return 'Чемпион ереси. Залпы во все стороны — ритуал. Пока он жив, вера слабеет в радиусе крика.';
      case CodexId.knight:
        return 'Когда-то — Адептус Астартес. Теперь клинок служит Хаосу. Сближение смертельно.';
      case CodexId.king:
        return 'Владыка этажа. Пока живы его чемпионы — он неуязвим. Сломай свиту — сломай короля.';
      case CodexId.tentacle:
        return 'Порождение Варпа из-за печати. Тысячи щупалец, один глаз. Император не смотрит сюда.';
      case CodexId.cyclops:
        return 'Древний демон с одним оком. Луч из глаза прожигает танк. Стоять в углу — вызвать его.';
      case CodexId.champion:
        return 'Элита культа. Золотая печать над головой. Убей — и реликвия может пасть к ногам Инквизитора.';
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
        return '+2% урон в ближнем';
      case CodexId.shielded:
      case CodexId.shieldedShooter:
        return '+3% пробитие щитов';
      case CodexId.flamer:
        return '+1с к горению';
      case CodexId.champion:
        return '+5% обломков с элит';
      case CodexId.boss:
      case CodexId.knight:
      case CodexId.king:
      case CodexId.miniBoss:
        return '+3% урон боссам';
      case CodexId.tentacle:
      case CodexId.cyclops:
        return '+1 SP при убийстве секрета (уже учтено)';
    }
  }
}

/// Meta rank between runs
class InquisitionRank {
  int wins; // completed runs (victory or arena milestone)
  InquisitionRank({this.wins = 0});
  int get rank => (wins ~/ 2).clamp(0, 20); // rank 0–20
  double get critBonus => rank * 0.01; // +1% crit per rank
  int get startScraps => rank * 3; // +3 scraps per rank at run start
  String get title {
    if (rank <= 0) return 'Новичок';
    if (rank <= 3) return 'Адепт';
    if (rank <= 7) return 'Интеррогатор';
    if (rank <= 12) return 'Инквизитор';
    if (rank <= 16) return 'Лорд-Инквизитор';
    return 'Мастер Ордо';
  }
  Map<String, dynamic> toJson() => {'wins': wins};
  factory InquisitionRank.fromJson(Map<String, dynamic>? j) {
    if (j == null) return InquisitionRank();
    return InquisitionRank(wins: j['wins'] as int? ?? 0);
  }
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
    }
  }
}

class SkillTree {
  int hp; int speed; int attackSpeed; int defense; int damage;
  SkillTree({this.hp = 0, this.speed = 0, this.attackSpeed = 0, this.defense = 0, this.damage = 0});
  int get totalSpent => hp + speed + attackSpeed + defense + damage;
  Map<String, dynamic> toJson() => {'hp': hp, 'speed': speed, 'attackSpeed': attackSpeed, 'defense': defense, 'damage': damage};
  factory SkillTree.fromJson(Map<String, dynamic>? j) {
    if (j == null) return SkillTree();
    return SkillTree(hp: j['hp'] as int? ?? 0, speed: j['speed'] as int? ?? 0, attackSpeed: j['attackSpeed'] as int? ?? 0, defense: j['defense'] as int? ?? 0, damage: j['damage'] as int? ?? 0);
  }
}

class Customization {
  int armorHue; int capeHue; int weaponHue; int trimHue;
  Customization({this.armorHue = 210, this.capeHue = 0, this.weaponHue = 45, this.trimHue = 45});
  Color armorColor([double l = 0.28]) => HSLColor.fromAHSL(1, armorHue.toDouble(), 0.18, l).toColor();
  Color capeColor([double l = 0.28]) => HSLColor.fromAHSL(1, capeHue.toDouble(), 0.75, l).toColor();
  Color weaponColor([double l = 0.45]) => HSLColor.fromAHSL(1, weaponHue.toDouble(), 0.65, l).toColor();
  Color trimColor([double l = 0.55]) => HSLColor.fromAHSL(1, trimHue.toDouble(), 0.70, l).toColor();
  Map<String, dynamic> toJson() => {'armorHue': armorHue, 'capeHue': capeHue, 'weaponHue': weaponHue, 'trimHue': trimHue};
  factory Customization.fromJson(Map<String, dynamic>? j) {
    if (j == null) return Customization();
    return Customization(armorHue: j['armorHue'] as int? ?? 210, capeHue: j['capeHue'] as int? ?? 0, weaponHue: j['weaponHue'] as int? ?? 45, trimHue: j['trimHue'] as int? ?? 45);
  }
}

class WeaponLoadout {
  BarrelMod barrel; SightMod sight; AmmoMod ammo;
  WeaponLoadout({this.barrel = BarrelMod.none, this.sight = SightMod.none, this.ammo = AmmoMod.none});
  Map<String, dynamic> toJson() => {'barrel': barrel.name, 'sight': sight.name, 'ammo': ammo.name};
  factory WeaponLoadout.fromJson(Map<String, dynamic>? j) {
    if (j == null) return WeaponLoadout();
    return WeaponLoadout(
      barrel: BarrelMod.values.firstWhere((e) => e.name == j['barrel'], orElse: () => BarrelMod.none),
      sight: SightMod.values.firstWhere((e) => e.name == j['sight'], orElse: () => SightMod.none),
      ammo: AmmoMod.values.firstWhere((e) => e.name == j['ammo'], orElse: () => AmmoMod.none),
    );
  }
}

class HighScoreEntry {
  final String name; final int score; final int seconds; final int floor; final int level;
  final bool completed; final String difficulty; final bool arena; final String playerClass;
  HighScoreEntry(this.name, this.score, this.seconds, {this.floor = 1, this.level = 1, this.completed = false, this.difficulty = 'normal', this.arena = false, this.playerClass = 'xenos'});
  String get timeStr => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  String get progressStr {
    if (arena) return 'АРЕНА • ${difficulty.toUpperCase()} • $playerClass';
    if (completed) return 'ВСЁ • ${difficulty.toUpperCase()} • $playerClass';
    return 'Этаж $floor / Ур. $level';
  }
  Map<String, dynamic> toJson() => {'name': name, 'score': score, 'seconds': seconds, 'floor': floor, 'level': level, 'completed': completed, 'difficulty': difficulty, 'arena': arena, 'playerClass': playerClass};
  factory HighScoreEntry.fromJson(Map<String, dynamic> j) => HighScoreEntry(j['name'] as String? ?? '?', j['score'] as int? ?? 0, j['seconds'] as int? ?? 0, floor: j['floor'] as int? ?? 1, level: j['level'] as int? ?? 1, completed: j['completed'] as bool? ?? false, difficulty: j['difficulty'] as String? ?? 'normal', arena: j['arena'] as bool? ?? false, playerClass: j['playerClass'] as String? ?? 'xenos');
}

class GameSave {
  final String name; final int floor, level, score, health, maxHealth, scraps;
  final int bolterDamage, rifleDamage, shotgunDamage, swordDamage, axeDamage, hammerDamage;
  final double playerSpeed, defenseChance;
  final String ranged, melee; final bool usingMelee, hasDash, hasLaser, ever11, ever21;
  final int playSeconds; final String dateIso; final String difficulty;
  final bool arenaMode; final int arenaKills, skillPoints;
  final Map<String, dynamic> skills, custom; final String playerClass; final List<String> relics;
  final String artifact; final Map<String, dynamic> loadout; final List<String> codex;
  final String lastEcho;

  GameSave({
    required this.name, required this.floor, required this.level, required this.score,
    required this.health, required this.maxHealth, required this.scraps,
    required this.bolterDamage, required this.rifleDamage, required this.shotgunDamage,
    required this.swordDamage, required this.axeDamage, required this.hammerDamage,
    required this.playerSpeed, required this.defenseChance, required this.ranged, required this.melee,
    required this.usingMelee, required this.hasDash, required this.hasLaser, required this.ever11, required this.ever21,
    required this.playSeconds, required this.dateIso, this.difficulty = 'normal', this.arenaMode = false,
    this.arenaKills = 0, this.skillPoints = 0, this.skills = const {}, this.custom = const {},
    this.playerClass = 'xenos', this.relics = const [], this.artifact = 'fragGrenade',
    this.loadout = const {}, this.codex = const [], this.lastEcho = 'none',
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'floor': floor, 'level': level, 'score': score, 'health': health, 'maxHealth': maxHealth, 'scraps': scraps,
    'bolterDamage': bolterDamage, 'rifleDamage': rifleDamage, 'shotgunDamage': shotgunDamage,
    'swordDamage': swordDamage, 'axeDamage': axeDamage, 'hammerDamage': hammerDamage,
    'playerSpeed': playerSpeed, 'defenseChance': defenseChance, 'ranged': ranged, 'melee': melee,
    'usingMelee': usingMelee, 'hasDash': hasDash, 'hasLaser': hasLaser, 'ever11': ever11, 'ever21': ever21,
    'playSeconds': playSeconds, 'dateIso': dateIso, 'difficulty': difficulty, 'arenaMode': arenaMode,
    'arenaKills': arenaKills, 'skillPoints': skillPoints, 'skills': skills, 'custom': custom,
    'playerClass': playerClass, 'relics': relics, 'artifact': artifact, 'loadout': loadout, 'codex': codex,
    'lastEcho': lastEcho,
  };

  factory GameSave.fromJson(Map<String, dynamic> j) => GameSave(
    name: j['name'] as String? ?? 'Inquisitor', floor: j['floor'] as int? ?? 1, level: j['level'] as int? ?? 1,
    score: j['score'] as int? ?? 0, health: j['health'] as int? ?? 6, maxHealth: j['maxHealth'] as int? ?? 6,
    scraps: j['scraps'] as int? ?? 0, bolterDamage: j['bolterDamage'] as int? ?? 8, rifleDamage: j['rifleDamage'] as int? ?? 18,
    shotgunDamage: j['shotgunDamage'] as int? ?? 10, swordDamage: j['swordDamage'] as int? ?? 12, axeDamage: j['axeDamage'] as int? ?? 14,
    hammerDamage: j['hammerDamage'] as int? ?? 28, playerSpeed: (j['playerSpeed'] as num?)?.toDouble() ?? 210,
    defenseChance: (j['defenseChance'] as num?)?.toDouble() ?? 0, ranged: j['ranged'] as String? ?? 'bolter',
    melee: j['melee'] as String? ?? 'sword', usingMelee: j['usingMelee'] as bool? ?? false,
    hasDash: j['hasDash'] as bool? ?? false, hasLaser: j['hasLaser'] as bool? ?? false,
    ever11: j['ever11'] as bool? ?? false, ever21: j['ever21'] as bool? ?? false,
    playSeconds: j['playSeconds'] as int? ?? 0, dateIso: j['dateIso'] as String? ?? '',
    difficulty: j['difficulty'] as String? ?? 'normal', arenaMode: j['arenaMode'] as bool? ?? false,
    arenaKills: j['arenaKills'] as int? ?? 0, skillPoints: j['skillPoints'] as int? ?? 0,
    skills: Map<String, dynamic>.from(j['skills'] as Map? ?? {}), custom: Map<String, dynamic>.from(j['custom'] as Map? ?? {}),
    playerClass: j['playerClass'] as String? ?? 'xenos', relics: (j['relics'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    artifact: j['artifact'] as String? ?? 'fragGrenade',
    loadout: Map<String, dynamic>.from(j['loadout'] as Map? ?? {}),
    codex: (j['codex'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    lastEcho: j['lastEcho'] as String? ?? 'none',
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

class DamageNumber extends PositionComponent {
  final int amount; final Color color; double life = 0.85; double vy = -55;
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
  BloodSplash({required Vector2 position, int count = 14}) : super(position: position.clone(), priority: 8) {
    final rnd = Random();
    for (int i = 0; i < count; i++) {
      final a = rnd.nextDouble() * 2 * pi;
      final sp = 40 + rnd.nextDouble() * 120;
      drops.add(_Drop(offset: Vector2.zero(), vel: Vector2(cos(a), sin(a)) * sp, radius: 2 + rnd.nextDouble() * 4.5, dark: rnd.nextBool()));
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
  Vector2 offset; Vector2 vel; double radius; bool dark;
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

class TelegraphZone extends PositionComponent {
  final String shape;
  final double radius;
  final double angle;
  double life;
  final double maxLife;
  TelegraphZone({
    required Vector2 position,
    required this.shape,
    required this.radius,
    this.angle = 0,
    this.life = 0.75,
  })  : maxLife = life,
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
      ..color = Color.fromRGBO(255, 30, 30, a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fill = Paint()..color = Color.fromRGBO(255, 0, 0, a * 0.25);
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
  }
}

/// Purple DoT puddle left by bosses — clean with Jedi Path melee
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
      if (game.isPlaying && !game.isPaused) {
        if (position.distanceTo(game.player.position) < 48) {
          game.player.applyStatus(StatusType.corruption, 1.2, tickDamage: 1);
          game.player.takeDamage(1);
        }
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

  static void inquisitor(Canvas c, {required double cx, required double cy, double s = 1.32, double flash = 0, Customization? custom, PlayerClass cls = PlayerClass.xenos}) {
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
    c.drawArc(Rect.fromCircle(center: Offset(cx - 24 * s, cy - 4 * s), radius: 15 * s), pi, pi, false, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 2.2 * s);
    c.drawArc(Rect.fromCircle(center: Offset(cx + 24 * s, cy - 4 * s), radius: 15 * s), pi, pi, false, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 2.2 * s);

    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 28 * s, cy + 16 * s), width: 12 * s, height: 24 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 28 * s, cy + 16 * s), width: 12 * s, height: 24 * s), Radius.circular(2 * s)), Paint()..color = armor);

    c.drawCircle(Offset(cx, cy - 18 * s), 13 * s, Paint()..color = const Color(0xFFC4A484));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 22 * s), width: 26 * s, height: 12 * s), Radius.circular(2 * s)), Paint()..color = dark);
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 19 * s), width: 16 * s, height: 4 * s), Paint()..color = visor.withOpacity(0.95));

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
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 2), width: 54, height: 30), Paint()..color = const Color(0xFF2D1F14));
    c.drawOval(Rect.fromCenter(center: Offset(cx - 4, cy), width: 40, height: 22), Paint()..color = const Color(0xFF3E2723));
    c.drawOval(Rect.fromCenter(center: Offset(cx + 24, cy - 8), width: 30, height: 24), Paint()..color = const Color(0xFF3E2723));
    c.drawOval(Rect.fromCenter(center: Offset(cx + 30, cy - 2), width: 16, height: 10), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx + 28, cy - 12), 4.5, Paint()..color = const Color(0xFFFFFDE7));
    c.drawCircle(Offset(cx + 28, cy - 12), 2, Paint()..color = const Color(0xFFB71C1C));
    for (final lx in [-16.0, -4.0, 8.0, 18.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + lx, cy + 16), width: 6, height: 14), const Radius.circular(2)),
        Paint()..color = const Color(0xFF2D1F14),
      );
    }
    for (int i = 0; i < 4; i++) {
      c.drawLine(
        Offset(cx - 12.0 + i * 8, cy - 8),
        Offset(cx - 10.0 + i * 8, cy - 18),
        Paint()..color = const Color(0xFF5D4037)..strokeWidth = 2,
      );
    }
    if (flash > 0) {
      c.drawCircle(Offset(cx, cy), 32, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
    }
  }

  static void cultistShooter(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 7 * s, cy + 22 * s), width: 10 * s, height: 18 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 7 * s, cy + 22 * s), width: 10 * s, height: 18 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 26 * s, height: 28 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 14 * s), 11 * s, Paint()..color = const Color(0xFF37474F));
    c.drawArc(Rect.fromCircle(center: Offset(cx, cy - 14 * s), radius: 12 * s), pi, pi, false, Paint()..color = const Color(0xFF2E7D32));
    bolter(c, cx + 2 * s, cy + 2 * s, s * 0.78);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void cultistMelee(Canvas c, double cx, double cy, double s, {double flash = 0}) {
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

  static void cyclops(Canvas c, double cx, double cy, double s, {double flash = 0, double charge = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10 * s), width: 74 * s, height: 84 * s), Paint()..color = const Color(0xFF3E2723));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 56 * s, height: 64 * s), Paint()..color = const Color(0xFF5D4037));
    c.drawCircle(Offset(cx, cy - 22 * s), 30 * s, Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 24 * s), 16 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 24 * s), 12 * s, Paint()..color = Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFF1744), charge)!);
    c.drawCircle(Offset(cx, cy - 24 * s), 5 * s, Paint()..color = Colors.white);
    c.drawLine(Offset(cx - 18 * s, cy - 38 * s), Offset(cx - 32 * s, cy - 60 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 6 * s);
    c.drawLine(Offset(cx + 18 * s, cy - 38 * s), Offset(cx + 32 * s, cy - 60 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 6 * s);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 62 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void statusIcons(Canvas c, double cx, double topY, List<StatusEffect> effects) {
    double x = cx - effects.length * 6.0;
    for (final e in effects) {
      c.drawCircle(Offset(x, topY), 5, Paint()..color = e.color);
      x += 12;
    }
  }

  static void championMark(Canvas c, double cx, double topY) {
    final path = Path()
      ..moveTo(cx, topY - 10)
      ..lineTo(cx + 7, topY)
      ..lineTo(cx, topY + 4)
      ..lineTo(cx - 7, topY)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFFFFD700));
    c.drawPath(path, Paint()..color = const Color(0xFFFF8F00)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  /// Visual marker for event props
  static void altar(Canvas c, double cx, double cy) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 10), width: 50, height: 28), const Radius.circular(4)), Paint()..color = const Color(0xFF5D4037));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 4), width: 36, height: 20), const Radius.circular(3)), Paint()..color = const Color(0xFF8D6E63));
    c.drawCircle(Offset(cx, cy - 18), 10, Paint()..color = const Color(0xFFFFD700).withOpacity(0.8));
  }

  static void merchantStall(Canvas c, double cx, double cy) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 56, height: 32), const Radius.circular(3)), Paint()..color = const Color(0xFF4E342E));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 10), width: 48, height: 16), const Radius.circular(2)), Paint()..color = const Color(0xFFB8860B));
    c.drawCircle(Offset(cx - 10, cy + 4), 5, Paint()..color = const Color(0xFFFFD700));
    c.drawCircle(Offset(cx + 10, cy + 4), 5, Paint()..color = const Color(0xFF90CAF9));
  }
}
class InquisitorGame extends FlameGame with HasCollisionDetection {
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
  WeaponLoadout loadout = WeaponLoadout();
  ActiveArtifact activeArtifact = ActiveArtifact.fragGrenade;
  double artifactCooldown = 0;
  double holyAuraTimer = 0;

  /// Meta rank (persisted between runs)
  InquisitionRank inquisitionRank = InquisitionRank();

  /// Event room for current level
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

  bool arenaMode = false;
  int arenaKills = 0;
  int arenaWave = 1;

  int currentFloor = 1;
  int currentLevel = 1;
  int enemiesAlive = 0;
  int enemiesToSpawn = 0;
  int enemiesSpawned = 0;

  bool portalSpawned = false;
  bool isBossLevel = false;
  bool isMiniBossLevel = false;
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

  bool get unlockedBarrelMods => currentFloor >= 2 || _everReached11;
  bool get unlockedSightMods => currentFloor >= 3 || _everReached11;
  bool get unlockedAmmoMods => currentFloor >= 4 || _everReached21;

  AudioPlayer? _bgmPlayer;
  final List<AudioPlayer> _sfxPool = [];
  static const int _sfxPoolSize = 8;
  int _sfxIdx = 0;

  final TextPaint hudPaint = TextPaint(style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));

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

  double get worldThreat => 1.0 + overallLevel * 0.06 + skills.totalSpent * 0.02;
  double get comboMult => (1.0 + (combo.clamp(0, 12) * 0.08)).clamp(1.0, 2.0);
  bool get hasCrit => relics.contains(RelicId.crit);
  bool get hasLifesteal => relics.contains(RelicId.lifesteal);
  bool get hasShieldPierce => relics.contains(RelicId.shieldPierce);
  bool get hasKillExplosion => relics.contains(RelicId.killExplosion);
  bool get hasHaste => relics.contains(RelicId.haste);
  bool get hasJediPath => relics.contains(RelicId.jediPath);

  bool get synergyFireCrits => hasCrit && hasKillExplosion;
  bool get synergyBloodRush => hasLifesteal && hasHaste;
  bool get synergyTrueFaith => hasShieldPierce && hasCrit;
  bool get synergyXenosBlast =>
      playerClass == PlayerClass.xenos &&
      rangedWeapon == RangedWeapon.shotgun &&
      loadout.ammo == AmmoMod.explosive &&
      !usingMelee;
  bool get synergyHereticusBleedDash =>
      playerClass == PlayerClass.hereticus &&
      usingMelee &&
      (meleeWeapon == MeleeWeapon.katana ||
          meleeWeapon == MeleeWeapon.powerKatana ||
          meleeWeapon == MeleeWeapon.executioner);

  String? get activeSynergyLabel {
    final parts = <String>[];
    if (synergyFireCrits) parts.add('Огненный крит');
    if (synergyBloodRush) parts.add('Кровавый рывок');
    if (synergyTrueFaith) parts.add('Истинная вера');
    if (synergyXenosBlast) parts.add('Прометий-конус');
    if (synergyHereticusBleedDash) parts.add('Кровавый след');
    if (hasJediPath) parts.add('Путь Джедая');
    return parts.isEmpty ? null : parts.join(' • ');
  }

  double get codexRangedBonus =>
      (codexUnlocked.contains(CodexId.shooter) ? 0.02 : 0) + (codexUnlocked.contains(CodexId.sniper) ? 0.02 : 0);
  double get codexMeleeBonus =>
      (codexUnlocked.contains(CodexId.melee) ? 0.02 : 0) +
      (codexUnlocked.contains(CodexId.dog) ? 0.02 : 0) +
      (codexUnlocked.contains(CodexId.brute) ? 0.02 : 0);
  double get codexShieldBonus =>
      (codexUnlocked.contains(CodexId.shielded) ? 0.03 : 0) + (codexUnlocked.contains(CodexId.shieldedShooter) ? 0.03 : 0);
  double get codexBossBonus =>
      [CodexId.miniBoss, CodexId.boss, CodexId.knight, CodexId.king].where(codexUnlocked.contains).length * 0.03;
  double get codexEliteScrapBonus => codexUnlocked.contains(CodexId.champion) ? 0.05 : 0;
  double get codexBurnBonus => codexUnlocked.contains(CodexId.flamer) ? 1.0 : 0.0;

  void unlockCodex(CodexId id) {
    if (codexUnlocked.add(id) && isPlaying) {
      world.add(DamageNumber(position: player.position + Vector2(0, -40), amount: 0, color: const Color(0xFFFFD700), label: 'CODEX'));
    }
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
    maxHealth = (baseMaxHealth + skills.hp + playerClass.hpMod).clamp(3, 99);
    playerSpeed = baseSpeed + skills.speed * 12.0 + playerClass.speedMod;
    defenseChance = min(0.45, skills.defense * 0.03);
    var aspd = max(0.55, 1.0 - skills.attackSpeed * 0.04);
    if (loadout.barrel == BarrelMod.rapid) aspd *= 0.88;
    if (loadout.barrel == BarrelMod.heavy) aspd *= 1.12;
    attackSpeedMult = aspd;
    final dmgM = (1.0 + skills.damage * 0.06) * playerClass.dmgMod;
    double rangedM = dmgM * (1 + codexRangedBonus);
    double meleeM = dmgM * (1 + codexMeleeBonus);
    if (loadout.barrel == BarrelMod.heavy) rangedM *= 1.18;
    if (loadout.sight == SightMod.precision) rangedM *= 1.10;
    bolterDamage = (baseBolter * rangedM).round();
    rifleDamage = (baseRifle * rangedM).round();
    shotgunDamage = (baseShotgun * rangedM).round();
    staffDamage = (baseStaff * rangedM).round();
    stormDamage = (baseStorm * rangedM).round();
    warpDamage = (baseWarp * rangedM).round();
    daggerDamage = (baseDagger * rangedM).round();
    needleDamage = (baseNeedle * rangedM).round();
    sniperNeedleDamage = (baseSniperNeedle * rangedM).round();
    swordDamage = (baseSword * meleeM).round();
    axeDamage = (baseAxe * meleeM).round();
    hammerDamage = (baseHammer * meleeM).round();
    forceDamage = (baseForce * meleeM).round();
    forceSwordDamage = (baseForceSword * meleeM).round();
    daemonDamage = (baseDaemon * meleeM).round();
    katanaDamage = (baseKatana * meleeM).round();
    powerKatanaDamage = (basePowerKatana * meleeM).round();
    execDamage = (baseExec * meleeM).round();
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

  void grantRelic(RelicId id) => relics.add(id);

  bool tryCrit() {
    final chance = (hasCrit ? (synergyTrueFaith ? 0.18 : 0.15) : 0.0) + inquisitionRank.critBonus;
    return chance > 0 && Random().nextDouble() < chance;
  }

  int scaleDamage(int base, {bool isBoss = false}) {
    var d = (base * tempDmgMult).round();
    if (isBoss) d = (d * (1 + codexBossBonus)).round();
    if (tryCrit()) d *= 2;
    return d;
  }

  void _checkUnlocks() {
    if (overallLevel >= 11) _everReached11 = true;
    if (overallLevel >= 21) _everReached21 = true;
  }

  void spawnDamageNumber(Vector2 pos, int amount, {Color color = const Color(0xFFFFEB3B), String? label}) {
    if (amount <= 0 && label == null) return;
    world.add(DamageNumber(position: pos + Vector2(0, -20), amount: amount, color: color, label: label));
  }

  void spawnBlood(Vector2 pos, {int count = 14}) => world.add(BloodSplash(position: pos, count: count));

  void spawnCorruptionZone(Vector2 pos) {
    if (arenaMode) return;
    world.add(CorruptionZone(position: pos.clone())..priority = 4);
  }

  void triggerShake({double power = 6, double time = 0.18}) {
    shakePower = max(shakePower, power);
    shakeTime = max(shakeTime, time);
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

  void registerKill({Vector2? at, bool isBoss = false, bool isChampion = false, bool meleeKill = false}) {
    combo++;
    comboTimer = comboWindow;
    for (final m in [5, 10, 15]) {
      if (combo >= m && !_comboMilestonesClaimed.contains(m)) {
        _comboMilestonesClaimed.add(m);
        scraps += 1;
        if (at != null) spawnDamageNumber(at + Vector2(0, -36), 0, color: const Color(0xFFFFD700), label: 'COMBO +1');
      }
    }
    if (combo >= 3 && combo % 3 == 0) camera.viewport.add(ComboBanner(combo: combo));
    if (at != null) {
      spawnBlood(at, count: isBoss || isChampion ? 28 : 14);
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
      hasDashAbility = true;
      _ensureDashButton();
      dashCooldown = min(dashCooldown, 1.0);
    }
    var gain = isBoss ? (8 + Random().nextInt(8)) : (isChampion ? (5 + Random().nextInt(5)) : (1 + Random().nextInt(3)));
    if (isChampion) gain = (gain * (1 + codexEliteScrapBonus)).round();
    scraps += gain;
    if (isChampion && Random().nextDouble() < 0.22) {
      final missing = RelicId.values.where((r) => !relics.contains(r)).toList();
      if (missing.isNotEmpty) grantRelic(missing[Random().nextInt(missing.length)]);
    }
  }

  void rememberBossEcho(EchoBossKind kind) {
    pendingEcho = kind;
  }

  /// Pick event every 2–3 combat levels (not boss/mini)
  EventRoomType _rollEvent() {
    levelsSinceEvent++;
    if (isBossLevel || isMiniBossLevel || arenaMode) return EventRoomType.none;
    if (levelsSinceEvent < 2) return EventRoomType.none;
    if (levelsSinceEvent >= 3 || Random().nextDouble() < 0.55) {
      levelsSinceEvent = 0;
      final r = Random().nextDouble();
      if (r < 0.34) return EventRoomType.altar;
      if (r < 0.67) return EventRoomType.merchant;
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
        // trap starts after short delay via update / on level start
        break;
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
    if (accept) {
      if (player.health > 1) {
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
    final n = 4 + currentFloor;
    for (int i = 0; i < n; i++) {
      enemiesToSpawn++;
      enemiesAlive++;
      enemiesSpawned++;
      final points = getEnemySpawnPoints();
      if (points.isEmpty) continue;
      final e = Enemy(floor: currentFloor, type: _chooseEnemyType(), isChampion: i == 0 && overallLevel >= 5);
      e.position = points[Random().nextInt(points.length)].clone();
      e.priority = 30;
      world.add(e);
    }
    spawnDamageNumber(player.position, 0, color: const Color(0xFFFF1744), label: 'ЗАСАДА!');
    triggerShake(power: 8, time: 0.25);
  }

  Future<void> recordVictoryRank() async {
    inquisitionRank.wins++;
    await persistRank();
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
      if (cu != null) {
        custom = Customization.fromJson(Map<String, dynamic>.from(jsonDecode(cu) as Map));
      }
      final cx = prefs.getString('codex');
      if (cx != null) {
        final list = (jsonDecode(cx) as List).map((e) => e.toString());
        codexUnlocked.addAll(
          list.map((n) => CodexId.values.firstWhere((e) => e.name == n, orElse: () => CodexId.shooter)),
        );
      }
      final rk = prefs.getString('inquisition_rank');
      if (rk != null) {
        inquisitionRank = InquisitionRank.fromJson(Map<String, dynamic>.from(jsonDecode(rk) as Map));
      }
    } catch (_) {}
  }

  Future<void> persistRank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inquisition_rank', jsonEncode(inquisitionRank.toJson()));
    } catch (_) {}
  }

  Future<void> persistCustomization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customization', jsonEncode(custom.toJson()));
      await prefs.setString('codex', jsonEncode(codexUnlocked.map((e) => e.name).toList()));
      await prefs.setString('inquisition_rank', jsonEncode(inquisitionRank.toJson()));
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
      custom: custom.toJson(),
      playerClass: playerClass.name,
      relics: relics.map((e) => e.name).toList(),
      artifact: activeArtifact.name,
      loadout: loadout.toJson(),
      codex: codexUnlocked.map((e) => e.name).toList(),
      lastEcho: pendingEcho.name,
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
    score = s.score;
    scraps = s.scraps;
    skills = SkillTree.fromJson(s.skills);
    skillPoints = s.skillPoints;
    custom = Customization.fromJson(s.custom);
    playerClass = PlayerClass.values.firstWhere((e) => e.name == s.playerClass, orElse: () => PlayerClass.xenos);
    relics
      ..clear()
      ..addAll(s.relics.map((n) => RelicId.values.firstWhere((e) => e.name == n, orElse: () => RelicId.crit)));
    codexUnlocked
      ..clear()
      ..addAll(s.codex.map((n) => CodexId.values.firstWhere((e) => e.name == n, orElse: () => CodexId.shooter)));
    loadout = WeaponLoadout.fromJson(s.loadout);
    activeArtifact = ActiveArtifact.values.firstWhere((e) => e.name == s.artifact, orElse: () => ActiveArtifact.fragGrenade);
    pendingEcho = EchoBossKind.values.firstWhere((e) => e.name == s.lastEcho, orElse: () => EchoBossKind.none);
    recomputeStats();
    rangedWeapon = RangedWeapon.values.firstWhere((e) => e.name == s.ranged, orElse: () => RangedWeapon.bolter);
    meleeWeapon = MeleeWeapon.values.firstWhere((e) => e.name == s.melee, orElse: () => MeleeWeapon.sword);
    usingMelee = s.usingMelee;
    hasDashAbility = s.hasDash || playerClass == PlayerClass.hereticus;
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
    portalSpawned = false;
    nearPortal = false;
    secretBossUnlockedThisLevel = false;
    secretBossSpawned = false;
    cornerStandTimer = 0;
    dashCooldown = 0;
    dashActive = 0;
    laserCooldown = 0;
    artifactCooldown = 0;
    holyAuraTimer = 0;
    invulnTimer = 0;
    hereticusDashBoost = 0;
    combo = 0;
    comboTimer = 0;
    _comboMilestonesClaimed.clear();
    tempDmgMult = 1.0;
    tempDmgTimer = 0;
    shieldTimer = 0;
    _hasteTimer = 0;
    currentEvent = EventRoomType.none;
    eventResolved = true;
    currentZoom = 0.85;
    _clearEverything();
    if (arenaMode) {
      _startArenaLevel();
    } else {
      _startLevel();
    }
    player.health = s.health.clamp(1, maxHealth);
    player.maxHealth = maxHealth;
    for (final o in [
      'mainMenu', 'loadSave', 'settings', 'nameInput', 'classSelect', 'gameOver',
      'levelComplete', 'skills', 'reward', 'shop', 'victory', 'records', 'backpack',
      'codex', 'eventAltar', 'eventMerchant',
    ]) {
      overlays.remove(o);
    }
    startMusic();
  }

  void addScoreEntry({bool completed = false, bool fromArena = false}) {
    playSeconds = _currentPlaySeconds();
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
    ));
    highScores.sort((a, b) => b.score.compareTo(a.score));
    if (highScores.length > 15) highScores = highScores.take(15).toList();
    _persistScores();
  }
    List<Vector2> getEnemySpawnPointsRaw() {
    final cx = mapWidth / 2, cy = mapHeight / 2;
    switch (currentFloor) {
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

    _checkUnlocks();
    recomputeStats();
    isBossLevel = currentLevel == 5;
    isMiniBossLevel = [3].contains(currentLevel);
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

    currentEvent = _rollEvent();
    eventResolved = currentEvent == EventRoomType.none;

    final wallColor = Color.lerp(const Color(0xFF5D4037), const Color(0xFF3E2723), (currentFloor - 1) / 4)!;
    world.add(Floor(size: Vector2(mapWidth, mapHeight)));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, mapHeight - 70), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(Wall(position: Vector2(mapWidth - 70, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(PlayerSpawnPoint(position: playerSpawnPos));

    final rng = Random(currentFloor * 100 + currentLevel * 13);
    final obstacleCount = 5 + currentFloor * 2 + currentLevel;
    int placed = 0, attempts = 0;
    while (placed < obstacleCount && attempts < 120) {
      attempts++;
      final x = 140.0 + rng.nextDouble() * (mapWidth - 280);
      final y = 140.0 + rng.nextDouble() * (mapHeight - 280);
      final pos = Vector2(x, y);
      if (pos.distanceTo(playerSpawnPos) < safeRadius + 40) continue;
      if (getEnemySpawnPointsRaw().any((s) => s.distanceTo(pos) < 90)) continue;
      world.add(Obstacle(position: pos));
      placed++;
    }

    if (!isBossLevel && !isMiniBossLevel) {
      for (int i = 0; i < 1 + rng.nextInt(2); i++) {
        final p = Vector2(140 + rng.nextDouble() * (mapWidth - 280), 140 + rng.nextDouble() * (mapHeight - 280));
        if (p.distanceTo(playerSpawnPos) > 150) world.add(MedkitPickup(position: p));
      }
      if (rng.nextDouble() < 0.35) {
        final p = Vector2(140 + rng.nextDouble() * (mapWidth - 280), 140 + rng.nextDouble() * (mapHeight - 280));
        if (p.distanceTo(playerSpawnPos) > 150) world.add(ShieldPickup(position: p));
      }
    }

    final baseCount = 3 + currentFloor + currentLevel + (overallLevel ~/ 5);
    enemiesToSpawn = isBossLevel ? 0 : (isMiniBossLevel ? (baseCount / 2).ceil() : baseCount);
    if (difficulty == Difficulty.hard) enemiesToSpawn = (enemiesToSpawn * 1.2).ceil();
    enemiesAlive = enemiesToSpawn;
    enemiesSpawned = 0;
    spawnTimer = 0.4;
    spawnInterval = max(0.45, 1.15 - currentFloor * 0.08 - currentLevel * 0.04);

    if (isBossLevel) {
      enemiesAlive = 1;
      enemiesToSpawn = 1;
      enemiesSpawned = 1;
      final bossPos = Vector2(mapWidth / 2, mapHeight / 2 - 260);
      if (currentFloor == 5) {
        enemiesAlive = 3;
        enemiesToSpawn = 3;
        world.add(Boss(floor: currentFloor, position: bossPos + Vector2(-170, 0))..priority = 25);
        world.add(KnightBoss(floor: currentFloor, position: bossPos + Vector2(170, 0))..priority = 25);
        world.add(KingBoss(position: bossPos)..priority = 26);
      } else if (currentFloor >= 3) {
        enemiesAlive = 2;
        enemiesToSpawn = 2;
        world.add(Boss(floor: currentFloor, position: bossPos + Vector2(-120, 0))..priority = 25);
        world.add(KnightBoss(floor: currentFloor, position: bossPos + Vector2(120, 0))..priority = 25);
      } else {
        world.add(Boss(floor: currentFloor, position: bossPos)..priority = 25);
      }
    } else if (isMiniBossLevel) {
      world.add(MiniBoss(floor: currentFloor, position: Vector2(mapWidth / 2, mapHeight / 2 - 280))..priority = 24);
      enemiesAlive++;
      enemiesToSpawn++;
      enemiesSpawned++;
    }

    _maybeSpawnEcho();
    _spawnEventProps();

    moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.35, paint: Paint()..color = Colors.white54),
      background: CircleComponent(radius: joystickSize * 0.55, paint: Paint()..color = Colors.white24),
      margin: const EdgeInsets.only(left: 28, bottom: 28),
    );
    attackJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.35, paint: Paint()..color = const Color(0xFFFF5252).withOpacity(0.8)),
      background: CircleComponent(radius: joystickSize * 0.55, paint: Paint()..color = const Color(0xFFFF5252).withOpacity(0.25)),
      margin: const EdgeInsets.only(right: 28, bottom: 28),
    );
    switchWeaponButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.55, paint: Paint()..color = const Color(0xFFB8860B)),
      buttonDown: CircleComponent(radius: buttonSize * 0.55, paint: Paint()..color = const Color(0xFFFFD700)),
      margin: const EdgeInsets.only(right: 28, bottom: 150),
      onPressed: () {
        usingMelee = !usingMelee;
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
    world.add(player);
    camera.follow(player);

    camera.viewport.add(moveJoystick);
    camera.viewport.add(attackJoystick);
    camera.viewport.add(switchWeaponButton);
    camera.viewport.add(settingsButton);
    camera.viewport.add(backpackButton);
    camera.viewport.add(zoomInButton);
    camera.viewport.add(zoomOutButton);
    camera.viewport.add(HudLabel(text: 'M', margin: const EdgeInsets.only(left: 58, bottom: 58)));
    camera.viewport.add(HudLabel(text: 'F', margin: const EdgeInsets.only(right: 58, bottom: 58)));
    camera.viewport.add(HudLabel(text: 'A', margin: const EdgeInsets.only(right: 38, bottom: 162)));
    camera.viewport.add(HudLabel(text: 'S', margin: const EdgeInsets.only(right: 22, top: 22)));
    camera.viewport.add(HudLabel(text: 'B', margin: const EdgeInsets.only(right: 74, top: 22)));
    camera.viewport.add(HudLabel(text: '+', margin: const EdgeInsets.only(left: 22, top: 22)));
    camera.viewport.add(HudLabel(text: '-', margin: const EdgeInsets.only(left: 66, top: 22)));
    _ensureDashButton();
    _ensureLaserButton();
    _ensureArtifactButton();

    // Trap event: delayed wave
    if (currentEvent == EventRoomType.trap) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (isPlaying && !eventResolved && currentEvent == EventRoomType.trap) {
          _startTrapWave();
        }
      });
    }
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
      case EchoBossKind.none:
        break;
    }
    spawnDamageNumber(pos, 0, color: const Color(0xFF9C27B0), label: 'ЭХО');
    pendingEcho = EchoBossKind.none;
  }

  void _startArenaLevel() {
    world.removeAll(world.children.toList());
    camera.viewport.children.whereType<HudLabel>().toList().forEach((c) => c.removeFromParent());
    portalButton?.removeFromParent();
    portalButton = null;
    currentEvent = EventRoomType.none;
    eventResolved = true;
    world.add(Floor(size: Vector2(mapWidth, mapHeight)));
    final wallColor = const Color(0xFF4A148C);
    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, mapHeight - 70), size: Vector2(mapWidth, 70), color: wallColor));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(Wall(position: Vector2(mapWidth - 70, 0), size: Vector2(70, mapHeight), color: wallColor));
    world.add(PlayerSpawnPoint(position: playerSpawnPos));
    enemiesToSpawn = 6 + arenaWave;
    enemiesAlive = enemiesToSpawn;
    enemiesSpawned = 0;
    spawnTimer = 0.3;
    spawnInterval = max(0.35, 0.9 - arenaWave * 0.02);
    portalSpawned = false;
    isBossLevel = false;
    isMiniBossLevel = false;
    recomputeStats();
    player = Player(moveJoystick)..priority = 20;
    player.maxHealth = maxHealth;
    player.health = maxHealth;
    world.add(player);
    camera.follow(player);
    camera.viewport.add(moveJoystick);
    camera.viewport.add(attackJoystick);
    camera.viewport.add(switchWeaponButton);
    camera.viewport.add(settingsButton);
    camera.viewport.add(backpackButton);
    camera.viewport.add(zoomInButton);
    camera.viewport.add(zoomOutButton);
    _ensureDashButton();
    _ensureLaserButton();
    _ensureArtifactButton();
  }

  void _ensureDashButton() {
    if (!hasDashAbility || dashButton != null) return;
    dashButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = const Color(0xFF00838F)),
      margin: const EdgeInsets.only(right: 116, top: 12),
      onPressed: activateDash,
    );
    camera.viewport.add(dashButton!);
    camera.viewport.add(HudLabel(text: 'U', margin: const EdgeInsets.only(right: 126, top: 22)));
  }

  void _ensureLaserButton() {
    if (!hasLaserAbility || laserButton != null) return;
    laserButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = const Color(0xFFE65100)),
      margin: const EdgeInsets.only(right: 168, top: 12),
      onPressed: activateLaser,
    );
    camera.viewport.add(laserButton!);
    camera.viewport.add(HudLabel(text: 'L', margin: const EdgeInsets.only(right: 178, top: 22)));
  }

  void _ensureArtifactButton() {
    if (artifactButton != null) return;
    artifactButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize * 0.45, paint: Paint()..color = const Color(0xFFBF360C)),
      margin: const EdgeInsets.only(right: 220, top: 12),
      onPressed: activateArtifact,
    );
    camera.viewport.add(artifactButton!);
    camera.viewport.add(HudLabel(text: 'R', margin: const EdgeInsets.only(right: 230, top: 22)));
  }

  void activateDash() {
    if (!hasDashAbility || dashCooldown > 0 || dashActive > 0 || !isPlaying || isPaused) return;
    final boost = hereticusDashBoost > 0;
    dashActive = (playerClass == PlayerClass.hereticus ? 2.6 : 2.0) + (boost ? 0.8 : 0);
    dashCooldown = (playerClass == PlayerClass.hereticus ? 5.0 : 6.0) - (boost ? 1.5 : 0);
    if (boost) hereticusDashBoost = 0;
    grantInvuln(0.25);
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
    final r = Random().nextDouble();
    if (overallLevel >= 18 && r < 0.10) return EnemyType.brute;
    if (overallLevel >= 14 && r < 0.18) return EnemyType.sniper;
    if (overallLevel >= 12 && r < 0.28) return EnemyType.flamer;
    if (overallLevel >= 20 && r < 0.42) return EnemyType.shieldedShooter;
    if (overallLevel >= 11 && r < 0.55) return EnemyType.dog;
    if (r < 0.38) return EnemyType.shooter;
    if (r < 0.68) return EnemyType.melee;
    return EnemyType.shielded;
  }

  void _spawnOneEnemy() {
    if (enemiesSpawned >= enemiesToSpawn) return;
    final points = getEnemySpawnPoints();
    if (points.isEmpty) return;
    final pos = points[Random().nextInt(points.length)].clone();
    world.add(EnemySpawnPortal(position: pos)..priority = 3);
    final isChamp = overallLevel >= 5 && Random().nextDouble() < (0.08 + currentFloor * 0.02);
    final e = Enemy(floor: currentFloor, type: _chooseEnemyType(), isChampion: isChamp);
    e.position = pos;
    e.priority = 30;
    world.add(e);
    enemiesSpawned++;
    if (isChamp) unlockCodex(CodexId.champion);
  }

  void onEnemyKilled({
    bool isBoss = false,
    Vector2? at,
    bool isChampion = false,
    EnemyType? type,
    bool meleeKill = false,
    EchoBossKind? echoKind,
  }) {
    enemiesAlive = max(0, enemiesAlive - 1);
    if (arenaMode) {
      arenaKills++;
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
      }
    }
    score += ((isBoss ? 200 : (isChampion ? 80 : 20)) * comboMult).round();
    registerKill(at: at, isBoss: isBoss, isChampion: isChampion, meleeKill: meleeKill);
    if (echoKind != null && echoKind != EchoBossKind.none) {
      rememberBossEcho(echoKind);
    }
  }

  void _spawnArenaBoss() {
    final pos = Vector2(mapWidth / 2, mapHeight / 2 - 200);
    enemiesAlive++;
    enemiesToSpawn++;
    enemiesSpawned++;
    final pick = Random().nextInt(4);
    if (pick == 0) world.add(Boss(floor: 5, position: pos)..priority = 25);
    else if (pick == 1) world.add(KnightBoss(floor: 5, position: pos)..priority = 25);
    else if (pick == 2) world.add(KingBoss(position: pos)..priority = 26);
    else world.add(MiniBoss(floor: 5, position: pos)..priority = 24);
  }

  void _checkPortal() {
    if (portalSpawned || enemiesAlive > 0 || enemiesSpawned < enemiesToSpawn) return;
    if (arenaMode) {
      arenaWave++;
      enemiesToSpawn = 6 + arenaWave;
      enemiesAlive = enemiesToSpawn;
      enemiesSpawned = 0;
      return;
    }
    portalSpawned = true;
    world.add(Portal(position: Vector2(mapWidth / 2, 160))..priority = 9);
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
    score += 6666;
    scraps += 20;
    skillPoints += 1;
    if (cyclops) {
      hasLaserAbility = true;
      _ensureLaserButton();
      unlockCodex(CodexId.cyclops);
    } else {
      hasDashAbility = true;
      _ensureDashButton();
      unlockCodex(CodexId.tentacle);
    }
    enemiesAlive = max(0, enemiesAlive - 1);
  }

  bool get areOtherBossesAlive {
    for (final c in world.children) {
      if (c is Boss || c is KnightBoss) return true;
    }
    return false;
  }
    @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying || isPaused) return;

    if (dashCooldown > 0) dashCooldown = max(0, dashCooldown - dt);
    if (dashActive > 0) {
      dashActive = max(0, dashActive - dt);
      if (dashActive <= 0) player.priority = 20;
    }
    if (laserCooldown > 0) laserCooldown = max(0, laserCooldown - dt);
    if (artifactCooldown > 0) artifactCooldown = max(0, artifactCooldown - dt);
    if (holyAuraTimer > 0) {
      holyAuraTimer = max(0, holyAuraTimer - dt);
      if (holyAuraTimer > 0) {
        for (final e in world.children.whereType<Enemy>()) {
          if (e.position.distanceTo(player.position) < 110) {
            e.applyDamage(1);
            e.applyStatus(StatusType.burn, 0.8, tickDamage: 1);
          }
        }
      }
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

    // Secret bosses corner
    if (!secretBossSpawned && !secretBossUnlockedThisLevel) {
      final inCorner = player.position.x < 140 && player.position.y < 140;
      final needLevel = (currentLevel == 5 && currentFloor == 1) || (currentLevel == 5 && currentFloor == 2);
      if (needLevel && inCorner && enemiesAlive <= 0) {
        cornerStandTimer += dt;
        if (cornerStandTimer >= 33) {
          _spawnSecretBoss(cyclops: currentFloor == 2);
        }
      } else {
        cornerStandTimer = 0;
      }
    }

    // Portal proximity
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
        margin: const EdgeInsets.only(bottom: 200, left: 0, right: 0),
        onPressed: goNextLevel,
      );
      camera.viewport.add(portalButton!);
      camera.viewport.add(HudLabel(text: 'P', margin: const EdgeInsets.only(bottom: 210)));
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
    final eventTag = currentEvent == EventRoomType.none
        ? ''
        : ' • ${currentEvent == EventRoomType.altar ? "Алтарь" : currentEvent == EventRoomType.merchant ? "Торговец" : "Засада"}';
    final rankTag = inquisitionRank.rank > 0 ? ' • ${inquisitionRank.title}' : '';
    final lines = [
      'Этаж $currentFloor  Ур.$currentLevel  $hp  Очки:$score  Обл:$scraps$eventTag',
      if (arenaMode) 'АРЕНА W$arenaWave  Убито:$arenaKills',
      if (combo >= 2) 'COMBO x$combo',
      if (activeSynergyLabel != null) activeSynergyLabel!,
      if (rankTag.isNotEmpty) rankTag.trim(),
    ];
    double y = 48;
    for (final line in lines) {
      hudPaint.render(canvas, line, Vector2(12, y));
      y += 16;
    }
  }

  void goNextLevel() {
    if (!nearPortal || !portalSpawned) return;
    playClick();
    isPaused = true;
    overlays.add('levelComplete');
  }

  void nextLevel() {
    overlays.remove('levelComplete');
    isPaused = false;
    if (currentLevel >= 5) {
      if (currentFloor >= 5) {
        showVictory();
        return;
      }
      currentFloor++;
      currentLevel = 1;
      skillPoints += 1;
      pendingRewards = _rollRewards();
      overlays.add('reward');
      isPaused = true;
      return;
    }
    currentLevel++;
    skillPoints += 1;
    pendingRewards = _rollRewards();
    overlays.add('reward');
    isPaused = true;
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
    isPlaying = false;
    isPaused = true;
    stopMusic();
    addScoreEntry(completed: true);
    recordVictoryRank();
    overlays.add('victory');
  }

  void finishAfterVictory() {
    overlays.remove('victory');
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

  void openNameInput() {
    for (final o in [
      'mainMenu', 'gameOver', 'victory', 'records', 'settings', 'loadSave',
      'classSelect', 'codex', 'eventAltar', 'eventMerchant',
    ]) {
      overlays.remove(o);
    }
    overlays.add('nameInput');
  }

  void confirmName(String name, Difficulty diff) {
    playerName = name.trim().isEmpty ? 'Inquisitor' : name.trim();
    difficulty = diff;
    overlays.remove('nameInput');
    overlays.add('classSelect');
  }

  void confirmClass(PlayerClass cls) {
    playerClass = cls;
    applyClassDefaults();
    overlays.remove('classSelect');
    startNewRun();
  }

  void startNewRun() {
    score = 0;
    scraps = inquisitionRank.startScraps; // rank bonus
    currentFloor = 1;
    currentLevel = 1;
    skills = SkillTree();
    skillPoints = 0;
    relics.clear();
    loadout = WeaponLoadout();
    activeArtifact = ActiveArtifact.fragGrenade;
    arenaMode = false;
    arenaKills = 0;
    _savedPlaySeconds = 0;
    playStartTime = DateTime.now();
    hasDashAbility = playerClass == PlayerClass.hereticus;
    hasLaserAbility = false;
    _everReached11 = false;
    _everReached21 = false;
    secretBossDefeated = false;
    pendingEcho = EchoBossKind.none;
    levelsSinceEvent = 0;
    currentEvent = EventRoomType.none;
    eventResolved = true;
    recomputeStats();
    isPlaying = true;
    isPaused = false;
    currentZoom = 0.85;
    camera.viewfinder.zoom = currentZoom;
    _clearEverything();
    _startLevel();
    startMusic();
  }

  void _clearEverything() {
    world.removeAll(world.children.toList());
    camera.viewport.children.toList().forEach((c) {
      if (c is! CameraComponent) c.removeFromParent();
    });
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
      'codex', 'eventAltar', 'eventMerchant',
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

// ─── Event props ─────────────────────────────────────────
class EventAltarProp extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  EventAltarProp({required Vector2 position})
      : super(position: position, size: Vector2(64, 64), anchor: Anchor.center, priority: 8);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 32));
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player && !game.eventResolved) {
      game.openEventAltar();
    }
  }
  @override
  void render(Canvas canvas) {
    WHDraw.altar(canvas, size.x / 2, size.y / 2);
  }
}

class EventMerchantProp extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  EventMerchantProp({required Vector2 position})
      : super(position: position, size: Vector2(70, 70), anchor: Anchor.center, priority: 8);
  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 34));
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player && !game.eventResolved) {
      game.openEventMerchant();
    }
  }
  @override
  void render(Canvas canvas) {
    WHDraw.merchantStall(canvas, size.x / 2, size.y / 2);
  }
}

class HudLabel extends PositionComponent with HasGameReference<InquisitorGame> {
  final String text;
  final EdgeInsets margin;
  HudLabel({required this.text, required this.margin}) : super(priority: 200);
  @override
  void onMount() {
    super.onMount();
    final size = game.size;
    double x = margin.left, y = margin.top;
    if (margin.right > 0) x = size.x - margin.right - 12;
    if (margin.bottom > 0) y = size.y - margin.bottom - 12;
    if (margin.left == 0 && margin.right == 0) x = size.x / 2 - 6;
    position = Vector2(x, y);
  }
  @override
  void render(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
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
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      18,
      Paint()..color = Color.fromRGBO(255, 140, 0, 0.45 + 0.4 * sin(flicker)),
    );
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

class Floor extends PositionComponent {
  Floor({required Vector2 size}) : super(size: size, position: Vector2.zero(), priority: 0);
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFB0BEC5));
    final grid = Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)),
      Paint()..color = const Color(0xFF6D4C41),
    );
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
    if (other is Wall || other is Obstacle || other is Enemy) _explode();
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
              const Text(
                'Пожертвуй 1 HP — получи случайную реликвию.\nЕсли реликвий больше нет: +15 обломков и +1 SP.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text('HP: ${game.player.health}/${game.player.maxHealth}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: game.player.health > 1 ? () => game.resolveAltar(accept: true) : null,
                child: const Text('ПОЖЕРТВОВАТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => game.resolveAltar(accept: false),
                child: const Text('ОТКАЗАТЬСЯ', style: TextStyle(color: Colors.white54)),
              ),
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
              const Text('СТРАНСТВУЮЩИЙ ТОРГОВЕЦ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Обломки: ${g.scraps}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              _item('+2 HP', 10, () {
                g.resolveMerchantBuy('heal');
                setState(() {});
              }),
              _item('+1 SP', 18, () {
                g.resolveMerchantBuy('scraps_sp');
                setState(() {});
              }),
              _item('Случайная реликвия', 25, () {
                g.resolveMerchantBuy('relic');
                setState(() {});
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: () => g.closeMerchant(),
                child: const Text('УЙТИ'),
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
              if (game.inquisitionRank.rank > 0)
                Text(
                  '${game.inquisitionRank.title} • +${(game.inquisitionRank.critBonus * 100).toStringAsFixed(0)}% крит • старт ${game.inquisitionRank.startScraps} обл.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 12),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _card(PlayerClass.xenos, const Color(0xFFB71C1C), 'HP 6 • Скорость норм • Болтер'),
                    _card(PlayerClass.malleus, const Color(0xFF1A237E), 'HP 5 • Медленнее • +12% пси • ДАЛЬНИЙ посох'),
                    _card(PlayerClass.hereticus, const Color(0xFF4A148C), 'HP 5 • Быстрее • Рывок U'),
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
              const Text('НАГРАДА УРОВНЯ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
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
              _item('Урон ×1.3', 12, () {
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
              if (g.unlockedBarrelMods)
                _item('Ствол: очередь', 18, () {
                  if (g.scraps < 18) return;
                  g.scraps -= 18;
                  g.loadout.barrel = BarrelMod.rapid;
                  g.recomputeStats();
                  setState(() {});
                }),
              if (g.unlockedSightMods)
                _item('Прицел: точность', 16, () {
                  if (g.scraps < 16) return;
                  g.scraps -= 16;
                  g.loadout.sight = SightMod.precision;
                  g.recomputeStats();
                  setState(() {});
                }),
              if (g.unlockedAmmoMods)
                _item('Боезапас: взрыв', 20, () {
                  if (g.scraps < 20) return;
                  g.scraps -= 20;
                  g.loadout.ammo = AmmoMod.explosive;
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
              Text('${g.inquisitionRank.title} (ранг ${g.inquisitionRank.rank})', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 12)),
              _s('HP', '${g.player.health}/${g.maxHealth}'),
              _s('Обломки', '${g.scraps}'),
              _s('Скорость', '${g.playerSpeed.toInt()}'),
              _s('Крит (ранг)', '${((g.hasCrit ? 15 : 0) + g.inquisitionRank.critBonus * 100).toStringAsFixed(0)}%'),
              if (g.hasLaserAbility) _s('Лазер L', 'CD ${g.laserCooldown.toStringAsFixed(0)}s'),
              if (g.hasJediPath) const Text('✦ Путь Джедая: клинок сбивает пули и очищает зоны', style: TextStyle(color: Color(0xFF81D4FA), fontSize: 12)),
              if (g.activeSynergyLabel != null)
                Text('Синергия: ${g.activeSynergyLabel}', style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 12)),
              if (g.playerClass == PlayerClass.xenos)
                const Text('Подсказка: Дробовик + взрывной боезапас = Прометий-конус', style: TextStyle(color: Colors.white38, fontSize: 11)),
              if (g.playerClass == PlayerClass.hereticus)
                const Text('Подсказка: Катана + убийство в ближнем = удлинённый рывок', style: TextStyle(color: Colors.white38, fontSize: 11)),
              if (g.playerClass == PlayerClass.malleus)
                const Text('Посох: увеличенная дальность волны и клинка', style: TextStyle(color: Colors.white38, fontSize: 11)),
              if (g.relics.isNotEmpty) ...[
                const Text('Реликвии', style: TextStyle(color: Color(0xFFFFD700))),
                ...g.relics.map((r) => Text('• ${r.title}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
              const SizedBox(height: 8),
              const Text('Артефакт R', style: TextStyle(color: Color(0xFFFFD700))),
              Wrap(
                spacing: 6,
                children: ActiveArtifact.values.map((a) {
                  final sel = g.activeArtifact == a;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sel ? const Color(0xFFBF360C) : const Color(0xFF2A2A2A),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => setState(() => g.activeArtifact = a),
                    child: Text(a.title, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              const Text('Моды оружия', style: TextStyle(color: Color(0xFFFFD700))),
              if (g.unlockedBarrelMods)
                Wrap(spacing: 6, children: [
                  _modBtn('Ствол: нет', g.loadout.barrel == BarrelMod.none, () => setState(() { g.loadout.barrel = BarrelMod.none; g.recomputeStats(); })),
                  _modBtn('Очередь', g.loadout.barrel == BarrelMod.rapid, () => setState(() { g.loadout.barrel = BarrelMod.rapid; g.recomputeStats(); })),
                  _modBtn('Тяжёлый', g.loadout.barrel == BarrelMod.heavy, () => setState(() { g.loadout.barrel = BarrelMod.heavy; g.recomputeStats(); })),
                ]),
              if (g.unlockedSightMods)
                Wrap(spacing: 6, children: [
                  _modBtn('Прицел: нет', g.loadout.sight == SightMod.none, () => setState(() { g.loadout.sight = SightMod.none; g.recomputeStats(); })),
                  _modBtn('Точность', g.loadout.sight == SightMod.precision, () => setState(() { g.loadout.sight = SightMod.precision; g.recomputeStats(); })),
                  _modBtn('Широкий', g.loadout.sight == SightMod.wide, () => setState(() { g.loadout.sight = SightMod.wide; g.recomputeStats(); })),
                ]),
              if (g.unlockedAmmoMods)
                Wrap(spacing: 6, children: [
                  _modBtn('Боезапас: нет', g.loadout.ammo == AmmoMod.none, () => setState(() => g.loadout.ammo = AmmoMod.none)),
                  _modBtn('Рикошет', g.loadout.ammo == AmmoMod.ricochet, () => setState(() => g.loadout.ammo = AmmoMod.ricochet)),
                  _modBtn('Взрыв', g.loadout.ammo == AmmoMod.explosive, () => setState(() => g.loadout.ammo = AmmoMod.explosive)),
                  _modBtn('Пробитие', g.loadout.ammo == AmmoMod.pierce, () => setState(() => g.loadout.ammo = AmmoMod.pierce)),
                ]),
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

  Widget _modBtn(String t, bool sel, VoidCallback on) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: sel ? const Color(0xFFB8860B) : const Color(0xFF2A2A2A),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: on,
        child: Text(t, style: const TextStyle(fontSize: 11)),
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
        break;
      case PlayerClass.malleus:
        add('Посох', RangedWeapon.staff, true);
        add('Шторм', RangedWeapon.stormStaff, g.unlockedStormStaff);
        add('Варп', RangedWeapon.warpBeam, g.unlockedWarpBeam);
        break;
      case PlayerClass.hereticus:
        add('Кинжалы', RangedWeapon.daggers, true);
        add('Иглы', RangedWeapon.needles, g.unlockedNeedles);
        add('Снайпер', RangedWeapon.sniperNeedle, g.unlockedSniperNeedle);
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

  Widget _s(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.white70)),
            Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
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
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('КОДЕКС ИНКВИЗИЦИИ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Text('${game.codexUnlocked.length} / ${CodexId.values.length}', style: const TextStyle(color: Colors.white54)),
            Expanded(
              child: ListView.builder(
                itemCount: CodexId.values.length,
                itemBuilder: (_, i) {
                  final id = CodexId.values[i];
                  final open = game.codexUnlocked.contains(id);
                  return Card(
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ExpansionTile(
                      title: Text(open ? id.title : '???', style: TextStyle(color: open ? const Color(0xFFFFD700) : Colors.white38)),
                      subtitle: open ? Text(id.knowledgeBonus, style: const TextStyle(color: Colors.greenAccent, fontSize: 11)) : null,
                      children: open
                          ? [Padding(padding: const EdgeInsets.all(12), child: Text(id.lore, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)))]
                          : [const Padding(padding: EdgeInsets.all(12), child: Text('Убейте цель, чтобы открыть запись.', style: TextStyle(color: Colors.white38)))],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                game.playClick();
                game.closeCodex();
              },
              child: const Text('НАЗАД'),
            ),
          ],
        ),
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
              if (widget.game.inquisitionRank.rank > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${widget.game.inquisitionRank.title} • побед: ${widget.game.inquisitionRank.wins}',
                    style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 13),
                  ),
                ),
              TextField(
                controller: c,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Имя...', hintStyle: TextStyle(color: Colors.white38)),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _d(Difficulty.easy, Colors.green),
                const SizedBox(width: 8),
                _d(Difficulty.normal, const Color(0xFFB8860B)),
                const SizedBox(width: 8),
                _d(Difficulty.hard, Colors.redAccent),
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => widget.game.confirmName(c.text, diff),
                child: const Text('ДАЛЕЕ — КЛАСС'),
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

  Widget _d(Difficulty d, Color color) {
    final sel = diff == d;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: sel ? color : const Color(0xFF1A1A1A),
          side: BorderSide(color: color),
        ),
        onPressed: () => setState(() => diff = d),
        child: Text(d.labelRu, style: TextStyle(color: sel ? Colors.white : color, fontSize: 13)),
      ),
    );
  }
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MP(symbols))),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SOUL OF THE\nINQUISITOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    shadows: [Shadow(color: Colors.redAccent, blurRadius: 14)],
                  ),
                ),
                const Text('by Инквизитор Данте', style: TextStyle(color: Color(0xFFB8860B), fontSize: 14)),
                if (rank.rank > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${rank.title} • побед ${rank.wins} • +${(rank.critBonus * 100).toStringAsFixed(0)}% крит',
                      style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 12),
                    ),
                  ),
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
      tp.text = TextSpan(
        text: s.char,
        style: TextStyle(color: Color.fromRGBO(0, 255, 70, s.opacity), fontSize: 14 + s.speed * 4, fontFamily: 'monospace'),
      );
      tp.layout();
      tp.paint(canvas, Offset(s.x * size.width, s.y * size.height));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LoadSaveMenu extends StatelessWidget {
  final InquisitorGame game;
  const LoadSaveMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('ЗАГРУЗИТЬ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: game.saves.isEmpty
                  ? const Center(child: Text('Нет сохранений', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: game.saves.length,
                      itemBuilder: (_, i) {
                        final s = game.saves[i];
                        return Card(
                          color: const Color(0xFF1A1A1A),
                          child: ListTile(
                            title: Text(s.name, style: const TextStyle(color: Color(0xFFFFD700))),
                            subtitle: Text(
                              '${s.playerClass} • F${s.floor}/L${s.level} • ${s.scraps} обл.\n${s.dateStr}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            isThreeLine: true,
                            onTap: () {
                              game.playClick();
                              game.loadSave(s);
                            },
                          ),
                        );
                      },
                    ),
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
            Text(
              '${game.inquisitionRank.title} • побед: ${game.inquisitionRank.wins}',
              style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 12),
            ),
            Expanded(
              child: game.highScores.isEmpty
                  ? const Center(child: Text('Пусто', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: game.highScores.length,
                      itemBuilder: (_, i) {
                        final e = game.highScores[i];
                        return ListTile(
                          title: Text('${i + 1}. ${e.name}', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(e.progressStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: Text(
                            '${e.score}\n${e.timeStr}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13),
                          ),
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
            Text('Ранг: ${g.inquisitionRank.title} (${g.inquisitionRank.rank})', style: const TextStyle(color: Color(0xFF81D4FA))),
            Text('Джойстик ${g.joystickSize.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.joystickSize, min: 55, max: 120, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.joystickSize = v)),
            Text('Кнопки ${g.buttonSize.toInt()}', style: const TextStyle(color: Colors.white)),
            Slider(value: g.buttonSize, min: 28, max: 65, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.buttonSize = v)),
            SwitchListTile(
              title: const Text('Звуки', style: TextStyle(color: Colors.white)),
              value: g.soundEnabled,
              activeColor: const Color(0xFFFFD700),
              onChanged: (v) => setState(() => g.soundEnabled = v),
            ),
            Slider(
              value: g.soundVolume,
              min: 0,
              max: 1,
              activeColor: const Color(0xFFFFD700),
              onChanged: g.soundEnabled ? (v) => setState(() => g.soundVolume = v) : null,
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
            const Text('УРОВЕНЬ ПРОЙДЕН', style: TextStyle(color: Colors.greenAccent, fontSize: 26, fontWeight: FontWeight.bold)),
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
            Text('${game.playerName} • ${game.playerClass.title}', style: const TextStyle(color: Colors.white)),
            Text('${game.inquisitionRank.title} • побед: ${game.inquisitionRank.wins}', style: const TextStyle(color: Color(0xFF81D4FA), fontSize: 13)),
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
              child: const Text('АРЕНА'),
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
            Text(game.playerClass.title, style: const TextStyle(color: Colors.white54)),
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
    if (statuses.any((e) => e.type == StatusType.slow)) s *= 0.65;
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
            (e.type == StatusType.burn || e.type == StatusType.bleed || e.type == StatusType.corruption)) {
          health = max(0, health - e.tickDamage);
          hurtFlash = 0.12;
          if (health <= 0) game.showGameOver();
        }
      }
      if (e.remaining <= 0) statuses.remove(e);
    }
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
    final base = game.usingMelee
        ? (game.meleeWeapon == MeleeWeapon.hammer || game.meleeWeapon == MeleeWeapon.daemonHammer ? 0.78 : 0.42)
        : switch (game.rangedWeapon) {
            RangedWeapon.bolter => 0.28,
            RangedWeapon.rifle => 0.55,
            RangedWeapon.shotgun => 0.72,
            RangedWeapon.staff => 0.48,
            RangedWeapon.stormStaff => 0.55,
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
        _bullet(origin, dir, game.bolterDamage, const Color(0xFFFF6D00), 520, 5);
        if (game.loadout.barrel == BarrelMod.rapid) {
          Future.delayed(const Duration(milliseconds: 70), () {
            if (isMounted) _bullet(origin, dir, game.bolterDamage, const Color(0xFFFF6D00), 520, 5);
          });
        }
        break;
      case RangedWeapon.rifle:
        _bullet(origin, dir, game.rifleDamage, const Color(0xFF00E5FF), 680, 4);
        break;
      case RangedWeapon.shotgun:
        final n = game.loadout.sight == SightMod.wide ? 5 : 3;
        final spread = game.loadout.sight == SightMod.wide ? 0.32 : 0.22;
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
      case RangedWeapon.staff:
        game.world.add(PsyWave(
          position: origin.clone(),
          direction: dir,
          damage: game.scaleDamage(game.staffDamage),
          maxRadius: 160,
        )..priority = 13);
        break;
      case RangedWeapon.stormStaff:
        for (final o in [-0.35, 0.0, 0.35]) {
          final a = atan2(dir.y, dir.x) + o;
          game.world.add(PsyWave(
            position: origin.clone(),
            direction: Vector2(cos(a), sin(a)),
            damage: game.scaleDamage((game.stormDamage * 0.7).round()),
            maxRadius: 140,
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
    final exp = game.loadout.ammo == AmmoMod.explosive;
    final ric = game.loadout.ammo == AmmoMod.ricochet;
    final prc = pierce || game.loadout.ammo == AmmoMod.pierce;
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
    if (health <= 0) game.showGameOver();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
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
      canvas.drawCircle(
        Offset(cx, cy),
        40,
        Paint()
          ..color = const Color(0xFF81D4FA).withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
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
    if (other is Boss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is KnightBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is KingBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is TentacleBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is CyclopsBoss && hit.add(other.hashCode)) other.takeDamage(damage);
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
    if (other is Boss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is KnightBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is KingBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is TentacleBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is CyclopsBoss && hit.add(other.hashCode)) other.takeDamage(damage);
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
    position += velocity * dt;
    if (life <= 0 || position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) {
      removeFromParent();
    }
  }
  void _hitEnemy(Enemy e) {
    if (!hitIds.add(e.hashCode)) return;
    e.applyDamage(damage);
    if (applyBurn || explosive) e.applyStatus(StatusType.burn, 2.0 + game.codexBurnBonus, tickDamage: 1);
    if (explosive) {
      game.world.add(KillExplosion(position: position.clone(), radius: 55, damage: damage ~/ 3)..priority = 12);
    }
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
      if (!pierce) removeFromParent();
    }
    if (other is KnightBoss) {
      other.takeDamage(damage);
      if (!pierce) removeFromParent();
    }
    if (other is KingBoss) {
      other.takeDamage(damage);
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
    if (other is Wall || other is Obstacle) {
      if (ricochet && bounces < 2) {
        bounces++;
        velocity.x *= -1;
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
    // Jedi Path: destroy bullets
    if (game.hasJediPath && (other is EnemyBullet || other is BossProjectile)) {
      other.removeFromParent();
      game.spawnDamageNumber(other.position, 0, color: const Color(0xFF81D4FA), label: '✦');
      return;
    }
    // Jedi Path: purify corruption zones
    if (game.hasJediPath && other is CorruptionZone) {
      other.purify();
      return;
    }
    if (other is Enemy && hit.add(other.hashCode) && _inArc(other.position)) {
      other.applyDamage(damage);
      if (game.synergyHereticusBleedDash) other.applyStatus(StatusType.bleed, 2.5, tickDamage: 1);
    }
    if (other is MiniBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is Boss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is KnightBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is KingBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is TentacleBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is CyclopsBoss && hit.add(other.hashCode)) other.takeDamage(damage);
    if (other is Obstacle && hit.add(other.hashCode)) other.removeFromParent();
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
  final Vector2 velocity;
  final int damage;
  double life = 3.5;
  EnemyBullet({required Vector2 position, required Vector2 direction, required this.damage, double speed = 180})
      : velocity = direction.normalized() * speed,
        super(position: position.clone(), size: Vector2(14, 14), anchor: Anchor.center, priority: 16);
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
      other.takeDamage(damage);
      removeFromParent();
    }
    if (other is Wall || other is Obstacle) removeFromParent();
    if (other is MeleeAttack && game.hasJediPath) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6, Paint()..color = const Color(0xFF76FF03));
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
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];
  bool _dead = false;

  Enemy({required this.floor, required this.type, this.isChampion = false})
      : super(
          size: Vector2(type == EnemyType.brute ? 88 : 70, type == EnemyType.brute ? 88 : 70),
          anchor: Anchor.center,
          priority: 30,
        );

  @override
  Future<void> onLoad() async {
    final base = switch (type) {
      EnemyType.shooter => 18.0,
      EnemyType.melee => 22.0,
      EnemyType.shielded => 32.0,
      EnemyType.dog => 16.0,
      EnemyType.shieldedShooter => 36.0,
      EnemyType.flamer => 24.0,
      EnemyType.sniper => 20.0,
      EnemyType.brute => 55.0,
    };
    maxHp = (base * game.difficulty.hpMult * game.worldThreat * (1 + floor * 0.12) * (isChampion ? 2.2 : 1.0)).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: type == EnemyType.brute ? 36 : 28));
    if (isChampion) game.unlockCodex(CodexId.champion);
  }

  bool get isShielded => type == EnemyType.shielded || type == EnemyType.shieldedShooter;
  bool get isRanged =>
      type == EnemyType.shooter ||
      type == EnemyType.shieldedShooter ||
      type == EnemyType.flamer ||
      type == EnemyType.sniper;

  void applyStatus(StatusType t, double dur, {int tickDamage = 1}) {
    final ex = statuses.where((e) => e.type == t).toList();
    if (ex.isNotEmpty) {
      ex.first.remaining = max(ex.first.remaining, dur);
    } else {
      statuses.add(StatusEffect(t, dur, tickDamage: tickDamage));
    }
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

  void applyDamage(int amount, {bool fromStatus = false}) {
    if (_dead) return;
    var dmg = amount;
    if (isShielded && !fromStatus) {
      final pierce = game.hasShieldPierce || game.codexShieldBonus > 0;
      if (!pierce && !game.usingMelee) {
        dmg = max(1, (dmg * 0.15).round());
      } else if (!game.usingMelee) {
        dmg = max(1, (dmg * (0.45 + game.codexShieldBonus)).round());
      }
    }
    currentHp -= dmg;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, dmg, color: isChampion ? const Color(0xFFFFD700) : const Color(0xFFFFEB3B));
    if (currentHp <= 0) {
      _dead = true;
      final pos = position.clone();
      final meleeKill = game.usingMelee;
      removeFromParent();
      game.onEnemyKilled(at: pos, isChampion: isChampion, type: type, meleeKill: meleeKill);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused || _dead) return;
    _tickStatuses(dt);

    final toP = game.player.position - position;
    final dist = toP.length;
    var spd = switch (type) {
      EnemyType.dog => 165.0,
      EnemyType.brute => 70.0,
      EnemyType.sniper => 55.0,
      EnemyType.flamer => 80.0,
      EnemyType.shielded || EnemyType.shieldedShooter => 75.0,
      EnemyType.shooter => 95.0,
      EnemyType.melee => 110.0,
    };
    if (isChampion) spd *= 1.1;
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;
    spd *= (0.95 + game.difficulty.dmgMult * 0.05);

    final prefer = switch (type) {
      EnemyType.sniper => 320.0,
      EnemyType.shooter || EnemyType.shieldedShooter => 240.0,
      EnemyType.flamer => 160.0,
      _ => 0.0,
    };

    smartMove(game.player.position, spd, dt, radius: type == EnemyType.brute ? 36 : 28, kite: isRanged, preferDist: prefer);
    pushOutOfWalls(type == EnemyType.brute ? 36 : 28);

    attackTimer += dt;
    final closeBoost = dist < 140 ? 0.55 : 1.0;
    final interval = switch (type) {
          EnemyType.dog => 0.55,
          EnemyType.melee => 0.7,
          EnemyType.brute => 1.1,
          EnemyType.flamer => 1.4,
          EnemyType.sniper => 1.8,
          EnemyType.shooter => 1.1,
          EnemyType.shieldedShooter => 1.3,
          EnemyType.shielded => 0.9,
        } *
        closeBoost /
        (isChampion ? 1.15 : 1.0);

    if (attackTimer >= interval) {
      attackTimer = 0;
      final dir = dist > 1 ? toP / dist : Vector2(0, 1);
      final dmg = (1 * game.difficulty.dmgMult * (isChampion ? 1.4 : 1.0)).ceil();
      switch (type) {
        case EnemyType.melee:
        case EnemyType.dog:
        case EnemyType.brute:
        case EnemyType.shielded:
          if (dist < (type == EnemyType.brute ? 70 : 55)) {
            game.player.takeDamage(dmg + (type == EnemyType.brute ? 1 : 0));
          }
          break;
        case EnemyType.shooter:
        case EnemyType.shieldedShooter:
          game.world.add(EnemyBullet(position: position.clone(), direction: dir, damage: dmg)..priority = 16);
          break;
        case EnemyType.sniper:
          game.world.add(EnemyBullet(position: position.clone(), direction: dir, damage: dmg + 1, speed: 260)..priority = 16);
          break;
        case EnemyType.flamer:
          game.world.add(FlamerCloud(position: position + dir * 40)..priority = 11);
          if (dist < 90) game.player.applyStatus(StatusType.burn, 1.2, tickDamage: 1);
          break;
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      final n = (position - intersectionPoints.first).normalized();
      position += n * 12;
      avoidDir = Vector2(-n.y, n.x);
      stuckTimer = 0.55;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final f = hurtFlash / 0.12;
    switch (type) {
      case EnemyType.shooter:
        WHDraw.cultistShooter(canvas, cx, cy, 1.05, flash: f);
        break;
      case EnemyType.melee:
        WHDraw.cultistMelee(canvas, cx, cy, 1.05, flash: f);
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
        WHDraw.flamerCultist(canvas, cx, cy, 1.05, flash: f);
        break;
      case EnemyType.sniper:
        WHDraw.sniperCultist(canvas, cx, cy, 1.05, flash: f);
        break;
      case EnemyType.brute:
        WHDraw.brute(canvas, cx, cy, 1.15, flash: f);
        break;
    }
    final barW = size.x * 0.7;
    canvas.drawRect(
      Rect.fromLTWH(cx - barW / 2, -10, barW * (currentHp / maxHp), 5),
      Paint()..color = isChampion ? const Color(0xFFFFD700) : const Color(0xFFE53935),
    );
    if (isChampion) WHDraw.championMark(canvas, cx, -18);
    WHDraw.statusIcons(canvas, cx, -26, statuses);
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
    maxHp = ((90 + floor * 25) * game.difficulty.bossHpMult * game.worldThreat * 0.5 * mult).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 42));
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
      game.spawnBlood(pos, count: 22);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.mini,
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7;
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 200, angle: ang, life: 0.7)..priority = 6);
  }

  void _fireShotgun() {
    final toP = (game.player.position - position).normalized();
    final base = atan2(toP.y, toP.x);
    for (final o in [-0.35, -0.15, 0.0, 0.15, 0.35]) {
      final a = base + o;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
    }
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

    if (telegraphing) {
      smartMove(game.player.position, 40, dt, radius: 42, kite: true, preferDist: 200);
      pushOutOfWalls(42);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _fireShotgun();
      }
      return;
    }

    final dist = position.distanceTo(game.player.position);
    var spd = 95.0 * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;
    smartMove(game.player.position, spd, dt, radius: 42, kite: true, preferDist: 260);
    pushOutOfWalls(42);

    attackTimer += dt;
    final iv = (dist < 180 ? 1.0 : 1.5) * (isEcho ? 1.2 : 1.0);
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 14;
      stuckTimer = 0.65;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.hereticBoss(canvas, cx, cy, 1.15, flash: hurtFlash / 0.12);
    if (isEcho) {
      canvas.drawCircle(
        Offset(cx, cy),
        48,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(cx - 40, -16, 80 * (currentHp / maxHp), 7),
      Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF9800),
    );
    WHDraw.statusIcons(canvas, cx, -28, statuses);
  }
}
class Boss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  int hardBars = 1;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0;
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
    add(CircleHitbox(radius: 50));
    if (!isEcho) game.unlockCodex(CodexId.boss);
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

  void takeDamage(int amount) {
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFF5252));
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 28);
      // zone left via registerKill(isBoss) inside onEnemyKilled
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.ranged,
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.75;
    attackMode = Random().nextInt(3);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 130, life: 0.75)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 220, angle: ang, life: 0.75)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 150, life: 0.75)..priority = 6);
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
    }
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

    smartMove(game.player.position, spd, dt, radius: 50, kite: dist > 280, preferDist: 220);
    pushOutOfWalls(50);

    attackTimer += dt;
    final iv = (dist < 160 ? 1.2 : 1.7) * (isEcho ? 1.25 : 1.0) / (game.difficulty == Difficulty.hard ? 1.15 : 1.0);
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.75;
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
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      canvas.drawRect(
        Rect.fromLTWH(cx - 50, -22 - i * 10.0, 100 * remain, 8),
        Paint()..color = isEcho ? const Color(0xFF9C27B0) : const Color(0xFFE53935),
      );
    }
    WHDraw.statusIcons(canvas, cx, -34, statuses);
  }
}
class KnightBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final bool isEcho;
  late int maxHp;
  late int currentHp;
  int hardBars = 1;
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
    add(CircleHitbox(radius: 48));
    if (!isEcho) game.unlockCodex(CodexId.knight);
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

  void takeDamage(int amount) {
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFF90CAF9));
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 30);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.knight,
      );
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7;
    attackMode = Random().nextInt(3);
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
    }
  }

  void _executeAttack() {
    final dist = position.distanceTo(game.player.position);
    final toP = (game.player.position - position).normalized();
    switch (attackMode) {
      case 0:
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
    }
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
    var spd = 110.0 * (isEcho ? 0.85 : 1.0);
    if (statuses.any((e) => e.type == StatusType.slow)) spd *= 0.6;

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

    smartMove(game.player.position, spd, dt, radius: 48);
    pushOutOfWalls(48);

    attackTimer += dt;
    final iv = (dist < 120 ? 0.9 : 1.4) * (isEcho ? 1.2 : 1.0);
    if (attackTimer >= iv) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
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
    attackMode = phase == 1 ? Random().nextInt(2) : Random().nextInt(3);
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
    }
  }

  void _volley() {
    final n = game.difficulty == Difficulty.hard ? 16 : 12;
    for (int i = 0; i < n; i++) {
      final a = (i / n) * 2 * pi;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
    }
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
    final hardBoost = game.difficulty == Difficulty.hard
        ? 1.0 + ((maxHp - currentHp) / maxHp) * 0.4
        : 1.0;

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
      (phase == 1 ? 100.0 : 38.0) * hardBoost * (isEcho ? 0.85 : 1.0),
      dt,
      radius: 60,
    );
    pushOutOfWalls(60);

    if (phase == 1) {
      final interval = (dist < 140 ? 0.55 : 0.9) / hardBoost * (isEcho ? 1.2 : 1.0);
      meleeTimer += dt;
      if (meleeTimer >= interval) {
        meleeTimer = 0;
        _startTelegraph();
      }
    } else {
      phase2Timer += dt;
      final volleyGap = game.difficulty == Difficulty.hard ? 0.28 : 0.35;
      final cycle = game.difficulty == Difficulty.hard ? 2.4 : 3.0;
      if (phase2VolleyCount > 0) {
        if (phase2Timer >= volleyGap) {
          phase2Timer = 0;
          game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 100, life: 0.35)..priority = 6);
          _volley();
          phase2VolleyCount--;
        }
      } else if (phase2Timer >= cycle) {
        phase2Timer = 0;
        phase2VolleyCount = game.difficulty == Difficulty.hard ? 3 : 2;
        _startTelegraph();
      }
    }
  }

  void takeDamage(int amount) {
    if (!isEcho && game.areOtherBossesAlive) return;
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: isEcho ? const Color(0xFF9C27B0) : const Color(0xFFFFD700));
    if (phase == 1 && currentHp <= phaseHp) {
      phase = 2;
      phase2Timer = 0;
      game.triggerShake(power: 12, time: 0.35);
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 36);
      game.onEnemyKilled(
        isBoss: true,
        at: pos,
        meleeKill: game.usingMelee,
        echoKind: isEcho ? EchoBossKind.none : EchoBossKind.king,
      );
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
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
      canvas.drawCircle(
        Offset(cx, cy),
        68,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
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
    WHDraw.statusIcons(canvas, cx, -68, statuses);
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    anim += dt;
    final dist = position.distanceTo(game.player.position);
    final hardBoost = game.difficulty == Difficulty.hard ? 1.2 : 1.0;

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

    smartMove(game.player.position, (phase == 1 ? 45.0 : 30.0) * hardBoost, dt, radius: 60);
    pushOutOfWalls(60);

    if (phase == 1) {
      phaseTimer += dt;
      final iv = game.difficulty == Difficulty.hard ? 1.4 : 1.8;
      if (phaseTimer >= iv) {
        phaseTimer = 0;
        _startRingTelegraph();
      }
      if (currentHp <= maxHp ~/ 2) {
        phase = 2;
        phaseTimer = 0;
        meleeHitsLeft = game.difficulty == Difficulty.hard ? 8 : 6;
        meleeGap = 0;
        game.triggerShake(power: 10, time: 0.3);
      }
    } else {
      if (meleeHitsLeft > 0) {
        meleeGap += dt;
        if (meleeGap >= (game.difficulty == Difficulty.hard ? 0.42 : 0.55)) {
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
          meleeHitsLeft = game.difficulty == Difficulty.hard ? 8 : 6;
          meleeGap = 0;
        }
      }
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFF9C27B0));
    if (currentHp <= 0) {
      currentHp = 0;
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 36);
      game.spawnCorruptionZone(pos);
      game.onSecretBossKilled(cyclops: false);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 20;
      stuckTimer = 0.85;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2, t = anim;
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    final hardBoost = game.difficulty == Difficulty.hard ? 1.15 : 1.0;

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

    smartMove(game.player.position, (phase == 1 ? 55.0 : 70.0) * hardBoost, dt, radius: 62);
    pushOutOfWalls(62);
    phaseTimer += dt;

    if (phase == 1) {
      if (phaseTimer >= (game.difficulty == Difficulty.hard ? 1.5 : 2.0)) {
        phaseTimer = 0;
        if (Random().nextDouble() < 0.35) {
          chargingLaser = true;
          charge = 0;
        } else {
          _startTelegraph(Random().nextInt(2));
        }
      }
      if (currentHp <= maxHp ~/ 2) {
        phase = 2;
        phaseTimer = 0;
        game.triggerShake(power: 11, time: 0.3);
      }
    } else {
      if (phaseTimer >= (game.difficulty == Difficulty.hard ? 1.1 : 1.4)) {
        phaseTimer = 0;
        if (Random().nextDouble() < 0.5) {
          chargingLaser = true;
          charge = 0;
        } else {
          _startTelegraph(Random().nextInt(3));
        }
      }
    }
  }

  void takeDamage(int amount) {
    if (chargingLaser && charge > 0.3) amount = (amount * 0.7).round();
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFFFF6D00));
    if (currentHp <= 0) {
      currentHp = 0;
      final pos = position.clone();
      removeFromParent();
      game.spawnBlood(pos, count: 40);
      game.spawnCorruptionZone(pos);
      game.onSecretBossKilled(cyclops: true);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
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
