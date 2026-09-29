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
  late HudButtonComponent settingsButton;
  late HudButtonComponent zoomInButton;
  late HudButtonComponent zoomOutButton;

  int score = 0;
  bool isPlaying = false;
  bool isPaused = false;

  int currentFloor = 1;
  int currentLevel = 1;
  int enemiesAlive = 0;
  int enemiesToSpawn = 0;
  int enemiesSpawned = 0;

  bool portalSpawned = false;
  bool isBossLevel = false;

  // Улучшения
  int bolterDamage = 8;
  int swordDamage = 15;
  int maxHealth = 6;
  double playerSpeed = 210;
  double defenseChance = 0.0;

  double joystickSize = 80;
  double buttonSize = 42;
  double currentZoom = 1.0;

  final double mapWidth = 900;
  final double mapHeight = 1600;

  final TextPaint hudPaint = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
  );

  // Точки спавна врагов (внутри карты)
  final List<Vector2> enemySpawnPoints = [
    Vector2(180, 280),
    Vector2(720, 280),
    Vector2(180, 800),
    Vector2(720, 800),
    Vector2(450, 450),
    Vector2(300, 1200),
    Vector2(600, 1200),
  ];

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2(mapWidth, mapHeight);
    camera.viewfinder.zoom = currentZoom;
  }

  void startGame() {
    isPlaying = true;
    isPaused = false;
    score = 0;
    currentFloor = 1;
    currentLevel = 1;
    portalSpawned = false;
    isBossLevel = false;

    bolterDamage = 8;
    swordDamage = 15;
    maxHealth = 6;
    playerSpeed = 210;
    defenseChance = 0.0;
    currentZoom = 1.0;

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

    // Пол
    world.add(Floor(size: Vector2(mapWidth, mapHeight))..priority = 0);

    // Стены и преграды
    _createWalls();
    _createObstacles();

    // Точки спавна врагов (оранжевые мерцающие)
    for (final pos in enemySpawnPoints) {
      world.add(EnemySpawnPortal(position: pos)..priority = 3);
    }

    // Точка спавна игрока (фиолетовая)
    world.add(PlayerSpawnPoint(position: Vector2(mapWidth / 2, mapHeight / 2 + 280))..priority = 3);

    // === УПРАВЛЕНИЕ ===
    final knobPaint = Paint()..color = const Color(0xFF8B0000);
    final bgPaint = Paint()..color = const Color(0xFF2F2F2F).withOpacity(0.75);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.38, paint: knobPaint),
      background: CircleComponent(radius: joystickSize, paint: bgPaint),
      margin: const EdgeInsets.only(left: 28, bottom: 35),
    );

    shootButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize, paint: Paint()..color = const Color(0xFF8B0000).withOpacity(0.9)),
      buttonDown: CircleComponent(radius: buttonSize, paint: Paint()..color = const Color(0xFF8B0000)),
      margin: const EdgeInsets.only(right: 32, bottom: 45),
      onPressed: () { if (isPlaying && !isPaused) player.isAttacking = true; },
      onReleased: () { if (isPlaying) player.isAttacking = false; },
      onCancelled: () { if (isPlaying) player.isAttacking = false; },
    );

    switchWeaponButton = HudButtonComponent(
      button: CircleComponent(radius: 30, paint: Paint()..color = Colors.grey[800]!),
      buttonDown: CircleComponent(radius: 30, paint: Paint()..color = Colors.grey),
      margin: const EdgeInsets.only(right: 32, bottom: 140),
      onPressed: () { if (isPlaying && !isPaused) player.switchWeapon(); },
    );

    // Кнопка настроек в бою
    settingsButton = HudButtonComponent(
      button: CircleComponent(radius: 26, paint: Paint()..color = const Color(0xFF37474F)),
      buttonDown: CircleComponent(radius: 26, paint: Paint()..color = Colors.blueGrey),
      margin: const EdgeInsets.only(right: 32, top: 90),
      onPressed: () {
        if (isPlaying) {
          isPaused = true;
          overlays.add('settings');
        }
      },
    );

    // Зум +
    zoomInButton = HudButtonComponent(
      button: CircleComponent(radius: 24, paint: Paint()..color = const Color(0xFF455A64)),
      buttonDown: CircleComponent(radius: 24, paint: Paint()..color = Colors.blueGrey[400]!),
      margin: const EdgeInsets.only(left: 28, top: 90),
      onPressed: () {
        currentZoom = (currentZoom + 0.15).clamp(0.7, 1.8);
        camera.viewfinder.zoom = currentZoom;
      },
    );

    // Зум –
    zoomOutButton = HudButtonComponent(
      button: CircleComponent(radius: 24, paint: Paint()..color = const Color(0xFF455A64)),
      buttonDown: CircleComponent(radius: 24, paint: Paint()..color = Colors.blueGrey[400]!),
      margin: const EdgeInsets.only(left: 28, top: 150),
      onPressed: () {
        currentZoom = (currentZoom - 0.15).clamp(0.7, 1.8);
        camera.viewfinder.zoom = currentZoom;
      },
    );

    player = Player(joystick);
    world.add(player);
    camera.viewport.add(joystick);
    camera.viewport.add(shootButton);
    camera.viewport.add(switchWeaponButton);
    camera.viewport.add(settingsButton);
    camera.viewport.add(zoomInButton);
    camera.viewport.add(zoomOutButton);
    camera.follow(player);
    camera.viewfinder.zoom = currentZoom;

    if (isBossLevel) {
      enemiesToSpawn = 1;
      enemiesAlive = 1;
      enemiesSpawned = 1;
      world.add(Boss(floor: currentFloor, position: Vector2(mapWidth / 2, mapHeight / 2 - 180))..priority = 12);
    } else {
      enemiesToSpawn = 6 + (currentLevel * 2) + (currentFloor * 3);
      _spawnWave();
    }
  }

  void _createWalls() {
    const t = 42.0;
    final brown = const Color(0xFF5D4037);

    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, t), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(0, mapHeight - t), size: Vector2(mapWidth, t), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(0, 0), size: Vector2(t, mapHeight), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(mapWidth - t, 0), size: Vector2(t, mapHeight), color: brown)..priority = 5);

    world.add(Wall(position: Vector2(220, 320), size: Vector2(160, 28), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(520, 680), size: Vector2(28, 200), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(260, 1080), size: Vector2(240, 28), color: brown)..priority = 5);
  }

  void _createObstacles() {
    final positions = [Vector2(160, 520), Vector2(710, 420), Vector2(420, 920), Vector2(620, 1320), Vector2(190, 1380)];
    for (final pos in positions) {
      world.add(Obstacle(position: pos)..priority = 5);
    }
  }

  void _spawnWave() {
    final spawnPeriod = max(0.45, 1.5 - (currentFloor * 0.12) - (currentLevel * 0.07));

    add(SpawnComponent(
      factory: (index) {
        if (enemiesSpawned >= enemiesToSpawn) return PositionComponent();
        enemiesSpawned++;
        enemiesAlive++;

        // Выбираем точку спавна внутри карты
        final spawnPos = enemySpawnPoints[Random().nextInt(enemySpawnPoints.length)];

        EnemyType type;
        final roll = Random().nextDouble();
        if (currentFloor == 1) {
          type = roll < 0.55 ? EnemyType.melee : EnemyType.shooter;
        } else if (currentFloor <= 3) {
          type = roll < 0.35 ? EnemyType.melee : (roll < 0.7 ? EnemyType.shooter : EnemyType.shielded);
        } else {
          type = roll < 0.3 ? EnemyType.melee : (roll < 0.6 ? EnemyType.shooter : EnemyType.shielded);
        }

        final enemy = Enemy(floor: currentFloor, type: type)..priority = 11;
        enemy.position = spawnPos.clone();
        return enemy;
      },
      period: spawnPeriod,
      selfPositioning: true,
    ));
  }

  void onEnemyKilled() {
    enemiesAlive = max(0, enemiesAlive - 1);
    score += isBossLevel ? 180 + (currentFloor * 60) : 12 + (currentFloor * 6);

    if (enemiesAlive <= 0 && !portalSpawned) {
      portalSpawned = true;
      world.add(Portal(position: Vector2(mapWidth / 2, mapHeight / 2))..priority = 9);
    }
  }

  void goToNextLevel() {
    isPlaying = false;
    if (currentFloor == 5 && currentLevel == 5) {
      overlays.add('victory');
      return;
    }
    if (currentLevel == 5) {
      overlays.add('upgrade');
      return;
    }
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
      case 'bolter': bolterDamage += 5; break;
      case 'sword': swordDamage += 7; break;
      case 'health': maxHealth += 2; break;
      case 'speed': playerSpeed += 28; break;
      case 'defense': defenseChance = min(0.45, defenseChance + 0.13); break;
    }
    currentFloor++;
    currentLevel = 1;
    overlays.remove('upgrade');
    overlays.add('levelComplete');
  }

  void nextLevel() {
    overlays.remove('levelComplete');
    _clearEverything();
    isPlaying = true;
    isPaused = false;
    _startLevel();
  }

  void openSettings() {
    overlays.remove('mainMenu');
    overlays.add('settings');
  }

  void closeSettings() {
    overlays.remove('settings');
    isPaused = false;
  }

  void backToMenu() {
    isPlaying = false;
    isPaused = false;
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
      hudPaint.render(canvas, 'Floor $currentFloor | Lvl $currentLevel', Vector2(14, 14));
      hudPaint.render(canvas, 'Score: $score', Vector2(14, 38));
      hudPaint.render(canvas, 'HP: ${player.health}/${player.maxHealth}', Vector2(14, 62));
      hudPaint.render(canvas, isBossLevel ? 'BOSS' : 'Enemies: $enemiesAlive', Vector2(14, 86));
      hudPaint.render(canvas, player.weapon == WeaponType.bolter ? 'BOLTER' : 'SWORD', Vector2(14, 110));
    }
  }
}

