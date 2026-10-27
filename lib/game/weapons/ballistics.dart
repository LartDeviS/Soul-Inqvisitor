import 'dart:math';

enum SurfaceMaterial { flesh, lightArmor, heavyArmor, energyShield, stone, metal }

class BallisticHit {
  final int damage;
  final bool penetrates;
  final bool ricochet;
  final double remainingEnergy;
  const BallisticHit({required this.damage, required this.penetrates, required this.ricochet, required this.remainingEnergy});
}

class Ballistics {
  static BallisticHit resolve({required double baseDamage, required double distance,
    required double effectiveRange, required double penetration, required double targetArmor,
    required SurfaceMaterial material, bool canPenetrate = false, bool canRicochet = false,
    double falloffStart = 0.65}) {
    final safeRange = max(1.0, effectiveRange);
    final distanceRatio = (distance / safeRange).clamp(0.0, 2.0);
    final falloff = distanceRatio <= falloffStart ? 1.0 : (1.0 - (distanceRatio - falloffStart) * 0.48).clamp(0.25, 1.0);
    final materialArmor = switch (material) {
      SurfaceMaterial.flesh => 0.0,
      SurfaceMaterial.lightArmor => 0.18,
      SurfaceMaterial.heavyArmor => 0.42,
      SurfaceMaterial.energyShield => 0.5,
      SurfaceMaterial.stone => 0.3,
      SurfaceMaterial.metal => 0.36,
    };
    final armor = (targetArmor + materialArmor - penetration).clamp(0.0, 0.85);
    final energy = max(0.0, baseDamage * falloff * (1 - armor));
    final blocked = armor > 0.72;
    return BallisticHit(damage: max(1, energy.round()), penetrates: canPenetrate && energy > baseDamage * 0.38,
      ricochet: canRicochet && (material == SurfaceMaterial.metal || material == SurfaceMaterial.stone) && !blocked,
      remainingEnergy: canPenetrate ? (energy * 0.58).toDouble() : 0.0);
  }
}
