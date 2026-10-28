# Soul of the Inquisitor — Story RPG Update 2: Field Operations

## Scope

The narrative investigation is now linked to the existing action-run lifecycle. Three investigation scenes offer optional field operations. Starting an operation launches the existing combat run; victory records its success flag and a requisition reward, while defeat or abandonment records a failed attempt without resetting the investigation. Success unlocks additional choices, including a new tactical-justice ending.

## Files changed

- `lib/game/missions/story_campaign.dart` — operation catalog, active operation state, attempts, success/failure persistence, new branch and ending.
- `lib/main.dart` — field-operation panel and deploy button; victory, defeat and abandonment resolve the active operation.
- `lib/game/inquisitor_game.dart` — expansion payload schema advanced to 7.
- `lib/saves/save_migration.dart` — schema migration updated.
- `test/story_campaign_test.dart` — operation lifecycle and retry tests.

## Important gameplay limitation

The field operations currently launch the existing full action run. Their narrative outcomes and rewards are connected, but each operation does not yet have its own custom map, bespoke enemy composition, or unique objective tracker. That is a sensible next step after build verification.

## Verification

This environment has no Flutter/Dart SDK. `flutter analyze`, `flutter test`, and `flutter build apk --debug` were not run. Build success is not claimed. Run the project's GitHub Actions workflow and share the complete log if compilation fails.
