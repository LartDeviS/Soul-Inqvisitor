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
    int safeInt(dynamic value, int fallback) => value is num ? value.toInt() : fallback;
    return GearItem(id:raw['id'] as String, name:raw['name'] as String, slot:raw['slot'] as String, rarity:safeInt(raw['rarity'], 0).clamp(0, 4).toInt(), power:safeInt(raw['power'], 0).clamp(0, 100000).toInt(), modifiers:mods, setId:raw['setId'] is String ? raw['setId'] as String : null, uniquePower:raw['uniquePower'] is String ? raw['uniquePower'] as String : null);
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
class InventoryState {
  final List<GearItem> backpack = <GearItem>[];
  final List<GearItem> vault = <GearItem>[];
  final Map<String, GearItem> equipped = <String, GearItem>{};
  int medkits = 2, grenades = 2, shards = 0, capacity = 24;

  bool add(GearItem item) {
    if (backpack.length >= capacity || _containsId(item.id)) return false;
    backpack.add(item);
    return true;
  }

  bool _containsId(String id) => backpack.any((e) => e.id == id) ||
      vault.any((e) => e.id == id) || equipped.values.any((e) => e.id == id);

  /// Swaps equipment atomically. A full backpack is not a blocker because the
  /// incoming item leaves the backpack before the old equipped item is stored.
  bool equip(GearItem item) {
    final index = backpack.indexWhere((e) => identical(e, item) || e.id == item.id);
    if (index < 0 || item.slot.trim().isEmpty) return false;
    final incoming = backpack[index];
    final old = equipped[incoming.slot];
    if (old?.id == incoming.id) return false;
    // Validate the complete operation before mutating either collection.
    if (old != null && backpack.length > capacity) return false;
    backpack.removeAt(index);
    if (old != null) backpack.add(old);
    equipped[incoming.slot] = incoming;
    return true;
  }

  void dismantle(GearItem item) {
    if (backpack.remove(item)) shards += 1 + item.rarity;
  }

  void toVault(GearItem item) {
    if (backpack.remove(item)) vault.add(item);
  }

  /// Returns false without changing either list when the backpack is full.
  bool toBackpack(GearItem item) {
    final index = vault.indexWhere((e) => identical(e, item) || e.id == item.id);
    if (index < 0 || backpack.length >= capacity || backpack.any((e) => e.id == item.id)) {
      return false;
    }
    final stored = vault[index];
    vault.removeAt(index);
    backpack.add(stored);
    return true;
  }

  Map<String, dynamic> toJson() => {
    'backpack': backpack.map((e) => e.toJson()).toList(),
    'vault': vault.map((e) => e.toJson()).toList(),
    'equipped': equipped.map((k, v) => MapEntry(k, v.toJson())),
    'medkits': medkits, 'grenades': grenades, 'shards': shards, 'capacity': capacity,
  };

  /// Loads untrusted/legacy save data, then normalizes it so one item ID can
  /// exist in only one location and backpack capacity is always respected.
  void loadJson(dynamic raw) {
    if (raw is! Map) return;
    List<GearItem> parse(dynamic value) => (value is List ? value : const <dynamic>[])
        .map(GearItem.fromJson).whereType<GearItem>().toList();
    final parsedBackpack = parse(raw['backpack']);
    final parsedVault = parse(raw['vault']);
    final parsedEquipped = <String, GearItem>{};
    if (raw['equipped'] is Map) {
      (raw['equipped'] as Map).forEach((key, value) {
        final item = GearItem.fromJson(value);
        if (key is String && item != null && key == item.slot) parsedEquipped[key] = item;
      });
    }
    int safeInt(dynamic value, int fallback, {int minValue = 0, int maxValue = 100000}) =>
        (value is num ? value.toInt() : fallback).clamp(minValue, maxValue).toInt();
    capacity = safeInt(raw['capacity'], 24, minValue: 1, maxValue: 200);
    medkits = safeInt(raw['medkits'], 2, maxValue: 999);
    grenades = safeInt(raw['grenades'], 2, maxValue: 999);
    shards = safeInt(raw['shards'], 0, maxValue: 1000000);

    final seen = <String>{};
    equipped
      ..clear()
      ..addEntries(parsedEquipped.entries.where((entry) => seen.add(entry.value.id)));
    backpack.clear();
    final overflow = <GearItem>[];
    for (final item in parsedBackpack) {
      if (!seen.add(item.id)) continue;
      if (backpack.length < capacity) {
        backpack.add(item);
      } else {
        overflow.add(item);
      }
    }
    vault
      ..clear()
      ..addAll(overflow)
      ..addAll(parsedVault.where((item) => seen.add(item.id)));
  }
}

class EquipmentInventory {
  final InventoryState state;
  EquipmentInventory({InventoryState? state}) : state = state ?? InventoryState();
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
    final upgraded=GearItem(id:old.id,name:old.name,slot:old.slot,rarity:(old.rarity+1).clamp(0,4).toInt(),power:old.power+5,modifiers:old.modifiers.map((k,v)=>MapEntry(k,v*1.15+0.01)),setId:old.setId,uniquePower:old.uniquePower);
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

