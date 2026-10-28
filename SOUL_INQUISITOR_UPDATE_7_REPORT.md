Soul of the Inquisitor — Update 7 report

Implemented:
- Persistent consequence summary displayed on the investigation screen.
- New optional `submit_complete_dossier` choice at `archive_confrontation`.
- New ending node `ending_complete_dossier` requiring three persistent outcome flags and three pieces of evidence.
- Added tests for consequence summary, gating conditions, and save/load persistence.
- No save schema change.

Changed files:
- lib/game/missions/story_campaign.dart
- lib/main.dart
- test/story_campaign_consequences_test.dart
- STORY_RPG_UPDATE_7.md

Validation:
- Flutter/Dart are not installed here; analyze/tests/APK build were not run.
- ZIP integrity should be verified after packaging.