// ====================== ТОЧКИ СПАВНА ======================
class EnemySpawnPortal extends PositionComponent {
  double flicker = 0;
  EnemySpawnPortal({required Vector2 position}) : super(position: position, size: Vector2(40, 40), anchor: Anchor.center, priority: 3);

  @override
  void update(double dt) {
    super.update(dt);
    flicker += dt * 4;
  }

  @override
  void render(Canvas canvas) {
    final alpha = 0.4 + 0.4 * sin(flicker);
    final paint = Paint()..color = Color.fromRGBO(255, 140, 0, alpha);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 16, paint);
    final inner = Paint()..color = Color.fromRGBO(255, 200, 50, alpha * 0.8);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 8, inner);
  }
}

class PlayerSpawnPoint extends PositionComponent {
  PlayerSpawnPoint({required Vector2 position}) : super(position: position, size: Vector2(50, 50), anchor: Anchor.center, priority: 3);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF9C27B0).withOpacity(0.7);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 20, paint);
    final inner = Paint()..color = const Color(0xFFE040FB).withOpacity(0.9);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 10, inner);
  }
}

// ====================== ПОЛ / СТЕНЫ / ПРЕГРАДЫ / ПОРТАЛ ======================
class Floor extends PositionComponent {
  Floor({required Vector2 size}) : super(size: size, position: Vector2.zero(), priority: 0);
  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFB0BEC5);
    canvas.drawRect(size.toRect(), paint);
    final grid = Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
    }
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  final Color color;
  Wall({required Vector2 position, required Vector2 size, required this.color}) : super(position: position, size: size, priority: 5);
  @override
  Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = color);
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.stroke..strokeWidth = 3);
  }
}

