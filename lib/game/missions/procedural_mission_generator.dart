import 'dart:math';
enum MissionNodeType { combat, elite, hazard, cache, rest, boss, investigation }
class MissionNode { final String id; final MissionNodeType type; final int depth; final List<String> next; const MissionNode({required this.id, required this.type, required this.depth, this.next = const []}); Map<String,dynamic> toJson()=>{'id':id,'type':type.name,'depth':depth,'next':next}; }
class ProceduralMission { final int seed; final List<MissionNode> nodes; const ProceduralMission(this.seed,this.nodes); static ProceduralMission? fromJson(dynamic raw){if(raw is! Map||raw['seed'] is! num||raw['nodes'] is! List)return null;final nodes=<MissionNode>[];for(final item in raw['nodes'] as List){if(item is! Map||item['id'] is! String||item['type'] is! String)continue;final type=MissionNodeType.values.where((e)=>e.name==item['type']).firstOrNull;if(type==null)continue;nodes.add(MissionNode(id:item['id'] as String,type:type,depth:item['depth'] is num?(item['depth'] as num).toInt():nodes.length,next:(item['next'] is List?item['next'] as List:const []).whereType<String>().toList()));}return nodes.isEmpty?null:ProceduralMission((raw['seed'] as num).toInt(),nodes);} bool get hasBoss=>nodes.any((n)=>n.type==MissionNodeType.boss); bool get isReachable=>nodes.isNotEmpty && nodes.first.depth==0 && nodes.last.type==MissionNodeType.boss && _allReachable(); bool _allReachable(){final byId={for(final n in nodes)n.id:n};final seen=<String>{};void visit(String id){if(!seen.add(id))return;for(final next in byId[id]?.next??const <String>[])visit(next);}visit(nodes.first.id);return seen.length==nodes.length;} Map<String,dynamic> toJson()=>{'seed':seed,'nodes':nodes.map((n)=>n.toJson()).toList()}; }
class ProceduralMissionGenerator {
  ProceduralMission generate({required int seed, int floor=1, int minRooms=6, int maxRooms=10}) {
    final random=Random(seed); final count=minRooms+random.nextInt(max(1,maxRooms-minRooms+1)); final types=<MissionNodeType>[];
    for(var i=0;i<count;i++){if(i==count-1){types.add(MissionNodeType.boss);continue;} if(i==0){types.add(MissionNodeType.combat);continue;} final roll=random.nextDouble();types.add(roll<.12?MissionNodeType.rest:roll<.24?MissionNodeType.cache:roll<.36?MissionNodeType.investigation:roll<.49?MissionNodeType.hazard:roll<.62?MissionNodeType.elite:MissionNodeType.combat);}
    final nodes=<MissionNode>[];for(var i=0;i<count;i++){final next=<String>[];if(i+1<count)next.add('node_${i+1}');if(i+2<count && random.nextDouble()<.24)next.add('node_${i+2}');nodes.add(MissionNode(id:'node_$i',type:types[i],depth:i,next:next));}
    // Ensure all nodes remain reachable and boss is the terminal node.
    for(var i=0;i<count-1;i++){if(nodes[i].next.isEmpty)nodes[i]=MissionNode(id:nodes[i].id,type:nodes[i].type,depth:i,next:['node_${i+1}']);}
    return ProceduralMission(seed,nodes);
  }
}

extension _MissionNodeFirstOrNull<T> on Iterable<T>{T? get firstOrNull=>isEmpty?null:first;}
