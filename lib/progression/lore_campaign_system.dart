/// Stage IV: lore, investigations, Ordo reputation, relic trade-offs and campaign consequences.
/// Pure Dart domain models; UI/gameplay can call these APIs without depending on Flame.

enum InvestigationDecision { rapidPurge, preserveEvidence }
enum RelicRisk { none, healthDrain, alarmIncrease, ammoScarcity, warpInstability }

class EnemyDossier {
  final String enemyId, name, origin, weaknesses, tactics, reward;
  final int studyReward;
  const EnemyDossier({required this.enemyId, required this.name, required this.origin,
    required this.weaknesses, required this.tactics, required this.reward, this.studyReward = 5});
}

class EnemyDossierCatalog {
  static const List<EnemyDossier> all = [
    EnemyDossier(enemyId:'cult_shooter', name:'Культист-стрелок', origin:'Гражданские, сломленные проповедями Хаоса и обещаниями силы.', weaknesses:'Уязвим при сближении; слабая броня.', tactics:'Держит дистанцию и ведёт огонь очередями. Используй укрытия и фланг.', reward:'Опыт и реквизиция', studyReward:5),
    EnemyDossier(enemyId:'cult_sniper', name:'Снайпер-культист', origin:'Фанатик, обученный охотиться на офицеров и санкционированных псайкеров.', weaknesses:'Низкая скорость и малая стойкость в ближнем бою.', tactics:'Прицеливается перед мощным выстрелом. Срывай прицеливание движением.', reward:'Данные о позициях противника', studyReward:7),
    EnemyDossier(enemyId:'chaos_bulwark', name:'Бронированный элитник Хаоса', origin:'Бывший солдат Империума в тяжёлой осквернённой броне.', weaknesses:'Медлителен; уязвим для бронебойных боеприпасов.', tactics:'Продвигается прямо и подавляет огнём. Обходи с фланга.', reward:'Редкие компоненты', studyReward:10),
    EnemyDossier(enemyId:'chaos_psyker', name:'Псайкер Хаоса', origin:'Колдун, чья воля стала проводником варп-сущностей.', weaknesses:'Низкая физическая стойкость; опасен, пока свободно колдует.', tactics:'Подготавливает варп-атаку. Прерывай каст и не стой в отмеченной зоне.', reward:'Психоактивные данные', studyReward:10),
    EnemyDossier(enemyId:'bloodletter', name:'Кровопускатель', origin:'Демон Кхорна, проявившийся через нестабильный разлом.', weaknesses:'Подвержен концентрированному урону после промаха рывком.', tactics:'Быстро сокращает дистанцию и атакует сериями.', reward:'Образец варп-остатка', studyReward:10),
    EnemyDossier(enemyId:'warp_summoner', name:'Призыватель разлома', origin:'Демонолог, поддерживающий портал ценой жертв и собственной плоти.', weaknesses:'Хрупок вне прикрытия; призыв требует времени.', tactics:'Создаёт подкрепления. Устрани его до завершения ритуала.', reward:'Координаты варп-узла', studyReward:12),
    EnemyDossier(enemyId:'tyranid_gaunt', name:'Тиранид-гаунт', origin:'Организм-рабочий роя, управляемый инстинктом и синаптическим импульсом.', weaknesses:'Малая прочность; эффективны атаки по группе.', tactics:'Обходит с флангов и атакует стаей.', reward:'Ксенобиологические данные', studyReward:5),
    EnemyDossier(enemyId:'tyranid_stalker', name:'Тиранид-убийца', origin:'Быстрый охотник, выведенный для устранения изолированных целей.', weaknesses:'Уязвим после неудачного прыжка.', tactics:'Меняет позицию и пытается атаковать сзади.', reward:'Сведения о повадках роя', studyReward:8),
    EnemyDossier(enemyId:'necron_immortal', name:'Некрон-бессмертный', origin:'Воин древней династии, пробуждённый из тысячелетнего сна.', weaknesses:'Уязвим к стабильному огню; не давай ему восстановить строй.', tactics:'Стреляет с дистанции и держит линию.', reward:'Ксенотехнические сведения', studyReward:10),
    EnemyDossier(enemyId:'ork_boy', name:'Орк', origin:'Воин-ксенос, усиливающийся в свалке и под боевой какофонией.', weaknesses:'Слабая дисциплина; опасен в ближнем бою.', tactics:'Рвётся вперёд. Контролируй дистанцию и не позволяй окружить себя.', reward:'Данные о численности орков', studyReward:5),
  ];
  static EnemyDossier? byId(String id) { for (final item in all) { if (item.enemyId == id) return item; } return null; }
}

