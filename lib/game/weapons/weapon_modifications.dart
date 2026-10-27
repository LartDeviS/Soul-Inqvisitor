class WeaponMod { final String id,name,slot; final Set<String> compatibleTags; final Map<String,double> modifiers; final Map<String,double> drawbacks; const WeaponMod({required this.id,required this.name,required this.slot,this.compatibleTags=const {},this.modifiers=const {},this.drawbacks=const {}}); }
class WeaponModificationSystem {
  static const catalog=<WeaponMod>[
    WeaponMod(id:'rifled_barrel',name:'Нарезной ствол',slot:'barrel',compatibleTags:{'kinetic','bolter'},modifiers:{'damage':.12,'accuracy':.08},drawbacks:{'reload':.06}),
    WeaponMod(id:'vented_coil',name:'Вентилируемый блок',slot:'power',compatibleTags:{'plasma','warp'},modifiers:{'cooldown':.15},drawbacks:{'damage':-.04}),
    WeaponMod(id:'extended_magazine',name:'Увеличенный магазин',slot:'magazine',modifiers:{'magazine':.30},drawbacks:{'reload':.12}),
    WeaponMod(id:'auspex_sight',name:'Прицел ауспекса',slot:'sight',modifiers:{'critChance':.05,'range':.10},drawbacks:{'moveSpeed':-.03}),
    WeaponMod(id:'sanctified_rounds',name:'Освящённые боеприпасы',slot:'ammo',compatibleTags:{'kinetic','bolter'},modifiers:{'daemonDamage':.18},drawbacks:{'ammoCost':.10}),
  ];
  final Map<String,WeaponMod> equipped=<String,WeaponMod>{};
  bool equip(WeaponMod mod,{required Set<String> weaponTags}){if(mod.compatibleTags.isNotEmpty&&!mod.compatibleTags.any(weaponTags.contains))return false;equipped[mod.slot]=mod;return true;}
  Map<String,double> get combinedModifiers{final out=<String,double>{};for(final mod in equipped.values){for(final e in mod.modifiers.entries){out[e.key]=(out[e.key]??0)+e.value;}for(final e in mod.drawbacks.entries){out[e.key]=(out[e.key]??0)+e.value;}}return out;}
  Map<String,dynamic> toJson()=>{'mods':equipped.map((k,v)=>MapEntry(k,v.id))};
  void loadJson(dynamic raw){if(raw is! Map)return;equipped.clear();final values=raw['mods'];if(values is Map){for(final e in values.entries){if(e.key is String&&e.value is String){final mod=catalog.where((m)=>m.id==e.value&&m.slot==e.key).firstOrNull;if(mod!=null)equipped[e.key as String]=mod;}}}}
}
extension _WeaponModFirstOrNull<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}
