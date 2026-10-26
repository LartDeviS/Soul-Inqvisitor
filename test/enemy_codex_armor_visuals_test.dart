import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';
import '../lib/game/enemies/enemy_type.dart' as enemy_catalog;

void main() {
  test('legacy enemy roster includes every enemy type used by combat', () {
    expect(EnemyType.values.length, 17);
    expect(EnemyType.values.toSet().length, EnemyType.values.length);
  });

  test('expanded enemy roster is represented by stable unique IDs', () {
    expect(enemy_catalog.EnemyTypeData.all.length, 10);
    expect(enemy_catalog.EnemyTypeData.all.map((e) => e.id).toSet().length, 10);
  });

  test('all procedural armor patterns have labels and prices', () {
    expect(ArmorPattern.values.length, 9);
    for (final pattern in ArmorPattern.values) {
      expect(pattern.labelRu.trim(), isNotEmpty);
      expect(pattern.price, greaterThanOrEqualTo(0));
    }
  });
}
