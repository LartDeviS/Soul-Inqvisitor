# Soul of the Inquisitor — Update 19

## Дело IX — «Личность под печатью»

Update 19 continues from the Case VIII ending and reveals the coordinator's identity: Magister Severian Voss, an administrator officially declared dead seven years earlier.

### New operation
- **Operation:** «Личность под печатью»
- **Location:** command node «Слепой престол»
- **Boss:** Magister Severian Voss
- **Required field objective:** recover the identity ledger (`case9_identity_ledger_secured`)
- **Combat requirements:** 11 kills and defeat the boss

### Three strategic outcomes
1. **Capture Voss alive** — preserve the network and evidence for a trial.
2. **Destroy the network** — prevent further forged orders but burn part of the evidence.
3. **Repurpose the network** — seize its infrastructure for the Inquisition at a corruption cost.

### Changed files
- `lib/game/missions/story_campaign.dart`
- `lib/game/missions/story_boss_profiles.dart`
- `lib/main.dart`
- `test/story_boss_profiles_test.dart`
- `test/story_campaign_case9_test.dart` (new)

Save schema remains unchanged. Flutter/Dart tests and APK build must be run through the repository's GitHub Actions because Flutter/Dart SDK is unavailable in the preparation environment.
