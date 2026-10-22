import 'dart:math';

enum BossHitZone { armor, core, head, limb }

class HitPoint {
  final double x, y;
  const HitPoint(this.x, this.y);
}

class BossWeakSpot {
  final BossHitZone zone;
  final double centerX, centerY, radius;
  final double damageMultiplier;
  final bool requiresExposedPhase;
  const BossWeakSpot({required this.zone, required this.centerX,
    required this.centerY, required this.radius, required this.damageMultiplier,
    this.requiresExposedPhase = true});
  bool contains(HitPoint point) {
    final dx = point.x - centerX, dy = point.y - centerY;
    return dx * dx + dy * dy <= radius * radius;
  }
}

class BossHitZoneResult {
  final BossHitZone zone;
  final double multiplier;
  final bool wasWeakSpot;
  const BossHitZoneResult(this.zone, this.multiplier, this.wasWeakSpot);
}

/// Normalized hit zones use 0..1 coordinates relative to the boss sprite.
/// The renderer maps these coordinates to its current sprite bounds.
class BossWeakSpotSystem {
  static const defaultSpots = <BossWeakSpot>[
    BossWeakSpot(zone: BossHitZone.core, centerX: .50, centerY: .44,
      radius: .13, damageMultiplier: 1.8),
    BossWeakSpot(zone: BossHitZone.head, centerX: .50, centerY: .20,
      radius: .105, damageMultiplier: 1.45),
    BossWeakSpot(zone: BossHitZone.limb, centerX: .22, centerY: .62,
      radius: .09, damageMultiplier: .9, requiresExposedPhase: false),
  ];

  static BossHitZoneResult resolve({required HitPoint normalizedPoint,
      required bool weakSpotExposed, List<BossWeakSpot> spots = defaultSpots}) {
    for (final spot in spots) {
      if (spot.contains(normalizedPoint) && (!spot.requiresExposedPhase || weakSpotExposed)) {
        return BossHitZoneResult(spot.zone, spot.damageMultiplier, true);
      }
    }
    return const BossHitZoneResult(BossHitZone.armor, .72, false);
  }

  static double applyDamage({required int baseDamage, required HitPoint point,
      required bool weakSpotExposed, double phaseMultiplier = 1,
      List<BossWeakSpot> spots = defaultSpots}) {
    if (baseDamage <= 0) return 0;
    final hit = resolve(normalizedPoint: HitPoint(
      point.x.clamp(0.0, 1.0).toDouble(), point.y.clamp(0.0, 1.0).toDouble()),
      weakSpotExposed: weakSpotExposed, spots: spots);
    return max(1, (baseDamage * hit.multiplier * phaseMultiplier).round()).toDouble();
  }
}
