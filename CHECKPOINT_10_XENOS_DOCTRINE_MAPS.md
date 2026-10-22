# Checkpoint 10 — Ordo Xenos Doctrine & Expanded Maps

## Ordo Xenos doctrine
- Active ability `Ауспекс`: emits a cyan pulse around the player, marks enemies in range for 6 seconds and slows them briefly. Marked enemies take +25% damage from the player. Cooldown: 15 seconds.
- SP passive 1 — `Тактическая ксенология`: +10% damage against Orks, Tyranids, Necrons and Genestealers.
- SP passive 2 — `Ауспексная маркировка`: unlocks after Tactical Xenology; mark radius increases from 285 to 330, duration from 6 to 8 seconds, and marked targets take +40% damage.
- SP passive 3 — `Трофейная ксенотехника`: unlocks after Auspex Mastery; Xenos kills grant +2 scraps, champion Xenos +4.
- All three passive skills cost 1 SP and are stored by the existing OrdoDoctrine JSON serializer. Existing save fields remain unchanged.

## Procedural map variety
Added three deterministic layouts to the existing five:
- `spiral`: broken spiral cover, alternating lanes.
- `fractured`: irregular obstacle islands and several crossing routes.
- `killbox`: alternating firing lanes and cover rows.

Layout selection now also factors in biome, so the same floor/level sequence can vary more across biomes. Obstacle placement keeps a deployment safety radius and skips guaranteed travel paths.

## Lore basis
The design takes inspiration from the Ordo Xenos' established remit to catalogue and study alien species, detect their influence, and adapt tactics to the threat; its Chamber Militant is the Deathwatch. The specific ability names, numerical bonuses, SP tree and map-generation rules are original gameplay adaptations, not canonical tabletop rules.

## Validation
- Added unit tests for Xenos doctrine damage, serialization and branch catalog count.
- ZIP integrity checked after packaging.
- Flutter/Dart CLI was not available in the packaging environment, so `flutter analyze`, `flutter test` and APK build were not run here. Run GitHub Actions to verify compilation.
