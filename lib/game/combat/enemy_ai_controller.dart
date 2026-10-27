enum EnemyAIState { approach, holdRange, retreat, windup, recover, investigate }

class EnemyAIDecision {
  final EnemyAIState state;
  final bool kite;
  final double preferredDistance;
  final double aggression;
  const EnemyAIDecision(this.state, {required this.kite, required this.preferredDistance, required this.aggression});
}

/// Stateless decision policy; movement and attacks stay in the existing Enemy component.
class EnemyAIController {
  EnemyAIDecision decide({required double distance, required double preferredDistance,
    required bool ranged, required double healthRatio, required bool windingUp,
    required bool recovering, required bool canRetreat}) {
    if (windingUp) return EnemyAIDecision(EnemyAIState.windup, kite: false, preferredDistance: preferredDistance, aggression: 0.0);
    if (recovering) return EnemyAIDecision(EnemyAIState.recover, kite: ranged, preferredDistance: preferredDistance, aggression: 0.35);
    if (canRetreat && healthRatio < 0.22 && distance < preferredDistance * 0.75) {
      return EnemyAIDecision(EnemyAIState.retreat, kite: true, preferredDistance: preferredDistance, aggression: 0.25);
    }
    if (ranged && distance < preferredDistance * 0.72) {
      return EnemyAIDecision(EnemyAIState.holdRange, kite: true, preferredDistance: preferredDistance, aggression: 0.55);
    }
    return EnemyAIDecision(EnemyAIState.approach, kite: ranged && distance < preferredDistance,
      preferredDistance: preferredDistance, aggression: healthRatio > 0.5 ? 1.0 : 0.8);
  }
}
