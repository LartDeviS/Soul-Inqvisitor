import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 18: Case VIII evidence convergence', () {
    final scenarios = <({String previousEnding, String sourceFlag})>[
      (previousEnding: 'ending_case7_dead_signatory', sourceFlag: 'case8_evidence_biometric_key'),
      (previousEnding: 'ending_case7_mobile_node', sourceFlag: 'case8_evidence_sync_schedule'),
      (previousEnding: 'ending_case7_supply_convergence', sourceFlag: 'case8_evidence_original_order'),
    ];

    test('all three Case VII routes converge on the same operation', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = scenario.previousEnding
          ..endingId = scenario.previousEnding;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, 'case_08_origin_convergence');
        expect(campaign.currentOperation?.id, 'case8_origin_convergence_operation');
        expect(campaign.flags, contains(scenario.sourceFlag));
        expect(campaign.flags, contains('case8_converged_from_case7'));
        expect(campaign.beginCurrentOperation(), isTrue);
      }
    });

    test('root order cannot be claimed before the objective, kills and boss are complete', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'case_08_origin_convergence';
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.choose('case8_complete_origin_convergence'), isFalse);
      campaign.collectFieldObjective('case8_root_order_recovered');
      for (var i = 0; i < campaign.activeOperation!.requiredKills; i++) {
        campaign.recordActiveOperationKill();
      }
      campaign.recordActiveOperationKill(isBoss: true);
      campaign.resolveActiveOperation(success: true);
      expect(campaign.choose('case8_complete_origin_convergence'), isTrue);
      expect(campaign.currentNodeId, 'ending_case8_origin_convergence');
      expect(campaign.flags, contains('case8_root_order_verified'));
      expect(campaign.flags, contains('case8_three_evidence_chains_unified'));
    });

    test('the new coordinator has a distinct, valid three-phase profile', () {
      final profile = StoryBossProfile.forKind(StoryBossKind.rootOrderCoordinator);
      expect(profile.title, 'Координатор корневого приказа');
      expect(profile.phaseOneAttacks, isNotEmpty);
      expect(profile.phaseTwoAttacks, isNotEmpty);
      expect(profile.phaseThreeAttacks, isNotEmpty);
      for (var phase = 1; phase <= 3; phase++) {
        for (var i = 0; i < 30; i++) {
          expect(profile.attackModeFor(phase, i), inInclusiveRange(0, 4));
        }
      }
    });

    test('convergence flags and active operation survive JSON save/load', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'ending_case7_mobile_node'
        ..endingId = 'ending_case7_mobile_node';
      expect(campaign.continueAfterEnding(), isTrue);
      campaign.beginCurrentOperation();
      campaign.collectFieldObjective('case8_root_order_recovered');
      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.activeOperationId, 'case8_origin_convergence_operation');
      expect(restored.flags, contains('case8_evidence_sync_schedule'));
      expect(restored.operationFieldObjectives, contains('case8_root_order_recovered'));
    });
  });
}
