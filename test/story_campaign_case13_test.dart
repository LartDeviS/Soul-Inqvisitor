import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 23: consequences of Case XII', () {
    test('each Case XII ending opens its matching Case XIII operation', () {
      final scenarios = <({String ending, String node, String operation, String flag})>[
        (ending: 'ending_case12_tribunal_exposed', node: 'case_13_independent_inquiry', operation: 'case13_independent_inquiry_operation', flag: 'case13_route_independent_inquiry'),
        (ending: 'ending_case12_evacuation_cut', node: 'case_13_military_pursuit', operation: 'case13_military_pursuit_operation', flag: 'case13_route_military_pursuit'),
        (ending: 'ending_case12_manual_authority', node: 'case_13_controlled_network', operation: 'case13_controlled_network_operation', flag: 'case13_route_controlled_network'),
      ];
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..endingId = scenario.ending;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, scenario.node);
        expect(campaign.currentOperation?.id, scenario.operation);
        expect(campaign.flags, contains(scenario.flag));
      }
    });

    test('Case XIII choices require operation completion and preserve branch consequences', () {
      final scenarios = <({String node, String operation, String objective, String choice, String ending, String flag})>[
        (node: 'case_13_independent_inquiry', operation: 'case13_independent_inquiry_operation', objective: 'case13_original_orders_recovered', choice: 'case13_publish_original_orders', ending: 'ending_case13_independent_record', flag: 'case13_witnesses_protected'),
        (node: 'case_13_military_pursuit', operation: 'case13_military_pursuit_operation', objective: 'case13_convoy_registry_seized', choice: 'case13_seize_convoy_registry', ending: 'ending_case13_convoy_broken', flag: 'case13_military_trust_lost'),
        (node: 'case_13_controlled_network', operation: 'case13_controlled_network_operation', objective: 'case13_control_key_verified', choice: 'case13_sever_autonomous_protocol', ending: 'ending_case13_network_audited', flag: 'case13_audit_required'),
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

    test('Case XIII bosses have unique profiles and all three attack phases', () {
      final kinds = <StoryBossKind>[
        StoryBossKind.witnessExecutioner,
        StoryBossKind.convoyReclaimer,
        StoryBossKind.autonomyDaemon,
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
