import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 15: Case V field operations', () {
    final scenarios = <({String ending, String node, String operation, String objective, String successFlag, String choice, String nextEnding})>[
      (ending: 'ending_case5_interrogation', node: 'case_05_field_interrogation', operation: 'case5_interrogation_operation', objective: 'case5_command_registry_secured', successFlag: 'operation_case5_interrogation_secured', choice: 'case5_complete_interrogation_operation', nextEnding: 'ending_case5_field_interrogation'),
      (ending: 'ending_case5_signal_hunt', node: 'case_05_field_signal_intercept', operation: 'case5_signal_intercept_operation', objective: 'case5_mobile_transmitter_disabled', successFlag: 'operation_case5_signal_intercept_secured', choice: 'case5_complete_signal_operation', nextEnding: 'ending_case5_field_signal_intercept'),
      (ending: 'ending_case5_limited_search', node: 'case_05_field_fragment_search', operation: 'case5_fragment_search_operation', objective: 'case5_route_cache_recovered', successFlag: 'operation_case5_fragment_search_secured', choice: 'case5_complete_fragment_operation', nextEnding: 'ending_case5_field_fragment_search'),
    ];

    test('each previous ending opens its own field operation', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = scenario.ending
          ..endingId = scenario.ending;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, scenario.node);
        expect(campaign.currentOperation?.id, scenario.operation);
        expect(campaign.beginCurrentOperation(), isTrue);
        expect(campaign.activeOperationId, scenario.operation);
      }
    });

    test('mission conclusion remains locked until objective, kills and boss are complete', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = scenario.node
          ..flags.add(scenario.successFlag);
        campaign.beginCurrentOperation();
        expect(campaign.choose(scenario.choice), isFalse);
        campaign.collectFieldObjective(scenario.objective);
        final requiredKills = campaign.activeOperation!.requiredKills;
        for (var i = 0; i < requiredKills; i++) {
          campaign.recordActiveOperationKill();
        }
        campaign.recordActiveOperationKill(isBoss: true);
        expect(campaign.activeOperationObjectivesComplete, isTrue);
        campaign.resolveActiveOperation(success: true);
        expect(campaign.choose(scenario.choice), isTrue);
        expect(campaign.currentNodeId, scenario.nextEnding);
        expect(campaign.endingId, scenario.nextEnding);
      }
    });

    test('each operation has a distinct boss profile and attack sequence', () {
      final kinds = <StoryBossKind>[
        StoryBossKind.commandCustodian,
        StoryBossKind.mobileInterceptor,
        StoryBossKind.ambushMarshal,
      ];
      final titles = kinds.map((kind) => StoryBossProfile.forKind(kind).title).toSet();
      expect(titles.length, 3);
      for (final kind in kinds) {
        final profile = StoryBossProfile.forKind(kind);
        expect(profile.phaseOneAttacks, isNotEmpty);
        expect(profile.phaseTwoAttacks, isNotEmpty);
        expect(profile.phaseThreeAttacks, isNotEmpty);
        expect(List.generate(8, (i) => profile.attackModeFor(3, i)), everyElement(inInclusiveRange(0, 4)));
      }
    });

    test('field-operation progress survives save and load', () {
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = scenario.node;
        campaign.beginCurrentOperation();
        campaign.collectFieldObjective(scenario.objective);
        final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
        expect(restored.activeOperationId, scenario.operation);
        expect(restored.operationFieldObjectives, contains(scenario.objective));
      }
    });
  });
}
