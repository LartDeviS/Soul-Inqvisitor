import 'package:flutter/material.dart';
import '../../game/world/arena_events.dart';
import '../../game/world/biome_data.dart';

/// Static reference for environments and event types; it does not roll events.
class WorldCodexPanel extends StatelessWidget {
  const WorldCodexPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151719),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: const Icon(Icons.public, color: Color(0xFF80CBC4)),
        title: const Text('МИРЫ И ОПЕРАЦИОННЫЕ СОБЫТИЯ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text('${BiomeData.all.length} биомов • ${WorldEventType.values.length} типов событий', style: const TextStyle(color: Colors.white54, fontSize: 10)),
        children: [
          ...BiomeData.all.values.map((b) => ExpansionTile(
            dense: true,
            title: Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 12)),
            subtitle: Text('Опасность ×${b.hazard.toStringAsFixed(2)} • добыча ×${b.lootMultiplier.toStringAsFixed(2)} • скорость врагов ×${b.enemySpeed.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.description, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 4),
              Text('Элементы окружения: ${b.props.join(', ')}', style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 10)),
            ]))],
          )),
          const Divider(color: Colors.white12),
          ...WorldEventType.values.map((e) => ListTile(
            dense: true,
            leading: const Icon(Icons.bolt, color: Colors.amber, size: 17),
            title: Text(_eventTitle(e), style: const TextStyle(color: Colors.white70, fontSize: 11)),
            subtitle: Text(_eventDescription(e), style: const TextStyle(color: Colors.white38, fontSize: 10)),
          )),
        ],
      ),
    );
  }

  String _eventTitle(WorldEventType e) => switch (e) {
    WorldEventType.supplyDrop => 'Аварийный сброс снабжения',
    WorldEventType.warpSurge => 'Варп-всплеск',
    WorldEventType.ambush => 'Засада',
    WorldEventType.relicCache => 'Скрытый реликварий',
    WorldEventType.toxicLeak => 'Утечка токсинов',
    WorldEventType.powerOutage => 'Сбой питания',
    WorldEventType.auspexPing => 'Импульс ауспекса',
    WorldEventType.quietInterval => 'Передышка',
  };

  String _eventDescription(WorldEventType e) => switch (e) {
    WorldEventType.supplyDrop => 'Повышенная добыча и реквизиция из контейнера.',
    WorldEventType.warpSurge => 'Повышенная опасность и ценность добычи.',
    WorldEventType.ambush => 'Противник атакует с флангов.',
    WorldEventType.relicCache => 'Шанс найти редкие реликвии и компоненты.',
    WorldEventType.toxicLeak => 'Опасная зона требует быстрого продвижения.',
    WorldEventType.powerOutage => 'Нарушение энергоснабжения ухудшает условия боя.',
    WorldEventType.auspexPing => 'Кратковременное обнаружение тайников и элитных целей.',
    WorldEventType.quietInterval => 'Временное ослабление давления противника.',
  };
}
