/// Persistent branching narrative layer for Soul of the Inquisitor.
/// Pure Dart domain model: the Flutter overlay renders this data and submits choices.

enum StoryChoiceTone { puritan, radical, investigative, pragmatic }

class StoryEvidence {
  final String id;
  final String title;
  final String description;
  const StoryEvidence({required this.id, required this.title, required this.description});
}

/// A field operation attached to an investigation scene. Completing the existing
/// action run records a persistent flag that can unlock a special narrative route.
class StoryOperation {
  final String id;
  final String nodeId;
  final String title;
  final String objective;
  final String briefing;
  final String successFlag;
  final int requiredKills;
  final int requiredChampions;
  final int requiredBosses;
  final Set<String> requiredFieldObjectives;
  const StoryOperation({
    required this.id,
    required this.nodeId,
    required this.title,
    required this.objective,
    required this.briefing,
    required this.successFlag,
    this.requiredKills = 0,
    this.requiredChampions = 0,
    this.requiredBosses = 0,
    this.requiredFieldObjectives = const <String>{},
  });
}

class StoryChoice {
  final String id;
  final String label;
  final String consequenceText;
  final String nextNodeId;
  final Set<String> requiredFlags;
  final Set<String> requiredEvidence;
  final Set<String> flagsToAdd;
  final int corruptionDelta;
  final int requisitionDelta;
  final StoryChoiceTone tone;
  final int requiredMinSectorStability;
  const StoryChoice({
    required this.id,
    required this.label,
    required this.consequenceText,
    required this.nextNodeId,
    this.requiredFlags = const <String>{},
    this.requiredEvidence = const <String>{},
    this.flagsToAdd = const <String>{},
    this.corruptionDelta = 0,
    this.requisitionDelta = 0,
    this.tone = StoryChoiceTone.investigative,
    this.requiredMinSectorStability = 0,
  });
}

class StoryNode {
  final String id;
  final String chapterId;
  final String chapterTitle;
  final String title;
  final String location;
  final String briefing;
  final String dialogueSpeaker;
  final String dialogue;
  final List<StoryEvidence> evidence;
  final List<StoryChoice> choices;
  final bool ending;
  const StoryNode({
    required this.id,
    required this.chapterId,
    required this.chapterTitle,
    required this.title,
    required this.location,
    required this.briefing,
    this.dialogueSpeaker = 'Сервочереп-аналитик',
    this.dialogue = '',
    this.evidence = const <StoryEvidence>[],
    this.choices = const <StoryChoice>[],
    this.ending = false,
  });
}

