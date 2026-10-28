import 'package:flutter_test/flutter_test.dart';
import '../lib/game/missions/story_campaign.dart';
import '../lib/game/missions/story_boss_profiles.dart';

void main() {
  group('Update 20: consequences of Case IX', () {
    test('each branch locks its decision until field objective, kills and boss are complete', () {
      final scenarios = <({String node, String operation, String objective, String choice, String ending, String flag})>[
        (node: 'case_10_trial_evidence', operation: 'case10_trial_evidence_operation', objective: 'case10_testimony_archive_seized', choice: 'case10_secure_testimony', ending: 'ending_case10_trial_evidence', flag: 'case10_testimony_preserved'),
        (node: 'case_10_cell_cleanup', operation: 'case10_cell_cleanup_operation', objective: 'case10_fugitive_registry_recovered', choice: 'case10_close_cells', ending: 'ending_case10_cells_cleared', flag: 'case10_cells_cleared'),
        (node: 'case_10_shadow_network', operation: 'case10_shadow_network_operation', objective: 'case10_control_key_extracted', choice: 'case10_claim_shadow_node', ending: 'ending_case10_shadow_node_claimed', flag: 'case10_shadow_node_rekeyed'),
      ];
      for (final scenario in scenarios) {
        final campaign = StoryCampaignSystem()..currentNodeId = scenario.node;
        expect(campaign.currentOperation?.id, scenario.operation);
        expect(campaign.beginCurrentOperation(), isTrue);
        expect(campaign.choose(scenario.choice), isFalse);
        campaign.collectFieldObjective(scenario.objective);
        for (var i = 0; i < campaign.activeOperation!.requiredKills; i++) {
          campaign.recordActiveOperationKill();
        }
        campaign.recordActiveOperationKill(isBoss: true);
        campaign.resolveActiveOperation(success: true);
        expect(campaign.choose(scenario.choice), isTrue);
        expect(campaign.currentNodeId, scenario.ending);
        expect(campaign.flags, contains(scenario.flag));
      }
    });

    test('three new branch bosses have unique identities and three attack phases', () {
      final kinds = <StoryBossKind>[
        StoryBossKind.tribunalJusticiar,
        StoryBossKind.cellPursuer,
        StoryBossKind.shadowNetworkWarden,
      ];
      final titles = kinds.map((kind) => StoryBossProfile.forKind(kind).title).toSet();
      expect(titles, hasLength(3));
      for (final kind in kinds) {
        final profile = StoryBossProfile.forKind(kind);
        expect(profile.phaseOneAttacks, isNotEmpty);
        expect(profile.phaseTwoAttacks, isNotEmpty);
        expect(profile.phaseThreeAttacks, isNotEmpty);
      }
    });
  });
}
