# Checkpoint 6 — Enemy & Boss Runtime Integration

## Runtime changes

- Enemy spawning now assigns a deliberate summoner role to some cult psykers from floor 4 onward, rather than restricting summoning behavior to randomly rolled champions.
- Summoners use the existing cult-psyker attack/AI path, summon two adds at half health, and receive a purple procedural warp-ring visual. Their attack wind-up uses a distinct warp warning color.
- Existing sniper, heavy/armored, and genestealer/assassin archetypes retain their dedicated AI paths: long-range aimed fire with a visible wind-up, high armor/health melee pressure, and fast pounce/bleed attacks respectively.
- Bosses now retain a readable weak-point vulnerability window after a telegraphed attack resolves in phase 2 and later (1.4 seconds, 1.8 seconds in phase 3+). Damage during the window receives the existing 22% weak-point bonus. The window is cleared when the boss transitions phases.
- Existing boss attack telegraphs (circle, cone, cross) and projectile resolution remain part of the live Flame game loop.

## Balance notes

- Summoner chance is 24% of non-champion cult-psyker spawns on floor 4+, in addition to champion affixes.
- Summoner minions remain two melee enemies, each scaled to 25% of the summoner's maximum health.
- Boss vulnerability rewards a successful dodge and creates a short damage window without changing base boss HP.

## Validation

This archive was checked for ZIP integrity. Flutter/Dart compilation and device gameplay tests were not run in the authoring environment; run `flutter analyze`, `flutter test`, and `flutter build apk --debug` in GitHub Actions before treating the checkpoint as release-ready.
