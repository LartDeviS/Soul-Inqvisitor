# Soul of the Inquisitor — Story RPG Update 3: Field Missions

## Implemented in this update

- Story operations now have measurable objectives tied to actual enemy-death callbacks.
- Operation “Тишина в эфире” requires 12 confirmed kills.
- Operation “Груз без печати” requires 10 kills and at least one elite/champion kill. Its first floor guarantees a champion spawn.
- Operation “Архив под пеплом” requires 8 kills and one boss kill.
- Objective progress is shown in the in-game HUD during an active story operation.
- Victory only unlocks a story operation route when its required objectives were met. Completing a run without meeting the operation objective records a failed attempt and allows a retry.
- The first floor of each story operation uses a distinctive layout: corridors for the vox station, open yard for the cargo interception, chambers for the archive.
- Story deployments bias enemy composition to reinforce each operation's theme.
- Operation objective progress is serialized; root save schema advances to version 8 and story-campaign schema to version 3.
- Tests cover objective requirements, progress persistence, retry after failure, and route unlocking.

## Full replacement files

- `lib/game/missions/story_campaign.dart`
- `lib/main.dart`
- `lib/game/inquisitor_game.dart`
- `lib/saves/save_migration.dart`
- `test/story_campaign_test.dart`

## Verification

- ZIP integrity and static consistency checks are run when packaging this update.
- Flutter/Dart SDK is not available in the preparation environment, so `flutter analyze`, `flutter test`, and `flutter build apk --debug` are not run here.
- Run the existing GitHub Actions workflow before treating the APK as build-verified.

## Remaining limitations

- Story operations still run through the existing multi-floor action run. Their first floor has a distinct layout and enemy composition, but these are not yet separate bespoke maps with unique props, scripted encounters, and custom mission-ending screens.
- Mission goals are confirmed at the run's victory screen rather than ending the run immediately when the objective is achieved.
