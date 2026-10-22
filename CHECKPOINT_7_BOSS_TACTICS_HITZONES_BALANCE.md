# Checkpoint 7 — Boss Tactics, Hit Zones & Floor Balance

## Included
- `lib/game/enemies/boss_tactics.dart`: themed attack catalogue and telegraph/active/recovery state machine.
- `lib/game/enemies/boss_weak_spots.dart`: normalized hit zones for core, head, limb and armor; weak spots can require the exposed phase.
- `lib/game/balance/floor_balance_profile.dart`: capped floor-based enemy HP, damage, speed, spawn and boss-HP multipliers.
- `InquisitorExpansionSystems` exposes `floorBalance`, `bossAttackWarning`, `bossAttackResolved` and `resolveBossHit(...)`; `startBoss` initializes the attack runtime.
- Unit tests cover attack selection/timing, hit-zone multipliers and smooth/capped scaling.

## Important integration note
This checkpoint adds and wires the systems into the expansion/domain facade. The existing legacy Flame boss renderer and collision callbacks must call `resolveBossHit` with normalized sprite-relative hit coordinates and render `bossAttackWarning`/the active attack geometry for full in-game visual behavior. This archive is not represented as a verified APK: run `flutter analyze`, `flutter test`, and `flutter build apk --debug` in GitHub Actions.

## Suggested attack visuals
- Warp nova: expanding ring around the boss.
- Sweeping beam: rotating sector warning.
- Charge: line/rectangle along the charge vector.
- Summoning rift: pulsing circle on target ground.
- Ground slam: inner-radius warning circle.
