import 'package:flutter_test/flutter_test.dart';
import 'package:soul_of_the_inquisitor/game/weapons/weapon_data.dart';
import 'package:soul_of_the_inquisitor/game/weapons/weapon_system.dart';
import 'package:soul_of_the_inquisitor/saves/save_migration.dart';

void main() {
  test('every weapon id has catalog data', () {
    expect(WeaponData.all.keys.toSet(), WeaponId.values.toSet());
  });

  test('six new Ordo weapons have unique ids and correct faction tags', () {
    final malleus = WeaponData.all.values.where((w) => w.ordo == WeaponOrdo.malleus).toList();
    final hereticus = WeaponData.all.values.where((w) => w.ordo == WeaponOrdo.hereticus).toList();
    expect(malleus.map((w) => w.id).toSet(), {
      WeaponId.psycannon, WeaponId.exorcistIncinerator, WeaponId.daemonbanePistol,
    });
    expect(hereticus.map((w) => w.id).toSet(), {
      WeaponId.condemnorBoltgun, WeaponId.sanctifiedStakeCrossbow, WeaponId.infernoPistol,
    });
    expect(WeaponData.all.length, 19);
  });

  test('new weapons serialize and restore by stable enum names', () {
    final original = WeaponSystem()..equipped = WeaponId.psycannon;
    original.weapons[WeaponId.psycannon]!.ammo = 7;
    final restored = WeaponSystem()..loadJson(original.toJson());
    expect(restored.equipped, WeaponId.psycannon);
    expect(restored.weapons[WeaponId.psycannon]!.ammo, 7);
  });

  test('legacy saves without a schema still migrate safely', () {
    final migrated = SaveMigration.migrate({'ranged': 'bolter', 'floor': 2});
    expect(migrated['schemaVersion'], 2);
    expect(migrated['ranged'], 'bolter');
    expect(migrated['inventory'], isA<Map>());
  });
}
