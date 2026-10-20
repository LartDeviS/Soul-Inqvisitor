class GearItem {
  final String id, name, slot;
  final int rarity, power;
  final Map<String, double> modifiers;
  /// Pieces sharing a setId contribute to the set bonus when equipped.
  final String? setId;
  /// Unique passive identifier; kept as data so saves remain forward-compatible.
  final String? uniquePower;
  const GearItem({required this.id, required this.name, required this.slot, this.rarity=0, this.power=0, this.modifiers=const {}, this.setId, this.uniquePower});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'slot':slot,'rarity':rarity,'power':power,'modifiers':modifiers,'setId':setId,'uniquePower':uniquePower};
  static GearItem? fromJson(dynamic raw) {
    if (raw is! Map || raw['id'] is! String || raw['name'] is! String || raw['slot'] is! String) return null;
    final mods=<String,double>{};
    if (raw['modifiers'] is Map) (raw['modifiers'] as Map).forEach((k,v){if(k is String&&v is num) mods[k]=v.toDouble();});
    return GearItem(id:raw['id'], name:raw['name'], slot:raw['slot'], rarity:(raw['rarity'] as num?)?.toInt()??0, power:(raw['power'] as num?)?.toInt()??0, modifiers:mods, setId:raw['setId'] is String ? raw['setId'] as String : null, uniquePower:raw['uniquePower'] is String ? raw['uniquePower'] as String : null);
  }
}

class GearSetDefinition {
  final String id, name, description;
  final int piecesForTwo, piecesForFull;
  final Map<String,double> twoPieceModifiers, fullSetModifiers;
  const GearSetDefinition({required this.id,required this.name,required this.description,this.piecesForTwo=2,this.piecesForFull=4,this.twoPieceModifiers=const {},this.fullSetModifiers=const {}});
}

const gearSetCatalog = <GearSetDefinition>[
  GearSetDefinition(id:'inquisitorial',name:'Комплект Инквизитора',description:'Адаптивный панцирь, печать допуска и реликтовые элементы.',twoPieceModifiers:{'defense':0.025},fullSetModifiers:{'damage':0.08,'health':2}),
  GearSetDefinition(id:'deathwatch',name:'Комплект Deathwatch',description:'Охотник на ксеносов: усиленная защита и точный огонь.',twoPieceModifiers:{'rangedDamage':0.06},fullSetModifiers:{'rangedDamage':0.12,'defense':0.04}),
  GearSetDefinition(id:'ordo_malleus',name:'Комплект Ордо Маллеус',description:'Защита от варп-угроз и усиление экзорцистских атак.',twoPieceModifiers:{'health':1,'defense':0.02},fullSetModifiers:{'damage':0.10,'health':2}),
];
class InventoryState { final List<GearItem> backpack=[],vault=[]; final Map<String,GearItem> equipped={}; int medkits=2,grenades=2,shards=0,capacity=24; bool add(GearItem item){if(backpack.length>=capacity)return false;backpack.add(item);return true;} bool equip(GearItem item){if(!backpack.any((e)=>e.id==item.id))return false;final old=equipped[item.slot];if(old!=null&&backpack.length<capacity)backpack.add(old);else if(old!=null)return false;backpack.removeWhere((e)=>e.id==item.id);equipped[item.slot]=item;return true;} void dismantle(GearItem item){if(backpack.remove(item))shards+=1+item.rarity;} void toVault(GearItem item){if(backpack.remove(item))vault.add(item);} void toBackpack(GearItem item){if(vault.remove(item)&&backpack.length<capacity)backpack.add(item);} Map<String,dynamic> toJson()=>{'backpack':backpack.map((e)=>e.toJson()).toList(),'vault':vault.map((e)=>e.toJson()).toList(),'equipped':equipped.map((k,v)=>MapEntry(k,v.toJson())),'medkits':medkits,'grenades':grenades,'shards':shards,'capacity':capacity}; void loadJson(dynamic raw){if(raw is! Map)return;List<GearItem> parse(dynamic v)=>(v is List?v:const[]).map(GearItem.fromJson).whereType<GearItem>().toList();backpack..clear()..addAll(parse(raw['backpack']));vault..clear()..addAll(parse(raw['vault']));equipped.clear();if(raw['equipped'] is Map)(raw['equipped'] as Map).forEach((k,v){final i=GearItem.fromJson(v);if(k is String&&i!=null)equipped[k]=i;});medkits=(raw['medkits'] as num?)?.toInt()??2;grenades=(raw['grenades'] as num?)?.toInt()??2;shards=(raw['shards'] as num?)?.toInt()??0;capacity=(raw['capacity'] as num?)?.toInt()??24;} }
class EquipmentInventory {
  final InventoryState state=InventoryState();
  Map<String,double> get totalModifiers {
    final out=<String,double>{};
    for(final item in state.equipped.values){item.modifiers.forEach((k,v)=>out[k]=(out[k]??0)+v);}
    return out;
  }
  Map<String,double> get activeSetModifiers {
    final counts=<String,int>{};
    for(final item in state.equipped.values){final id=item.setId;if(id!=null)counts[id]=(counts[id]??0)+1;}
    final out=<String,double>{};
    for(final set in gearSetCatalog){final count=counts[set.id]??0;final bonuses=count>=set.piecesForTwo?set.twoPieceModifiers:const <String,double>{};bonuses.forEach((k,v)=>out[k]=(out[k]??0)+v);if(count>=set.piecesForFull)set.fullSetModifiers.forEach((k,v)=>out[k]=(out[k]??0)+v);}
    return out;
  }
  Map<String,int> get equippedSetCounts {
    final counts=<String,int>{};
    for(final item in state.equipped.values){final id=item.setId;if(id!=null)counts[id]=(counts[id]??0)+1;}
    return counts;
  }
  GearSetDefinition? setDefinition(String? id) {for(final set in gearSetCatalog){if(set.id==id)return set;}return null;}
  bool containsUniquePower(String id)=>state.equipped.values.any((item)=>item.uniquePower==id);

  bool equipById(String id) {
    GearItem? item;
    for (final candidate in state.backpack) { if (candidate.id == id) { item = candidate; break; } }
    return item != null && state.equip(item);
  }
  bool upgrade(String id) {
    final list = <GearItem>[...state.backpack, ...state.vault, ...state.equipped.values];
    final index = list.indexWhere((e)=>e.id==id);
    if(index<0) return false;
    final old=list[index];
    final cost=2+old.rarity*2+old.power~/5;
    if(state.shards<cost || old.rarity>=4) return false;
    state.shards-=cost;
    final upgraded=GearItem(id:old.id,name:old.name,slot:old.slot,rarity:(old.rarity+1).clamp(0,4),power:old.power+5,modifiers:old.modifiers.map((k,v)=>MapEntry(k,v*1.15+0.01)),setId:old.setId,uniquePower:old.uniquePower);
    final bi=state.backpack.indexWhere((e)=>e.id==id);
    final vi=state.vault.indexWhere((e)=>e.id==id);
    if(bi>=0) state.backpack[bi]=upgraded;
    else if(vi>=0) state.vault[vi]=upgraded;
    else state.equipped[old.slot]=upgraded;
    return true;
  }
  bool dismantle(String id) {
    GearItem? item;
    for (final candidate in state.backpack) { if (candidate.id == id) { item = candidate; break; } }
    if(item==null) return false;
    state.dismantle(item); return true;
  }
}

