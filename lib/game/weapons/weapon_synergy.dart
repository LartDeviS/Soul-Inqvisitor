import 'weapon_data.dart';

enum CombatStatus { burning, armorBroken, warpMarked, staggered }
class SynergyResult {
  final double damageMultiplier;
  final Set<CombatStatus> appliedStatuses;
  final String description;
  const SynergyResult(this.damageMultiplier, this.appliedStatuses, this.description);
}
/// Resolves status/weapon interactions in one testable place. The caller should
/// merge appliedStatuses into the target's status set after a confirmed hit.
class WeaponSynergySystem {
  static SynergyResult resolve({required DamageType weaponType,
    required Set<CombatStatus> targetStatuses, required String targetFaction,
    bool armorPiercing = false}) {
    var multiplier = 1.0;
    final applied = <CombatStatus>{};
    final notes = <String>[];
    if (weaponType == DamageType.flame) {
      applied.add(CombatStatus.burning);
      if (targetStatuses.contains(CombatStatus.burning)) { multiplier *= 1.12; notes.add('поддержание горения'); }
    }
    if (armorPiercing) {
      applied.add(CombatStatus.armorBroken);
      if (targetStatuses.contains(CombatStatus.armorBroken)) { multiplier *= 1.18; notes.add('пробитая броня'); }
    }
    if (weaponType == DamageType.warp) {
      applied.add(CombatStatus.warpMarked);
      if (targetFaction == 'daemon' || targetFaction == 'chaos') { multiplier *= 1.15; notes.add('варп-синергия'); }
    }
    if (weaponType == DamageType.explosive) {
      applied.add(CombatStatus.staggered);
      if (targetStatuses.contains(CombatStatus.armorBroken)) { multiplier *= 1.10; notes.add('удар по повреждённой броне'); }
    }
    return SynergyResult(multiplier, applied, notes.isEmpty ? 'базовый эффект' : notes.join(', '));
  }
}
