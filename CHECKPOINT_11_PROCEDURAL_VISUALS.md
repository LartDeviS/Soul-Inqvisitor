# Checkpoint 11 — Procedural Visual Pass

All new visual elements are drawn at runtime with Flutter Canvas/Flame components; no external textures, sprites, models or image assets were added.

Implemented in this checkpoint:
- Biome-tinted ambient light, subtle arena vignette and pulsing light pools.
- Weapon-specific muzzle flash silhouettes for ballistic, plasma, flame and warp weapons.
- Additional deterministic floor micro-detail: hatches, rivets, hazard marks and cracks.
- Short-lived hit/explosion burst particles and spark strokes.
- Animated Inquisitorial ritual seals in ritual, shrine and warp-ruin sectors.
- Deterministic procedural environmental decoration pass.
- Dash afterimages while the player moves during an active dash.
- Dynamic enemy health bars, elite armor strips, player vitality/armor rings and segmented boss health/phase bars.

Validation note: this archive was checked structurally after editing, but Flutter/Dart SDK was not available in the editing environment. Run `flutter analyze`, `flutter test`, and the GitHub Actions APK build before treating the checkpoint as verified.
