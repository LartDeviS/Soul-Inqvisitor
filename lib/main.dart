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

  bool portalSpawned = false;
  bool isBossLevel = false;

  double joystickSize = 75;
  double buttonSize = 40;

  final double mapWidth = 900;
  final double mapHeight = 1600;

  final TextPaint hudPaint = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
  );

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2(mapWidth, mapHeight);
  }

  void startGame() {
    isPlaying = true;
    score = 0;
    currentFloor = 1;
    currentLevel = 1;
    portalSpawned = false;
    isBossLevel = false;
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
    portalSpawned = false;
    isBossLevel = (currentLevel == 5);

    // Пол
    world.add(Floor(size: Vector2(mapWidth, mapHeight)));

    // Стены
    _createWalls();

    // Преграды
    _createObstacles();

    // Управление
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
    camera.follow(player);

    if (isBossLevel) {
      // Босс вместо обычных врагов
      enemiesToSpawn = 1;
      enemiesAlive = 1;
      enemiesSpawned = 1;
      world.add(Boss(floor: currentFloor, position: Vector2(mapWidth / 2, mapHeight / 2 - 200)));
    } else {
      enemiesToSpawn = 5 + (currentLevel * 2) + (currentFloor * 3);
      _spawnWave();
    }
  }

  void _createWalls() {
    const thickness = 40.0;
    final brown = const Color(0xFF5D4037);

    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, thickness), color: brown));
    world.add(Wall(position: Vector2(0, mapHeight - thickness), size: Vector2(mapWidth, thickness), color: brown));
    world.add(Wall(position: Vector2(0, 0), size: Vector2(thickness, mapHeight), color: brown));
    world.add(Wall(position: Vector2(mapWidth - thickness, 0), size: Vector2(thickness, mapHeight), color: brown));

    world.add(Wall(position: Vector2(200, 300), size: Vector2(180, 30), color: brown));
    world.add(Wall(position: Vector2(500, 700), size: Vector2(30, 220), color: brown));
    world.add(Wall(position: Vector2(250, 1100), size: Vector2(250, 30), color: brown));
  }

  void _createObstacles() {
    final positions = [
      Vector2(150, 500),
      Vector2(700, 400),
      Vector2(400, 900),
      Vector2(600, 1300),
      Vector2(180, 1400),
    ];
    for (final pos in positions) {
      world.add(Obstacle(position: pos));
    }
  }

  void _spawnWave() {
    final spawnPeriod = max(0.4, 1.6 - (currentFloor * 0.15) - (currentLevel * 0.08));

    add(SpawnComponent(
      factory: (index) {
        if (enemiesSpawned >= enemiesToSpawn) return PositionComponent();
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
    score += isBossLevel ? 150 + (currentFloor * 50) : 10 + (currentFloor * 5);

    if (enemiesAlive <= 0 && !portalSpawned) {
      portalSpawned = true;
      world.add(Portal(position: Vector2(mapWidth / 2, mapHeight / 2)));
    }
  }

  void goToNextLevel() {
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
      hudPaint.render(canvas, isBossLevel ? 'BOSS FIGHT' : 'Enemies: $enemiesAlive', Vector2(16, 94));
      hudPaint.render(canvas, 'Weapon: ${player.weapon == WeaponType.bolter ? "BOLTER" : "SWORD"}', Vector2(16, 120));
    }
  }
}

// ====================== БОСС ======================
class Boss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;
  final double attackInterval = 2.2;
  double moveTimer = 0;

  Boss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(90, 100), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    maxHp = 80 + (floor * 40);
    currentHp = maxHp;
    add(CircleHitbox(radius: 40));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    // Медленное преследование
    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * (35 + floor * 5.0) * dt);
    angle = toPlayer.screenAngle();

    // Массовая атака
    attackTimer += dt;
    if (attackTimer >= attackInterval) {
      attackTimer = 0;
      _massAttack();
    }
  }

  void _massAttack() {
    // 8 направлений
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final dir = Vector2(cos(angle), sin(angle));
      game.world.add(BossProjectile(
        position: position.clone(),
        direction: dir,
      ));
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    if (currentHp <= 0) {
      currentHp = 0;
      removeFromParent();
      game.onEnemyKilled();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      final overlap = intersectionPoints.first - position;
      position -= overlap.normalized() * 5;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Большой тёмный корпус
    final body = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 60, height: 55), const Radius.circular(10)),
      body,
    );

    // Плечи
    final shoulder = Paint()..color = const Color(0xFF333333);
    canvas.drawCircle(Offset(cx - 28, cy + 2), 14, shoulder);
    canvas.drawCircle(Offset(cx + 28, cy + 2), 14, shoulder);

    // Голова
    final head = Paint()..color = const Color(0xFF0D0D0D);
    canvas.drawCircle(Offset(cx, cy - 22), 18, head);

    // Красные глаза
    final eye = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(cx - 7, cy - 24), 4, eye);
    canvas.drawCircle(Offset(cx + 7, cy - 24), 4, eye);

    // === ПОЛОСКА HP ===
    final barWidth = 80.0;
    final barHeight = 10.0;
    final hpPercent = currentHp / maxHp;

    // Фон полоски
    final bgBar = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - barWidth / 2, -25, barWidth, barHeight), const Radius.circular(4)),
      bgBar,
    );

    // HP
    final hpBar = Paint()..color = hpPercent > 0.3 ? const Color(0xFFE53935) : const Color(0xFFFF1744);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - barWidth / 2, -25, barWidth * hpPercent, barHeight), const Radius.circular(4)),
      hpBar,
    );
  }
}

