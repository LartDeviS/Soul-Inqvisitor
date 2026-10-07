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
enum RelicId { crit, lifesteal, shieldPierce, killExplosion, haste }

enum StatusType { burn, bleed, slow, corruption }
enum ActiveArtifact { fragGrenade, holyAura, servoTurret }
enum BarrelMod { none, rapid, heavy }
enum SightMod { none, precision, wide }
enum AmmoMod { none, ricochet, explosive, pierce }

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
      case PlayerClass.malleus: return 'Псайкер. −1 HP, +пси-урон, медленнее. Посох-волна и варп.';
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
    }
  }
  String get desc {
    switch (this) {
      case RelicId.crit: return '15% крит ×2';
      case RelicId.lifesteal: return '15% +1 HP при убийстве';
      case RelicId.shieldPierce: return 'Частичное пробитие щитов';
      case RelicId.killExplosion: return 'Взрыв при убийстве';
      case RelicId.haste: return '+12% скорость 3с после килла';
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
      case ActiveArtifact.servoTurret: return 'Турель 8с, стреляет по ближайшим. CD 16с';
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
  /// weak passive when unlocked
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
    this.loadout = const {}, this.codex = const [],
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
  );

  String get dateStr {
    try {
      final d = DateTime.parse(dateIso);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return dateIso; }
  }
}

class DamageNumber extends PositionComponent {
  final int amount; final Color color; double life = 0.85; double vy = -55;
  DamageNumber({required Vector2 position, required this.amount, this.color = const Color(0xFFFFEB3B)}) : super(position: position.clone(), priority: 100);
  @override
  void update(double dt) { super.update(dt); life -= dt; position.y += vy * dt; vy *= 0.98; if (life <= 0) removeFromParent(); }
  @override
  void render(Canvas canvas) {
    final a = (life / 0.85).clamp(0.0, 1.0);
    final tp = TextPainter(text: TextSpan(text: '-$amount', style: TextStyle(color: color.withOpacity(a), fontSize: 18, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black.withOpacity(a), blurRadius: 3)])), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

class BloodSplash extends PositionComponent {
  final List<_Drop> drops = []; double life = 1.4;
  BloodSplash({required Vector2 position, int count = 14}) : super(position: position.clone(), priority: 8) {
    final rnd = Random();
    for (int i = 0; i < count; i++) {
      final a = rnd.nextDouble() * 2 * pi; final sp = 40 + rnd.nextDouble() * 120;
      drops.add(_Drop(offset: Vector2.zero(), vel: Vector2(cos(a), sin(a)) * sp, radius: 2 + rnd.nextDouble() * 4.5, dark: rnd.nextBool()));
    }
  }
  @override
  void update(double dt) {
    super.update(dt); life -= dt;
    for (final d in drops) { d.vel.y += 280 * dt; d.offset += d.vel * dt; d.vel *= 0.92; }
    if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 1.4).clamp(0.0, 1.0);
    for (final d in drops) {
      canvas.drawCircle(Offset(d.offset.x, d.offset.y), d.radius * (0.6 + 0.4 * a), Paint()..color = d.dark ? Color.fromRGBO(120, 0, 0, 0.85 * a) : Color.fromRGBO(200, 16, 16, 0.9 * a));
    }
  }
}
class _Drop { Vector2 offset; Vector2 vel; double radius; bool dark; _Drop({required this.offset, required this.vel, required this.radius, required this.dark}); }

class KillExplosion extends CircleComponent {
  double life = 0.35; final int damage; final bool applyBurn;
  KillExplosion({required Vector2 position, required double radius, required this.damage, this.applyBurn = false})
      : super(position: position, radius: radius, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFF6D00).withOpacity(0.45), priority: 12);
  @override Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt); life -= dt;
    paint.color = Color.fromRGBO(255, 109, 0, (life / 0.35 * 0.45).clamp(0.0, 0.45));
    if (life <= 0) removeFromParent();
  }
}

