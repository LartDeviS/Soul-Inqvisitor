/// Data-driven identities for the three campaign operation bosses.
/// This file deliberately has no Flutter/Flame dependency so its rules are testable.
enum StoryBossKind { voxWarden, convoyEnforcer, archiveGuardian }

class StoryBossProfile {
  final StoryBossKind kind;
  final String title;
  final String subtitle;
  final double healthMultiplier;
  final double movementMultiplier;
  final double attackIntervalMultiplier;
  final double damageTakenMultiplier;
  final List<int> phaseOneAttacks;
  final List<int> phaseTwoAttacks;
  final List<int> phaseThreeAttacks;

  const StoryBossProfile({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.healthMultiplier,
    required this.movementMultiplier,
    required this.attackIntervalMultiplier,
    required this.damageTakenMultiplier,
    required this.phaseOneAttacks,
    required this.phaseTwoAttacks,
    required this.phaseThreeAttacks,
  });

  int attackModeFor(int phase, int attackIndex) {
    final sequence = phase >= 3
        ? phaseThreeAttacks
        : phase == 2
            ? phaseTwoAttacks
            : phaseOneAttacks;
    if (sequence.isEmpty) return 0;
    return sequence[attackIndex % sequence.length].clamp(0, 4).toInt();
  }

  static const Map<StoryBossKind, StoryBossProfile> all = {
    StoryBossKind.voxWarden: StoryBossProfile(
      kind: StoryBossKind.voxWarden,
      title: 'Смотритель вокс-станции',
      subtitle: 'Подавитель сигнала',
      healthMultiplier: 0.92,
      movementMultiplier: 1.08,
      attackIntervalMultiplier: 0.94,
      damageTakenMultiplier: 1.08,
      phaseOneAttacks: [1, 2, 1, 0],
      phaseTwoAttacks: [2, 4, 1, 3],
      phaseThreeAttacks: [4, 2, 4, 0, 3],
    ),
    StoryBossKind.convoyEnforcer: StoryBossProfile(
      kind: StoryBossKind.convoyEnforcer,
      title: 'Каратель конвоя',
      subtitle: 'Броня грузового эскорта',
      healthMultiplier: 1.22,
      movementMultiplier: 0.88,
      attackIntervalMultiplier: 1.12,
      damageTakenMultiplier: 0.82,
      phaseOneAttacks: [0, 3, 0, 1],
      phaseTwoAttacks: [3, 0, 4, 3],
      phaseThreeAttacks: [3, 4, 0, 4, 3],
    ),
    StoryBossKind.archiveGuardian: StoryBossProfile(
      kind: StoryBossKind.archiveGuardian,
      title: 'Страж архива',
      subtitle: 'Хранитель запретных имён',
      healthMultiplier: 1.12,
      movementMultiplier: 1.0,
      attackIntervalMultiplier: 0.82,
      damageTakenMultiplier: 0.94,
      phaseOneAttacks: [2, 1, 3],
      phaseTwoAttacks: [4, 2, 3, 1],
      phaseThreeAttacks: [4, 3, 2, 4, 1],
    ),
  };

  static StoryBossProfile forKind(StoryBossKind kind) => all[kind]!;
}