// Снаряд босса
class BossProjectile extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 180;

  BossProjectile({required super.position, required this.direction})
      : super(radius: 10, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFF1744));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * speed * dt);
    if (position.x < -50 || position.x > game.mapWidth + 50 || position.y < -50 || position.y > game.mapHeight + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      removeFromParent();
    }
  }
}

// ====================== ОСТАЛЬНЫЕ КЛАССЫ (пол, стены, преграды, портал, меню, игрок, враги, пули) ======================

class Floor extends PositionComponent {
  Floor({required Vector2 size}) : super(size: size, position: Vector2.zero());

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFBDBDBD);
    canvas.drawRect(size.toRect(), paint);
    final gridPaint = Paint()..color = const Color(0xFF9E9E9E)..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  final Color color;
  Wall({required Vector2 position, required Vector2 size, required this.color}) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(size.toRect(), paint);
    final border = Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawRect(size.toRect(), border);
  }
}

class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({required Vector2 position}) : super(position: position, size: Vector2(50, 50), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF795548);
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)), paint);
  }
}

class Portal extends PositionComponent with CollisionCallbacks {
  Portal({required Vector2 position}) : super(position: position, size: Vector2(70, 70), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final center = size / 2;
    final paint = Paint()..color = const Color(0xFFE91E63).withOpacity(0.8);
    canvas.drawCircle(center.toOffset(), 32, paint);
    final inner = Paint()..color = const Color(0xFFF48FB1);
    canvas.drawCircle(center.toOffset(), 18, inner);
    final core = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(center.toOffset(), 8, core);
  }
}

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
            const Text('Soul of the Inquisitor', style: TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
              Slider(value: widget.game.joystickSize, min: 50, max: 120, divisions: 14, activeColor: Colors.blue, onChanged: (v) => setState(() => widget.game.joystickSize = v)),
              const SizedBox(height: 30),
              Text('Button size: ${widget.game.buttonSize.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18)),
              Slider(value: widget.game.buttonSize, min: 25, max: 70, divisions: 9, activeColor: Colors.red, onChanged: (v) => setState(() => widget.game.buttonSize = v)),
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

class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  double speed = 210;
  int health = 6;
  bool isAttacking = false;
  double attackTimer = 0;
  WeaponType weapon = WeaponType.bolter;

  Player(this.joystick) : super(size: 
