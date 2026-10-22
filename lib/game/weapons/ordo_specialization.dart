import 'weapon_data.dart';

enum OrdoSkill { wardingSeal, daemonology, banishment, witchHunter, nullRounds, interrogator }
class OrdoSkillDefinition {
  final OrdoSkill id; final String nameRu, description; final WeaponOrdo ordo; final int cost; final double damageBonus, defenseBonus;
  const OrdoSkillDefinition(this.id,this.nameRu,this.description,this.ordo,{this.cost=1,this.damageBonus=0,this.defenseBonus=0});
}
const ordoSkillCatalog = <OrdoSkillDefinition>[
  OrdoSkillDefinition(OrdoSkill.wardingSeal,'Печать защиты','Снижает входящий варп-урон; защитная печать Маллеус.',WeaponOrdo.malleus,defenseBonus:.06),
  OrdoSkillDefinition(OrdoSkill.daemonology,'Знание демонологии','Увеличивает урон по демонам оружием Маллеус.',WeaponOrdo.malleus,damageBonus:.10),
  OrdoSkillDefinition(OrdoSkill.banishment,'Ритуал изгнания','Усиливает варп-оружие против демонов и элитных целей.',WeaponOrdo.malleus,damageBonus:.08),
  OrdoSkillDefinition(OrdoSkill.witchHunter,'Охотник на ведьм','Увеличивает урон по культистам и псайкерам.',WeaponOrdo.hereticus,damageBonus:.10),
  OrdoSkillDefinition(OrdoSkill.nullRounds,'Нулевые заряды','Снижает эффективность варп-защиты псайкеров; бонус против хаоса.',WeaponOrdo.hereticus,damageBonus:.07),
  OrdoSkillDefinition(OrdoSkill.interrogator,'Искусство допроса','Повышает эффективность против человеческих фракций.',WeaponOrdo.hereticus,damageBonus:.05),
];

class OrdoDoctrine {
  final Set<OrdoSkill> unlockedSkills;
  const OrdoDoctrine({this.unlockedSkills=const {}});
  bool has(OrdoSkill id)=>unlockedSkills.contains(id);
  double damageMultiplier({required WeaponOrdo weaponOrdo,required String targetFaction,required DamageType damageType}) {
    var bonus=0.0;
    for(final skill in ordoSkillCatalog.where((s)=>unlockedSkills.contains(s.id)&&s.ordo==weaponOrdo)) {
      final applies = switch(skill.id) {
        OrdoSkill.wardingSeal => false,
        OrdoSkill.daemonology || OrdoSkill.banishment => targetFaction=='daemon' || targetFaction=='chaos',
        OrdoSkill.witchHunter => targetFaction=='cult' || targetFaction=='psyker' || targetFaction=='chaos',
        OrdoSkill.nullRounds => targetFaction=='psyker' || targetFaction=='chaos',
        OrdoSkill.interrogator => targetFaction=='cult' || targetFaction=='human',
      };
      if(applies) bonus+=skill.damageBonus;
    }
    return 1+bonus;
  }
  double get warpDefenseBonus => unlockedSkills.contains(OrdoSkill.wardingSeal) ? .06 : 0;
  Map<String,dynamic> toJson()=>{'unlockedSkills':unlockedSkills.map((e)=>e.name).toList()};
  factory OrdoDoctrine.fromJson(dynamic raw) {
    final values=raw is Map && raw['unlockedSkills'] is List ? raw['unlockedSkills'] as List : const [];
    return OrdoDoctrine(unlockedSkills: values.whereType<String>().map((s)=>OrdoSkill.values.where((e)=>e.name==s).firstOrNull).whereType<OrdoSkill>().toSet());
  }
}
extension _OrdoFirstOrNull<T> on Iterable<T> { T? get firstOrNull=>isEmpty?null:first; }