class StoryCampaignSystem {
  static const int schemaVersion = 4;
  static const List<StoryOperation> operations = <StoryOperation>[
    StoryOperation(
      id: 'secure_station', nodeId: 'station_investigation',
      title: 'Операция «Тишина в эфире»',
      objective: 'Зачистить вокс-станцию и завершить вылазку живым.',
      briefing: 'Группа подавления обнаружила активность в нижнем техническом ярусе. Уничтожьте сопротивление и вернитесь с подтверждением, что станция больше не используется заговорщиками.',
      successFlag: 'operation_station_secured',
      requiredKills: 12, requiredBosses: 1,
      requiredFieldObjectives: <String>{'station_relay_disabled'},
    ),
    StoryOperation(
      id: 'intercept_cargo', nodeId: 'cargo_depot',
      title: 'Операция «Груз без печати»',
      objective: 'Перехватить маршрут снабжения и выжить.',
      briefing: 'По следу контейнера отправлен ударный отряд. Перехват должен лишить сеть снабжения прикрытия и дать Инквизитору доказательство для входа в архив.',
      successFlag: 'operation_cargo_intercepted',
      requiredKills: 10, requiredChampions: 1, requiredBosses: 1,
      requiredFieldObjectives: <String>{'cargo_manifest_secured'},
    ),
    StoryOperation(
      id: 'breach_archive', nodeId: 'archive_confrontation',
      title: 'Операция «Архив под пеплом»',
      objective: 'Прорваться в архивный комплекс и завершить операцию.',
      briefing: 'Архив закрыт внутренними печатями, а охрана получила приказ уничтожить документы. Захватите комплекс, чтобы открыть путь к тактическому задержанию куратора.',
      successFlag: 'operation_archive_breached',
      requiredKills: 8, requiredBosses: 1,
      requiredFieldObjectives: <String>{'archive_core_alpha', 'archive_core_omega'},
    ),
    StoryOperation(
      id: 'secure_outer_relay', nodeId: 'case_04_field_operation',
      title: 'Операция «Эхо за печатью»',
      objective: 'Захватить внешний ретранслятор, извлечь пакет и ликвидировать его стража.',
      briefing: 'Источник сигнала находится за пределами Геллион-IX. Маршрут разведки определяет подход к узлу, но сам ретранслятор охраняет неизвестная боевая единица. Активируйте восходящий канал, затем уничтожьте стража и завершите вылазку живым.',
      successFlag: 'operation_outer_relay_secured',
      requiredKills: 8, requiredBosses: 1,
      requiredFieldObjectives: <String>{'outer_relay_uplink_secured'},
    ),
  ];
  static const List<StoryNode> nodes = <StoryNode>[
    StoryNode(
      id: 'prologue_briefing', chapterId: 'case_01', chapterTitle: 'Дело I — Пепел вокс-станции',
      title: 'Приказ из Ордо', location: 'Крейсер «Безмолвный приговор»',
      briefing: 'На промышленной луне Геллион-IX замолчала имперская вокс-станция. Последний пакет содержал фрагмент молитвы, наложенный на координаты запретного грузового маршрута. Ордо требует установить источник сигнала и не допустить утечки сведений.',
      dialogueSpeaker: 'Инквизиторский куратор',
      dialogue: '«Не путай скорость с поспешностью. Нам нужен виновный, но ещё больше нам нужна правда. Реши, будет ли сектор закрыт до начала дознания».',
      choices: <StoryChoice>[
        StoryChoice(id: 'seal_sector', label: 'Изолировать сектор и начать дознание', consequenceText: 'Снизит риск утечки, но напугает свидетелей.', nextNodeId: 'station_investigation', flagsToAdd: <String>{'sector_sealed'}, requisitionDelta: 5, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'covert_entry', label: 'Войти скрытно, не предупреждая местные власти', consequenceText: 'Сохранит элемент неожиданности и откроет радикальный путь.', nextNodeId: 'station_investigation', flagsToAdd: <String>{'covert_entry'}, corruptionDelta: 1, tone: StoryChoiceTone.radical),
      ],
    ),
    StoryNode(
      id: 'station_investigation', chapterId: 'case_01', chapterTitle: 'Дело I — Пепел вокс-станции',
      title: 'Молчание станции', location: 'Вокс-станция «Гелиос-4»',
      briefing: 'Внутри нет следов открытого боя. Консоли выжжены изнутри, а двери запечатаны по протоколу техноереси. Три зацепки могут связать саботаж с грузовым маршрутом.',
      dialogueSpeaker: 'Сервочереп «Люмен»',
      dialogue: '«Обнаружены следы химического ожога, удалённые записи доступа и остаточная варп-активность. Приоритет анализа выбирает оператор».',
      evidence: <StoryEvidence>[
        StoryEvidence(id: 'vox_fragment', title: 'Повреждённый вокс-фрагмент', description: 'В шуме повторяется позывной «Серая свеча». Доказательство указывает на организованную передачу.'),
        StoryEvidence(id: 'access_log', title: 'Журнал доступа', description: 'За минуту до отключения использован служебный код диакона Вейла.'),
        StoryEvidence(id: 'warp_residue', title: 'Варп-остаток', description: 'След слишком слаб для призыва, но согласуется с ритуальным подавлением сигнала.'),
      ],
      choices: <StoryChoice>[
        StoryChoice(id: 'secure_station_route', label: 'Предъявить полевой отчёт и допросить Вейла', consequenceText: 'Успешная полевая операция подтверждает безопасность места и открывает более надёжный допрос.', nextNodeId: 'deacon_interrogation', requiredFlags: <String>{'operation_station_secured'}, requiredEvidence: <String>{'access_log'}, flagsToAdd: <String>{'station_secured', 'deacon_questioned_under_guard'}, requisitionDelta: 8, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'question_deacon', label: 'Допросить диакона Вейла', consequenceText: 'Доступ к допросу зависит от журнала доступа или вокс-фрагмента.', nextNodeId: 'deacon_interrogation', requiredEvidence: <String>{'access_log'}),
        StoryChoice(id: 'trace_cargo', label: 'Проследить маршрут «Серой свечи»', consequenceText: 'Путь ведёт к подпольному складу.', nextNodeId: 'cargo_depot', requiredEvidence: <String>{'vox_fragment'}, flagsToAdd: <String>{'cargo_route_found'}, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'purge_station', label: 'Сжечь станцию и закрыть дело', consequenceText: 'Угроза на месте будет устранена, но важные следы могут быть потеряны.', nextNodeId: 'puritan_verdict', flagsToAdd: <String>{'station_purged'}, corruptionDelta: -3, requisitionDelta: 12, tone: StoryChoiceTone.puritan),
      ],
    ),
    StoryNode(
      id: 'deacon_interrogation', chapterId: 'case_01', chapterTitle: 'Дело I — Пепел вокс-станции',
      title: 'Свидетель под печатью', location: 'Изолятор станции',
      briefing: 'Диакон Вейл утверждает, что его код украли. Он знает позывной «Серая свеча», но просит защиту для семьи. Допрос может сохранить свидетеля или превратить его в очередную запись в архиве казней.',
      dialogueSpeaker: 'Диакон Вейл',
      dialogue: '«Я не открывал канал. Клянусь Террой. Но я видел грузчиков без знаков цеха. Они увезли ящик в старый склад под часовней».',
      evidence: <StoryEvidence>[
        StoryEvidence(id: 'deacon_testimony', title: 'Показания диакона', description: 'Вейл связывает грузовой маршрут со старым складом под часовней и просит защиты.'),
      ],
      choices: <StoryChoice>[
        StoryChoice(id: 'protect_witness', label: 'Взять Вейла под защиту', consequenceText: 'Откроет дополнительную зацепку в следующем деле.', nextNodeId: 'cargo_depot', flagsToAdd: <String>{'witness_protected', 'deacon_alive'}, requisitionDelta: -3, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'coerce_witness', label: 'Принудить Вейла к сотрудничеству', consequenceText: 'Получите сведения немедленно, но доверие будет потеряно.', nextNodeId: 'cargo_depot', flagsToAdd: <String>{'witness_coerced'}, corruptionDelta: 2, requisitionDelta: 8, tone: StoryChoiceTone.radical),
        StoryChoice(id: 'execute_witness', label: 'Казнить за соучастие', consequenceText: 'Допрос закончен. В дальнейшем свидетели будут менее склонны сотрудничать.', nextNodeId: 'cargo_depot', flagsToAdd: <String>{'deacon_executed'}, corruptionDelta: -2, requisitionDelta: 5, tone: StoryChoiceTone.puritan),
      ],
    ),
    StoryNode(
      id: 'cargo_depot', chapterId: 'case_02', chapterTitle: 'Дело II — Груз без печати',
      title: 'Склад под часовней', location: 'Нижние ярусы Геллион-IX',
      briefing: 'Склад пуст, но его пол испещрён следами тяжёлого контейнера. На стене — символ серой свечи, перечёркнутый тремя линиями. За дверью слышен ритм промышленного насоса: груз уже перемещают дальше.',
      dialogueSpeaker: 'Сервочереп «Люмен»',
      dialogue: '«Обнаружен конфликт показаний. Если свидетель был защищён, его тайный знак совпадает с маркировкой контейнера. Если он погиб, остаётся только машинная запись».',
      evidence: <StoryEvidence>[
        StoryEvidence(id: 'cargo_manifest', title: 'Поддельная накладная', description: 'Контейнер оформлен как медицинское оборудование, но его масса соответствует тяжёлому реликварию.'),
        StoryEvidence(id: 'grey_candle_mark', title: 'Знак Серой свечи', description: 'Символ указывает на сеть снабжения, действующую через подставные приходы.'),
        StoryEvidence(id: 'hidden_vox', title: 'Скрытая передача', description: 'Запись подтверждает, что груз направлен в архивный комплекс под старой цитаделью.'),
      ],
      choices: <StoryChoice>[
        StoryChoice(id: 'ambush_cargo_convoy', label: 'Устроить засаду на грузовой конвой', consequenceText: 'Полевой перехват позволяет войти в архив через охраняемый грузовой шлюз.', nextNodeId: 'archive_confrontation', requiredFlags: <String>{'operation_cargo_intercepted'}, requiredEvidence: <String>{'cargo_manifest'}, flagsToAdd: <String>{'cargo_intercept', 'archive_entry_secure'}, requisitionDelta: 18, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'follow_archive', label: 'Перехватить груз у архивного комплекса', consequenceText: 'Позволит выйти на организатора сети.', nextNodeId: 'archive_confrontation', requiredEvidence: <String>{'cargo_manifest'}, flagsToAdd: <String>{'cargo_intercept'}, requisitionDelta: 10, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'use_witness_mark', label: 'Использовать тайный знак защищённого свидетеля', consequenceText: 'Только защищённый Вейл может открыть запасной вход в архив.', nextNodeId: 'archive_confrontation', requiredFlags: <String>{'witness_protected'}, requiredEvidence: <String>{'cargo_manifest'}, flagsToAdd: <String>{'witness_route'}, requisitionDelta: 15, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'submit_preserved_manifest', label: 'Передать сохранённую накладную Ордо', consequenceText: 'Сохранённая накладная подтверждает цепочку снабжения и укрепляет доказательную базу перед штурмом.', nextNodeId: 'archive_confrontation', requiredFlags: <String>{'cargo_evidence_preserved'}, requiredEvidence: <String>{'cargo_manifest'}, flagsToAdd: <String>{'manifest_chain_verified'}, requisitionDelta: 22, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'broadcast_accusation', label: 'Обнародовать обвинение через местный вокс', consequenceText: 'Поднимет тревогу и вынудит заговорщиков действовать открыто.', nextNodeId: 'archive_confrontation', flagsToAdd: <String>{'public_accusation'}, corruptionDelta: 3, requisitionDelta: 15, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'destroy_manifest', label: 'Уничтожить накладные и изъять груз', consequenceText: 'Скроет операцию от властей, но осложнит доказательство вины.', nextNodeId: 'archive_confrontation', flagsToAdd: <String>{'evidence_suppressed'}, corruptionDelta: 4, requisitionDelta: 20, tone: StoryChoiceTone.radical),
      ],
    ),
    StoryNode(
      id: 'archive_confrontation', chapterId: 'case_03', chapterTitle: 'Дело III — Архив под пеплом',
      title: 'Архив без имён', location: 'Подземный архив старой цитадели',
      briefing: 'В архиве хранятся списки исчезнувших работников, схемы запретного канала и печать, которую не должен иметь ни один местный чиновник. За заговором стоит человек с доступом к имперским приказам.',
      dialogueSpeaker: 'Архивариус Кастор',
      dialogue: '«Вы пришли за культистами, но они лишь переносили ящики. Подпись на приказе принадлежит человеку, который прислал вас сюда».',
      evidence: <StoryEvidence>[
        StoryEvidence(id: 'sealed_order', title: 'Приказ с двойной печатью', description: 'Одна печать подлинная, вторая нанесена позже. След ведёт к куратору операции.'),
        StoryEvidence(id: 'missing_names', title: 'Список исчезнувших', description: 'Сотни работников объявлены умершими до фактического исчезновения.'),
        StoryEvidence(id: 'warp_blueprint', title: 'Схема подавителя', description: 'Устройство не призывает демона, а скрывает передачу данных от санкционированных сканеров.'),
      ],
      choices: <StoryChoice>[
        StoryChoice(id: 'tactical_capture_curator', label: 'Задержать куратора после штурма архива', consequenceText: 'Полевой успех позволяет сохранить документы и взять куратора живым. Это открывает отдельный тактический финал.', nextNodeId: 'ending_tactical_justice', requiredFlags: <String>{'operation_archive_breached'}, requiredEvidence: <String>{'sealed_order', 'missing_names'}, flagsToAdd: <String>{'curator_captured_alive', 'archive_secured'}, requisitionDelta: 65, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'expose_curator', label: 'Предъявить доказательства и арестовать куратора', consequenceText: 'Доступно при наличии приказа и списка исчезнувших.', nextNodeId: 'ending_justice', requiredEvidence: <String>{'sealed_order', 'missing_names'}, flagsToAdd: <String>{'curator_exposed'}, requisitionDelta: 35, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'testify_with_witness', label: 'Вывести защищённого свидетеля и дать показания', consequenceText: 'Особый путь справедливости: свидетель подтверждает цепочку приказов.', nextNodeId: 'ending_witness_justice', requiredFlags: <String>{'witness_protected'}, requiredEvidence: <String>{'sealed_order', 'missing_names'}, flagsToAdd: <String>{'witness_testified', 'curator_exposed'}, requisitionDelta: 50, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'testify_with_archivist', label: 'Вывести спасённого архивариуса к трибуналу', consequenceText: 'Архивариус пережил штурм и подтверждает, что документы не были подменены после захвата.', nextNodeId: 'ending_justice', requiredFlags: <String>{'archive_archivist_rescued'}, requiredEvidence: <String>{'sealed_order', 'missing_names'}, flagsToAdd: <String>{'archivist_testified', 'curator_exposed'}, requisitionDelta: 42, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'submit_complete_dossier', label: 'Предъявить полное досье трёх спасённых линий', consequenceText: 'Особый финал доступен, если свидетель защищён, накладная сохранена, архивариус спасён, а приказ и список исчезнувших изъяты. Все три линии подтверждают друг друга.', nextNodeId: 'ending_complete_dossier', requiredFlags: <String>{'witness_protected', 'cargo_evidence_preserved', 'archive_archivist_rescued'}, requiredEvidence: <String>{'sealed_order', 'missing_names', 'cargo_manifest'}, flagsToAdd: <String>{'complete_dossier_submitted', 'curator_exposed', 'all_witnesses_protected'}, requisitionDelta: 75, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'purge_archive', label: 'Объявить архив заражённым и уничтожить его', consequenceText: 'Сохранит секретность, но правда останется погребённой.', nextNodeId: 'ending_purge', flagsToAdd: <String>{'archive_purged'}, corruptionDelta: -8, requisitionDelta: 20, tone: StoryChoiceTone.puritan),
        StoryChoice(id: 'use_blueprint', label: 'Присвоить схему и использовать её против врагов', consequenceText: 'Откроет радикальный исход при наличии схемы подавителя.', nextNodeId: 'ending_radical', requiredEvidence: <String>{'warp_blueprint'}, flagsToAdd: <String>{'blueprint_taken'}, corruptionDelta: 12, requisitionDelta: 45, tone: StoryChoiceTone.radical),
        StoryChoice(id: 'restore_helion', label: 'Восстановить порядок и передать сектор гражданской администрации', consequenceText: 'Доступно при высокой стабильности, защите Вейла, сохранённой накладной и спасённом архивариусе. Сектор получает шанс на восстановление без сокрытия преступлений.', nextNodeId: 'ending_sector_restored', requiredFlags: <String>{'witness_protected', 'cargo_evidence_preserved', 'archive_archivist_rescued'}, requiredEvidence: <String>{'sealed_order', 'missing_names', 'cargo_manifest'}, requiredMinSectorStability: 8, flagsToAdd: <String>{'sector_restored', 'curator_exposed', 'all_witnesses_protected'}, requisitionDelta: 45, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'impose_martial_law', label: 'Передать Геллион-IX под военное управление Ордо', consequenceText: 'При успешном штурме архив закрывается под охраной, а сектор переходит под чрезвычайное управление. Безопасность обеспечена ценой гражданских свобод.', nextNodeId: 'ending_military_occupation', requiredFlags: <String>{'operation_archive_breached'}, requiredEvidence: <String>{'sealed_order', 'missing_names'}, flagsToAdd: <String>{'sector_martial_law', 'curator_captured_alive'}, requisitionDelta: 30, corruptionDelta: 1, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'seal_helion_quarantine', label: 'Запечатать сектор на постоянный карантин', consequenceText: 'Доступно при успешном штурме и обнаружении схемы подавителя. Распространение угрозы ограничивается, но жители остаются под изоляцией.', nextNodeId: 'ending_sector_quarantine', requiredFlags: <String>{'operation_archive_breached'}, requiredEvidence: <String>{'sealed_order', 'warp_blueprint'}, flagsToAdd: <String>{'sector_quarantined', 'archive_purged'}, corruptionDelta: -3, requisitionDelta: 25, tone: StoryChoiceTone.puritan),
      ],
    ),
    StoryNode(
      id: 'puritan_verdict', chapterId: 'case_03', chapterTitle: 'Дело III — Архив под пеплом',
      title: 'Пепел вместо ответа', location: 'Площадь перед вокс-станцией',
      briefing: 'Станция уничтожена, а доступные улики погибли вместе с ней. В официальном отчёте дело закрыто. Но в обломках остаётся незапечатанный контейнер с архивной меткой.',
      dialogueSpeaker: 'Инквизиторский куратор',
      dialogue: '«Вы устранили угрозу, но не доказали, кто её создал. Империум запомнит результат. История — не обязательно».',
      choices: <StoryChoice>[
        StoryChoice(id: 'close_case', label: 'Закрыть дело и вернуться на крейсер', consequenceText: 'Пуританский финал: сектор очищен, заговор не раскрыт.', nextNodeId: 'ending_purge', flagsToAdd: <String>{'case_closed'}, tone: StoryChoiceTone.puritan),
        StoryChoice(id: 'reopen_case', label: 'Нарушить приказ и исследовать контейнер', consequenceText: 'Вернёт расследование на путь поиска истины.', nextNodeId: 'cargo_depot', flagsToAdd: <String>{'case_reopened'}, corruptionDelta: 2, tone: StoryChoiceTone.investigative),
      ],
    ),
    StoryNode(
      id: 'ending_complete_dossier', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Три свидетельства, одна печать',
      location: 'Зал дознаний крейсера «Безмолвный приговор»',
      briefing: 'Вейл подтвердил маршрут и происхождение знака, сохранённая накладная связала поставки с архивом, а архивариус Кастор доказал подлинность изъятых документов. Три независимые линии выдержали перекрёстную проверку. Куратор арестован, свидетели взяты под защиту, а список исчезнувших передан семьям и Ордо. Это редкая победа, в которой ни один ключевой голос не был принесён в жертву ради удобства отчёта.',
      dialogueSpeaker: 'Инквизиторский куратор', dialogue: '«Теперь это не версия. Это цепь доказательств, в которой каждое звено подтверждает следующее».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_tactical_justice', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Архив сохранён, куратор взят живым',
      location: 'Зал дознаний крейсера «Безмолвный приговор»',
      briefing: 'Штурм позволил захватить архив целиком. Куратор предстал перед закрытым трибуналом живым, а цепочка приказов и имена исчезнувших были сохранены без уничтожения доказательств. Победа не очистила сектор мгновенно, но дала Ордо возможность провести настоящее дознание.',
      dialogueSpeaker: 'Инквизиторский куратор', dialogue: '«Сила открыла дверь. Доказательства не позволили ей захлопнуться снова».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_justice', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Приговор по печати',
      location: 'Зал дознаний крейсера «Безмолвный приговор»',
      briefing: 'Доказательства выдержали проверку. Куратор арестован, сеть снабжения раскрыта, а имена пропавших внесены в официальный архив. Однако несколько приказов были уничтожены до изъятия — расследование может продолжиться.',
      dialogueSpeaker: 'Архивариус Кастор', dialogue: '«Справедливость в Империуме редко бывает чистой. Но сегодня хотя бы одна ложь получила имя и подпись».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_witness_justice', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Свидетельская печать',
      location: 'Зал дознаний крейсера «Безмолвный приговор»',
      briefing: 'Вейл дал показания перед закрытым трибуналом и подтвердил подлинность цепочки приказов. Куратор арестован, пропавшие получили имена, а свидетеля перевели под защиту Ордо. Впервые в этом секторе доказательства пережили и заговор, и процедуру дознания.',
      dialogueSpeaker: 'Диакон Вейл', dialogue: '«Я думал, что печать защищает меня от страха. Теперь я понимаю: она обязывает говорить, даже когда страшно».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_purge', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Пепел очищения',
      location: 'Карантинный периметр Геллион-IX',
      briefing: 'Сектор очищен, оборудование уничтожено, а официальное дело закрыто. Угроза не может вернуться тем же путём, но истина о двойной печати так и не попала в архив.',
      dialogueSpeaker: 'Инквизиторский куратор', dialogue: '«Империум выжил ещё на один день. Иногда это и есть единственный допустимый ответ».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_radical', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Инструмент ереси',
      location: 'Запечатанная лаборатория крейсера',
      briefing: 'Схема подавителя изъята и скрыта в личном архиве Инквизитора. Теперь у вас есть инструмент, способный обходить имперские системы контроля. Он может спасти тысячи жизней — или скрыть преступление куда большего масштаба.',
      dialogueSpeaker: 'Сервочереп «Люмен»', dialogue: '«Предупреждение: принятое решение повышает риск дальнейшей порчи. Рекомендация куратора — удалить этот файл. Вы не обязаны следовать рекомендации».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_sector_restored', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Геллион-IX: возвращение к жизни',
      location: 'Административный центр Геллион-IX',
      briefing: 'Свидетельские показания, грузовая накладная и подлинные архивные документы выдержали перекрёстную проверку. После ареста куратора Ордо передало гражданской администрации полномочия под надзором независимых представителей. Восстановление будет долгим, но семьи исчезнувших получили ответы, а сектор — шанс выйти из чрезвычайного положения.',
      dialogueSpeaker: 'Диакон Вейл', dialogue: '«Мы не вернули тех, кого потеряли. Но впервые нам не приказали забыть их имена».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_military_occupation', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Геллион-IX: железный порядок',
      location: 'Командный бастион Ордо',
      briefing: 'Куратор задержан, архив взят под вооружённую охрану, а Геллион-IX передан под военное управление. Патрули подавили открытые беспорядки, но комендантский час и проверки стали частью повседневной жизни. Сектор безопаснее, чем прежде, однако жители знают: чрезвычайные полномочия редко исчезают сами собой.',
      dialogueSpeaker: 'Инквизитор', dialogue: '«Порядок восстановлен. Не путайте это с доверием».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_sector_quarantine', chapterId: 'epilogue', chapterTitle: 'Эпилог', title: 'Геллион-IX: вечный карантин',
      location: 'Карантинный периметр Геллион-IX',
      briefing: 'Архив и опасные технологии запечатаны, а сектор отрезан от обычного сообщения. Распространение запретного сигнала остановлено, но эвакуация не смогла охватить всех жителей. Ордо объявило карантин бессрочным: угроза изолирована, цена решения останется предметом закрытых споров.',
      dialogueSpeaker: 'Сервочереп «Люмен»', dialogue: '«Риск распространения снижен до приемлемого уровня. Человеческие потери не входят в расчёт приемлемости».',
      ending: true,
    ),
    StoryNode(
      id: 'case_04_dispatch', chapterId: 'case_04', chapterTitle: 'Дело IV — Эхо за печатью',
      title: 'Эхо за печатью', location: 'Крейсер «Безмолвный приговор», зал стратегического планирования',
      briefing: 'Через несколько суток после решения по Геллион-IX на закрытом канале появляется пакет с идентификатором, который должен был исчезнуть вместе с архивом. Источник сигнала связан с прежним делом, но содержание зависит от того, что осталось после вашей операции. Новое расследование начинается не с чистого листа: прошлое определило, кто готов помочь и чему можно верить.',
      dialogueSpeaker: 'Инквизитор', dialogue: '«Дело закрыто только на бумаге. Если сигнал настоящий, кто-то пережил зачистку — или кто-то рассчитывал, что мы поверим в её завершённость».',
      choices: <StoryChoice>[
        StoryChoice(id: 'follow_reconstruction_signal', label: 'Запросить гражданскую сеть восстановления', consequenceText: 'После восстановления сектора местные связисты помогают проследить источник пакета.', nextNodeId: 'case_04_reconstruction_route', requiredFlags: <String>{'prior_ending_ending_sector_restored'}, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'follow_military_audit', label: 'Потребовать доступ к военным журналам', consequenceText: 'При военном управлении след сигнала ищут через журналы гарнизона и контрольные пункты.', nextNodeId: 'case_04_occupation_route', requiredFlags: <String>{'prior_ending_ending_military_occupation'}, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'follow_quarantine_beacon', label: 'Проверить сигнал с карантинного периметра', consequenceText: 'При бессрочном карантине пакет мог пройти только через изолированный маяк.', nextNodeId: 'case_04_quarantine_route', requiredFlags: <String>{'prior_ending_ending_sector_quarantine'}, tone: StoryChoiceTone.puritan),
        StoryChoice(id: 'follow_residual_signal', label: 'Проверить остаточный сигнал без поддержки сектора', consequenceText: 'Ни одна из трёх специальных линий не доступна. Расследование продолжается по ограниченному каналу.', nextNodeId: 'case_04_residual_route', requiredFlags: <String>{'prior_ending_other'}, tone: StoryChoiceTone.investigative),
      ],
    ),
    StoryNode(
      id: 'case_04_reconstruction_route', chapterId: 'case_04', chapterTitle: 'Дело IV — Эхо за печатью',
      title: 'Гражданский ретранслятор', location: 'Восстановленный жилой квартал Геллион-IX',
      briefing: 'Связисты обнаружили повторяющийся импульс в списке аварийных вызовов. Его маскировали под запросы на медицинскую помощь. В обмен на защиту они передают вам фрагмент маршрута, но предупреждают: несколько семей всё ещё числятся пропавшими.',
      dialogueSpeaker: 'Координатор гражданской сети', dialogue: '«Мы помним, кто не бросил свидетелей. Не просите нас снова молчать, если этот сигнал приведёт к живым людям».',
      evidence: <StoryEvidence>[StoryEvidence(id: 'case4_civilian_trace', title: 'Маршрут гражданского ретранслятора', description: 'Фрагмент маршрута, связывающий сигнал с заброшенным узлом связи.')],
      choices: <StoryChoice>[StoryChoice(id: 'submit_civilian_trace', label: 'Приобщить маршрут к новому делу', consequenceText: 'Маршрут принят как подтверждённая улика. Следующий этап расследования открыт.', nextNodeId: 'case_04_signal_review', requiredEvidence: <String>{'case4_civilian_trace'}, flagsToAdd: <String>{'case4_route_civilian'}, requisitionDelta: 8, tone: StoryChoiceTone.investigative)],
    ),
    StoryNode(
      id: 'case_04_occupation_route', chapterId: 'case_04', chapterTitle: 'Дело IV — Эхо за печатью',
      title: 'Журнал гарнизона', location: 'Военный архив Геллион-IX',
      briefing: 'Дежурный офицер находит пропуск, выданный после официального закрытия дела. Запись подтверждает, что кто-то пользовался внутренним каналом гарнизона уже после ареста куратора. Доступ к оригиналу журнала оставляет цифровой след, который невозможно полностью стереть.',
      dialogueSpeaker: 'Офицер внутренней безопасности', dialogue: '«Этот пропуск не должен был существовать. Если вы внесёте его в дело, мне придётся объяснять, почему контрольный журнал молчал».',
      evidence: <StoryEvidence>[StoryEvidence(id: 'case4_garrison_log', title: 'Запись контрольного журнала', description: 'Служебная запись о пропуске, активированном после закрытия предыдущего дела.')],
      choices: <StoryChoice>[StoryChoice(id: 'submit_garrison_log', label: 'Приобщить журнал к новому делу', consequenceText: 'Запись принята как подтверждённая улика. Следующий этап расследования открыт.', nextNodeId: 'case_04_signal_review', requiredEvidence: <String>{'case4_garrison_log'}, flagsToAdd: <String>{'case4_route_military'}, requisitionDelta: 8, tone: StoryChoiceTone.pragmatic)],
    ),
    StoryNode(
      id: 'case_04_quarantine_route', chapterId: 'case_04', chapterTitle: 'Дело IV — Эхо за печатью',
      title: 'Маяк за периметром', location: 'Карантинный периметр Геллион-IX',
      briefing: 'Сигнал идёт с автоматического маяка, который должен передавать только телеметрию герметичных шлюзов. В пакете обнаруживается человеческий голос, оборванный на координатах внутреннего сектора. Передача записи может нарушить режим секретности, но без неё след будет потерян.',
      dialogueSpeaker: 'Сервочереп «Люмен»', dialogue: '«Источник не соответствует разрешённому профилю. Вероятность присутствия живого оператора: 41,7 процента. Рекомендация: извлечь исходный пакет».',
      evidence: <StoryEvidence>[StoryEvidence(id: 'case4_quarantine_packet', title: 'Пакет карантинного маяка', description: 'Исходная передача с координатами внутреннего сектора и фрагментом человеческого голоса.')],
      choices: <StoryChoice>[StoryChoice(id: 'submit_quarantine_packet', label: 'Приобщить пакет к новому делу', consequenceText: 'Передача изъята до автоматического удаления. Следующий этап расследования открыт.', nextNodeId: 'case_04_signal_review', requiredEvidence: <String>{'case4_quarantine_packet'}, flagsToAdd: <String>{'case4_route_quarantine'}, requisitionDelta: 8, tone: StoryChoiceTone.puritan)],
    ),
    StoryNode(
      id: 'case_04_residual_route', chapterId: 'case_04', chapterTitle: 'Дело IV — Эхо за печатью',
      title: 'Остаточный импульс', location: 'Служебный отсек крейсера «Безмолвный приговор»',
      briefing: 'Без помощи местных связистов и доступа к закрытым журналам остаётся лишь короткий импульс в архиве связи крейсера. Он слишком слаб для точной локализации, но содержит повторяющийся номер старого контейнера. Это единственный след, который удалось сохранить.',
      dialogueSpeaker: 'Сервочереп «Люмен»', dialogue: '«Точность локализации низкая. Однако идентификатор контейнера совпадает с материалами предыдущего дела. Рекомендую продолжить анализ».',
      evidence: <StoryEvidence>[StoryEvidence(id: 'case4_residual_fragment', title: 'Фрагмент остаточного сигнала', description: 'Повреждённый пакет с идентификатором старого контейнера.')],
      choices: <StoryChoice>[StoryChoice(id: 'submit_residual_fragment', label: 'Приобщить фрагмент к новому делу', consequenceText: 'Фрагмент принят как подтверждённая улика, несмотря на ограниченную точность.', nextNodeId: 'case_04_signal_review', requiredEvidence: <String>{'case4_residual_fragment'}, flagsToAdd: <String>{'case4_route_residual'}, requisitionDelta: 3, tone: StoryChoiceTone.investigative)],
    ),
    StoryNode(
      id: 'case_04_signal_review', chapterId: 'case_04', chapterTitle: 'Дело IV — Эхо за печатью',
      title: 'Имя за шумом', location: 'Лаборатория криптоанализа крейсера',
      briefing: 'Собранный материал подтверждает: сигнал не является автоматическим эхом. Кто-то отправил его после завершения дела Серой свечи и намеренно использовал старый идентификатор. Улика указывает на узел связи за пределами Геллион-IX. Следующий шаг — подготовить отдельную экспедицию и установить, кто пережил зачистку.',
      dialogueSpeaker: 'Инквизитор', dialogue: '«Первое дело показало нам, кто лгал. Второе должно показать, кто остался за пределами нашего приговора».',
      choices: <StoryChoice>[
        StoryChoice(id: 'authorize_outer_relay_expedition', label: 'Одобрить экспедицию к внешнему ретранслятору', consequenceText: 'Следующее дело получает официальный статус. Собранная улика и выбранный маршрут сохраняются в хронике.', nextNodeId: 'case_04_field_operation', requiredFlags: <String>{'case4_route_civilian'}, requiredEvidence: <String>{'case4_civilian_trace'}, flagsToAdd: <String>{'case4_expedition_authorized'}, requisitionDelta: 20, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'authorize_garrison_audit', label: 'Начать с проверки военных журналов', consequenceText: 'Экспедиция будет сопровождаться внутренним аудитом гарнизонных каналов.', nextNodeId: 'case_04_field_operation', requiredFlags: <String>{'case4_route_military'}, requiredEvidence: <String>{'case4_garrison_log'}, flagsToAdd: <String>{'case4_expedition_authorized', 'case4_audit_required'}, requisitionDelta: 16, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'authorize_quarantine_probe', label: 'Отправить зонд к карантинному маяку', consequenceText: 'Экспедиция начнётся с изоляции источника и проверки сигнала на биологические и варп-аномалии.', nextNodeId: 'case_04_field_operation', requiredFlags: <String>{'case4_route_quarantine'}, requiredEvidence: <String>{'case4_quarantine_packet'}, flagsToAdd: <String>{'case4_expedition_authorized', 'case4_quarantine_protocol'}, requisitionDelta: 16, tone: StoryChoiceTone.puritan),
        StoryChoice(id: 'authorize_limited_expedition', label: 'Одобрить ограниченную экспедицию', consequenceText: 'Недостаточно данных для точной локализации, поэтому экспедиция отправится с минимальным снабжением.', nextNodeId: 'case_04_field_operation', requiredFlags: <String>{'case4_route_residual'}, requiredEvidence: <String>{'case4_residual_fragment'}, flagsToAdd: <String>{'case4_expedition_authorized', 'case4_limited_intelligence'}, requisitionDelta: 5, tone: StoryChoiceTone.investigative),
      ],
    ),
    StoryNode(
      id: 'case_04_field_operation', chapterId: 'case_04', chapterTitle: 'Дело IV — Эхо за печатью',
      title: 'Узел за пределами карты', location: 'Внешний ретранслятор «Немезида-9»',
      briefing: 'Крейсер вышел на дальность высадки. На узле обнаружены следы недавнего обслуживания и активный защитный контур. Разведывательный маршрут определяет, какие системы будут доступны на подходе, но не отменяет необходимости взять передатчик силой.',
      dialogueSpeaker: 'Инквизитор',
      dialogue: '«Мы прошли через ложь, карантин и пепел. Теперь найдите того, кто всё ещё отвечает на этот сигнал. Не уничтожайте пакет — он должен говорить на допросе».',
      choices: <StoryChoice>[
        StoryChoice(id: 'complete_outer_relay_operation', label: 'Извлечь пакет и перейти к оценке узла', consequenceText: 'После активации восходящего канала, восьми подтверждённых ликвидаций и уничтожения стража отряд получает доступ к последнему решению: допросить оператора, извлечь данные или уничтожить ретранслятор.', nextNodeId: 'case_04_relay_aftermath', requiredFlags: <String>{'operation_outer_relay_secured'}, flagsToAdd: <String>{'case4_expedition_completed'}, requisitionDelta: 12, tone: StoryChoiceTone.investigative),
      ],
    ),
    StoryNode(
      id: 'case_04_relay_aftermath', chapterId: 'case_04', chapterTitle: 'Дело IV — Эхо за печатью',
      title: 'Последний выбор у узла', location: 'Внешний ретранслятор «Немезида-9»',
      briefing: 'Страж уничтожен, восходящий канал активен, а пакет извлечён из буферного ядра. За бронестеклом обнаружен живой оператор, подключённый к резервному терминалу. Узел ещё можно сохранить, но передача уже готовится к повтору. Несколько секунд отделяют допрос от уничтожения единственного свидетеля и источника сигнала.',
      dialogueSpeaker: 'Инквизитор',
      dialogue: '«У нас три пути. Живой оператор может назвать заказчика. Сырые данные могут привести нас к следующему узлу. Или мы уничтожим передатчик и лишим врага возможности ответить. Выбирайте, что важнее: голос, истина или безопасность».',
      choices: <StoryChoice>[
        StoryChoice(id: 'capture_relay_operator', label: 'Захватить оператора живым для допроса', consequenceText: 'Оператор сохранён как свидетель. Его личность и цепь приказов станут центральной линией следующего дела, но удержание пленника потребует ресурсов.', nextNodeId: 'ending_case4_operator_captured', requiredFlags: <String>{'case4_expedition_completed'}, flagsToAdd: <String>{'case4_operator_captured', 'case4_operator_alive', 'case4_next_case_interrogation'}, requisitionDelta: 24, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'extract_relay_data', label: 'Извлечь данные и оставить узел целым', consequenceText: 'Сырые журналы передачи сохранены, а ретранслятор остаётся доступным для дальнейшего наблюдения. Вы получаете технический след к следующему узлу, но оператор может исчезнуть до возвращения отряда.', nextNodeId: 'ending_case4_data_extracted', requiredFlags: <String>{'case4_expedition_completed'}, flagsToAdd: <String>{'case4_data_extracted', 'case4_relay_intact', 'case4_next_case_signal_trace'}, requisitionDelta: 20, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'destroy_outer_relay', label: 'Уничтожить ретранслятор и подавить сигнал', consequenceText: 'Повторная передача остановлена, но оператор и большая часть исходных журналов потеряны. Угроза немедленной утечки ниже, зато следующую цель придётся искать по обрывочным следам.', nextNodeId: 'ending_case4_relay_destroyed', requiredFlags: <String>{'case4_expedition_completed'}, flagsToAdd: <String>{'case4_relay_destroyed', 'case4_signal_suppressed', 'case4_next_case_fragmentary_trace'}, corruptionDelta: -2, requisitionDelta: 10, tone: StoryChoiceTone.puritan),
      ],
    ),
    StoryNode(
      id: 'ending_case4_operator_captured', chapterId: 'epilogue', chapterTitle: 'Конец дела IV', title: 'Свидетель под печатью',
      location: 'Изолятор крейсера «Безмолвный приговор»',
      briefing: 'Оператор ретранслятора доставлен на крейсер живым и помещён под печать Ордо. Он отказывается называть заказчика, но его имплант содержит ключ, который не мог быть выдан без доступа к закрытому командному реестру. Следующее дело начнётся с допроса и проверки цепи приказов. Свидетель опасен, но его голос может связать внешний узел с теми, кто считал себя недосягаемым.',
      dialogueSpeaker: 'Инквизитор', dialogue: '«Не ломайте его прежде, чем узнаем, кто выдал ему ключ. Правда иногда говорит тише боли — и потому требует терпения».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_case4_data_extracted', chapterId: 'epilogue', chapterTitle: 'Конец дела IV', title: 'След в машинном коде',
      location: 'Лаборатория криптоанализа крейсера',
      briefing: 'Журналы ретранслятора извлечены без разрушения узла. В последовательности передач обнаружена координатная подпись следующего узла, а также временное окно, когда сеть переходит на резервный канал. Оператор исчезает в хаосе эвакуации, но данные дают точный технический след. Следующее дело начнётся с охоты на передатчик, пока противник ещё не понял, что его маршрут раскрыт.',
      dialogueSpeaker: 'Сервочереп «Люмен»', dialogue: '«Пакет проверен на подмену. Координаты согласуются с тремя независимыми временными метками. Рекомендация: немедленно продолжить отслеживание».',
      ending: true,
    ),
    StoryNode(
      id: 'ending_case4_relay_destroyed', chapterId: 'epilogue', chapterTitle: 'Конец дела IV', title: 'Тишина после сигнала',
      location: 'Обломки внешнего ретранслятора «Немезида-9»',
      briefing: 'Ретранслятор уничтожен до повторной передачи. Сигнал оборван, а противник лишён безопасного канала связи. Вместе с узлом погибли оператор и большая часть исходных журналов. На обугленном накопителе остался только фрагмент маршрута, достаточный для приблизительного поиска следующей цели. Ордо одобрило решение как меру сдерживания, но расследование потеряло важнейший источник.',
      dialogueSpeaker: 'Инквизитор', dialogue: '«Мы закрыли канал. Теперь придётся выяснить, кто был на другом конце, не имея возможности спросить его напрямую».',
      ending: true,
    ),
    StoryNode(
      id: 'case_05_dispatch', chapterId: 'case_05', chapterTitle: 'Дело V — Тот, кто отвечает',
      title: 'Три следа, один заказчик', location: 'Крейсер «Безмолвный приговор»',
      briefing: 'Внешний ретранслятор больше не определяет ход расследования — теперь всё зависит от того, что удалось унести с Немезиды-9. Пленный оператор может назвать владельца командного ключа. Извлечённые журналы позволяют вычислить следующий передатчик. Если узел был уничтожен, остаётся только неполный фрагмент маршрута и риск отправить отряд в ловушку.',
      dialogueSpeaker: 'Инквизитор',
      dialogue: '«Мы не будем притворяться, будто все три пути равны. Один даёт нам голос, второй — координаты, третий — лишь направление. Но даже обрывок может привести к правде, если не спутать догадку с доказательством».',
      choices: <StoryChoice>[
        StoryChoice(id: 'case5_follow_interrogation', label: 'Начать с допроса пленного оператора', consequenceText: 'Доступно, если оператор был захвачен живым. Его показания нужно сопоставить с командным реестром.', nextNodeId: 'case_05_interrogation_route', requiredFlags: <String>{'case4_next_case_interrogation'}, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'case5_follow_signal_trace', label: 'Охотиться по координатам из журналов передачи', consequenceText: 'Технический след указывает на передвижной узел связи, который скоро сменит позицию.', nextNodeId: 'case_05_signal_route', requiredFlags: <String>{'case4_next_case_signal_trace'}, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'case5_follow_fragment', label: 'Восстановить маршрут по обломку накопителя', consequenceText: 'Точная цель неизвестна. Придётся проверить несколько вероятных точек и учитывать возможность засады.', nextNodeId: 'case_05_fragment_route', requiredFlags: <String>{'case4_next_case_fragmentary_trace'}, tone: StoryChoiceTone.puritan),
      ],
    ),
    StoryNode(
      id: 'case_05_interrogation_route', chapterId: 'case_05', chapterTitle: 'Дело V — Тот, кто отвечает',
      title: 'Показания под изоляцией', location: 'Изолятор крейсера',
      briefing: 'Оператор утверждает, что командный ключ выдавался через посредника с позывным «Арбитр-Ноль». Он готов подтвердить личность посредника, но только после сверки импланта с реестром. В показаниях есть пробел: последнее подтверждение ключа было сделано уже после официальной смерти его владельца.',
      dialogueSpeaker: 'Пленный оператор',
      dialogue: '«Я никогда не видел заказчика. Я видел только подпись, которую нельзя подделать без доступа к закрытому реестру. Если вы покажете мне запись, я укажу, где её изменили».',
      evidence: <StoryEvidence>[StoryEvidence(id: 'case5_operator_testimony', title: 'Показания оператора', description: 'Оператор называет посредника «Арбитр-Ноль» и указывает на подтверждение ключа после смерти владельца.')],
      choices: <StoryChoice>[StoryChoice(id: 'case5_submit_testimony', label: 'Сверить показания с командным реестром', consequenceText: 'Показания приняты как рабочая зацепка, но требуют проверки независимым источником.', nextNodeId: 'case_05_evidence_review', requiredEvidence: <String>{'case5_operator_testimony'}, flagsToAdd: <String>{'case5_testimony_verified'}, requisitionDelta: 8, tone: StoryChoiceTone.investigative)],
    ),
    StoryNode(
      id: 'case_05_signal_route', chapterId: 'case_05', chapterTitle: 'Дело V — Тот, кто отвечает',
      title: 'Охота по временным меткам', location: 'Лаборатория криптоанализа',
      briefing: 'Журналы передачи указывают не на постоянную станцию, а на мобильный узел, который использует короткие окна связи. Три временные метки совпадают с маршрутами снабжения, но одна из них была добавлена задним числом. Если вычислить исходный пакет, можно перехватить следующий сеанс.',
      dialogueSpeaker: 'Сервочереп «Люмен»',
      dialogue: '«Корреляция маршрута — 81 процент. Одна временная метка имеет признаки ручной вставки. Рекомендация: считать координаты достоверными, но не окончательными».',
      evidence: <StoryEvidence>[StoryEvidence(id: 'case5_signal_coordinates', title: 'Координатная подпись мобильного узла', description: 'Координаты следующего передатчика и временное окно следующего сеанса связи.')],
      choices: <StoryChoice>[StoryChoice(id: 'case5_submit_coordinates', label: 'Подготовить перехват мобильного узла', consequenceText: 'Координаты подтверждены для планирования операции; возможна ложная временная метка.', nextNodeId: 'case_05_evidence_review', requiredEvidence: <String>{'case5_signal_coordinates'}, flagsToAdd: <String>{'case5_coordinates_verified'}, requisitionDelta: 10, tone: StoryChoiceTone.pragmatic)],
    ),
    StoryNode(
      id: 'case_05_fragment_route', chapterId: 'case_05', chapterTitle: 'Дело V — Тот, кто отвечает',
      title: 'Маршрут из пепла', location: 'Мастерская восстановления данных',
      briefing: 'Обугленный накопитель сохранил лишь несколько байтов адреса и часть печати маршрутизации. Аналитики восстановили три возможных района, но только один связан с поставками компонентов для ретранслятора. Ошибка приведёт отряд к пустому объекту или подготовленной засаде.',
      dialogueSpeaker: 'Техножрец-аналитик',
      dialogue: '«Данных недостаточно для уверенного наведения. Мы можем выбрать наиболее вероятный сектор, но это будет оперативная гипотеза, а не установленный факт».',
      evidence: <StoryEvidence>[StoryEvidence(id: 'case5_fragmentary_route', title: 'Неполный маршрутный фрагмент', description: 'Три вероятных района поиска и один совпадающий код поставщика компонентов.')],
      choices: <StoryChoice>[StoryChoice(id: 'case5_submit_fragment', label: 'Утвердить ограниченную поисковую операцию', consequenceText: 'Ордо санкционирует разведку по неполному маршруту с уменьшенным запасом ресурсов.', nextNodeId: 'case_05_evidence_review', requiredEvidence: <String>{'case5_fragmentary_route'}, flagsToAdd: <String>{'case5_fragmentary_search'}, requisitionDelta: 3, tone: StoryChoiceTone.puritan)],
    ),
    StoryNode(
      id: 'case_05_evidence_review', chapterId: 'case_05', chapterTitle: 'Дело V — Тот, кто отвечает',
      title: 'Проверка перед высадкой', location: 'Комната тактического планирования',
      briefing: 'Зацепка внесена в дело. Перед высадкой Инквизитор должен определить, какой уровень риска допустим: использовать подтверждённые показания, перехватить узел по техническим координатам или провести ограниченную разведку по неполному маршруту. Решение фиксируется в хронике и определит подготовку следующей операции.',
      dialogueSpeaker: 'Инквизитор',
      dialogue: '«Сомнение — не слабость. Слабость — забыть, где заканчивается доказательство и начинается предположение. Отметьте степень уверенности, и пусть отряд знает, чем рискует».',
      choices: <StoryChoice>[
        StoryChoice(id: 'case5_authorize_interrogation_lead', label: 'Санкционировать операцию по показаниям оператора', consequenceText: 'Приоритет — поиск «Арбитра-Ноль» и проверка командного реестра.', nextNodeId: 'ending_case5_interrogation', requiredFlags: <String>{'case5_testimony_verified'}, requiredEvidence: <String>{'case5_operator_testimony'}, flagsToAdd: <String>{'case5_operation_interrogation'}, requisitionDelta: 12, tone: StoryChoiceTone.investigative),
        StoryChoice(id: 'case5_authorize_signal_hunt', label: 'Санкционировать перехват мобильного узла', consequenceText: 'Приоритет — быстрое развёртывание на координатах следующего сеанса связи.', nextNodeId: 'ending_case5_signal_hunt', requiredFlags: <String>{'case5_coordinates_verified'}, requiredEvidence: <String>{'case5_signal_coordinates'}, flagsToAdd: <String>{'case5_operation_signal_hunt'}, requisitionDelta: 12, tone: StoryChoiceTone.pragmatic),
        StoryChoice(id: 'case5_authorize_limited_search', label: 'Санкционировать ограниченную поисковую операцию', consequenceText: 'Приоритет — осторожная разведка с запасным маршрутом и ограниченным снабжением.', nextNodeId: 'ending_case5_limited_search', requiredFlags: <String>{'case5_fragmentary_search'}, requiredEvidence: <String>{'case5_fragmentary_route'}, flagsToAdd: <String>{'case5_operation_limited_search'}, requisitionDelta: 5, tone: StoryChoiceTone.puritan),
      ],
    ),
    StoryNode(
      id: 'ending_case5_interrogation', chapterId: 'epilogue', chapterTitle: 'Подготовка к делу VI', title: 'Имя за командным ключом',
      location: 'Тактический мостик крейсера',
      briefing: 'Операция начинается с проверки реестра и поиска «Арбитра-Ноль». Пленный оператор остаётся под охраной, а его показания становятся отправной точкой следующего дела. Команда знает, что ключ подтверждали после смерти владельца: значит, кто-то продолжает использовать имя мертвеца.',
      dialogueSpeaker: 'Инквизитор', dialogue: '«Сначала найдём руку, которая подписывает приказы. Потом решим, сколько голов должно упасть».', ending: true,
    ),
    StoryNode(
      id: 'ending_case5_signal_hunt', chapterId: 'epilogue', chapterTitle: 'Подготовка к делу VI', title: 'Перехват до смены канала',
      location: 'Навигационный мостик крейсера',
      briefing: 'Крейсер берёт курс на мобильный узел. Временное окно коротко, поэтому операция начнётся с перехвата и отключения резервного канала. Технические данные точны настолько, чтобы рискнуть высадкой, но команда готовится к возможной ложной метке.',
      dialogueSpeaker: 'Сервочереп «Люмен»', dialogue: '«Окно связи рассчитано. Если цель сменит позицию, следующее совпадение будет значительно слабее».', ending: true,
    ),
    StoryNode(
      id: 'ending_case5_limited_search', chapterId: 'epilogue', chapterTitle: 'Подготовка к делу VI', title: 'Три точки на пустой карте',
      location: 'Комната тактического планирования',
      briefing: 'Операция санкционирована с ограниченным снабжением. Три района остаются возможными целями, а совпадение кода поставщика даёт лишь слабое преимущество. Отряд отправится по наиболее вероятному маршруту, сохраняя резерв на случай засады.',
      dialogueSpeaker: 'Инквизитор', dialogue: '«Мы идём не потому, что уверены. Мы идём потому, что промедление оставит врагу время стереть остатки следа».', ending: true,
    ),
    // Retained as a valid legacy destination for saves created by Update 12.
    StoryNode(
      id: 'ending_case4_expedition', chapterId: 'epilogue', chapterTitle: 'Конец дела IV', title: 'Курс на внешний ретранслятор',
      location: 'Навигационный мостик крейсера «Безмолвный приговор»',
      briefing: 'Экспедиция получила санкцию Инквизиции. Старое дело остаётся закрытым, но его последствия больше не ограничены Геллион-IX. Внешний ретранслятор молчит, пока крейсер прокладывает курс. Впереди новое расследование, а первый пакет уже внесён в архив как доказательство того, что кто-то продолжает действовать за пределами известной сети.',
      dialogueSpeaker: 'Инквизитор', dialogue: '«Подготовить корабль. На этот раз мы идём не по следу исчезнувших документов, а по следу того, кто их оставил».',
      ending: true,
    ),
  ];

