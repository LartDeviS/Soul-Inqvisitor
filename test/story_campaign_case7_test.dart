import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 17: Case VII operations', () {
    final scenarios = <({String previousEnding, String node, String operation, String objective, String choice, String finalNode})>[
      (previousEnding: 'ending_case6_registry_audit', node: 'case_07_dead_signatory', operation: 'case7_dead_signatory_operation', objective: 'case7_biometric_key_recovered', choice: 'case7_complete_dead_signatory', finalNode: 'ending_case7_dead_signatory'),
      (previousEnding: 'ending_case6_mobile_pursuit', node: 'case_07_mobile_node', operation: 'case7_mobile_node_operation', objective: 'case7_sync_relay_disabled', choice: 'case7_complete_mobile_node', finalNode: 'ending_case7_mobile_node'),
      (previousEnding: 'ending_case6_supplier_trace', node: 'case_07_supply_convergence', operation: 'case7_supply_convergence_operation', objective: 'case7_original_order_recovered', choice: 'case7_complete_supply_convergence', finalNode: 'ending_case7_supply_convergence'),
    ];
    test('each Case VI result opens its corresponding Case VII operation', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..currentNodeId = scenario.previousEnding..endingId = scenario.previousEnding;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, scenario.node);
        expect(campaign.currentOperation?.id, scenario.operation);
        expect(campaign.beginCurrentOperation(), isTrue);
      }
    });
    test('objective, kill count and boss gate each outcome', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..currentNodeId = scenario.node;
        expect(campaign.beginCurrentOperation(), isTrue);
        expect(campaign.choose(scenario.choice), isFalse);
        campaign.collectFieldObjective(scenario.objective);
        for (var i = 0; i < campaign.activeOperation!.requiredKills; i++) { campaign.recordActiveOperationKill(); }
        campaign.recordActiveOperationKill(isBoss: true);
        campaign.resolveActiveOperation(success: true);
        expect(campaign.choose(scenario.choice), isTrue);
        expect(campaign.currentNodeId, scenario.finalNode);
      }
    });
    test('Case VII boss profiles have distinct identities and attack phases', () {
      final kinds = <StoryBossKind>[StoryBossKind.biometricKeeper, StoryBossKind.syncNodeHunter, StoryBossKind.requisitionMaster];
      expect(kinds.map((kind) => StoryBossProfile.forKind(kind).title).toSet(), hasLength(3));
      for (final kind in kinds) {
        final profile = StoryBossProfile.forKind(kind);
        expect(profile.phaseOneAttacks, isNotEmpty);
        expect(profile.phaseTwoAttacks, isNotEmpty);
        expect(profile.phaseThreeAttacks, isNotEmpty);
      }
    });
  });
}
