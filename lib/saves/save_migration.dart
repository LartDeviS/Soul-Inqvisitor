/// Migrates expansion save payloads forward while preserving unknown fields.
class SaveMigration {
  static Map<String, dynamic> migrate(dynamic raw) {
    if (raw is! Map) return {'schemaVersion': 9};
    final result = Map<String, dynamic>.from(raw);
    final version = result['schemaVersion'] is num
        ? (result['schemaVersion'] as num).toInt()
        : 0;
    if (version < 1) {
      result.putIfAbsent('inventory', () => {'backpack': <dynamic>[], 'vault': <dynamic>[], 'equipped': <String, dynamic>{}});
    }
    if (version < 2) {
      result.putIfAbsent('worldEventHistory', () => <dynamic>[]);
      result.putIfAbsent('progressionTrack', () => {'experience': 0, 'level': 1, 'skillPoints': 0});
    }
    if (version < 3) {
      result.putIfAbsent('ordoDoctrine', () => {'unlockedSkills': <dynamic>[]});
      final weapons = result['weapons'];
      if (weapons is Map && weapons['weapons'] is Map) {
        for (final entry in (weapons['weapons'] as Map).values) {
          if (entry is Map) {
            entry.putIfAbsent('ammoType', () => 'standard');
            entry.putIfAbsent('rarity', () => 'common');
          }
        }
      }
    }
    if (version < 5) {
      result.putIfAbsent('systems', () => {
        'waveDirector': {'wave': 0, 'phase': 'opening'},
        'arenaHazards': <dynamic>[],
        'weaponModifications': {'mods': <String, dynamic>{}},
        'servoSkulls': {'companions': <dynamic>[]},
        'codexChallenges': {'progress': <String, dynamic>{}, 'claimed': <dynamic>[]},
        'fieldInvestigations': {'collected': <dynamic>[], 'interrogated': <dynamic>[]},
      });
    }
    if (version < 6) {
      if (result['systems'] is! Map) result['systems'] = <String, dynamic>{};
      final systems = result['systems'] as Map;
      systems.putIfAbsent('storyCampaign', () => <String, dynamic>{'schemaVersion': 1, 'currentNodeId': 'prologue_briefing'});
    }
    if (version < 7) {
      if (result['systems'] is! Map) result['systems'] = <String, dynamic>{};
      final systems = result['systems'] as Map;
      if (systems['storyCampaign'] is! Map) {
        systems['storyCampaign'] = <String, dynamic>{'schemaVersion': 2, 'currentNodeId': 'prologue_briefing'};
      } else {
        final story = systems['storyCampaign'] as Map;
        story.putIfAbsent('schemaVersion', () => 2);
        story.putIfAbsent('activeOperationId', () => null);
        story.putIfAbsent('operationAttempts', () => <String, dynamic>{});
      }
    }
    if (version < 8) {
      if (result['systems'] is! Map) result['systems'] = <String, dynamic>{};
      final systems = result['systems'] as Map;
      if (systems['storyCampaign'] is Map) {
        final story = systems['storyCampaign'] as Map;
        story['schemaVersion'] = 3;
        story.putIfAbsent('operationKills', () => 0);
        story.putIfAbsent('operationChampions', () => 0);
        story.putIfAbsent('operationBosses', () => 0);
      }
    }
    if (version < 9) {
      if (result['systems'] is! Map) result['systems'] = <String, dynamic>{};
      final systems = result['systems'] as Map;
      if (systems['storyCampaign'] is Map) {
        final story = systems['storyCampaign'] as Map;
        story['schemaVersion'] = 4;
        story.putIfAbsent('operationFieldObjectives', () => <dynamic>[]);
      }
    }
    result['schemaVersion'] = 9;
    return result;
  }
}