  String currentNodeId = 'prologue_briefing';
  final Set<String> visitedNodes = <String>{};
  final Set<String> collectedEvidence = <String>{};
  final Set<String> flags = <String>{};
  final Map<String, String> decisions = <String, String>{};
  String? endingId;
  String? activeOperationId;
  final Map<String, int> operationAttempts = <String, int>{};
  int operationKills = 0;
  int operationChampions = 0;
  int operationBosses = 0;
  final Set<String> operationFieldObjectives = <String>{};
  int corruptionDelta = 0;
  int requisitionDelta = 0;

  StoryNode get currentNode => nodeById(currentNodeId) ?? nodes.first;
  bool get completed => endingId != null;

  /// Human-readable consequences that persist across later investigation scenes.
  /// The UI uses this to make earlier choices visible rather than silently hidden in flags.
  List<String> get consequenceSummary {
    final result = <String>[];
    if (flags.contains('witness_protected')) {
      result.add('Диакон Вейл жив и защищён: доступен его маршрут и свидетельские показания.');
    } else if (flags.contains('witness_coerced')) {
      result.add('Вейл сотрудничал под давлением: показания получены, но доверие свидетелей подорвано.');
    } else if (flags.contains('deacon_executed')) {
      result.add('Вейл казнён: личные свидетельские показания больше недоступны.');
    } else if (flags.contains('crisis_failed_station_witness')) {
      result.add('Сигнал подавлен: Вейла не удалось защитить во время полевой операции.');
    }
    if (flags.contains('cargo_evidence_preserved')) {
      result.add('Накладная сохранена: можно подтвердить цепочку снабжения перед штурмом архива.');
    } else if (flags.contains('crisis_failed_cargo_evidence') || flags.contains('evidence_suppressed')) {
      result.add('Цепочка снабжения неполна: особый путь полного досье закрыт.');
    }
    if (flags.contains('archive_archivist_rescued')) {
      result.add('Архивариус Кастор спасён: он может подтвердить подлинность документов в трибунале.');
    } else if (flags.contains('crisis_failed_archive_archivist')) {
      result.add('Архивариус не был эвакуирован: его свидетельство недоступно.');
    }
    if (flags.contains('complete_dossier_submitted')) {
      result.add('Полное досье принято Ордо: все три линии доказательств объединены.');
    }
    switch (endingId) {
      case 'ending_sector_restored':
        result.add('Судьба сектора: восстановление гражданского управления и защита свидетелей.');
        break;
      case 'ending_military_occupation':
        result.add('Судьба сектора: чрезвычайное военное управление Ордо.');
        break;
      case 'ending_sector_quarantine':
        result.add('Судьба сектора: бессрочная изоляция под карантинными печатями.');
        break;
    }
    return result;
  }

