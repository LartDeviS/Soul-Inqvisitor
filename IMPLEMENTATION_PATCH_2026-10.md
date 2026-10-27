# Soul of the Inquisitor — implementation patch (2026-10)

## Applied fixes

- Fixed vault-to-backpack transfer: a full backpack leaves the vault unchanged.
- Fixed equipment swapping: an incoming item is removed before the displaced item is returned, allowing swaps at full capacity.
- Added save normalization for inventory: safe numeric parsing, capacity clamping, slot validation, duplicate-ID prevention, and overflow preservation in the vault.
- Made `InquisitorExpansionSystems.inventory` the shared inventory state used by `EquipmentInventory`.
- Made `InquisitorExpansionSystems.progression` the shared progression state used by `InquisitorGame.progressionTrack`. Legacy save keys remain readable.
- Extracted `GameSave`, procedural effects, drawing helpers and enemy texture rendering into `lib/game/procedural_visuals.part.dart`, reducing the main entrypoint while preserving private access through Dart `part` semantics.
- Isolated corrupted high-score and save-list preferences so one malformed preference does not prevent those lists from loading.
- Added save schema migration to version 5 for the new systems.

## Added code-driven systems

- Wave pacing director with seeded randomness, elite/ambush/respite/boss directives, and serializable state.
- Enemy AI decision policy and integration into the legacy enemy movement logic.
- Range-based ballistic damage falloff, with existing armor resolution retained to avoid applying armor twice.
- Relic synergy catalog driven by combat events.
- Seeded procedural mission graph generator with reachability checks.
- Investigation evidence interaction model.
- Arena hazard models with save/load support.
- Data-driven weapon modification catalog with compatibility checks and aggregated modifiers.
- Servo-skull companion roles and cooldown-driven effects.
- Challenge mode catalog and codex challenge progression.
- Runtime performance monitor for FPS/frame-time/component-count sampling.

## Validation

New regression tests cover inventory loss/swap/load cases and the added domain systems. The current execution environment does not include Flutter or Dart, so `flutter analyze`, `flutter test`, and Android APK build could not be executed here. Run those commands in a Flutter-enabled environment before release.

## Follow-up integration notes

The new domain systems are available through `InquisitorExpansionSystems` and are serialized. Some systems (mission graph UI, investigation interaction zones, hazard rendering/interactions, weapon-mod UI, companion visuals, and challenge selection UI) still need dedicated player-facing overlay wiring. The legacy spawn queue remains authoritative, but arena wave transitions now consult the wave director for assault/ambush/elite/respite/boss-wave budgets and display a small procedural combat announcement. The first spawn in an elite wave is promoted to a champion. This avoids running a second independent spawn queue.
