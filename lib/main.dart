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
  int score = 0;
  final TextPaint scorePaint = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 24),
  );

  @override
  Future<void> onLoad() async {
    // Тёмный фон в стиле 40k
    camera.viewfinder.visibleGameSize = size;

    // Джойстик
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: knobPaint),
      background: CircleComponent(radius: 70, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 30, bottom: 30),
    );

    // Инквизитор
    player = Player(joystick);
    world.add(player);
    camera.viewport.add(joystick);

    // Спавн врагов каждые 2 секунды
    add(SpawnComponent(
      factory: (index) => Enemy(),
      period: 2.0,
      area: Rectangle.fromLTWH(0, 0, size.x, size.y),
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Очки
    scorePaint.render(canvas, 'Очки: $score', Vector2(20, 20));
    // Жизни
    scorePaint.render(canvas, 'Жизни: ${player.health}', Vector2(20, 50));
  }
}

// ==================== ИНКВИЗИТОР ====================
class Player extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  double speed = 200;
  int health = 5;
  double shootTimer = 0;
  final double shootInterval = 0.4; // стреляет каждые 0.4 секунды

  Player(this.joystick)
      : super(
          radius: 20,
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

    // Движение джойстиком
    if (joystick.direction != JoystickDirection.idle) {
      position.add(joystick.relativeDelta * speed * dt);
      angle = joystick.delta.screenAngle();
    }

    // Держим внутри экрана
    position.x = position.x.clamp(radius, game.size.x - radius);
    position.y = position.y.clamp(radius, game.size.y - radius);

    // Автоматическая стрельба
    shootTimer += dt;
    if (shootTimer >= shootInterval && joystick.direction != JoystickDirection.idle) {
      shootTimer = 0;
      final direction = joystick.relativeDelta.normalized();
      if (direction != Vector2.zero()) {
        game.world.add(Bullet(
          position: position.clone(),
          direction: direction,
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
        // Пока просто останавливаем
        health = 0;
      }
    }
  }
}

// ==================== ПУЛЯ ====================
class Bullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 400;

  Bullet({required Vector2 position, required this.direction})
      : super(
          radius: 6,
          paint: BasicPalette.yellow.paint(),
          position: position,
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

    // Удаляем, если вышла за экран
    if (position.x < -20 ||
        position.x > game.size.x + 20 ||
        position.y < -20 ||
        position.y > game.size.y + 20) {
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

// ==================== ВРАГ (еретик) ====================
class Enemy extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final double speed = 80 + Random().nextDouble() * 40;

  Enemy()
      : super(
          radius: 18,
          paint: BasicPalette.red.paint(),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Спавним с краёв экрана
    final side = Random().nextInt(4);
    switch (side) {
      case 0: // сверху
        position = Vector2(Random().nextDouble() * game.size.x, -20);
        break;
      case 1: // снизу
        position = Vector2(Random().nextDouble() * game.size.x, game.size.y + 20);
        break;
      case 2: // слева
        position = Vector2(-20, Random().nextDouble() * game.size.y);
        break;
      case 3: // справа
        position = Vector2(game.size.x + 20, Random().nextDouble() * game.size.y);
        break;
    }
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Бежит к Инквизитору
    final player = game.player;
    final direction = (player.position - position).normalized();
    position.add(direction * speed * dt);
  }
}
