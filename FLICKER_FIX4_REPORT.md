# Soul of the Inquisitor — Flicker Fix 4

## Root cause addressed

The active-game `InquisitorGame.update()` loop called `camera.follow(player)` every frame. In Flame, camera following is configured through a follow effect; repeatedly reconfiguring it during the frame loop can destabilize camera tracking and make the arena appear to jump while touch controls are held and the player is firing.

## Change

- Removed the per-frame `camera.follow(player)` call from `InquisitorGame.update()`.
- Removed the per-frame assignment `camera.viewfinder.zoom = currentZoom` from the same loop. Zoom remains applied when the user changes zoom and when the game initializes the HUD/player.
- Kept the single `camera.follow(player)` call in `_setupHudAndPlayer()`.
- Kept firing, aiming, movement, cooldown visuals, damage and combat logic unchanged.

## Validation

- Static source inspection confirms there is one executable `camera.follow(player)` call, in `_setupHudAndPlayer()`.
- Static source inspection confirms the active frame loop no longer rewrites the camera zoom transform.
- Flutter/Dart SDK is unavailable in this environment, so `flutter analyze`, tests, and APK compilation could not be run here. Build and verify through GitHub Actions and on the target Android device.
