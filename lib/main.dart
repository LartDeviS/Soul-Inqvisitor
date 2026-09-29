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
          'upgrade': (context, game) => UpgradeMenu(game as InquisitorGame),
          'victory': (context, game) => VictoryMenu(game as InquisitorGame),
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

  // Улучшения игрока
  int bolterDamage = 8;
  int swordDamage = 15;
  int maxHealth = 6;
  double playerSpeed = 210;
  double defenseChance = 0.0; // 0.0 – 0.4

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

    // Сброс улучшений
    bolterDamage = 8;
    swordDamage = 15;
    maxHealth = 6;
    playerSpeed = 210;
    defenseChance = 0.0;

    _clearEverything();
    _startLevel();
    overlays.remove('mainMenu');
    overlays.remove('settings');
    overlays.remove('gameOver');
    overlays.remove('levelComplete');
    overlays.remove('upgrade');
    overlays.remove('victory');
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

    // Пол (самый нижний слой)
    world.add(Floor(size: Vector2(mapWidth, mapHeight))..priority = 0);

    // Стены и преграды
    _createWalls();
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
      enemiesToSpawn = 1;
      enemiesAlive = 1;
      enemiesSpawned = 1;
      world.add(Boss(floor: currentFloor, position: Vector2(mapWidth / 2, mapHeight / 2 - 200))..priority = 10);
    } else {
      enemiesToSpawn = 5 + (currentLevel * 2) + (currentFloor * 3);
      _spawnWave();
    }
  }

  void _createWalls() {
    const thickness = 40.0;
    final brown = const Color(0xFF5D4037);

    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, thickness), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(0, mapHeight - thickness), size: Vector2(mapWidth, thickness), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(0, 0), size: Vector2(thickness, mapHeight), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(mapWidth - thickness, 0), size: Vector2(thickness, mapHeight), color: brown)..priority = 5);

    world.add(Wall(position: Vector2(200, 300), size: Vector2(180, 30), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(500, 700), size: Vector2(30, 220), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(250, 1100), size: Vector2(250, 30), color: brown)..priority = 5);
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
      world.add(Obstacle(position: pos)..priority = 5);
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
        return Enemy(floor: currentFloor, type: type)..priority = 10;
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
      world.add(Portal(position: Vector2(mapWidth / 2, mapHeight / 2))..priority = 8);
    }
  }

  void goToNextLevel() {
    isPlaying = false;

    // Победа на 25 уровне
    if (currentFloor == 5 && currentLevel == 5) {
      overlays.add('victory');
      return;
    }

    // После босса (уровень 5) — меню улучшений
    if (currentLevel == 5) {
      overlays.add('upgrade');
      return;
    }

    // Обычный переход
    if (currentLevel >= 5) {
      currentFloor++;
      currentLevel = 1;
    } else {
      currentLevel++;
    }
    overlays.add('levelComplete');
  }

  void applyUpgrade(String type) {
    switch (type) {
      case 'bolter':
        bolterDamage += 4;
        break;
      case 'sword':
        swordDamage += 6;
        break;
      case 'health':
        maxHealth += 2;
        break;
      case 'speed':
        playerSpeed += 25;
        break;
      case 'defense':
        defenseChance = min(0.4, defenseChance + 0.12);
        break;
    }

    // Переходим на следующий этаж
    currentFloor++;
    currentLevel = 1;
    overlays.remove('upgrade');
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
    overlays.remove('upgrade');
    overlays.remove('victory');
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
      hudPaint.render(canvas, 'HP: ${player.health}/${player.maxHealth}', Vector2(16, 68));
      hudPaint.render(canvas, isBossLevel ? 'BOSS FIGHT' : 'Enemies: $enemiesAlive', Vector2(16, 94));
      hudPaint.render(canvas, 'Weapon: ${player.weapon == WeaponType.bolter ? "BOLTER" : "SWORD"}', Vector2(16, 120));
    }
  }
}

