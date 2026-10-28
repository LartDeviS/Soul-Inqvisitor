import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';

void main() {
  group('Campaign sector status and ally network', () {
    test('legacy or fresh campaign gets a stable default baseline', () {
      final campaign = StoryCampaignSystem();
      expect(campaign.sectorStabilityScore, 3);
      expect(campaign.sectorStabilityLabel, 'Нестабильность сохраняется');
      expect(campaign.allyNetworkSummary, hasLength(1));
    });

    test('protected witness and preserved evidence improve sector stability', () {
      final campaign = StoryCampaignSystem()
        ..flags.addAll(<String>{'witness_protected', 'cargo_evidence_preserved'});
      expect(campaign.sectorStabilityScore, 7);
      expect(campaign.allyNetworkSummary.join(' '), contains('Диакон Вейл'));
      expect(campaign.allyNetworkSummary.join(' '), contains('накладная сохранена'));
    });

    test('three sources of archive intelligence provide rank three support', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'archive_confrontation'
        ..activeOperationId = 'breach_archive'
        ..flags.addAll(<String>{
          'witness_protected',
          'cargo_evidence_preserved',
          'archive_archivist_rescued',
        });
      expect(campaign.activeOperationSupportRank, 3);
      expect(campaign.activeOperationSupportRequisitionBonus, 24);
      expect(campaign.activeOperationSupportSummary.join(' '), contains('Кастор'));
    });

    test('purging the station reduces stability and score stays bounded', () {
      final campaign = StoryCampaignSystem()
        ..flags.addAll(<String>{'station_purged', 'archive_purged'});
      expect(campaign.sectorStabilityScore, 0);
      expect(campaign.sectorStabilityLabel, 'Сектор на грани распада');
    });

    test('derived status survives save/load without extra schema fields', () {
      final original = StoryCampaignSystem()
        ..flags.addAll(<String>{'witness_protected', 'archive_archivist_rescued'});
      final restored = StoryCampaignSystem()..loadJson(original.toJson());
      expect(restored.sectorStabilityScore, original.sectorStabilityScore);
      expect(restored.sectorStabilityLabel, original.sectorStabilityLabel);
    });
  });
}
