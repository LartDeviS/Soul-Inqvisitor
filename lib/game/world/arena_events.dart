import 'dart:math';
import 'biome_data.dart';

enum WorldEventType {
  supplyDrop,
  warpSurge,
  ambush,
  relicCache,
  toxicLeak,
  powerOutage,
  auspexPing,
  quietInterval,
}

class WorldEvent {
  final WorldEventType type;
  final String title;
  final String description;
  final double duration;
  final double damageMultiplier;
  final double lootMultiplier;
  final int requisition;

  const WorldEvent(
    this.type,
    this.title,
    this.description, {
    this.duration = 18,
    this.damageMultiplier = 1,
    this.lootMultiplier = 1,
    this.requisition = 0,
  });

  double get enemyThreatMultiplier => switch (type) {
        WorldEventType.warpSurge => 1.15,
        WorldEventType.ambush => 1.08,
        WorldEventType.powerOutage => 1.05,
        WorldEventType.quietInterval => 0.92,
        _ => 1.0,
      };
}

class WorldEventEffects {
  final double enemyThreatMultiplier;
  final double lootMultiplier;
  final double duration;
  final int bonusRequisition;

  const WorldEventEffects({
    required this.enemyThreatMultiplier,
    required this.lootMultiplier,
    required this.bonusRequisition,
    required this.duration,
  });
}

class WorldDirector {
  final Random _random;

  WorldDirector({int? seed}) : _random = Random(seed);

  WorldEvent rollEvent(BiomeId biome, {required int floor, int? seed}) {
    final r = seed == null ? _random : Random(seed + floor * 31);
    final candidates = <WorldEvent>[
      const WorldEvent(
        WorldEventType.supplyDrop,
        'Аварийный сброс снабжения',
        'Имперский контейнер: боеприпасы и реквизиция',
        lootMultiplier: 1.4,
        requisition: 8,
      ),
      const WorldEvent(
        WorldEventType.warpSurge,
        'Варп-всплеск',
        'Варп нестабилен: враги опаснее, но реликвии ценнее',
        duration: 14,
        damageMultiplier: 1.15,
        lootMultiplier: 1.35,
      ),
      const WorldEvent(
        WorldEventType.ambush,
        'Засада',
        'Сигнатуры противника приближаются с флангов',
        duration: 12,
      ),
      const WorldEvent(
        WorldEventType.relicCache,
        'Скрытый реликварий',
        'Ауспекс обнаружил запечатанный тайник',
        lootMultiplier: 1.6,
        requisition: 5,
      ),
      const WorldEvent(
        WorldEventType.toxicLeak,
        'Утечка токсинов',
        'Не задерживайся в опасной зоне',
        duration: 16,
      ),
      const WorldEvent(
        WorldEventType.powerOutage,
        'Сбой питания',
        'Видимость падает, противники получают преимущество',
        duration: 12,
        damageMultiplier: 1.08,
      ),
      const WorldEvent(
        WorldEventType.auspexPing,
        'Импульс ауспекса',
        'Кратковременно обнаружены тайники и элитные цели',
        duration: 10,
        lootMultiplier: 1.25,
      ),
      const WorldEvent(
        WorldEventType.quietInterval,
        'Передышка',
        'Сигнатуры противника ослабли',
        duration: 10,
        damageMultiplier: 0.92,
      ),
    ];
    if (biome == BiomeId.warpRuin || biome == BiomeId.necronTomb) {
      candidates.add(
        const WorldEvent(
          WorldEventType.relicCache,
          'Археотехнологический тайник',
          'Древний механизм сохранил ценные компоненты',
          lootMultiplier: 1.8,
          requisition: 10,
        ),
      );
    }
    return candidates[r.nextInt(candidates.length)];
  }

  WorldEventEffects applyEventModifiers(WorldEvent event, Object game) {
    return WorldEventEffects(
      enemyThreatMultiplier: event.enemyThreatMultiplier,
      lootMultiplier: event.lootMultiplier,
      bonusRequisition: event.requisition,
      duration: event.duration,
    );
  }
}
