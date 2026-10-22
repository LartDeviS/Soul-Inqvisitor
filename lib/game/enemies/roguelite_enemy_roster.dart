import 'enemy_type.dart';

/// Enemy roster additions for the combat roguelite. Values are tuning baselines,
/// not lore claims; game difficulty and floor scaling are applied at runtime.
class RogueliteEnemyRoster {
  static const sniper = EnemyTypeData(
    'cult_sniper', 'Снайпер-культист', EnemyFaction.cult,
    EnemyArchetype.sniper, armor: .08, speed: .78, hp: 38,
  );
  static const armoredElite = EnemyTypeData(
    'chaos_bulwark', 'Бронированный элитник Хаоса', EnemyFaction.chaos,
    EnemyArchetype.heavy, armor: .52, speed: .62, hp: 115,
  );
  static const assassin = EnemyTypeData(
    'tyranid_stalker', 'Тиранид-убийца', EnemyFaction.tyranid,
    EnemyArchetype.flanker, armor: .12, speed: 2.05, hp: 34,
  );
  static const summoner = EnemyTypeData(
    'warp_summoner', 'Призыватель разлома', EnemyFaction.daemon,
    EnemyArchetype.summoner, armor: .10, speed: .72, hp: 76,
  );
  static const all = <EnemyTypeData>[sniper, armoredElite, assassin, summoner];

  static EnemyTypeData? byId(String id) {
    for (final enemy in all) {
      if (enemy.id == id) return enemy;
    }
    return null;
  }
}
