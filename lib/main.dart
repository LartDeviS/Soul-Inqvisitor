import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: InquisitorGame()));
}

class InquisitorGame extends FlameGame with HasCollisionDetection {
  late final Player player;
  late final JoystickComponent joystick;
  late final HudButtonComponent shootButton;
  int score = 0;

  final TextPaint hudPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  Future<void> onLoad() async {
    // Джойстик слева
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final bgPaint = BasicPalette.blue.withAlpha(80).paint();

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 28, paint: knobPaint),
      background: CircleComponent(radius: 75, paint: bgPaint),
      margin: const EdgeInsets.only(left: 25, bottom: 30),
    );

    // Кнопка стрельбы справа
    shootButton = HudButtonComponent(
      button: CircleComponent(radius: 40, paint: BasicPalette.red.withAlpha(180).paint()),
      buttonDown: CircleComponent(radius: 40, paint: BasicPalette.red.paint()),
      margin: const EdgeInsets.only(right: 30, bottom: 40),
      onPressed: () => player.isShooting = true,
      onReleased: () => player.isShooting = false,
      onCancelled: () => player.isShooting = false,
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
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    hudPaint.render(canvas, 'Очки: $score', Vector2(16, 16));
    hudPaint.render(canvas, 'Жизни: ${player.health}', Vector2(16, 48));
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

    // Движение
    if (joystick.direction != JoystickDirection.idle) {
      position.add(joystick.relativeDelta * speed * dt);
      angle = joystick.delta.screenAngle();
    }

    // Границы экрана
    position.x = position.x.clamp(radius, game.size.x - radius);
    position.y = position.y.clamp(radius, game.size.y - radius);

    // Стрельба по кнопке
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
        // Пока просто останавливаем жизнь
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

    // Спавн строго с краёв
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
