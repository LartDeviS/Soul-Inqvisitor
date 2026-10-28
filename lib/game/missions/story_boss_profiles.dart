/// Data-driven identities for the three campaign operation bosses.
/// This file deliberately has no Flutter/Flame dependency so its rules are testable.
enum StoryBossKind { voxWarden, convoyEnforcer, archiveGuardian, relaySentinel, commandCustodian, mobileInterceptor, ambushMarshal, authorityAuditor, signalPursuer, supplyLineEnforcer, biometricKeeper, syncNodeHunter, requisitionMaster }

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
    StoryBossKind.relaySentinel: StoryBossProfile(
      kind: StoryBossKind.relaySentinel,
      title: 'Страж внешнего ретранслятора',
      subtitle: 'Автономный перехватчик сигнала',
      healthMultiplier: 1.18,
      movementMultiplier: 1.12,
      attackIntervalMultiplier: 0.88,
      damageTakenMultiplier: 0.90,
      phaseOneAttacks: [1, 4, 2, 1],
      phaseTwoAttacks: [4, 3, 1, 2],
      phaseThreeAttacks: [4, 2, 3, 4, 1, 2],
    ),
    StoryBossKind.commandCustodian: StoryBossProfile(
      kind: StoryBossKind.commandCustodian,
      title: 'Хранитель командного ключа',
      subtitle: 'Защитник закрытого реестра',
      healthMultiplier: 1.08, movementMultiplier: 0.92,
      attackIntervalMultiplier: 0.94, damageTakenMultiplier: 0.96,
      phaseOneAttacks: [0, 1, 3, 0], phaseTwoAttacks: [3, 1, 4, 0],
      phaseThreeAttacks: [4, 3, 1, 4, 0],
    ),
    StoryBossKind.mobileInterceptor: StoryBossProfile(
      kind: StoryBossKind.mobileInterceptor,
      title: 'Командир мобильного перехвата',
      subtitle: 'Охрана резервного канала',
      healthMultiplier: 0.98, movementMultiplier: 1.22,
      attackIntervalMultiplier: 0.78, damageTakenMultiplier: 1.02,
      phaseOneAttacks: [1, 2, 4, 1], phaseTwoAttacks: [4, 2, 3, 1],
      phaseThreeAttacks: [4, 1, 2, 4, 3],
    ),
    StoryBossKind.ambushMarshal: StoryBossProfile(
      kind: StoryBossKind.ambushMarshal,
      title: 'Маршал засады',
      subtitle: 'Командир блокирующего отряда',
      healthMultiplier: 1.16, movementMultiplier: 0.96,
      attackIntervalMultiplier: 0.86, damageTakenMultiplier: 0.88,
      phaseOneAttacks: [3, 0, 2, 3], phaseTwoAttacks: [3, 4, 0, 2],
      phaseThreeAttacks: [4, 3, 2, 0, 4],
    ),
    StoryBossKind.authorityAuditor: StoryBossProfile(
      kind: StoryBossKind.authorityAuditor,
      title: 'Аудитор полномочий', subtitle: 'Стирает следы чужих приказов',
      healthMultiplier: 1.24, movementMultiplier: 0.84,
      attackIntervalMultiplier: 1.08, damageTakenMultiplier: 0.80,
      phaseOneAttacks: [0, 3, 1, 0], phaseTwoAttacks: [3, 4, 0, 1],
      phaseThreeAttacks: [4, 3, 0, 4, 1],
    ),
    StoryBossKind.signalPursuer: StoryBossProfile(
      kind: StoryBossKind.signalPursuer,
      title: 'Преследователь сигнала', subtitle: 'Охрана мобильного канала',
      healthMultiplier: 0.96, movementMultiplier: 1.28,
      attackIntervalMultiplier: 0.76, damageTakenMultiplier: 1.04,
      phaseOneAttacks: [1, 4, 2, 1], phaseTwoAttacks: [4, 2, 1, 3],
      phaseThreeAttacks: [4, 1, 2, 4, 3],
    ),
    StoryBossKind.supplyLineEnforcer: StoryBossProfile(
      kind: StoryBossKind.supplyLineEnforcer,
      title: 'Каратель цепочки снабжения', subtitle: 'Защитник складских документов',
      healthMultiplier: 1.14, movementMultiplier: 0.94,
      attackIntervalMultiplier: 0.90, damageTakenMultiplier: 0.86,
      phaseOneAttacks: [3, 0, 2, 3], phaseTwoAttacks: [3, 4, 0, 2],
      phaseThreeAttacks: [4, 3, 2, 0, 4],
    ),
    StoryBossKind.biometricKeeper: StoryBossProfile(
      kind: StoryBossKind.biometricKeeper,
      title: 'Хранитель биометрической печати', subtitle: 'Защитник капсулы идентификации',
      healthMultiplier: 1.20, movementMultiplier: 0.90,
      attackIntervalMultiplier: 0.92, damageTakenMultiplier: 0.82,
      phaseOneAttacks: [0, 3, 2, 0], phaseTwoAttacks: [3, 4, 2, 1],
      phaseThreeAttacks: [4, 3, 2, 0, 4],
    ),
    StoryBossKind.syncNodeHunter: StoryBossProfile(
      kind: StoryBossKind.syncNodeHunter,
      title: 'Охотник за синхронизатором', subtitle: 'Командир мобильного узла',
      healthMultiplier: 1.00, movementMultiplier: 1.30,
      attackIntervalMultiplier: 0.74, damageTakenMultiplier: 1.02,
      phaseOneAttacks: [1, 4, 2, 1], phaseTwoAttacks: [4, 2, 3, 1],
      phaseThreeAttacks: [4, 1, 2, 3, 4],
    ),
    StoryBossKind.requisitionMaster: StoryBossProfile(
      kind: StoryBossKind.requisitionMaster,
      title: 'Распорядитель реквизиций', subtitle: 'Хранитель оригинала заказа',
      healthMultiplier: 1.16, movementMultiplier: 0.92,
      attackIntervalMultiplier: 0.88, damageTakenMultiplier: 0.85,
      phaseOneAttacks: [3, 0, 2, 3], phaseTwoAttacks: [3, 4, 0, 2],
      phaseThreeAttacks: [4, 3, 2, 0, 4],
    ),
  };

  static StoryBossProfile forKind(StoryBossKind kind) => all[kind]!;
}
