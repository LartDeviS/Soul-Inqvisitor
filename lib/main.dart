import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
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

    // Джойстик
    final knobPaint = Paint()..color = const Color(0xFF8B0000);
    final bgPaint = Paint()..color = const Color(0xFF2F2F2F).withOpacity(0.7);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.37, paint: knobPaint),
      background: CircleComponent(radius: joystickSize, paint: bgPaint),
      margin: const EdgeInsets.only(left: 25, bottom: 30),
    );

    // Кнопка атаки
    shootButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize, paint: Paint()..color = const Color(0xFF8B0000).withOpacity(0.8)),
      buttonDown: CircleComponent(radius: buttonSize, paint: Paint()..color = const Color(0xFF8B0000)),
      margin: const EdgeInsets.only(right: 30, bottom: 40),
      onPressed: () {
        if (isPlaying) player.isAttacking = true;
      },
      onReleased: () {
        if (isPlaying) player.isAttacking = false;
      },
      onCancelled: () {
        if (isPlaying) player.isAttacking = false;
      },
    );

    // Кнопка смены оружия
    switchWeaponButton = HudButtonComponent(
      button: CircleComponent(radius: 28, paint: Paint()..color = Colors.grey[800]!),
      buttonDown: CircleComponent(radius: 28, paint: Paint()..color = Colors.grey),
      margin: const EdgeInsets.only(right: 30, bottom: 130),
      onPressed: () {
        if (isPlaying) player.switchWeapon();
      },
    );

    player = Player(joystick);
    world.add(player);
    camera.viewport.add(joystick);
    camera.viewport.add(shootButton);
    camera.viewport.add(switchWeaponButton);

    _spawnWave();
  }

  void _spawnWave() {
    final spawnPeriod = max(0.35, 1.6 - (currentFloor * 0.15) - (currentLevel * 0.08));

    add(SpawnComponent(
      factory: (_) {
        if (enemiesSpawned >= enemiesToSpawn) return null;
        enemiesSpawned++;
        enemiesAlive++;

        // Типы врагов зависят от этажа
        EnemyType type;
        final roll = Random().nextDouble();
        if (currentFloor == 1) {
          type = roll < 0.6 ? EnemyType.melee : EnemyType.shooter;
        } else if (currentFloor == 2) {
          type = roll < 0.4 ? EnemyType.melee : (roll < 0.75 ? EnemyType.shooter : EnemyType.shielded);
        } else {
          type = roll < 0.3 ? EnemyType.melee : (roll < 0.65 ? EnemyType.shooter : EnemyType.shielded);
        }

        return Enemy(floor: currentFloor, type: type);
      },
      period: spawnPeriod,
      selfPositioning: true,
    ));
  }

  void onEnemyKilled() {
    enemiesAlive--;
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

// ==================== МЕНЮ (оставляем как было) ====================
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
            const Text(
              'Soul of the Inquisitor',
              style: TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
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
              Slider(
                value: widget.game.joystickSize,
                min: 50, max: 120, divisions: 14, activeColor: Colors.blue,
                onChanged: (v) => setState(() => widget.game.joystickSize = v),
              ),
              const SizedBox(height: 30),
              Text('Button size: ${widget.game.buttonSize.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18)),
              Slider(
                value: widget.game.buttonSize,
                min: 25, max: 70, divisions: 9, activeColor: Colors.red,
                onChanged: (v) => setState(() => widget.game.buttonSize = v),
              ),
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
            const Text('THE INQUISITOR HAS FALLEN', style: TextStyle(color: Colors.redAccent, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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

// ==================== ИГРОК ====================
class Player extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  double speed = 210;
  int health = 6;
  bool isAttacking = false;
  double attackTimer = 0;
  WeaponType weapon = WeaponType.bolter;

  // Цвета Инквизитора: чёрный / серый / красный
  final Paint bodyPaint = Paint()..color = const Color(0xFF1A1A1A); // почти чёрный
  final Paint accentPaint = Paint()..color = const Color(0xFF8B0000); // тёмно-красный

  Player(this.joystick) : super(radius: 22, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = game.size / 2;
    paint = bodyPaint;
    add(CircleHitbox());
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

    position.x = position.x.clamp(radius, game.size.x - radius);
    position.y = position.y.clamp(radius, game.size.y - radius);

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
      game.world.add(Bullet(position: position.clone(), direction: attackDir, isPlayer: true));
    } else {
      // Меч — ближняя атака
      game.world.add(MeleeAttack(position: position + attackDir * 30, direction: attackDir));
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!game.isPlaying) return;

    if (other is Enemy) {
      health--;
      other.removeFromParent();
      game.onEnemyKilled();
      if (health <= 0) {
        health = 0;
        game.showGameOver();
      }
    } else if (other is EnemyBullet) {
      health--;
      other.removeFromParent();
      if (health <= 0) {
        health = 0;
        game.showGameOver();
      }
    }
  }
}

// ==================== ПУЛЯ ИГРОКА (Болтер) ====================
class Bullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final bool isPlayer;
  final double speed = 480;

  Bullet({required super.position, required this.direction, this.isPlayer = true})
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
        // Пули не работают по щитовикам
        removeFromParent();
        return;
      }
      other.removeFromParent();
      game.onEnemyKilled();
      removeFromParent();
    }
  }
}

// ==================== БЛИЖНЯЯ АТАКА (Меч) ====================
class MeleeAttack extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  double life = 0.18;

  MeleeAttack({required super.position, required this.direction})
      : super(radius: 28, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFAAAAAA).withOpacity(0.7));

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

// ==================== ВРАГ ====================
class Enemy extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  final EnemyType type;
  late final double speed;
  double shootTimer = 0;
  final double shootInterval = 1.8;

  Enemy({required this.floor, required this.type}) : super(radius: 17, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Цвета по типу
    switch (type) {
      case EnemyType.shooter:
        paint = Paint()..color = const Color(0xFF1A3A1A); // тёмно-зелёный
        speed = 55 + floor * 8.0;
        break;
      case EnemyType.melee:
        paint = Paint()..color = const Color(0xFF3A3A1A); // тёмно-жёлтый/оливковый
        speed = 90 + floor * 12.0;
        break;
      case EnemyType.shielded:
        paint = Paint()..color = const Color(0xFF1A1A3A); // тёмно-синий
        speed = 45 + floor * 6.0;
        radius = 20;
        break;
    }

    final side = Random().nextInt(4);
    switch (side) {
      case 0: position = Vector2(Random().nextDouble() * game.size.x, -30); break;
      case 1: position = Vector2(Random().nextDouble() * game.size.x, game.size.y + 30); break;
      case 2: position = Vector2(-30, Random().nextDouble() * game.size.y); break;
      case 3: position = Vector2(game.size.x + 30, Random().nextDouble() * game.size.y); break;
    }

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * speed * dt);

    // Стрелки только у стрелков
    if (type == EnemyType.shooter) {
      shootTimer += dt;
      if (shootTimer >= shootInterval) {
        shootTimer = 0;
        game.world.add(EnemyBullet(
          position: position.clone(),
          direction: toPlayer,
        ));
      }
    }
  }
}

// ==================== СТРЕЛА ВРАГА (медленная) ====================
class EnemyBullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 160; // медленная, можно увернуться

  EnemyBullet({required super.position, required this.direction})
      : super(radius: 8, anchor: Anchor.center, paint: Paint()..color = const Color(0xFF88FF88));

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
