enum BossPhase { telegraph, assault, exposed, enraged, defeated }
enum BossAttack { warpNova, charge, summon, rangedVolley }

class BossPhaseState {
  final BossPhase phase;
  final String title;
  final String warning;
  final double duration;
  final double damageMultiplier;
  final bool weakSpotExposed;
  const BossPhaseState({required this.phase, required this.title,
    required this.warning, required this.duration,
    this.damageMultiplier = 1, this.weakSpotExposed = false});
}

/// Deterministic phase controller. Call update(dt) from the encounter tick;
/// UI can render [current.warning] as a telegraph before an attack resolves.
class BossEncounter {
  final String bossId;
  final List<BossPhaseState> phases;
  int phaseIndex = 0;
  double phaseTime = 0;
  int hp;
  final int maxHp;
  BossEncounter({required this.bossId, required this.maxHp, List<BossPhaseState>? phases})
      : hp = maxHp,
        phases = phases ?? const <BossPhaseState>[
          BossPhaseState(phase: BossPhase.telegraph, title: 'Сбор энергии',
            warning: 'Босс собирает энергию — уклонитесь от отмеченной зоны', duration: 1.2),
          BossPhaseState(phase: BossPhase.assault, title: 'Атака',
            warning: 'Немедленная атака босса', duration: 5, damageMultiplier: 1.0),
          BossPhaseState(phase: BossPhase.exposed, title: 'Уязвимость',
            warning: 'Слабое место открыто — нанесите максимальный урон', duration: 2.5,
            damageMultiplier: .75, weakSpotExposed: true),
          BossPhaseState(phase: BossPhase.enraged, title: 'Ярость',
            warning: 'Босс ускоряет атаки', duration: 6, damageMultiplier: 1.35),
        ];
  BossPhaseState get current => hp <= 0
      ? const BossPhaseState(phase: BossPhase.defeated, title: 'Побеждён', warning: 'Угроза устранена', duration: 0)
      : phases[phaseIndex];
  bool get isWeakSpotExposed => current.weakSpotExposed;
  void update(double dt) {
    if (hp <= 0 || phases.isEmpty) return;
    phaseTime += dt;
    if (phaseTime >= current.duration) {
      phaseTime = 0;
      phaseIndex = (phaseIndex + 1) % phases.length;
    }
  }
  void applyDamage(int amount) { if (amount > 0) hp = (hp - amount).clamp(0, maxHp).toInt(); }
}
