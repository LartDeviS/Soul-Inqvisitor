# Checkpoint 14 — Procedural weapons and synthesized audio

- Added a detail pass to the player weapon renderer: casing bevels, rivets, vents, cooling fins, energized coils, emitter rings and powered-melee rune marks. Everything is drawn with Flutter Canvas.
- Added code-drawn carried weapons to ranged enemy silhouettes: cultist lasguns, sniper long-las, flamer tanks/nozzle, Necron gauss tubes, psyker warp focus and an improvised Ork gun. Enemy weapon direction tracks the player.
- Player ranged attacks now choose a distinct synthesized WAV by weapon family; ranged enemies trigger matching sound families when they attack.
- Added 23 short mono PCM WAV clips (a unique sound for each of the 19 ranged weapons, plus enemy sound families) generated locally from oscillator sweeps, shaped noise and transient envelopes. No third-party game recordings or image/audio assets are used. The sound design takes broad genre cues (sharp bolter crack, thin las report, heavy shotgun blast, rising plasma whine, warp shimmer, melta roar, flamer rush), not copied samples.

Validation: ZIP integrity and source-level checks are run by the packaging script. Flutter/Dart SDK availability is required to run `flutter analyze`, tests and an APK build; these are not claimed unless executed in the build environment.


## Sound-design reference notes

The procedural sound direction follows general principles described by Fatshark's Darktide sound team: avoid generic “pew-pew” sci-fi clichés; use distinct timbre, pitch, duration and dynamics; make las-weapons feel electrically heated, plasma feel liquid/analog, and warp sounds pulse like unstable circuitry. For game readability, sniper shots should be distinct and enemy cues should not all occupy the same sonic space. These are design references only; the included audio was synthesized from scratch and does not contain samples from those games.

References:
- Fatshark, “The Sounds of Darktide” (2024): https://www.playdarktide.com/news/the-sounds-of-darktide
- Fatshark, “New Weapons — Grim Protocols” (2024): https://www.playdarktide.com/news/new-weapons-grim-protocols
- Tim Willits on oversized, emphatic weapon sound design in Space Marine II (Gamereactor, 2024): https://www.gamereactor.eu/heres-how-every-gun-sounds-so-devastating-in-warhammer-40000-space-marine-ii-1429413/
