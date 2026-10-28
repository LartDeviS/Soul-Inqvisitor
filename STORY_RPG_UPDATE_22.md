# Soul of the Inquisitor — Update 22

## Дело XII: Раскол Ордо

Update 22 продолжает кампанию из Update 21. Финал Дела XI определяет одну из трёх отдельных операций:

- `ending_case11_counterproof` → `case_12_tribunal_conspiracy`: изъять список скрытых покровителей в трибунальном комплексе.
- `ending_case11_cells_sealed` → `case_12_purge_allies`: перехватить эвакуационный канал военного перевалочного узла.
- `ending_case11_network_bound` → `case_12_inquisitorial_control`: изъять журнал ручного контроля автономного командного узла.

Каждая операция требует выполнения полевой цели, указанного количества обычных ликвидаций и победы над боссом перед выбором эпилога. Введены три новых профиля босса и три новых финальных сюжетных узла. Формат сохранения не менялся; исходные окончания Дела XI используются для маршрутизации старых сохранений.

## Изменённые файлы

- `lib/game/missions/story_campaign.dart`
- `lib/game/missions/story_boss_profiles.dart`
- `lib/main.dart`
- `test/story_boss_profiles_test.dart`
- `test/story_campaign_case12_test.dart` (новый)
- `STORY_RPG_UPDATE_22.md` (новый)

## Проверки

Статическая проверка исходников и целостности ZIP выполняется при подготовке архива. В среде подготовки нет Flutter/Dart SDK, поэтому `flutter analyze`, `flutter test` и сборка APK не запускались. Финальную компиляцию следует выполнить через GitHub Actions.
