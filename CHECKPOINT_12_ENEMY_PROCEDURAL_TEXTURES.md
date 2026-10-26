# Checkpoint 12 — Enemy Procedural Textures

## Goal
Improve the readability and material detail of every regular enemy type using only Flutter Canvas geometry. No raster textures, sprites, downloaded art, or new external assets are used.

## Included
- A shared `EnemyTextureRenderer` material pass, called by the live `Enemy.render` path.
- Dedicated vector detail for cultists, shielded troops, hounds, brutes, plague bearers, Bloodletter-style daemons, Orks, Tyranid gaunts, Genestealers, Necron Warriors/Immortals, and Chaos Spawn.
- Armor edge highlights, rivets, painted panels, cloth seams, purity/chaos markings, chitin plates, claws, horns, pustules, skeletal ribs, gauss glow, scratches and animated pulses.
- Damage-aware wear and champion-specific rune/halo treatment.
- Extra detail passes for the mini-boss and rival Inquisitor.
- A Flutter test that calls the renderer for every `EnemyType` value.

## Lore-inspired visual language
- Orks: green hide, crude mismatched plates, checker paint and tusks.
- Tyranids/Genestealers: layered chitin, hooked talons and bioluminescent details.
- Necrons: skeletal living-metal ribs and cold cyan/green energy seams.
- Chaos cultists/daemons: ragged robes, forbidden sigils, horns and warp-colored glows.
- Plague entities: diseased green hide, pustules and corroded markings.
- Heavily armored enemies: segmented plates, rivets and heraldic stripes.

These are original procedural approximations inspired by broad faction motifs, not copies of official artwork.

## Validation status
- Archive integrity and source-level checks should be run before release.
- `flutter analyze`, `flutter test`, and Android APK compilation must be run in GitHub Actions; they were not executed in the editing environment.
