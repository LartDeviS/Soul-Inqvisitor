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
          'records': (context, game) => RecordsMenu(game as InquisitorGame),
        },
        initialActiveOverlays: const ['mainMenu'],
      ),
    ),
  );
}

enum WeaponType { bolter, sword }
enum EnemyType { shooter, melee, shielded, dog, shieldedShooter }

class InquisitorGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent moveJoystick;
  late JoystickComponent attackJoystick;
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

  double spawnTimer = 0;
  double spawnInterval = 1.2;

  int bolterDamage = 8;
  int swordDamage = 12;
  int maxHealth = 6;
  double playerSpeed = 210;
  double defenseChance = 0.0;

  double joystickSize = 80;
  double buttonSize = 42;
  double currentZoom = 1.0;

  List<int> highScores = [];

  final double mapWidth = 900;
  final double mapHeight = 1600;

  final TextPaint hudPaint = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
  );

  int get overallLevel => (currentFloor - 1) * 5 + currentLevel;

  List<Vector2> getEnemySpawnPoints() {
    switch (currentFloor) {
      case 1:
        return [
          Vector2(150, 250), Vector2(750, 250),
          Vector2(150, 800), Vector2(750, 800),
          Vector2(450, 500), Vector2(300, 1200), Vector2(600, 1200),
        ];
      case 2:
        return [
          Vector2(120, 200), Vector2(780, 200),
          Vector2(120, 900), Vector2(780, 900),
          Vector2(450, 400), Vector2(450, 1100),
        ];
      case 3:
        return [
          Vector2(200, 300), Vector2(700, 300),
          Vector2(200, 1300), Vector2(700, 1300),
          Vector2(450, 800), Vector2(150, 800), Vector2(750, 800),
        ];
      case 4:
        return [
          Vector2(130, 220), Vector2(770, 220),
          Vector2(130, 1400), Vector2(770, 1400),
          Vector2(450, 600), Vector2(300, 1000), Vector2(600, 1000),
        ];
      case 5:
      default:
        return [
          Vector2(180, 300), Vector2(720, 300),
          Vector2(180, 1300), Vector2(720, 1300),
          Vector2(450, 450), Vector2(300, 900), Vector2(600, 900),
        ];
    }
  }

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2(mapWidth, mapHeight);
    camera.viewfinder.zoom = currentZoom;
  }

  void addScore(int value) {
    highScores.add(value);
    highScores.sort((a, b) => b.compareTo(a));
    if (highScores.length > 10) highScores = highScores.take(10).toList();
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
    swordDamage = 12;
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
    overlays.remove('records');
  }

  void _clearEverything() {
    world.removeAll(world.children.toList());
    camera.viewport.children.whereType<JoystickComponent>().toList().forEach((c) => c.removeFromParent());
    camera.viewport.children.whereType<HudButtonComponent>().toList().forEach((c) => c.removeFromParent());
  }

  void _startLevel() {
    enemiesSpawned = 0;
    enemiesAlive = 0;
    portalSpawned = false;
    isBossLevel = (currentLevel == 5);
    spawnTimer = 0;
    spawnInterval = max(0.5, 1.3 - (currentFloor * 0.1) - (currentLevel * 0.06));

    world.add(Floor(size: Vector2(mapWidth, mapHeight))..priority = 0);
    _createWalls();
    _createObstacles();

    for (final pos in getEnemySpawnPoints()) {
      world.add(EnemySpawnPortal(position: pos)..priority = 3);
    }
    world.add(PlayerSpawnPoint(position: Vector2(mapWidth / 2, mapHeight / 2 + 280))..priority = 3);

    final moveKnob = Paint()..color = const Color(0xFF8B0000);
    final moveBg = Paint()..color = const Color(0xFF2F2F2F).withOpacity(0.75);
    moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.38, paint: moveKnob),
      background: CircleComponent(radius: joystickSize, paint: moveBg),
      margin: const EdgeInsets.only(left: 28, bottom: 35),
    );

    final attackKnob = Paint()..color = const Color(0xFF00BCD4);
    final attackBg = Paint()..color = const Color(0xFF006064).withOpacity(0.7);
    attackJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.35, paint: attackKnob),
      background: CircleComponent(radius: joystickSize * 0.95, paint: attackBg),
      margin: const EdgeInsets.only(right: 28, bottom: 35),
    );

    switchWeaponButton = HudButtonComponent(
      button: CircleComponent(radius: 28, paint: Paint()..color = Colors.grey[800]!),
      buttonDown: CircleComponent(radius: 28, paint: Paint()..color = Colors.grey),
      margin: const EdgeInsets.only(right: 32, bottom: 160),
      onPressed: () { if (isPlaying && !isPaused) player.switchWeapon(); },
    );

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

    zoomInButton = HudButtonComponent(
      button: CircleComponent(radius: 24, paint: Paint()..color = const Color(0xFF455A64)),
      buttonDown: CircleComponent(radius: 24, paint: Paint()..color = Colors.blueGrey[400]!),
      margin: const EdgeInsets.only(left: 28, top: 90),
      onPressed: () {
        currentZoom = (currentZoom + 0.15).clamp(0.7, 1.8);
        camera.viewfinder.zoom = currentZoom;
      },
    );

    zoomOutButton = HudButtonComponent(
      button: CircleComponent(radius: 24, paint: Paint()..color = const Color(0xFF455A64)),
      buttonDown: CircleComponent(radius: 24, paint: Paint()..color = Colors.blueGrey[400]!),
      margin: const EdgeInsets.only(left: 28, top: 150),
      onPressed: () {
        currentZoom = (currentZoom - 0.15).clamp(0.7, 1.8);
        camera.viewfinder.zoom = currentZoom;
      },
    );

    player = Player(moveJoystick);
    world.add(player);

    camera.viewport.add(moveJoystick);
    camera.viewport.add(attackJoystick);
    camera.viewport.add(switchWeaponButton);
    camera.viewport.add(settingsButton);
    camera.viewport.add(zoomInButton);
    camera.viewport.add(zoomOutButton);
    camera.follow(player);
    camera.viewfinder.zoom = currentZoom;

    if (isBossLevel) {
      _spawnBosses();
    } else {
      enemiesToSpawn = 6 + (currentLevel * 2) + (currentFloor * 3);
    }
  }

  void _spawnBosses() {
    enemiesToSpawn = 1;
    enemiesAlive = 1;
    enemiesSpawned = 1;
    world.add(Boss(floor: currentFloor, position: Vector2(mapWidth / 2 - 120, mapHeight / 2 - 200))..priority = 25);

    if (overallLevel >= 15) {
      enemiesToSpawn++;
      enemiesAlive++;
      enemiesSpawned++;
      world.add(KnightBoss(floor: currentFloor, position: Vector2(mapWidth / 2 + 120, mapHeight / 2 - 200))..priority = 25);
    }

    if (overallLevel == 25) {
      enemiesToSpawn++;
      enemiesAlive++;
      enemiesSpawned++;
      world.add(KingBoss(position: Vector2(mapWidth / 2, mapHeight / 2 - 320))..priority = 26);
    }
  }

  void _createWalls() {
    const t = 42.0;
    final brown = const Color(0xFF5D4037);

    world.add(Wall(position: Vector2(0, 0), size: Vector2(mapWidth, t), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(0, mapHeight - t), size: Vector2(mapWidth, t), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(0, 0), size: Vector2(t, mapHeight), color: brown)..priority = 5);
    world.add(Wall(position: Vector2(mapWidth - t, 0), size: Vector2(t, mapHeight), color: brown)..priority = 5);

    switch (currentFloor) {
      case 1:
        world.add(Wall(position: Vector2(350, 700), size: Vector2(200, 28), color: brown)..priority = 5);
        break;
      case 2:
        world.add(Wall(position: Vector2(280, 150), size: Vector2(28, 500), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(590, 150), size: Vector2(28, 500), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(280, 900), size: Vector2(28, 500), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(590, 900), size: Vector2(28, 500), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(150, 700), size: Vector2(200, 28), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(550, 700), size: Vector2(200, 28), color: brown)..priority = 5);
        break;
      case 3:
        world.add(Wall(position: Vector2(380, 200), size: Vector2(28, 450), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(490, 200), size: Vector2(28, 450), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(380, 950), size: Vector2(28, 450), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(490, 950), size: Vector2(28, 450), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(150, 700), size: Vector2(250, 28), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(500, 700), size: Vector2(250, 28), color: brown)..priority = 5);
        break;
      case 4:
        world.add(Wall(position: Vector2(200, 250), size: Vector2(180, 28), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(520, 250), size: Vector2(180, 28), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(200, 500), size: Vector2(28, 200), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(670, 500), size: Vector2(28, 200), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(300, 750), size: Vector2(300, 28), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(200, 1000), size: Vector2(28, 250), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(670, 1000), size: Vector2(28, 250), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(250, 1300), size: Vector2(400, 28), color: brown)..priority = 5);
        break;
      case 5:
        world.add(Wall(position: Vector2(180, 350), size: Vector2(50, 50), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(670, 350), size: Vector2(50, 50), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(180, 750), size: Vector2(50, 50), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(670, 750), size: Vector2(50, 50), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(180, 1150), size: Vector2(50, 50), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(670, 1150), size: Vector2(50, 50), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(400, 200), size: Vector2(100, 40), color: brown)..priority = 5);
        world.add(Wall(position: Vector2(400, 1360), size: Vector2(100, 40), color: brown)..priority = 5);
        break;
    }
  }

  void _createObstacles() {
    List<Vector2> positions;
    switch (currentFloor) {
      case 1:
        positions = [Vector2(250, 600), Vector2(650, 900), Vector2(450, 1100)];
        break;
      case 2:
        positions = [Vector2(400, 350), Vector2(500, 1050), Vector2(200, 1100), Vector2(700, 500)];
        break;
      case 3:
        positions = [Vector2(300, 500), Vector2(600, 500), Vector2(300, 1100), Vector2(600, 1100)];
        break;
      case 4:
        positions = [Vector2(350, 400), Vector2(550, 650), Vector2(400, 1100), Vector2(200, 800), Vector2(700, 800)];
        break;
      case 5:
      default:
        positions = [Vector2(300, 550), Vector2(600, 550), Vector2(300, 1050), Vector2(600, 1050)];
        break;
    }
    for (final pos in positions) {
      world.add(Obstacle(position: pos)..priority = 5);
    }
  }

  void _spawnOneEnemy() {
    if (enemiesSpawned >= enemiesToSpawn) return;
    enemiesSpawned++;
    enemiesAlive++;

    final points = getEnemySpawnPoints();
    final spawnPos = points[Random().nextInt(points.length)];
    final type = _chooseEnemyType();

    final enemy = Enemy(floor: currentFloor, type: type);
    enemy.position = spawnPos.clone();
    enemy.priority = 30;
    world.add(enemy);
  }

  EnemyType _chooseEnemyType() {
    final roll = Random().nextDouble();
    final lvl = overallLevel;

    if (lvl >= 20) {
      if (roll < 0.25) return EnemyType.dog;
      if (roll < 0.50) return EnemyType.shieldedShooter;
      if (roll < 0.70) return EnemyType.shielded;
      if (roll < 0.85) return EnemyType.shooter;
      return EnemyType.melee;
    } else if (lvl >= 11) {
      if (roll < 0.30) return EnemyType.dog;
      if (roll < 0.50) return EnemyType.melee;
      if (roll < 0.70) return EnemyType.shooter;
      return EnemyType.shielded;
    } else if (currentFloor <= 2) {
      return roll < 0.55 ? EnemyType.melee : EnemyType.shooter;
    } else {
      if (roll < 0.35) return EnemyType.melee;
      if (roll < 0.70) return EnemyType.shooter;
      return EnemyType.shielded;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying || isPaused || isBossLevel) return;
    if (enemiesSpawned < enemiesToSpawn) {
      spawnTimer += dt;
      if (spawnTimer >= spawnInterval) {
        spawnTimer = 0;
        _spawnOneEnemy();
      }
    }
  }

  void onEnemyKilled() {
    enemiesAlive = max(0, enemiesAlive - 1);
    score += isBossLevel ? 180 + (currentFloor * 60) : 12 + (currentFloor * 6);
    if (enemiesAlive <= 0 && enemiesSpawned >= enemiesToSpawn && !portalSpawned) {
      portalSpawned = true;
      world.add(Portal(position: Vector2(mapWidth / 2, mapHeight / 2))..priority = 9);
    }
  }

  void goToNextLevel() {
    isPlaying = false;
    if (currentFloor == 5 && currentLevel == 5) {
      addScore(score);
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
      case 'sword': swordDamage += 5; break;
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
    overlays.remove('records');
    overlays.add('mainMenu');
  }

  void showGameOver() {
    isPlaying = false;
    addScore(score);
    overlays.add('gameOver');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (isPlaying) {
      hudPaint.render(canvas, 'Floor $currentFloor | Lvl $currentLevel', Vector2(14, 14));
      hudPaint.render(canvas, 'Score: $score', Vector2(14, 38));
      hudPaint.render(canvas, 'HP: ${player.health}/${player.maxHealth}', Vector2(14, 62));
      hudPaint.render(canvas, isBossLevel ? 'BOSS FIGHT' : 'Enemies: $enemiesAlive', Vector2(14, 86));
      hudPaint.render(canvas, player.weapon == WeaponType.bolter ? 'BOLTER' : 'SWORD', Vector2(14, 110));
    }
  }
}

