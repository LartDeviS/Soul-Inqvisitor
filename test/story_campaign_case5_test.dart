import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';

void main() {
  group('Update 14: case V follows the outer-relay decision', () {
    final scenarios = <({String ending, String route, String evidence, String submit, String review, String finalNode, String flag})>[
      (ending: 'ending_case4_operator_captured', route: 'case5_follow_interrogation', evidence: 'case5_operator_testimony', submit: 'case5_submit_testimony', review: 'case5_authorize_interrogation_lead', finalNode: 'ending_case5_interrogation', flag: 'case5_operation_interrogation'),
      (ending: 'ending_case4_data_extracted', route: 'case5_follow_signal_trace', evidence: 'case5_signal_coordinates', submit: 'case5_submit_coordinates', review: 'case5_authorize_signal_hunt', finalNode: 'ending_case5_signal_hunt', flag: 'case5_operation_signal_hunt'),
      (ending: 'ending_case4_relay_destroyed', route: 'case5_follow_fragment', evidence: 'case5_fragmentary_route', submit: 'case5_submit_fragment', review: 'case5_authorize_limited_search', finalNode: 'ending_case5_limited_search', flag: 'case5_operation_limited_search'),
    ];

    for (final scenario in scenarios) {
      test('${scenario.ending} unlocks only its matching investigation route', () {
        final campaign = StoryCampaignSystem()
          ..currentNodeId = scenario.ending
          ..endingId = scenario.ending;
        expect(campaign.continueAfterEnding(), isTrue);
        expect(campaign.currentNodeId, 'case_05_dispatch');
        expect(campaign.chapterNumber, 5);
        expect(campaign.availableChoices.map((choice) => choice.id), contains(scenario.route));
        expect(campaign.choose(scenario.route), isTrue);
        expect(campaign.currentNodeId.startsWith('case_05_'), isTrue);
        expect(campaign.choose(scenario.submit), isFalse, reason: 'evidence must be collected before submission');
        expect(campaign.collectEvidence(scenario.evidence), isTrue);
        expect(campaign.choose(scenario.submit), isTrue);
        expect(campaign.currentNodeId, 'case_05_evidence_review');
        expect(campaign.choose(scenario.review), isTrue);
        expect(campaign.currentNodeId, scenario.finalNode);
        expect(campaign.endingId, scenario.finalNode);
        expect(campaign.flags, contains(scenario.flag));
      });
    }

    test('legacy fourth-case ending safely falls back to fragmentary search', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'ending_case4_expedition'
        ..endingId = 'ending_case4_expedition';
      expect(campaign.continueAfterEnding(), isTrue);
      expect(campaign.currentNodeId, 'case_05_dispatch');
      expect(campaign.availableChoices.map((choice) => choice.id), contains('case5_follow_fragment'));
    });

    test('branch and evidence survive serialization', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'ending_case4_data_extracted'
        ..endingId = 'ending_case4_data_extracted';
      campaign.continueAfterEnding();
      campaign.choose('case5_follow_signal_trace');
      campaign.collectEvidence('case5_signal_coordinates');
      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.currentNodeId, 'case_05_signal_route');
      expect(restored.flags, contains('case4_next_case_signal_trace'));
      expect(restored.collectedEvidence, contains('case5_signal_coordinates'));
      expect(restored.availableChoices.map((choice) => choice.id), contains('case5_submit_coordinates'));
    });

    test('first trilogy endings still continue into case IV', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'ending_sector_restored'
        ..endingId = 'ending_sector_restored';
      expect(campaign.continueAfterEnding(), isTrue);
      expect(campaign.currentNodeId, 'case_04_dispatch');
      expect(campaign.chapterNumber, 4);
    });
  });
}
