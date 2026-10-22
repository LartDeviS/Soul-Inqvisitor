# Checkpoint 9 — Stage IV: Progression and Lore

## Added
- Enemy dossiers for ten existing enemy IDs: origins, weaknesses, tactics, study rewards.
- Investigation state with evidence collection, witness interrogation, and two meaningful conclusions: rapid purge or preserve evidence.
- Ordo reputation for Malleus, Hereticus and Xenos, including threshold-based order unlocks.
- Relic catalog with explicit upside/downside multipliers and risk tags.
- Branching contract definitions with selectable routes, objectives, conditions, consequences and rewards.
- Campaign consequence ledger tracking destroyed evidence, saved/lost witnesses, recovered terminals and purged sectors. The ledger changes the next-briefing text and availability flags.
- `LoreProgressionPanel`, a reference UI for dossiers, relics and contract branches.
- Unit tests covering decision outcomes, reputation, relic trade-offs, branching and campaign consequence logic.

## Integration notes
The domain layer is exposed by `InquisitorExpansionSystems` and included in its save JSON. Existing legacy Flame gameplay remains in `main.dart`; the new APIs are callable from mission objective, evidence, dialogue, relic selection and end-of-mission callbacks. This checkpoint establishes the persistent systems and reference UI; it does not automatically create in-world evidence objects or dialogue scenes unless those legacy components are wired to the new callbacks.

## Validation
Archive integrity is checked. Flutter/Dart are not installed in this environment, so `flutter analyze`, `flutter test` and APK compilation have not been run here. Run the repository's GitHub Actions workflow and use its log as the source of truth for compile validation.
