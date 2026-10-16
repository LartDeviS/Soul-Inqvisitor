// Integration facade for the legacy Flame game. The full game remains in main.dart for compatibility.
import 'balance/difficulty_config.dart';
import 'enemies/enemy.dart';
import 'missions/mission_data.dart';
import 'progression/campaign_state.dart';
import 'progression/inventory_state.dart';
import 'weapons/weapon_system.dart';
import 'world/biome_data.dart';

/// Additive runtime services for new content. Kept independent of Flame so it is testable.
class InquisitorExpansionSystems {
  final CampaignProgress campaign = CampaignProgress();
  final InventoryState inventory = InventoryState();
  final WeaponSystem weapons = WeaponSystem();
  DifficultyConfig difficulty = DifficultyConfig.normal;
  BiomeId biome = BiomeId.hive;
  MissionData? activeMission;
  final List<EnemyRuntimeState> trackedEnemies = <EnemyRuntimeState>[];

  void beginMission(MissionData mission, {BiomeId? selectedBiome, DifficultyConfig? selectedDifficulty}) {
    activeMission = mission;
    if (selectedBiome != null) biome = selectedBiome;
    if (selectedDifficulty != null) difficulty = selectedDifficulty;
    campaign.beginMission(mission.id);
    trackedEnemies.clear();
  }

  void recordEnemyDefeated(EnemyRuntimeState enemy) {
    enemy.isDefeated = true;
    campaign.recordKill(enemy.type.name);
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'campaign': campaign.toJson(),
    'inventory': inventory.toJson(),
    'weapons': weapons.toJson(),
    'difficulty': difficulty.id,
    'biome': biome.name,
    'activeMissionId': activeMission?.id,
  };

  void loadJson(Map<String, dynamic> json, {List<MissionData> missions = const []}) {
    campaign.loadJson(json['campaign']);
    inventory.loadJson(json['inventory']);
    weapons.loadJson(json['weapons']);
    difficulty = DifficultyConfig.byId(json['difficulty'] as String? ?? 'normal');
    biome = BiomeId.values.firstWhere((e) => e.name == json['biome'], orElse: () => BiomeId.hive);
    final id = json['activeMissionId'];
    activeMission = id is String ? _findMission(missions, id) : null;
    trackedEnemies.clear();
  }

  MissionData? _findMission(List<MissionData> missions, String id) {
    for (final mission in missions) { if (mission.id == id) return mission; }
    return null;
  }
}
