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

class InquisitorGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late HudButtonComponent shootButton;

  int score = 0;
  bool isPlaying = false;

  // Система уровней
  int currentFloor = 1;   // 1–5
  int currentLevel = 1;   // 1–5
  int enemiesAlive = 0;
  int enemiesToSpawn = 0;
  int enemiesSpawned = 0;

  // Настройки размеров
  double joystickSize = 75;
  double buttonSize = 40;

  final TextPaint hudPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
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
    camera.viewport.children
        .whereType<JoystickComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());
    camera.viewport.children
        .whereType<HudButtonComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());
    children.whereType<SpawnComponent>().toList().forEach((c) => c.removeFromParent());
  }

  void _startLevel() {
    enemiesSpawned = 0;
    enemiesAlive = 0;

    // Количество врагов растёт с уровнем и этажом
    enemiesToSpawn = 4 + (currentLevel * 2) + (currentFloor * 3);

    // Джойстик
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final bgPaint = BasicPalette.blue.withAlpha(80).paint();

    joystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.37, paint: knobPaint),
      background: CircleComponent(radius: joystickSize, paint: bgPaint),
      margin: const EdgeInsets.only(left: 25, bottom: 30),
    );

    // Кнопка стрельбы
    shootButton = HudButtonComponent(
      button: CircleComponent(radius: buttonSize, paint: BasicPalette.red.withAlpha(180).paint()),
      buttonDown: CircleComponent(radius: buttonSize, paint: BasicPalette.red.paint()),
      margin: const EdgeInsets.only(right: 30, bottom: 40),
      onPressed: () {
        if (isPlaying) player.isShooting = true;
      },
      onReleased: () {
        if (isPlaying) player.isShooting = false;
      },
      onCancelled: () {
        if (isPlaying) player.isShooting = false;
      },
    );

    player = Player(joystick);
    world.add(player);
    camera.viewport.add(joystick);
    camera.viewport.add(shootButton);

    // Спавн врагов с небольшой задержкой
    _spawnWave();
  }

  void _spawnWave() {
    // Спавним врагов постепенно
    final spawnPeriod = max(0.4, 1.8 - (currentFloor * 0.2) - (currentLevel * 0.1));

    add(
      SpawnComponent(
        factory: (_) {
          if (enemiesSpawned >= enemiesToSpawn) return null;
          enemiesSpawned++;
          enemiesAlive++;
          return Enemy(floor: currentFloor);
        },
        period: spawnPeriod,
        selfPositioning: true,
      ),
    );
  }

  void onEnemyKilled() {
    enemiesAlive--;
    score += 10 + (currentFloor * 5);

    if (enemiesAlive <= 0 && enemiesSpawned >= enemiesToSpawn) {
      // Уровень пройден
      _levelCompleted();
    }
  }

  void _levelCompleted() {
    isPlaying = false;

    if (currentLevel >= 5) {
      // Этаж пройден
      if (currentFloor >= 5) {
        // Игра полностью пройдена
        overlays.add('gameOver'); // Можно сделать отдельный экран победы позже
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
      hudPaint.render(canvas, 'Этаж $currentFloor  |  Уровень $currentLevel', Vector2(16, 16));
      hudPaint.render(canvas, 'Очки: $score', Vector2(16, 44));
      hudPaint.render(canvas, 'Жизни: ${player.health}', Vector2(16, 72));
      hudPaint.render(canvas, 'Враги: $enemiesAlive', Vector2(16, 100));
    }
  }
}