class ComboBanner extends PositionComponent with HasGameReference<InquisitorGame> {
  double life = 1.2; final int combo;
  ComboBanner({required this.combo}) : super(priority: 200);
  @override void onMount() { super.onMount(); position = Vector2(game.size.x / 2 - 40, 120); }
  @override void update(double dt) { super.update(dt); life -= dt; position.y -= 20 * dt; if (life <= 0) removeFromParent(); }
  @override
  void render(Canvas canvas) {
    final a = (life / 1.2).clamp(0.0, 1.0);
    final tp = TextPainter(text: TextSpan(text: 'COMBO x$combo', style: TextStyle(color: Color.fromRGBO(255, 215, 0, a), fontSize: 22, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset.zero);
  }
}

/// Red warning zone before boss attacks
class TelegraphZone extends PositionComponent {
  final String shape; // circle | cone | cross
  final double radius;
  final double angle; // for cone direction
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
/// Procedural WH40k art — class silhouettes, weapons, enemies
class WHDraw {
  static void _armorPlate(Canvas c, Rect r, Color col, Color edge) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = col);
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(2)), Paint()..color = edge.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 1.2);
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
    final cape = Path()
      ..moveTo(cx - 14 * s, cy)
      ..quadraticBezierTo(cx - 50 * s, cy + 30 * s, cx - 16 * s, cy + 56 * s)
      ..lineTo(cx + 16 * s, cy + 56 * s)
      ..quadraticBezierTo(cx + 50 * s, cy + 30 * s, cx + 14 * s, cy)
      ..close();
    c.drawPath(cape, Paint()..color = capeCol.withOpacity(0.92));
    c.drawPath(cape, Paint()..color = gold.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    for (final lx in [-11.0, 11.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + lx * s, cy + 32 * s), width: 14 * s, height: 26 * s), Radius.circular(2 * s)), Paint()..color = armor);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + lx * s, cy + 42 * s), width: 16 * s, height: 8 * s), Radius.circular(2 * s)), Paint()..color = dark);
    }
    _armorPlate(c, Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 38 * s, height: 36 * s), armor, gold);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 24 * s, height: 22 * s), Radius.circular(4 * s)), Paint()..color = armorLite);
    c.drawCircle(Offset(cx, cy + 4 * s), 7 * s, Paint()..color = gold);
    c.drawCircle(Offset(cx, cy + 4 * s), 3.5 * s, Paint()..color = dark);
    if (cls == PlayerClass.malleus) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 28 * s), width: 28 * s, height: 14 * s), Radius.circular(6 * s)), Paint()..color = const Color(0xFF4527A0));
      c.drawCircle(Offset(cx, cy - 30 * s), 5 * s, Paint()..color = visor.withOpacity(0.7));
    }
    if (cls == PlayerClass.hereticus) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 8 * s), width: 20 * s, height: 8 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF311B92));
    }
    c.drawCircle(Offset(cx - 22 * s, cy - 4 * s), 14 * s, Paint()..color = armor);
    c.drawCircle(Offset(cx + 22 * s, cy - 4 * s), 14 * s, Paint()..color = armor);
    c.drawArc(Rect.fromCircle(center: Offset(cx - 22 * s, cy - 4 * s), radius: 14 * s), pi, pi, false, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawArc(Rect.fromCircle(center: Offset(cx + 22 * s, cy - 4 * s), radius: 14 * s), pi, pi, false, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 26 * s, cy + 16 * s), width: 11 * s, height: 22 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 26 * s, cy + 16 * s), width: 11 * s, height: 22 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawCircle(Offset(cx, cy - 18 * s), 12 * s, Paint()..color = const Color(0xFFC4A484));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 22 * s), width: 24 * s, height: 11 * s), Radius.circular(2 * s)), Paint()..color = dark);
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 19 * s), width: 15 * s, height: 3.5 * s), Paint()..color = visor.withOpacity(0.95));
    c.drawLine(Offset(cx - 8 * s, cy + 18 * s), Offset(cx - 8 * s, cy + 28 * s), Paint()..color = const Color(0xFFFFF8E1)..strokeWidth = 2 * s);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 46 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void bolter(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final body = accent ?? const Color(0xFFC62828);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2 * s, cy - 2 * s, 11 * s, 15 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF6D4C41));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy - 11 * s, 32 * s, 15 * s), Radius.circular(2 * s)), Paint()..color = body);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 18 * s, cy + 4 * s, 10 * s, 14 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF546E7A));
    c.drawCircle(Offset(cx + 26 * s, cy - 3 * s), 5 * s, Paint()..color = const Color(0xFFFFF8E1));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 38 * s, cy - 7 * s, 20 * s, 7 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF546E7A));
  }

  static void rifle(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final glow = accent ?? const Color(0xFF00E5FF);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 6 * s, 40 * s, 11 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFFA1887F));
    for (int i = 0; i < 5; i++) c.drawCircle(Offset(cx + 26 * s + i * 5 * s, cy), 3.2 * s, Paint()..color = glow.withOpacity(0.85));
  }

  static void shotgun(Canvas c, double cx, double cy, double s, {Color? accent}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 12 * s, cy - 5 * s, 30 * s, 10 * s), Radius.circular(1 * s)), Paint()..color = accent ?? const Color(0xFF546E7A));
  }

  static void staff(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final glow = accent ?? const Color(0xFF7C4DFF);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 4 * s, 8 * s, 52 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF4A148C));
    c.drawCircle(Offset(cx + 10 * s, cy - 14 * s), 11 * s, Paint()..color = glow.withOpacity(0.9));
    c.drawCircle(Offset(cx + 10 * s, cy - 14 * s), 5 * s, Paint()..color = Colors.white70);
  }

  static void stormStaff(Canvas c, double cx, double cy, double s, {Color? accent}) {
    staff(c, cx, cy, s, accent: accent ?? const Color(0xFFEA80FC));
    c.drawCircle(Offset(cx + 10 * s, cy - 14 * s), 16 * s, Paint()..color = const Color(0xFFEA80FC).withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 2 * s);
  }

  static void warpBeamGun(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final g = accent ?? const Color(0xFF651FFF);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 8 * s, 36 * s, 14 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF311B92));
    c.drawCircle(Offset(cx + 42 * s, cy), 8 * s, Paint()..color = g);
  }

  static void daggers(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFFE0E0E0);
    for (final ox in [-6.0, 6.0]) {
      final p = Path()..moveTo(cx + ox * s, cy + 4 * s)..lineTo(cx + ox * s + 4 * s, cy - 28 * s)..lineTo(cx + ox * s + 8 * s, cy + 4 * s)..close();
      c.drawPath(p, Paint()..color = blade);
    }
  }

  static void needles(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final col = accent ?? const Color(0xFFCE93D8);
    for (int i = 0; i < 3; i++) {
      c.drawLine(Offset(cx + 4 * s, cy - 2 * s + i * 4 * s), Offset(cx + 36 * s, cy - 18 * s + i * 4 * s), Paint()..color = col..strokeWidth = 2 * s);
    }
  }

  static void sniperNeedle(Canvas c, double cx, double cy, double s, {Color? accent}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 4 * s, 48 * s, 6 * s), Radius.circular(1 * s)), Paint()..color = accent ?? const Color(0xFF9C27B0));
    c.drawCircle(Offset(cx + 20 * s, cy - 10 * s), 4 * s, Paint()..color = const Color(0xFFE040FB));
  }

  static void powerSword(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFF4DD0E1);
    final p = Path()..moveTo(cx + 10 * s, cy - 2 * s)..lineTo(cx + 14 * s, cy - 42 * s)..lineTo(cx + 18 * s, cy - 2 * s)..close();
    c.drawPath(p, Paint()..color = blade);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 10 * s, cy), width: 18 * s, height: 6 * s), Paint()..color = const Color(0xFFB8860B));
  }

  static void chainAxe(Canvas c, double cx, double cy, double s, {Color? accent}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 2.5 * s, 30 * s, 5 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF8D4E3A));
    final head = Offset(cx + 38 * s, cy);
    final top = Path()..moveTo(head.dx, head.dy - 3 * s)..lineTo(head.dx + 8 * s, head.dy - 24 * s)..lineTo(head.dx + 18 * s, head.dy - 8 * s)..close();
    c.drawPath(top, Paint()..color = accent ?? const Color(0xFF78909C));
    c.drawCircle(head, 6 * s, Paint()..color = const Color(0xFF546E7A));
  }

  static void thunderHammer(Canvas c, double cx, double cy, double s, {Color? accent}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 2 * s, 36 * s, 5 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 48 * s, cy), width: 18 * s, height: 24 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF455A64));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 48 * s, cy), width: 12 * s, height: 16 * s), Radius.circular(1 * s)), Paint()..color = accent ?? const Color(0xFFB8860B));
  }

  static void forceBlade(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFFB388FF);
    final p = Path()..moveTo(cx + 8 * s, cy)..lineTo(cx + 16 * s, cy - 48 * s)..lineTo(cx + 24 * s, cy)..close();
    c.drawPath(p, Paint()..color = blade);
    c.drawCircle(Offset(cx + 16 * s, cy), 6 * s, Paint()..color = const Color(0xFF4A148C));
  }

  static void forceSword(Canvas c, double cx, double cy, double s, {Color? accent}) {
    forceBlade(c, cx, cy, s * 1.1, accent: accent ?? const Color(0xFFEA80FC));
    c.drawCircle(Offset(cx + 16 * s, cy - 20 * s), 4 * s, Paint()..color = Colors.white54);
  }

  static void daemonHammer(Canvas c, double cx, double cy, double s, {Color? accent}) {
    thunderHammer(c, cx, cy, s, accent: accent ?? const Color(0xFF7C4DFF));
    c.drawCircle(Offset(cx + 48 * s, cy), 10 * s, Paint()..color = const Color(0xFF7C4DFF).withOpacity(0.35));
  }

  static void katana(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFFECEFF1);
    c.drawLine(Offset(cx + 8 * s, cy + 2 * s), Offset(cx + 14 * s, cy - 50 * s), Paint()..color = blade..strokeWidth = 3.2 * s..strokeCap = StrokeCap.round);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 8 * s, cy + 4 * s), width: 16 * s, height: 5 * s), Paint()..color = const Color(0xFF4A148C));
  }

  static void powerKatana(Canvas c, double cx, double cy, double s, {Color? accent}) {
    katana(c, cx, cy, s, accent: accent ?? const Color(0xFFE040FB));
    c.drawLine(Offset(cx + 10 * s, cy), Offset(cx + 12 * s, cy - 46 * s), Paint()..color = const Color(0xFFEA80FC).withOpacity(0.5)..strokeWidth = 5 * s);
  }

  static void executioner(Canvas c, double cx, double cy, double s, {Color? accent}) {
    final blade = accent ?? const Color(0xFFF3E5F5);
    c.drawLine(Offset(cx + 6 * s, cy + 4 * s), Offset(cx + 20 * s, cy - 56 * s), Paint()..color = blade..strokeWidth = 4.5 * s..strokeCap = StrokeCap.round);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 6 * s, cy + 6 * s), width: 20 * s, height: 7 * s), Paint()..color = const Color(0xFF6A1B9A));
  }

  static void chaosHound(Canvas c, double cx, double cy, {double flash = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 2), width: 52, height: 28), Paint()..color = const Color(0xFF2D1F14));
    c.drawOval(Rect.fromCenter(center: Offset(cx + 22, cy - 8), width: 28, height: 22), Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx + 26, cy - 12), 4, Paint()..color = const Color(0xFFFFFDE7));
    c.drawCircle(Offset(cx + 26, cy - 12), 1.8, Paint()..color = const Color(0xFFB71C1C));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 30, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void cultistShooter(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 24 * s, height: 26 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 12 * s), 11 * s, Paint()..color = const Color(0xFF37474F));
    c.drawCircle(Offset(cx - 3.5 * s, cy - 13 * s), 3.2 * s, Paint()..color = const Color(0xFF1B5E20));
    c.drawCircle(Offset(cx + 3.5 * s, cy - 13 * s), 3.2 * s, Paint()..color = const Color(0xFF1B5E20));
    bolter(c, cx + 2 * s, cy + 2 * s, s * 0.78);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void cultistMelee(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 12 * s), width: 30 * s, height: 38 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF6B1B1B));
    c.drawCircle(Offset(cx, cy - 16 * s), 11 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx - 3.5 * s, cy - 16 * s), 2 * s, Paint()..color = const Color(0xFFFF1744));
    c.drawCircle(Offset(cx + 3.5 * s, cy - 16 * s), 2 * s, Paint()..color = const Color(0xFFFF1744));
    c.drawLine(Offset(cx + 16 * s, cy + 2 * s), Offset(cx + 34 * s, cy - 22 * s), Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 3.5 * s);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void shieldedMarine(Canvas c, double cx, double cy, double s, {bool withGun = false, double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 32 * s, height: 30 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF2A2A2A));
    c.drawCircle(Offset(cx, cy - 16 * s), 12 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 8 * s, cy + 6 * s), width: 40 * s, height: 52 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF37474F));
    if (withGun) bolter(c, cx - 8 * s, cy + 2 * s, s * 0.72);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 36 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void flamerCultist(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 28 * s, height: 30 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFFBF360C));
    c.drawCircle(Offset(cx, cy - 14 * s), 11 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 4 * s, 28 * s, 12 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF5D4037));
    c.drawCircle(Offset(cx + 36 * s, cy), 8 * s, Paint()..color = const Color(0xFFFF6D00).withOpacity(0.8));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void sniperCultist(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 22 * s, height: 28 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF33691E));
    c.drawCircle(Offset(cx, cy - 12 * s), 10 * s, Paint()..color = const Color(0xFF1B5E20));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 6 * s, 42 * s, 6 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF558B2F));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 32 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void brute(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 44 * s, height: 40 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 18 * s), 14 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx - 5 * s, cy - 18 * s), 3 * s, Paint()..color = const Color(0xFFFF6D00));
    c.drawCircle(Offset(cx + 5 * s, cy - 18 * s), 3 * s, Paint()..color = const Color(0xFFFF6D00));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 28 * s, cy + 4 * s), width: 16 * s, height: 28 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF5D4037));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 40 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.4 * flash));
  }

  static void hereticBoss(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 16 * s), width: 30 * s, height: 42 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 14 * s), 12 * s, Paint()..color = const Color(0xFFC4A484));
    if (flash > 0) c.drawCircle(Offset(cx, cy), 52 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void knightBoss(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 42 * s, height: 36 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 22 * s), 13 * s, Paint()..color = const Color(0xFF212121));
    powerSword(c, cx + 10 * s, cy + 4 * s, s * 1.05);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 50 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void kingBossDraw(Canvas c, double cx, double cy, double s, {double flash = 0}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 46 * s, height: 38 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 22 * s), 12 * s, Paint()..color = const Color(0xFFC4A484));
    thunderHammer(c, cx + 8 * s, cy + 4 * s, s * 0.9);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 58 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
  }

  static void cyclops(Canvas c, double cx, double cy, double s, {double flash = 0, double charge = 0}) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10 * s), width: 70 * s, height: 80 * s), Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx, cy - 20 * s), 28 * s, Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 22 * s), 14 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 22 * s), 10 * s, Paint()..color = Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFF1744), charge)!);
    c.drawCircle(Offset(cx, cy - 22 * s), 4 * s, Paint()..color = Colors.white);
    c.drawLine(Offset(cx - 16 * s, cy - 36 * s), Offset(cx - 28 * s, cy - 56 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 5 * s);
    c.drawLine(Offset(cx + 16 * s, cy - 36 * s), Offset(cx + 28 * s, cy - 56 * s), Paint()..color = const Color(0xFF212121)..strokeWidth = 5 * s);
    if (flash > 0) c.drawCircle(Offset(cx, cy), 60 * s, Paint()..color = Color.fromRGBO(255, 0, 0, 0.35 * flash));
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

  int combo = 0;
  double comboTimer = 0;
  static const double comboWindow = 2.4;

  double tempDmgMult = 1.0;
  double tempDmgTimer = 0;
  double shieldTimer = 0;
  double _hasteTimer = 0;

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
  int baseStaff = 11, baseStorm = 14, baseWarp = 22;
  int baseDagger = 7, baseNeedle = 9, baseSniperNeedle = 20;
  int baseSword = 12, baseAxe = 14, baseHammer = 28;
  int baseForce = 13, baseForceSword = 16, baseDaemon = 26;
  int baseKatana = 15, basePowerKatana = 18, baseExec = 24;
  int baseMaxHealth = 6;
  double baseSpeed = 210;

  int bolterDamage = 8, rifleDamage = 18, shotgunDamage = 10;
  int staffDamage = 11, stormDamage = 14, warpDamage = 22;
  int daggerDamage = 7, needleDamage = 9, sniperNeedleDamage = 20;
  int swordDamage = 12, axeDamage = 14, hammerDamage = 28;
  int forceDamage = 13, forceSwordDamage = 16, daemonDamage = 26;
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

  // mod unlocks by floor
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

  // ── Synergies ──
  bool get synergyFireCrits => hasCrit && hasKillExplosion; // crit applies burn
  bool get synergyBloodRush => hasLifesteal && hasHaste; // kill: +2 HP chance + longer haste
  bool get synergyTrueFaith => hasShieldPierce && hasCrit; // shield hits can crit fully

  String? get activeSynergyLabel {
    final parts = <String>[];
    if (synergyFireCrits) parts.add('Огненный крит');
    if (synergyBloodRush) parts.add('Кровавый рывок');
    if (synergyTrueFaith) parts.add('Истинная вера');
    return parts.isEmpty ? null : parts.join(' • ');
  }

  // Codex knowledge passives (stack lightly)
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
  double get codexBurnBonus => codexUnlocked.contains(CodexId.flamer) ? 1.0 : 0.0; // +1s burn

  void unlockCodex(CodexId id) {
    if (codexUnlocked.add(id)) {
      // toast via damage number style
      if (isPlaying) {
        world.add(DamageNumber(position: player.position + Vector2(0, -40), amount: 0, color: const Color(0xFFFFD700)));
      }
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
    final chance = hasCrit ? (synergyTrueFaith ? 0.18 : 0.15) : 0.0;
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

  void spawnDamageNumber(Vector2 pos, int amount, {Color color = const Color(0xFFFFEB3B)}) {
    if (amount <= 0) return;
    world.add(DamageNumber(position: pos + Vector2(0, -20), amount: amount, color: color));
  }

  void spawnBlood(Vector2 pos, {int count = 14}) => world.add(BloodSplash(position: pos, count: count));

  void triggerShake({double power = 6, double time = 0.18}) {
    shakePower = max(shakePower, power);
    shakeTime = max(shakeTime, time);
  }

  void registerKill({Vector2? at, bool isBoss = false, bool isChampion = false}) {
    combo++;
    comboTimer = comboWindow;
    if (combo >= 3 && combo % 3 == 0) camera.viewport.add(ComboBanner(combo: combo));
    if (at != null) {
      spawnBlood(at, count: isBoss || isChampion ? 28 : 14);
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
    var gain = isBoss ? (8 + Random().nextInt(8)) : (isChampion ? (5 + Random().nextInt(5)) : (1 + Random().nextInt(3)));
    if (isChampion) gain = (gain * (1 + codexEliteScrapBonus)).round();
    scraps += gain;
    // champion relic chance
    if (isChampion && Random().nextDouble() < 0.22) {
      final missing = RelicId.values.where((r) => !relics.contains(r)).toList();
      if (missing.isNotEmpty) grantRelic(missing[Random().nextInt(missing.length)]);
    }
  }

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2(mapWidth, mapHeight);
    camera.viewfinder.zoom = currentZoom;
    for (int i = 0; i < _sfxPoolSize; i++) _sfxPool.add(AudioPlayer());
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
    try { await _bgmPlayer?.stop(); await _bgmPlayer?.dispose(); } catch (_) {}
    _bgmPlayer = null;
  }

  void applyMusicSetting() {
    if (musicEnabled && isPlaying) startMusic();
    else if (!musicEnabled) stopMusic();
  }

  Future<void> loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hs = prefs.getString('high_scores');
      if (hs != null) {
        highScores = (jsonDecode(hs) as List).map((e) => HighScoreEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      final sv = prefs.getString('game_saves');
      if (sv != null) {
        saves = (jsonDecode(sv) as List).map((e) => GameSave.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      final cu = prefs.getString('customization');
      if (cu != null) custom = Customization.fromJson(Map<String, dynamic>.from(jsonDecode(cu) as Map));
      final cx = prefs.getString('codex');
      if (cx != null) {
        final list = (jsonDecode(cx) as List).map((e) => e.toString());
        codexUnlocked.addAll(list.map((n) => CodexId.values.firstWhere((e) => e.name == n, orElse: () => CodexId.shooter)));
      }
    } catch (_) {}
  }

  Future<void> persistCustomization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customization', jsonEncode(custom.toJson()));
      await prefs.setString('codex', jsonEncode(codexUnlocked.map((e) => e.name).toList()));
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
      name: playerName, floor: currentFloor, level: currentLevel, score: score,
      health: player.health, maxHealth: maxHealth, scraps: scraps,
      bolterDamage: bolterDamage, rifleDamage: rifleDamage, shotgunDamage: shotgunDamage,
      swordDamage: swordDamage, axeDamage: axeDamage, hammerDamage: hammerDamage,
      playerSpeed: playerSpeed, defenseChance: defenseChance,
      ranged: rangedWeapon.name, melee: meleeWeapon.name, usingMelee: usingMelee,
      hasDash: hasDashAbility, hasLaser: hasLaserAbility, ever11: _everReached11, ever21: _everReached21,
      playSeconds: _currentPlaySeconds(), dateIso: DateTime.now().toIso8601String(),
      difficulty: difficulty.name, arenaMode: arenaMode, arenaKills: arenaKills,
      skillPoints: skillPoints, skills: skills.toJson(), custom: custom.toJson(),
      playerClass: playerClass.name, relics: relics.map((e) => e.name).toList(),
      artifact: activeArtifact.name, loadout: loadout.toJson(),
      codex: codexUnlocked.map((e) => e.name).toList(),
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
    relics..clear()..addAll(s.relics.map((n) => RelicId.values.firstWhere((e) => e.name == n, orElse: () => RelicId.crit)));
    codexUnlocked..clear()..addAll(s.codex.map((n) => CodexId.values.firstWhere((e) => e.name == n, orElse: () => CodexId.shooter)));
    loadout = WeaponLoadout.fromJson(s.loadout);
    activeArtifact = ActiveArtifact.values.firstWhere((e) => e.name == s.artifact, orElse: () => ActiveArtifact.fragGrenade);
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
    combo = 0;
    comboTimer = 0;
    tempDmgMult = 1.0;
    tempDmgTimer = 0;
    shieldTimer = 0;
    _hasteTimer = 0;
    currentZoom = 0.85;
    _clearEverything();
    if (arenaMode) _startArenaLevel(); else _startLevel();
    player.health = s.health.clamp(1, maxHealth);
    player.maxHealth = maxHealth;
    for (final o in ['mainMenu', 'loadSave', 'settings', 'nameInput', 'classSelect', 'gameOver', 'levelComplete', 'skills', 'reward', 'shop', 'victory', 'records', 'backpack', 'codex']) {
      overlays.remove(o);
    }
    startMusic();
  }

  void addScoreEntry({bool completed = false, bool fromArena = false}) {
    playSeconds = _currentPlaySeconds();
    highScores.add(HighScoreEntry(playerName, score, playSeconds, floor: currentFloor, level: currentLevel, completed: completed, difficulty: difficulty.name, arena: fromArena || arenaMode, playerClass: playerClass.name));
    highScores.sort((a, b) => b.score.compareTo(a.score));
    if (highScores.length > 15) highScores = highScores.take(15).toList();
    _persistScores();
  }
    List<Vector2> getEnemySpawnPointsRaw() {
    switch (currentFloor) {
      case 1: return [Vector2(180, 280), Vector2(1020, 280), Vector2(180, 900), Vector2(1020, 900), Vector2(600, 550), Vector2(350, 1400), Vector2(850, 1400), Vector2(600, 1100)];
      case 2: return [Vector2(150, 220), Vector2(1050, 220), Vector2(150, 1000), Vector2(1050, 1000), Vector2(600, 450), Vector2(600, 1300), Vector2(400, 700), Vector2(800, 700)];
      case 3: return [Vector2(220, 320), Vector2(980, 320), Vector2(220, 1600), Vector2(980, 1600), Vector2(600, 900), Vector2(180, 900), Vector2(1020, 900), Vector2(600, 500)];
      case 4: return [Vector2(160, 250), Vector2(1040, 250), Vector2(160, 1700), Vector2(1040, 1700), Vector2(600, 700), Vector2(380, 1200), Vector2(820, 1200), Vector2(600, 1500)];
      default: return [Vector2(200, 320), Vector2(1000, 320), Vector2(200, 1600), Vector2(1000, 1600), Vector2(600, 500), Vector2(380, 1000), Vector2(820, 1000), Vector2(600, 1400)];
    }
  }
  List<Vector2> getEnemySpawnPoints() {
    final spawn = playerSpawnPos;
    return getEnemySpawnPointsRaw().where((p) => p.distanceTo(spawn) > safeRadius).toList();
  }
  bool isInSafeZone(Vector2 pos, {double extra = 0}) => pos.distanceTo(playerSpawnPos) < safeRadius + extra;

  void openNameInput() { overlays.remove('mainMenu'); overlays.add('nameInput'); }
  void openLoadSave() { overlays.remove('mainMenu'); overlays.add('loadSave'); }
  void openCodex() {
    if (isPlaying) isPaused = true;
    overlays.remove('mainMenu');
    overlays.add('codex');
  }
  void confirmName(String name, Difficulty diff) {
    playerName = name.trim().isEmpty ? 'Inquisitor' : name.trim();
    difficulty = diff;
    overlays.remove('nameInput');
    overlays.add('classSelect');
  }
  void confirmClass(PlayerClass cls) {
    playerClass = cls;
    overlays.remove('classSelect');
    startGame();
  }

  void startGame() {
    isPlaying = true; isPaused = false; arenaMode = false; arenaKills = 0; arenaWave = 1;
    score = 0; scraps = 0; currentFloor = 1; currentLevel = 1;
    skills = SkillTree(); skillPoints = 0; relics.clear();
    // keep codex across runs (meta) — do not clear codexUnlocked
    loadout = WeaponLoadout();
    activeArtifact = ActiveArtifact.fragGrenade;
    artifactCooldown = 0; holyAuraTimer = 0;
    combo = 0; comboTimer = 0; tempDmgMult = 1.0; tempDmgTimer = 0; shieldTimer = 0; _hasteTimer = 0;
    baseMaxHealth = 6; baseSpeed = 210;
    applyClassDefaults(); recomputeStats();
    portalSpawned = false; isBossLevel = false; isMiniBossLevel = false; nearPortal = false;
    playStartTime = DateTime.now(); playSeconds = 0; _savedPlaySeconds = 0;
    _everReached11 = false; _everReached21 = false;
    secretBossUnlockedThisLevel = false; secretBossSpawned = false; secretBossDefeated = false;
    cornerStandTimer = 0; dashCooldown = 0; dashActive = 0; laserCooldown = 0;
    hasLaserAbility = false;
    currentZoom = 0.85; shakeTime = 0; shakePower = 0;
    _clearEverything();
    _startLevel();
    for (final o in ['mainMenu', 'nameInput', 'classSelect', 'settings', 'gameOver', 'levelComplete', 'skills', 'reward', 'shop', 'victory', 'records', 'backpack', 'loadSave', 'codex']) {
      overlays.remove(o);
    }
    startMusic();
  }

  void startArena() {
    overlays.remove('victory');
    arenaMode = true; arenaKills = 0; arenaWave = 1;
    isPlaying = true; isPaused = false; portalSpawned = false; nearPortal = false;
    isBossLevel = false; isMiniBossLevel = false; currentFloor = 5; currentLevel = 5;
    _clearEverything(); _startArenaLevel(); startMusic();
  }
  void finishAfterVictory() { addScoreEntry(completed: true); backToMenu(); }

  void _clearEverything() {
    world.removeAll(world.children.toList());
    camera.viewport.children.whereType<JoystickComponent>().toList().forEach((c) => c.removeFromParent());
    camera.viewport.children.whereType<HudButtonComponent>().toList().forEach((c) => c.removeFromParent());
    camera.viewport.children.whereType<HudLabel>().toList().forEach((c) => c.removeFromParent());
    camera.viewport.children.whereType<ComboBanner>().toList().forEach((c) => c.removeFromParent());
    portalButton = null; dashButton = null; laserButton = null; artifactButton = null;
  }

  CircleComponent _btn(Color c, double r) => CircleComponent(radius: r, paint: Paint()..color = c);

  void _addHud() {
    moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.38, paint: Paint()..color = const Color(0xFF8B0000)),
      background: CircleComponent(radius: joystickSize, paint: Paint()..color = const Color(0xFF2F2F2F).withOpacity(0.75)),
      margin: const EdgeInsets.only(left: 28, bottom: 35),
    );
    attackJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.35, paint: Paint()..color = const Color(0xFF00BCD4)),
      background: CircleComponent(radius: joystickSize * 0.95, paint: Paint()..color = const Color(0xFF006064).withOpacity(0.7)),
      margin: const EdgeInsets.only(right: 28, bottom: 35),
    );
    final br = (buttonSize * 0.55).clamp(18.0, 36.0);
    switchWeaponButton = HudButtonComponent(
      button: _btn(Colors.grey[800]!, br), buttonDown: _btn(Colors.grey, br),
      margin: const EdgeInsets.only(right: 32, bottom: 160),
      onPressed: () { if (isPlaying && !isPaused) { usingMelee = !usingMelee; playClick(); } },
    );
    backpackButton = HudButtonComponent(
      button: _btn(const Color(0xFF5D4037), br * 0.93), buttonDown: _btn(const Color(0xFF8D6E63), br * 0.93),
      margin: const EdgeInsets.only(right: 32, top: 150),
      onPressed: () { if (isPlaying) { isPaused = true; playClick(); overlays.add('backpack'); } },
    );
    settingsButton = HudButtonComponent(
      button: _btn(const Color(0xFF37474F), br * 0.93), buttonDown: _btn(Colors.blueGrey, br * 0.93),
      margin: const EdgeInsets.only(right: 32, top: 90),
      onPressed: () { if (isPlaying) { isPaused = true; playClick(); overlays.add('settings'); } },
    );
    zoomInButton = HudButtonComponent(
      button: _btn(const Color(0xFF455A64), br * 0.85), buttonDown: _btn(Colors.blueGrey[400]!, br * 0.85),
      margin: const EdgeInsets.only(left: 28, top: 90),
      onPressed: () { currentZoom = (currentZoom + 0.12).clamp(0.55, 1.5); camera.viewfinder.zoom = currentZoom; playClick(); },
    );
    zoomOutButton = HudButtonComponent(
      button: _btn(const Color(0xFF455A64), br * 0.85), buttonDown: _btn(Colors.blueGrey[400]!, br * 0.85),
      margin: const EdgeInsets.only(left: 28, top: 150),
      onPressed: () { currentZoom = (currentZoom - 0.12).clamp(0.55, 1.5); camera.viewfinder.zoom = currentZoom; playClick(); },
    );
    // Artifact R
    artifactButton = HudButtonComponent(
      button: _btn(const Color(0xFFBF360C), br * 0.9), buttonDown: _btn(const Color(0xFFFF6D00), br * 0.9),
      margin: const EdgeInsets.only(left: 28, top: 330),
      onPressed: activateArtifact,
    );
    player = Player(moveJoystick);
    world.add(player);
    camera.viewport.add(moveJoystick);
    camera.viewport.add(attackJoystick);
    camera.viewport.add(switchWeaponButton);
    camera.viewport.add(backpackButton);
    camera.viewport.add(settingsButton);
    camera.viewport.add(zoomInButton);
    camera.viewport.add(zoomOutButton);
    camera.viewport.add(artifactButton!);
    camera.viewport.add(HudLabel(text: '+', margin: const EdgeInsets.only(left: 40, top: 98)));
    camera.viewport.add(HudLabel(text: '-', margin: const EdgeInsets.only(left: 42, top: 158)));
    camera.viewport.add(HudLabel(text: 'S', margin: const EdgeInsets.only(right: 48, top: 98)));
    camera.viewport.add(HudLabel(text: 'B', margin: const EdgeInsets.only(right: 48, top: 158)));
    camera.viewport.add(HudLabel(text: 'A', margin: const EdgeInsets.only(right: 48, bottom: 168)));
    camera.viewport.add(HudLabel(text: 'M', margin: const EdgeInsets.only(left: 58, bottom: 50)));
    camera.viewport.add(HudLabel(text: 'F', margin: const EdgeInsets.only(right: 58, bottom: 50)));
    camera.viewport.add(HudLabel(text: 'R', margin: const EdgeInsets.only(left: 40, top: 338)));
    if (hasDashAbility) _ensureDashButton();
    if (hasLaserAbility) _ensureLaserButton();
    camera.follow(player);
    camera.viewfinder.zoom = currentZoom;
  }

  void _spawnLoot() {
    final rnd = Random();
    for (int i = 0; i < 1 + rnd.nextInt(2); i++) {
      final p = Vector2(150 + rnd.nextDouble() * (mapWidth - 300), 200 + rnd.nextDouble() * (mapHeight - 400));
      if (!isInSafeZone(p, extra: 40)) world.add(MedkitPickup(position: p)..priority = 7);
    }
    if (rnd.nextDouble() < 0.65) {
      final p = Vector2(150 + rnd.nextDouble() * (mapWidth - 300), 200 + rnd.nextDouble() * (mapHeight - 400));
      if (!isInSafeZone(p, extra: 40)) world.add(ShieldPickup(position: p)..priority = 7);
    }
  }

  void _startLevel() {
    enemiesSpawned = 0; enemiesAlive = 0; portalSpawned = false; nearPortal = false;
    isBossLevel = currentLevel == 5; isMiniBossLevel = currentLevel == 3;
    spawnTimer = 0; spawnInterval = max(0.40, 1.25 - (currentFloor * 0.1) - (currentLevel * 0.06));
    secretBossUnlockedThisLevel = false; secretBossSpawned = false; cornerStandTimer = 0;
    combo = 0; comboTimer = 0;
    _checkUnlocks(); recomputeStats();
    world.add(Floor(size: Vector2(mapWidth, mapHeight))..priority = 0);
    _createWalls(); _createObstacles(); _spawnLoot();
    for (final pos in getEnemySpawnPoints()) world.add(EnemySpawnPortal(position: pos)..priority = 3);
    world.add(PlayerSpawnPoint(position: playerSpawnPos.clone())..priority = 3);
    _addHud();
    if (isBossLevel) {
      _spawnBosses();
    } else if (isMiniBossLevel) {
      enemiesToSpawn = 1; enemiesAlive = 1; enemiesSpawned = 1;
      world.add(MiniBoss(floor: currentFloor, position: Vector2(mapWidth / 2, mapHeight / 2 - 220))..priority = 24);
    } else {
      enemiesToSpawn = 6 + (currentLevel * 2) + (currentFloor * 3);
      enemiesToSpawn = (enemiesToSpawn * worldThreat * 0.85).round();
      if (difficulty == Difficulty.hard) enemiesToSpawn = (enemiesToSpawn * 1.2).round();
      if (difficulty == Difficulty.easy) enemiesToSpawn = max(4, (enemiesToSpawn * 0.85).round());
      // 1–2 champions planned among spawns
    }
  }

  void _startArenaLevel() {
    enemiesSpawned = 0; enemiesAlive = 0; enemiesToSpawn = 999999;
    portalSpawned = false; nearPortal = false; isBossLevel = false; isMiniBossLevel = false;
    spawnTimer = 0; spawnInterval = 0.85;
    secretBossUnlockedThisLevel = false; secretBossSpawned = false; cornerStandTimer = 0;
    _checkUnlocks(); recomputeStats();
    world.add(Floor(size: Vector2(mapWidth, mapHeight))..priority = 0);
    _createWalls(); _createObstacles(); _spawnLoot();
    for (final pos in getEnemySpawnPoints()) world.add(EnemySpawnPortal(position: pos)..priority = 3);
    world.add(PlayerSpawnPoint(position: playerSpawnPos.clone())..priority = 3);
    _addHud();
  }

  void showPortalButton() {
    if (portalButton != null) return;
    portalButton = HudButtonComponent(
      button: _btn(const Color(0xFFE91E63), 32), buttonDown: _btn(const Color(0xFFF48FB1), 32),
      margin: const EdgeInsets.only(bottom: 200), anchor: Anchor.bottomCenter,
      onPressed: () { if (isPlaying && !isPaused && portalSpawned) goToNextLevel(); },
    );
    camera.viewport.add(portalButton!);
    camera.viewport.add(HudLabel(text: 'P', margin: const EdgeInsets.only(bottom: 210)));
  }
  void hidePortalButton() { portalButton?.removeFromParent(); portalButton = null; }

  void _ensureDashButton() {
    if (dashButton != null) return;
    dashButton = HudButtonComponent(
      button: _btn(const Color(0xFF6A1B9A), 26), buttonDown: _btn(const Color(0xFF9C27B0), 26),
      margin: const EdgeInsets.only(left: 28, top: 210), onPressed: activateDash,
    );
    camera.viewport.add(dashButton!);
    camera.viewport.add(HudLabel(text: 'U', margin: const EdgeInsets.only(left: 40, top: 218)));
  }
  void _ensureLaserButton() {
    if (laserButton != null) return;
    laserButton = HudButtonComponent(
      button: _btn(const Color(0xFFFF6D00), 26), buttonDown: _btn(const Color(0xFFFFAB40), 26),
      margin: const EdgeInsets.only(left: 28, top: 270), onPressed: activateLaser,
    );
    camera.viewport.add(laserButton!);
    camera.viewport.add(HudLabel(text: 'L', margin: const EdgeInsets.only(left: 40, top: 278)));
  }

  void activateDash() {
    if (!hasDashAbility || dashCooldown > 0 || dashActive > 0 || !isPlaying || isPaused) return;
    dashActive = playerClass == PlayerClass.hereticus ? 2.6 : 2.0;
    dashCooldown = playerClass == PlayerClass.hereticus ? 5.0 : 6.0;
    if (playerClass == PlayerClass.hereticus) {
      final d = player.aimDir.length2 < 0.01 ? Vector2(0, -1) : player.aimDir;
      player.position += d * 90;
    }
  }

  void activateLaser() {
    if (!hasLaserAbility || laserCooldown > 0 || !isPlaying || isPaused) return;
    laserCooldown = 20.0;
    playShoot();
    final d = player.aimDir.length2 < 0.01 ? Vector2(0, -1) : player.aimDir;
    world.add(CyclopsLaserBeam(position: player.position.clone(), direction: d, damage: scaleDamage(45 + overallLevel * 2))..priority = 14);
    triggerShake(power: 8, time: 0.2);
  }

  void activateArtifact() {
    if (!isPlaying || isPaused || artifactCooldown > 0) return;
    artifactCooldown = activeArtifact.cooldown;
    playShoot();
    final d = player.aimDir.length2 < 0.01 ? Vector2(0, -1) : player.aimDir;
    switch (activeArtifact) {
      case ActiveArtifact.fragGrenade:
        world.add(FragGrenade(position: player.position + d * 40, direction: d, damage: scaleDamage(18 + overallLevel))..priority = 14);
        break;
      case ActiveArtifact.holyAura:
        holyAuraTimer = 8.0;
        break;
      case ActiveArtifact.servoTurret:
        world.add(ServoTurret(position: player.position + d * 50)..priority = 14);
        break;
    }
  }

  void _spawnSecretBoss() {
    secretBossSpawned = true;
    secretBossUnlockedThisLevel = false;
    cornerStandTimer = 0;
    enemiesAlive++; enemiesToSpawn++; enemiesSpawned++;
    if (overallLevel == 10) {
      world.add(CyclopsBoss(position: Vector2(mapWidth / 2, mapHeight / 2 - 120))..priority = 28);
    } else {
      world.add(TentacleBoss(position: Vector2(mapWidth / 2, mapHeight / 2 - 120))..priority = 28);
    }
  }

  void onSecretBossKilled({bool cyclops = false}) {
    secretBossDefeated = true;
    score += 6666;
    skillPoints += 2;
    scraps += 25;
    enemiesAlive = max(0, enemiesAlive - 1);
    triggerShake(power: 12, time: 0.35);
    if (cyclops) {
      hasLaserAbility = true;
      unlockCodex(CodexId.cyclops);
      _ensureLaserButton();
    } else {
      hasDashAbility = true;
      unlockCodex(CodexId.tentacle);
      _ensureDashButton();
    }
  }

  void _spawnBosses() {
    enemiesToSpawn = 1; enemiesAlive = 1; enemiesSpawned = 1;
    world.add(Boss(floor: currentFloor, position: Vector2(mapWidth / 2 - 140, mapHeight / 2 - 240))..priority = 25);
    if (overallLevel >= 15) {
      enemiesToSpawn++; enemiesAlive++; enemiesSpawned++;
      world.add(KnightBoss(floor: currentFloor, position: Vector2(mapWidth / 2 + 140, mapHeight / 2 - 240))..priority = 25);
    }
    if (overallLevel == 25) {
      enemiesToSpawn++; enemiesAlive++; enemiesSpawned++;
      world.add(KingBoss(position: Vector2(mapWidth / 2, mapHeight / 2 - 380))..priority = 26);
    }
  }

  void _spawnArenaBoss() {
    enemiesAlive++; enemiesSpawned++;
    final r = Random().nextInt(4);
    final pos = Vector2(mapWidth / 2 + (Random().nextDouble() - 0.5) * 200, mapHeight / 2 - 200);
    switch (r) {
      case 0: world.add(Boss(floor: 5, position: pos)..priority = 25); break;
      case 1: world.add(KnightBoss(floor: 5, position: pos)..priority = 25); break;
      case 2: world.add(KingBoss(position: pos)..priority = 26); break;
      default: world.add(MiniBoss(floor: 5, position: pos)..priority = 24); break;
    }
    triggerShake(power: 10, time: 0.3);
  }

  void _createWalls() {
    const t = 48.0;
    final brown = const Color(0xFF5D4037);
    void border(Vector2 p, Vector2 s) => world.add(Wall(position: p, size: s, color: brown)..priority = 5);
    border(Vector2(0, 0), Vector2(mapWidth, t));
    border(Vector2(0, mapHeight - t), Vector2(mapWidth, t));
    border(Vector2(0, 0), Vector2(t, mapHeight));
    border(Vector2(mapWidth - t, 0), Vector2(t, mapHeight));
    void inner(Vector2 p, Vector2 s) {
      if (isInSafeZone(p + s / 2, extra: 50)) return;
      world.add(Wall(position: p, size: s, color: brown)..priority = 5);
    }
    switch (currentFloor) {
      case 1: inner(Vector2(480, 850), Vector2(240, 32)); break;
      case 2: inner(Vector2(360, 180), Vector2(32, 560)); inner(Vector2(800, 180), Vector2(32, 560)); break;
      case 3: inner(Vector2(520, 240), Vector2(32, 520)); inner(Vector2(180, 900), Vector2(300, 32)); break;
      case 4: inner(Vector2(240, 280), Vector2(220, 32)); inner(Vector2(380, 920), Vector2(360, 32)); break;
      case 5:
        for (final p in [Vector2(220, 400), Vector2(920, 400), Vector2(220, 900), Vector2(920, 900)]) {
          inner(p, Vector2(60, 60));
        }
        break;
    }
  }

  void _createObstacles() {
    for (final pos in [Vector2(320, 700), Vector2(880, 1050), Vector2(600, 1300), Vector2(450, 480), Vector2(750, 780)]) {
      if (isInSafeZone(pos, extra: 30)) continue;
      world.add(Obstacle(position: pos)..priority = 5);
    }
  }

  void _spawnOneEnemy() {
    if (!arenaMode && enemiesSpawned >= enemiesToSpawn) return;
    final points = getEnemySpawnPoints();
    if (points.isEmpty) return;
    enemiesSpawned++; enemiesAlive++;
    // champions: ~18% after level 3, up to 2 per level
    final champsNow = world.children.whereType<Enemy>().where((e) => e.isChampion).length;
    final wantChamp = !isBossLevel && !isMiniBossLevel && champsNow < 2 && overallLevel >= 3 && Random().nextDouble() < 0.18;
    final enemy = Enemy(floor: arenaMode ? min(5, 1 + arenaWave ~/ 3) : currentFloor, type: _chooseEnemyType(), isChampion: wantChamp);
    enemy.position = points[Random().nextInt(points.length)].clone();
    enemy.priority = 30;
    world.add(enemy);
  }

  EnemyType _chooseEnemyType() {
    final roll = Random().nextDouble();
    final lvl = arenaMode ? 20 + arenaWave : overallLevel;
    if (lvl >= 18) {
      if (roll < 0.15) return EnemyType.brute;
      if (roll < 0.30) return EnemyType.sniper;
      if (roll < 0.45) return EnemyType.flamer;
      if (roll < 0.55) return EnemyType.dog;
      if (roll < 0.70) return EnemyType.shieldedShooter;
      if (roll < 0.82) return EnemyType.shielded;
      return roll < 0.91 ? EnemyType.shooter : EnemyType.melee;
    }
    if (lvl >= 11) {
      if (roll < 0.18) return EnemyType.flamer;
      if (roll < 0.32) return EnemyType.sniper;
      if (roll < 0.48) return EnemyType.dog;
      if (roll < 0.65) return EnemyType.melee;
      if (roll < 0.82) return EnemyType.shooter;
      return EnemyType.shielded;
    }
    if (lvl >= 6) {
      if (roll < 0.15) return EnemyType.flamer;
      if (roll < 0.40) return EnemyType.melee;
      if (roll < 0.70) return EnemyType.shooter;
      return EnemyType.shielded;
    }
    return roll < 0.55 ? EnemyType.melee : EnemyType.shooter;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (shakeTime > 0) {
      shakeTime -= dt;
      final ox = (Random().nextDouble() - 0.5) * 2 * shakePower;
      final oy = (Random().nextDouble() - 0.5) * 2 * shakePower;
      if (isPlaying && world.children.whereType<Player>().isNotEmpty) {
        camera.viewfinder.position = player.position + Vector2(ox, oy);
      }
      if (shakeTime <= 0) shakePower = 0;
    }
    if (!isPlaying || isPaused) return;

    if (comboTimer > 0) { comboTimer -= dt; if (comboTimer <= 0) combo = 0; }
    if (tempDmgTimer > 0) { tempDmgTimer -= dt; if (tempDmgTimer <= 0) tempDmgMult = 1.0; }
    if (shieldTimer > 0) shieldTimer = max(0, shieldTimer - dt);
    if (_hasteTimer > 0) _hasteTimer = max(0, _hasteTimer - dt);
    if (dashCooldown > 0) dashCooldown = max(0, dashCooldown - dt);
    if (dashActive > 0) dashActive = max(0, dashActive - dt);
    if (laserCooldown > 0) laserCooldown = max(0, laserCooldown - dt);
    if (artifactCooldown > 0) artifactCooldown = max(0, artifactCooldown - dt);
    if (holyAuraTimer > 0) {
      holyAuraTimer = max(0, holyAuraTimer - dt);
      // damage nearby enemies lightly
      for (final e in world.children.whereType<Enemy>().toList()) {
        if (e.position.distanceTo(player.position) < 110) {
          e.applyStatus(StatusType.corruption, 0.6, tickDamage: 1);
        }
      }
    }

    for (final ex in world.children.whereType<KillExplosion>().toList()) {
      for (final e in world.children.whereType<Enemy>().toList()) {
        if (e.position.distanceTo(ex.position) < ex.radius + 20) {
          e.applyDamage(ex.damage);
          if (ex.applyBurn) e.applyStatus(StatusType.burn, 2.0 + codexBurnBonus, tickDamage: 1);
        }
      }
    }

    if (arenaMode) {
      if (enemiesAlive < 6 + arenaWave.clamp(0, 10)) {
        spawnTimer += dt;
        if (spawnTimer >= max(0.35, spawnInterval - arenaWave * 0.03)) {
          spawnTimer = 0; _spawnOneEnemy();
        }
      }
    } else if (!isBossLevel && !isMiniBossLevel && !secretBossSpawned && enemiesSpawned < enemiesToSpawn) {
      spawnTimer += dt;
      if (spawnTimer >= spawnInterval) { spawnTimer = 0; _spawnOneEnemy(); }
    }

    if (portalSpawned && !arenaMode) {
      bool near = false;
      for (final p in world.children.whereType<Portal>()) {
        if (player.position.distanceTo(p.position) < 100) { near = true; break; }
      }
      if (near && !nearPortal) { nearPortal = true; showPortalButton(); }
      else if (!near && nearPortal) { nearPortal = false; hidePortalButton(); }
    }

    if (secretBossUnlockedThisLevel && !secretBossSpawned && portalSpawned) {
      final inCorner = player.position.x < 140 && player.position.y < 140;
      if (inCorner) {
        cornerStandTimer += dt;
        if (cornerStandTimer >= 33) _spawnSecretBoss();
      } else {
        cornerStandTimer = 0;
      }
    }
  }

  void onEnemyKilled({bool isBoss = false, Vector2? at, bool isChampion = false, EnemyType? type}) {
    enemiesAlive = max(0, enemiesAlive - 1);
    registerKill(at: at, isBoss: isBoss, isChampion: isChampion);
    if (type != null) {
      final map = {
        EnemyType.shooter: CodexId.shooter,
        EnemyType.melee: CodexId.melee,
        EnemyType.shielded: CodexId.shielded,
        EnemyType.dog: CodexId.dog,
        EnemyType.shieldedShooter: CodexId.shieldedShooter,
        EnemyType.flamer: CodexId.flamer,
        EnemyType.sniper: CodexId.sniper,
        EnemyType.brute: CodexId.brute,
      };
      unlockCodex(map[type]!);
    }
    if (isChampion) unlockCodex(CodexId.champion);
    final points = ((isBossLevel || isMiniBossLevel || isBoss) ? 180 + (currentFloor * 60) : 12 + (currentFloor * 6));
    final champBonus = isChampion ? 40 : 0;
    score += ((points + champBonus) * comboMult).round();
    if (arenaMode) {
      arenaKills++;
      if (arenaKills % 100 == 0) { arenaWave++; skillPoints += 1; _spawnArenaBoss(); }
      return;
    }
    if (isBoss) triggerShake(power: 10, time: 0.28);
    if (enemiesAlive <= 0 && enemiesSpawned >= enemiesToSpawn && !portalSpawned) {
      portalSpawned = true;
      world.add(Portal(position: Vector2(mapWidth / 2, mapHeight / 2))..priority = 9);
      if (overallLevel == 5 || overallLevel == 10) secretBossUnlockedThisLevel = true;
    }
  }

  List<RewardOption> _rollRewards() {
    final rnd = Random();
    final pool = <RewardOption>[RewardOption.skillPoint(), RewardOption.coins(12 + rnd.nextInt(18)), RewardOption.heal()];
    final missing = RelicId.values.where((r) => !relics.contains(r)).toList();
    if (missing.isNotEmpty) pool.add(RewardOption.relic(missing[rnd.nextInt(missing.length)]));
    else pool.add(RewardOption.coins(20 + rnd.nextInt(15)));
    pool.add(RewardOption.tempBuff());
    // artifact unlock options
    pool.add(RewardOption.artifact(ActiveArtifact.values[rnd.nextInt(ActiveArtifact.values.length)]));
    pool.shuffle(rnd);
    return pool.take(3).toList();
  }

  void goToNextLevel() {
    isPlaying = false; hidePortalButton(); nearPortal = false;
    skillPoints += isBossLevel ? 1 : 0;
    if (currentFloor == 5 && currentLevel == 5) { stopMusic(); overlays.add('victory'); return; }
    pendingRewards = _rollRewards();
    overlays.add('reward');
  }
  void finishRewardThenShop() { overlays.remove('reward'); overlays.add('shop'); }
  void finishShopThenSkills() {
    overlays.remove('shop');
    if (skillPoints > 0) overlays.add('skills'); else finishSkillsAndContinue();
  }
  void finishSkillsAndContinue() {
    overlays.remove('skills');
    if (currentLevel == 5) { currentFloor++; currentLevel = 1; } else { currentLevel++; }
    overlays.add('levelComplete');
  }
  void nextLevel() {
    overlays.remove('levelComplete');
    _clearEverything();
    isPlaying = true; isPaused = false;
    _startLevel();
  }

  void openSettings() { overlays.remove('mainMenu'); overlays.add('settings'); }
  void closeSettings() { overlays.remove('settings'); isPaused = false; persistCustomization(); }
  void closeBackpack() { overlays.remove('backpack'); isPaused = false; }
  void closeCodex() {
    overlays.remove('codex');
    if (isPlaying) isPaused = false; else overlays.add('mainMenu');
  }

  void exitMatch() {
    stopMusic(); isPlaying = false; isPaused = false; hidePortalButton();
    addScoreEntry(completed: false, fromArena: arenaMode); arenaMode = false; _clearEverything();
    for (final o in ['settings', 'gameOver', 'levelComplete', 'skills', 'reward', 'shop', 'victory', 'records', 'nameInput', 'classSelect', 'backpack', 'loadSave', 'codex']) {
      overlays.remove(o);
    }
    overlays.add('mainMenu');
  }
  void backToMenu() {
    stopMusic(); isPlaying = false; isPaused = false; arenaMode = false; _clearEverything();
    for (final o in ['settings', 'gameOver', 'levelComplete', 'skills', 'reward', 'shop', 'victory', 'records', 'nameInput', 'classSelect', 'backpack', 'loadSave', 'codex']) {
      overlays.remove(o);
    }
    overlays.add('mainMenu');
  }
  void showGameOver() {
    stopMusic(); isPlaying = false; hidePortalButton();
    addScoreEntry(completed: false, fromArena: arenaMode);
    overlays.add('gameOver');
  }

  bool get areOtherBossesAlive =>
      world.children.whereType<Boss>().isNotEmpty || world.children.whereType<KnightBoss>().isNotEmpty;

  String get currentWeaponName {
    if (usingMelee) return meleeWeapon.name.toUpperCase();
    return rangedWeapon.name.toUpperCase();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isPlaying) return;
    if (arenaMode) {
      hudPaint.render(canvas, 'АРЕНА W$arenaWave', Vector2(14, 14));
      hudPaint.render(canvas, 'Kills: $arenaKills', Vector2(14, 34));
    } else {
      hudPaint.render(canvas, 'F$currentFloor L$currentLevel', Vector2(14, 14));
      hudPaint.render(canvas, 'Enemies: $enemiesAlive', Vector2(14, 74));
    }
    hudPaint.render(canvas, 'Score: $score', Vector2(14, arenaMode ? 54 : 34));
    hudPaint.render(canvas, 'HP: ${player.health}/${player.maxHealth}', Vector2(14, arenaMode ? 74 : 54));
    hudPaint.render(canvas, '${playerClass.title} | $currentWeaponName', Vector2(14, 94));
    hudPaint.render(canvas, 'Scraps: $scraps  SP: $skillPoints', Vector2(14, 114));
    if (combo > 1) hudPaint.render(canvas, 'COMBO x$combo', Vector2(14, 134));
    if (artifactCooldown > 0) {
      hudPaint.render(canvas, 'R ${artifactCooldown.toStringAsFixed(0)}s', Vector2(14, 154));
    } else {
      hudPaint.render(canvas, 'R: ${activeArtifact.title}', Vector2(14, 154));
    }
    if (holyAuraTimer > 0) hudPaint.render(canvas, 'AURA ${holyAuraTimer.toStringAsFixed(1)}s', Vector2(14, 174));
    final syn = activeSynergyLabel;
    if (syn != null) hudPaint.render(canvas, syn, Vector2(14, 194));
  }
}

