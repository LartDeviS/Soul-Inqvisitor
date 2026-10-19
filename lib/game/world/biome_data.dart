enum BiomeId { manufactorum, hive, shrine, deathWorld, warpRuin, voidship, necronTomb }
class BiomeData { final BiomeId id; final String title,description; final double hazard,lootMultiplier,enemySpeed; final List<String> props; const BiomeData(this.id,this.title,this.description,{this.hazard=1, this.lootMultiplier=1,this.enemySpeed=1,this.props=const[]}); static const all=<BiomeId,BiomeData>{
BiomeId.manufactorum:BiomeData(BiomeId.manufactorum,'Промышленный мир','Раскалённые печи, конвейеры и токсичные выбросы',hazard:1.08,lootMultiplier:1.15,props:['печь','конвейер','бочка']),
BiomeId.hive:BiomeData(BiomeId.hive,'Улей','Тесные коридоры, ржавчина и культовые тайники',hazard:1.0,lootMultiplier:1.05,props:['баррикада','труба','тайник']),
BiomeId.shrine:BiomeData(BiomeId.shrine,'Храмовый комплекс','Священные реликварии и опасные ловушки',hazard:.94,lootMultiplier:1.2,props:['алтарь','свечи','реликварий']),
BiomeId.deathWorld:BiomeData(BiomeId.deathWorld,'Мир смерти','Агрессивная среда и быстрые хищники',hazard:1.2,enemySpeed:1.14,props:['корни','гнездо','споры']),
BiomeId.warpRuin:BiomeData(BiomeId.warpRuin,'Варп-разлом','Нестабильная реальность и варп-эхо',hazard:1.25,lootMultiplier:1.25,props:['разлом','обелиск','руны']),
BiomeId.voidship:BiomeData(BiomeId.voidship,'Заброшенный корабль','Разгерметизация и узкие палубы',hazard:1.12,props:['люк','кабель','аварийный терминал']),
BiomeId.necronTomb:BiomeData(BiomeId.necronTomb,'Гробница некронов','Гаусс-ловушки и древние механизмы',hazard:1.18,lootMultiplier:1.3,props:['саркофаг','обелиск','плита'])}; }
