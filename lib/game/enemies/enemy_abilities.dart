enum EnemyAbilityKind { charge, summon, regeneration, warpBlast, poisonCloud, suppressingFire, phaseShift }
class EnemyAbility {
  final EnemyAbilityKind kind;
  final double cooldown, range, power;
  final String telegraph;
  const EnemyAbility(this.kind, {required this.cooldown, required this.range, required this.power, required this.telegraph});
}
class EnemyAbilityBook {
  static const abilities = <String, List<EnemyAbility>>{
    'genestealer': [EnemyAbility(EnemyAbilityKind.charge, cooldown: 5, range: 260, power: 1.5, telegraph: 'Генокрад готовится к рывку!')],
    'chaosPsyker': [EnemyAbility(EnemyAbilityKind.warpBlast, cooldown: 6, range: 300, power: 1.8, telegraph: 'Псайкер собирает энергию варпа!')],
    'plagueBearer': [EnemyAbility(EnemyAbilityKind.poisonCloud, cooldown: 8, range: 100, power: 0.7, telegraph: 'Чумной демон выпускает облако скверны!')],
    'necronImmortal': [EnemyAbility(EnemyAbilityKind.regeneration, cooldown: 10, range: 0, power: 0.2, telegraph: 'Некрон начинает самовосстановление!')],
    'daemonPrince': [EnemyAbility(EnemyAbilityKind.summon, cooldown: 12, range: 360, power: 3, telegraph: 'Демон-принц разрывает завесу варпа!'), EnemyAbility(EnemyAbilityKind.phaseShift, cooldown: 18, range: 250, power: 1.4, telegraph: 'Демон-принц переходит в новую фазу!')],
  };
  static List<EnemyAbility> forType(String type) => abilities[type] ?? const [];
}
