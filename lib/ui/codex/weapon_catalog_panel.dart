import 'package:flutter/material.dart';
import '../../game/weapons/weapon_data.dart';
import '../../game/weapons/ammo_types.dart';
import '../../game/weapons/weapon_rarity.dart';
import 'procedural_weapon_glyph.dart';

/// Searchable, lore-styled weapon reference. It is a read-only codex and does not
/// mutate the current loadout or the save file.
class WeaponCatalogPanel extends StatefulWidget {
  const WeaponCatalogPanel({super.key});
  @override
  State<WeaponCatalogPanel> createState() => _WeaponCatalogPanelState();
}

class _WeaponCatalogPanelState extends State<WeaponCatalogPanel> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final weapons = WeaponData.all.values.where((w) {
      final q = query.trim().toLowerCase();
      return q.isEmpty || w.nameRu.toLowerCase().contains(q) || w.id.name.toLowerCase().contains(q) || w.damageType.name.toLowerCase().contains(q);
    }).toList()..sort((a, b) => a.nameRu.compareTo(b.nameRu));
    return Card(
      color: const Color(0xFF151719),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('АРСЕНАЛЬНЫЙ СПРАВОЧНИК', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 6),
          TextField(
            onChanged: (v) => setState(() => query = v),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.amber),
              hintText: 'Найти оружие или тип урона…', hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
              isDense: true, filled: true, fillColor: Color(0xFF090A0B), border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          Text('Записей: ${weapons.length} / ${WeaponData.all.length}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ...weapons.map((w) => ExpansionTile(
            tilePadding: EdgeInsets.zero,
            dense: true,
            iconColor: Colors.amber,
            collapsedIconColor: Colors.white54,
            title: Row(children: [ProceduralWeaponGlyph(ordo: w.ordo, damageType: w.damageType, size: 30), const SizedBox(width: 8), Expanded(child: Text(w.nameRu, style: const TextStyle(color: Colors.white, fontSize: 13)))]),
            subtitle: Text('Урон ${w.damage.toStringAsFixed(1)} • ${w.damageType.name} • ${w.cooldown.toStringAsFixed(2)} с${w.ordo == WeaponOrdo.common ? '' : ' • ${w.ordo.name.toUpperCase()}'}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            children: [Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (w.description.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(w.description, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3))),
                _line('Принадлежность', w.ordo.name.toUpperCase()),
                _line('Редкость', WeaponRarityProfile.byId(WeaponRarity.common).nameRu + ' (базовый экземпляр)'),
                _line('Боеприпасы', AmmoProfile.all.values.where((a)=>a.compatibleWith(w.damageType)).map((a)=>a.nameRu).join(', ')),
                _line('Дальность', '${w.range.round()} ед.'),
                _line('Пробитие брони', '${(w.armorPenetration * 100).round()}%'),
                _line('Снарядов за выстрел', '${w.pellets}'),
                _line('Магазин', w.magazine > 0 ? '${w.magazine} ед.' : 'Не применяется / без магазина'),
                _line('Скорость снаряда', '${w.projectileSpeed.round()} ед./с'),
                _line('Особые свойства', [if (w.piercing) 'пробивание', if (w.areaDamage) 'урон по области', if (w.appliesBurn) 'поджигание'].join(', ').ifEmpty('нет')),
              ]),
            )],
          )),
          if (weapons.isEmpty) const Padding(padding: EdgeInsets.all(10), child: Text('Совпадений нет.', style: TextStyle(color: Colors.white54))),
        ]),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))), Text(value, style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 11))]),
  );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