enum RewardKind { skillPoint, relic, coins, heal, tempBuff, artifact }
class RewardOption {
  final RewardKind kind; final RelicId? relic; final int coins; final ActiveArtifact? artifact;
  RewardOption._(this.kind, {this.relic, this.coins = 0, this.artifact});
  factory RewardOption.skillPoint() => RewardOption._(RewardKind.skillPoint);
  factory RewardOption.relic(RelicId r) => RewardOption._(RewardKind.relic, relic: r);
  factory RewardOption.coins(int n) => RewardOption._(RewardKind.coins, coins: n);
  factory RewardOption.heal() => RewardOption._(RewardKind.heal);
  factory RewardOption.tempBuff() => RewardOption._(RewardKind.tempBuff);
  factory RewardOption.artifact(ActiveArtifact a) => RewardOption._(RewardKind.artifact, artifact: a);
  String get title {
    switch (kind) {
      case RewardKind.skillPoint: return '+1 Очко навыка';
      case RewardKind.relic: return relic!.title;
      case RewardKind.coins: return '+$coins обломков';
      case RewardKind.heal: return 'Полное лечение';
      case RewardKind.tempBuff: return 'Бафф урона ×1.25';
      case RewardKind.artifact: return 'Артефакт: ${artifact!.title}';
    }
  }
  String get subtitle {
    switch (kind) {
      case RewardKind.skillPoint: return 'В меню навыков';
      case RewardKind.relic: return relic!.desc;
      case RewardKind.coins: return 'Для магазина';
      case RewardKind.heal: return 'Восстановить HP';
      case RewardKind.tempBuff: return 'На следующий уровень';
      case RewardKind.artifact: return artifact!.desc;
    }
  }
  void apply(InquisitorGame g) {
    switch (kind) {
      case RewardKind.skillPoint: g.skillPoints++; break;
      case RewardKind.relic: if (relic != null) g.grantRelic(relic!); break;
      case RewardKind.coins: g.scraps += coins; break;
      case RewardKind.heal:
        if (g.world.children.whereType<Player>().isNotEmpty) g.player.health = g.player.maxHealth;
        break;
      case RewardKind.tempBuff: g.tempDmgMult = 1.25; g.tempDmgTimer = 9999; break;
      case RewardKind.artifact: if (artifact != null) g.activeArtifact = artifact!; break;
    }
  }
}
class HudLabel extends PositionComponent with HasGameReference<InquisitorGame> {
  final String text; final EdgeInsets margin;
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
      text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset.zero);
  }
}

