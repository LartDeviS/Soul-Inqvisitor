import 'weapon_data.dart';
import 'ammo_types.dart';
import 'weapon_rarity.dart';

class WeaponRuntime {
  final WeaponData data;
  int ammo;
  double heat=0,cooldownRemaining=0;
  AmmoType ammoType=AmmoType.standard;
  WeaponRarity rarity=WeaponRarity.common;
  WeaponRuntime(this.data):ammo=data.magazine;
  bool get overheated=>heat>=100;
  bool get canFire=>cooldownRemaining<=0&&!overheated&&(data.magazine==0||ammo>0);
  double get effectiveDamage=>data.damage*WeaponRarityProfile.byId(rarity).damageMultiplier*AmmoProfile.byId(ammoType).damageMultiplier;
  double get effectiveCooldown=>data.cooldown*WeaponRarityProfile.byId(rarity).cooldownMultiplier;
  double get effectiveArmorPenetration=>(data.armorPenetration+WeaponRarityProfile.byId(rarity).penetrationBonus+AmmoProfile.byId(ammoType).armorPenetrationBonus).clamp(0.0,.95).toDouble();
  bool setAmmoType(AmmoType value){if(!AmmoProfile.byId(value).compatibleWith(data.damageType))return false;ammoType=value;return true;}
  bool fire(){if(!canFire)return false;cooldownRemaining=effectiveCooldown;if(data.magazine>0)ammo--;if(data.damageType==DamageType.plasma||data.damageType==DamageType.warp)heat=(heat+(data.damageType==DamageType.plasma?24:8)).clamp(0,120).toDouble();return true;}
  void update(double dt){cooldownRemaining=(cooldownRemaining-dt).clamp(0,999).toDouble();heat=(heat-(data.damageType==DamageType.plasma?10:18)*dt).clamp(0,100).toDouble();}
  void reload()=>ammo=data.magazine;
  Map<String,dynamic> toJson()=>{'id':data.id.name,'ammo':ammo,'heat':heat,'ammoType':ammoType.name,'rarity':rarity.name};
}
class WeaponSystem {
  WeaponId equipped=WeaponId.bolter;
  final Map<WeaponId,WeaponRuntime> weapons={for(final id in WeaponId.values) id:WeaponRuntime(WeaponData.all[id]!)};
  WeaponRuntime get current=>weapons[equipped]!;
  bool equip(WeaponId id){if(!weapons.containsKey(id))return false;equipped=id;return true;}
  bool selectAmmo(AmmoType type)=>current.setAmmoType(type);
  bool setRarity(WeaponId id,WeaponRarity rarity){final weapon=weapons[id];if(weapon==null)return false;weapon.rarity=rarity;return true;}
  bool fire()=>current.fire();
  void update(double dt){for(final w in weapons.values)w.update(dt);}
  Map<String,dynamic> toJson()=>{'equipped':equipped.name,'weapons':weapons.map((k,v)=>MapEntry(k.name,v.toJson()))};
  void loadJson(dynamic raw){if(raw is! Map)return;equipped=WeaponId.values.firstWhere((e)=>e.name==raw['equipped'],orElse:()=>WeaponId.bolter);final list=raw['weapons'];if(list is Map){for(final id in WeaponId.values){final v=list[id.name];if(v is Map){final w=weapons[id]!;w.ammo=(v['ammo'] as num?)?.toInt()??w.data.magazine;w.heat=(v['heat'] as num?)?.toDouble()??0;w.ammoType=AmmoProfile.parse(v['ammoType']);w.rarity=WeaponRarityProfile.parse(v['rarity']);if(!AmmoProfile.byId(w.ammoType).compatibleWith(w.data.damageType))w.ammoType=AmmoType.standard;}}}}
}
