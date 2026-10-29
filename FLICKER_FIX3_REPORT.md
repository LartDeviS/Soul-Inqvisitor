# Soul of the Inquisitor — Flicker Fix 3

## What the supplied recording shows
The on-screen control cluster stays in a fixed position while the arena viewport changes apparent scale/visible area during combat. This points to camera zoom animation rather than the control buttons themselves being rebuilt.

## Change
- Disabled `triggerCinemaZoom()` animation; it now restores `currentZoom` immediately.
- During the game update, forcibly keep `camera.viewfinder.zoom = currentZoom` and clear `cinemaZoomTimer`.
- Kept the previous fixes that disable positional camera shake and reduce attack-stick visual overlap.

## Expected result
The arena should no longer pulse in and out during combat; screen-space control positions remain fixed. Cinematic zoom effects are intentionally disabled.

## Verification
Archive integrity can be checked, but Flutter/Dart SDK is not available in this environment, so `flutter analyze` and APK compilation were not run here. Run GitHub Actions and test the resulting APK on the device.