  /// Tactical support earned from earlier decisions. These effects are derived
  /// from persistent flags, so old saves automatically receive the correct state.
  int get activeOperationSupportRank {
    switch (activeOperationId ?? currentOperation?.id) {
      case 'intercept_cargo':
        return flags.contains('witness_protected') ? 1 : 0;
      case 'breach_archive':
        var rank = 0;
        if (flags.contains('witness_protected')) rank++;
        if (flags.contains('cargo_evidence_preserved')) rank++;
        if (flags.contains('archive_archivist_rescued')) rank++;
        return rank;
      case 'secure_outer_relay':
        if (flags.contains('case4_route_civilian')) return 2;
        if (flags.contains('case4_route_military') || flags.contains('case4_route_quarantine')) return 1;
        return 0;
      default:
        return 0;
    }
  }

  int get activeOperationSupportRequisitionBonus => activeOperationSupportRank * 8;

  /// A compact, derived measure of the sector's condition. It is calculated
  /// from existing campaign flags so old saves need no migration.
  int get sectorStabilityScore {
    var score = 3;
    if (flags.contains('witness_protected')) score += 2;
    if (flags.contains('cargo_evidence_preserved')) score += 2;
    if (flags.contains('archive_archivist_rescued')) score += 2;
    if (flags.contains('curator_exposed')) score += 2;
    if (flags.contains('complete_dossier_submitted')) score += 1;
    if (flags.contains('archive_purged') || flags.contains('station_purged')) score -= 3;
    if (flags.contains('crisis_failed_station_witness')) score -= 1;
    return score.clamp(0, 10).toInt();
  }

