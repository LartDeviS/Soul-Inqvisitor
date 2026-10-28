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
        StoryChoice(id: 'purge_archive', label: 'Объявить архив заражённым и уничтожить его', consequenceText: 'Сохранит секретность, но правда останется погребённой.', nextNodeId: 'ending_purge', flagsToAdd: <String>{'archive_purged'}, corruptionDelta: -8, requisitionDelta: 20, tone: StoryChoiceTone.puritan),
        StoryChoice(id: 'use_blueprint', label: 'Присвоить схему и использовать её против врагов', consequenceText: 'Откроет радикальный исход при наличии схемы подавителя.', nextNodeId: 'ending_radical', requiredEvidence: <String>{'warp_blueprint'}, flagsToAdd: <String>{'blueprint_taken'}, corruptionDelta: 12, requisitionDelta: 45, tone: StoryChoiceTone.radical),
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
    return completed ? 4 : 1;
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
    flags.containsAll(choice.requiredFlags) && collectedEvidence.containsAll(choice.requiredEvidence)).toList(growable: false);

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
