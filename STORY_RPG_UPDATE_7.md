# Soul of the Inquisitor — Story RPG Update 7

## Persistent consequences and a complete-dossier ending

Update 7 makes the consequences of earlier decisions visible in the investigation UI and adds a rare final route requiring the player to preserve all three evidence/personnel lines:

- protect Deacon Vale during the station operation or later choose to protect him during interrogation;
- preserve the cargo manifest during the timed cargo crisis;
- rescue archivist Kastor during the archive crisis;
- collect the sealed order, missing-person list, and cargo manifest.

When every condition is met, `submit_complete_dossier` becomes available at `archive_confrontation`. It leads to the new ending `ending_complete_dossier`, where the witness, manifest, and archivist corroborate one another. The choice adds persistent flags `complete_dossier_submitted`, `curator_exposed`, and `all_witnesses_protected` and grants 75 requisition.

The investigation screen now displays a consequence panel based on persistent campaign flags. It identifies protected/coerced/lost witness outcomes, whether the manifest chain survived, whether the archivist was rescued, and whether the complete dossier was submitted. Existing save serialization already persists these flags and ending IDs, so no save-schema migration is required.

## Changed files

- `lib/game/missions/story_campaign.dart` — consequence summary and new ending/choice.
- `lib/main.dart` — consequence panel in the story investigation UI.
- `test/story_campaign_consequences_test.dart` — route unlock, consequence summary, and save round-trip tests.

## Verification status

The ZIP archives are checked for integrity. Flutter/Dart SDK is not installed in this environment; `flutter analyze`, `flutter test`, and APK build were not run. Run the GitHub Actions workflow to validate compilation and build the APK.