// ====================== УЛУЧШЕНИЯ ======================
class UpgradeMenu extends StatelessWidget {
  final InquisitorGame game;
  const UpgradeMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'УЛУЧШЕНИЕ ИНКВИЗИТОРА',
                style: TextStyle(color: Colors.amber, fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Этаж ${game.currentFloor} пройден. Выберите 1 улучшение:',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: [
                    _upgradeButton('Урон болтера (+4)', 'bolter', Colors.orange),
                    _upgradeButton('Урон меча (+6)', 'sword', Colors.redAccent),
                    _upgradeButton('Здоровье (+2 макс.)', 'health', Colors.green),
                    _upgradeButton('Скорость (+25)', 'speed', Colors.lightBlue),
                    _upgradeButton('Защита (+12% шанс блока)', 'defense', Colors.purpleAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _upgradeButton(String title, String type, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => game.applyUpgrade(type),
        child: Text(title, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ====================== ПОБЕДА ======================
class VictoryMenu extends StatelessWidget {
  final InquisitorGame game;
  const VictoryMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ВЫ ПРОШЛИ ИСПЫТАНИЕ\nИНКВИЗИТОРА',
              style: TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.bold, height: 1.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text('Финальный счёт: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              onPressed: () => game.backToMenu(),
              child: const Text('В ГЛАВНОЕ МЕНЮ', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== ПОЛ / СТЕНЫ / ПРЕГРАДЫ / ПОРТАЛ ======================
class Floor extends PositionComponent {
  Floor({required Vector2 size}) : super(size: size, position: Vector2.zero(), priority: 0);

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
  Wall({required Vector2 position, required Vector2 size, required this.color})
      : super(position: position, size: size, priority: 5);

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
  Obstacle({required Vector2 position})
      : super(position: position, size: Vector2(50, 50), anchor: Anchor.center, priority: 5);

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
  Portal({required Vector2 position})
      : super(position: position, size: Vector2(70, 70), anchor: Anchor.center, priority: 8);

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
            // Большой логотип SI
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SI',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Soul of the Inquisitor',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'From the Inquisitor\'s perspective',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'by Инквизитор Данте',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              ),
              onPressed: () => game.startGame(),
              child: const Text(
                'PLAY',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: () => game.openSettings(),
              child: const Text(
                'Settings',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
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

// ====================== ИГРОК ======================
class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  late int health;
  late int maxHealth;
  bool isAttacking = false;
  double attackTimer = 0;
  WeaponType weapon = WeaponType.bolter;

  Player(this.joystick) : super(size: Vector2(52, 58), anchor: Anchor.center, priority: 15);

  @override
  Future<void> onLoad() async {
    maxHealth = game.maxHealth;
    health = maxHealth;
    position = Vector2(game.mapWidth / 2, game.mapHeight / 2 + 300);
    add(CircleHitbox(radius: 20));
  }

  void switchWeapon() {
    weapon = weapon == WeaponType.bolter ? WeaponType.sword : WeaponType.bolter;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    if (joystick.direction != JoystickDirection.idle) {
      position.add(joystick.relativeDelta * game.playerSpeed * dt);
      angle = joystick.delta.screenAngle();
    }

    // Ограничение карты
    position.x = position.x.clamp(50, game.mapWidth - 50);
    position.y = position.y.clamp(50, game.mapHeight - 50);

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
      game.world.add(Bullet(position: position.clone(), direction: attackDir)..priority = 12);
    } else {
      game.world.add(MeleeAttack(position: position + attackDir * 34, direction: attackDir)..priority = 12);
    }
  }

  void takeDamage(int amount) {
    // Шанс защиты
    if (Random().nextDouble() < game.defenseChance) {
      return; // урон заблокирован
    }
    health -= amount;
    if (health <= 0) {
      health = 0;
      game.showGameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    final cape = Paint()..color = const Color(0xFF6B0000).withOpacity(0.7);
    final capePath = Path()
      ..moveTo(cx - 18, cy + 4)
      ..quadraticBezierTo(cx - 28, cy + 22, cx - 8, cy + 28)
      ..lineTo(cx + 8, cy + 28)
      ..quadraticBezierTo(cx + 28, cy + 22, cx + 18, cy + 4)
      ..close();
    canvas.drawPath(capePath, cape);

    final body = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6), width: 28, height: 26), const Radius.circular(6)), body);

    final shoulder = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawCircle(Offset(cx - 14, cy + 2), 7, shoulder);
    canvas.drawCircle(Offset(cx + 14, cy + 2), 7, shoulder);

    final head = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(Offset(cx, cy - 12), 11, head);

    final visor = Paint()..color = const Color(0xFFB22222);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 13), width: 14, height: 5), const Radius.circular(2)), visor);

    final symbol = Paint()..color = const Color(0xFF8B0000);
    canvas.drawCircle(Offset(cx, cy + 4), 4, symbol);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!game.isPlaying) return;

    if (other is Wall || other is Obstacle) {
      final overlap = intersectionPoints.first - position;
      position -= overlap.normalized() * 4;
    }

    if (other is Enemy || other is EnemyBullet || other is BossProjectile) {
      takeDamage(1);
      other.removeFromParent();
      if (other is Enemy) game.onEnemyKilled();
    }

    if (other is Boss) {
      takeDamage(1);
    }

    if (other is Portal && weapon == WeaponType.sword) {
      game.goToNextLevel();
    }
  }
}

