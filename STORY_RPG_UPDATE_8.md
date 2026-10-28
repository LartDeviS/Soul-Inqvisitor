# Soul of the Inquisitor — Story RPG Update 8

## Strategic consequences across later operations

Update 8 carries two prior campaign decisions into later combat deployments. Protecting Deacon Vale provides intelligence for the cargo interception; preserving the cargo manifest gives the archive assault a verified supply route. When both are preserved, the archive operation receives rank-2 strategic support.

The operation card displays the support available before deployment. Support reduces the random elite-enemy chance by 2.5 percentage points per support rank (the chance is clamped to 3–50%; forced champions and boss requirements are unchanged). Successfully completing a supported operation awards an additional 8 requisition per support rank, on top of the existing 25 requisition operation reward.

The support state is derived from existing persistent campaign flags; no save-schema migration is required. A new pure-Dart test file covers support rank, bonus calculations, summaries, and the no-support case.

## Changed files

- `lib/game/missions/story_campaign.dart` — support rank, summary, and reward bonus derived from saved flags.
- `lib/main.dart` — elite spawn probability adjustment, successful-operation support reward, and support panel in the campaign UI.
- `test/story_campaign_strategic_support_test.dart` — strategic-support tests.

## Verification

ZIP integrity is checked after packaging. Flutter/Dart SDK is not available in this environment, so `flutter analyze`, `flutter test`, and APK build have not been run. Validate by running the repository's GitHub Actions workflow.