mixin SmartMover on PositionComponent, HasGameReference<InquisitorGame> {
  double stuckTimer = 0; Vector2? avoidDir; double strafeSign = 1; double rethinkTimer = 0;
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
      if (dist < preferDist * 0.75) desired = -desired;
      else if (dist < preferDist * 1.15) desired = Vector2(-desired.y, desired.x) * strafeSign;
    }
    Vector2 sep = Vector2.zero();
    for (final e in game.world.children.whereType<Enemy>()) {
      if (identical(e, this)) continue;
      final d = position.distanceTo(e.position);
      if (d > 0 && d < radius * 2.4) sep += (position - e.position).normalized() * ((radius * 2.4 - d) / (radius * 2.4));
    }
    if (sep.length2 > 0.01) desired = (desired + sep.normalized() * 0.55).normalized();
    if (avoidDir != null) {
      stuckTimer -= dt;
      if (stuckTimer <= 0) avoidDir = null;
      else desired = (desired * 0.35 + avoidDir! * 0.65).normalized();
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
        position = n1; avoidDir = slide1; stuckTimer = 0.55;
      } else if (_canStand(n2, radius)) {
        position = n2; avoidDir = slide2; stuckTimer = 0.55;
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
      if (Rect.fromLTRB(r.left - radius, r.top - radius, r.right + radius, r.bottom + radius).contains(pos.toOffset())) return false;
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
  EnemySpawnPortal({required Vector2 position}) : super(position: position, size: Vector2(48, 48), anchor: Anchor.center, priority: 3);
  @override void update(double dt) { super.update(dt); flicker += dt * 4; }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 18, Paint()..color = Color.fromRGBO(255, 140, 0, 0.45 + 0.4 * sin(flicker)));
  }
}

class PlayerSpawnPoint extends PositionComponent {
  PlayerSpawnPoint({required Vector2 position}) : super(position: position, size: Vector2(56, 56), anchor: Anchor.center, priority: 3);
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
    for (double x = 0; x < size.x; x += 60) canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    for (double y = 0; y < size.y; y += 60) canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  final Color color;
  Wall({required Vector2 position, required Vector2 size, required this.color}) : super(position: position, size: size, priority: 5);
  @override Future<void> onLoad() async => add(RectangleHitbox());
  @override void render(Canvas canvas) => canvas.drawRect(size.toRect(), Paint()..color = color);
}

class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({required Vector2 position}) : super(position: position, size: Vector2(56, 56), anchor: Anchor.center, priority: 5);
  @override Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)), Paint()..color = const Color(0xFF6D4C41));
  }
}

class Portal extends PositionComponent with CollisionCallbacks {
  Portal({required Vector2 position}) : super(position: position, size: Vector2(88, 88), anchor: Anchor.center, priority: 9);
  @override Future<void> onLoad() async => add(CircleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawCircle((size / 2).toOffset(), 38, Paint()..color = const Color(0xFFE91E63).withOpacity(0.85));
  }
}

