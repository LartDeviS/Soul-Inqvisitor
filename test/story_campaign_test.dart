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

    test('field operation success unlocks a special route and persists', () {
      final campaign = StoryCampaignSystem();
      expect(campaign.choose('covert_entry'), isTrue);
      expect(campaign.currentOperation?.id, 'secure_station');
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.choose('purge_station'), isFalse, reason: 'choices are locked while deployed');
      for (var i = 0; i < 12; i++) { campaign.recordActiveOperationKill(); }
      expect(campaign.activeOperationObjectivesComplete, isFalse, reason: 'the field relay must also be secured');
      expect(campaign.collectFieldObjective('station_relay_disabled'), isTrue);
      expect(campaign.collectFieldObjective('station_relay_disabled'), isFalse, reason: 'field objectives can only be secured once');
      expect(campaign.activeOperationObjectivesComplete, isTrue);
      final resolved = campaign.resolveActiveOperation(success: true);
      expect(resolved?.id, 'secure_station');
      expect(campaign.flags, contains('operation_station_secured'));
      expect(campaign.collectEvidence('access_log'), isTrue);
      expect(campaign.availableChoices.map((choice) => choice.id), contains('secure_station_route'));
      expect(campaign.beginCurrentOperation(), isFalse, reason: 'a completed operation cannot be replayed in the same scene');

      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.flags, contains('operation_station_secured'));
      expect(restored.attemptsFor(restored.currentOperation!), 1);
      expect(restored.operationInProgress, isFalse);
    });

    test('failed operation can be retried without resetting investigation', () {
      final campaign = StoryCampaignSystem();
      campaign.choose('seal_sector');
      expect(campaign.beginCurrentOperation(), isTrue);
      campaign.resolveActiveOperation(success: false);
      expect(campaign.flags, contains('operation_failed_secure_station'));
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.attemptsFor(campaign.currentOperation!), 2);
      for (var i = 0; i < 12; i++) { campaign.recordActiveOperationKill(); }
      campaign.collectFieldObjective('station_relay_disabled');
      campaign.resolveActiveOperation(success: true);
      expect(campaign.isOperationCompleted(campaign.currentOperation!), isTrue);
    });

    test('cargo operation requires an elite kill and persists objective progress', () {
      final campaign = StoryCampaignSystem();
      campaign.choose('seal_sector');
      campaign.collectEvidence('access_log');
      campaign.choose('question_deacon');
      campaign.choose('coerce_witness');
      campaign.collectEvidence('cargo_manifest');
      expect(campaign.currentNode.id, 'cargo_depot');
      expect(campaign.beginCurrentOperation(), isTrue);
      for (var i = 0; i < 10; i++) { campaign.recordActiveOperationKill(); }
      expect(campaign.activeOperationObjectivesComplete, isFalse);
      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.operationKills, 10);
      expect(restored.activeOperationObjectivesComplete, isFalse);
      restored.recordActiveOperationKill(isChampion: true);
      expect(restored.activeOperationObjectivesComplete, isFalse);
      expect(restored.collectFieldObjective('cargo_manifest_secured'), isTrue);
      expect(restored.activeOperationObjectivesComplete, isTrue);
      restored.resolveActiveOperation(success: true);
      expect(restored.flags, contains('operation_cargo_intercepted'));
    });

    test('archive operation requires both archive cores and the boss objective', () {
      final campaign = StoryCampaignSystem();
      campaign.choose('seal_sector');
      campaign.collectEvidence('access_log');
      campaign.choose('question_deacon');
      campaign.choose('coerce_witness');
      campaign.collectEvidence('cargo_manifest');
      campaign.choose('follow_archive');
      expect(campaign.currentNode.id, 'archive_confrontation');
      expect(campaign.beginCurrentOperation(), isTrue);
      for (var i = 0; i < 8; i++) { campaign.recordActiveOperationKill(); }
      campaign.recordActiveOperationKill(isBoss: true);
      expect(campaign.collectFieldObjective('archive_core_alpha'), isTrue);
      expect(campaign.activeOperationObjectivesComplete, isFalse);
      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.operationFieldObjectives, contains('archive_core_alpha'));
      expect(restored.collectFieldObjective('archive_core_omega'), isTrue);
      expect(restored.activeOperationObjectivesComplete, isTrue);
    });

    test('victory without required objectives does not unlock the operation route', () {
      final campaign = StoryCampaignSystem();
      campaign.choose('seal_sector');
      expect(campaign.beginCurrentOperation(), isTrue);
      campaign.recordActiveOperationKill();
      campaign.resolveActiveOperation(success: true);
      expect(campaign.flags, isNot(contains('operation_station_secured')));
      expect(campaign.flags, contains('operation_failed_secure_station'));
    });

    test('story field objectives are operation-specific and persist safely', () {
      final campaign = StoryCampaignSystem();
      campaign.choose('seal_sector');
      expect(campaign.beginCurrentOperation(), isTrue);
      expect(campaign.collectFieldObjective('cargo_manifest_secured'), isFalse,
          reason: 'cargo evidence must not satisfy a station operation');
      expect(campaign.collectFieldObjective('station_relay_disabled'), isTrue);
      final restored = StoryCampaignSystem()..loadJson(campaign.toJson());
      expect(restored.operationFieldObjectives, contains('station_relay_disabled'));
      expect(restored.activeOperationProgressLabel, contains('Объекты: 1/1'));
      for (var i = 0; i < 12; i++) { restored.recordActiveOperationKill(); }
      expect(restored.activeOperationObjectivesComplete, isTrue);
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
