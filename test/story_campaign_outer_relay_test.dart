import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 13: outer relay aftermath and choices', () {
    StoryCampaignSystem prepareRoute(String evidenceId, String submitChoice) {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'ending_sector_restored'
        ..endingId = 'ending_sector_restored';
      campaign.continueAfterEnding();
      campaign.choose('follow_reconstruction_signal');
      campaign.collectEvidence(evidenceId);
      campaign.choose(submitChoice);
      return campaign;
    }

    test('civilian route leads to the required field operation', () {
      final campaign = prepareRoute('case4_civilian_trace', 'submit_civilian_trace');
      expect(campaign.currentNodeId, 'case_04_signal_review');
      expect(campaign.choose('authorize_outer_relay_expedition'), isTrue);
      expect(campaign.currentOperation?.id, 'secure_outer_relay');
      expect(campaign.currentNodeId, 'case_04_field_operation');
      expect(campaign.availableChoices.map((choice) => choice.id), isNot(contains('complete_outer_relay_operation')));
    });


    test('military, quarantine and residual clues also launch the operation', () {
      final cases = <({String ending, String route, String evidence, String submit, String authorize})>[
        (ending: 'ending_military_occupation', route: 'follow_military_audit', evidence: 'case4_garrison_log', submit: 'submit_garrison_log', authorize: 'authorize_garrison_audit'),
        (ending: 'ending_sector_quarantine', route: 'follow_quarantine_beacon', evidence: 'case4_quarantine_packet', submit: 'submit_quarantine_packet', authorize: 'authorize_quarantine_probe'),
        (ending: 'ending_justice', route: 'follow_residual_signal', evidence: 'case4_residual_fragment', submit: 'submit_residual_fragment', authorize: 'authorize_limited_expedition'),
      ];
      for (final scenario in cases) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = scenario.ending
          ..endingId = scenario.ending;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.choose(scenario.route), isTrue);
        expect(campaign.collectEvidence(scenario.evidence), isTrue);
        expect(campaign.choose(scenario.submit), isTrue);
        expect(campaign.choose(scenario.authorize), isTrue);
        expect(campaign.currentNodeId, 'case_04_field_operation');
        expect(campaign.currentOperation?.id, 'secure_outer_relay');
      }
    });

    test('the ending is locked until objective, kills and sentinel are complete', () {
      final campaign = prepareRoute('case4_civilian_trace', 'submit_civilian_trace');
      campaign.choose('authorize_outer_relay_expedition');
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.choose('complete_outer_relay_operation'), isFalse);
      expect(campaign.collectFieldObjective('outer_relay_uplink_secured'), isTrue);
      for (var i = 0; i < 8; i++) {
        campaign.recordActiveOperationKill();
      }
      expect(campaign.activeOperationObjectivesComplete, isFalse);
      campaign.recordActiveOperationKill(isBoss: true);
      expect(campaign.activeOperationObjectivesComplete, isTrue);
      campaign.resolveActiveOperation(success: true);
      expect(campaign.availableChoices.map((choice) => choice.id), contains('complete_outer_relay_operation'));
      expect(campaign.choose('complete_outer_relay_operation'), isTrue);
      expect(campaign.currentNodeId, 'case_04_relay_aftermath');
      expect(campaign.endingId, isNull);
    });

    test('route evidence changes tactical support rank', () {
      final civilian = prepareRoute('case4_civilian_trace', 'submit_civilian_trace');
      civilian.choose('authorize_outer_relay_expedition');
      expect(civilian.activeOperationSupportRank, 2);

      final residual = StoryCampaignSystem()
        ..currentNodeId = 'ending_military_occupation'
        ..endingId = 'ending_military_occupation';
      residual.continueAfterEnding();
      residual.flags.add('prior_ending_other');
      residual.choose('follow_residual_signal');
      residual.collectEvidence('case4_residual_fragment');
      residual.choose('submit_residual_fragment');
      residual.choose('authorize_limited_expedition');
      expect(residual.activeOperationSupportRank, 0);
    });

    test('relay sentinel has its own profile and deterministic attacks', () {
      final profile = StoryBossProfile.forKind(StoryBossKind.relaySentinel);
      expect(profile.title, contains('ретранслятора'));
      expect(profile.healthMultiplier, greaterThan(1.0));
      expect(profile.attackModeFor(1, 0), profile.attackModeFor(1, 0));
      expect(List.generate(6, (i) => profile.attackModeFor(3, i)), everyElement(inInclusiveRange(0, 4)));
    });

    test('operation state and route flags survive save/load', () {
      final campaign = prepareRoute('case4_civilian_trace', 'submit_civilian_trace');
      campaign.choose('authorize_outer_relay_expedition');
      campaign.beginCurrentOperation();
      campaign.collectFieldObjective('outer_relay_uplink_secured');
      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.activeOperationId, 'secure_outer_relay');
      expect(restored.operationFieldObjectives, contains('outer_relay_uplink_secured'));
      expect(restored.flags, contains('case4_route_civilian'));
    });

    test('all three post-operation choices lead to distinct endings and flags', () {
      final scenarios = <({String choice, String ending, String flag})>[
        (choice: 'capture_relay_operator', ending: 'ending_case4_operator_captured', flag: 'case4_operator_alive'),
        (choice: 'extract_relay_data', ending: 'ending_case4_data_extracted', flag: 'case4_data_extracted'),
        (choice: 'destroy_outer_relay', ending: 'ending_case4_relay_destroyed', flag: 'case4_signal_suppressed'),
      ];
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = 'case_04_relay_aftermath'
          ..flags.add('case4_expedition_completed');
        expect(campaign.choose(scenario.choice), isTrue);
        expect(campaign.currentNodeId, scenario.ending);
        expect(campaign.endingId, scenario.ending);
        expect(campaign.flags, contains(scenario.flag));
      }
    });

    test('post-operation choices stay locked until the field operation is complete', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'case_04_relay_aftermath';
      expect(campaign.availableChoices, isEmpty);
      expect(campaign.choose('destroy_outer_relay'), isFalse);
      campaign.flags.add('case4_expedition_completed');
      expect(campaign.availableChoices.length, 3);
    });

    test('branch decision survives save and load', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'case_04_relay_aftermath'
        ..flags.addAll(<String>{'case4_expedition_completed', 'case4_route_civilian'});
      expect(campaign.choose('extract_relay_data'), isTrue);
      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.currentNodeId, 'ending_case4_data_extracted');
      expect(restored.flags, contains('case4_relay_intact'));
      expect(restored.decisions['case_04_relay_aftermath'], 'extract_relay_data');
    });
  });
}
