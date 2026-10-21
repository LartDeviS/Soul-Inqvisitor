import 'package:flutter/material.dart';
import '../../game/weapons/weapon_data.dart';

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
            leading: SizedBox(width: 42, height: 30, child: CustomPaint(painter: _WeaponGlyphPainter(w.id.name))),
            dense: true,
            iconColor: Colors.amber,
            collapsedIconColor: Colors.white54,
            title: Text(w.nameRu, style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text('Урон ${w.damage.toStringAsFixed(1)} • ${w.damageType.name} • ${w.cooldown.toStringAsFixed(2)} с', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            children: [Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _line('Принадлежность', _ordoFor(w.id.name)),
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

  String _ordoFor(String id) {
    if ({'psycannon','incinerator','daemonHammer'}.contains(id)) return 'Ordo Malleus • против демонов / Варпа';
    if ({'condemnorBoltgun','stakeCrossbow','infernoPistol'}.contains(id)) return 'Ordo Hereticus • охота на ведьм / культы';
    if ({'bolter','rifle','shotgun','plasmaGun','heavyBolter'}.contains(id)) return 'Универсальный / Ordo Xenos';
    return 'Общий арсенал Инквизиции';
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))), Text(value, style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 11))]),
  );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}


/// Procedural, resolution-independent weapon glyphs: no downloaded textures required.
class _WeaponGlyphPainter extends CustomPainter {
  final String id;
  _WeaponGlyphPainter(this.id);
  @override
  void paint(Canvas canvas, Size size) {
    final malleus = {'psycannon','incinerator','daemonHammer'}.contains(id);
    final hereticus = {'condemnorBoltgun','stakeCrossbow','infernoPistol'}.contains(id);
    final color = malleus ? const Color(0xFF8E75D5) : hereticus ? const Color(0xFFB84D42) : const Color(0xFFC7AD68);
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    final y = size.height * .5;
    canvas.drawLine(Offset(3, y), Offset(size.width - 7, y), p);
    canvas.drawLine(Offset(size.width * .35, y - 5), Offset(size.width * .35, y + 5), p);
    canvas.drawLine(Offset(size.width * .58, y - 3), Offset(size.width * .58, y + 3), p);
    canvas.drawLine(Offset(size.width - 7, y), Offset(size.width - 12, y - 4), p);
    canvas.drawLine(Offset(size.width - 7, y), Offset(size.width - 12, y + 4), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, y - 3, size.width * .26, 6), const Radius.circular(1)), p);
    if (malleus) {
      canvas.drawCircle(Offset(size.width * .48, y), 4, p);
      canvas.drawLine(Offset(size.width * .48, y - 7), Offset(size.width * .48, y + 7), p);
    } else if (hereticus) {
      canvas.drawLine(Offset(size.width * .42, y - 7), Offset(size.width * .42, y + 7), p);
      canvas.drawLine(Offset(size.width * .42 - 3, y - 5), Offset(size.width * .42 + 3, y - 5), p);
    }
  }
  @override
  bool shouldRepaint(covariant _WeaponGlyphPainter oldDelegate) => oldDelegate.id != id;
}
