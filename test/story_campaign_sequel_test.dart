import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';

void main() {
  group('Update 11: sequel case and inherited ending', () {
    test('continues from the restored-sector ending and unlocks civilian route', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'ending_sector_restored'
        ..endingId = 'ending_sector_restored';

      expect(campaign.continueAfterEnding(), isTrue);
      expect(campaign.completed, isFalse);
      expect(campaign.currentNodeId, 'case_04_dispatch');
      expect(campaign.chapterNumber, 4);
      expect(campaign.availableChoices.map((choice) => choice.id), contains('follow_reconstruction_signal'));
      expect(campaign.availableChoices.map((choice) => choice.id), isNot(contains('follow_quarantine_beacon')));
    });

    test('military occupation and quarantine preserve distinct next-case routes', () {
      final occupation = StoryCampaignSystem()
        ..currentNodeId = 'ending_military_occupation'
        ..endingId = 'ending_military_occupation';
      expect(occupation.continueAfterEnding(), isTrue);
      expect(occupation.availableChoices.map((choice) => choice.id), contains('follow_military_audit'));

      final quarantine = StoryCampaignSystem()
        ..currentNodeId = 'ending_sector_quarantine'
        ..endingId = 'ending_sector_quarantine';
      expect(quarantine.continueAfterEnding(), isTrue);
      expect(quarantine.availableChoices.map((choice) => choice.id), contains('follow_quarantine_beacon'));
    });

    test('branch evidence is required before the expedition can be authorized', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'ending_sector_restored'
        ..endingId = 'ending_sector_restored';
      expect(campaign.continueAfterEnding(), isTrue);
      expect(campaign.choose('follow_reconstruction_signal'), isTrue);
      expect(campaign.availableChoices.any((choice) => choice.id == 'submit_civilian_trace'), isTrue);
      expect(campaign.choose('submit_civilian_trace'), isFalse);
      expect(campaign.collectEvidence('case4_civilian_trace'), isTrue);
      expect(campaign.choose('submit_civilian_trace'), isTrue);
      expect(campaign.currentNodeId, 'case_04_signal_review');
      expect(campaign.availableChoices.map((choice) => choice.id), contains('authorize_outer_relay_expedition'));
      expect(campaign.choose('authorize_outer_relay_expedition'), isTrue);
      expect(campaign.endingId, 'ending_case4_expedition');
      expect(campaign.flags, contains('case4_expedition_authorized'));
    });

    test('prior ending and sequel progress survive serialization', () {
      final original = StoryCampaignSystem()
        ..currentNodeId = 'ending_sector_quarantine'
        ..endingId = 'ending_sector_quarantine';
      expect(original.continueAfterEnding(), isTrue);
      expect(original.choose('follow_quarantine_beacon'), isTrue);
      expect(original.collectEvidence('case4_quarantine_packet'), isTrue);

      final restored = StoryCampaignSystem()..loadJson(original.toJson());
      expect(restored.currentNodeId, 'case_04_quarantine_route');
      expect(restored.flags, contains('prior_ending_ending_sector_quarantine'));
      expect(restored.collectedEvidence, contains('case4_quarantine_packet'));
      expect(restored.availableChoices.map((choice) => choice.id), contains('submit_quarantine_packet'));
    });

    test('cannot continue without a completed ending', () {
      final campaign = StoryCampaignSystem();
      expect(campaign.continueAfterEnding(), isFalse);
      expect(campaign.currentNodeId, 'prologue_briefing');
    });
  });
}
