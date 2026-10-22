# Checkpoint 9 build fix

Fixed the Dart compilation errors reported in `lib/main.dart` around lines 10301 and 10309.

The `MiniBoss` class accidentally referenced `phase` and `weakSpotTimer`, which are not members of `MiniBoss`. Removed those misplaced references and moved the intended weak-point timing into the phased `Boss` class, where both `phase` and `weakSpotTimer` exist. The weak-point window now opens after a telegraphed attack in phases II/III and counts down in the boss update loop.

The uploaded GitHub Actions log also contains Gradle/AGP/Kotlin compatibility warnings, but they were warnings, not the cause of this failed build. The failure was the Dart compilation error in `MiniBoss`.

Validation: ZIP integrity checked. Flutter/Dart are not installed in the editing environment, so `flutter analyze`, `flutter test`, and APK compilation were not run here.
