import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: InquisitorGame(),
        overlayBuilderMap: {
          'mainMenu': (context, game) => MainMenu(game as InquisitorGame),
          'settings': (context, game) => SettingsMenu(game as InquisitorGame),
          'gameOver': (context, game) => GameOverMenu(game as InquisitorGame),
          'levelComplete': (context, game) => LevelCompleteMenu(game as InquisitorGame),
        },
        initialActiveOverlays: const ['mainMenu'],
      ),
    ),
  );
}

enum WeaponType { bolter, sword }
enum EnemyType { shooter, melee, shielded }

class InquisitorGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late HudButtonComponent shootButton;
  late HudButtonComponent switchWeaponButton;

  int score = 0;
  bool isPlaying = false;

  int currentFloor = 1;
  int currentLevel = 1;
  int enemiesAlive = 0;
  int enemiesToSpawn = 0;
  int enemiesSpawned = 0;

  double joystickSize = 75;
  double buttonSize = 40;

  final TextPaint hudPaint = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
  );

  @override
  Future<void> onLoad() async {}

  void startGame() {
    isPlaying = true;
    score = 0;
    currentFloor = 1;
    currentLevel = 1;
    _clearEverything();
    _startLevel();
    overlays.remove('mainMenu');
    overlays.remove('settings');
    overlays.remove('gameOver');
    overlays.remove('levelComplete');
  }

  void _clearEverything() {
    world.removeAll(world.children.toList());
    camera.viewport.children.whereType<JoystickComponent>().toList().forEach((c) => c.removeFromParent());
    camera.viewport.children.whereType<HudButtonComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<SpawnComponent>().toList().forEach((c) => c.removeFromParent());
  }

  void _startLevel() {
    enemiesSpawned = 0;
    enemiesAlive = 0;
    enemiesToSpawn = 5 + (currentLevel * 2) + (currentFloor * 3);

    final knobPaint = Paint()..color = const Color(0xFF8B0000);
    final bgPaint = Paint()..color = const Color(0xFF2F2F2F).withOpacity(0.7);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.37, paint: knobPaint),
      background: CircleComponent(radius: joystickSize, paint: bgPaint),
      margin: const EdgeInsets.only(left: 25, bottom: 30),
    );

    shootButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize, paint: Paint()..color = const Color(0xFF8B0000).withOpacity(0.85)),
      buttonDown: CircleComponent(radius: buttonSize, paint: Paint()..color = const Color(0xFF8B0000)),
      margin: const EdgeInsets.only(right: 30, bottom: 40),
      onPressed: () { if (isPlaying) player.isAttacking = true; },
      onReleased: () { if (isPlaying) player.isAttacking = false; },
      onCancelled: () { if (isPlaying) player.isAttacking = false; },
    );

    switchWeaponButton = HudButtonComponent(
      button: CircleComponent(radius: 28, paint: Paint()..color = Colors.grey[800]!),
      buttonDown: CircleComponent(radius: 28, paint: Paint()..color = Colors.grey),
      margin: const EdgeInsets.only(right: 30, bottom: 130),
      onPressed: () { if (isPlaying) player.switchWeapon(); },
    );

    player = Player(joystick);
    world.add(player);
    camera.viewport.add(joystick);
    camera.viewport.add(shootButton);
    camera.viewport.add(switchWeaponButton);

    _spawnWave();
  }

  void _spawnWave() {
    final spawnPeriod = max(0.35, 1.55 - (currentFloor * 0.15) - (currentLevel * 0.08));

    add(SpawnComponent(
      factory: (index) {
        if (enemiesSpawned >= enemiesToSpawn) {
          return PositionComponent(); // пустышка, чтобы не ломать тип
        }
        enemiesSpawned++;
        enemiesAlive++;

        EnemyType type;
        final roll = Random().nextDouble();
        if (currentFloor == 1) {
          type = roll < 0.55 ? EnemyType.melee : EnemyType.shooter;
        } else if (currentFloor <= 3) {
          type = roll < 0.35 ? EnemyType.melee : (roll < 0.7 ? EnemyType.shooter : EnemyType.shielded);
        } else {
          type = roll < 0.3 ? EnemyType.melee : (roll < 0.6 ? EnemyType.shooter : EnemyType.shielded);
        }
        return Enemy(floor: currentFloor, type: type);
      },
      period: spawnPeriod,
      selfPositioning: true,
    ));
  }

  void onEnemyKilled() {
    enemiesAlive = max(0, enemiesAlive - 1);
    score += 10 + (currentFloor * 5);
    if (enemiesAlive <= 0 && enemiesSpawned >= enemiesToSpawn) {
      _levelCompleted();
    }
  }

  void _levelCompleted() {
    isPlaying = false;
    if (currentLevel >= 5) {
      if (currentFloor >= 5) {
        overlays.add('gameOver');
        return;
      }
      currentFloor++;
      currentLevel = 1;
    } else {
      currentLevel++;
    }
    overlays.add('levelComplete');
  }

  void nextLevel() {
    overlays.remove('levelComplete');
    _clearEverything();
    isPlaying = true;
    _startLevel();
  }

  void openSettings() {
    overlays.remove('mainMenu');
    overlays.add('settings');
  }

  void backToMenu() {
    isPlaying = false;
    _clearEverything();
    overlays.remove('settings');
    overlays.remove('gameOver');
    overlays.remove('levelComplete');
    overlays.add('mainMenu');
  }

  void showGameOver() {
    isPlaying = false;
    overlays.add('gameOver');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (isPlaying) {
      hudPaint.render(canvas, 'Floor $currentFloor  |  Level $currentLevel', Vector2(16, 16));
      hudPaint.render(canvas, 'Score: $score', Vector2(16, 42));
      hudPaint.render(canvas, 'HP: ${player.health}', Vector2(16, 68));
      hudPaint.render(canvas, 'Enemies: $enemiesAlive', Vector2(16, 94));
      hudPaint.render(canvas, 'Weapon: ${player.weapon == WeaponType.bolter ? "BOLTER" : "SWORD"}', Vector2(16, 120));
    }
  }
}

