# Soul of the Inquisitor — Checkpoint 2: Ordo Specialization

## Implemented in this source update
- Ordo doctrine model with six passive skills split between Ordo Malleus and Ordo Hereticus.
- Doctrine-aware damage calculation, including target-faction conditions and explanatory hit reasons.
- Five ammo profiles: standard, sanctified, armor-piercing, warp-stabilized and incendiary; compatibility is validated before selection.
- Four weapon rarity tiers: common, improved, relic and unique, with damage/cooldown/penetration modifiers.
- WeaponRuntime supports selecting ammo, rarity, effective damage, cooldown and armor penetration; both properties serialize with the weapon.
- Save schema migration v3 safely adds default doctrine/ammo/rarity values to older saves.
- Codex shows code-generated vector weapon glyphs and compatible ammunition/rarity metadata.
- Added automated tests for doctrine, ammo compatibility, rarity, serialization and migration.

## Important integration boundary
The new domain systems are wired into the expansion facade and damage calculator. Existing legacy combat code in `lib/main.dart` is very large and may still use its original weapon/projectile path; verify that path before claiming the doctrine/ammo/rarity bonuses affect every legacy shot. The Codex is descriptive; it does not itself unlock perks or change inventory.

## Validation
Run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug` in GitHub Actions. Flutter SDK was not available in the archive-editing environment, so no successful build is claimed here.
