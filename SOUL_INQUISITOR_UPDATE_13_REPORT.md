# Soul of the Inquisitor — Update 13 report

## Implemented: «Последний выбор у узла»

After successfully completing the external relay operation, the player now makes one of three consequential choices:

1. **Capture the operator alive** — preserves a witness and opens the interrogation direction for the next case; +24 requisition.
2. **Extract the data and leave the relay intact** — preserves transmission logs and leaves the node available for observation; +20 requisition.
3. **Destroy the relay** — suppresses the signal but loses the operator and most original logs; +10 requisition and −2 corruption.

Each choice sets distinct campaign flags and opens its own ending scene. The old `ending_case4_expedition` node remains in the story graph as a compatibility destination for saves from Update 12.

## Files changed

- `lib/game/missions/story_campaign.dart` — post-operation choice node, three distinct endings, legacy node retained.
- `test/story_campaign_outer_relay_test.dart` — tests for all branches, gating, and save/load.
- `test/story_campaign_sequel_test.dart` — updated expected flow after completing the field operation.
- `STORY_RPG_UPDATE_13.md` — update notes.
- `SOUL_INQUISITOR_UPDATE_13_REPORT.md` — this report.

No save schema version change was required. Branch state uses existing `flags`, `decisions`, `currentNodeId`, and `endingId` fields.

## Validation status

Static graph check: all story node IDs are unique and all `nextNodeId` references point to existing nodes. ZIP integrity is checked after packaging.

Flutter/Dart SDK is unavailable in the preparation environment, so `flutter analyze`, `flutter test`, and APK build were not executed. Run the existing GitHub Actions workflow to validate the actual build.