// ====================== МЕНЮ ======================
class MainMenu extends StatelessWidget {
  final InquisitorGame game;
  const MainMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Soul of the Inquisitor',
                style: TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('From the Inquisitor\'s perspective', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16)),
              onPressed: () => game.startGame(),
              child: const Text('PLAY', style: TextStyle(fontSize: 22, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: () => game.openSettings(),
              child: const Text('Settings', style: TextStyle(fontSize: 18, color: Colors.white)),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Text('Joystick size: ${widget.game.joystickSize.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18)),
              Slider(value: widget.game.joystickSize, min: 50, max: 120, divisions: 14, activeColor: Colors.blue,
                  onChanged: (v) => setState(() => widget.game.joystickSize = v)),
              const SizedBox(height: 30),
              Text('Button size: ${widget.game.buttonSize.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18)),
              Slider(value: widget.game.buttonSize, min: 25, max: 70, divisions: 9, activeColor: Colors.red,
                  onChanged: (v) => setState(() => widget.game.buttonSize = v)),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
                  onPressed: () => widget.game.backToMenu(),
                  child: const Text('Back', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
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
            const Text('LEVEL CLEARED', style: TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Floor ${game.currentFloor}  •  Level ${game.currentLevel}', style: const TextStyle(color: Colors.white70, fontSize: 18)),
            Text('Score: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: () => game.nextLevel(),
              child: const Text('NEXT LEVEL', style: TextStyle(fontSize: 20, color: Colors.white)),
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
            const Text('THE INQUISITOR HAS FALLEN',
                style: TextStyle(color: Colors.redAccent, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Score: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 24)),
            Text('Floor ${game.currentFloor}  •  Level ${game.currentLevel}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: () => game.startGame(),
              child: const Text('TRY AGAIN', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: () => game.backToMenu(),
              child: const Text('Main Menu', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== ИНКВИЗИТОР ======================
class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  double speed = 210;
  int health = 6;
  bool isAttacking = false;
  double attackTimer = 0;
  WeaponType weapon = WeaponType.bolter;

  Player(this.joystick) : super(size: Vector2(52, 58), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = game.size / 2;
    add(CircleHitbox(radius: 22));
  }

  void switchWeapon() {
    weapon = weapon == WeaponType.bolter ? WeaponType.sword : WeaponType.bolter;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    if (joystick.direction != JoystickDirection.idle) {
      position.add(joystick.relativeDelta * speed * dt);
      angle = joystick.delta.screenAngle();
    }

    position.x = position.x.clamp(26, game.size.x - 26);
    position.y = position.y.clamp(29, game.size.y - 29);

    if (isAttacking) {
      attackTimer += dt;
      final interval = weapon == WeaponType.bolter ? 0.32 : 0.45;
      if (attackTimer >= interval) {
        attackTimer = 0;
        _doAttack();
      }
    }
  }

  void _doAttack() {
    final dir = joystick.relativeDelta.normalized();
    final attackDir = dir == Vector2.zero() ? Vector2(0, -1) : dir;

    if (weapon == WeaponType.bolter) {
      game.world.add(Bullet(position: position.clone(), direction: attackDir));
    } else {
      game.world.add(MeleeAttack(position: position + attackDir * 34, direction: attackDir));
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Плащ
    final cape = Paint()..color = const Color(0xFF6B0000).withOpacity(0.7);
    final capePath = Path()
      ..moveTo(cx - 18, cy + 4)
      ..quadraticBezierTo(cx - 28, cy + 22, cx - 8, cy + 28)
      ..lineTo(cx + 8, cy + 28)
      ..quadraticBezierTo(cx + 28, cy + 22, cx + 18, cy + 4)
      ..close();
    canvas.drawPath(capePath, cape);

    // Торс
    final body = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6), width: 28, height: 26), const Radius.circular(6)), body);

    // Плечи
    final shoulder = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawCircle(Offset(cx - 14, cy + 2), 7, shoulder);
    canvas.drawCircle(Offset(cx + 14, cy + 2), 7, shoulder);

    // Голова
    final head = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(Offset(cx, cy - 12), 11, head);

    // Визор
    final visor = Paint()..color = const Color(0xFFB22222);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 13), width: 14, height: 5), const Radius.circular(2)), visor);

    // Символ
    final symbol = Paint()..color = const Color(0xFF8B0000);
    canvas.drawCircle(Offset(cx, cy + 4), 4, symbol);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!game.isPlaying) return;

    if (other is Enemy || other is EnemyBullet) {
      health--;
      other.removeFromParent();
      if (other is Enemy) game.onEnemyKilled();
      if (health <= 0) {
        health = 0;
        game.showGameOver();
      }
    }
  }
}

// ====================== ВРАГИ ======================
class Enemy extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  final EnemyType type;
  late final double speed;
  double shootTimer = 0;
  final double shootInterval = 1.85;

  Enemy({required this.floor, required this.type}) : super(size: Vector2(46, 52), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    switch (type) {
      case EnemyType.shooter:
        speed = 50 + floor * 7.0;
        break;
      case EnemyType.melee:
        speed = 85 + floor * 11.0;
        break;
      case EnemyType.shielded:
        speed = 40 + floor * 5.5;
        size = Vector2(52, 56);
        break;
    }

    final side = Random().nextInt(4);
    switch (side) {
      case 0: position = Vector2(Random().nextDouble() * game.size.x, -40); break;
      case 1: position = Vector2(Random().nextDouble() * game.size.x, game.size.y + 40); break;
      case 2: position = Vector2(-40, Random().nextDouble() * game.size.y); break;
      case 3: position = Vector2(game.size.x + 40, Random().nextDouble() * game.size.y); break;
    }

    add(CircleHitbox(radius: type == EnemyType.shielded ? 24 : 19));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * speed * dt);
    angle = toPlayer.screenAngle();

    if (type == EnemyType.shooter) {
      shootTimer += dt;
      if (shootTimer >= shootInterval) {
        shootTimer = 0;
        game.world.add(EnemyBullet(position: position.clone(), direction: toPlayer));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    final body = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 5), width: 24, height: 24), const Radius.circular(5)), body);

    final shoulder = Paint()..color = const Color(0xFF3A3A3A);
    canvas.drawCircle(Offset(cx - 12, cy + 1), 6.5, shoulder);
    canvas.drawCircle(Offset(cx + 12, cy + 1), 6.5, shoulder);

    final head = Paint()..color = const Color(0xFF1F1F1F);
    canvas.drawCircle(Offset(cx, cy - 13), 10, head);

    switch (type) {
      case EnemyType.shooter:
        final accent = Paint()..color = const Color(0xFF2E8B57);
        canvas.drawCircle(Offset(cx, cy - 14), 4, accent);
        final gun = Paint()..color = const Color(0xFF111111)..strokeWidth = 4..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx + 6, cy - 2), Offset(cx + 18, cy - 8), gun);
        break;
      case EnemyType.melee:
        final accent = Paint()..color = const Color(0xFFDAA520);
        canvas.drawCircle(Offset(cx, cy - 14), 4, accent);
        final blade = Paint()..color = const Color(0xFFC9A227)..strokeWidth = 3.5..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx + 8, cy - 4), Offset(cx + 19, cy - 16), blade);
        break;
      case EnemyType.shielded:
        final accent = Paint()..color = const Color(0xFF1E90FF);
        canvas.drawCircle(Offset(cx, cy - 14), 4, accent);
        final shield = Paint()
          ..color = const Color(0xFF4169E1).withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5;
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy + 2), radius: 23), -1.1, 2.2, false, shield);
        break;
    }
  }
}

// ====================== ПУЛИ ======================
class Bullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 490;

  Bullet({required super.position, required this.direction})
      : super(radius: 6, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFFD700));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * speed * dt);
    if (position.x < -40 || position.x > game.size.x + 40 || position.y < -40 || position.y > game.size.y + 40) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      if (other.type == EnemyType.shielded) {
        removeFromParent();
        return;
      }
      other.removeFromParent();
      game.onEnemyKilled();
      removeFromParent();
    }
  }
}

class MeleeAttack extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  double life = 0.17;

  MeleeAttack({required super.position, required this.direction})
      : super(radius: 30, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFAAAAAA).withOpacity(0.55));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      other.removeFromParent();
      game.onEnemyKilled();
    }
  }
}

class EnemyBullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 150;

  EnemyBullet({required super.position, required this.direction})
      : super(radius: 7, anchor: Anchor.center, paint: Paint()..color = const Color(0xFF7CFC00));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * speed * dt);
    if (position.x < -50 || position.x > game.size.x + 50 || position.y < -50 || position.y > game.size.y + 50) {
      removeFromParent();
    }
  }
}