  String get sectorStabilityLabel {
    final score = sectorStabilityScore;
    if (score >= 8) return 'Сектор стабилизирован';
    if (score >= 5) return 'Порядок удерживается';
    if (score >= 3) return 'Нестабильность сохраняется';
    return 'Сектор на грани распада';
  }

  List<String> get allyNetworkSummary {
    final allies = <String>[];
    if (flags.contains('witness_protected')) {
      allies.add('Диакон Вейл: свидетельские показания и разведка маршрутов.');
    } else if (flags.contains('witness_coerced')) {
      allies.add('Диакон Вейл: сведения получены, но доверие утрачено.');
    } else if (flags.contains('deacon_executed')) {
      allies.add('Диакон Вейл: погиб; его свидетельские показания недоступны.');
    }
    if (flags.contains('cargo_evidence_preserved')) {
      allies.add('Грузовая сеть: накладная сохранена и может подтвердить цепочку снабжения.');
    }
    if (flags.contains('archive_archivist_rescued')) {
      allies.add('Архивариус Кастор: доступен для подтверждения подлинности документов.');
    }
    if (allies.isEmpty) allies.add('Надёжные союзники и подтверждённые линии доказательств пока не получены.');
    return allies;
  }

  List<String> get activeOperationSupportSummary {
    switch (activeOperationId ?? currentOperation?.id) {
      case 'intercept_cargo':
        if (flags.contains('witness_protected')) {
          return <String>['Поддержка Вейла: маршрут конвоя известен заранее.', 'Тактический эффект: ниже шанс появления элитного противника.', 'Бонус при успехе: +8 реквизиции.'];
        }
        return <String>['Поддержка отсутствует: конвой сохраняет элемент неожиданности.'];
      case 'breach_archive':
        final effects = <String>[];
        if (flags.contains('witness_protected')) effects.add('Вейл передал обходной маршрут: ниже шанс элитного подкрепления.');
        if (flags.contains('cargo_evidence_preserved')) effects.add('Накладная раскрыла снабжение архива: ниже шанс элитного подкрепления.');
        if (flags.contains('archive_archivist_rescued')) effects.add('Архивариус Кастор передал план внутренних переходов: ниже шанс элитного подкрепления.');
        if (effects.isEmpty) return <String>['Нет подтверждённых разведданных о внутренней охране архива.'];
        effects.add('Бонус при успехе: +${activeOperationSupportRequisitionBonus} реквизиции.');
        return effects;
      case 'secure_outer_relay':
        final route = flags.contains('case4_route_civilian')
            ? 'Гражданский маршрут: доступен обходной сервисный шлюз.'
            : flags.contains('case4_route_military')
                ? 'Военный аудит: открыт контрольный журнал, элитное подкрепление менее вероятно.'
                : flags.contains('case4_route_quarantine')
                    ? 'Карантинный зонд: обнаружена изолированная линия питания.'
                    : 'Остаточный сигнал: ограниченная локализация и минимум поддержки.';
        return <String>[route, 'Разведывательный ранг: $activeOperationSupportRank.', 'Бонус при успехе: +${activeOperationSupportRequisitionBonus} реквизиции.'];
      default:
        return <String>[];
    }
  }

