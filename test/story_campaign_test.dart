import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';

void main() {
  group('Branching story campaign', () {
    test('evidence unlocks investigative routes and persists', () {
      final campaign = StoryCampaignSystem();
      expect(campaign.currentNode.id, 'prologue_briefing');
      expect(campaign.choose('covert_entry'), isTrue);
      expect(campaign.currentNode.id, 'station_investigation');
      expect(campaign.choose('trace_cargo'), isFalse);
      expect(campaign.collectEvidence('vox_fragment'), isTrue);
      expect(campaign.collectEvidence('vox_fragment'), isFalse);
      expect(campaign.choose('trace_cargo'), isTrue);
      expect(campaign.currentNode.id, 'cargo_depot');

      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.currentNode.id, 'cargo_depot');
      expect(restored.flags, contains('cargo_route_found'));
      expect(restored.collectedEvidence, contains('vox_fragment'));
      expect(restored.decisions['station_investigation'], 'trace_cargo');
    });

    test('final outcomes require the matching evidence and remain saved', () {
      final campaign = StoryCampaignSystem();
      campaign.choose('seal_sector');
      campaign.collectEvidence('access_log');
      campaign.choose('question_deacon');
      campaign.choose('protect_witness');
      campaign.collectEvidence('cargo_manifest');
      campaign.choose('follow_archive');
      campaign.collectEvidence('sealed_order');
      expect(campaign.choose('expose_curator'), isFalse);
      campaign.collectEvidence('missing_names');
      expect(campaign.choose('expose_curator'), isTrue);
      expect(campaign.completed, isTrue);
      expect(campaign.endingId, 'ending_justice');

      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.completed, isTrue);
      expect(restored.currentNode.title, 'Приговор по печати');
      expect(restored.choose('anything'), isFalse);
    });

    test('protecting a witness unlocks a distinct justice ending', () {
      final campaign = StoryCampaignSystem();
      campaign.choose('seal_sector');
      campaign.collectEvidence('access_log');
      campaign.choose('question_deacon');
      campaign.choose('protect_witness');
      campaign.collectEvidence('cargo_manifest');
      expect(campaign.choose('use_witness_mark'), isTrue);
      campaign.collectEvidence('sealed_order');
      campaign.collectEvidence('missing_names');
      expect(campaign.choose('testify_with_witness'), isTrue);
      expect(campaign.endingId, 'ending_witness_justice');
      expect(campaign.flags, contains('witness_testified'));
    });

    test('invalid save values fall back to a safe opening scene', () {
      final campaign = StoryCampaignSystem()..loadJson({
        'currentNodeId': 'missing-node',
        'visitedNodes': ['missing-node', 'prologue_briefing'],
        'collectedEvidence': ['fake-evidence'],
        'flags': ['known_flag'],
        'endingId': 'not-an-ending',
        'corruptionDelta': 100000,
        'requisitionDelta': -100000,
      });
      expect(campaign.currentNode.id, 'prologue_briefing');
      expect(campaign.visitedNodes, {'prologue_briefing'});
      expect(campaign.collectedEvidence, isEmpty);
      expect(campaign.endingId, isNull);
      expect(campaign.corruptionDelta, 100);
      expect(campaign.requisitionDelta, -500);
    });
  });
}
