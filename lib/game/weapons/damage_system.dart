import 'weapon_data.dart';
import 'ammo_types.dart';
import 'ordo_specialization.dart';
import 'weapon_rarity.dart';
class DamageContext { final String targetFaction; final double armor; final bool boss, weakSpot; const DamageContext({this.targetFaction='human',this.armor=0,this.boss=false,this.weakSpot=false}); }
class DamageResult { final int amount; final double multiplier, effectiveArmor; final String reason; const DamageResult(this.amount,this.multiplier,this.effectiveArmor,this.reason); }
class DamageSystem {
  static DamageResult calculate({required int baseDamage,required DamageType type,required DamageContext target,double armorPenetration=0,WeaponOrdo weaponOrdo=WeaponOrdo.common,AmmoType ammoType=AmmoType.standard,WeaponRarity rarity=WeaponRarity.common,OrdoDoctrine doctrine=const OrdoDoctrine()}) {
    final ammo=AmmoProfile.byId(ammoType); final rank=WeaponRarityProfile.byId(rarity);
    final armor=(target.armor-armorPenetration-ammo.armorPenetrationBonus-rank.penetrationBonus).clamp(0.0,.85).toDouble(); double mult=rank.damageMultiplier*ammo.damageMultiplier; final notes=<String>[];
    switch(target.targetFaction){
      case 'necron': if(type==DamageType.plasma||type==DamageType.melta){mult*=1.28;notes.add('уязвимость к теплу');} else if(type==DamageType.kinetic) mult*=.88; break;
      case 'tyranid': if(type==DamageType.flame||type==DamageType.explosive) mult*=1.18; break;
      case 'daemon': if(type==DamageType.warp) mult*=1.25; else if(type==DamageType.kinetic) mult*=.82; break;
      case 'ork': if(type==DamageType.flame||type==DamageType.plasma||type==DamageType.melta) mult*=1.12; break;
      case 'chaos': if(type==DamageType.warp) mult*=1.12; break;
      case 'cult': if(ammo.id==AmmoType.sanctified) {mult*=1.08;notes.add('освящённый заряд');} break;
    }
    if(ammo.antiWarp&&(target.targetFaction=='daemon'||target.targetFaction=='chaos')) {mult*=1.15;notes.add('антиварп-боеприпас');}
    if(ammo.appliesBurn&&(target.targetFaction=='cult'||target.targetFaction=='tyranid')) {mult*=1.08;notes.add('зажигательный эффект');}
    final doctrineMultiplier=doctrine.damageMultiplier(weaponOrdo:weaponOrdo,targetFaction:target.targetFaction,damageType:type); mult*=doctrineMultiplier;
    if(doctrineMultiplier>1)notes.add('доктрина Ордо');
    if(target.boss && (type==DamageType.plasma||type==DamageType.melta)) mult*=1.12;
    if(target.weakSpot) {mult*=1.22;notes.add('уязвимая зона');}
    final amount=(baseDamage*mult*(1-armor)).round().clamp(1,999999);
    return DamageResult(amount,mult,armor,notes.isEmpty?'обычное попадание':notes.join(', '));
  }
}
