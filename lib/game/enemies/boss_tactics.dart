import 'dart:math';

enum BossAttackPattern { warpNova, sweepingBeam, charge, summoningRift, groundSlam }

class BossAttackDefinition {
  final BossAttackPattern pattern;
  final String title;
  final String telegraph;
  final double windupSeconds;
  final double recoverySeconds;
  final double radius;
  final double damageMultiplier;
  const BossAttackDefinition({required this.pattern, required this.title,
    required this.telegraph, required this.windupSeconds,
    required this.recoverySeconds, required this.radius,
    required this.damageMultiplier});
}

class BossAttackCatalog {
  static const all = <BossAttackDefinition>[
    BossAttackDefinition(pattern: BossAttackPattern.warpNova, title: 'Варп-нова',
      telegraph: 'Отойдите от босса: энергия разойдётся круговой волной',
      windupSeconds: 1.35, recoverySeconds: 1.1, radius: 180, damageMultiplier: 1.25),
    BossAttackDefinition(pattern: BossAttackPattern.sweepingBeam, title: 'Рассекающий луч',
      telegraph: 'Луч пройдёт по сектору — уклонитесь поперёк направления',
      windupSeconds: 1.05, recoverySeconds: 1.35, radius: 260, damageMultiplier: 1.0),
    BossAttackDefinition(pattern: BossAttackPattern.charge, title: 'Таран',
      telegraph: 'Босс готовится к рывку по прямой',
      windupSeconds: .9, recoverySeconds: 1.6, radius: 300, damageMultiplier: 1.4),
    BossAttackDefinition(pattern: BossAttackPattern.summoningRift, title: 'Разлом призыва',
      telegraph: 'Разлом откроется рядом с игроком — покиньте отмеченную область',
      windupSeconds: 1.6, recoverySeconds: 1.0, radius: 125, damageMultiplier: .85),
    BossAttackDefinition(pattern: BossAttackPattern.groundSlam, title: 'Удар по земле',
      telegraph: 'Удар по земле: опасная зона у босса',
      windupSeconds: 1.1, recoverySeconds: 1.45, radius: 145, damageMultiplier: 1.3),
  ];

  static BossAttackDefinition forBoss(String bossId, int sequence) {
    final id = bossId.toLowerCase();
    final choices = id.contains('warp') || id.contains('daemon')
        ? const [BossAttackPattern.warpNova, BossAttackPattern.sweepingBeam, BossAttackPattern.summoningRift]
        : id.contains('knight') || id.contains('bulwark')
            ? const [BossAttackPattern.charge, BossAttackPattern.groundSlam, BossAttackPattern.sweepingBeam]
            : BossAttackPattern.values;
    final selected = choices[sequence.abs() % choices.length];
    return all.firstWhere((entry) => entry.pattern == selected);
  }
}

/// Small deterministic state machine: wind-up is the dodge window; active is
/// the resolution window; recovery prevents attacks from chaining instantly.
class BossAttackRuntime {
  final String bossId;
  int sequence = 0;
  double timer = 0;
  bool active = false;
  bool recovering = false;
  BossAttackDefinition current;
  BossAttackRuntime({required this.bossId}) : current = BossAttackCatalog.forBoss(bossId, 0) {
    timer = current.windupSeconds;
  }
  String get warning => active ? 'Атака: ${current.title}' : recovering ? 'Босс восстанавливается' : current.telegraph;
  double get remaining => max(0, timer);

  /// Returns true once when the telegraphed attack resolves.
  bool update(double dt) {
    if (dt <= 0) return false;
    timer -= dt;
    if (!active && !recovering && timer <= 0) {
      active = true;
      timer = .22;
      return false;
    }
    if (active && timer <= 0) {
      active = false;
      recovering = true;
      timer = current.recoverySeconds;
      return true;
    }
    if (recovering && timer <= 0) {
      recovering = false;
      sequence++;
      current = BossAttackCatalog.forBoss(bossId, sequence);
      timer = current.windupSeconds;
    }
    return false;
  }
}