class MedkitPickup extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  MedkitPickup({required Vector2 position}) : super(position: position, size: Vector2(36, 36), anchor: Anchor.center, priority: 7);
  @override Future<void> onLoad() async => add(CircleHitbox());
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
  ShieldPickup({required Vector2 position}) : super(position: position, size: Vector2(36, 36), anchor: Anchor.center, priority: 7);
  @override Future<void> onLoad() async => add(CircleHitbox());
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

/// Artifact: frag grenade
class FragGrenade extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 velocity;
  final int damage;
  double life = 0.9;
  FragGrenade({required Vector2 position, required Vector2 direction, required this.damage})
      : velocity = direction.normalized() * 320,
        super(position: position.clone(), size: Vector2(20, 20), anchor: Anchor.center, priority: 14);
  @override Future<void> onLoad() async => add(CircleHitbox(radius: 10));
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

/// Artifact: servo turret
class ServoTurret extends PositionComponent with HasGameReference<InquisitorGame> {
  double life = 8.0;
  double shootTimer = 0;
  ServoTurret({required Vector2 position}) : super(position: position.clone(), size: Vector2(40, 40), anchor: Anchor.center, priority: 14);
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) { removeFromParent(); return; }
    shootTimer += dt;
    if (shootTimer >= 0.45) {
      shootTimer = 0;
      Enemy? nearest;
      double best = 420;
      for (final e in game.world.children.whereType<Enemy>()) {
        final d = e.position.distanceTo(position);
        if (d < best) { best = d; nearest = e; }
      }
      if (nearest != null) {
        final dir = (nearest.position - position).normalized();
        game.world.add(Bullet(
          position: position.clone(),
          direction: dir,
          damage: game.scaleDamage(6 + game.overallLevel ~/ 2),
          color: const Color(0xFFFFAB40),
          speed: 480,
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

// ─── Menus ───────────────────────────────────────────────
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('ВЫБОР ОРДО', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
            Text(game.playerName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Expanded(child: ListView(children: [
              _card(PlayerClass.xenos, const Color(0xFFB71C1C), 'HP 6 • Скорость норм • Болтер'),
              _card(PlayerClass.malleus, const Color(0xFF1A237E), 'HP 5 • Медленнее • +12% пси-урон'),
              _card(PlayerClass.hereticus, const Color(0xFF4A148C), 'HP 5 • Быстрее • Рывок U'),
            ])),
          ]),
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
        onTap: () { game.playClick(); game.confirmClass(cls); },
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('НАГРАДА УРОВНЯ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...game.pendingRewards.map((o) => Card(
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                title: Text(o.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(o.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () { game.playClick(); o.apply(game); game.finishRewardThenShop(); },
              ),
            )),
          ]),
        ),
      ),
    );
  }
}

class ShopMenu extends StatefulWidget {
  final InquisitorGame game;
  const ShopMenu(this.game, {super.key});
  @override State<ShopMenu> createState() => _ShopMenuState();
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('МАГАЗИН', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Обломки: ${g.scraps}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            _item('+2 HP', 8, () {
              if (g.scraps < 8) return;
              g.scraps -= 8;
              if (g.world.children.whereType<Player>().isNotEmpty) g.player.health = min(g.player.maxHealth, g.player.health + 2);
              setState(() {});
            }),
            _item('+1 SP', 15, () {
              if (g.scraps < 15) return;
              g.scraps -= 15; g.skillPoints++; setState(() {});
            }),
            _item('Урон ×1.3', 12, () {
              if (g.scraps < 12) return;
              g.scraps -= 12; g.tempDmgMult = 1.3; g.tempDmgTimer = 9999; setState(() {});
            }),
            _item('Щит 8с', 10, () {
              if (g.scraps < 10) return;
              g.scraps -= 10; g.shieldTimer = max(g.shieldTimer, 8); setState(() {});
            }),
            if (g.unlockedBarrelMods)
              _item('Ствол: очередь', 18, () {
                if (g.scraps < 18) return;
                g.scraps -= 18; g.loadout.barrel = BarrelMod.rapid; g.recomputeStats(); setState(() {});
              }),
            if (g.unlockedSightMods)
              _item('Прицел: точность', 16, () {
                if (g.scraps < 16) return;
                g.scraps -= 16; g.loadout.sight = SightMod.precision; g.recomputeStats(); setState(() {});
              }),
            if (g.unlockedAmmoMods)
              _item('Боезапас: взрыв', 20, () {
                if (g.scraps < 20) return;
                g.scraps -= 20; g.loadout.ammo = AmmoMod.explosive; setState(() {});
              }),
            const Spacer(),
            ElevatedButton(onPressed: () { g.playClick(); g.finishShopThenSkills(); }, child: const Text('ДАЛЬШЕ')),
          ]),
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
        onTap: can ? () { widget.game.playClick(); buy(); } : null,
      ),
    );
  }
}

class SkillsMenu extends StatefulWidget {
  final InquisitorGame game;
  const SkillsMenu(this.game, {super.key});
  @override State<SkillsMenu> createState() => _SkillsMenuState();
}
class _SkillsMenuState extends State<SkillsMenu> {
  @override
  Widget build(BuildContext context) {
    final g = widget.game; final s = g.skills;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.94),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('НАВЫКИ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
            Text('SP: ${g.skillPoints}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            Expanded(child: ListView(children: [
              _row('HP', s.hp, () => setState(() => g.spendSkill('hp'))),
              _row('Скорость', s.speed, () => setState(() => g.spendSkill('speed'))),
              _row('Скор. атаки', s.attackSpeed, () => setState(() => g.spendSkill('attackSpeed'))),
              _row('Защита', s.defense, () => setState(() => g.spendSkill('defense'))),
              _row('Урон', s.damage, () => setState(() => g.spendSkill('damage'))),
            ])),
            ElevatedButton(onPressed: () { g.playClick(); g.finishSkillsAndContinue(); }, child: const Text('ПРОДОЛЖИТЬ')),
          ]),
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
        trailing: ElevatedButton(onPressed: can ? () { widget.game.playClick(); onAdd(); } : null, child: const Text('+1')),
      ),
    );
  }
}
class BackpackMenu extends StatefulWidget {
  final InquisitorGame game;
  const BackpackMenu(this.game, {super.key});
  @override State<BackpackMenu> createState() => _BackpackMenuState();
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
          child: ListView(children: [
            const Text('РЮКЗАК', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
            Text('${g.playerName} • ${g.playerClass.title}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            _s('HP', '${g.player.health}/${g.maxHealth}'),
            _s('Обломки', '${g.scraps}'),
            _s('Скорость', '${g.playerSpeed.toInt()}'),
            if (g.hasLaserAbility) _s('Лазер L', 'CD ${g.laserCooldown.toStringAsFixed(0)}s'),
            if (g.activeSynergyLabel != null)
              Text('Синергия: ${g.activeSynergyLabel}', style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 12)),
            if (g.relics.isNotEmpty) ...[
              const Text('Реликвии', style: TextStyle(color: Color(0xFFFFD700))),
              ...g.relics.map((r) => Text('• ${r.title}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
            ],
            const SizedBox(height: 8),
            const Text('Артефакт R', style: TextStyle(color: Color(0xFFFFD700))),
            Wrap(spacing: 6, children: ActiveArtifact.values.map((a) {
              final sel = g.activeArtifact == a;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: sel ? const Color(0xFFBF360C) : const Color(0xFF2A2A2A), padding: const EdgeInsets.symmetric(horizontal: 8)),
                onPressed: () => setState(() => g.activeArtifact = a),
                child: Text(a.title, style: const TextStyle(fontSize: 11)),
              );
            }).toList()),
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
          ]),
        ),
      ),
    );
  }

  Widget _modBtn(String t, bool sel, VoidCallback on) => ElevatedButton(
    style: ElevatedButton.styleFrom(backgroundColor: sel ? const Color(0xFFB8860B) : const Color(0xFF2A2A2A), padding: const EdgeInsets.symmetric(horizontal: 8)),
    onPressed: on,
    child: Text(t, style: const TextStyle(fontSize: 11)),
  );

  List<Widget> _ranged() {
    final g = widget.game;
    final list = <Widget>[];
    void add(String n, RangedWeapon w, bool u) {
      final sel = !g.usingMelee && g.rangedWeapon == w;
      list.add(ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: sel ? const Color(0xFFB8860B) : const Color(0xFF2A2A2A), padding: const EdgeInsets.symmetric(horizontal: 10)),
        onPressed: u ? () => setState(() { g.rangedWeapon = w; g.usingMelee = false; }) : null,
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
        style: ElevatedButton.styleFrom(backgroundColor: sel ? const Color(0xFFB8860B) : const Color(0xFF2A2A2A), padding: const EdgeInsets.symmetric(horizontal: 10)),
        onPressed: u ? () => setState(() { g.meleeWeapon = w; g.usingMelee = true; }) : null,
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
      children: [Text(k, style: const TextStyle(color: Colors.white70)), Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
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
        child: Column(children: [
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
          ElevatedButton(onPressed: () { game.playClick(); game.closeCodex(); }, child: const Text('НАЗАД')),
        ]),
      ),
    );
  }
}

class NameInputMenu extends StatefulWidget {
  final InquisitorGame game;
  const NameInputMenu(this.game, {super.key});
  @override State<NameInputMenu> createState() => _NameInputMenuState();
}
class _NameInputMenuState extends State<NameInputMenu> {
  final c = TextEditingController();
  Difficulty diff = Difficulty.normal;
  @override void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('ИМЯ ИНКВИЗИТОРА', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            TextField(controller: c, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Имя...', hintStyle: TextStyle(color: Colors.white38))),
            const SizedBox(height: 16),
            Row(children: [
              _d(Difficulty.easy, Colors.green), const SizedBox(width: 8),
              _d(Difficulty.normal, const Color(0xFFB8860B)), const SizedBox(width: 8),
              _d(Difficulty.hard, Colors.redAccent),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => widget.game.confirmName(c.text, diff), child: const Text('ДАЛЕЕ — КЛАСС')),
            TextButton(onPressed: () { widget.game.overlays.remove('nameInput'); widget.game.overlays.add('mainMenu'); }, child: const Text('НАЗАД', style: TextStyle(color: Colors.white54))),
          ]),
        ),
      ),
    );
  }
  Widget _d(Difficulty d, Color color) {
    final sel = diff == d;
    return Expanded(child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: sel ? color : const Color(0xFF1A1A1A), side: BorderSide(color: color)),
      onPressed: () => setState(() => diff = d),
      child: Text(d.labelRu, style: TextStyle(color: sel ? Colors.white : color, fontSize: 13)),
    ));
  }
}

class MainMenu extends StatefulWidget {
  final InquisitorGame game;
  const MainMenu(this.game, {super.key});
  @override State<MainMenu> createState() => _MainMenuState();
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
            s.y = -0.1; s.x = _rnd.nextDouble();
            s.char = _chars[_rnd.nextInt(_chars.length)];
            s.opacity = 0.2 + _rnd.nextDouble() * 0.7;
          }
        }
      });
    });
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _MP(symbols))),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('SOUL OF THE\nINQUISITOR', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 32, fontWeight: FontWeight.w900, height: 1.15, shadows: [Shadow(color: Colors.redAccent, blurRadius: 14)])),
          const Text('by Инквизитор Данте', style: TextStyle(color: Color(0xFFB8860B), fontSize: 14)),
          const SizedBox(height: 28),
          _btn('НАЧАТЬ ИГРУ', () { widget.game.playClick(); widget.game.openNameInput(); }),
          const SizedBox(height: 8),
          _btn('ЗАГРУЗИТЬ', () { widget.game.playClick(); widget.game.openLoadSave(); }),
          const SizedBox(height: 8),
          _btn('КОДЕКС', () { widget.game.playClick(); widget.game.openCodex(); }),
          const SizedBox(height: 8),
          _btn('РЕКОРДЫ', () { widget.game.playClick(); widget.game.overlays.remove('mainMenu'); widget.game.overlays.add('records'); }),
          const SizedBox(height: 8),
          _btn('НАСТРОЙКИ', () { widget.game.playClick(); widget.game.openSettings(); }),
        ])),
      ]),
    );
  }
  Widget _btn(String text, VoidCallback onTap) => SizedBox(
    width: 260,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFFB8860B)), padding: const EdgeInsets.symmetric(vertical: 12)),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
    ),
  );
}
class _MS { double x, y, speed, opacity; String char; _MS(this.x, this.y, this.speed, this.char, this.opacity); }
class _MP extends CustomPainter {
  final List<_MS> symbols; _MP(this.symbols);
  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final s in symbols) {
      tp.text = TextSpan(text: s.char, style: TextStyle(color: Color.fromRGBO(0, 255, 70, s.opacity), fontSize: 14 + s.speed * 4, fontFamily: 'monospace'));
      tp.layout(); tp.paint(canvas, Offset(s.x * size.width, s.y * size.height));
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LoadSaveMenu extends StatelessWidget {
  final InquisitorGame game;
  const LoadSaveMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('ЗАГРУЗИТЬ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold))),
        Expanded(child: game.saves.isEmpty
          ? const Center(child: Text('Нет сохранений', style: TextStyle(color: Colors.white54)))
          : ListView.builder(itemCount: game.saves.length, itemBuilder: (_, i) {
              final s = game.saves[i];
              return Card(color: const Color(0xFF1A1A1A), child: ListTile(
                title: Text(s.name, style: const TextStyle(color: Color(0xFFFFD700))),
                subtitle: Text('${s.playerClass} • F${s.floor}/L${s.level} • ${s.scraps} обл.\n${s.dateStr}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                isThreeLine: true,
                onTap: () { game.playClick(); game.loadSave(s); },
              ));
            })),
        ElevatedButton(onPressed: () { game.overlays.remove('loadSave'); game.overlays.add('mainMenu'); }, child: const Text('НАЗАД')),
      ])),
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
      body: SafeArea(child: Column(children: [
        const Text('РЕКОРДЫ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold)),
        Expanded(child: game.highScores.isEmpty
          ? const Center(child: Text('Пусто', style: TextStyle(color: Colors.white54)))
          : ListView.builder(itemCount: game.highScores.length, itemBuilder: (_, i) {
              final e = game.highScores[i];
              return ListTile(
                title: Text('${i + 1}. ${e.name}', style: const TextStyle(color: Colors.white)),
                subtitle: Text(e.progressStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: Text('${e.score}\n${e.timeStr}', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
              );
            })),
        ElevatedButton(onPressed: () { game.overlays.remove('records'); game.overlays.add('mainMenu'); }, child: const Text('НАЗАД')),
      ])),
    );
  }
}

class SettingsMenu extends StatefulWidget {
  final InquisitorGame game;
  const SettingsMenu(this.game, {super.key});
  @override State<SettingsMenu> createState() => _SettingsMenuState();
}
class _SettingsMenuState extends State<SettingsMenu> {
  String? _saveMsg;
  @override
  Widget build(BuildContext context) {
    final g = widget.game; final c = g.custom;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('НАСТРОЙКИ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
        Text('Джойстик ${g.joystickSize.toInt()}', style: const TextStyle(color: Colors.white)),
        Slider(value: g.joystickSize, min: 55, max: 120, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.joystickSize = v)),
        Text('Кнопки ${g.buttonSize.toInt()}', style: const TextStyle(color: Colors.white)),
        Slider(value: g.buttonSize, min: 28, max: 65, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.buttonSize = v)),
        SwitchListTile(title: const Text('Звуки', style: TextStyle(color: Colors.white)), value: g.soundEnabled, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.soundEnabled = v)),
        Slider(value: g.soundVolume, min: 0, max: 1, activeColor: const Color(0xFFFFD700), onChanged: g.soundEnabled ? (v) => setState(() => g.soundVolume = v) : null),
        SwitchListTile(title: const Text('Музыка', style: TextStyle(color: Colors.white)), value: g.musicEnabled, activeColor: const Color(0xFFFFD700), onChanged: (v) { setState(() { g.musicEnabled = v; g.applyMusicSetting(); }); }),
        Slider(value: g.musicVolume, min: 0, max: 1, activeColor: const Color(0xFFFFD700), onChanged: g.musicEnabled ? (v) { setState(() { g.musicVolume = v; g._bgmPlayer?.setVolume(v); }); } : null),
        const Text('ЦВЕТА', style: TextStyle(color: Color(0xFFFFD700))),
        Slider(value: c.armorHue.toDouble(), min: 0, max: 360, activeColor: c.armorColor(0.4), onChanged: (v) => setState(() => c.armorHue = v.round())),
        Slider(value: c.capeHue.toDouble(), min: 0, max: 360, activeColor: c.capeColor(0.4), onChanged: (v) => setState(() => c.capeHue = v.round())),
        Slider(value: c.weaponHue.toDouble(), min: 0, max: 360, activeColor: c.weaponColor(0.45), onChanged: (v) => setState(() => c.weaponHue = v.round())),
        if (g.isPlaying) ...[
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)), onPressed: () async { await g.saveGame(); setState(() => _saveMsg = 'OK'); }, child: const Text('СОХРАНИТЬ')),
          if (_saveMsg != null) Text(_saveMsg!, style: const TextStyle(color: Colors.greenAccent)),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)), onPressed: () { g.playClick(); g.exitMatch(); }, child: const Text('ВЫХОД')),
        ],
        ElevatedButton(onPressed: () { g.playClick(); if (g.isPlaying) g.closeSettings(); else { g.persistCustomization(); g.backToMenu(); } }, child: Text(g.isPlaying ? 'В БОЙ' : 'НАЗАД')),
      ])),
    );
  }
}