class InvestigationState {
  final String id, title, briefing;
  final Set<String> evidenceIds = <String>{};
  final Set<String> interrogatedWitnesses = <String>{};
  InvestigationDecision? decision;
  bool completed = false;
  InvestigationState({required this.id, required this.title, required this.briefing});
  bool collectEvidence(String evidenceId) => evidenceIds.add(evidenceId);
  bool interrogate(String witnessId) => interrogatedWitnesses.add(witnessId);
  /// Preserving evidence improves intel/reputation; rapid purge grants immediate requisition but raises alarm.
  Map<String, int> conclude(InvestigationDecision choice) {
    decision = choice; completed = true;
    if (choice == InvestigationDecision.preserveEvidence) {
      return {'clues': evidenceIds.length + interrogatedWitnesses.length, 'requisition': 8, 'alarm': -2, 'reputation': 3};
    }
    return {'clues': 0, 'requisition': 22, 'alarm': 3, 'reputation': -2};
  }
  Map<String, dynamic> toJson() => {'id':id,'title':title,'briefing':briefing,'evidenceIds':evidenceIds.toList(),'interrogatedWitnesses':interrogatedWitnesses.toList(),'decision':decision?.name,'completed':completed};
  void loadJson(dynamic raw) { if (raw is! Map) return; evidenceIds..clear()..addAll((raw['evidenceIds'] as List? ?? const []).whereType<String>()); interrogatedWitnesses..clear()..addAll((raw['interrogatedWitnesses'] as List? ?? const []).whereType<String>()); final d=raw['decision']; decision=InvestigationDecision.values.where((e)=>e.name==d).firstOrNull; completed=raw['completed']==true; }
}

class OrdoReputation {
  final Map<String, int> _standing = {'malleus':0,'hereticus':0,'xenos':0};
  int standing(String ordo) => _standing[ordo.toLowerCase()] ?? 0;
  void add(String ordo, int amount) { final key=ordo.toLowerCase(); _standing[key]=(( _standing[key] ?? 0)+amount).clamp(-100,100).toInt(); }
  bool unlocks(String ordo, {int required=10}) => standing(ordo)>=required;
  List<String> get availableOrders => [if (standing('malleus')>=10) 'Охота на демонический источник', if (standing('hereticus')>=10) 'Расследование еретического культа', if (standing('xenos')>=10) 'Изъятие ксенотехнологии'];
  Map<String,dynamic> toJson()=>Map<String,dynamic>.from(_standing);
  void loadJson(dynamic raw){if(raw is Map){for(final key in ['malleus','hereticus','xenos']){final v=raw[key];if(v is num)_standing[key]=v.toInt().clamp(-100,100).toInt();}}}
}

class RelicChoice {
  final String id, name, description;
  final double damageMultiplier, incomingDamageMultiplier;
  final RelicRisk risk;
  const RelicChoice({required this.id,required this.name,required this.description,required this.damageMultiplier,required this.incomingDamageMultiplier,required this.risk});
}
class RelicCatalog {
  static const List<RelicChoice> all = [
    RelicChoice(id:'cursed_round',name:'Проклятый патрон',description:'+25% урона оружия, но входящий урон увеличен на 15%.',damageMultiplier:1.25,incomingDamageMultiplier:1.15,risk:RelicRisk.healthDrain),
    RelicChoice(id:'saint_ward',name:'Печать святого',description:'Входящий урон снижен на 20%, но урон оружия снижен на 10%.',damageMultiplier:0.90,incomingDamageMultiplier:0.80,risk:RelicRisk.ammoScarcity),
    RelicChoice(id:'warp_lens',name:'Линза варп-наблюдателя',description:'+40% урона по слабым местам, но растёт тревога операции.',damageMultiplier:1.40,incomingDamageMultiplier:1.0,risk:RelicRisk.warpInstability),
    RelicChoice(id:'iron_oath',name:'Железная клятва',description:'+10% урона и защита от части урона, но меньше награда за реквизицию.',damageMultiplier:1.10,incomingDamageMultiplier:0.90,risk:RelicRisk.alarmIncrease),
  ];
  static RelicChoice? byId(String id){for(final r in all){if(r.id==id)return r;}return null;}
}