// ====================== ТОЧКИ СПАВНА ======================
class EnemySpawnPortal extends PositionComponent {
  double flicker = 0;
  EnemySpawnPortal({required Vector2 position}) : super(position: position, size: Vector2(40, 40), anchor: Anchor.center, priority: 3);
  @override
  void update(double dt) { super.update(dt); flicker += dt * 4; }
  @override
  void render(Canvas canvas) {
    final alpha = 0.45 + 0.4 * sin(flicker);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 16, Paint()..color = Color.fromRGBO(255, 140, 0, alpha));
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 8, Paint()..color = Color.fromRGBO(255, 200, 50, alpha * 0.85));
  }
}

class PlayerSpawnPoint extends PositionComponent {
  PlayerSpawnPoint({required Vector2 position}) : super(position: position, size: Vector2(50, 50), anchor: Anchor.center, priority: 3);
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 20, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.75));
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 10, Paint()..color = const Color(0xFFE040FB).withOpacity(0.9));
  }
}

// ====================== ПОЛ / СТЕНЫ / ПРЕГРАДЫ / ПОРТАЛ ======================
class Floor extends PositionComponent {
  Floor({required Vector2 size}) : super(size: size, position: Vector2.zero(), priority: 0);
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFB0BEC5));
    final grid = Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 55) canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    for (double y = 0; y < size.y; y += 55) canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
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
class MainMenu extends StatefulWidget {
  final InquisitorGame game;
  const MainMenu(this.game, {super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_MatrixSymbol> symbols = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    for (int i = 0; i < 65; i++) {
      symbols.add(_MatrixSymbol(x: _rnd.nextDouble(), y: _rnd.nextDouble(), speed: 0.25 + _rnd.nextDouble() * 1.3, char: _randomChar(), opacity: 0.15 + _rnd.nextDouble() * 0.75));
    }
    _controller.addListener(() {
      setState(() {
        for (final s in symbols) {
          s.y += s.speed * 0.013;
          if (s.y > 1.15) {
            s.y = -0.1;
            s.x = _rnd.nextDouble();
            s.char = _randomChar();
            s.opacity = 0.15 + _rnd.nextDouble() * 0.75;
          }
        }
      });
    });
  }

  String _randomChar() {
    const chars = '01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンABCDEFXYZ';
    return chars[_rnd.nextInt(chars.length)];
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MatrixPainter(symbols))),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('SOUL OF THE\nINQUISITOR', style: TextStyle(color: Color(0xFFFFD700), fontSize: 32, fontWeight: FontWeight.w900, height: 1.15, shadows: [Shadow(color: Colors.redAccent, blurRadius: 14)]), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('by Инквизитор Данте', style: TextStyle(color: Color(0xFFB8860B), fontSize: 14)),
                const SizedBox(height: 48),
                _menuButton('НАЧАТЬ ИГРУ', () => widget.game.startGame()),
                const SizedBox(height: 16),
                _menuButton('РЕКОРДЫ', () {
                  widget.game.overlays.remove('mainMenu');
                  widget.game.overlays.add('records');
                }),
                const SizedBox(height: 16),
                _menuButton('НАСТРОЙКИ', () => widget.game.openSettings()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: 240,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFFB8860B), width: 1.5), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFFFD700))),
      ),
    );
  }
}

