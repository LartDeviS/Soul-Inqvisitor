import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import '../lib/main.dart' as game;

void main() {
  group('Boss hit zones', () {
    final center = Vector2(100, 100);
    final size = Vector2(100, 100);

    test('exposed core is a critical hit', () {
      final result = game.resolveBossHitZone(
        impact: Vector2(100, 95), center: center, size: size, exposed: true,
      );
      expect(result.zone, game.BossHitZoneKind.core);
      expect(result.multiplier, 1.8);
    });

    test('closed core is reduced by armor', () {
      final result = game.resolveBossHitZone(
        impact: Vector2(100, 95), center: center, size: size,
      );
      expect(result.zone, game.BossHitZoneKind.armor);
      expect(result.multiplier, 0.72);
    });

    test('head shots outperform armor hits', () {
      final head = game.resolveBossHitZone(
        impact: Vector2(100, 70), center: center, size: size,
      );
      final armor = game.resolveBossHitZone(
        impact: Vector2(125, 115), center: center, size: size,
      );
      expect(head.zone, game.BossHitZoneKind.head);
      expect(head.multiplier, greaterThan(armor.multiplier));
    });

    test('limb hit has its own result', () {
      final result = game.resolveBossHitZone(
        impact: Vector2(70, 120), center: center, size: size,
      );
      expect(result.zone, game.BossHitZoneKind.limb);
      expect(result.multiplier, 0.9);
    });
  });
}