class LevelCompleteMenu extends StatelessWidget {
  final InquisitorGame game;
  const LevelCompleteMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black.withOpacity(0.85), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('УРОВЕНЬ ПРОЙДЕН', style: TextStyle(color: Colors.greenAccent, fontSize: 26, fontWeight: FontWeight.bold)),
      Text('Очки ${game.score} • Обломки ${game.scraps}', style: const TextStyle(color: Colors.white)),
      ElevatedButton(onPressed: game.nextLevel, child: const Text('ДАЛЬШЕ')),
    ])));
  }
}
class VictoryMenu extends StatelessWidget {
  final InquisitorGame game;
  const VictoryMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black.withOpacity(0.93), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('ИСПЫТАНИЕ ПРОЙДЕНО', style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
      Text('${game.playerName} • ${game.playerClass.title}', style: const TextStyle(color: Colors.white)),
      ElevatedButton(onPressed: () { game.playClick(); game.finishAfterVictory(); }, child: const Text('ЗАКОНЧИТЬ')),
      ElevatedButton(onPressed: () { game.playClick(); game.startArena(); }, child: const Text('АРЕНА')),
    ])));
  }
}
class GameOverMenu extends StatelessWidget {
  final InquisitorGame game;
  const GameOverMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black.withOpacity(0.85), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('ИНКВИЗИТОР ПАЛ', style: TextStyle(color: Colors.redAccent, fontSize: 26, fontWeight: FontWeight.bold)),
      Text('${game.playerName}: ${game.score}', style: const TextStyle(color: Colors.white)),
      Text(game.playerClass.title, style: const TextStyle(color: Colors.white54)),
      ElevatedButton(onPressed: game.openNameInput, child: const Text('СНОВА')),
      ElevatedButton(onPressed: game.backToMenu, child: const Text('МЕНЮ')),
    ])));
  }
}
class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent moveJoystick;
  late int health;
  late int maxHealth;
  double attackTimer = 0;
  Vector2 aimDir = Vector2(0, -1);
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  Player(this.moveJoystick) : super(size: Vector2(76, 86), anchor: Anchor.center, priority: 15);

  @override
  Future<void> onLoad() async {
    maxHealth = game.maxHealth;
    health = maxHealth;
    position = game.playerSpawnPos.clone();
    add(CircleHitbox(radius: 30));
  }

  double get speedMul {
    double m = 1.0;
    for (final s in statuses) {
      if (s.type == StatusType.slow) m *= 0.7;
      if (s.type == StatusType.corruption) m *= 0.85;
    }
    return m;
  }

  void applyStatus(StatusType type, double duration, {int tickDamage = 1}) {
    final existing = statuses.where((s) => s.type == type).toList();
    if (existing.isNotEmpty) {
      existing.first.remaining = max(existing.first.remaining, duration);
    } else {
      statuses.add(StatusEffect(type, duration, tickDamage: tickDamage));
    }
  }

  void _tickStatuses(double dt) {
    for (final s in statuses.toList()) {
      s.remaining -= dt;
      s.tickAcc += dt;
      if (s.tickAcc >= s.tickEvery) {
        s.tickAcc = 0;
        if (s.type == StatusType.burn || s.type == StatusType.bleed || s.type == StatusType.corruption) {
          health = max(0, health - s.tickDamage);
          game.spawnDamageNumber(position, s.tickDamage, color: s.color);
          if (health <= 0) { health = 0; game.showGameOver(); return; }
        }
      }
      if (s.remaining <= 0) statuses.remove(s);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    _tickStatuses(dt);
    var spd = game.playerSpeed * (game.dashActive > 0 ? 1.30 : 1.0) * speedMul;
    if (game._hasteTimer > 0) spd *= 1.12;
    if (moveJoystick.direction != JoystickDirection.idle) {
      position.add(moveJoystick.relativeDelta * spd * dt);
    }
    if (game.attackJoystick.direction != JoystickDirection.idle) {
      final d = game.attackJoystick.relativeDelta;
      if (d.length2 > 0.01) aimDir = d.normalized();
    } else if (moveJoystick.direction != JoystickDirection.idle) {
      final d = moveJoystick.relativeDelta;
      if (d.length2 > 0.01) aimDir = d.normalized();
    }
    position.x = position.x.clamp(70, game.mapWidth - 70);
    position.y = position.y.clamp(70, game.mapHeight - 70);
    if (game.attackJoystick.direction != JoystickDirection.idle) {
      attackTimer += dt;
      if (attackTimer >= _cd()) {
        attackTimer = 0;
        _atk();
      }
    } else {
      attackTimer = 0;
    }
  }

  double _cd() {
    double base = 0.4;
    if (game.usingMelee) {
      switch (game.meleeWeapon) {
        case MeleeWeapon.sword: base = 0.42; break;
        case MeleeWeapon.axe: base = 0.58; break;
        case MeleeWeapon.hammer: base = 0.75; break;
        case MeleeWeapon.forceBlade: base = 0.48; break;
        case MeleeWeapon.forceSword: base = 0.44; break;
        case MeleeWeapon.daemonHammer: base = 0.72; break;
        case MeleeWeapon.katana: base = 0.36; break;
        case MeleeWeapon.powerKatana: base = 0.34; break;
        case MeleeWeapon.executioner: base = 0.55; break;
      }
    } else {
      switch (game.rangedWeapon) {
        case RangedWeapon.bolter: base = 0.30; break;
        case RangedWeapon.rifle: base = 0.55; break;
        case RangedWeapon.shotgun: base = 0.70; break;
        case RangedWeapon.staff: base = 0.85; break;
        case RangedWeapon.stormStaff: base = 0.70; break;
        case RangedWeapon.warpBeam: base = 1.0; break;
        case RangedWeapon.daggers: base = 0.28; break;
        case RangedWeapon.needles: base = 0.32; break;
        case RangedWeapon.sniperNeedle: base = 0.80; break;
      }
    }
    return base * game.attackSpeedMult;
  }

  void _fireBullet(Vector2 d, int dmg, Color color, {double speed = 520, double radius = 7, bool isDagger = false}) {
    final spread = game.loadout.sight == SightMod.wide ? [-0.1, 0.0, 0.1] : [0.0];
    final baseAng = atan2(d.y, d.x);
    for (final o in spread) {
      final a = baseAng + o;
      game.world.add(Bullet(
        position: position.clone(),
        direction: Vector2(cos(a), sin(a)),
        damage: dmg,
        color: color,
        speed: speed,
        radius: radius,
        isDagger: isDagger,
        ammoMod: game.loadout.ammo,
      )..priority = 13);
    }
  }

  void _atk() {
    if (game.usingMelee) game.playMelee(); else game.playShoot();
    final d = aimDir.length2 < 0.01 ? Vector2(0, -1) : aimDir;

    if (game.usingMelee) {
      switch (game.meleeWeapon) {
        case MeleeWeapon.sword:
          game.world.add(MeleeAttack(position: position + d * 48, direction: d, radius: 56, damage: game.scaleDamage(game.swordDamage), color: const Color(0xFF00E5FF), status: StatusType.bleed)..priority = 13);
          break;
        case MeleeWeapon.axe:
          game.world.add(MeleeAttack(position: position.clone(), direction: d, radius: 108, damage: game.scaleDamage(game.axeDamage), color: const Color(0xFFFF6D00), status: StatusType.bleed)..priority = 13);
          break;
        case MeleeWeapon.hammer:
          game.world.add(MeleeAttack(position: position + d * 28, direction: d, radius: 118, damage: game.scaleDamage(game.hammerDamage), color: const Color(0xFFFFD600))..priority = 13);
          break;
        case MeleeWeapon.forceBlade:
          game.world.add(MeleeAttack(position: position + d * 50, direction: d, radius: 62, damage: game.scaleDamage(game.forceDamage), color: const Color(0xFFB388FF), status: StatusType.corruption)..priority = 13);
          break;
        case MeleeWeapon.forceSword:
          game.world.add(MeleeAttack(position: position + d * 52, direction: d, radius: 70, damage: game.scaleDamage(game.forceSwordDamage), color: const Color(0xFFEA80FC), status: StatusType.corruption)..priority = 13);
          break;
        case MeleeWeapon.daemonHammer:
          game.world.add(MeleeAttack(position: position + d * 30, direction: d, radius: 120, damage: game.scaleDamage(game.daemonDamage), color: const Color(0xFF7C4DFF), status: StatusType.corruption)..priority = 13);
          break;
        case MeleeWeapon.katana:
          game.world.add(MeleeAttack(position: position + d * 52, direction: d, radius: 64, damage: game.scaleDamage(game.katanaDamage), color: const Color(0xFFE0E0E0), status: StatusType.bleed)..priority = 13);
          break;
        case MeleeWeapon.powerKatana:
          game.world.add(MeleeAttack(position: position + d * 54, direction: d, radius: 72, damage: game.scaleDamage(game.powerKatanaDamage), color: const Color(0xFFE040FB), status: StatusType.bleed)..priority = 13);
          break;
        case MeleeWeapon.executioner:
          game.world.add(MeleeAttack(position: position + d * 40, direction: d, radius: 100, damage: game.scaleDamage(game.execDamage), color: const Color(0xFFF3E5F5), status: StatusType.bleed)..priority = 13);
          break;
      }
    } else {
      switch (game.rangedWeapon) {
        case RangedWeapon.bolter:
          _fireBullet(d, game.scaleDamage(game.bolterDamage), const Color(0xFFFFD700));
          break;
        case RangedWeapon.rifle:
          _fireBullet(d, game.scaleDamage(game.rifleDamage), const Color(0xFFFF8A65), speed: 680, radius: 5);
          break;
        case RangedWeapon.shotgun:
          final base = atan2(d.y, d.x);
          for (final o in [-0.28, 0.0, 0.28]) {
            final a = base + o;
            game.world.add(Bullet(position: position.clone(), direction: Vector2(cos(a), sin(a)), damage: game.scaleDamage(game.shotgunDamage), color: const Color(0xFFFFAB40), speed: 440, radius: 6, ammoMod: game.loadout.ammo)..priority = 13);
          }
          break;
        case RangedWeapon.staff:
          game.world.add(PsyWave(position: position.clone(), direction: d, damage: game.scaleDamage(game.staffDamage))..priority = 13);
          break;
        case RangedWeapon.stormStaff:
          game.world.add(PsyWave(position: position.clone(), direction: d, damage: game.scaleDamage(game.stormDamage), wide: true)..priority = 13);
          break;
        case RangedWeapon.warpBeam:
          _fireBullet(d, game.scaleDamage(game.warpDamage), const Color(0xFF651FFF), speed: 400, radius: 10);
          break;
        case RangedWeapon.daggers:
          final base = atan2(d.y, d.x);
          for (final o in [-0.12, 0.12]) {
            final a = base + o;
            game.world.add(Bullet(position: position.clone(), direction: Vector2(cos(a), sin(a)), damage: game.scaleDamage(game.daggerDamage), color: const Color(0xFFE0E0E0), speed: 560, radius: 5, isDagger: true, ammoMod: game.loadout.ammo)..priority = 13);
          }
          break;
        case RangedWeapon.needles:
          final base = atan2(d.y, d.x);
          for (final o in [-0.18, 0.0, 0.18]) {
            final a = base + o;
            game.world.add(Bullet(position: position.clone(), direction: Vector2(cos(a), sin(a)), damage: game.scaleDamage(game.needleDamage), color: const Color(0xFFCE93D8), speed: 600, radius: 4, isDagger: true, ammoMod: game.loadout.ammo)..priority = 13);
          }
          break;
        case RangedWeapon.sniperNeedle:
          _fireBullet(d, game.scaleDamage(game.sniperNeedleDamage), const Color(0xFFE040FB), speed: 900, radius: 4, isDagger: true);
          break;
      }
    }
  }

  void takeDamage(int amount) {
    if (game.dashActive > 1.5) return;
    if (game.shieldTimer > 0) return;
    if (game.holyAuraTimer > 0) amount = max(1, (amount * 0.7).round());
    if (Random().nextDouble() < game.defenseChance) return;
    final dmg = max(1, (amount * game.difficulty.dmgMult).round());
    health -= dmg;
    hurtFlash = 0.15;
    game.triggerShake(power: 5, time: 0.15);
    game.spawnDamageNumber(position, dmg, color: const Color(0xFFFF5252));
    if (health <= 0) { health = 0; game.showGameOver(); }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    if (game.dashActive > 0) canvas.drawCircle(Offset(cx, cy), 46, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.28));
    if (game.shieldTimer > 0 || game.holyAuraTimer > 0) {
      canvas.drawCircle(Offset(cx, cy), 42, Paint()..color = const Color(0xFF42A5F5).withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    final facingLeft = aimDir.x < -0.15;
    canvas.save();
    if (facingLeft) { canvas.translate(cx, cy); canvas.scale(-1, 1); canvas.translate(-cx, -cy); }
    WHDraw.inquisitor(canvas, cx: cx, cy: cy, s: 1.32, flash: hurtFlash / 0.15, custom: game.custom, cls: game.playerClass);
    canvas.restore();
    final ang = atan2(aimDir.y, aimDir.x);
    final w = game.custom.weaponColor(0.45);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);
    if (game.usingMelee) {
      switch (game.meleeWeapon) {
        case MeleeWeapon.sword: WHDraw.powerSword(canvas, 0, 0, 1.25, accent: w); break;
        case MeleeWeapon.axe: WHDraw.chainAxe(canvas, 0, 0, 1.25, accent: w); break;
        case MeleeWeapon.hammer: WHDraw.thunderHammer(canvas, 0, 0, 1.25, accent: w); break;
        case MeleeWeapon.forceBlade: WHDraw.forceBlade(canvas, 0, 0, 1.25, accent: w); break;
        case MeleeWeapon.forceSword: WHDraw.forceSword(canvas, 0, 0, 1.25, accent: w); break;
        case MeleeWeapon.daemonHammer: WHDraw.daemonHammer(canvas, 0, 0, 1.25, accent: w); break;
        case MeleeWeapon.katana: WHDraw.katana(canvas, 0, 0, 1.25, accent: w); break;
        case MeleeWeapon.powerKatana: WHDraw.powerKatana(canvas, 0, 0, 1.25, accent: w); break;
        case MeleeWeapon.executioner: WHDraw.executioner(canvas, 0, 0, 1.25, accent: w); break;
      }
    } else {
      switch (game.rangedWeapon) {
        case RangedWeapon.bolter: WHDraw.bolter(canvas, 0, 0, 1.18, accent: w); break;
        case RangedWeapon.rifle: WHDraw.rifle(canvas, 0, 0, 1.18, accent: w); break;
        case RangedWeapon.shotgun: WHDraw.shotgun(canvas, 0, 0, 1.18, accent: w); break;
        case RangedWeapon.staff: WHDraw.staff(canvas, 0, 0, 1.15, accent: w); break;
        case RangedWeapon.stormStaff: WHDraw.stormStaff(canvas, 0, 0, 1.15, accent: w); break;
        case RangedWeapon.warpBeam: WHDraw.warpBeamGun(canvas, 0, 0, 1.15, accent: w); break;
        case RangedWeapon.daggers: WHDraw.daggers(canvas, 0, 0, 1.15, accent: w); break;
        case RangedWeapon.needles: WHDraw.needles(canvas, 0, 0, 1.15, accent: w); break;
        case RangedWeapon.sniperNeedle: WHDraw.sniperNeedle(canvas, 0, 0, 1.15, accent: w); break;
      }
    }
    canvas.restore();
    if (statuses.isNotEmpty) WHDraw.statusIcons(canvas, cx, -8, statuses);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!game.isPlaying || game.isPaused) return;
    if (other is Wall || other is Obstacle) position -= (intersectionPoints.first - position).normalized() * 6;
    if (other is Enemy || other is EnemyBullet || other is BossProjectile || other is FlamerCloud) {
      takeDamage(other is Enemy && (other.type == EnemyType.dog || other.type == EnemyType.brute || other.isChampion) ? 2 : 1);
      if (other is FlamerCloud) applyStatus(StatusType.burn, 2.0, tickDamage: 1);
      if (other is Enemy) {
        final pos = other.position.clone();
        final t = other.type;
        final champ = other.isChampion;
        other.removeFromParent();
        game.onEnemyKilled(at: pos, type: t, isChampion: champ);
      } else if (other is! FlamerCloud) {
        other.removeFromParent();
      }
    }
    if (other is Boss || other is KnightBoss || other is KingBoss || other is MiniBoss || other is TentacleBoss || other is CyclopsBoss) {
      takeDamage(1);
    }
  }
}

