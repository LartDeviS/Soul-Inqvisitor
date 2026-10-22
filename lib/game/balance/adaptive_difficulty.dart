/// Smooth, capped scaling by floor and recent performance. Avoids abrupt
/// difficulty jumps: every result is clamped to a narrow band around baseline.
class AdaptiveDifficulty {
  final double hpMultiplier, damageMultiplier, spawnMultiplier;
  const AdaptiveDifficulty({required this.hpMultiplier, required this.damageMultiplier, required this.spawnMultiplier});
  factory AdaptiveDifficulty.calculate({required int floor, required int recentDeaths,
      required int recentKills, double baseHp = 1, double baseDamage = 1, double baseSpawn = 1}) {
    final depth = (1 + (floor.clamp(1, 30) - 1) * .025).clamp(1.0, 1.65).toDouble();
    final performance = (recentKills - recentDeaths * 2).clamp(-10, 20);
    final adjustment = (1 + performance * .012).clamp(.88, 1.18).toDouble();
    return AdaptiveDifficulty(
      hpMultiplier: (baseHp * depth * adjustment).clamp(.75, 1.9).toDouble(),
      damageMultiplier: (baseDamage * (1 + (depth - 1) * .65) * adjustment).clamp(.72, 1.65).toDouble(),
      spawnMultiplier: (baseSpawn * (1 + (depth - 1) * .45) * (performance < -2 ? .92 : 1)).clamp(.75, 1.5).toDouble(),
    );
  }
}