// ====================== ВРАГИ ======================
class Enemy extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  final EnemyType type;
  late final double speed;
  double shootTimer = 0;
  final double shootInterval = 1.9;

  Enemy({required this.floor, required this.type})
      : super(size: Vector2(46, 52), anchor: Anchor.center, priority: 10);

  @override
  Future<void> onLoad() async {
    switch (type) {
      case EnemyType.shooter:
        speed = 48 + floor * 6.5;
        break;
      case EnemyType.melee:
        speed = 80 + floor * 10.0;
        break;
      case EnemyType.shielded:
        speed = 38 + floor * 5.0;
        size = Vector2(52, 56);
        break;
    }

    // Спавн СТРОГО внутри карты
    position = Vector2(
      80 + Random().nextDouble() * (game.mapWidth - 160),
      80 + Random().nextDouble() * (game.mapHeight - 160),
    );

    add(CircleHitbox(radius: type == EnemyType.shielded ? 22 : 18));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * speed * dt);
    angle = toPlayer.screenAngle();

    // Не даём уходить за границы
    position.x = position.x.clamp(60, game.mapWidth - 60);
    position.y = position.y.clamp(60, game.mapHeight - 60);

    if (type == EnemyType.shooter) {
      shootTimer += dt;
      if (shootTimer >= shootInterval) {
        shootTimer = 0;
        game.world.add(EnemyBullet(position: position.clone(), direction: toPlayer)..priority = 12);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      final overlap = intersectionPoints.first - position;
      position -= overlap.normalized() * 6; // сильнее отталкиваем
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
        final shield = Paint()..color = const Color(0xFF4169E1).withOpacity(0.75)..style = PaintingStyle.stroke..strokeWidth = 5;
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy + 2), radius: 23), -1.1, 2.2, false, shield);
        break;
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

  Boss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(90, 100), anchor: Anchor.center, priority: 10);

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

    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * (35 + floor * 5.0) * dt);
    angle = toPlayer.screenAngle();

    position.x = position.x.clamp(70, game.mapWidth - 70);
    position.y = position.y.clamp(70, game.mapHeight - 70);

    attackTimer += dt;
    if (attackTimer >= attackInterval) {
      attackTimer = 0;
      _massAttack();
    }
  }

  void _massAttack() {
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final dir = Vector2(cos(angle), sin(angle));
      game.world.add(BossProjectile(position: position.clone(), direction: dir)..priority = 12);
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
      position -= overlap.normalized() * 6;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    final body = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 60, height: 55), const Radius.circular(10)), body);

    final shoulder = Paint()..color = const Color(0xFF333333);
    canvas.drawCircle(Offset(cx - 28, cy + 2), 14, shoulder);
    canvas.drawCircle(Offset(cx + 28, cy + 2), 14, shoulder);

    final head = Paint()..color = const Color(0xFF0D0D0D);
    canvas.drawCircle(Offset(cx, cy - 22), 18, head);

    final eye = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(cx - 7, cy - 24), 4, eye);
    canvas.drawCircle(Offset(cx + 7, cy - 24), 4, eye);

    // HP bar
    final barWidth = 80.0;
    final barHeight = 10.0;
    final hpPercent = currentHp / maxHp;

    final bgBar = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barWidth / 2, -25, barWidth, barHeight), const Radius.circular(4)), bgBar);

    final hpBar = Paint()..color = hpPercent > 0.3 ? const Color(0xFFE53935) : const Color(0xFFFF1744);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barWidth / 2, -25, barWidth * hpPercent, barHeight), const Radius.circular(4)), hpBar);
  }
}

class BossProjectile extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 180;

  BossProjectile({required super.position, required this.direction})
      : super(radius: 10, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFF1744), priority: 12);

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

// ====================== ПУЛИ И АТАКИ ======================
class Bullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 490;

  Bullet({required super.position, required this.direction})
      : super(radius: 6, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFFD700), priority: 12);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * speed * dt);
    if (position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      removeFromParent();
    }
    if (other is Enemy) {
      if (other.type == EnemyType.shielded) {
        removeFromParent();
        return;
      }
      other.removeFromParent();
      game.onEnemyKilled();
      removeFromParent();
    }
    if (other is Boss) {
      other.takeDamage(game.bolterDamage);
      removeFromParent();
    }
  }
}

class MeleeAttack extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  double life = 0.18;

  MeleeAttack({required super.position, required this.direction})
      : super(radius: 32, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFAAAAAA).withOpacity(0.5), priority: 12);

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
    if (other is Obstacle) {
      other.removeFromParent();
    }
    if (other is Boss) {
      other.takeDamage(game.swordDamage);
    }
    if (other is Portal) {
      game.goToNextLevel();
    }
  }
}

class EnemyBullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 145;

  EnemyBullet({required super.position, required this.direction})
      : super(radius: 7, anchor: Anchor.center, paint: Paint()..color = const Color(0xFF7CFC00), priority: 12);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * speed * dt);
    if (position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) {
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
