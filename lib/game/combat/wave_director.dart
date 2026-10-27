import 'dart:math';

enum WavePhase { opening, assault, elite, respite, boss, complete }
enum WaveDirectiveType { none, spawnWave, spawnElite, ambush, respite, boss }

class WaveDirective {
  final WaveDirectiveType type;
  final int budget;
  final double threatMultiplier;
  const WaveDirective(this.type, {this.budget = 0, this.threatMultiplier = 1});
  static const none = WaveDirective(WaveDirectiveType.none);
}

/// Deterministic-capable pacing director. It proposes events; the game remains
/// responsible for creating entities through its existing spawn pipeline.
class WaveDirector {
  final Random _random;
  WaveDirector({int? seed}) : _random = Random(seed);
  WavePhase phase = WavePhase.opening;
  int wave = 0;
  double _clock = 0;
  double _quietClock = 0;
  int maximumAlive = 12;
  bool enabled = true;

  WaveDirective update(double dt, {required int livingEnemies, required int pendingSpawns,
    required int floor, int alarm = 0, bool bossAvailable = false}) {
    if (!enabled || dt <= 0) return WaveDirective.none;
    _clock += dt;
    if (livingEnemies > 0 || pendingSpawns > 0) {
      _quietClock = 0;
      if (livingEnemies >= maximumAlive) return WaveDirective.none;
      return WaveDirective.none;
    }
    _quietClock += dt;
    if (_quietClock < 2.0) return WaveDirective.none;
    _quietClock = 0;
    _clock = 0;
    wave++;
    if (bossAvailable && wave % 5 == 0) {
      phase = WavePhase.boss;
      return WaveDirective(WaveDirectiveType.boss, budget: 1, threatMultiplier: 1.0 + min(0.45, floor * 0.025));
    }
    if (wave % 4 == 0) {
      phase = WavePhase.respite;
      return const WaveDirective(WaveDirectiveType.respite);
    }
    if (wave % 3 == 0 || alarm >= 70 && _random.nextDouble() < 0.45) {
      phase = WavePhase.elite;
      return WaveDirective(WaveDirectiveType.spawnElite, budget: 1 + floor ~/ 5, threatMultiplier: 1.15 + min(0.5, floor * 0.02));
    }
    phase = WavePhase.assault;
    final budget = (3 + floor ~/ 2 + wave ~/ 2).clamp(3, maximumAlive).toInt();
    return WaveDirective(_random.nextDouble() < 0.22 ? WaveDirectiveType.ambush : WaveDirectiveType.spawnWave,
      budget: budget, threatMultiplier: 1.0 + min(0.35, alarm / 250));
  }

  Map<String, dynamic> toJson() => {'wave': wave, 'phase': phase.name, 'clock': _clock, 'quietClock': _quietClock};
  void loadJson(dynamic raw) {
    if (raw is! Map) return;
    wave = (raw['wave'] is num ? (raw['wave'] as num).toInt() : 0).clamp(0, 1000000).toInt();
    final name = raw['phase'];
    phase = WavePhase.values.firstWhere((e) => e.name == name, orElse: () => WavePhase.opening);
    _clock = raw['clock'] is num ? (raw['clock'] as num).toDouble().clamp(0, 1e6).toDouble() : 0;
    _quietClock = raw['quietClock'] is num ? (raw['quietClock'] as num).toDouble().clamp(0, 10).toDouble() : 0;
  }
}
