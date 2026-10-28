import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 16: Case VI follow-up operations', () {
    final scenarios = <({String previousEnding, String node, String operation, String objective, String successFlag, String choice, String finalNode})>[
      (previousEnding: 'ending_case5_field_interrogation', node: 'case_06_registry_audit', operation: 'case6_registry_audit_operation', objective: 'case6_authority_ledger_seized', successFlag: 'operation_case6_registry_audit_secured', choice: 'case6_complete_registry_audit', finalNode: 'ending_case6_registry_audit'),
      (previousEnding: 'ending_case5_field_signal_intercept', node: 'case_06_mobile_pursuit', operation: 'case6_mobile_pursuit_operation', objective: 'case6_tracking_beacon_disabled', successFlag: 'operation_case6_mobile_pursuit_secured', choice: 'case6_complete_mobile_pursuit', finalNode: 'ending_case6_mobile_pursuit'),
      (previousEnding: 'ending_case5_field_fragment_search', node: 'case_06_supplier_trace', operation: 'case6_supplier_trace_operation', objective: 'case6_supplier_manifest_recovered', successFlag: 'operation_case6_supplier_trace_secured', choice: 'case6_complete_supplier_trace', finalNode: 'ending_case6_supplier_trace'),
    ];

    test('each Case V field result opens its matching Case VI operation', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = scenario.previousEnding
          ..endingId = scenario.previousEnding;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, scenario.node);
        expect(campaign.currentOperation?.id, scenario.operation);
        expect(campaign.beginCurrentOperation(), isTrue);
      }
    });

    test('the evidence, kill and boss requirements gate each operation ending', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..currentNodeId = scenario.node;
        expect(campaign.beginCurrentOperation(), isTrue);
        expect(campaign.choose(scenario.choice), isFalse);
        campaign.collectFieldObjective(scenario.objective);
        for (var i = 0; i < campaign.activeOperation!.requiredKills; i++) {
          campaign.recordActiveOperationKill();
        }
        campaign.recordActiveOperationKill(isBoss: true);
        expect(campaign.activeOperationObjectivesComplete, isTrue);
        campaign.resolveActiveOperation(success: true);
        expect(campaign.choose(scenario.choice), isTrue);
        expect(campaign.currentNodeId, scenario.finalNode);
      }
    });

    test('new Case VI bosses have distinct profiles and valid attack modes', () {
      final kinds = <StoryBossKind>[
        StoryBossKind.authorityAuditor,
        StoryBossKind.signalPursuer,
        StoryBossKind.supplyLineEnforcer,
      ];
      expect(kinds.map((kind) => StoryBossProfile.forKind(kind).title).toSet(), hasLength(3));
      for (final kind in kinds) {
        final profile = StoryBossProfile.forKind(kind);
        expect(profile.phaseOneAttacks, isNotEmpty);
        expect(profile.phaseTwoAttacks, isNotEmpty);
        expect(profile.phaseThreeAttacks, isNotEmpty);
        expect(List.generate(12, (i) => profile.attackModeFor(3, i)), everyElement(inInclusiveRange(0, 4)));
      }
    });

    test('active operation and objective survive JSON save/load', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..currentNodeId = scenario.node;
        campaign.beginCurrentOperation();
        campaign.collectFieldObjective(scenario.objective);
        final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
        expect(restored.activeOperationId, scenario.operation);
        expect(restored.operationFieldObjectives, contains(scenario.objective));
      }
    });
  });
}
