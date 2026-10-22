import 'package:flutter_test/flutter_test.dart';
import 'package:soul_of_the_inquisitor/progression/lore_campaign_system.dart';

void main(){
 group('Stage IV lore and campaign systems',(){
  test('enemy dossiers are available by stable enemy id',(){expect(EnemyDossierCatalog.byId('warp_summoner'),isNotNull);expect(EnemyDossierCatalog.byId('unknown'),isNull);});
  test('preserving evidence and rapid purge have distinct consequences',(){final investigation=InvestigationState(id:'i1',title:'Тест',briefing:'Тест');investigation.collectEvidence('ledger');investigation.interrogate('witness');final careful=investigation.conclude(InvestigationDecision.preserveEvidence);expect(careful['clues'],2);expect(careful['alarm'],-2);final fast=InvestigationState(id:'i2',title:'Тест',briefing:'Тест').conclude(InvestigationDecision.rapidPurge);expect(fast['requisition'],greaterThan(careful['requisition']!));expect(fast['alarm'],greaterThan(0));});
  test('Ordo standing unlocks orders and is clamped',(){final rep=OrdoReputation();rep.add('malleus',12);expect(rep.unlocks('malleus'),isTrue);rep.add('malleus',500);expect(rep.standing('malleus'),100);});
  test('relics have explicit trade-offs',(){expect(RelicCatalog.byId('cursed_round')!.damageMultiplier,greaterThan(1));expect(RelicCatalog.byId('cursed_round')!.incomingDamageMultiplier,greaterThan(1));});
  test('branching contract rejects invalid route and accepts valid route',(){final c=BranchingContractCatalog.byId('ash_and_truth')!;expect(c.choose('not-a-route'),isFalse);expect(c.choose('evidence'),isTrue);expect(c.selectedRoute!.requisitionReward,20);});
  test('saved witnesses and recovered intel alter future briefing',(){final c=CampaignConsequences();c.recordWitnessSaved();expect(c.informantNetworkAvailable,isTrue);expect(c.nextBriefing,contains('безопасный маршрут'));c.recordEvidenceDestroyed(3);expect(c.informantNetworkAvailable,isFalse);expect(c.nextBriefing,contains('Улики уничтожены'));});
 });
}