class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({required Vector2 position}) : super(position: position, size: Vector2(48, 48), anchor: Anchor.center, priority: 5);
  @override
  Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(5)), Paint()..color = const Color(0xFF6D4C41));
  }
}

class Portal extends PositionComponent with CollisionCallbacks {
  Portal({required Vector2 position}) : super(position: position, size: Vector2(75, 75), anchor: Anchor.center, priority: 9);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void render(Canvas canvas) {
    final c = size / 2;
    canvas.drawCircle(c.toOffset(), 34, Paint()..color = const Color(0xFFE91E63).withOpacity(0.85));
    canvas.drawCircle(c.toOffset(), 20, Paint()..color = const Color(0xFFF48FB1));
    canvas.drawCircle(c.toOffset(), 9, Paint()..color = Colors.white.withOpacity(0.8));
  }
}

// ====================== МЕНЮ ======================
class MainMenu extends StatelessWidget {
  final InquisitorGame game;
  const MainMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.88),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent, width: 3.5),
                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.45), blurRadius: 20, spreadRadius: 2)],
              ),
              child: const Center(child: Text('SI', style: TextStyle(color: Colors.redAccent, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 3))),
            ),
            const SizedBox(height: 26),
            const Text('Soul of the Inquisitor', style: TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('From the Inquisitor\'s perspective', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 5),
            const Text('by Инквизитор Данте', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16)),
              onPressed: () => game.startGame(),
              child: const Text('PLAY', style: TextStyle(fontSize: 22, color: Colors.white)),
            ),
            const SizedBox(height: 18),
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
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Text('Joystick size: ${widget.game.joystickSize.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 17)),
              Slider(value: widget.game.joystickSize, min: 55, max: 120, divisions: 13, activeColor: Colors.blue, onChanged: (v) => setState(() => widget.game.joystickSize = v)),
              const SizedBox(height: 18),
              Text('Button size: ${widget.game.buttonSize.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 17)),
              Slider(value: widget.game.buttonSize, min: 28, max: 65, divisions: 8, activeColor: Colors.red, onChanged: (v) => setState(() => widget.game.buttonSize = v)),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
                  onPressed: () {
                    if (widget.game.isPlaying) {
                      widget.game.closeSettings();
                    } else {
                      widget.game.backToMenu();
                    }
                  },
                  child: Text(widget.game.isPlaying ? 'Back to Battle' : 'Back', style: const TextStyle(fontSize: 18, color: Colors.white)),
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
            Text('Floor ${game.currentFloor}  •  Level ${game.currentLevel}', style: const TextStyle(color: Colors.white70, fontSize: 17)),
            Text('Score: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 45),
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

class UpgradeMenu extends StatelessWidget {
  final InquisitorGame game;
  const UpgradeMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text('УЛУЧШЕНИЕ ИНКВИЗИТОРА', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Этаж ${game.currentFloor} пройден. Выберите улучшение:', style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _btn('Урон болтера (+5)', 'bolter', Colors.orange),
                    _btn('Урон меча (+7)', 'sword', Colors.redAccent),
                    _btn('Здоровье (+2)', 'health', Colors.green),
                    _btn('Скорость (+28)', 'speed', Colors.lightBlue),
                    _btn('Защита (+13% блок)', 'defense', Colors.purpleAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String title, String type, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.85), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: () => game.applyUpgrade(type),
        child: Text(title, style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
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
            const Text('ВЫ ПРОШЛИ ИСПЫТАНИЕ\nИНКВИЗИТОРА', style: TextStyle(color: Colors.amber, fontSize: 26, fontWeight: FontWeight.bold, height: 1.3), textAlign: TextAlign.center),
            const SizedBox(height: 22),
            Text('Финальный счёт: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 21)),
            const SizedBox(height: 45),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              onPressed: () => game.backToMenu(),
              child: const Text('В ГЛАВНОЕ МЕНЮ', style: TextStyle(fontSize: 17, color: Colors.white)),
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
            const Text('THE INQUISITOR HAS FALLEN', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Text('Score: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 22)),
            Text('Floor ${game.currentFloor}  •  Level ${game.currentLevel}', style: const TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 45),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: () => game.startGame(),
              child: const Text('TRY AGAIN', style: TextStyle(fontSize: 19, color: Colors.white)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 13)),
              onPressed: () => game.backToMenu(),
              child: const Text('Main Menu', style: TextStyle(fontSize: 17, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== ИГРОК (более детальный) ======================
class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  late int health;
  late int maxHealth;
  bool isAttacking = false;
  double attackTimer = 0;
  WeaponType weapon = WeaponType.bolter;

  Player(this.joystick) : super(size: Vector2(58, 64), anchor: Anchor.center, priority: 15);

  @override
  Future<void> onLoad() async {
    maxHealth = game.maxHealth;
    health = maxHealth;
    position = Vector2(game.mapWidth / 2, game.mapHeight / 2 + 280);
    add(CircleHitbox(radius: 22));
  }

  void switchWeapon() => weapon = weapon == WeaponType.bolter ? WeaponType.sword : WeaponType.bolter;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;

    if (joystick.direction != JoystickDirection.idle) {
      position.add(joystick.relativeDelta * game.playerSpeed * dt);
      angle = joystick.delta.screenAngle();
    }
    position.x = position.x.clamp(55, game.mapWidth - 55);
    position.y = position.y.clamp(55, game.mapHeight - 55);

    if (isAttacking) {
      attackTimer += dt;
      if (attackTimer >= (weapon == WeaponType.bolter ? 0.30 : 0.42)) {
        attackTimer = 0;
        _doAttack();
      }
    }
  }

  void _doAttack() {
    final dir = joystick.relativeDelta.normalized();
    final attackDir = dir == Vector2.zero() ? Vector2(0, -1) : dir;
    if (weapon == WeaponType.bolter) {
      game.world.add(Bullet(position: position.clone(), direction: attackDir)..priority = 13);
    } else {
      game.world.add(MeleeAttack(position: position + attackDir * 36, direction: attackDir)..priority = 13);
    }
  }

  void takeDamage(int amount) {
    if (Random().nextDouble() < game.defenseChance) return;
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

    // Плащ
    final cape = Path()
      ..moveTo(cx - 20, cy + 6)
      ..quadraticBezierTo(cx - 32, cy + 28, cx - 10, cy + 34)
      ..lineTo(cx + 10, cy + 34)
      ..quadraticBezierTo(cx + 32, cy + 28, cx + 20, cy + 6)
      ..close();
    canvas.drawPath(cape, Paint()..color = const Color(0xFF6B0000).withOpacity(0.75));

    // Торс (броня)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 30, height: 28), const Radius.circular(6)), Paint()..color = const Color(0xFF1C1C1C));
    // Плечи
    canvas.drawCircle(Offset(cx - 16, cy + 3), 8, Paint()..color = const Color(0xFF2A2A2A));
    canvas.drawCircle(Offset(cx + 16, cy + 3), 8, Paint()..color = const Color(0xFF2A2A2A));
    // Голова / шлем
    canvas.drawCircle(Offset(cx, cy - 14), 12, Paint()..color = const Color(0xFF111111));
    // Визор
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 15), width: 16, height: 5), const Radius.circular(2)), Paint()..color = const Color(0xFFB22222));
    // Символ Инквизиции
    canvas.drawCircle(Offset(cx, cy + 5), 4.5, Paint()..color = const Color(0xFF8B0000));

    // Оружие
    if (weapon == WeaponType.bolter) {
      // Болтер
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 10, cy - 6, 22, 8), const Radius.circular(2)), Paint()..color = const Color(0xFF37474F));
      canvas.drawRect(Rect.fromLTWH(cx + 28, cy - 4, 8, 4), Paint()..color = const Color(0xFF263238));
    } else {
      // Меч
      canvas.drawLine(Offset(cx + 12, cy - 8), Offset(cx + 28, cy - 22), Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 3.5..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(cx + 12, cy - 6), 3, Paint()..color = const Color(0xFF5D4037));
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!game.isPlaying || game.isPaused) return;

    if (other is Wall || other is Obstacle) {
      position -= (intersectionPoints.first - position).normalized() * 5;
    }
    if (other is Enemy || other is EnemyBullet || other is BossProjectile) {
      takeDamage(1);
      other.removeFromParent();
      if (other is Enemy) game.onEnemyKilled();
    }
    if (other is Boss) takeDamage(1);
    if (other is Portal && weapon == WeaponType.sword) game.goToNextLevel();
  }
}

// ====================== ВРАГИ (детальные) ======================
class Enemy extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  final EnemyType type;
  late final double speed;
  double shootTimer = 0;

  Enemy({required this.floor, required this.type}) : super(size: Vector2(50, 56), anchor: Anchor.center, priority: 11);

  @override
  Future<void> onLoad() async {
    switch (type) {
      case EnemyType.shooter: speed = 52 + floor * 6.0; break;
      case EnemyType.melee: speed = 82 + floor * 9.5; break;
      case EnemyType.shielded: speed = 40 + floor * 4.5; size = Vector2(54, 58); break;
    }
    add(CircleHitbox(radius: type == EnemyType.shielded ? 23 : 19));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;

    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * speed * dt);
    angle = toPlayer.screenAngle();
    position.x = position.x.clamp(60, game.mapWidth - 60);
    position.y = position.y.clamp(60, game.mapHeight - 60);

    if (type == EnemyType.shooter) {
      shootTimer += dt;
      if (shootTimer >= 1.85) {
        shootTimer = 0;
        game.world.add(EnemyBullet(position: position.clone(), direction: toPlayer)..priority = 13);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position -= (intersectionPoints.first - position).normalized() * 7;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Торс
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 6), width: 26, height: 26), const Radius.circular(5)), Paint()..color = const Color(0xFF2A2A2A));
    // Плечи
    canvas.drawCircle(Offset(cx - 13, cy + 2), 7, Paint()..color = const Color(0xFF3A3A3A));
    canvas.drawCircle(Offset(cx + 13, cy + 2), 7, Paint()..color = const Color(0xFF3A3A3A));
    // Голова
    canvas.drawCircle(Offset(cx, cy - 14), 11, Paint()..color = const Color(0xFF1F1F1F));

    switch (type) {
      case EnemyType.shooter:
        canvas.drawCircle(Offset(cx, cy - 15), 4.5, Paint()..color = const Color(0xFF2E8B57));
        canvas.drawLine(Offset(cx + 8, cy - 2), Offset(cx + 22, cy - 10), Paint()..color = const Color(0xFF1B5E20)..strokeWidth = 4..strokeCap = StrokeCap.round);
        break;
      case EnemyType.melee:
        canvas.drawCircle(Offset(cx, cy - 15), 4.5, Paint()..color = const Color(0xFFDAA520));
        canvas.drawLine(Offset(cx + 9, cy - 5), Offset(cx + 22, cy - 18), Paint()..color = const Color(0xFFFFC107)..strokeWidth = 3.5..strokeCap = StrokeCap.round);
        break;
      case EnemyType.shielded:
        canvas.drawCircle(Offset(cx, cy - 15), 4.5, Paint()..color = const Color(0xFF1E90FF));
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy + 3), radius: 24), -1.15, 2.3, false, Paint()..color = const Color(0xFF4169E1).withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 5);
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

  Boss({required this.floor, required Vector2 position}) : super(position: position, size: Vector2(95, 105), anchor: Anchor.center, priority: 12);

  @override
  Future<void> onLoad() async {
    maxHp = 90 + (floor * 45);
    currentHp = maxHp;
    add(CircleHitbox(radius: 42));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * (38 + floor * 5.0) * dt);
    angle = toPlayer.screenAngle();
    position.x = position.x.clamp(75, game.mapWidth - 75);
    position.y = position.y.clamp(75, game.mapHeight - 75);

    attackTimer += dt;
    if (attackTimer >= 2.1) {
      attackTimer = 0;
      for (int i = 0; i < 8; i++) {
        final a = (i / 8) * 2 * pi;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 13);
      }
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
      position -= (intersectionPoints.first - position).normalized() * 7;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 10), width: 64, height: 58), const Radius.circular(10)), Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(Offset(cx - 30, cy + 3), 15, Paint()..color = const Color(0xFF333333));
    canvas.drawCircle(Offset(cx + 30, cy + 3), 15, Paint()..color = const Color(0xFF333333));
    canvas.drawCircle(Offset(cx, cy - 24), 19, Paint()..color = const Color(0xFF0D0D0D));
    canvas.drawCircle(Offset(cx - 8, cy - 26), 4.5, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(cx + 8, cy - 26), 4.5, Paint()..color = const Color(0xFFFF1744));

    // HP bar
    final barW = 84.0;
    final hpP = currentHp / maxHp;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -28, barW, 11), const Radius.circular(4)), Paint()..color = Colors.black.withOpacity(0.75));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -28, barW * hpP, 11), const Radius.circular(4)), Paint()..color = hpP > 0.3 ? const Color(0xFFE53935) : const Color(0xFFFF1744));
  }
}

