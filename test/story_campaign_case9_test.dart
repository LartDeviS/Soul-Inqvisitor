import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 19: Case IX coordinator confrontation', () {
    test('Case VIII ending reveals coordinator identity and opens Case IX', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'ending_case8_origin_convergence'
        ..endingId = 'ending_case8_origin_convergence';

      expect(campaign.continueAfterEnding(), isTrue);
      expect(campaign.currentNodeId, 'case_09_coordinator_confrontation');
      expect(campaign.currentOperation?.id, 'case9_coordinator_confrontation_operation');
      expect(campaign.flags, contains('case9_root_order_decoded'));
      expect(campaign.flags, contains('case9_coordinator_identity_revealed'));
      expect(campaign.beginCurrentOperation(), isTrue);
    });

    test('final decision remains locked until objective, kills and boss are complete', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'case_09_coordinator_confrontation';
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.choose('case9_capture_voss'), isFalse);
      campaign.collectFieldObjective('case9_identity_ledger_secured');
      for (var i = 0; i < campaign.activeOperation!.requiredKills; i++) {
        campaign.recordActiveOperationKill();
      }
      campaign.recordActiveOperationKill(isBoss: true);
      campaign.resolveActiveOperation(success: true);
      expect(campaign.choose('case9_capture_voss'), isTrue);
      expect(campaign.currentNodeId, 'ending_case9_capture_voss');
      expect(campaign.flags, contains('case9_voss_captured'));
    });

    test('all three strategic choices have separate endings and consequences', () {
      final choices = <({String id, String ending, String flag})>[
        (id: 'case9_capture_voss', ending: 'ending_case9_capture_voss', flag: 'case9_voss_captured'),
        (id: 'case9_destroy_network', ending: 'ending_case9_network_destroyed', flag: 'case9_network_destroyed'),
        (id: 'case9_turn_network', ending: 'ending_case9_network_repurposed', flag: 'case9_network_repurposed'),
      ];
      for (final scenario in choices) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = 'case_09_coordinator_confrontation'
          ..flags.add('operation_case9_coordinator_confrontation_secured');
        expect(campaign.choose(scenario.id), isTrue);
        expect(campaign.currentNodeId, scenario.ending);
        expect(campaign.flags, contains(scenario.flag));
        expect(campaign.completed, isTrue);
        expect(campaign.continueAfterEnding(), isFalse);
        expect(campaign.currentNodeId, scenario.ending);
      }
    });


    test('each Case IX decision opens its matching Case X branch', () {
      final routes = <({String ending, String node, String flag, String operation})>[
        (ending: 'ending_case9_capture_voss', node: 'case_10_trial_evidence', flag: 'case10_route_trial', operation: 'case10_trial_evidence_operation'),
        (ending: 'ending_case9_network_destroyed', node: 'case_10_cell_cleanup', flag: 'case10_route_cell_cleanup', operation: 'case10_cell_cleanup_operation'),
        (ending: 'ending_case9_network_repurposed', node: 'case_10_shadow_network', flag: 'case10_route_shadow_network', operation: 'case10_shadow_network_operation'),
      ];
      for (final route in routes) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = route.ending
          ..endingId = route.ending;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, route.node);
        expect(campaign.flags, contains(route.flag));
        expect(campaign.currentOperation?.id, route.operation);
      }
    });

    test('Magister Voss has a unique three-phase boss profile', () {
      final profile = StoryBossProfile.forKind(StoryBossKind.deadSignatoryMagister);
      expect(profile.title, 'Магистр Севериан Восс');
      expect(profile.phaseOneAttacks, isNotEmpty);
      expect(profile.phaseTwoAttacks, isNotEmpty);
      expect(profile.phaseThreeAttacks, isNotEmpty);
      expect(StoryBossProfile.all.values.map((p) => p.title).toSet(), hasLength(18));
    });
  });
}