class PsyWave extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction; final int damage; final bool wide;
  double life = 0.45; double radius = 30; final Set<int> _hit = {};
  PsyWave({required Vector2 position, required this.direction, required this.damage, this.wide = false})
      : super(position: position, size: Vector2(80, 80), anchor: Anchor.center, priority: 13);
  @override Future<void> onLoad() async => add(CircleHitbox(radius: wide ? 50 : 40));
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    radius += (wide ? 180 : 140) * dt;
    position += direction * 220 * dt;
    if (life <= 0) removeFromParent();
  }
  void _hitTarget(PositionComponent other, int dmg) {
    final id = identityHashCode(other);
    if (_hit.contains(id)) return;
    _hit.add(id);
    if (other is Enemy) {
      other.applyDamage(dmg);
      other.applyStatus(StatusType.corruption, 2.0, tickDamage: 1);
    }
    if (other is Boss) other.takeDamage(dmg);
    if (other is KnightBoss) other.takeDamage(dmg);
    if (other is KingBoss) other.takeDamage(dmg);
    if (other is MiniBoss) other.takeDamage(dmg);
    if (other is TentacleBoss) other.takeDamage(dmg);
    if (other is CyclopsBoss) other.takeDamage(dmg);
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    _hitTarget(other, damage);
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 0.45).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), radius * 0.5, Paint()..color = Color.fromRGBO(124, 77, 255, 0.35 * a)..style = PaintingStyle.stroke..strokeWidth = wide ? 8 : 6);
  }
}

class CyclopsLaserBeam extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction; final int damage;
  double life = 0.55; final Set<int> _hit = {};
  CyclopsLaserBeam({required Vector2 position, required this.direction, required this.damage})
      : super(position: position, size: Vector2(40, 40), anchor: Anchor.center, priority: 14);
  @override Future<void> onLoad() async => add(CircleHitbox(radius: 20));
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position += direction * 900 * dt;
    if (life <= 0 || position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    final id = identityHashCode(other);
    if (_hit.contains(id)) return;
    if (other is Enemy) { _hit.add(id); other.applyDamage(damage); other.applyStatus(StatusType.burn, 2.5, tickDamage: 2); }
    if (other is Boss) { _hit.add(id); other.takeDamage(damage); }
    if (other is KnightBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is KingBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is MiniBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is TentacleBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is CyclopsBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is Wall || other is Obstacle) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    final a = (life / 0.55).clamp(0.0, 1.0);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, Paint()..color = Color.fromRGBO(255, 109, 0, 0.9 * a));
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6, Paint()..color = Colors.white.withOpacity(a));
  }
}

class Bullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  Vector2 direction;
  final int damage;
  final double speed;
  final bool isDagger;
  final AmmoMod ammoMod;
  int bounces = 0;
  Bullet({
    required super.position,
    required this.direction,
    required this.damage,
    Color color = const Color(0xFFFFD700),
    this.speed = 500,
    double radius = 7,
    this.isDagger = false,
    this.ammoMod = AmmoMod.none,
  }) : super(radius: radius, anchor: Anchor.center, paint: Paint()..color = color, priority: 13);

  @override Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * speed * dt);
    if (position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) {
      if (ammoMod == AmmoMod.ricochet && bounces < 2) {
        bounces++;
        if (position.x < 0 || position.x > game.mapWidth) direction = Vector2(-direction.x, direction.y);
        if (position.y < 0 || position.y > game.mapHeight) direction = Vector2(direction.x, -direction.y);
        position.x = position.x.clamp(10, game.mapWidth - 10);
        position.y = position.y.clamp(10, game.mapHeight - 10);
      } else {
        removeFromParent();
      }
    }
  }

  void _dmgEnemy(Enemy e) {
    final shielded = e.type == EnemyType.shielded || e.type == EnemyType.shieldedShooter;
    final pierceShield = game.hasShieldPierce || isDagger || ammoMod == AmmoMod.pierce || game.codexShieldBonus > 0;
    if (shielded && !pierceShield) {
      game.spawnDamageNumber(e.position, 0, color: const Color(0xFF90CAF9));
      if (ammoMod != AmmoMod.pierce) removeFromParent();
      return;
    }
    var dmg = shielded && pierceShield ? max(1, (damage * (0.5 + game.codexShieldBonus)).round()) : damage;
    e.applyDamage(dmg);
    if (ammoMod == AmmoMod.explosive) {
      e.applyStatus(StatusType.burn, 2.0 + game.codexBurnBonus, tickDamage: 1);
      game.world.add(KillExplosion(position: e.position.clone(), radius: 40, damage: dmg ~/ 3)..priority = 12);
    }
    if (game.synergyFireCrits && game.tryCrit()) {
      e.applyStatus(StatusType.burn, 2.5 + game.codexBurnBonus, tickDamage: 1);
    }
    if (isDagger) e.applyStatus(StatusType.bleed, 2.0, tickDamage: 1);
    if (ammoMod != AmmoMod.pierce) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      if (ammoMod == AmmoMod.ricochet && bounces < 2) {
        bounces++;
        direction = -direction;
      } else {
        removeFromParent();
      }
    }
    if (other is Enemy) _dmgEnemy(other);
    if (other is Boss) { other.takeDamage(damage); if (ammoMod != AmmoMod.pierce) removeFromParent(); }
    if (other is KnightBoss) { other.takeDamage(damage); if (ammoMod != AmmoMod.pierce) removeFromParent(); }
    if (other is KingBoss) { other.takeDamage(damage); if (ammoMod != AmmoMod.pierce) removeFromParent(); }
    if (other is MiniBoss) { other.takeDamage(damage); if (ammoMod != AmmoMod.pierce) removeFromParent(); }
    if (other is TentacleBoss) { other.takeDamage(damage); if (ammoMod != AmmoMod.pierce) removeFromParent(); }
    if (other is CyclopsBoss) { other.takeDamage(damage); if (ammoMod != AmmoMod.pierce) removeFromParent(); }
  }
}

class MeleeAttack extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final int damage;
  final StatusType? status;
  double life = 0.22;
  final Set<int> _hit = {};
  MeleeAttack({
    required super.position,
    required this.direction,
    required double radius,
    required this.damage,
    required Color color,
    this.status,
  }) : super(radius: radius, anchor: Anchor.center, paint: Paint()..color = color.withOpacity(0.42), priority: 13);

  @override Future<void> onLoad() async => add(CircleHitbox());
  @override void update(double dt) { super.update(dt); life -= dt; if (life <= 0) removeFromParent(); }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    final id = identityHashCode(other);
    if (_hit.contains(id)) return;
    if (other is Enemy) {
      _hit.add(id);
      other.applyDamage(damage);
      if (status != null) other.applyStatus(status!, 2.2, tickDamage: 1);
    }
    if (other is Obstacle) other.removeFromParent();
    if (other is Boss) { _hit.add(id); other.takeDamage(damage); }
    if (other is KnightBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is KingBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is MiniBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is TentacleBoss) { _hit.add(id); other.takeDamage(damage); }
    if (other is CyclopsBoss) { _hit.add(id); other.takeDamage(damage); }
  }
}

class EnemyBullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  EnemyBullet({required super.position, required this.direction})
      : super(radius: 9, anchor: Anchor.center, paint: Paint()..color = const Color(0xFF76FF03), priority: 22);
  @override Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * 160 * dt);
    if (position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) removeFromParent();
  }
}

class BossProjectile extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  BossProjectile({required super.position, required this.direction})
      : super(radius: 12, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFF1744), priority: 22);
  @override Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * 185 * dt);
    if (position.x < -80 || position.x > game.mapWidth + 80 || position.y < -80 || position.y > game.mapHeight + 80) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) removeFromParent();
  }
}