  StoryOperation? get currentOperation => operationForNode(currentNodeId);
  bool get operationInProgress => activeOperationId != null;
  bool isOperationCompleted(StoryOperation operation) => flags.contains(operation.successFlag);
  int attemptsFor(StoryOperation operation) => operationAttempts[operation.id] ?? 0;
  bool get activeOperationFieldObjectivesComplete {
    final operation = activeOperation;
    return operation != null && operationFieldObjectives.containsAll(operation.requiredFieldObjectives);
  }

  bool get activeOperationObjectivesComplete {
    final operation = activeOperation;
    if (operation == null) return false;
    return operationKills >= operation.requiredKills &&
        operationChampions >= operation.requiredChampions &&
        operationBosses >= operation.requiredBosses &&
        operationFieldObjectives.containsAll(operation.requiredFieldObjectives);
  }
  StoryOperation? get activeOperation {
    final id = activeOperationId;
    if (id == null) return null;
    for (final operation in operations) { if (operation.id == id) return operation; }
    return null;
  }
  String get activeOperationProgressLabel {
    final operation = activeOperation;
    if (operation == null) return '';
    final parts = <String>[];
    if (operation.requiredKills > 0) parts.add('Уничтожить врагов: ${operationKills.clamp(0, operation.requiredKills)}/${operation.requiredKills}');
    if (operation.requiredChampions > 0) parts.add('Элита: ${operationChampions.clamp(0, operation.requiredChampions)}/${operation.requiredChampions}');
    if (operation.requiredBosses > 0) parts.add('Босс: ${operationBosses.clamp(0, operation.requiredBosses)}/${operation.requiredBosses}');
    if (operation.requiredFieldObjectives.isNotEmpty) {
      parts.add('Объекты: ${operationFieldObjectives.intersection(operation.requiredFieldObjectives).length}/${operation.requiredFieldObjectives.length}');
    }
    return parts.join(' • ');
  }
  /// Records the outcome of an optional timed battlefield crisis. Outcomes are
  /// stored in the existing campaign flags so older save files remain compatible.
  bool resolveCrisisEvent(String eventId, {required bool success}) {
    final expectedOperation = switch (eventId) {
      'station_witness' => 'secure_station',
      'cargo_evidence' => 'intercept_cargo',
      'archive_archivist' => 'breach_archive',
      _ => null,
    };
    if (activeOperation == null || activeOperationId != expectedOperation) return false;
    final successFlag = 'crisis_success_$eventId';
    final failedFlag = 'crisis_failed_$eventId';
    if (flags.contains(successFlag) || flags.contains(failedFlag)) return false;
    flags.add(success ? successFlag : failedFlag);
    if (success && eventId == 'station_witness') flags.add('witness_protected');
    if (success && eventId == 'cargo_evidence') flags.add('cargo_evidence_preserved');
    if (success && eventId == 'archive_archivist') flags.add('archive_archivist_rescued');
    return true;
  }

