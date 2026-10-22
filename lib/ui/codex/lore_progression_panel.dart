import 'package:flutter/material.dart';
import '../../progression/lore_campaign_system.dart';

/// Read-only lore and progression reference panel. Live campaign actions are exposed by InquisitorExpansionSystems.
class LoreProgressionPanel extends StatelessWidget {
  const LoreProgressionPanel({super.key});
  static const gold=Color(0xFFFFD700), dark=Color(0xFF151719);
  @override
  Widget build(BuildContext context) => Card(color:dark,margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ExpansionTile(
    leading:const Icon(Icons.menu_book,color:gold),title:const Text('ДОСЬЕ И РАССЛЕДОВАНИЯ',style:TextStyle(color:gold,fontSize:12,fontWeight:FontWeight.bold)),
    subtitle:Text('${EnemyDossierCatalog.all.length} досье • ${RelicCatalog.all.length} реликвий • ${BranchingContractCatalog.all.length} разветвлённых контрактов',style:const TextStyle(color:Colors.white54,fontSize:10)),
    children:[
      ...EnemyDossierCatalog.all.map((d)=>ExpansionTile(dense:true,leading:const Icon(Icons.person_search,color:Colors.redAccent,size:18),title:Text(d.name,style:const TextStyle(color:Colors.white,fontSize:12)),subtitle:Text('Награда за изучение: ${d.studyReward} опыта',style:const TextStyle(color:Colors.white38,fontSize:10)),children:[Padding(padding:const EdgeInsets.fromLTRB(16,0,16,12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_line('Происхождение',d.origin),_line('Слабости',d.weaknesses),_line('Тактика',d.tactics),_line('Награда',d.reward)]))])),
      const Divider(color:Colors.white12),
      const ListTile(title:Text('РАССЛЕДОВАНИЯ И РЕШЕНИЯ',style:TextStyle(color:gold,fontSize:11,fontWeight:FontWeight.bold)),subtitle:Text('Собирай улики и допрашивай свидетелей. Сохранение доказательств даёт сведения и репутацию; немедленная зачистка приносит больше реквизиции, но повышает тревогу.',style:TextStyle(color:Colors.white70,fontSize:11))),
      ...RelicCatalog.all.map((r)=>ListTile(dense:true,leading:const Icon(Icons.auto_awesome,color:Colors.amber,size:17),title:Text(r.name,style:const TextStyle(color:Colors.white,fontSize:11)),subtitle:Text(r.description,style:const TextStyle(color:Colors.white54,fontSize:10)))),
      const Divider(color:Colors.white12),
      ...BranchingContractCatalog.all.map((c)=>ExpansionTile(dense:true,title:Text(c.title,style:const TextStyle(color:Colors.white,fontSize:11)),subtitle:Text(c.description,style:const TextStyle(color:Colors.white54,fontSize:10)),children:c.routes.map((r)=>ListTile(dense:true,title:Text(r.label,style:const TextStyle(color:gold,fontSize:11)),subtitle:Text('${r.objective}\nУсловие: ${r.condition}\nПоследствие: ${r.consequence}\nНаграда: ${r.requisitionReward} реквизиции',style:const TextStyle(color:Colors.white60,fontSize:10)))).toList())),
    ]));
  Widget _line(String title,String body)=>Padding(padding:const EdgeInsets.only(bottom:4),child:Text('$title: $body',style:const TextStyle(color:Colors.white70,fontSize:10)));
}