// ==================== ГЛАВНОЕ МЕНЮ ====================
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
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'From the Inquisitor\'s perspective',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              ),
              onPressed: () => game.startGame(),
              child: const Text('PLAY', style: TextStyle(fontSize: 22, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: () => game.openSettings(),
              child: const Text('Settings', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== НАСТРОЙКИ ====================
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
              const Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Text(
                'Joystick size: ${widget.game.joystickSize.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Slider(
                value: widget.game.joystickSize,
                min: 50,
                max: 120,
                divisions: 14,
                activeColor: Colors.blue,
                onChanged: (value) {
                  setState(() {
                    widget.game.joystickSize = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              Text(
                'Shoot button size: ${widget.game.buttonSize.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Slider(
                value: widget.game.buttonSize,
                min: 25,
                max: 70,
                divisions: 9,
                activeColor: Colors.red,
                onChanged: (value) {
                  setState(() {
                    widget.game.buttonSize = value;
                  });
                },
              ),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  onPressed: () => widget.game.backToMenu(),
                  child: const Text('Back', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== LEVEL COMPLETE ====================
class LevelCompleteMenu extends StatelessWidget {
  final InquisitorGame game;
  const LevelCompleteMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final isNewFloor = game.currentLevel == 1 && game.currentFloor > 1;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isNewFloor ? 'FLOOR ${game.currentFloor} CLEARED' : 'LEVEL CLEARED',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Floor ${game.currentFloor}  •  Level ${game.currentLevel}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${game.score}',
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: () => game.nextLevel(),
              child: const Text('NEXT LEVEL', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== GAME OVER ====================
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
            const Text(
              'THE INQUISITOR HAS FALLEN',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Score: ${game.score}',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            Text(
              'Floor ${game.currentFloor}  •  Level ${game.currentLevel}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: () => game.startGame(),
              child: const Text('TRY AGAIN', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: () => game.backToMenu(),
              child: const Text('Main Menu', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ИНКВИЗИТОР ====================
class Player extends CircleComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  double speed = 220;
  int health = 5;
  bool isShooting = false;
  double shootTimer = 0;
  final double shootInterval = 0.28;

  Player(this.joystick)
      : super(
          radius: 22,
          paint: BasicPalette.blue.paint(),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    position = game.size / 2;
    add(CircleHitbox());
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

    if (isShooting) {
      shootTimer += dt;
      if (shootTimer >= shootInterval) {
        shootTimer = 0;
        final dir = joystick.relativeDelta.normalized();
        final shootDir = dir == Vector2.zero() ? Vector2(0, -1) : dir;
        game.world.add(Bullet(
          position: position.clone(),
          direction: shootDir,
        ));
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy && game.isPlaying) {
      health--;
      other.removeFromParent();
      game.onEnemyKilled(); // чтобы счётчик уменьшился
      if (health <= 0) {
        health = 0;
        game.showGameOver();
      }
    }
  }
}

// ==================== ПУЛЯ ====================
class Bullet extends CircleComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 450;

  Bullet({required super.position, required this.direction})
      : super(
          radius: 7,
          paint: BasicPalette.yellow.paint(),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    position.add(direction * speed * dt);

    if (position.x < -30 ||
        position.x > game.size.x + 30 ||
        position.y < -30 ||
        position.y > game.size.y + 30) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      other.removeFromParent();
      game.onEnemyKilled();
      removeFromParent();
    }
  }
}

// ==================== ВРАГ ====================
class Enemy extends CircleComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final int floor;
  late final double speed;
  late final Color color;

  Enemy({required this.floor})
      : super(
          radius: 16 + floor.toDouble(),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Разные цвета и скорость по этажам
    switch (floor) {
      case 1:
        color = Colors.red;
        speed = 70 + Random().nextDouble() * 30;
        break;
      case 2:
        color = Colors.orange;
        speed = 85 + Random().nextDouble() * 35;
        break;
      case 3:
        color = Colors.purple;
        speed = 100 + Random().nextDouble() * 40;
        break;
      case 4:
        color = Colors.green;
        speed = 115 + Random().nextDouble() * 45;
        break;
      default:
        color = Colors.white;
        speed = 130 + Random().nextDouble() * 50;
    }

    paint = Paint()..color = color;

    final side = Random().nextInt(4);
    switch (side) {
      case 0:
        position = Vector2(Random().nextDouble() * game.size.x, -25);
        break;
      case 1:
        position = Vector2(Random().nextDouble() * game.size.x, game.size.y + 25);
        break;
      case 2:
        position = Vector2(-25, Random().nextDouble() * game.size.y);
        break;
      case 3:
        position = Vector2(game.size.x + 25, Random().nextDouble() * game.size.y);
        break;
    }

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    final direction = (game.player.position - position).normalized();
    position.add(direction * speed * dt);
  }
}
