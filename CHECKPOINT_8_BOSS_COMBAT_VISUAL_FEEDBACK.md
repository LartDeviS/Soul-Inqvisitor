# Checkpoint 8 — Boss combat visual feedback

This checkpoint builds on Checkpoint 7 and connects the boss telegraph and hit-zone mechanics to the existing Flame combat loop.

## Included

- Boss telegraph zones now display a prominent Russian `УКЛОНИСЬ!` warning in the marked danger area.
- Existing boss-specific circle, cone, and cross telegraphs remain the dodge cues; the warning is rendered directly on the Flame canvas.
- A dash that avoids a boss projectile produces an `УКЛОНЕНИЕ` combat callout.
- Projectile and melee hits against the supported boss types are classified by normalized impact position: head, core, limb, or armor.
- Head, limb, armor, and exposed/closed core contacts use different damage multipliers and display a matching result label.
- Boss sprites show subtle procedural rings for the head, core, and limb target regions. The primary Boss core ring becomes prominent while its weak spot is exposed.
- Added unit tests for exposed core, closed core, head, and limb hit-zone results.

## Important integration details

- The existing attack AI continues to own its attack timing and actual attack geometry; this change makes its existing telegraph clearer rather than replacing the AI.
- The current `Boss` class has a phase-aware exposed core. Other legacy boss classes show the target-zone overlay but do not all expose a shared weak-spot phase, so their core is treated as armored.
- The impact point uses Flame collision intersection data when available and falls back to the projectile position. Exact impact-point quality depends on the collider implementation.
- Damage labels are feedback indicators and can overlap when several hits land at once.

## Verification status

The archive is structurally validated, but Flutter/Dart are not installed in the file-generation environment. `flutter analyze`, `flutter test`, and APK compilation have **not** been run here. Please let GitHub Actions perform the actual build and tests before treating this checkpoint as a verified APK.