class BranchingContract {
  final String id, title, description;
  final List<ContractRoute> routes;
  String selectedRouteId;
  bool completed=false;
  BranchingContract({required this.id,required this.title,required this.description,required this.routes,this.selectedRouteId=''}) { if(selectedRouteId.isEmpty && routes.isNotEmpty) selectedRouteId=routes.first.id; }
  ContractRoute? get selectedRoute { for(final r in routes){if(r.id==selectedRouteId)return r;} return null; }
  bool choose(String routeId){if(completed || !routes.any((r)=>r.id==routeId))return false;selectedRouteId=routeId;return true;}
  Map<String,dynamic> toJson()=>{'id':id,'selectedRouteId':selectedRouteId,'completed':completed};
}
class ContractRoute { final String id,label,objective,condition,consequence; final int requisitionReward; const ContractRoute({required this.id,required this.label,required this.objective,required this.condition,required this.consequence,required this.requisitionReward}); }
class BranchingContractCatalog {
  static final List<BranchingContract> all = [
    BranchingContract(id:'ash_and_truth',title:'Пепел и истина',description:'Культ укрылся в жилом секторе. Выбери приоритет операции.',routes:const [
      ContractRoute(id:'purge',label:'Немедленное очищение',objective:'Уничтожить лидера и зачистить сектор',condition:'Выполнить до заполнения шкалы тревоги',consequence:'Сектор потерян, будущих свидетелей не будет',requisitionReward:35),
      ContractRoute(id:'evidence',label:'Изъять доказательства',objective:'Собрать улики и задержать информатора',condition:'Сохранить не менее двух улик',consequence:'Откроется дополнительное расследование',requisitionReward:20),
    ]),
    BranchingContract(id:'silent_vault',title:'Безмолвный склеп',description:'Некронский комплекс пробуждается. Риск или осторожность?',routes:const [
      ContractRoute(id:'destroy',label:'Разрушить ядро',objective:'Уничтожить источник питания',condition:'Победить охрану ядра',consequence:'Угроза устранена, ксеноданные уничтожены',requisitionReward:40),
      ContractRoute(id:'recover',label:'Извлечь данные',objective:'Взломать терминал и отступить',condition:'Сохранить терминал до завершения взлома',consequence:'Откроются сведения о следующем этаже',requisitionReward:28),
    ]),
  ];
  static BranchingContract? byId(String id){for(final c in all){if(c.id==id)return c;}return null;}
}

class CampaignConsequences {
  int evidenceDestroyed=0, witnessesSaved=0, witnessesLost=0, terminalsRecovered=0, sectorsPurged=0;
  final Set<String> flags=<String>{};
  void recordEvidenceDestroyed([int count=1])=>evidenceDestroyed+=count;
  void recordWitnessSaved([int count=1])=>witnessesSaved+=count;
  void recordWitnessLost([int count=1])=>witnessesLost+=count;
  void recordTerminalRecovered()=>terminalsRecovered++;
  void recordSectorPurged()=>sectorsPurged++;
  bool get informantNetworkAvailable=>witnessesSaved>0 && evidenceDestroyed<3;
  bool get xenoIntelAvailable=>terminalsRecovered>0;
  String get nextBriefing { if(informantNetworkAvailable)return 'Свидетельская сеть раскрыла безопасный маршрут и дополнительную цель.'; if(xenoIntelAvailable)return 'Извлечённые данные отмечают уязвимость охраны на следующем объекте.'; if(evidenceDestroyed>=3)return 'Улики уничтожены: координаты следующей цели неизвестны, тревога повышена.'; if(witnessesLost>0)return 'Потеря свидетелей усложнила идентификацию цели.'; return 'Командование ожидает отчёт. Дополнительных разведданных нет.'; }
  Map<String,dynamic> toJson()=>{'evidenceDestroyed':evidenceDestroyed,'witnessesSaved':witnessesSaved,'witnessesLost':witnessesLost,'terminalsRecovered':terminalsRecovered,'sectorsPurged':sectorsPurged,'flags':flags.toList()};
  void loadJson(dynamic raw){if(raw is! Map)return; evidenceDestroyed=(raw['evidenceDestroyed'] as num?)?.toInt()??0;witnessesSaved=(raw['witnessesSaved'] as num?)?.toInt()??0;witnessesLost=(raw['witnessesLost'] as num?)?.toInt()??0;terminalsRecovered=(raw['terminalsRecovered'] as num?)?.toInt()??0;sectorsPurged=(raw['sectorsPurged'] as num?)?.toInt()??0;flags..clear()..addAll((raw['flags'] as List? ?? const []).whereType<String>());}
}

extension _FirstOrNullLore<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
