import 'package:flutter_test/flutter_test.dart';
import '../lib/game/balance/adaptive_difficulty.dart';
import '../lib/game/enemies/boss_encounter.dart';
import '../lib/game/enemies/enemy_type.dart';
import '../lib/game/missions/operation_modifiers.dart';
import '../lib/game/weapons/weapon_data.dart';
import '../lib/game/weapons/weapon_synergy.dart';

void main() {
  group('Roguelite combat systems', () {
    test('new enemy archetypes are present in the shared catalog', () {
      expect(EnemyTypeData.all.any((e) => e.id == 'cult_sniper'), isTrue);
      expect(EnemyTypeData.all.any((e) => e.id == 'chaos_bulwark'), isTrue);
      expect(EnemyTypeData.all.any((e) => e.id == 'tyranid_stalker'), isTrue);
      expect(EnemyTypeData.all.any((e) => e.id == 'warp_summoner'), isTrue);
    });
    test('boss exposes a weak spot in the exposed phase', () {
      final boss = BossEncounter(bossId: 'warp_echo', maxHp: 500);
      boss.update(1.3); // telegraph -> assault
      boss.update(5.1); // assault -> exposed
      expect(boss.isWeakSpotExposed, isTrue);
      boss.applyDamage(900);
      expect(boss.current.phase, BossPhase.defeated);
    });
    test('operation modifier roll is deterministic with seed', () {
      final a = OperationModifierSystem().roll(seed: 42);
      final b = OperationModifierSystem().roll(seed: 42);
      expect(a.id, b.id);
    });
    test('weapon synergy applies burning and armor break', () {
      final result = WeaponSynergySystem.resolve(
        weaponType: DamageType.flame, targetStatuses: {CombatStatus.armorBroken},
        targetFaction: 'cult', armorPiercing: true,
      );
      expect(result.appliedStatuses, contains(CombatStatus.burning));
      expect(result.appliedStatuses, contains(CombatStatus.armorBroken));
      expect(result.damageMultiplier, greaterThan(1));
    });
    test('adaptive difficulty is capped', () {
      final result = AdaptiveDifficulty.calculate(floor: 99, recentDeaths: 0, recentKills: 10000);
      expect(result.hpMultiplier, lessThanOrEqualTo(1.9));
      expect(result.damageMultiplier, lessThanOrEqualTo(1.65));
      expect(result.spawnMultiplier, lessThanOrEqualTo(1.5));
    });
  });
}