class _MatrixSymbol {
  double x, y, speed, opacity;
  String char;
  _MatrixSymbol({required this.x, required this.y, required this.speed, required this.char, required this.opacity});
}

class _MatrixPainter extends CustomPainter {
  final List<_MatrixSymbol> symbols;
  _MatrixPainter(this.symbols);
  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final s in symbols) {
      tp.text = TextSpan(text: s.char, style: TextStyle(color: Color.fromRGBO(0, 255, 70, s.opacity), fontSize: 15 + s.speed * 5, fontFamily: 'monospace'));
      tp.layout();
      tp.paint(canvas, Offset(s.x * size.width, s.y * size.height));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RecordsMenu extends StatelessWidget {
  final InquisitorGame game;
  const RecordsMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    final scores = game.highScores;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('РЕКОРДЫ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.redAccent, blurRadius: 10)])),
              const SizedBox(height: 30),
              Expanded(
                child: scores.isEmpty
                    ? const Center(child: Text('Пока нет рекордов', style: TextStyle(color: Colors.white54, fontSize: 18)))
                    : ListView.builder(
                        itemCount: scores.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: const Color(0xFFB8860B).withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${index + 1}.', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('${scores[index]} очков', style: const TextStyle(color: Colors.white, fontSize: 18)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFFB8860B)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
                onPressed: () {
                  game.overlays.remove('records');
                  game.overlays.add('mainMenu');
                },
                child: const Text('НАЗАД', style: TextStyle(color: Color(0xFFFFD700), fontSize: 16)),
              ),
            ],
          ),
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
              const Text('НАСТРОЙКИ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Text('Размер джойстика: ${widget.game.joystickSize.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 17)),
              Slider(value: widget.game.joystickSize, min: 55, max: 120, divisions: 13, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => widget.game.joystickSize = v)),
              const SizedBox(height: 18),
              Text('Размер кнопок: ${widget.game.buttonSize.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 17)),
              Slider(value: widget.game.buttonSize, min: 28, max: 65, divisions: 8, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => widget.game.buttonSize = v)),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), side: const BorderSide(color: Color(0xFFB8860B)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
                  onPressed: () {
                    if (widget.game.isPlaying) widget.game.closeSettings();
                    else widget.game.backToMenu();
                  },
                  child: Text(widget.game.isPlaying ? 'НАЗАД В БОЙ' : 'НАЗАД', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16)),
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
            const Text('УРОВЕНЬ ПРОЙДЕН', style: TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Этаж ${game.currentFloor}  •  Уровень ${game.currentLevel}', style: const TextStyle(color: Colors.white70, fontSize: 17)),
            Text('Очки: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 45),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: () => game.nextLevel(),
              child: const Text('СЛЕДУЮЩИЙ УРОВЕНЬ', style: TextStyle(fontSize: 18, color: Colors.white)),
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
              const Text('УЛУЧШЕНИЕ ИНКВИЗИТОРА', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Этаж ${game.currentFloor} пройден. Выберите улучшение:', style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _btn('Урон болтера (+5)', 'bolter', Colors.orange),
                    _btn('Урон меча (+5)', 'sword', Colors.redAccent),
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
            const Text('ВЫ ПРОШЛИ ИСПЫТАНИЕ\nИНКВИЗИТОРА', style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold, height: 1.3), textAlign: TextAlign.center),
            const SizedBox(height: 22),
            Text('Финальный счёт: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 21)),
            const SizedBox(height: 45),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB8860B), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              onPressed: () => game.backToMenu(),
              child: const Text('В ГЛАВНОЕ МЕНЮ', style: TextStyle(fontSize: 17, color: Colors.black, fontWeight: FontWeight.bold)),
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
            const Text('ИНКВИЗИТОР ПАЛ', style: TextStyle(color: Colors.redAccent, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Text('Очки: ${game.score}', style: const TextStyle(color: Colors.white, fontSize: 22)),
            Text('Этаж ${game.currentFloor}  •  Уровень ${game.currentLevel}', style: const TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 45),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: () => game.startGame(),
              child: const Text('ПОПРОБОВАТЬ СНОВА', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 13)),
              onPressed: () => game.backToMenu(),
              child: const Text('ГЛАВНОЕ МЕНЮ', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== ИГРОК ======================
class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent moveJoystick;
  late int health;
  late int maxHealth;
  double attackTimer = 0;
  WeaponType weapon = WeaponType.bolter;

  Player(this.moveJoystick) : super(size: Vector2(58, 64), anchor: Anchor.center, priority: 15);

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

    if (moveJoystick.direction != JoystickDirection.idle) {
      position.add(moveJoystick.relativeDelta * game.playerSpeed * dt);
      angle = moveJoystick.delta.screenAngle();
    }
    position.x = position.x.clamp(55, game.mapWidth - 55);
    position.y = position.y.clamp(55, game.mapHeight - 55);

    if (game.attackJoystick.direction != JoystickDirection.idle) {
      attackTimer += dt;
      final interval = weapon == WeaponType.bolter ? 0.30 : 0.42;
      if (attackTimer >= interval) {
        attackTimer = 0;
        _doAttack();
      }
    } else {
      attackTimer = 0;
    }
  }

  void _doAttack() {
    final dir = game.attackJoystick.relativeDelta.normalized();
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
    final cape = Path()
      ..moveTo(cx - 20, cy + 6)
      ..quadraticBezierTo(cx - 32, cy + 28, cx - 10, cy + 34)
      ..lineTo(cx + 10, cy + 34)
      ..quadraticBezierTo(cx + 32, cy + 28, cx + 20, cy + 6)
      ..close();
    canvas.drawPath(cape, Paint()..color = const Color(0xFF6B0000).withOpacity(0.75));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 30, height: 28), const Radius.circular(6)), Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawCircle(Offset(cx - 16, cy + 3), 8, Paint()..color = const Color(0xFF2A2A2A));
    canvas.drawCircle(Offset(cx + 16, cy + 3), 8, Paint()..color = const Color(0xFF2A2A2A));
    canvas.drawCircle(Offset(cx, cy - 14), 12, Paint()..color = const Color(0xFF111111));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 15), width: 16, height: 5), const Radius.circular(2)), Paint()..color = const Color(0xFFB22222));
    canvas.drawCircle(Offset(cx, cy + 5), 4.5, Paint()..color = const Color(0xFF8B0000));
    if (weapon == WeaponType.bolter) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 10, cy - 6, 22, 8), const Radius.circular(2)), Paint()..color = const Color(0xFF37474F));
      canvas.drawRect(Rect.fromLTWH(cx + 28, cy - 4, 8, 4), Paint()..color = const Color(0xFF263238));
    } else {
      canvas.drawLine(Offset(cx + 12, cy - 8), Offset(cx + 28, cy - 22), Paint()..color = const Color(0xFF00E5FF)..strokeWidth = 3.5..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(cx + 12, cy - 6), 3, Paint()..color = const Color(0xFF0097A7));
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!game.isPlaying || game.isPaused) return;
    if (other is Wall || other is Obstacle) position -= (intersectionPoints.first - position).normalized() * 5;
    if (other is Enemy || other is EnemyBullet || other is BossProjectile) {
      int dmg = 1;
      if (other is Enemy && other.type == EnemyType.dog) dmg = 2;
      takeDamage(dmg);
      other.removeFromParent();
      if (other is Enemy) game.onEnemyKilled();
    }
    if (other is Boss || other is KnightBoss || other is KingBoss) takeDamage(1);
    if (other is Portal && weapon == WeaponType.sword) game.goToNextLevel();
  }
}

