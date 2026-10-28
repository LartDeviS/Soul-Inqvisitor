import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 22: consequences of Case XI', () {
    test('each Case XI ending opens its matching Case XII operation', () {
      final scenarios = <({String ending, String node, String operation, String flag})>[
        (ending: 'ending_case11_counterproof', node: 'case_12_tribunal_conspiracy', operation: 'case12_tribunal_conspiracy_operation', flag: 'case12_route_tribunal_conspiracy'),
        (ending: 'ending_case11_cells_sealed', node: 'case_12_purge_allies', operation: 'case12_purge_allies_operation', flag: 'case12_route_purge_allies'),
        (ending: 'ending_case11_network_bound', node: 'case_12_inquisitorial_control', operation: 'case12_inquisitorial_control_operation', flag: 'case12_route_inquisitorial_control'),
      ];
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..endingId = scenario.ending;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, scenario.node);
        expect(campaign.currentOperation?.id, scenario.operation);
        expect(campaign.flags, contains(scenario.flag));
      }
    });

    test('Case XII choices remain locked until kills, field objective and boss are complete', () {
      final scenarios = <({String node, String operation, String objective, String choice, String ending, String flag})>[
        (node: 'case_12_tribunal_conspiracy', operation: 'case12_tribunal_conspiracy_operation', objective: 'case12_patron_list_recovered', choice: 'case12_submit_patron_list', ending: 'ending_case12_tribunal_exposed', flag: 'case12_patron_network_exposed'),
        (node: 'case_12_purge_allies', operation: 'case12_purge_allies_operation', objective: 'case12_evacuation_channel_intercepted', choice: 'case12_seal_evacuation_channel', ending: 'ending_case12_evacuation_cut', flag: 'case12_evacuation_network_cut'),
        (node: 'case_12_inquisitorial_control', operation: 'case12_inquisitorial_control_operation', objective: 'case12_manual_control_log_seized', choice: 'case12_confirm_manual_authority', ending: 'ending_case12_manual_authority', flag: 'case12_manual_authority_confirmed'),
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

    test('three new bosses have unique profiles and all attack phases', () {
      final kinds = <StoryBossKind>[
        StoryBossKind.tribunalConspirator,
        StoryBossKind.evacuationInterdictor,
        StoryBossKind.authorityArbiter,
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
