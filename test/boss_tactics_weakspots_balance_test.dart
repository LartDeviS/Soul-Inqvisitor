import 'package:flutter_test/flutter_test.dart';
import '../lib/game/balance/floor_balance_profile.dart';
import '../lib/game/enemies/boss_tactics.dart';
import '../lib/game/enemies/boss_weak_spots.dart';

void main() {
  group('Boss tactics and hit zones', () {
    test('boss archetypes choose distinct themed attacks', () {
      expect(BossAttackCatalog.forBoss('warp_echo', 0).pattern, BossAttackPattern.warpNova);
      expect(BossAttackCatalog.forBoss('chaos_knight', 0).pattern, BossAttackPattern.charge);
    });
    test('boss attack runtime telegraphs before resolving', () {
      final runtime = BossAttackRuntime(bossId: 'warp_echo');
      expect(runtime.update(.5), isFalse);
      expect(runtime.warning, contains('Отойдите'));
      expect(runtime.update(1.0), isFalse);
      expect(runtime.update(.25), isTrue);
      expect(runtime.recovering, isTrue);
    });
    test('core hit is stronger only while exposed; armor reduces damage', () {
      final point = const HitPoint(.5, .44);
      final closed = BossWeakSpotSystem.resolve(normalizedPoint: point, weakSpotExposed: false);
      final open = BossWeakSpotSystem.resolve(normalizedPoint: point, weakSpotExposed: true);
      expect(closed.wasWeakSpot, isFalse);
      expect(open.wasWeakSpot, isTrue);
      expect(open.multiplier, greaterThan(closed.multiplier));
    });
    test('floor scaling is smooth and capped at deep floors', () {
      final a = FloorBalanceProfile.calculate(floor: 10, recentDeaths: 0, recentKills: 0);
      final b = FloorBalanceProfile.calculate(floor: 11, recentDeaths: 0, recentKills: 0);
      final deep = FloorBalanceProfile.calculate(floor: 999, recentDeaths: 0, recentKills: 1000);
      expect(b.enemyHp - a.enemyHp, lessThan(.2));
      expect(deep.enemySpeed, lessThanOrEqualTo(1.16));
      expect(deep.bossHp, lessThanOrEqualTo(2.8));
    });
  });
}