class FlamerCloud extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  double life = 1.8;
  FlamerCloud({required Vector2 position})
      : super(position: position, radius: 36, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFF6D00).withOpacity(0.4), priority: 11);
  @override Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    paint.color = Color.fromRGBO(255, 109, 0, (life / 1.8 * 0.4).clamp(0.0, 0.4));
    if (life <= 0) removeFromParent();
  }
}
class Enemy extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final EnemyType type;
  final bool isChampion;
  late final double speed;
  late int hp;
  late int maxHp;
  double shootTimer = 0;
  double meleeTimer = 0;
  double hurtFlash = 0;
  final List<StatusEffect> statuses = [];

  Enemy({required this.floor, required this.type, this.isChampion = false})
      : super(size: Vector2(72, 82), anchor: Anchor.center, priority: 30);

  @override
  Future<void> onLoad() async {
    final threat = game.worldThreat * game.difficulty.hpMult;
    final champMul = isChampion ? 2.2 : 1.0;
    switch (type) {
      case EnemyType.shooter:
        speed = 55 + floor * 6.0;
        maxHp = ((22 + floor * 8 * threat) * champMul).round();
        break;
      case EnemyType.melee:
        speed = 85 + floor * 9.0;
        maxHp = ((26 + floor * 9 * threat) * champMul).round();
        break;
      case EnemyType.shielded:
        speed = 42 + floor * 4.5;
        maxHp = ((36 + floor * 10 * threat) * champMul).round();
        break;
      case EnemyType.dog:
        speed = 145 + floor * 12.0;
        size = Vector2(62, 48);
        maxHp = ((16 + floor * 6 * threat) * champMul).round();
        break;
      case EnemyType.shieldedShooter:
        speed = 48 + floor * 5.0;
        maxHp = ((32 + floor * 10 * threat) * champMul).round();
        break;
      case EnemyType.flamer:
        speed = 50 + floor * 5.0;
        maxHp = ((28 + floor * 9 * threat) * champMul).round();
        break;
      case EnemyType.sniper:
        speed = 40 + floor * 4.0;
        maxHp = ((18 + floor * 7 * threat) * champMul).round();
        break;
      case EnemyType.brute:
        speed = 38 + floor * 4.0;
        size = Vector2(88, 92);
        maxHp = ((50 + floor * 14 * threat) * champMul).round();
        break;
    }
    if (isChampion) speed *= 1.08;
    hp = maxHp;
    add(CircleHitbox(radius: type == EnemyType.dog ? 22 : (type == EnemyType.brute ? 36 : 28)));
  }

  void applyStatus(StatusType type, double duration, {int tickDamage = 1}) {
    final existing = statuses.where((s) => s.type == type).toList();
    if (existing.isNotEmpty) {
      existing.first.remaining = max(existing.first.remaining, duration);
    } else {
      statuses.add(StatusEffect(type, duration, tickDamage: tickDamage));
    }
  }

  void _tickStatuses(double dt) {
    for (final s in statuses.toList()) {
      s.remaining -= dt;
      s.tickAcc += dt;
      if (s.tickAcc >= s.tickEvery) {
        s.tickAcc = 0;
        if (s.type == StatusType.burn || s.type == StatusType.bleed || s.type == StatusType.corruption) {
          hp -= s.tickDamage;
          game.spawnDamageNumber(position, s.tickDamage, color: s.color);
          if (hp <= 0) {
            final pos = position.clone();
            final t = type;
            final champ = isChampion;
            removeFromParent();
            game.onEnemyKilled(at: pos, type: t, isChampion: champ);
            return;
          }
        }
      }
      if (s.remaining <= 0) statuses.remove(s);
    }
  }

  double get _speedMul {
    double m = 1.0;
    for (final s in statuses) {
      if (s.type == StatusType.slow) m *= 0.55;
      if (s.type == StatusType.corruption) m *= 0.8;
    }
    return m;
  }

  void applyDamage(int amount) {
    hp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount);
    if (hp <= 0) {
      final pos = position.clone();
      final t = type;
      final champ = isChampion;
      removeFromParent();
      game.onEnemyKilled(at: pos, type: t, isChampion: champ);
    }
  }

  Vector2 _aimAtPlayer() {
    final toP = game.player.position - position;
    final dist = toP.length;
    if (dist < 1) return Vector2(0, -1);
    final lead = game.moveJoystick.relativeDelta * (dist / 280);
    return (toP + lead).normalized();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    _tickStatuses(dt);
    final dist = position.distanceTo(game.player.position);
    final isRanged = type == EnemyType.shooter || type == EnemyType.shieldedShooter || type == EnemyType.sniper || type == EnemyType.flamer;
    final prefer = type == EnemyType.sniper ? 380.0 : (type == EnemyType.flamer ? 200.0 : 280.0);
    final spd = speed * _speedMul * (isChampion ? 1.05 : 1.0);
    smartMove(game.player.position, spd, dt, radius: type == EnemyType.brute ? 36 : 28, kite: isRanged, preferDist: isRanged ? prefer : 0.0);
    pushOutOfWalls(type == EnemyType.brute ? 36 : 28);

    if (type == EnemyType.shooter || type == EnemyType.shieldedShooter) {
      final interval = (dist < 160 ? 0.55 : (dist < 320 ? 0.95 : 1.55)) * (isChampion ? 0.85 : 1.0);
      shootTimer += dt;
      if (shootTimer >= interval) {
        shootTimer = 0;
        game.world.add(EnemyBullet(position: position.clone(), direction: _aimAtPlayer())..priority = 22);
        if (isChampion) {
          final a = atan2(_aimAtPlayer().y, _aimAtPlayer().x);
          game.world.add(EnemyBullet(position: position.clone(), direction: Vector2(cos(a + 0.2), sin(a + 0.2)))..priority = 22);
        }
      }
    }
    if (type == EnemyType.sniper) {
      shootTimer += dt;
      if (shootTimer >= (isChampion ? 1.4 : 1.8)) {
        shootTimer = 0;
        game.world.add(BossProjectile(position: position.clone(), direction: _aimAtPlayer())..priority = 22);
      }
    }
    if (type == EnemyType.flamer) {
      shootTimer += dt;
      if (shootTimer >= (isChampion ? 1.1 : 1.4) && dist < 260) {
        shootTimer = 0;
        final dir = _aimAtPlayer();
        game.world.add(FlamerCloud(position: position + dir * 50)..priority = 11);
        game.world.add(FlamerCloud(position: position + dir * 90)..priority = 11);
        if (isChampion) game.world.add(FlamerCloud(position: position + dir * 130)..priority = 11);
      }
    }
    if (type == EnemyType.melee || type == EnemyType.dog || type == EnemyType.shielded || type == EnemyType.brute) {
      final hitRange = type == EnemyType.dog ? 58.0 : (type == EnemyType.brute ? 90.0 : 74.0);
      final interval = (dist < 100 ? 0.45 : 0.85) * (isChampion ? 0.8 : 1.0);
      meleeTimer += dt;
      if (meleeTimer >= interval && dist < hitRange) {
        meleeTimer = 0;
        game.player.takeDamage(type == EnemyType.brute || type == EnemyType.dog || isChampion ? 2 : 1);
        if (type == EnemyType.brute) game.player.applyStatus(StatusType.slow, 1.5);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 12;
      final n = (position - intersectionPoints.first).normalized();
      avoidDir = Vector2(-n.y, n.x);
      stuckTimer = 0.55;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final f = hurtFlash / 0.12;
    switch (type) {
      case EnemyType.dog:
        WHDraw.chaosHound(canvas, cx, cy, flash: f);
        break;
      case EnemyType.shooter:
        WHDraw.cultistShooter(canvas, cx, cy, 1.2, flash: f);
        break;
      case EnemyType.melee:
        WHDraw.cultistMelee(canvas, cx, cy, 1.2, flash: f);
        break;
      case EnemyType.shielded:
        WHDraw.shieldedMarine(canvas, cx, cy, 1.2, flash: f);
        break;
      case EnemyType.shieldedShooter:
        WHDraw.shieldedMarine(canvas, cx, cy, 1.15, withGun: true, flash: f);
        break;
      case EnemyType.flamer:
        WHDraw.flamerCultist(canvas, cx, cy, 1.2, flash: f);
        break;
      case EnemyType.sniper:
        WHDraw.sniperCultist(canvas, cx, cy, 1.2, flash: f);
        break;
      case EnemyType.brute:
        WHDraw.brute(canvas, cx, cy, 1.25, flash: f);
        break;
    }
    if (isChampion) {
      WHDraw.championMark(canvas, cx, -18);
      // mini HP bar
      final ratio = (hp / maxHp).clamp(0.0, 1.0);
      canvas.drawRect(Rect.fromLTWH(cx - 22, -28, 44, 5), Paint()..color = const Color(0xFF333333));
      canvas.drawRect(Rect.fromLTWH(cx - 22, -28, 44 * ratio, 5), Paint()..color = const Color(0xFFFFD700));
    }
    if (statuses.isNotEmpty) WHDraw.statusIcons(canvas, cx, isChampion ? -36 : -14, statuses);
  }
}

class MiniBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  late int maxHp, currentHp;
  double shootTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  double hurtFlash = 0;
  int phase = 1;

  MiniBoss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(96, 106), anchor: Anchor.center, priority: 24);

  @override
  Future<void> onLoad() async {
    final bars = game.difficulty == Difficulty.hard ? 2 : 1;
    maxHp = (((240 + floor * 95) / 2) * game.difficulty.bossHpMult * game.worldThreat * bars).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 42));
    game.unlockCodex(CodexId.miniBoss);
  }

  int get _barHp {
    final bars = game.difficulty == Difficulty.hard ? 2 : 1;
    return max(1, maxHp ~/ bars);
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7;
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    game.world.add(TelegraphZone(position: position + toP * 80, shape: 'cone', radius: 160, angle: ang, life: 0.7)..priority = 6);
  }

  void _fireVolley() {
    final toP = (game.player.position - position).normalized();
    final base = atan2(toP.y, toP.x);
    final spread = phase >= 2 ? [-0.4, -0.2, 0.0, 0.2, 0.4] : [-0.3, 0.0, 0.3];
    for (final o in spread) {
      final a = base + o;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    final dist = position.distanceTo(game.player.position);
    final spd = (52 + floor * 4.0) * (phase >= 2 ? 1.15 : 1.0);
    smartMove(game.player.position, spd, dt, radius: 42, kite: true, preferDist: 260);
    pushOutOfWalls(42);

    if (telegraphing) {
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _fireVolley();
      }
      return;
    }

    final interval = (dist < 200 ? 0.75 : 1.35) * (phase >= 2 ? 0.7 : 1.0);
    shootTimer += dt;
    if (shootTimer >= interval) {
      shootTimer = 0;
      _startTelegraph();
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFFFF8A65));
    if (game.difficulty == Difficulty.hard && phase == 1 && currentHp <= _barHp) {
      phase = 2;
      game.triggerShake(power: 8, time: 0.22);
    }
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.onEnemyKilled(isBoss: true, at: pos);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.65;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.cultistShooter(canvas, cx, cy, 1.55, flash: hurtFlash / 0.12);
    WHDraw.shotgun(canvas, cx + 4, cy, 1.35);
    final bars = game.difficulty == Difficulty.hard ? 2 : 1;
    for (int i = 0; i < bars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      canvas.drawRect(Rect.fromLTWH(cx - 38, -30 - i * 12.0, 76 * remain, 9), Paint()..color = i == 0 ? const Color(0xFFFF8A65) : const Color(0xFFFF5722));
    }
  }
}
class Boss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  late int maxHp, currentHp;
  double attackTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0; // 0 ring, 1 cone, 2 cross
  double hurtFlash = 0;
  int phase = 1;

  Boss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(116, 126), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    final bars = game.difficulty == Difficulty.hard ? 3 : 1;
    maxHp = ((240 + floor * 95) * game.difficulty.bossHpMult * game.worldThreat * bars).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 50));
    game.unlockCodex(CodexId.boss);
  }

  int get _barHp {
    final bars = game.difficulty == Difficulty.hard ? 3 : 1;
    return max(1, maxHp ~/ bars);
  }

  void _checkPhase() {
    if (game.difficulty != Difficulty.hard) return;
    final lost = ((maxHp - currentHp) / _barHp).floor() + 1;
    final newPhase = lost.clamp(1, 3);
    if (newPhase > phase) {
      phase = newPhase;
      game.triggerShake(power: 9, time: 0.25);
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.7 + (phase > 1 ? -0.1 : 0);
    attackMode = Random().nextInt(3);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0: // ring
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 130 + phase * 15.0, life: telegraphTimer)..priority = 6);
        break;
      case 1: // cone toward player
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 200, angle: ang, life: telegraphTimer)..priority = 6);
        break;
      case 2: // cross
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 160, life: telegraphTimer)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final toP = (game.player.position - position).normalized();
    final base = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0: // full ring
        final count = 8 + (phase - 1) * 4;
        for (int i = 0; i < count; i++) {
          final a = (i / count) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 1: // dense cone
        for (final o in [-0.5, -0.3, -0.15, 0.0, 0.15, 0.3, 0.5]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        if (phase >= 2) {
          for (final o in [-0.4, 0.0, 0.4]) {
            final a = base + o;
            game.world.add(BossProjectile(position: position.clone() + Vector2(cos(a), sin(a)) * 30, direction: Vector2(cos(a), sin(a)))..priority = 22);
          }
        }
        break;
      case 2: // cross (4 directions + diagonals in late phase)
        final dirs = <double>[0, pi / 2, pi, 3 * pi / 2];
        if (phase >= 2) dirs.addAll([pi / 4, 3 * pi / 4, 5 * pi / 4, 7 * pi / 4]);
        for (final a in dirs) {
          for (int k = 0; k < 3; k++) {
            game.world.add(BossProjectile(
              position: position.clone(),
              direction: Vector2(cos(a), sin(a)),
            )..priority = 22);
          }
        }
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    final dist = position.distanceTo(game.player.position);
    final spd = (42 + floor * 5.0) * (1 + (phase - 1) * 0.12);
    // smarter: kite a bit when far, push when close
    smartMove(game.player.position, spd, dt, radius: 50, kite: dist > 280, preferDist: 220);
    pushOutOfWalls(50);

    if (telegraphing) {
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    final interval = (dist < 220 ? 1.05 : 1.9) / (1 + (phase - 1) * 0.25);
    attackTimer += dt;
    if (attackTimer >= interval) {
      attackTimer = 0;
      _startTelegraph();
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFFE53935));
    _checkPhase();
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.onEnemyKilled(isBoss: true, at: pos);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 18;
      stuckTimer = 0.75;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.hereticBoss(canvas, cx, cy, 1.55, flash: hurtFlash / 0.12);
    final bars = game.difficulty == Difficulty.hard ? 3 : 1;
    for (int i = 0; i < bars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      final colors = [const Color(0xFFE53935), const Color(0xFFFF9800), const Color(0xFFFFEB3B)];
      canvas.drawRect(Rect.fromLTWH(cx - 46, -34 - i * 12.0, 92 * remain, 10), Paint()..color = colors[i % colors.length]);
    }
  }
}
class KnightBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  late int maxHp, currentHp;
  double meleeTimer = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0; // 0 charge slash, 1 ring slam, 2 cone dash
  double hurtFlash = 0;
  int phase = 1;

  KnightBoss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(110, 120), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    final bars = game.difficulty == Difficulty.hard ? 3 : 1;
    maxHp = ((300 + floor * 105) * game.difficulty.bossHpMult * game.worldThreat * bars).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 48));
    game.unlockCodex(CodexId.knight);
  }

  int get _barHp {
    final bars = game.difficulty == Difficulty.hard ? 3 : 1;
    return max(1, maxHp ~/ bars);
  }

  void _checkPhase() {
    if (game.difficulty != Difficulty.hard) return;
    final lost = ((maxHp - currentHp) / _barHp).floor() + 1;
    final newPhase = lost.clamp(1, 3);
    if (newPhase > phase) {
      phase = newPhase;
      game.triggerShake(power: 9, time: 0.25);
    }
  }

  void _startTelegraph() {
    telegraphing = true;
    telegraphTimer = 0.65;
    attackMode = Random().nextInt(phase >= 2 ? 3 : 2);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0:
        game.world.add(TelegraphZone(position: position + toP * 70, shape: 'cone', radius: 140, angle: ang, life: 0.65)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 120 + phase * 12.0, life: 0.65)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position + toP * 100, shape: 'cross', radius: 100, life: 0.65)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final dist = position.distanceTo(game.player.position);
    final toP = (game.player.position - position).normalized();
    switch (attackMode) {
      case 0: // slash + lunge
        position += toP * 55;
        if (dist < 130 + phase * 8) game.player.takeDamage(1 + phase);
        for (final o in [-0.35, 0.0, 0.35]) {
          final a = atan2(toP.y, toP.x) + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 1: // ring slam
        final n = 6 + phase * 2;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        if (dist < 130) game.player.takeDamage(2);
        game.triggerShake(power: 6, time: 0.15);
        break;
      case 2: // dash cross
        position += toP * 90;
        for (final a in [0.0, pi / 2, pi, 3 * pi / 2]) {
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        if (position.distanceTo(game.player.position) < 100) game.player.takeDamage(2);
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hurtFlash > 0) hurtFlash = max(0, hurtFlash - dt);
    if (!game.isPlaying || game.isPaused) return;
    final dist = position.distanceTo(game.player.position);
    final spd = (78 + floor * 8.0) * (1 + (phase - 1) * 0.15);

    if (telegraphing) {
      // slow approach while telegraphing
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

    final interval = (dist < 130 ? 0.55 : 1.0) / (1 + (phase - 1) * 0.2);
    meleeTimer += dt;
    if (meleeTimer >= interval) {
      meleeTimer = 0;
      _startTelegraph();
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFF78909C));
    _checkPhase();
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.onEnemyKilled(isBoss: true, at: pos);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 18;
      stuckTimer = 0.75;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.knightBoss(canvas, cx, cy, 1.5, flash: hurtFlash / 0.12);
    final bars = game.difficulty == Difficulty.hard ? 3 : 1;
    for (int i = 0; i < bars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      final colors = [const Color(0xFF78909C), const Color(0xFFFF6D00), const Color(0xFFFFD700)];
      canvas.drawRect(Rect.fromLTWH(cx - 44, -32 - i * 12.0, 88 * remain, 10), Paint()..color = colors[i % colors.length]);
    }
  }
}

class KingBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  late int maxHp, currentHp, phaseHp;
  int phase = 1;
  double meleeTimer = 0, phase2Timer = 0;
  int phase2VolleyCount = 0;
  double telegraphTimer = 0;
  bool telegraphing = false;
  int attackMode = 0;
  double hurtFlash = 0;
  int hardBars = 2;

  KingBoss({required Vector2 position})
      : super(position: position, size: Vector2(145, 155), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    hardBars = game.difficulty == Difficulty.hard ? 4 : 2;
    phaseHp = (420 * game.difficulty.bossHpMult * game.worldThreat).round();
    maxHp = phaseHp * 2;
    if (game.difficulty == Difficulty.hard) {
      maxHp = (maxHp * 1.35).round();
      phaseHp = maxHp ~/ 2;
    }
    currentHp = maxHp;
    add(CircleHitbox(radius: 60));
    game.unlockCodex(CodexId.king);
  }

  int get _barHp => max(1, maxHp ~/ hardBars);

  void _checkHardPhase() {
    if (game.difficulty != Difficulty.hard) return;
    final barIndex = ((maxHp - currentHp) / _barHp).floor() + 1;
    final want = barIndex >= 3 ? 2 : 1;
    if (want != phase) {
      phase = want;
      phase2Timer = 0;
      game.triggerShake(power: 11, time: 0.3);
    }
  }

  void _startTelegraph() {
    if (game.areOtherBossesAlive) return;
    telegraphing = true;
    telegraphTimer = 0.75;
    attackMode = phase == 1 ? Random().nextInt(2) : Random().nextInt(3);
    final toP = (game.player.position - position).normalized();
    final ang = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'circle', radius: 140, life: 0.75)..priority = 6);
        break;
      case 1:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cone', radius: 220, angle: ang, life: 0.75)..priority = 6);
        break;
      case 2:
        game.world.add(TelegraphZone(position: position.clone(), shape: 'cross', radius: 180, life: 0.75)..priority = 6);
        break;
    }
  }

  void _executeAttack() {
    final dist = position.distanceTo(game.player.position);
    final toP = (game.player.position - position).normalized();
    final base = atan2(toP.y, toP.x);
    switch (attackMode) {
      case 0: // slam ring
        final n = game.difficulty == Difficulty.hard ? 16 : 12;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        if (dist < 140) game.player.takeDamage(3);
        break;
      case 1: // cone barrage
        for (final o in [-0.55, -0.35, -0.15, 0.0, 0.15, 0.35, 0.55]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 2: // cross + diagonals
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
    final dist = position.distanceTo(game.player.position);
    final hardBoost = game.difficulty == Difficulty.hard ? 1.0 + ((maxHp - currentHp) / maxHp) * 0.4 : 1.0;

    if (telegraphing) {
      smartMove(game.player.position, (phase == 1 ? 40.0 : 20.0) * hardBoost, dt, radius: 60);
      pushOutOfWalls(60);
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        telegraphing = false;
        _executeAttack();
      }
      return;
    }

    smartMove(game.player.position, (phase == 1 ? 100.0 : 38.0) * hardBoost, dt, radius: 60);
    pushOutOfWalls(60);

    if (phase == 1) {
      final interval = (dist < 140 ? 0.55 : 0.9) / hardBoost;
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
          // telegraph short before each volley in phase 2
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
    if (game.areOtherBossesAlive) return;
    currentHp -= amount;
    hurtFlash = 0.12;
    game.spawnDamageNumber(position, amount, color: const Color(0xFFFFD700));
    if (phase == 1 && currentHp <= phaseHp) {
      phase = 2;
      phase2Timer = 0;
      game.triggerShake(power: 12, time: 0.35);
    }
    _checkHardPhase();
    if (currentHp <= 0) {
      final pos = position.clone();
      removeFromParent();
      game.onEnemyKilled(isBoss: true, at: pos);
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
    final inv = game.areOtherBossesAlive;
    WHDraw.kingBossDraw(canvas, cx, cy, 1.6, flash: hurtFlash / 0.12);
    if (inv) {
      canvas.drawCircle(Offset(cx, cy), 68, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 4);
    }
    for (int i = 0; i < hardBars; i++) {
      final remain = (currentHp - i * _barHp).clamp(0, _barHp) / _barHp;
      final colors = [const Color(0xFFE53935), const Color(0xFFFF9800), const Color(0xFFFFEB3B), const Color(0xFFFFD700)];
      canvas.drawRect(Rect.fromLTWH(cx - 55, -56 - i * 11.0, 110 * remain, 8), Paint()..color = colors[i % colors.length]);
    }
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
          // short telegraph before slam
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

/// Secret boss on overall level 10 — single eye, laser charge, stomp, ring volleys
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
      case 0: // ring
        final n = game.difficulty == Difficulty.hard ? 14 : 10;
        for (int i = 0; i < n; i++) {
          final a = (i / n) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 1: // cone laser-like projectiles
        for (final o in [-0.35, -0.18, 0.0, 0.18, 0.35]) {
          final a = base + o;
          game.world.add(BossProjectile(position: position + Vector2(0, -30), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
        break;
      case 2: // stomp cross
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
      // telegraph cone while charging
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
          game.world.add(CyclopsLaserBeam(position: position + Vector2(0, -30), direction: Vector2(cos(a), sin(a)), damage: 12)..priority = 22);
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
      canvas.drawCircle(Offset(cx, cy - 30), 40 + charge * 20, Paint()
        ..color = Color.fromRGBO(255, 109, 0, 0.25 + charge * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4);
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
