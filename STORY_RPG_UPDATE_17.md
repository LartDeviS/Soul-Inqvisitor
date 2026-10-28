# Soul of the Inquisitor — Update 17

## Дело VII — «Личность под печатью»

Update 17 continues each Case VI ending into a dedicated field operation. Existing save schema is unchanged; continuation uses the existing ending ID and campaign flags.

### Branches
- `ending_case6_registry_audit` → `case_07_dead_signatory`: recover a biometric identity key; boss: Хранитель биометрической печати; 9 kills.
- `ending_case6_mobile_pursuit` → `case_07_mobile_node`: disable a synchronization relay; boss: Охотник за синхронизатором; 8 kills.
- `ending_case6_supplier_trace` → `case_07_supply_convergence`: recover the original requisition; boss: Распорядитель реквизиций; 8 kills.

Each operation requires its field objective, required kill count, and operation boss before the story choice unlocks. Each branch has a dedicated epilogue and persistent flags.

### Changed files
- `lib/game/missions/story_campaign.dart`
- `lib/game/missions/story_boss_profiles.dart`
- `lib/main.dart`
- `test/story_boss_profiles_test.dart`
- `test/story_campaign_case7_test.dart`

### Validation
ZIP integrity and static story-graph checks are run during packaging. Flutter/Dart tests and APK build require the SDK and are not claimed unless run.
