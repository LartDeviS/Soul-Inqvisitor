# Checkpoint 13 — Enemy silhouettes, full Codex, procedural armor visuals

## Changes
- Expanded the Codex to enumerate every `EnemyType.values` entry automatically; new enemy enum values will appear in the Codex list rather than silently missing.
- Added Russian dossiers, faction labels, color accents and icons for all 17 current enemy types.
- Increased procedural armor distinction: separate material palettes, shoulder widths, chest construction, helmet silhouettes, visors, crests, hoses, purity-seal ribbons, rosette details and Terminator abdominal/shoulder plates.
- The player renderer already reads `game.activeArmor`; the revised renderer makes that selected armor change geometry and palette in the live character render. Existing save field `activeArmor` and forge selection flow are retained.
- All new visual elements are drawn with Flutter Canvas; no external textures, sprites or images added.

## Validation
- ZIP integrity and source-level structural checks performed.
- Flutter SDK was not available here; `flutter analyze`, `flutter test` and Android APK build were not executed. Run these in GitHub Actions before treating the build as verified.

- Codex now also includes all 10 profiles from the separate `EnemyTypeData` expansion roster, with faction, archetype, ID and dossier.
- Equipped gear in the `armor` slot now selects a matching procedural armor visual profile (Deathwatch, Ordo Malleus, Inquisitorial, rarity-based and ID-based variants); if no gear armor is equipped, the Forge-selected `activeArmor` remains visible.