// ====================== ВРАГИ ======================
class Enemy extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  final EnemyType type;
  late final double speed;
  double shootTimer = 0;
  int contactDamage = 1;

  Enemy({required this.floor, required this.type}) : super(size: Vector2(56, 62), anchor: Anchor.center, priority: 30);

  @override
  Future<void> onLoad() async {
    switch (type) {
      case EnemyType.shooter:
        speed = 50 + floor * 6.0;
        break;
      case EnemyType.melee:
        speed = 78 + floor * 9.0;
        break;
      case EnemyType.shielded:
        speed = 38 + floor * 4.5;
        size = Vector2(60, 64);
        break;
      case EnemyType.dog:
        speed = 130 + floor * 12.0;
        size = Vector2(48, 40);
        contactDamage = 2;
        break;
      case EnemyType.shieldedShooter:
        speed = 45 + floor * 5.0;
        size = Vector2(58, 62);
        break;
    }
    add(CircleHitbox(radius: type == EnemyType.dog ? 18 : (type == EnemyType.shielded || type == EnemyType.shieldedShooter ? 26 : 22)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * speed * dt);
    angle = toPlayer.screenAngle();
    position.x = position.x.clamp(70, game.mapWidth - 70);
    position.y = position.y.clamp(70, game.mapHeight - 70);

    if (type == EnemyType.shooter || type == EnemyType.shieldedShooter) {
      shootTimer += dt;
      if (shootTimer >= 1.85) {
        shootTimer = 0;
        game.world.add(EnemyBullet(position: position.clone(), direction: toPlayer)..priority = 22);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) position -= (intersectionPoints.first - position).normalized() * 8;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    if (type == EnemyType.dog) {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4), width: 36, height: 22), Paint()..color = const Color(0xFF4E342E));
      canvas.drawCircle(Offset(cx + 14, cy - 4), 10, Paint()..color = const Color(0xFF3E2723));
      canvas.drawCircle(Offset(cx + 18, cy - 6), 3, Paint()..color = const Color(0xFFFF1744));
      return;
    }

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 7), width: 28, height: 28), const Radius.circular(6)), Paint()..color = const Color(0xFF2A2A2A));
    canvas.drawCircle(Offset(cx - 14, cy + 2), 8, Paint()..color = const Color(0xFF3A3A3A));
    canvas.drawCircle(Offset(cx + 14, cy + 2), 8, Paint()..color = const Color(0xFF3A3A3A));
    canvas.drawCircle(Offset(cx, cy - 15), 12, Paint()..color = const Color(0xFF1A1A1A));

    switch (type) {
      case EnemyType.shooter:
        canvas.drawCircle(Offset(cx, cy - 16), 5, Paint()..color = const Color(0xFF00C853));
        canvas.drawLine(Offset(cx + 9, cy - 3), Offset(cx + 24, cy - 12), Paint()..color = const Color(0xFF1B5E20)..strokeWidth = 4.5..strokeCap = StrokeCap.round);
        break;
      case EnemyType.melee:
        canvas.drawCircle(Offset(cx, cy - 16), 5, Paint()..color = const Color(0xFFFFAB00));
        canvas.drawLine(Offset(cx + 10, cy - 6), Offset(cx + 24, cy - 20), Paint()..color = const Color(0xFFFFD600)..strokeWidth = 4..strokeCap = StrokeCap.round);
        break;
      case EnemyType.shielded:
        canvas.drawCircle(Offset(cx, cy - 16), 5, Paint()..color = const Color(0xFF2979FF));
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy + 4), radius: 26), -1.2, 2.4, false, Paint()..color = const Color(0xFF448AFF).withOpacity(0.85)..style = PaintingStyle.stroke..strokeWidth = 5.5);
        break;
      case EnemyType.shieldedShooter:
        canvas.drawCircle(Offset(cx, cy - 16), 5, Paint()..color = const Color(0xFF00BCD4));
        canvas.drawLine(Offset(cx + 9, cy - 3), Offset(cx + 24, cy - 12), Paint()..color = const Color(0xFF006064)..strokeWidth = 4.5..strokeCap = StrokeCap.round);
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy + 4), radius: 26), -1.2, 2.4, false, Paint()..color = const Color(0xFF00ACC1).withOpacity(0.85)..style = PaintingStyle.stroke..strokeWidth = 5.5);
        break;
      case EnemyType.dog:
        break;
    }
  }
}

