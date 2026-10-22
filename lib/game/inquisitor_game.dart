import 'balance/difficulty_config.dart';
import 'balance/adaptive_difficulty.dart';
import 'enemies/boss_encounter.dart';
import 'missions/operation_modifiers.dart';
import 'weapons/weapon_synergy.dart';
import 'enemies/enemy.dart';
import 'enemies/enemy_type.dart';
import 'missions/mission_data.dart';
import 'missions/mission_events.dart';
import 'missions/contracts.dart';
import '../progression/campaign_state.dart';
import '../progression/inventory_state.dart';
import '../progression/progression_system.dart';
import '../saves/save_manager.dart';
import '../saves/save_migration.dart';
import 'weapons/weapon_system.dart';
import 'weapons/ordo_specialization.dart';
import 'weapons/weapon_data.dart';
import 'world/biome_data.dart';
import 'world/arena_events.dart';

/// Connected data layer for new combat, world, mission and gear systems.
/// Legacy Flame components remain in main.dart while this facade owns testable domain state.
class InquisitorExpansionSystems {
  final CampaignProgress campaign=CampaignProgress();
  final InventoryState inventory=InventoryState();
  final WeaponSystem weapons=WeaponSystem();
  OrdoDoctrine ordoDoctrine=const OrdoDoctrine();
  bool unlockOrdoSkill(OrdoSkill id){if(ordoDoctrine.has(id))return false;final definition=ordoSkillCatalog.firstWhere((s)=>s.id==id);if(!progression.unlock(id.name,cost:definition.cost))return false;final next={...ordoDoctrine.unlockedSkills,id};ordoDoctrine=OrdoDoctrine(unlockedSkills:next);return true;}
  final ProgressionTrack progression=ProgressionTrack();
  final ContractBoard contracts=ContractBoard();
  final WorldDirector world=WorldDirector();
  final OperationModifierSystem operationModifiers=OperationModifierSystem();
  OperationModifierData? activeOperationModifier;
  BossEncounter? activeBoss;
  final Map<String, Set<CombatStatus>> enemyStatuses = {};
  int recentDeaths = 0;
  int recentKills = 0;
  AdaptiveDifficulty get adaptiveDifficulty => AdaptiveDifficulty.calculate(floor: activeMission?.floor ?? 1, recentDeaths: recentDeaths, recentKills: recentKills, baseHp: difficulty.hpMultiplier, baseDamage: difficulty.damageMultiplier, baseSpawn: difficulty.spawnMultiplier);
  SynergyResult resolveWeaponHit({required String enemyId, required String targetFaction, required DamageType weaponType, bool armorPiercing = false}) { final current = enemyStatuses[enemyId] ?? <CombatStatus>{}; final result = WeaponSynergySystem.resolve(weaponType: weaponType, targetStatuses: current, targetFaction: targetFaction, armorPiercing: armorPiercing); enemyStatuses[enemyId] = {...current, ...result.appliedStatuses}; return result; }
  void startBoss({required String id, required int hp}) { activeBoss = BossEncounter(bossId: id, maxHp: hp); }
  void updateCombatSystems(double dt) { activeBoss?.update(dt); weapons.update(dt); }
  void recordPlayerDeath() { recentDeaths++; }
  final MissionEventDirector missionEvents=MissionEventDirector();
  final ExpansionSaveManager saves=ExpansionSaveManager();
  DifficultyConfig difficulty=DifficultyConfig.normal;
  BiomeId biome=BiomeId.hive;
  MissionData? activeMission;
  WorldEvent? activeWorldEvent;
  MissionEvent? activeMissionEvent;
  final List<EnemyRuntimeState> trackedEnemies=[];
  void beginMission(MissionData mission,{BiomeId? selectedBiome,DifficultyConfig? selectedDifficulty,int? seed}) {activeMission=mission;if(selectedBiome!=null)biome=selectedBiome;if(selectedDifficulty!=null)difficulty=selectedDifficulty;campaign.beginMission(mission.id);activeWorldEvent=world.rollEvent(biome,floor:mission.floor,seed:seed);activeOperationModifier=operationModifiers.roll(seed:seed == null ? null : seed + 41);activeBoss=null;enemyStatuses.clear();activeMissionEvent=missionEvents.roll(floor:mission.floor,alarm:campaign.alarm,seed:seed==null?null:seed+17);trackedEnemies.clear();}
  void recordEnemyDefeated(EnemyRuntimeState enemy){enemy.isDefeated=true;recentKills++;campaign.recordKill(enemy.type.faction.name);contracts.recordKill(elite:enemy.type.archetype==EnemyArchetype.heavy||enemy.type.archetype==EnemyArchetype.sniper);progression.grantExperience(12);}
  void recordCacheFound(){contracts.recordCache();campaign.requisition+=activeWorldEvent?.requisition??5;progression.grantExperience(8);}
  Map<String,dynamic> toJson()=>{'schemaVersion':3,'campaign':campaign.toJson(),'inventory':inventory.toJson(),'weapons':weapons.toJson(),'ordoDoctrine':ordoDoctrine.toJson(),'progression':progression.toJson(),'contracts':contracts.toJson(),'difficulty':difficulty.id,'biome':biome.name,'activeMissionId':activeMission?.id,'activeWorldEvent':activeWorldEvent?.type.name,'activeMissionEvent':activeMissionEvent?.type.name,'activeOperationModifier':activeOperationModifier?.id.name,'recentDeaths':recentDeaths,'recentKills':recentKills};
  void loadJson(dynamic input,{List<MissionData> missions=const[]}){final migrated=SaveMigration.migrate(input);campaign.loadJson(migrated['campaign']);inventory.loadJson(migrated['inventory']);weapons.loadJson(migrated['weapons']);ordoDoctrine=OrdoDoctrine.fromJson(migrated['ordoDoctrine']);progression.loadJson(migrated['progression']);contracts.loadJson(migrated['contracts']);difficulty=DifficultyConfig.byId(migrated['difficulty'] as String? ?? 'normal');biome=BiomeId.values.firstWhere((e)=>e.name==migrated['biome'],orElse:()=>BiomeId.hive);final id=migrated['activeMissionId'];activeMission=id is String?missions.where((m)=>m.id==id).firstOrNull:null;activeOperationModifier=OperationModifier.values.where((e)=>e.name==migrated['activeOperationModifier']).map(OperationModifierSystem.byId).firstOrNull;recentDeaths=(migrated['recentDeaths'] as num?)?.toInt() ?? 0;recentKills=(migrated['recentKills'] as num?)?.toInt() ?? 0;activeBoss=null;enemyStatuses.clear();trackedEnemies.clear();}
}
extension _FirstOrNull<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}
