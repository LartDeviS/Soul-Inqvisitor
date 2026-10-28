import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';

void main() {
  group('Strategic support from campaign consequences', () {
    test('protected witness provides intel for the cargo operation', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'cargo_depot'
        ..activeOperationId = 'intercept_cargo'
        ..flags.add('witness_protected');

      expect(campaign.activeOperationSupportRank, 1);
      expect(campaign.activeOperationSupportRequisitionBonus, 8);
      expect(campaign.activeOperationSupportSummary.join(' '), contains('маршрут конвоя'));
    });

    test('preserved manifest and protected witness support archive assault', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'archive_confrontation'
        ..activeOperationId = 'breach_archive'
        ..flags.addAll(<String>{'witness_protected', 'cargo_evidence_preserved'});

      expect(campaign.activeOperationSupportRank, 2);
      expect(campaign.activeOperationSupportRequisitionBonus, 16);
      expect(campaign.activeOperationSupportSummary.join(' '), contains('обходной маршрут'));
      expect(campaign.activeOperationSupportSummary.join(' '), contains('раскрыла снабжение'));
    });

    test('no prior successes do not grant support or bonus', () {
      final campaign = StoryCampaignSystem()
        ..currentNodeId = 'archive_confrontation'
        ..activeOperationId = 'breach_archive';

      expect(campaign.activeOperationSupportRank, 0);
      expect(campaign.activeOperationSupportRequisitionBonus, 0);
      expect(campaign.activeOperationSupportSummary.single, contains('Поддержка'));
    });
  });
}
