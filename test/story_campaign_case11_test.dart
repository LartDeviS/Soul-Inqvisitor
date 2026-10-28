import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 21: consequences of Case X', () {
    test('each Case X ending opens its matching Case XI operation', () {
      final scenarios = <({String ending, String node, String operation, String flag})>[
        (ending: 'ending_case10_trial_evidence', node: 'case_11_trial_counterproof', operation: 'case11_trial_counterproof_operation', flag: 'case11_route_trial_counterproof'),
        (ending: 'ending_case10_cells_cleared', node: 'case_11_cell_sweep', operation: 'case11_cell_sweep_operation', flag: 'case11_route_cell_sweep'),
        (ending: 'ending_case10_shadow_node_claimed', node: 'case_11_network_override', operation: 'case11_network_override_operation', flag: 'case11_route_network_override'),
      ];
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..endingId = scenario.ending;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, scenario.node);
        expect(campaign.currentOperation?.id, scenario.operation);
        expect(campaign.flags, contains(scenario.flag));
      }
    });

    test('Case XI decisions stay locked until kills, field objective and boss are complete', () {
      final scenarios = <({String node, String operation, String objective, String choice, String ending, String flag})>[
        (node: 'case_11_trial_counterproof', operation: 'case11_trial_counterproof_operation', objective: 'case11_counterproof_protocol_seized', choice: 'case11_submit_counterproof', ending: 'ending_case11_counterproof', flag: 'case11_counterproof_verified'),
        (node: 'case_11_cell_sweep', operation: 'case11_cell_sweep_operation', objective: 'case11_fugitive_contacts_recovered', choice: 'case11_burn_fugitive_routes', ending: 'ending_case11_cells_sealed', flag: 'case11_fugitive_routes_sealed'),
        (node: 'case_11_network_override', operation: 'case11_network_override_operation', objective: 'case11_override_key_extracted', choice: 'case11_lock_network_control', ending: 'ending_case11_network_bound', flag: 'case11_manual_control_installed'),
      ];
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..currentNodeId = scenario.node;
        expect(campaign.currentOperation?.id, scenario.operation);
        expect(campaign.beginCurrentOperation(), isTrue);
        expect(campaign.choose(scenario.choice), isFalse);
        campaign.collectFieldObjective(scenario.objective);
        for (var i = 0; i < campaign.activeOperation!.requiredKills; i++) {
          campaign.recordActiveOperationKill();
        }
        campaign.recordActiveOperationKill(isBoss: true);
        campaign.resolveActiveOperation(success: true);
        expect(campaign.choose(scenario.choice), isTrue);
        expect(campaign.currentNodeId, scenario.ending);
        expect(campaign.flags, contains(scenario.flag));
      }
    });

    test('three new bosses have distinct profiles and all attack phases', () {
      final kinds = <StoryBossKind>[
        StoryBossKind.counterproofArchivist,
        StoryBossKind.fugitiveRouteMarshal,
        StoryBossKind.networkOverrideSentinel,
      ];
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
