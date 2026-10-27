part of '../main.dart';

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
    final total = game.playerClass == PlayerClass.malleus ? 13.0 : game.playerClass == PlayerClass.xenos ? 15.0 : 11.0;
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
/// Procedural enemy material pass: faction-specific plates, chitin, scars, runes and glow.
/// All shapes are generated at runtime with Canvas; no textures or external art are used.
class EnemyTextureRenderer {
  static void draw(
    Canvas c, {
    required double cx,
    required double cy,
    required EnemyType type,
    double scale = 1.0,
    double clock = 0,
    int variant = 0,
    double healthRatio = 1,
    bool champion = false,
  }) {
    final s = scale;
    final pulse = 0.55 + 0.45 * sin(clock * 4.2 + variant * 0.7);
    final hp = healthRatio.clamp(0.0, 1.0).toDouble();
    final pale = const Color(0xFFC9C4B7);
    final dark = const Color(0xFF17191B);

    // Common painted surface: edge highlights, rivets, seams and wear scratches.
    if (type != EnemyType.dog && type != EnemyType.tyranidGaunt && type != EnemyType.genestealer && type != EnemyType.chaosSpawn && type != EnemyType.bloodletter) {
      final base = switch (type) {
        EnemyType.necronWarrior || EnemyType.necronImmortal => const Color(0xFF9AA7A0),
        EnemyType.orkBoy => const Color(0xFF4B5142),
        EnemyType.plagueBearer => const Color(0xFF66753A),
        EnemyType.brute => const Color(0xFF5A463B),
        EnemyType.shielded || EnemyType.shieldedShooter => const Color(0xFF81919B),
        _ => const Color(0xFF7A5A50),
      };
      final torso = Rect.fromCenter(center: Offset(cx, cy + 6 * s), width: 23 * s, height: 26 * s);
      c.drawRRect(RRect.fromRectAndRadius(torso, Radius.circular(3 * s)), Paint()..color = base.withOpacity(0.32));
      c.drawLine(Offset(torso.left + 3*s, torso.top + 4*s), Offset(torso.left + 3*s, torso.bottom - 4*s), Paint()..color = pale.withOpacity(0.26)..strokeWidth = 1.0*s);
      for (int i=0; i<3; i++) {
        final y = cy - 1*s + i*6*s;
        c.drawLine(Offset(cx - 7*s, y), Offset(cx + 7*s, y), Paint()..color = dark.withOpacity(0.35)..strokeWidth = 1.0*s);
      }
      for (final side in [-1.0, 1.0]) {
        c.drawCircle(Offset(cx + side*10*s, cy + 1*s), 1.25*s, Paint()..color = pale.withOpacity(0.8));
      }
      if (variant % 2 == 0 || hp < 0.72) {
        final wear = Paint()..color = const Color(0xFF171412).withOpacity(0.45 + (1-hp)*0.3)..strokeWidth = 1.2*s..strokeCap = StrokeCap.round;
        c.drawLine(Offset(cx - 8*s, cy - 5*s), Offset(cx - 3*s, cy - 1*s), wear);
        c.drawLine(Offset(cx + 5*s, cy + 8*s), Offset(cx + 9*s, cy + 12*s), wear);
        if (hp < 0.45) c.drawLine(Offset(cx - 3*s, cy + 13*s), Offset(cx + 1*s, cy + 18*s), wear);
      }
    }

    switch (type) {
      case EnemyType.shooter:
      case EnemyType.melee:
      case EnemyType.flamer:
      case EnemyType.sniper:
      case EnemyType.cultPsyker:
        // Ragged cult robes, stitched hems, forbidden icon and improvised armor.
        final robe = type == EnemyType.cultPsyker ? const Color(0xFFB388FF) : const Color(0xFFBCAAA4);
        for (int i=0; i<4; i++) {
          final x = cx - 10*s + i*6.5*s;
          c.drawLine(Offset(x, cy + 18*s), Offset(x + (i.isEven ? 1.5 : -1.5)*s, cy + 31*s), Paint()..color = robe.withOpacity(0.42)..strokeWidth = 1.1*s);
        }
        final sigil = Path()..moveTo(cx, cy - 1*s)..lineTo(cx + 4*s, cy + 5*s)..lineTo(cx, cy + 11*s)..lineTo(cx - 4*s, cy + 5*s)..close();
        c.drawPath(sigil, Paint()..color = type == EnemyType.cultPsyker ? const Color(0xFFEA80FC) : const Color(0xFFB71C1C));
        c.drawCircle(Offset(cx, cy + 5*s), 5.5*s, Paint()..color = const Color(0xFF211817)..style = PaintingStyle.stroke..strokeWidth = 1.0*s);
        c.drawLine(Offset(cx - 13*s, cy + 1*s), Offset(cx - 17*s, cy + 12*s), Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 2*s);
        if (type == EnemyType.flamer) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8*s, cy - 1*s, 9*s, 14*s), Radius.circular(2*s)), Paint()..color = const Color(0xFF263238));
          c.drawCircle(Offset(cx + 16*s, cy + 2*s), 3.5*s, Paint()..color = Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFFF59D), pulse)!);
        }
        if (type == EnemyType.sniper) {
          c.drawLine(Offset(cx + 3*s, cy - 9*s), Offset(cx + 15*s, cy - 9*s), Paint()..color = const Color(0xFFCFD8DC)..strokeWidth = 1.3*s);
          c.drawCircle(Offset(cx + 7*s, cy - 11*s), 2*s, Paint()..color = const Color(0xFFFFB74D));
        }
        if (type == EnemyType.cultPsyker) {
          WHDraw.energyArc(c, Offset(cx, cy + 3*s), 24*s, const Color(0xFFB388FF), clock*0.8, 0.42*s);
          c.drawCircle(Offset(cx - 17*s, cy + 8*s), 3*s, Paint()..color = const Color(0xFFEA80FC).withOpacity(pulse));
          c.drawCircle(Offset(cx + 17*s, cy + 8*s), 3*s, Paint()..color = const Color(0xFFEA80FC).withOpacity(pulse));
        }
        break;
      case EnemyType.shielded:
      case EnemyType.shieldedShooter:
        // Heavy ceramite-like segmented armor, riveted pauldrons and heraldic stripe.
        for (final side in [-1.0, 1.0]) {
          final r = Rect.fromCenter(center: Offset(cx + side*15*s, cy - 1*s), width: 13*s, height: 15*s);
          c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(3*s)), Paint()..color = const Color(0xFF455A64));
          c.drawRRect(RRect.fromRectAndRadius(r.deflate(2*s), Radius.circular(2*s)), Paint()..color = const Color(0xFF90A4AE).withOpacity(0.38)..style = PaintingStyle.stroke..strokeWidth = 1*s);
          c.drawCircle(Offset(cx + side*15*s, cy - 1*s), 1.4*s, Paint()..color = const Color(0xFFFFD54F));
        }
        c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 6*s), width: 4*s, height: 19*s), Paint()..color = const Color(0xFFC62828));
        c.drawCircle(Offset(cx, cy + 4*s), 4*s, Paint()..color = const Color(0xFFFFD54F));
        c.drawLine(Offset(cx - 4*s, cy + 4*s), Offset(cx + 4*s, cy + 4*s), Paint()..color = dark..strokeWidth = 1.2*s);
        break;
      case EnemyType.dog:
        // Hound musculature, spines, segmented jaw and warp-brand.
        for (int i=0; i<4; i++) {
          final x = cx - 8*s + i*5*s;
          final spike = Path()..moveTo(x, cy - 7*s)..lineTo(x + 2*s, cy - (17 + (i%2)*4)*s)..lineTo(x + 5*s, cy - 5*s)..close();
          c.drawPath(spike, Paint()..color = const Color(0xFF5D4037));
        }
        c.drawLine(Offset(cx + 17*s, cy - 2*s), Offset(cx + 27*s, cy + 1*s), Paint()..color = const Color(0xFFBCAAA4)..strokeWidth = 2*s);
        c.drawCircle(Offset(cx + 24*s, cy - 10*s), 3.2*s, Paint()..color = const Color(0xFFFF1744).withOpacity(pulse));
        c.drawLine(Offset(cx - 10*s, cy + 5*s), Offset(cx + 5*s, cy + 10*s), Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 2*s);
        break;
      case EnemyType.brute:
        // Massive scavenged plates, studs, crude chain links and old impact dents.
        for (final side in [-1.0, 1.0]) {
          final r = Rect.fromCenter(center: Offset(cx + side*14*s, cy - 1*s), width: 15*s, height: 18*s);
          c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(4*s)), Paint()..color = const Color(0xFF5D4037));
          c.drawRRect(RRect.fromRectAndRadius(r.deflate(2*s), Radius.circular(3*s)), Paint()..color = const Color(0xFFBCAAA4).withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.2*s);
          c.drawCircle(Offset(cx + side*14*s, cy - 1*s), 1.8*s, Paint()..color = const Color(0xFFB0BEC5));
        }
        for (int i=0; i<5; i++) c.drawCircle(Offset(cx - 10*s + i*5*s, cy + 14*s), 1.3*s, Paint()..color = const Color(0xFFB0BEC5));
        c.drawLine(Offset(cx - 8*s, cy - 10*s), Offset(cx + 8*s, cy - 10*s), Paint()..color = const Color(0xFFFF6D00).withOpacity(pulse)..strokeWidth = 2*s);
        break;
      case EnemyType.plagueBearer:
        // Diseased hide, pustules, hanging boils and corroded blade scars.
        for (final o in [Offset(-13,0), Offset(12,4), Offset(-5,15), Offset(8,20), Offset(0,-4)]) {
          c.drawCircle(Offset(cx + o.dx*s, cy + o.dy*s), 3.2*s, Paint()..color = const Color(0xFF9CCC65));
          c.drawCircle(Offset(cx + o.dx*s - .7*s, cy + o.dy*s - .8*s), 1.0*s, Paint()..color = const Color(0xFFE6EE9C).withOpacity(0.8));
        }
        c.drawArc(Rect.fromCenter(center: Offset(cx, cy + 6*s), width: 26*s, height: 18*s), 0.1, 2.8, false, Paint()..color = const Color(0xFF26351A)..style = PaintingStyle.stroke..strokeWidth = 2*s);
        for (int i=0; i<3; i++) c.drawLine(Offset(cx + (i-1)*6*s, cy + 20*s), Offset(cx + (i-1)*6*s, cy + (24 + i%2*3)*s), Paint()..color = const Color(0xFF8D9B45)..strokeWidth = 1.4*s);
        break;
      case EnemyType.bloodletter:
        // Daemonic horns, sinew grooves, brass collar and hellblade edge.
        for (final side in [-1.0, 1.0]) {
          final horn = Path()..moveTo(cx + side*7*s, cy - 23*s)..quadraticBezierTo(cx + side*17*s, cy - 34*s, cx + side*13*s, cy - 39*s)..lineTo(cx + side*4*s, cy - 25*s)..close();
          c.drawPath(horn, Paint()..color = const Color(0xFF3E2723));
          c.drawLine(Offset(cx + side*5*s, cy - 8*s), Offset(cx + side*11*s, cy + 12*s), Paint()..color = const Color(0xFF8E2424)..strokeWidth = 2*s);
        }
        c.drawArc(Rect.fromCenter(center: Offset(cx, cy + 2*s), width: 29*s, height: 14*s), 0, pi, false, Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.stroke..strokeWidth = 2*s);
        c.drawLine(Offset(cx + 17*s, cy + 3*s), Offset(cx + 27*s, cy - 13*s), Paint()..color = const Color(0xFFECEFF1)..strokeWidth = 2.5*s);
        c.drawCircle(Offset(cx - 4*s, cy - 17*s), 2*s, Paint()..color = const Color(0xFFFFD54F));
        c.drawCircle(Offset(cx + 4*s, cy - 17*s), 2*s, Paint()..color = const Color(0xFFFFD54F));
        break;
      case EnemyType.orkBoy:
        // Green skin, brutal jaw, tusks, mismatched plates and crude checker paint.
        c.drawOval(Rect.fromCenter(center: Offset(cx, cy - 14*s), width: 19*s, height: 17*s), Paint()..color = const Color(0xFF558B2F));
        c.drawOval(Rect.fromCenter(center: Offset(cx - 13*s, cy + 2*s), width: 8*s, height: 19*s), Paint()..color = const Color(0xFF558B2F));
        c.drawOval(Rect.fromCenter(center: Offset(cx + 13*s, cy + 2*s), width: 8*s, height: 19*s), Paint()..color = const Color(0xFF558B2F));
        c.drawArc(Rect.fromCenter(center: Offset(cx, cy - 11*s), width: 17*s, height: 10*s), 0, pi, false, Paint()..color = const Color(0xFF1B2414)..style = PaintingStyle.stroke..strokeWidth = 2*s);
        for (final side in [-1.0, 1.0]) {
          final tusk = Path()..moveTo(cx + side*4*s, cy - 10*s)..lineTo(cx + side*6*s, cy - 3*s)..lineTo(cx + side*1*s, cy - 7*s)..close();
          c.drawPath(tusk, Paint()..color = const Color(0xFFFFF3E0));
        }
        final plateR = Rect.fromCenter(center: Offset(cx - 10*s, cy + 1*s), width: 12*s, height: 14*s);
        c.drawRRect(RRect.fromRectAndRadius(plateR, Radius.circular(2*s)), Paint()..color = const Color(0xFF8D6E63));
        for (int i=0; i<3; i++) for (int j=0; j<2; j++) {
          c.drawRect(Rect.fromLTWH(plateR.left + i*4*s, plateR.top + j*6*s, 3*s, 3*s), Paint()..color = (i+j).isEven ? const Color(0xFF212121) : const Color(0xFFFFD54F));
        }
        c.drawLine(Offset(cx - 3*s, cy + 9*s), Offset(cx + 7*s, cy + 12*s), Paint()..color = const Color(0xFF263238)..strokeWidth = 2*s);
        break;
      case EnemyType.tyranidGaunt:
        // Chitin carapace plates, ribbed abdomen, hooked scythes and bio-luminescence.
        final shell = Path()..moveTo(cx - 13*s, cy - 9*s)..quadraticBezierTo(cx, cy - 31*s, cx + 13*s, cy - 9*s)..lineTo(cx + 10*s, cy + 4*s)..lineTo(cx - 10*s, cy + 4*s)..close();
        c.drawPath(shell, Paint()..color = const Color(0xFF4E342E));
        c.drawPath(shell, Paint()..color = const Color(0xFF9CCC65).withOpacity(0.65)..style = PaintingStyle.stroke..strokeWidth = 1.4*s);
        for (int i=0; i<4; i++) {
          final y = cy - 3*s + i*5*s;
          c.drawArc(Rect.fromCenter(center: Offset(cx, y), width: 18*s, height: 7*s), 0, pi, false, Paint()..color = const Color(0xFFB0C76A)..style = PaintingStyle.stroke..strokeWidth = 1.3*s);
        }
        for (final side in [-1.0, 1.0]) {
          final claw = Path()..moveTo(cx + side*10*s, cy + 2*s)..quadraticBezierTo(cx + side*23*s, cy + 8*s, cx + side*20*s, cy + 20*s)..lineTo(cx + side*14*s, cy + 12*s)..close();
          c.drawPath(claw, Paint()..color = const Color(0xFFCFD8DC));
          c.drawLine(Offset(cx + side*8*s, cy - 6*s), Offset(cx + side*15*s, cy - 13*s), Paint()..color = const Color(0xFFB0C76A)..strokeWidth = 2*s);
        }
        c.drawCircle(Offset(cx + 4*s, cy - 15*s), 2.2*s, Paint()..color = Color.lerp(const Color(0xFF76FF03), const Color(0xFFE6EE9C), pulse)!);
        break;
      case EnemyType.genestealer:
        // Sleek alien carapace, four-limb silhouette, ridged forehead and talons.
        final head = Path()..moveTo(cx - 10*s, cy - 11*s)..lineTo(cx - 5*s, cy - 25*s)..lineTo(cx + 3*s, cy - 29*s)..lineTo(cx + 11*s, cy - 14*s)..lineTo(cx + 7*s, cy - 7*s)..close();
        c.drawPath(head, Paint()..color = const Color(0xFF3949AB));
        for (int i=0; i<4; i++) c.drawLine(Offset(cx - 7*s + i*4*s, cy - 22*s), Offset(cx - 5*s + i*4*s, cy - 13*s), Paint()..color = const Color(0xFF9FA8DA)..strokeWidth = 1*s);
        for (final side in [-1.0, 1.0]) {
          c.drawLine(Offset(cx + side*9*s, cy - 1*s), Offset(cx + side*21*s, cy + 12*s), Paint()..color = const Color(0xFF5C6BC0)..strokeWidth = 3*s..strokeCap = StrokeCap.round);
          c.drawLine(Offset(cx + side*12*s, cy + 5*s), Offset(cx + side*24*s, cy + 21*s), Paint()..color = const Color(0xFFCFD8DC)..strokeWidth = 2.4*s..strokeCap = StrokeCap.round);
          c.drawLine(Offset(cx + side*24*s, cy + 21*s), Offset(cx + side*27*s, cy + 24*s), Paint()..color = const Color(0xFFECEFF1)..strokeWidth = 1.4*s);
        }
        c.drawCircle(Offset(cx - 4*s, cy - 17*s), 2.3*s, Paint()..color = const Color(0xFFFF1744).withOpacity(pulse));
        c.drawCircle(Offset(cx + 4*s, cy - 17*s), 2.3*s, Paint()..color = const Color(0xFFFF1744).withOpacity(pulse));
        break;
      case EnemyType.necronWarrior:
      case EnemyType.necronImmortal:
        // Skeletal living-metal ribs, angular crown, green gauss conduits and phase seams.
        final green = Color.lerp(const Color(0xFF00E5FF), const Color(0xFF76FF03), pulse)!;
        final head = Path()..moveTo(cx - 8*s, cy - 25*s)..lineTo(cx, cy - 31*s)..lineTo(cx + 8*s, cy - 25*s)..lineTo(cx + 6*s, cy - 13*s)..lineTo(cx - 6*s, cy - 13*s)..close();
        c.drawPath(head, Paint()..color = const Color(0xFF9EAAA3));
        c.drawRect(Rect.fromCenter(center: Offset(cx, cy - 19*s), width: 10*s, height: 2.5*s), Paint()..color = green);
        for (int i=0; i<4; i++) {
          final y = cy - 3*s + i*5*s;
          c.drawArc(Rect.fromCenter(center: Offset(cx, y), width: 17*s, height: 6*s), 0.1, pi-0.2, false, Paint()..color = const Color(0xFFB0BDB5)..style = PaintingStyle.stroke..strokeWidth = 1.6*s);
        }
        c.drawLine(Offset(cx - 9*s, cy - 5*s), Offset(cx - 13*s, cy + 15*s), Paint()..color = const Color(0xFF9EAAA3)..strokeWidth = 3*s);
        c.drawLine(Offset(cx + 9*s, cy - 5*s), Offset(cx + 13*s, cy + 15*s), Paint()..color = const Color(0xFF9EAAA3)..strokeWidth = 3*s);
        c.drawLine(Offset(cx + 12*s, cy - 6*s), Offset(cx + 23*s, cy - 6*s), Paint()..color = green.withOpacity(0.45)..strokeWidth = 7*s..maskFilter = MaskFilter.blur(BlurStyle.normal, 3*s));
        c.drawLine(Offset(cx + 12*s, cy - 6*s), Offset(cx + 23*s, cy - 6*s), Paint()..color = green..strokeWidth = 2.4*s);
        if (type == EnemyType.necronImmortal) {
          for (int i=0; i<3; i++) c.drawLine(Offset(cx - 8*s, cy + 7*s + i*4*s), Offset(cx + 8*s, cy + 7*s + i*4*s), Paint()..color = green.withOpacity(0.7)..strokeWidth = 1.3*s);
        }
        break;
      case EnemyType.chaosSpawn:
        // Mutated flesh, asymmetrical horns, warp blisters and curling tendrils.
        for (int i=0; i<3; i++) {
          final side = i.isEven ? -1.0 : 1.0;
          final start = Offset(cx + side*(9 + i*2)*s, cy + (i-1)*4*s);
          final path = Path()..moveTo(start.dx, start.dy)..cubicTo(start.dx + side*10*s, start.dy - 7*s, start.dx + side*13*s, start.dy + 7*s, start.dx + side*(17+i*2)*s, start.dy + 1*s);
          final tendrilPaint = Paint()
            ..color = i.isEven ? const Color(0xFF8E24AA) : const Color(0xFF6D4C41)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (2.2 - i * 0.25) * s
            ..strokeCap = StrokeCap.round;
          c.drawPath(path, tendrilPaint);
        }
        for (final o in [Offset(-7,-8), Offset(5,-14), Offset(12,6), Offset(-9,13)]) {
          c.drawCircle(Offset(cx + o.dx*s, cy + o.dy*s), (2.6 + pulse)*s, Paint()..color = const Color(0xFFCE93D8).withOpacity(0.65));
        }
        for (final side in [-1.0, 1.0]) {
          final horn = Path()..moveTo(cx + side*8*s, cy - 15*s)..quadraticBezierTo(cx + side*17*s, cy - 27*s, cx + side*13*s, cy - 32*s);
          c.drawPath(horn, Paint()..color = const Color(0xFFBCAAA4)..style = PaintingStyle.stroke..strokeWidth = 3*s..strokeCap = StrokeCap.round);
        }
        break;
    }

    if (champion) {
      final glow = const Color(0xFFFFC857).withOpacity(0.25 + pulse*0.25);
      c.drawCircle(Offset(cx, cy), 30*s, Paint()..color = glow..style = PaintingStyle.stroke..strokeWidth = 1.6*s);
      WHDraw.engravedRunes(c, Offset(cx, cy + 5*s), 24*s, const Color(0xFFFFD54F), 0.45*s, count: 8);
    }
  }
}