// ====================== БОССЫ ======================
class Boss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  late int maxHp;
  late int currentHp;
  double attackTimer = 0;

  Boss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(95, 105), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    maxHp = 220 + (floor * 90);
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
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
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

    final barW = 84.0;
    final hpP = (currentHp / maxHp).clamp(0.0, 1.0);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -28, barW, 11), const Radius.circular(4)), Paint()..color = Colors.black.withOpacity(0.75));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -28, barW * hpP, 11), const Radius.circular(4)), Paint()..color = hpP > 0.3 ? const Color(0xFFE53935) : const Color(0xFFFF1744));
  }
}

class KnightBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  late int maxHp;
  late int currentHp;

  KnightBoss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(90, 100), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    maxHp = 280 + (floor * 100);
    currentHp = maxHp;
    add(CircleHitbox(radius: 40));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * (70 + floor * 8.0) * dt);
    angle = toPlayer.screenAngle();
    position.x = position.x.clamp(75, game.mapWidth - 75);
    position.y = position.y.clamp(75, game.mapHeight - 75);
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
    if (other is Player) other.takeDamage(2);
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8), width: 58, height: 55), const Radius.circular(8)), Paint()..color = const Color(0xFF37474F));
    canvas.drawCircle(Offset(cx - 26, cy + 2), 13, Paint()..color = const Color(0xFF546E7A));
    canvas.drawCircle(Offset(cx + 26, cy + 2), 13, Paint()..color = const Color(0xFF546E7A));
    canvas.drawCircle(Offset(cx, cy - 22), 17, Paint()..color = const Color(0xFF263238));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 28), width: 22, height: 8), Paint()..color = const Color(0xFF90A4AE));
    canvas.drawLine(Offset(cx + 20, cy - 10), Offset(cx + 38, cy - 30), Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 5..strokeCap = StrokeCap.round);

    final barW = 80.0;
    final hpP = (currentHp / maxHp).clamp(0.0, 1.0);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -26, barW, 10), const Radius.circular(4)), Paint()..color = Colors.black.withOpacity(0.75));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -26, barW * hpP, 10), const Radius.circular(4)), Paint()..color = const Color(0xFF78909C));
  }
}

class KingBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  late int maxHp;
  late int currentHp;
  late int phaseHp;
  int phase = 1;

  double attackTimer = 0;
  double meleeTimer = 0;
  double phase2Timer = 0;
  int phase2VolleyCount = 0;

  KingBoss({required Vector2 position})
      : super(position: position, size: Vector2(120, 130), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    phaseHp = 400;
    maxHp = phaseHp * 2;
    currentHp = maxHp;
    add(CircleHitbox(radius: 52));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;

    final toPlayer = (game.player.position - position).normalized();
    position.add(toPlayer * (phase == 1 ? 50.0 : 65.0) * dt);
    angle = toPlayer.screenAngle();
    position.x = position.x.clamp(80, game.mapWidth - 80);
    position.y = position.y.clamp(80, game.mapHeight - 80);

    if (phase == 1) {
      attackTimer += dt;
      if (attackTimer >= 2.0) {
        attackTimer = 0;
        for (int i = 0; i < 10; i++) {
          final a = (i / 10) * 2 * pi;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
      }
    } else {
      phase2Timer += dt;
      if (phase2VolleyCount > 0) {
        if (phase2Timer >= 0.35) {
          phase2Timer = 0;
          _fireVolley();
          phase2VolleyCount--;
        }
      } else if (phase2Timer >= 3.0) {
        phase2Timer = 0;
        phase2VolleyCount = 2;
        _fireVolley();
      }
    }

    meleeTimer += dt;
    if (meleeTimer >= 1.0) {
      meleeTimer = 0;
      if (position.distanceTo(game.player.position) < 95) {
        game.player.takeDamage(phase == 1 ? 2 : 3);
      }
    }
  }

  void _fireVolley() {
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * pi;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    if (currentHp <= 0) {
      currentHp = 0;
      removeFromParent();
      game.onEnemyKilled();
      return;
    }
    if (phase == 1 && currentHp <= phaseHp) {
      phase = 2;
      phase2Timer = 0;
      phase2VolleyCount = 0;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position -= (intersectionPoints.first - position).normalized() * 8;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 12), width: 80, height: 70), const Radius.circular(12)), Paint()..color = const Color(0xFF1A0000));
    canvas.drawCircle(Offset(cx - 36, cy + 4), 18, Paint()..color = const Color(0xFF4A0000));
    canvas.drawCircle(Offset(cx + 36, cy + 4), 18, Paint()..color = const Color(0xFF4A0000));
    canvas.drawCircle(Offset(cx, cy - 30), 24, Paint()..color = const Color(0xFF0D0000));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 48), width: 30, height: 12), Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(Offset(cx - 8, cy - 32), 5, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(cx + 8, cy - 32), 5, Paint()..color = const Color(0xFFFF1744));

    final barW = 100.0;
    final barH = 9.0;

    final phase2Hp = (currentHp - phaseHp).clamp(0, phaseHp);
    final p2 = phase2Hp / phaseHp;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -48, barW, barH), const Radius.circular(3)), Paint()..color = Colors.black.withOpacity(0.8));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -48, barW * p2, barH), const Radius.circular(3)), Paint()..color = const Color(0xFFFFD700));

    final phase1Hp = currentHp.clamp(0, phaseHp);
    final p1 = phase1Hp / phaseHp;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -36, barW, barH), const Radius.circular(3)), Paint()..color = Colors.black.withOpacity(0.8));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, -36, barW * p1, barH), const Radius.circular(3)), Paint()..color = phase == 2 ? const Color(0xFFFF1744) : const Color(0xFFE53935));
  }
}

