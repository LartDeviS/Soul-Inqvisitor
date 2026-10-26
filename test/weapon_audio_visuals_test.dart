import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('procedural weapon renderer and per-weapon audio routing are present', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('void playWeaponShoot(RangedWeapon weapon)'));
    expect(source, contains('Procedural carried weapon pass'));
    expect(source, contains('High-detail weapon pass'));
    expect(source, contains('void playEnemyWeapon(EnemyType type)'));
  });

  test('synthesized weapon sound assets are included', () {
    final names = <String>[
      'weapon_bolter.wav',
      'weapon_lasgun.wav',
      'weapon_shotgun.wav',
      'weapon_plasma_gun.wav',
      'weapon_force_staff.wav',
      'weapon_storm_staff.wav',
      'weapon_warp_beam.wav',
      'weapon_throwing_daggers.wav',
      'weapon_needler.wav',
      'weapon_sniper_needle.wav',
      'weapon_melta_gun.wav',
      'weapon_flamer.wav',
      'weapon_heavy_bolter.wav',
      'weapon_psycannon.wav',
      'weapon_exorcist_incinerator.wav',
      'weapon_daemonbane_pistol.wav',
      'weapon_condemnor_boltgun.wav',
      'weapon_sanctified_crossbow.wav',
      'weapon_inferno_pistol.wav',
      'enemy_lasgun.wav',
      'enemy_flamer.wav',
      'enemy_gauss.wav',
      'enemy_heavy.wav',
    ];
    for (final name in names) {
      expect(File('assets/sounds/$name').existsSync(), isTrue, reason: name);
      expect(File('assets/sounds/$name').lengthSync(), greaterThan(1000), reason: name);
    }
  });
}
