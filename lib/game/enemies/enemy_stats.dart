import 'enemy_type.dart';

class EnemyStats {
  final double health, moveSpeed, contactDamage, rangedDamage, attackRange, attackCooldown, armor;
  final EnemyRole role;
  const EnemyStats({required this.health, required this.moveSpeed, required this.contactDamage, this.rangedDamage = 0, this.attackRange = 28, this.attackCooldown = 1.2, this.armor = 0, required this.role});
  EnemyStats scaled({double health = 1, double damage = 1, double speed = 1}) => EnemyStats(health: this.health * health, moveSpeed: moveSpeed * speed, contactDamage: contactDamage * damage, rangedDamage: rangedDamage * damage, attackRange: attackRange, attackCooldown: attackCooldown, armor: armor, role: role);
  static const Map<EnemyType, EnemyStats> defaults = {
    EnemyType.cultist: EnemyStats(health: 28, moveSpeed: 62, contactDamage: 4, rangedDamage: 5, attackRange: 210, attackCooldown: 1.5, role: EnemyRole.shooter),
    EnemyType.chaosPsyker: EnemyStats(health: 48, moveSpeed: 42, contactDamage: 3, rangedDamage: 12, attackRange: 260, attackCooldown: 2.8, role: EnemyRole.controller),
    EnemyType.plagueBearer: EnemyStats(health: 110, moveSpeed: 25, contactDamage: 11, armor: 0.18, role: EnemyRole.tank),
    EnemyType.bloodletter: EnemyStats(health: 75, moveSpeed: 86, contactDamage: 13, role: EnemyRole.chaser),
    EnemyType.orkBoy: EnemyStats(health: 72, moveSpeed: 43, contactDamage: 10, rangedDamage: 6, attackRange: 170, role: EnemyRole.chaser),
    EnemyType.orkShoota: EnemyStats(health: 62, moveSpeed: 32, contactDamage: 5, rangedDamage: 8, attackRange: 230, attackCooldown: 1.8, role: EnemyRole.shooter),
    EnemyType.tyranidGaunt: EnemyStats(health: 24, moveSpeed: 100, contactDamage: 5, role: EnemyRole.chaser),
    EnemyType.genestealer: EnemyStats(health: 95, moveSpeed: 112, contactDamage: 15, role: EnemyRole.chaser),
    EnemyType.tyranidWarrior: EnemyStats(health: 180, moveSpeed: 40, contactDamage: 14, rangedDamage: 11, attackRange: 220, armor: 0.2, role: EnemyRole.tank),
    EnemyType.necronWarrior: EnemyStats(health: 80, moveSpeed: 30, contactDamage: 7, rangedDamage: 9, attackRange: 250, attackCooldown: 1.7, armor: 0.12, role: EnemyRole.shooter),
    EnemyType.necronImmortal: EnemyStats(health: 145, moveSpeed: 28, contactDamage: 8, rangedDamage: 14, attackRange: 290, armor: 0.25, role: EnemyRole.tank),
    EnemyType.chaosSpawn: EnemyStats(health: 220, moveSpeed: 48, contactDamage: 18, armor: 0.1, role: EnemyRole.tank),
    EnemyType.daemonPrince: EnemyStats(health: 900, moveSpeed: 55, contactDamage: 24, rangedDamage: 18, attackRange: 300, armor: 0.25, role: EnemyRole.boss),
  };
}
