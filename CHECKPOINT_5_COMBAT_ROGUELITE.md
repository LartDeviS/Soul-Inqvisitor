# Checkpoint 5 — Combat Roguelite

This checkpoint adds testable data/domain systems for the third roadmap stage:

- Four additional enemy types: cult sniper, armored Chaos elite, fast Tyranid stalker, and Warp summoner.
- A reusable boss phase controller with telegraph, assault, exposed weak spot, enrage, and defeat states.
- Operation modifiers: power outage, Warp surge, ambush, and emergency supply drop.
- Weapon/status synergies for burning, armor break, Warp marks, and stagger.
- Capped adaptive difficulty based on floor depth and recent kills/deaths.
- `InquisitorExpansionSystems` now exposes the modifier, boss, synergy and adaptive-difficulty systems and serializes the recent performance counters and active operation modifier.
- Automated tests cover the enemy roster, boss phases, deterministic modifiers, synergies and difficulty caps.

## Validation status

The archive is structurally valid. Flutter/Dart SDK was not available in the editing environment, so `flutter analyze`, `flutter test`, and APK compilation still need to be run in GitHub Actions. These systems are exposed through the expansion domain facade; wiring each behavior to every legacy Flame enemy/projectile component may require additional integration after inspecting the actual runtime path in `main.dart`.
