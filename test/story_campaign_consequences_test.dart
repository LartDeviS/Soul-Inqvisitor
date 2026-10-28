import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';

void main() {
  group('Persistent story consequences', () {
    test('the campaign journal explains saved and lost people or evidence', () {
      final campaign = StoryCampaignSystem();
      campaign.flags.addAll(<String>{
        'witness_protected',
        'cargo_evidence_preserved',
        'crisis_failed_archive_archivist',
      });

      final summary = campaign.consequenceSummary.join(' ');
      expect(summary, contains('Диакон Вейл жив и защищён'));
      expect(summary, contains('Накладная сохранена'));
      expect(summary, contains('Архивариус не был эвакуирован'));
    });

    test('complete dossier ending stays locked until all three lines and evidence exist', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'archive_confrontation';
      final choiceId = 'submit_complete_dossier';

      expect(campaign.availableChoices.any((choice) => choice.id == choiceId), isFalse);

      campaign.flags.addAll(<String>{
        'witness_protected',
        'cargo_evidence_preserved',
        'archive_archivist_rescued',
      });
      campaign.collectedEvidence.addAll(<String>{'sealed_order', 'missing_names'});
      expect(campaign.availableChoices.any((choice) => choice.id == choiceId), isFalse);

      campaign.collectedEvidence.add('cargo_manifest');
      expect(campaign.availableChoices.any((choice) => choice.id == choiceId), isTrue);
      expect(campaign.choose(choiceId), isTrue);
      expect(campaign.currentNodeId, 'ending_complete_dossier');
      expect(campaign.completed, isTrue);
      expect(campaign.flags, contains('complete_dossier_submitted'));
    });

    test('consequence summary and special ending survive save round-trip', () {
      final campaign = StoryCampaignSystem()..currentNodeId = 'archive_confrontation';
      campaign.flags.addAll(<String>{
        'witness_protected',
        'cargo_evidence_preserved',
        'archive_archivist_rescued',
      });
      campaign.collectedEvidence.addAll(<String>{'sealed_order', 'missing_names', 'cargo_manifest'});
      expect(campaign.choose('submit_complete_dossier'), isTrue);

      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.currentNodeId, 'ending_complete_dossier');
      expect(restored.endingId, 'ending_complete_dossier');
      expect(restored.flags, contains('complete_dossier_submitted'));
      expect(restored.consequenceSummary.join(' '), contains('Полное досье принято Ордо'));
    });
  });
}
