# Soul of the Inquisitor — Update 5: Story Boss Encounters

## Changes

- Added `lib/game/missions/story_boss_profiles.dart`, a data-driven catalog for three campaign bosses.
- Each of the three field operations now requires defeating its operation boss as well as completing its existing kill/evidence objectives.
- Completing the mandatory field evidence spawns the matching boss once per run:
  - `secure_station`: Смотритель вокс-станции — faster movement and signal-style aimed/cross attacks.
  - `intercept_cargo`: Каратель конвоя — more health, slower movement, higher resistance and heavy radial attacks.
  - `breach_archive`: Страж архива — faster attack cadence and mixed late-phase volleys.
- Story bosses use the existing boss phase, collision, telegraph and damage systems, with profile-specific health, movement, cadence and attack sequences.
- Added a distinct color aura and title above each story boss.
- Added `test/story_boss_profiles_test.dart` for profile uniqueness, attack mode bounds and deterministic sequences.

## Compatibility

No new persistent runtime state was introduced, so the save schema does not need to be bumped. Existing saves continue using schema 9.

## Limitations

- Bosses share the existing Boss base implementation and projectile types; the new profiles vary their combat parameters and attack sequence rather than adding bespoke animation assets or wholly new projectile physics.
- This environment does not have Flutter or Dart installed. `flutter analyze`, `flutter test` and `flutter build apk --debug` have not been run. Build success is not confirmed.
