import 'adaptive_difficulty.dart';

class FloorBalanceProfile {
  final int floor;
  final double enemyHp, enemyDamage, enemySpeed, spawnBudget, bossHp;
  const FloorBalanceProfile({required this.floor, required this.enemyHp,
    required this.enemyDamage, required this.enemySpeed,
    required this.spawnBudget, required this.bossHp});

  /// Smooth per-floor curve. Performance shifts stay small and all multipliers
  /// are capped so deep runs remain difficult without sudden spikes.
  factory FloorBalanceProfile.calculate({required int floor,
      required int recentDeaths, required int recentKills,
      double difficultyHp = 1, double difficultyDamage = 1,
      double difficultySpawn = 1}) {
    final safeFloor = floor.clamp(1, 100).toInt();
    final adaptive = AdaptiveDifficulty.calculate(floor: safeFloor,
      recentDeaths: recentDeaths, recentKills: recentKills,
      baseHp: difficultyHp, baseDamage: difficultyDamage, baseSpawn: difficultySpawn);
    final depth = (1 + (safeFloor - 1) * .018).clamp(1.0, 1.7).toDouble();
    return FloorBalanceProfile(floor: safeFloor,
      enemyHp: adaptive.hpMultiplier,
      enemyDamage: adaptive.damageMultiplier,
      enemySpeed: (1 + (depth - 1) * .22).clamp(1.0, 1.16).toDouble(),
      spawnBudget: adaptive.spawnMultiplier,
      bossHp: (depth * adaptive.hpMultiplier * 1.15).clamp(1.15, 2.8).toDouble());
  }
}