  bool collectFieldObjective(String objectiveId) {
    final operation = activeOperation;
    if (operation == null || !operation.requiredFieldObjectives.contains(objectiveId)) return false;
    return operationFieldObjectives.add(objectiveId);
  }

  void recordActiveOperationKill({bool isChampion = false, bool isBoss = false}) {
    if (activeOperation == null) return;
    operationKills = (operationKills + 1).clamp(0, 100000).toInt();
    if (isChampion || isBoss) operationChampions = (operationChampions + 1).clamp(0, 100000).toInt();
    if (isBoss) operationBosses = (operationBosses + 1).clamp(0, 100000).toInt();
  }

  static StoryOperation? operationForNode(String nodeId) {
    for (final operation in operations) {
      if (operation.nodeId == nodeId) return operation;
    }
    return null;
  }

  bool beginCurrentOperation() {
    final operation = currentOperation;
    if (completed || operation == null || operationInProgress || isOperationCompleted(operation)) return false;
    activeOperationId = operation.id;
    operationKills = 0; operationChampions = 0; operationBosses = 0; operationFieldObjectives.clear();
    for (final eventId in <String>['station_witness', 'cargo_evidence', 'archive_archivist']) {
      flags.remove('crisis_success_$eventId');
      flags.remove('crisis_failed_$eventId');
    }
    operationAttempts[operation.id] = (operationAttempts[operation.id] ?? 0) + 1;
    return true;
  }

