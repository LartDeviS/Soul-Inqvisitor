# Checkpoint 4 — Ordo active abilities and combat visuals

## Implemented in this source snapshot

- Added an Ordo-only HUD action button (`O`) for Malleus and Hereticus characters.
- **Ordo Malleus — Exorcism Pulse**: 190-unit radial pulse, stronger damage against Bloodletters/Chaos Spawn, slow effect, 4-second damage ward, 13-second cooldown.
- **Ordo Hereticus — Inquisitor's Verdict**: targets the nearest enemy within 360 units, stronger damage against cultist/psyker-like human enemies, slow effect, 11-second cooldown.
- Added separate procedural Canvas effects: expanding Ordo pulse, red judgment beam, passive unlocked-skill halo, and cooldown ring/countdown over the HUD button.
- Added a description card for each active ability to the Skills screen.
- Added a visible pulse and notification when an Ordo passive skill is unlocked during a run.
- Cooldowns tick down in the existing combat update loop. The Malleus ward reduces incoming damage while active.
- The active ability HUD is recreated on level and arena transitions.

## Validation status

- Source changes and ZIP integrity are checked.
- Flutter SDK was not available in the editing environment, so `flutter analyze`, `flutter test`, and `flutter build apk --debug` have **not** been executed here.
- The repository's GitHub Actions workflow already runs those three checks and uploads the debug APK if they pass.

## Manual smoke test after GitHub Actions succeeds

1. Start a run as Ordo Malleus. Confirm the purple `O` button appears.
2. Press `O` near enemies: the violet pulse should expand, nearby enemies should take damage/slow, and the player should receive a short ward.
3. Press `O` again before 13 seconds: the ability should not activate. Confirm the yellow cooldown ring and number decrease.
4. Start as Ordo Hereticus. Confirm the red `O` button and red judgment beam appear; the nearest enemy in range should take damage and slow.
5. Unlock a passive skill in the Skills screen. Confirm the unlock notification/pulse appears during a run and the passive halo continues periodically.
6. Transition to another floor and to arena mode; verify the ability button and cooldown overlay do not duplicate or disappear.
