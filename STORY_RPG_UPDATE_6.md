# Soul of the Inquisitor — Story RPG Update 6

## Timed battlefield story crises

Update 6 adds one optional, timed crisis to each of the three campaign operations:

- **Operation «Тишина в эфире»** — rescue a witness before the signal is suppressed. Success sets `witness_protected` and opens the existing witness route.
- **Operation «Груз без печати»** — reach and preserve the cargo manifest before evidence is destroyed. Success sets `cargo_evidence_preserved` and unlocks the additional `submit_preserved_manifest` story choice.
- **Operation «Архив под пеплом»** — extract the trapped archivist before the perimeter collapses. Success sets `archive_archivist_rescued` and unlocks the `testify_with_archivist` choice.

Each event has a visible countdown, a pulsing marker and a warning color when ten seconds remain. Touching the marker completes the event. Letting its timer expire records a distinct failure outcome, increases the alarm, and removes the event from the field. Success grants requisition and investigation evidence. Outcomes are stored in existing campaign flags, so no save-schema migration is required. Retrying an operation clears only the timed-crisis outcome flags for these three events.

## Changed files

- `lib/main.dart` — event placement, timer/marker component, event resolution rewards and chronicle entries.
- `lib/game/missions/story_campaign.dart` — persistent event outcomes and two additional branching choices.
- `test/story_crisis_events_test.dart` — tests for success, failure, duplicate resolution, retry reset and narrative unlocks.

## Verification status

Archive integrity is checked. Flutter/Dart SDK is not installed in this environment, so `flutter analyze`, `flutter test` and APK build were not run. Run the repository's GitHub Actions workflow to validate compilation and produce the APK.
