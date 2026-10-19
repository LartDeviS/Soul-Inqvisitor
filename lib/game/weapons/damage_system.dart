import 'weapon_data.dart';
class DamageContext { final String targetFaction; final double armor; final bool boss, weakSpot; const DamageContext({this.targetFaction='human',this.armor=0,this.boss=false,this.weakSpot=false}); }
class DamageResult { final int amount; final double multiplier, effectiveArmor; final String reason; const DamageResult(this.amount,this.multiplier,this.effectiveArmor,this.reason); }
class DamageSystem {
  static DamageResult calculate({required int baseDamage,required DamageType type,required DamageContext target,double armorPenetration=0}) {
    final armor=(target.armor-armorPenetration).clamp(0.0,.85).toDouble(); double mult=1.0; final notes=<String>[];
    switch(target.targetFaction){
      case 'necron': if(type==DamageType.plasma||type==DamageType.melta){mult*=1.28;notes.add('уязвимость к теплу');} else if(type==DamageType.kinetic) mult*=.88; break;
      case 'tyranid': if(type==DamageType.flame||type==DamageType.explosive) mult*=1.18; break;
      case 'daemon': if(type==DamageType.warp) mult*=1.25; else if(type==DamageType.kinetic) mult*=.82; break;
      case 'ork': if(type==DamageType.flame||type==DamageType.plasma||type==DamageType.melta) mult*=1.12; break;
      case 'chaos': if(type==DamageType.warp) mult*=1.12; break;
    }
    if(target.boss && (type==DamageType.plasma||type==DamageType.melta)) mult*=1.12;
    if(target.weakSpot) {mult*=1.22;notes.add('уязвимая зона');}
    final amount=(baseDamage*mult*(1-armor)).round().clamp(1,999999);
    return DamageResult(amount,mult,armor,notes.isEmpty?'обычное попадание':notes.join(', '));
  }
}
