import 'balance/difficulty_config.dart';
import 'balance/adaptive_difficulty.dart';
import 'balance/floor_balance_profile.dart';
import 'enemies/boss_tactics.dart';
import 'enemies/boss_weak_spots.dart';
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
import '../progression/lore_campaign_system.dart';
import 'combat/wave_director.dart';
import 'weapons/relic_synergy.dart';
import 'missions/procedural_mission_generator.dart';
import 'world/arena_hazards.dart';
import 'weapons/weapon_modifications.dart';
import 'companions/servo_skull_system.dart';
import 'progression/challenge_modes.dart';
import 'progression/codex_challenges.dart';
import 'performance/performance_monitor.dart';
import 'missions/investigation_interactions.dart';
import 'missions/story_campaign.dart';

/// Connected data layer for new combat, world, mission and gear systems.
/// Legacy Flame components remain in main.dart while this facade owns testable domain state.
class InquisitorExpansionSystems {
  final CampaignProgress campaign=CampaignProgress();
  final WaveDirector waveDirector = WaveDirector();
  final RelicSynergySystem relicSynergies = RelicSynergySystem();
  final ProceduralMissionGenerator missionGenerator = ProceduralMissionGenerator();
  ProceduralMission? activeProceduralMission;
  ProceduralMission generateProceduralMission({required int seed, int floor = 1}) {
    final generated = missionGenerator.generate(seed: seed, floor: floor);
    activeProceduralMission = generated;
    return generated;
  }
  bool collectFieldEvidence(String evidenceId) => fieldInvestigations.collect(evidenceId);
  bool interrogateFieldWitness(String witnessId) => fieldInvestigations.interrogate(witnessId);
  final ArenaHazardSystem arenaHazards = ArenaHazardSystem();
  final WeaponModificationSystem weaponModifications = WeaponModificationSystem();
  final ServoSkullSystem servoSkulls = ServoSkullSystem();
  final CodexChallengeSystem codexChallenges = CodexChallengeSystem();
  final PerformanceMonitor performance = PerformanceMonitor();
  final InvestigationInteractionSystem fieldInvestigations = InvestigationInteractionSystem();
  final StoryCampaignSystem storyCampaign = StoryCampaignSystem();
  ChallengeMode? activeChallengeMode;
  final OrdoReputation ordoReputation = OrdoReputation();
  final CampaignConsequences campaignConsequences = CampaignConsequences();
  final Map<String, InvestigationState> investigations = <String, InvestigationState>{};
  final Set<String> studiedEnemyDossiers = <String>{};
  final Set<String> acquiredRelics = <String>{};
  final Map<String, BranchingContract> branchingContracts = {for (final c in BranchingContractCatalog.all) c.id: c};
  int studyEnemy(String enemyId) {
    final dossier = EnemyDossierCatalog.byId(enemyId);
    if (dossier == null || !studiedEnemyDossiers.add(enemyId)) return 0;
    progression.grantExperience(dossier.studyReward);
    return dossier.studyReward;
  }
  InvestigationState beginInvestigation({required String id, required String title, required String briefing}) {
    return investigations.putIfAbsent(id, () => InvestigationState(id: id, title: title, briefing: briefing));
  }
  bool collectInvestigationEvidence(String investigationId, String evidenceId) => investigations[investigationId]?.collectEvidence(evidenceId) ?? false;
  bool interrogateWitness(String investigationId, String witnessId) => investigations[investigationId]?.interrogate(witnessId) ?? false;
  Map<String, int>? concludeInvestigation(String investigationId, InvestigationDecision decision) {
    final investigation = investigations[investigationId];
    if (investigation == null || investigation.completed) return null;
    final result = investigation.conclude(decision);
    campaign.investigationClues += result['clues'] ?? 0;
    campaign.requisition += result['requisition'] ?? 0;
    campaign.alarm = (campaign.alarm + (result['alarm'] ?? 0)).clamp(0, 100).toInt();
    ordoReputation.add('hereticus', result['reputation'] ?? 0);
    if (decision == InvestigationDecision.rapidPurge) campaignConsequences.recordSectorPurged();
    return result;
  }
  bool chooseBranchingContractRoute(String contractId, String routeId) => branchingContracts[contractId]?.choose(routeId) ?? false;
  bool acquireRelic(String relicId) => RelicCatalog.byId(relicId) != null && acquiredRelics.add(relicId);
  double get relicDamageMultiplier => acquiredRelics.fold<double>(1.0, (value, id) => value * (RelicCatalog.byId(id)?.damageMultiplier ?? 1.0));
  double get relicIncomingDamageMultiplier => acquiredRelics.fold<double>(1.0, (value, id) => value * (RelicCatalog.byId(id)?.incomingDamageMultiplier ?? 1.0));
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
  BossAttackRuntime? activeBossAttack;
  FloorBalanceProfile get floorBalance => FloorBalanceProfile.calculate(
    floor: activeMission?.floor ?? 1, recentDeaths: recentDeaths, recentKills: recentKills,
    difficultyHp: difficulty.hpMultiplier, difficultyDamage: difficulty.damageMultiplier,
    difficultySpawn: difficulty.spawnMultiplier);
  bool get bossAttackResolved => _bossAttackResolved;
  bool _bossAttackResolved = false;
  String? get bossAttackWarning => activeBossAttack?.warning;
  BossHitZoneResult resolveBossHit({required HitPoint normalizedPoint, int baseDamage = 10, double phaseMultiplier = 1}) {
    final hit = BossWeakSpotSystem.resolve(normalizedPoint: normalizedPoint, weakSpotExposed: activeBoss?.isWeakSpotExposed ?? false);
    if (activeBoss != null) {
      final damage = BossWeakSpotSystem.applyDamage(baseDamage: baseDamage, point: normalizedPoint,
        weakSpotExposed: activeBoss!.isWeakSpotExposed, phaseMultiplier: phaseMultiplier);
      activeBoss!.applyDamage(damage.round());
    }
    return hit;
  }
  final Map<String, Set<CombatStatus>> enemyStatuses = {};
  int recentDeaths = 0;
  int recentKills = 0;
  AdaptiveDifficulty get adaptiveDifficulty => AdaptiveDifficulty.calculate(floor: activeMission?.floor ?? 1, recentDeaths: recentDeaths, recentKills: recentKills, baseHp: difficulty.hpMultiplier, baseDamage: difficulty.damageMultiplier, baseSpawn: difficulty.spawnMultiplier);
  SynergyResult resolveWeaponHit({required String enemyId, required String targetFaction, required DamageType weaponType, bool armorPiercing = false}) { final current = enemyStatuses[enemyId] ?? <CombatStatus>{}; final result = WeaponSynergySystem.resolve(weaponType: weaponType, targetStatuses: current, targetFaction: targetFaction, armorPiercing: armorPiercing); enemyStatuses[enemyId] = {...current, ...result.appliedStatuses}; return result; }
  void startBoss({required String id, required int hp}) { activeBoss = BossEncounter(bossId: id, maxHp: hp); activeBossAttack = BossAttackRuntime(bossId: id); }
  void updateCombatSystems(double dt) { activeBoss?.update(dt); _bossAttackResolved = activeBossAttack?.update(dt) ?? false; weapons.update(dt); }
  void recordPlayerDeath() { recentDeaths++; }
  final MissionEventDirector missionEvents=MissionEventDirector();
  final ExpansionSaveManager saves=ExpansionSaveManager();
  DifficultyConfig difficulty=DifficultyConfig.normal;
  BiomeId biome=BiomeId.hive;
  MissionData? activeMission;
  WorldEvent? activeWorldEvent;
  MissionEvent? activeMissionEvent;
  final List<EnemyRuntimeState> trackedEnemies=[];
  void beginMission(MissionData mission,{BiomeId? selectedBiome,DifficultyConfig? selectedDifficulty,int? seed}) {activeMission=mission;if(selectedBiome!=null)biome=selectedBiome;if(selectedDifficulty!=null)difficulty=selectedDifficulty;campaign.beginMission(mission.id);activeWorldEvent=world.rollEvent(biome,floor:mission.floor,seed:seed);activeOperationModifier=operationModifiers.roll(seed:seed == null ? null : seed + 41);activeBoss=null;activeBossAttack=null;_bossAttackResolved=false;enemyStatuses.clear();activeMissionEvent=missionEvents.roll(floor:mission.floor,alarm:campaign.alarm,seed:seed==null?null:seed+17);trackedEnemies.clear();}
  void recordEnemyDefeated(EnemyRuntimeState enemy){enemy.isDefeated=true;recentKills++;campaign.recordKill(enemy.type.faction.name);contracts.recordKill(elite:enemy.type.archetype==EnemyArchetype.heavy||enemy.type.archetype==EnemyArchetype.sniper);progression.grantExperience(12);}
  void recordCacheFound(){contracts.recordCache();campaign.requisition+=activeWorldEvent?.requisition??5;progression.grantExperience(8);}
  Map<String,dynamic> toJson()=>{'schemaVersion':8,'systems':{'storyCampaign':storyCampaign.toJson(),'waveDirector':waveDirector.toJson(),'arenaHazards':arenaHazards.hazards.map((e)=>e.toJson()).toList(),'weaponModifications':weaponModifications.toJson(),'servoSkulls':servoSkulls.toJson(),'codexChallenges':codexChallenges.toJson(),'fieldInvestigations':fieldInvestigations.toJson(),'proceduralMission':activeProceduralMission?.toJson(),'activeChallengeMode':activeChallengeMode?.id},'loreStage4':{'ordoReputation':ordoReputation.toJson(),'campaignConsequences':campaignConsequences.toJson(),'investigations':investigations.map((k,v)=>MapEntry(k,v.toJson())),'studiedEnemyDossiers':studiedEnemyDossiers.toList(),'acquiredRelics':acquiredRelics.toList(),'branchingContracts':branchingContracts.map((k,v)=>MapEntry(k,v.toJson()))},'campaign':campaign.toJson(),'inventory':inventory.toJson(),'weapons':weapons.toJson(),'ordoDoctrine':ordoDoctrine.toJson(),'progression':progression.toJson(),'contracts':contracts.toJson(),'difficulty':difficulty.id,'biome':biome.name,'activeMissionId':activeMission?.id,'activeWorldEvent':activeWorldEvent?.type.name,'activeMissionEvent':activeMissionEvent?.type.name,'activeOperationModifier':activeOperationModifier?.id.name,'recentDeaths':recentDeaths,'recentKills':recentKills};
  void loadJson(dynamic input,{List<MissionData> missions=const[]}){final migrated=SaveMigration.migrate(input);final lore=migrated['loreStage4'];if(lore is Map){ordoReputation.loadJson(lore['ordoReputation']);campaignConsequences.loadJson(lore['campaignConsequences']);studiedEnemyDossiers..clear()..addAll((lore['studiedEnemyDossiers'] as List? ?? const []).whereType<String>());acquiredRelics..clear()..addAll((lore['acquiredRelics'] as List? ?? const []).whereType<String>());investigations.clear();if(lore['investigations'] is Map){(lore['investigations'] as Map).forEach((key,value){if(key is String && value is Map){final item=InvestigationState(id:key,title:value['title'] as String? ?? key,briefing:value['briefing'] as String? ?? '');item.loadJson(value);investigations[key]=item;}});}if(lore['branchingContracts'] is Map){(lore['branchingContracts'] as Map).forEach((key,value){final contract=branchingContracts[key];if(contract!=null && value is Map){contract.choose(value['selectedRouteId'] as String? ?? contract.selectedRouteId);contract.completed=value['completed']==true;}});}}final systems=migrated['systems'];if(systems is Map){storyCampaign.loadJson(systems['storyCampaign']);waveDirector.loadJson(systems['waveDirector']);arenaHazards.loadJson(systems['arenaHazards']);weaponModifications.loadJson(systems['weaponModifications']);servoSkulls.loadJson(systems['servoSkulls']);codexChallenges.loadJson(systems['codexChallenges']);fieldInvestigations.loadJson(systems['fieldInvestigations']);activeProceduralMission=ProceduralMission.fromJson(systems['proceduralMission']);activeChallengeMode=ChallengeModeCatalog.byId(systems['activeChallengeMode'] is String ? systems['activeChallengeMode'] as String : '');}campaign.loadJson(migrated['campaign']);inventory.loadJson(migrated['inventory']);weapons.loadJson(migrated['weapons']);ordoDoctrine=OrdoDoctrine.fromJson(migrated['ordoDoctrine']);progression.loadJson(migrated['progression']);contracts.loadJson(migrated['contracts']);difficulty=DifficultyConfig.byId(migrated['difficulty'] as String? ?? 'normal');biome=BiomeId.values.firstWhere((e)=>e.name==migrated['biome'],orElse:()=>BiomeId.hive);final id=migrated['activeMissionId'];activeMission=id is String?missions.where((m)=>m.id==id).firstOrNull:null;activeOperationModifier=OperationModifier.values.where((e)=>e.name==migrated['activeOperationModifier']).map(OperationModifierSystem.byId).firstOrNull;recentDeaths=(migrated['recentDeaths'] as num?)?.toInt() ?? 0;recentKills=(migrated['recentKills'] as num?)?.toInt() ?? 0;activeBoss=null;activeBossAttack=null;_bossAttackResolved=false;enemyStatuses.clear();trackedEnemies.clear();}
}
extension _FirstOrNull<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}
