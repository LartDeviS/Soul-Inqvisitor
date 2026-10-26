# Checkpoint 15 — Combat Performance, Character Bounds & Gear Visuals

## Changes

- Rate-limited player bullet trails to at most one segment per 45 ms and enemy bullet trails to one per 55 ms. This reduces temporary Flame component churn during automatic fire and dense enemy volleys.
- Cached the static HUD control-label `TextPainter` instead of constructing and laying it out every render frame.
- Expanded the player's render component bounds to fit the full character and long weapon silhouette while retaining the existing gameplay hitbox radius.
- Made equipped armor select its silhouette from concrete item IDs/names before set/rarity fallbacks. Unknown armor IDs use a stable deterministic pattern selection.
- Made armor base material color and trim color derive from the equipped item and set, with a deterministic per-item tint so items from the same set can look different. No generated image textures were added; armor remains Canvas geometry.

## Validation

- Source checks confirm trail throttles, cached HUD painter, larger player visual bounds, item-specific armor palette and deterministic silhouette fallback are present.
- ZIP integrity check passed after packaging.
- Flutter/Dart SDK was not available in the build environment, so `flutter analyze`, `flutter test`, and APK compilation were not run.

## Rendering note

The current joystick and action buttons are Flame viewport components, so they still share Flame's render loop. The changes above reduce the frame-time spikes that can cause visible flicker, but they do not give the controls a truly independent render scheduler. That requires moving the HUD visuals to Flutter overlay widgets while preserving pointer input routing.
