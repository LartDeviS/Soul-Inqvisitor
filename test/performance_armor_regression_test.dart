import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  group('Checkpoint 15 visual/performance regression checks', () {
    test('all nine procedural armor profiles remain available', () {
      expect(ArmorPattern.values, hasLength(9));
      expect(ArmorPattern.values.map((e) => e.labelRu).toSet(), hasLength(9));
    });

    test('armor profiles retain unique names and valid prices', () {
      for (final armor in ArmorPattern.values) {
        expect(armor.labelRu.trim(), isNotEmpty);
        expect(armor.price, greaterThanOrEqualTo(0));
        expect(armor.defense, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}
