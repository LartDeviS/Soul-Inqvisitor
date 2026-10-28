import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Story boss profiles', () {
    test('each operation boss has a distinct identity and combat profile', () {
      final profiles = StoryBossProfile.all.values.toList();
      expect(profiles, hasLength(21));
      expect(profiles.map((p) => p.title).toSet(), hasLength(21));
      for (final profile in profiles) {
        expect(profile.healthMultiplier, greaterThan(0));
        expect(profile.movementMultiplier, greaterThan(0));
        expect(profile.attackIntervalMultiplier, greaterThan(0));
        expect(profile.damageTakenMultiplier, greaterThan(0));
      }
    });

    test('attack sequences stay within the five supported telegraph patterns', () {
      for (final profile in StoryBossProfile.all.values) {
        for (var phase = 1; phase <= 3; phase++) {
          for (var index = 0; index < 30; index++) {
            expect(profile.attackModeFor(phase, index), inInclusiveRange(0, 4));
          }
        }
      }
    });

    test('profile attack sequences repeat deterministically', () {
      final profile = StoryBossProfile.forKind(StoryBossKind.archiveGuardian);
      expect(profile.attackModeFor(1, 0), profile.attackModeFor(1, 3));
      expect(profile.attackModeFor(2, 1), profile.attackModeFor(2, 5));
    });
  });
}
