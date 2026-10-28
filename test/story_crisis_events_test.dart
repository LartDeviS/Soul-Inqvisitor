import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';

void main() {
  group('Timed story crisis outcomes', () {
    test('saving the station witness opens the witness route', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'station_investigation';
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.resolveCrisisEvent('station_witness', success: true), isTrue);
      expect(campaign.flags, contains('crisis_success_station_witness'));
      expect(campaign.flags, contains('witness_protected'));
      expect(campaign.resolveCrisisEvent('station_witness', success: false), isFalse);
    });

    test('losing a timed objective is persisted as a different outcome', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'cargo_depot';
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.resolveCrisisEvent('cargo_evidence', success: false), isTrue);
      expect(campaign.flags, contains('crisis_failed_cargo_evidence'));
      expect(campaign.flags, isNot(contains('cargo_evidence_preserved')));
    });

    test('successful archive rescue creates its own narrative flag', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'archive_confrontation';
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.resolveCrisisEvent('archive_archivist', success: true), isTrue);
      expect(campaign.flags, contains('archive_archivist_rescued'));
      final node = StoryCampaignSystem.nodeById('archive_confrontation')!;
      expect(node.choices.any((choice) => choice.id == 'testify_with_archivist'), isTrue);
    });

    test('starting a retry clears only timed-crisis result flags', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'cargo_depot';
      campaign.beginCurrentOperation();
      campaign.resolveCrisisEvent('cargo_evidence', success: true);
      campaign.flags.add('unrelated_investigation_flag');
      campaign.resolveActiveOperation(success: false);
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.flags, isNot(contains('crisis_success_cargo_evidence')));
      expect(campaign.flags, contains('unrelated_investigation_flag'));
    });
  });
}
