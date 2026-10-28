import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';

void main() {
  group('Update 10: sector fate endings', () {
    StoryCampaignSystem readyAtArchive() => StoryCampaignSystem()
      ..currentNodeId = 'archive_confrontation';

    test('restoration ending requires all allies, evidence, and high stability', () {
      final campaign = readyAtArchive()
        ..flags.addAll(<String>{
          'witness_protected',
          'cargo_evidence_preserved',
          'archive_archivist_rescued',
        })
        ..collectedEvidence.addAll(<String>{'sealed_order', 'missing_names', 'cargo_manifest'});

      expect(campaign.sectorStabilityScore, 9);
      expect(campaign.availableChoices.any((choice) => choice.id == 'restore_helion'), isTrue);
      expect(campaign.choose('restore_helion'), isTrue);
      expect(campaign.endingId, 'ending_sector_restored');
      expect(campaign.consequenceSummary.join(' '), contains('гражданского управления'));
    });

    test('restoration remains locked when a required ally is missing', () {
      final campaign = readyAtArchive()
        ..flags.addAll(<String>{'witness_protected', 'cargo_evidence_preserved'})
        ..collectedEvidence.addAll(<String>{'sealed_order', 'missing_names', 'cargo_manifest'});
      expect(campaign.availableChoices.any((choice) => choice.id == 'restore_helion'), isFalse);
    });

    test('military occupation requires a successful archive operation and evidence', () {
      final campaign = readyAtArchive()
        ..flags.add('operation_archive_breached')
        ..collectedEvidence.addAll(<String>{'sealed_order', 'missing_names'});
      expect(campaign.availableChoices.any((choice) => choice.id == 'impose_martial_law'), isTrue);
      expect(campaign.choose('impose_martial_law'), isTrue);
      expect(campaign.endingId, 'ending_military_occupation');
      expect(campaign.consequenceSummary.join(' '), contains('военное управление'));
    });

    test('quarantine ending requires archive operation and suppression blueprint', () {
      final campaign = readyAtArchive()
        ..flags.add('operation_archive_breached')
        ..collectedEvidence.addAll(<String>{'sealed_order', 'warp_blueprint'});
      expect(campaign.availableChoices.any((choice) => choice.id == 'seal_helion_quarantine'), isTrue);
      expect(campaign.choose('seal_helion_quarantine'), isTrue);
      expect(campaign.endingId, 'ending_sector_quarantine');
      expect(campaign.flags, contains('sector_quarantined'));
    });

    test('new ending is preserved after save/load', () {
      final campaign = readyAtArchive()
        ..flags.add('operation_archive_breached')
        ..collectedEvidence.addAll(<String>{'sealed_order', 'missing_names'});
      expect(campaign.choose('impose_martial_law'), isTrue);
      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.endingId, 'ending_military_occupation');
      expect(restored.currentNodeId, 'ending_military_occupation');
      expect(restored.consequenceSummary.join(' '), contains('военное управление'));
    });
  });
}
