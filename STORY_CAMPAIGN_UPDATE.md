# Soul of the Inquisitor — Story RPG Update

## Added

- A persistent branching investigation, **The Grey Candle Case**, with three investigation chapters and four endings, including a special witness-protection route.
- Evidence collection with duplicate prevention and evidence-gated dialogue/decisions.
- Witness interrogation with protection, coercion, or execution routes.
- Consequence-bearing choices that modify requisition and Warp corruption.
- Campaign flags, decision history, evidence, current scene, and ending persisted in the expansion save payload.
- A new full-screen story campaign overlay reachable from the main menu and Inquisition Hub.
- Save schema migration to version 6; existing saves receive a default opening scene.
- Unit tests for evidence gates, branching, persistence, endings, and malformed save input.

## Files added

- `lib/game/missions/story_campaign.dart`
- `test/story_campaign_test.dart`
- `STORY_CAMPAIGN_UPDATE.md`

## Files changed

- `lib/main.dart`
- `lib/game/inquisitor_game.dart`
- `lib/saves/save_migration.dart`

## Verification status

This environment does not have Flutter or Dart installed, so `flutter analyze`, `flutter test`, and `flutter build apk --debug` were not run. The project must be verified by GitHub Actions. Build success is not claimed.