  /// Resolves the active field operation. Returns null when no story operation was active.
  StoryOperation? resolveActiveOperation({required bool success}) {
    final id = activeOperationId;
    if (id == null) return null;
    StoryOperation? operation;
    for (final candidate in operations) {
      if (candidate.id == id) { operation = candidate; break; }
    }
    final objectiveSuccess = success && activeOperationObjectivesComplete;
    activeOperationId = null;
    if (operation != null && objectiveSuccess) {
      flags.add(operation.successFlag);
      flags.remove('operation_failed_${operation.id}');
    }
    if (operation != null && !objectiveSuccess && !flags.contains(operation.successFlag)) flags.add('operation_failed_${operation.id}');
    operationFieldObjectives.clear();
    return operation;
  }

  int get chapterNumber {
    if (currentNode.chapterId == 'case_01') return 1;
    if (currentNode.chapterId == 'case_02') return 2;
    if (currentNode.chapterId == 'case_03') return 3;
    if (currentNode.chapterId == 'case_04') return 4;
    if (currentNode.chapterId == 'case_05') return 5;
    return completed ? 5 : 1;
  }
  double get progress => visitedNodes.length / nodes.length;
  static StoryNode? nodeById(String id) {
    for (final node in nodes) { if (node.id == id) return node; }
    return null;
  }

  bool collectEvidence(String evidenceId) {
    final valid = nodes.any((node) => node.evidence.any((e) => e.id == evidenceId));
    if (!valid || !currentNode.evidence.any((e) => e.id == evidenceId)) return false;
    return collectedEvidence.add(evidenceId);
  }

  List<StoryChoice> get availableChoices => currentNode.choices.where((choice) =>
    flags.containsAll(choice.requiredFlags) &&
    collectedEvidence.containsAll(choice.requiredEvidence) &&
    sectorStabilityScore >= choice.requiredMinSectorStability).toList(growable: false);

  bool choose(String choiceId) {
    if (completed || operationInProgress) return false;
    StoryChoice? selected;
    for (final choice in availableChoices) { if (choice.id == choiceId) { selected = choice; break; } }
    if (selected == null) return false;
    decisions[currentNodeId] = selected.id;
    visitedNodes.add(currentNodeId);
    flags.addAll(selected.flagsToAdd);
    corruptionDelta = (corruptionDelta + selected.corruptionDelta).clamp(-100, 100).toInt();
    requisitionDelta = (requisitionDelta + selected.requisitionDelta).clamp(-500, 500).toInt();
    currentNodeId = selected.nextNodeId;
    if (nodeById(currentNodeId) == null) return false;
    if (currentNode.ending) {
      visitedNodes.add(currentNodeId);
      endingId = currentNodeId;
    }
    return true;
  }

  void restart() {
    currentNodeId = 'prologue_briefing';
    visitedNodes.clear(); collectedEvidence.clear(); flags.clear(); decisions.clear();
    endingId = null; activeOperationId = null; operationAttempts.clear(); operationFieldObjectives.clear(); operationKills = 0; operationChampions = 0; operationBosses = 0; corruptionDelta = 0; requisitionDelta = 0;
  }

  /// Starts the sequel case while preserving the completed first-case record.
  /// The previous ending is stored as a flag so existing save payloads remain compatible.
  bool continueAfterEnding() {
    final previousEnding = endingId;
    if (previousEnding == null || !completed || operationInProgress) return false;
    flags.add('prior_ending_$previousEnding');
    final caseFourEndings = <String>{
      'ending_case4_operator_captured',
      'ending_case4_data_extracted',
      'ending_case4_relay_destroyed',
      'ending_case4_expedition',
    };
    if (caseFourEndings.contains(previousEnding)) {
      // Reconstruct the expected route from the ending itself as a safety net
      // for older or partially migrated saves that lack the corresponding flag.
      switch (previousEnding) {
        case 'ending_case4_operator_captured':
          flags.add('case4_next_case_interrogation');
          break;
        case 'ending_case4_data_extracted':
          flags.add('case4_next_case_signal_trace');
          break;
        case 'ending_case4_relay_destroyed':
        case 'ending_case4_expedition':
          if (!flags.contains('case4_next_case_interrogation') &&
              !flags.contains('case4_next_case_signal_trace') &&
              !flags.contains('case4_next_case_fragmentary_trace')) {
            flags.add('case4_next_case_fragmentary_trace');
          }
          break;
      }
      visitedNodes.add(currentNodeId);
      currentNodeId = 'case_05_dispatch';
    } else {
      if (!<String>{'ending_sector_restored', 'ending_military_occupation', 'ending_sector_quarantine'}.contains(previousEnding)) {
        flags.add('prior_ending_other');
      }
      visitedNodes.add(currentNodeId);
      currentNodeId = 'case_04_dispatch';
    }
    endingId = null;
    activeOperationId = null;
    operationKills = 0;
    operationChampions = 0;
    operationBosses = 0;
    operationFieldObjectives.clear();
    return true;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion, 'currentNodeId': currentNodeId,
    'visitedNodes': visitedNodes.toList(), 'collectedEvidence': collectedEvidence.toList(),
    'flags': flags.toList(), 'decisions': decisions,
    'endingId': endingId, 'activeOperationId': activeOperationId,
    'operationAttempts': operationAttempts,
    'operationKills': operationKills, 'operationChampions': operationChampions, 'operationBosses': operationBosses,
    'operationFieldObjectives': operationFieldObjectives.toList(),
    'corruptionDelta': corruptionDelta, 'requisitionDelta': requisitionDelta,
  };

  void loadJson(dynamic raw) {
    if (raw is! Map) return;
    final current = raw['currentNodeId'];
    currentNodeId = current is String && nodeById(current) != null ? current : 'prologue_briefing';
    visitedNodes..clear()..addAll((raw['visitedNodes'] is List ? raw['visitedNodes'] as List : const <dynamic>[]).whereType<String>().where((id) => nodeById(id) != null));
    final validEvidence = nodes.expand((n) => n.evidence).map((e) => e.id).toSet();
    collectedEvidence..clear()..addAll((raw['collectedEvidence'] is List ? raw['collectedEvidence'] as List : const <dynamic>[]).whereType<String>().where(validEvidence.contains));
    flags..clear()..addAll((raw['flags'] is List ? raw['flags'] as List : const <dynamic>[]).whereType<String>().take(500));
    decisions..clear();
    if (raw['decisions'] is Map) {
      (raw['decisions'] as Map).forEach((key, value) {
        if (key is String && value is String && nodeById(key)?.choices.any((choice) => choice.id == value) == true) decisions[key] = value;
      });
    }
    final ending = raw['endingId'];
    endingId = ending is String && nodeById(ending)?.ending == true ? ending : null;
    final active = raw['activeOperationId'];
    activeOperationId = active is String && operations.any((operation) => operation.id == active) ? active : null;
    operationAttempts.clear();
    operationKills = ((raw['operationKills'] as num?)?.toInt() ?? 0).clamp(0, 100000).toInt();
    operationChampions = ((raw['operationChampions'] as num?)?.toInt() ?? 0).clamp(0, 100000).toInt();
    operationBosses = ((raw['operationBosses'] as num?)?.toInt() ?? 0).clamp(0, 100000).toInt();
    operationFieldObjectives.clear();
    StoryOperation? activeDefinition;
    for (final operation in operations) { if (operation.id == activeOperationId) { activeDefinition = operation; break; } }
    if (activeDefinition != null && raw['operationFieldObjectives'] is List) {
      final validObjectives = activeDefinition.requiredFieldObjectives;
      operationFieldObjectives.addAll((raw['operationFieldObjectives'] as List).whereType<String>().where(validObjectives.contains));
    }
    if (raw['operationAttempts'] is Map) {
      (raw['operationAttempts'] as Map).forEach((key, value) {
        if (key is String && operations.any((operation) => operation.id == key) && value is num) {
          operationAttempts[key] = value.toInt().clamp(0, 10000).toInt();
        }
      });
    }
    // Never retain an operation whose scene no longer matches the saved scene.
    if (activeOperationId != null && operationForNode(currentNodeId)?.id != activeOperationId) { activeOperationId = null; operationKills = 0; operationChampions = 0; operationBosses = 0; operationFieldObjectives.clear(); }
    corruptionDelta = ((raw['corruptionDelta'] as num?)?.toInt() ?? 0).clamp(-100, 100).toInt();
    requisitionDelta = ((raw['requisitionDelta'] as num?)?.toInt() ?? 0).clamp(-500, 500).toInt();
    if (currentNode.ending) endingId ??= currentNodeId;
  }
}
