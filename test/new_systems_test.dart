import 'package:flutter_test/flutter_test.dart';
import '../lib/game/combat/wave_director.dart';
import '../lib/game/combat/enemy_ai_controller.dart';
import '../lib/game/missions/procedural_mission_generator.dart';
import '../lib/game/progression/codex_challenges.dart';
import '../lib/game/weapons/ballistics.dart';
import '../lib/game/weapons/relic_synergy.dart';
import '../lib/game/weapons/weapon_modifications.dart';
import '../lib/game/world/arena_hazards.dart';

void main() {
  group('New code-driven gameplay systems', () {
    test('wave director creates a paced wave after a clear', () {
      final director = WaveDirector(seed: 7);
      expect(director.update(1, livingEnemies: 0, pendingSpawns: 0, floor: 3).type, WaveDirectiveType.none);
      final next = director.update(1.2, livingEnemies: 0, pendingSpawns: 0, floor: 3);
      expect(next.type, isNot(WaveDirectiveType.none));
      expect(next.budget, greaterThanOrEqualTo(0));
    });

    test('AI chooses to retreat for a wounded ranged enemy at close range', () {
      final decision = EnemyAIController().decide(distance: 60, preferredDistance: 240,
        ranged: true, healthRatio: .1, windingUp: false, recovering: false, canRetreat: true);
      expect(decision.state, EnemyAIState.retreat);
      expect(decision.kite, isTrue);
    });

    test('procedural mission graph is connected and ends with a boss', () {
      final mission = ProceduralMissionGenerator().generate(seed: 420, floor: 5);
      expect(mission.isReachable, isTrue);
      expect(mission.hasBoss, isTrue);
    });

    test('ballistics reduces damage at long range', () {
      final close = Ballistics.resolve(baseDamage: 20, distance: 50, effectiveRange: 500,
        penetration: 1, targetArmor: 0, material: SurfaceMaterial.flesh);
      final far = Ballistics.resolve(baseDamage: 20, distance: 900, effectiveRange: 500,
        penetration: 1, targetArmor: 0, material: SurfaceMaterial.flesh);
      expect(far.damage, lessThan(close.damage));
    });

    test('relic synergies only activate when trigger and relic match', () {
      final system = RelicSynergySystem();
      final event = const CombatEvent(CombatEventType.criticalHit);
      expect(system.resolve(event, {'executioner_mark'}).single.id, 'executioner_cycle');
      expect(system.resolve(event, {}).isEmpty, isTrue);
    });

    test('weapon mods enforce compatibility and combine modifiers', () {
      final system = WeaponModificationSystem();
      final barrel = WeaponModificationSystem.catalog.firstWhere((m) => m.id == 'rifled_barrel');
      expect(system.equip(barrel, weaponTags: {'kinetic'}), isTrue);
      expect(system.combinedModifiers['damage'], .12);
      expect(system.equip(barrel, weaponTags: {'plasma'}), isFalse); // incompatible weapon tags are rejected
    });

    test('arena hazards can be damaged and saved', () {
      final system = ArenaHazardSystem();
      final hazard = system.add(HazardType.explosiveBarrel, x: 10, y: 10, health: 2);
      expect(system.hazardsAt(10, 10), hasLength(1));
      system.damage(hazard.id, 3);
      expect(system.hazardsAt(10, 10), isEmpty);
      final restored = ArenaHazardSystem()..loadJson(system.hazards.map((h) => h.toJson()).toList());
      expect(restored.hazards, hasLength(1));
      expect(restored.hazards.single.active, isFalse);
    });

    test('codex challenge progress is capped and reward cannot be claimed twice', () {
      final system = CodexChallengeSystem();
      system.record('bolter_kill', 500);
      expect(system.getCompleted('bolter_marksman'), isTrue);
      expect(system.claim('bolter_marksman'), 100);
      expect(system.claim('bolter_marksman'), 0);
    });
  });
}