class BossProjectile extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  BossProjectile({required super.position, required this.direction})
      : super(radius: 11, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFF1744), priority: 22);
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
  Bullet({required super.position, required this.direction})
      : super(radius: 7, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFFD700), priority: 13);
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
      if (other.type == EnemyType.shielded || other.type == EnemyType.shieldedShooter) {
        removeFromParent();
        return;
      }
      other.removeFromParent();
      game.onEnemyKilled();
      removeFromParent();
    }
    if (other is Boss) { other.takeDamage(game.bolterDamage); removeFromParent(); }
    if (other is KnightBoss) { other.takeDamage(game.bolterDamage); removeFromParent(); }
    if (other is KingBoss) { other.takeDamage(game.bolterDamage); removeFromParent(); }
  }
}

class MeleeAttack extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  double life = 0.17;
  MeleeAttack({required super.position, required this.direction})
      : super(radius: 34, anchor: Anchor.center, paint: Paint()..color = const Color(0xFF00E5FF).withOpacity(0.55), priority: 13);
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
    if (other is KnightBoss) other.takeDamage(game.swordDamage);
    if (other is KingBoss) other.takeDamage(game.swordDamage);
    if (other is Portal) game.goToNextLevel();
  }
}

class EnemyBullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  EnemyBullet({required super.position, required this.direction})
      : super(radius: 8, anchor: Anchor.center, paint: Paint()..color = const Color(0xFF76FF03), priority: 22);
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
