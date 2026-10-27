import 'package:flutter_test/flutter_test.dart';
import '../lib/progression/inventory_state.dart';

GearItem gear(String id, String slot) => GearItem(id: id, name: id, slot: slot);

void main() {
  group('Inventory integrity regressions', () {
    test('full backpack does not delete a vault item', () {
      final state = InventoryState()..capacity = 1;
      final stored = gear('vault_item', 'weapon');
      state.vault.add(stored);
      state.backpack.add(gear('backpack_item', 'armor'));

      expect(state.toBackpack(stored), isFalse);
      expect(state.vault.single.id, 'vault_item');
      expect(state.backpack.single.id, 'backpack_item');
    });

    test('equipping into an occupied slot swaps items even when backpack is full', () {
      final state = InventoryState()..capacity = 2;
      final old = gear('old_weapon', 'weapon');
      final incoming = gear('new_weapon', 'weapon');
      state.equipped['weapon'] = old;
      state.backpack..add(incoming)..add(gear('armor_item', 'armor'));

      expect(state.equip(incoming), isTrue);
      expect(state.equipped['weapon']?.id, 'new_weapon');
      expect(state.backpack.map((e) => e.id).toSet(), {'old_weapon', 'armor_item'});
      expect(state.backpack.length, state.capacity);
    });

    test('loading malformed saves clamps capacity and deduplicates item IDs', () {
      final state = InventoryState();
      state.loadJson({
        'capacity': 1,
        'backpack': [
          {'id': 'same', 'name': 'Backpack', 'slot': 'weapon'},
          {'id': 'overflow', 'name': 'Overflow', 'slot': 'armor'},
        ],
        'vault': [
          {'id': 'same', 'name': 'Duplicate', 'slot': 'weapon'},
        ],
        'equipped': {
          'head': {'id': 'helmet', 'name': 'Helmet', 'slot': 'head'},
          'wrong_slot': {'id': 'invalid', 'name': 'Invalid', 'slot': 'boots'},
        },
      });

      expect(state.capacity, 1);
      expect(state.backpack.map((e) => e.id), ['same']);
      expect(state.vault.map((e) => e.id), ['overflow']);
      expect(state.equipped.keys.toSet(), {'head'});
      final allIds = [
        ...state.backpack.map((e) => e.id),
        ...state.vault.map((e) => e.id),
        ...state.equipped.values.map((e) => e.id),
      ];
      expect(allIds.toSet().length, allIds.length);
    });
  });
}
