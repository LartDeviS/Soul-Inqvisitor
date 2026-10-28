# Build fix — Soul of the Inquisitor Update 23

## Причина
GitHub Actions остановил сборку Flutter на этапе компиляции `lib/main.dart`. В методе `_startTelegraph()` классов `KnightBoss` и `BloodChampionBoss` использовались `_storyProfile` и `_storyAttackIndex`, которые не объявлены в этих классах.

## Исправление
В обоих классах восстановлен локальный случайный выбор режима атаки:
`Random().nextInt(phase == 1 ? 3 : phase == 2 ? 4 : 5)`

Сюжетная профильная последовательность атак в общем классе `Boss` сохранена без изменений.

## Проверки
- В `KnightBoss` больше нет ссылок на `_storyProfile` / `_storyAttackIndex`.
- В `BloodChampionBoss` больше нет ссылок на `_storyProfile` / `_storyAttackIndex`.
- В общем классе `Boss` профильная последовательность сохранена.
- ZIP-архив проверен на целостность.

## Ограничение
В этой среде Flutter/Dart SDK недоступны, поэтому `flutter analyze`, `flutter test` и фактическая сборка APK не запускались. Финальная проверка компиляции должна пройти через GitHub Actions.
