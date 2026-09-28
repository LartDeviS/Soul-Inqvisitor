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

  // Настройки размеров
  double joystickSize = 75; // радиус фона джойстика
  double buttonSize = 40;   // радиус кнопки стрельбы

  final TextPaint hudPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  Future<void> onLoad() async {
    // Игра пока не запущена
  }

  void startGame() {
    isPlaying = true;
    score = 0;

    // Очищаем старые компоненты
    world.removeAll(world.children);
    camera.viewport.removeAll(camera.viewport.children.whereType<JoystickComponent>());
    camera.viewport.removeAll(camera.viewport.children.whereType<HudButtonComponent>());

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

    // Спавн врагов
    add(
      SpawnComponent(
        factory: (_) => Enemy(),
        period: 1.6,
        selfPositioning: true,
      ),
    );

    overlays.remove('mainMenu');
    overlays.remove('settings');
  }

  void openSettings() {
    overlays.remove('mainMenu');
    overlays.add('settings');
  }

  void backToMenu() {
    overlays.remove('settings');
    overlays.add('mainMenu');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (isPlaying) {
      hudPaint.render(canvas, 'Очки: $score', Vector2(16, 16));
      hudPaint.render(canvas, 'Жизни: ${player.health}', Vector2(16, 48));
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
              'INQUISITOR 40K',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'От лица Инквизитора',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              ),
              onPressed: () => game.startGame(),
              child: const Text('ИГРАТЬ', style: TextStyle(fontSize: 22, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: () => game.openSettings(),
              child: const Text('Настройки', style: TextStyle(fontSize: 18, color: Colors.white)),
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
                'Настройки',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Размер джойстика
              Text(
                'Размер джойстика: ${widget.game.joystickSize.toInt()}',
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

              // Размер кнопки
              Text(
                'Размер кнопки стрельбы: ${widget.game.buttonSize.toInt()}',
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
                  child: const Text('Назад', style: TextStyle(fontSize: 18, color: Colors.white)),
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
    if (other is Enemy) {
      health--;
      other.removeFromParent();
      if (health <= 0) {
        health = 0;
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
      game.score += 10;
      removeFromParent();
    }
  }
}

// ==================== ВРАГ ====================
class Enemy extends CircleComponent
    with HasGameReference<InquisitorGame>, CollisionCallbacks {
  late final double speed;

  Enemy()
      : super(
          radius: 18,
          paint: BasicPalette.red.paint(),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    speed = 70 + Random().nextDouble() * 50;

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
    final direction = (game.player.position - position).normalized();
    position.add(direction * speed * dt);
  }
}
