# Soul of the Inquisitor — update notes

## Implemented in this patch

- The Codex page now uses one vertical scroll surface, so its sections can be browsed in portrait and landscape layouts instead of forcing the threat dossier list into a fixed-height region.
- Added six data-driven entries to `WeaponData`:
  - **Ordo Malleus:** Psycannon, Exorcist Incinerator, Nemesis Daemon Hammer.
  - **Ordo Hereticus:** Condemnor Boltgun, Purgatus Stake Crossbow, Inferno Pistol.
- Added procedural weapon glyphs drawn with Flutter `CustomPainter`; no external texture files or network downloads are required. Malleus glyphs use a warp-violet accent, Hereticus glyphs use a purgation-red accent, and general weapons use an aged-gold accent.
- Added Ordo affiliation to each weapon's Codex details.

## Lore and balance rationale

Malleus is the Ordo tasked with daemonic and Warp threats, so its additions emphasize anti-Warp piercing, area denial/burning, and a high-risk close-range daemon-hammer strike. Hereticus investigates heresy and hunts witches/rogue psykers; its additions emphasize a boltgun with a blessed anti-psyker stake, a dedicated stake crossbow, and a short-range melta sidearm. These are game-specific prototype values, not tabletop rules profiles.

## Validation note

The patch was made against the supplied ZIP snapshot. A Flutter SDK was not available in the editing environment, so `flutter analyze` and an Android APK build were not run here. Run the repository's GitHub Actions workflow after committing; if it fails, share the complete log and I can prepare a full-file correction.

## Next steps recommended

1. Connect the new entries to the actual combat/loadout selection path (the Codex itself remains a reference panel).
2. Add per-Ordo weapon unlocks and enemy-specific modifiers rather than only generic damage numbers.
3. Add a compact two-column Codex layout for wide screens and keep one scroll owner to avoid nested-scroll friction.
4. Add a small in-game playtest matrix for damage per second, ammo economy, range, and enemy archetypes.