class BossProjectile extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  BossProjectile({required super.position, required this.direction}) : super(radius: 11, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFF1744), priority: 13);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * 175 * dt);
    if (position.x < -60 || position.x > game.mapWidth + 60 || position.y < -60 || position.y > game.mapHeight + 60) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) removeFromParent();
  }
}

// ====================== АТАКИ ======================
class Bullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  Bullet({required super.position, required this.direction}) : super(radius: 7, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFFD700), priority: 13);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * 500 * dt);
    if (position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) removeFromParent();
    if (other is Enemy) {
      if (other.type == EnemyType.shielded) { removeFromParent(); return; }
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
  double life = 0.17;
  MeleeAttack({required super.position, required this.direction}) : super(radius: 34, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFB0BEC5).withOpacity(0.55), priority: 13);
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
    if (other is Enemy) { other.removeFromParent(); game.onEnemyKilled(); }
    if (other is Obstacle) other.removeFromParent();
    if (other is Boss) other.takeDamage(game.swordDamage);
    if (other is Portal) game.goToNextLevel();
  }
}

class EnemyBullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  EnemyBullet({required super.position, required this.direction}) : super(radius: 8, anchor: Anchor.center, paint: Paint()..color = const Color(0xFF76FF03), priority: 13);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * 150 * dt);
    if (position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) removeFromParent();
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) removeFromParent();
  }
}
