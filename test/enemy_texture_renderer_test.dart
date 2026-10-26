import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:soul_of_the_inquisitor/main.dart';

void main() {
  test('procedural texture renderer draws every enemy type without throwing', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (final type in EnemyType.values) {
      EnemyTextureRenderer.draw(
        canvas,
        cx: 80,
        cy: 80,
        type: type,
        scale: 1,
        clock: 1.25,
        variant: 2,
        healthRatio: 0.63,
        champion: true,
      );
    }
    final picture = recorder.endRecording();
    picture.dispose();
  });
}
