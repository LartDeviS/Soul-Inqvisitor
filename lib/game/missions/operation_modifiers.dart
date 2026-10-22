import 'dart:math';

enum OperationModifier { powerOutage, warpSurge, ambush, emergencySupply }
class OperationModifierData {
  final OperationModifier id;
  final String title, description;
  final double enemyDamageMultiplier, enemyHpMultiplier, playerVisibilityMultiplier, lootMultiplier;
  final int requisitionBonus;
  const OperationModifierData(this.id, this.title, this.description, {
    this.enemyDamageMultiplier = 1, this.enemyHpMultiplier = 1,
    this.playerVisibilityMultiplier = 1, this.lootMultiplier = 1,
    this.requisitionBonus = 0,
  });
}
class OperationModifierSystem {
  static const catalog = <OperationModifierData>[
    OperationModifierData(OperationModifier.powerOutage, 'Отключение света', 'Видимость снижена; полагайтесь на силуэты и телеграфы.', playerVisibilityMultiplier: .55, enemyDamageMultiplier: 1.05),
    OperationModifierData(OperationModifier.warpSurge, 'Варп-всплеск', 'Враги опаснее, но аномалии могут усилить добычу.', enemyDamageMultiplier: 1.15, enemyHpMultiplier: 1.08, lootMultiplier: 1.25),
    OperationModifierData(OperationModifier.ambush, 'Засада', 'Начало операции сопровождается фланговой атакой.', enemyDamageMultiplier: 1.08, enemyHpMultiplier: 1.03),
    OperationModifierData(OperationModifier.emergencySupply, 'Аварийные поставки', 'Контейнер снабжения даёт дополнительные ресурсы.', lootMultiplier: 1.2, requisitionBonus: 12),
  ];
  final Random _random;
  OperationModifierSystem({int? seed}) : _random = Random(seed);
  OperationModifierData roll({int? seed}) {
    final random = seed == null ? _random : Random(seed);
    return catalog[random.nextInt(catalog.length)];
  }
  static OperationModifierData byId(OperationModifier id) => catalog.firstWhere((e) => e.id == id);
}
