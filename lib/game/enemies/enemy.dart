import 'enemy_stats.dart';
import 'enemy_type.dart';
class EnemyRuntimeState {
  final EnemyType type;
  final EnemyStats stats;
  double currentHealth;
  double abilityCooldown = 0;
  bool isDefeated = false;
  EnemyRuntimeState(this.type, {EnemyStats? stats}) : stats = stats ?? EnemyStats.defaults[type]!, currentHealth = (stats ?? EnemyStats.defaults[type]!).health;
  double applyDamage(double rawDamage) {
    if (isDefeated || rawDamage <= 0) return 0;
    final dealt = rawDamage * (1 - stats.armor.clamp(0, 0.85).toDouble());
    currentHealth = (currentHealth - dealt).clamp(0, stats.health).toDouble();
    if (currentHealth <= 0) isDefeated = true;
    return dealt;
  }
}
