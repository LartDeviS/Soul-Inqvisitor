enum WeaponRarity { common, improved, relic, unique }
class WeaponRarityProfile {
  final WeaponRarity id; final String nameRu; final double damageMultiplier, cooldownMultiplier, penetrationBonus; final int shardValue;
  const WeaponRarityProfile(this.id,this.nameRu,{this.damageMultiplier=1,this.cooldownMultiplier=1,this.penetrationBonus=0,this.shardValue=1});
  static const Map<WeaponRarity,WeaponRarityProfile> all={
    WeaponRarity.common:WeaponRarityProfile(WeaponRarity.common,'Обычное',shardValue:1),
    WeaponRarity.improved:WeaponRarityProfile(WeaponRarity.improved,'Улучшенное',damageMultiplier:1.08,cooldownMultiplier:.97,penetrationBonus:.03,shardValue:2),
    WeaponRarity.relic:WeaponRarityProfile(WeaponRarity.relic,'Реликтовое',damageMultiplier:1.18,cooldownMultiplier:.93,penetrationBonus:.08,shardValue:4),
    WeaponRarity.unique:WeaponRarityProfile(WeaponRarity.unique,'Уникальное',damageMultiplier:1.30,cooldownMultiplier:.90,penetrationBonus:.12,shardValue:8),
  };
  static WeaponRarityProfile byId(WeaponRarity id)=>all[id]!;
  static WeaponRarity parse(Object? raw)=>WeaponRarity.values.firstWhere((e)=>e.name==raw,orElse:()=>WeaponRarity.common);
}
