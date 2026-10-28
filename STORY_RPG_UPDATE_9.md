# Soul of the Inquisitor — Story RPG Update 9

## Sector stability and ally network

This update extends the existing consequence system without adding persistent fields or changing the save schema.

- The investigation screen now shows a derived **Sector Status** score from 0 to 10, a status label, and the active ally/evidence network.
- Sector status is calculated from existing campaign flags: protected witness, preserved cargo evidence, rescued archivist, exposed curator, submitted complete dossier, and purged locations.
- Archive assault support now recognizes three sources of intelligence: Deacon Vael, the preserved cargo manifest, and Archivist Kastor. Each source lowers the chance of random elite reinforcement and adds 8 requisition on a successful operation, for up to +24 with all three sources.
- The effects are derived from existing flags, so previous saves remain compatible.
- Added unit tests for baseline status, positive/negative outcomes, full three-source support, and save/load compatibility.

## Files changed

- `lib/game/missions/story_campaign.dart`
- `lib/main.dart`
- `test/story_campaign_sector_status_test.dart` (new)
- `STORY_RPG_UPDATE_9.md` (new)

## Verification

The ZIP archive was checked for integrity. Flutter/Dart SDK is not available in the packaging environment, so `flutter analyze`, `flutter test`, and APK build were not run here. Run the existing GitHub Actions workflow to verify compilation.
