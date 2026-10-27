enum CombatEventType { criticalHit, enemyKilled, targetBurningKilled, playerDamaged, abilityUsed }
class CombatEvent { final CombatEventType type; final String? targetId; final double value; const CombatEvent(this.type, {this.targetId, this.value = 0}); }
class RelicSynergyEffect { final String id, description; final CombatEventType trigger; final String requiredRelic; final String? requiredStatus; final double magnitude; const RelicSynergyEffect({required this.id, required this.description, required this.trigger, required this.requiredRelic, this.requiredStatus, required this.magnitude = 1}); }
class RelicSynergySystem {
  static const catalog = <RelicSynergyEffect>[
    RelicSynergyEffect(id:'executioner_cycle', description:'Критический удар ускоряет восстановление способности.', trigger:CombatEventType.criticalHit, requiredRelic:'warp_lens', magnitude:0.8),
    RelicSynergyEffect(id:'immolation_spread', description:'Убийство горящей цели вызывает цепную вспышку.', trigger:CombatEventType.targetBurningKilled, requiredRelic:'cursed_round', requiredStatus:'burning', magnitude:1.25),
    RelicSynergyEffect(id:'iron_reprisal', description:'Полученный урон усиливает следующий удар.', trigger:CombatEventType.playerDamaged, requiredRelic:'iron_oath', magnitude:1.15),
  ];
  List<RelicSynergyEffect> resolve(CombatEvent event, Set<String> ownedRelics, {Set<String> targetStatuses = const {}}) => catalog.where((effect) =>
    effect.trigger == event.type && ownedRelics.contains(effect.requiredRelic) &&
    (effect.requiredStatus == null || targetStatuses.contains(effect.requiredStatus))).toList(growable:false);
}
