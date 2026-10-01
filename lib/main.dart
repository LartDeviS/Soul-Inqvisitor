import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: InquisitorGame(),
        overlayBuilderMap: {
          'mainMenu': (c, g) => MainMenu(g as InquisitorGame),
          'nameInput': (c, g) => NameInputMenu(g as InquisitorGame),
          'settings': (c, g) => SettingsMenu(g as InquisitorGame),
          'gameOver': (c, g) => GameOverMenu(g as InquisitorGame),
          'levelComplete': (c, g) => LevelCompleteMenu(g as InquisitorGame),
          'upgrade': (c, g) => UpgradeMenu(g as InquisitorGame),
          'victory': (c, g) => VictoryMenu(g as InquisitorGame),
          'records': (c, g) => RecordsMenu(g as InquisitorGame),
          'backpack': (c, g) => BackpackMenu(g as InquisitorGame),
          'loadSave': (c, g) => LoadSaveMenu(g as InquisitorGame),
        },
        initialActiveOverlays: const ['mainMenu'],
      ),
    ),
  );
}

enum RangedWeapon { bolter, rifle, shotgun }
enum MeleeWeapon { sword, axe, hammer }
enum EnemyType { shooter, melee, shielded, dog, shieldedShooter }

class HighScoreEntry {
  final String name;
  final int score;
  final int seconds;
  final int floor;
  final int level;
  final bool completed;
  HighScoreEntry(this.name, this.score, this.seconds, {this.floor = 1, this.level = 1, this.completed = false});
  String get timeStr {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  String get progressStr => completed ? 'ВСЁ ПРОЙДЕНО' : 'Этаж $floor / Ур. $level';
  Map<String, dynamic> toJson() => {
        'name': name, 'score': score, 'seconds': seconds,
        'floor': floor, 'level': level, 'completed': completed,
      };
  factory HighScoreEntry.fromJson(Map<String, dynamic> j) => HighScoreEntry(
        j['name'] as String? ?? '?',
        j['score'] as int? ?? 0,
        j['seconds'] as int? ?? 0,
        floor: j['floor'] as int? ?? 1,
        level: j['level'] as int? ?? 1,
        completed: j['completed'] as bool? ?? false,
      );
}

class GameSave {
  final String name;
  final int floor, level, score, health, maxHealth;
  final int bolterDamage, rifleDamage, shotgunDamage, swordDamage, axeDamage, hammerDamage;
  final double playerSpeed, defenseChance;
  final String ranged, melee;
  final bool usingMelee, hasDash, ever11, ever21;
  final int playSeconds;
  final String dateIso;
  GameSave({
    required this.name, required this.floor, required this.level, required this.score,
    required this.health, required this.maxHealth,
    required this.bolterDamage, required this.rifleDamage, required this.shotgunDamage,
    required this.swordDamage, required this.axeDamage, required this.hammerDamage,
    required this.playerSpeed, required this.defenseChance,
    required this.ranged, required this.melee, required this.usingMelee,
    required this.hasDash, required this.ever11, required this.ever21,
    required this.playSeconds, required this.dateIso,
  });
  Map<String, dynamic> toJson() => {
        'name': name, 'floor': floor, 'level': level, 'score': score,
        'health': health, 'maxHealth': maxHealth,
        'bolterDamage': bolterDamage, 'rifleDamage': rifleDamage, 'shotgunDamage': shotgunDamage,
        'swordDamage': swordDamage, 'axeDamage': axeDamage, 'hammerDamage': hammerDamage,
        'playerSpeed': playerSpeed, 'defenseChance': defenseChance,
        'ranged': ranged, 'melee': melee, 'usingMelee': usingMelee,
        'hasDash': hasDash, 'ever11': ever11, 'ever21': ever21,
        'playSeconds': playSeconds, 'dateIso': dateIso,
      };
  factory GameSave.fromJson(Map<String, dynamic> j) => GameSave(
        name: j['name'] as String? ?? 'Inquisitor',
        floor: j['floor'] as int? ?? 1,
        level: j['level'] as int? ?? 1,
        score: j['score'] as int? ?? 0,
        health: j['health'] as int? ?? 6,
        maxHealth: j['maxHealth'] as int? ?? 6,
        bolterDamage: j['bolterDamage'] as int? ?? 8,
        rifleDamage: j['rifleDamage'] as int? ?? 18,
        shotgunDamage: j['shotgunDamage'] as int? ?? 10,
        swordDamage: j['swordDamage'] as int? ?? 12,
        axeDamage: j['axeDamage'] as int? ?? 14,
        hammerDamage: j['hammerDamage'] as int? ?? 28,
        playerSpeed: (j['playerSpeed'] as num?)?.toDouble() ?? 210,
        defenseChance: (j['defenseChance'] as num?)?.toDouble() ?? 0,
        ranged: j['ranged'] as String? ?? 'bolter',
        melee: j['melee'] as String? ?? 'sword',
        usingMelee: j['usingMelee'] as bool? ?? false,
        hasDash: j['hasDash'] as bool? ?? false,
        ever11: j['ever11'] as bool? ?? false,
        ever21: j['ever21'] as bool? ?? false,
        playSeconds: j['playSeconds'] as int? ?? 0,
        dateIso: j['dateIso'] as String? ?? '',
      );
  String get dateStr {
    try {
      final d = DateTime.parse(dateIso);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateIso;
    }
  }
}

class WHDraw {
  static void inquisitor(Canvas c, {required double cx, required double cy, double s = 1.2, bool cape = true}) {
    if (cape) {
      final capePath = Path()
        ..moveTo(cx - 18 * s, cy + 2 * s)
        ..quadraticBezierTo(cx - 40 * s, cy + 30 * s, cx - 12 * s, cy + 48 * s)
        ..lineTo(cx + 12 * s, cy + 48 * s)
        ..quadraticBezierTo(cx + 40 * s, cy + 30 * s, cx + 18 * s, cy + 2 * s)
        ..close();
      c.drawPath(capePath, Paint()..color = const Color(0xFF8B0000));
      c.drawLine(Offset(cx - 10 * s, cy + 20 * s), Offset(cx - 14 * s, cy + 42 * s), Paint()..color = const Color(0xFFB8860B).withOpacity(0.7)..strokeWidth = 2 * s);
      c.drawLine(Offset(cx + 10 * s, cy + 20 * s), Offset(cx + 14 * s, cy + 42 * s), Paint()..color = const Color(0xFFB8860B).withOpacity(0.7)..strokeWidth = 2 * s);
    }
    const armor = Color(0xFF3A4A55);
    const dark = Color(0xFF1E2830);
    const gold = Color(0xFFC9A227);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 9 * s, cy + 28 * s), width: 12 * s, height: 22 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 9 * s, cy + 28 * s), width: 12 * s, height: 22 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 9 * s, cy + 38 * s), width: 14 * s, height: 7 * s), Radius.circular(1 * s)), Paint()..color = dark);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 9 * s, cy + 38 * s), width: 14 * s, height: 7 * s), Radius.circular(1 * s)), Paint()..color = dark);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 32 * s, height: 30 * s), Radius.circular(4 * s)), Paint()..color = armor);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 18 * s, height: 16 * s), Radius.circular(3 * s)), Paint()..color = dark);
    c.drawCircle(Offset(cx, cy + 4 * s), 5 * s, Paint()..color = gold);
    c.drawCircle(Offset(cx, cy + 4 * s), 2.5 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx - 18 * s, cy - 4 * s), 11 * s, Paint()..color = armor);
    c.drawCircle(Offset(cx + 18 * s, cy - 4 * s), 11 * s, Paint()..color = armor);
    c.drawCircle(Offset(cx - 18 * s, cy - 4 * s), 5 * s, Paint()..color = gold.withOpacity(0.5));
    c.drawCircle(Offset(cx + 18 * s, cy - 4 * s), 5 * s, Paint()..color = gold.withOpacity(0.5));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 22 * s, cy + 12 * s), width: 9 * s, height: 18 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 22 * s, cy + 12 * s), width: 9 * s, height: 18 * s), Radius.circular(2 * s)), Paint()..color = armor);
    c.drawCircle(Offset(cx, cy - 18 * s), 11 * s, Paint()..color = const Color(0xFFC4A484));
    c.drawCircle(Offset(cx - 3.5 * s, cy - 19 * s), 1.8 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx + 3.5 * s, cy - 19 * s), 1.8 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 8 * s), width: 20 * s, height: 6 * s), Radius.circular(2 * s)), Paint()..color = dark);
  }

  static void bolter(Canvas c, double cx, double cy, double s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy + 2 * s, 10 * s, 16 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF8D6E63));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy + 14 * s, 8 * s, 12 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF6D4C41));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 10 * s, cy - 10 * s, 28 * s, 16 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFFC62828));
    c.drawCircle(Offset(cx + 28 * s, cy - 2 * s), 5 * s, Paint()..color = const Color(0xFFFFF8E1));
    c.drawCircle(Offset(cx + 28 * s, cy - 2 * s), 2.2 * s, Paint()..color = const Color(0xFF37474F));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 36 * s, cy - 6 * s, 18 * s, 8 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF546E7A));
    c.drawRect(Rect.fromLTWH(cx + 52 * s, cy - 4 * s, 8 * s, 4 * s), Paint()..color = const Color(0xFF37474F));
  }

  static void rifle(Canvas c, double cx, double cy, double s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 8 * s, cy - 4 * s, 16 * s, 12 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF6D4C41));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 6 * s, 36 * s, 12 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFFA1887F));
    for (int i = 0; i < 4; i++) {
      c.drawCircle(Offset(cx + 28 * s + i * 5 * s, cy), 4 * s, Paint()..color = const Color(0xFF00E5FF).withOpacity(0.85));
    }
    c.drawRect(Rect.fromLTWH(cx + 46 * s, cy - 3 * s, 22 * s, 6 * s), Paint()..color = const Color(0xFF78909C));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 14 * s, cy + 6 * s, 8 * s, 14 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF5D4037));
  }

  static void shotgun(Canvas c, double cx, double cy, double s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 4 * s, cy - 4 * s, 18 * s, 14 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF6D4C41));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 12 * s, cy - 6 * s, 28 * s, 12 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF546E7A));
    c.drawRect(Rect.fromLTWH(cx + 38 * s, cy - 3 * s, 20 * s, 6 * s), Paint()..color = const Color(0xFF37474F));
  }

  static void powerSword(Canvas c, double cx, double cy, double s) {
    final blade = Path()
      ..moveTo(cx + 14 * s, cy - 2 * s)
      ..lineTo(cx + 18 * s, cy - 36 * s)
      ..lineTo(cx + 22 * s, cy - 2 * s)
      ..close();
    c.drawPath(blade, Paint()..color = const Color(0xFF4DD0E1));
    c.drawRect(Rect.fromCenter(center: Offset(cx + 14 * s, cy), width: 18 * s, height: 5 * s), Paint()..color = const Color(0xFFB8860B));
    c.drawCircle(Offset(cx + 14 * s, cy), 5 * s, Paint()..color = const Color(0xFFECEFF1));
    c.drawCircle(Offset(cx + 12.5 * s, cy - 1 * s), 1.2 * s, Paint()..color = const Color(0xFF212121));
    c.drawCircle(Offset(cx + 15.5 * s, cy - 1 * s), 1.2 * s, Paint()..color = const Color(0xFF212121));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 4 * s, cy - 2 * s, 10 * s, 6 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF8B0000));
  }

  static void chainAxe(Canvas c, double cx, double cy, double s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 6 * s, cy - 3 * s, 28 * s, 6 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF8D4E3A));
    final head = Offset(cx + 38 * s, cy);
    final top = Path()
      ..moveTo(head.dx, head.dy - 4 * s)
      ..lineTo(head.dx + 8 * s, head.dy - 22 * s)
      ..lineTo(head.dx + 18 * s, head.dy - 8 * s)
      ..lineTo(head.dx + 10 * s, head.dy)
      ..close();
    final bot = Path()
      ..moveTo(head.dx, head.dy + 4 * s)
      ..lineTo(head.dx + 8 * s, head.dy + 22 * s)
      ..lineTo(head.dx + 18 * s, head.dy + 8 * s)
      ..lineTo(head.dx + 10 * s, head.dy)
      ..close();
    c.drawPath(top, Paint()..color = const Color(0xFF78909C));
    c.drawPath(bot, Paint()..color = const Color(0xFF78909C));
    c.drawCircle(head, 6 * s, Paint()..color = const Color(0xFF546E7A));
    c.drawCircle(head, 3.5 * s, Paint()..color = const Color(0xFFE53935));
  }

  static void thunderHammer(Canvas c, double cx, double cy, double s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy - 2 * s, 36 * s, 5 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF3E2723));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 50 * s, cy), width: 18 * s, height: 22 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF455A64));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 50 * s, cy), width: 12 * s, height: 14 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFFB8860B));
    c.drawCircle(Offset(cx + 50 * s, cy), 4 * s, Paint()..color = const Color(0xFF37474F));
    c.drawCircle(Offset(cx + 50 * s, cy), 2 * s, Paint()..color = const Color(0xFFFFD700));
  }

  static void chaosHound(Canvas c, double cx, double cy) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy + 2), width: 48, height: 26), Paint()..color = const Color(0xFF2D1F14));
    c.drawOval(Rect.fromCenter(center: Offset(cx - 6, cy), width: 20, height: 14), Paint()..color = const Color(0xFF5D1A1A).withOpacity(0.7));
    for (int i = 0; i < 4; i++) {
      c.drawLine(Offset(cx - 4.0 + i * 6, cy - 6), Offset(cx - 2.0 + i * 6, cy + 4), Paint()..color = const Color(0xFFD7CCC8)..strokeWidth = 1.8);
    }
    c.drawOval(Rect.fromCenter(center: Offset(cx + 20, cy - 6), width: 26, height: 20), Paint()..color = const Color(0xFF3E2723));
    final jaw = Path()..moveTo(cx + 28, cy - 2)..lineTo(cx + 38, cy + 6)..lineTo(cx + 26, cy + 8)..close();
    c.drawPath(jaw, Paint()..color = const Color(0xFF4A1C1C));
    for (final fx in [30.0, 34.0, 37.0]) {
      c.drawLine(Offset(cx + fx, cy), Offset(cx + fx + 1, cy + 7), Paint()..color = const Color(0xFFECEFF1)..strokeWidth = 1.6..strokeCap = StrokeCap.round);
    }
    c.drawCircle(Offset(cx + 24, cy - 10), 3.5, Paint()..color = const Color(0xFFFFFDE7));
    c.drawCircle(Offset(cx + 24, cy - 10), 1.5, Paint()..color = const Color(0xFF212121));
    for (final lx in [-16.0, -6.0, 6.0, 16.0]) {
      c.drawLine(Offset(cx + lx, cy + 12), Offset(cx + lx - 3, cy + 24), Paint()..color = const Color(0xFF4E342E)..strokeWidth = 3.5..strokeCap = StrokeCap.round);
      c.drawCircle(Offset(cx + lx - 3, cy + 25), 3, Paint()..color = const Color(0xFFB71C1C));
    }
  }

  static void shieldedMarine(Canvas c, double cx, double cy, double s, {Color accent = const Color(0xFF2979FF)}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 8 * s, cy + 26 * s), width: 11 * s, height: 20 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF212121));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 8 * s, cy + 26 * s), width: 11 * s, height: 20 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF212121));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * s), width: 30 * s, height: 28 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF2A2A2A));
    c.drawCircle(Offset(cx - 16 * s, cy - 4 * s), 10 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx + 16 * s, cy - 4 * s), 10 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 16 * s), 11 * s, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx - 3.5 * s, cy - 16 * s), 2.5 * s, Paint()..color = const Color(0xFFFF1744));
    c.drawCircle(Offset(cx + 3.5 * s, cy - 16 * s), 2.5 * s, Paint()..color = const Color(0xFFFF1744));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 4 * s, cy + 6 * s), width: 36 * s, height: 48 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF37474F));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 4 * s, cy + 6 * s), width: 30 * s, height: 42 * s), Radius.circular(2 * s)), Paint()..color = const Color(0xFF263238));
  }

  static void cultistShooter(Canvas c, double cx, double cy, double s) {
    final cloak = Path()
      ..moveTo(cx - 14 * s, cy)
      ..quadraticBezierTo(cx - 28 * s, cy + 24 * s, cx - 8 * s, cy + 40 * s)
      ..lineTo(cx + 8 * s, cy + 40 * s)
      ..quadraticBezierTo(cx + 22 * s, cy + 20 * s, cx + 10 * s, cy)
      ..close();
    c.drawPath(cloak, Paint()..color = const Color(0xFF5D4037).withOpacity(0.9));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 22 * s, height: 24 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF4E342E));
    c.drawCircle(Offset(cx, cy - 12 * s), 10 * s, Paint()..color = const Color(0xFF37474F));
    c.drawCircle(Offset(cx - 3 * s, cy - 13 * s), 3 * s, Paint()..color = const Color(0xFF1B5E20));
    c.drawCircle(Offset(cx + 3 * s, cy - 13 * s), 3 * s, Paint()..color = const Color(0xFF1B5E20));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8 * s, cy + 2 * s, 26 * s, 7 * s), Radius.circular(1 * s)), Paint()..color = const Color(0xFF455A64));
  }

  static void cultistMelee(Canvas c, double cx, double cy, double s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 12 * s), width: 28 * s, height: 36 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF6B1B1B));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 26 * s, height: 22 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF5D4037));
    c.drawCircle(Offset(cx, cy - 16 * s), 10 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx - 3 * s, cy - 16 * s), 1.8 * s, Paint()..color = const Color(0xFFFF1744));
    c.drawCircle(Offset(cx + 3 * s, cy - 16 * s), 1.8 * s, Paint()..color = const Color(0xFFFF1744));
    for (int i = 0; i < 3; i++) {
      final ox = (i - 1) * 8.0 * s;
      c.drawCircle(Offset(cx + ox, cy - 28 * s), 5 * s, Paint()..color = const Color(0xFFECEFF1));
    }
    c.drawLine(Offset(cx + 14 * s, cy + 2 * s), Offset(cx + 28 * s, cy - 16 * s), Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 3 * s);
  }

  static void hereticBoss(Canvas c, double cx, double cy, double s) {
    c.drawCircle(Offset(cx, cy - 8 * s), 36 * s, Paint()..color = const Color(0xFF4A0000).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * pi - pi / 2;
      final x = cx + cos(a) * 36 * s;
      final y = cy - 8 * s + sin(a) * 36 * s;
      c.drawCircle(Offset(x + cos(a) * 12 * s, y + sin(a) * 12 * s), 4 * s, Paint()..color = const Color(0xFFECEFF1));
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 16 * s), width: 28 * s, height: 40 * s), Radius.circular(4 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy - 14 * s), 11 * s, Paint()..color = const Color(0xFFC4A484));
    c.drawCircle(Offset(cx - 3.5 * s, cy - 14 * s), 2.5 * s, Paint()..color = const Color(0xFFFF1744));
    c.drawCircle(Offset(cx + 3.5 * s, cy - 14 * s), 2.5 * s, Paint()..color = const Color(0xFFFF1744));
  }

  static void knightBoss(Canvas c, double cx, double cy, double s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 12 * s, cy + 32 * s), width: 16 * s, height: 26 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF2A2A2A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 12 * s, cy + 32 * s), width: 16 * s, height: 26 * s), Radius.circular(3 * s)), Paint()..color = const Color(0xFF2A2A2A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 40 * s, height: 34 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(cx, cy), 8 * s, Paint()..color = const Color(0xFFB71C1C));
    c.drawCircle(Offset(cx - 22 * s, cy - 8 * s), 14 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx + 22 * s, cy - 8 * s), 14 * s, Paint()..color = const Color(0xFF3E2723));
    c.drawCircle(Offset(cx, cy - 22 * s), 12 * s, Paint()..color = const Color(0xFF212121));
    c.drawCircle(Offset(cx - 3 * s, cy - 22 * s), 2.5 * s, Paint()..color = const Color(0xFFFF6D00));
    c.drawCircle(Offset(cx + 3 * s, cy - 22 * s), 2.5 * s, Paint()..color = const Color(0xFFFF6D00));
    powerSword(c, cx + 8 * s, cy + 4 * s, s * 0.95);
  }

  static void kingBossDraw(Canvas c, double cx, double cy, double s) {
    final cape = Path()
      ..moveTo(cx - 20 * s, cy)
      ..quadraticBezierTo(cx - 45 * s, cy + 35 * s, cx - 10 * s, cy + 52 * s)
      ..lineTo(cx + 10 * s, cy + 52 * s)
      ..quadraticBezierTo(cx + 30 * s, cy + 30 * s, cx + 16 * s, cy)
      ..close();
    c.drawPath(cape, Paint()..color = const Color(0xFF4A148C).withOpacity(0.85));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 44 * s, height: 36 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFF1A1A1A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 44 * s, height: 36 * s), Radius.circular(5 * s)), Paint()..color = const Color(0xFFC9A227)..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 4 * s), 5 * s, Paint()..color = const Color(0xFFFF1744));
    c.drawCircle(Offset(cx - 24 * s, cy - 6 * s), 14 * s, Paint()..color = const Color(0xFF2A2A2A));
    c.drawCircle(Offset(cx + 24 * s, cy - 6 * s), 14 * s, Paint()..color = const Color(0xFF2A2A2A));
    c.drawCircle(Offset(cx, cy - 22 * s), 11 * s, Paint()..color = const Color(0xFFC4A484));
    thunderHammer(c, cx + 6 * s, cy + 4 * s, s * 0.85);
  }
}

class InquisitorGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent moveJoystick;
  late JoystickComponent attackJoystick;
  late HudButtonComponent switchWeaponButton;
  late HudButtonComponent settingsButton;
  late HudButtonComponent backpackButton;
  late HudButtonComponent zoomInButton;
  late HudButtonComponent zoomOutButton;
  HudButtonComponent? portalButton;
  HudButtonComponent? dashButton;

  int score = 0;
  bool isPlaying = false;
  bool isPaused = false;
  String playerName = 'Inquisitor';
  DateTime? playStartTime;
  int playSeconds = 0;
  int _savedPlaySeconds = 0;

  int currentFloor = 1;
  int currentLevel = 1;
  int enemiesAlive = 0;
  int enemiesToSpawn = 0;
  int enemiesSpawned = 0;

  bool portalSpawned = false;
  bool isBossLevel = false;
  bool isMiniBossLevel = false;
  bool nearPortal = false;

  double spawnTimer = 0;
  double spawnInterval = 1.2;

  int bolterDamage = 8;
  int rifleDamage = 18;
  int shotgunDamage = 10;
  int swordDamage = 12;
  int axeDamage = 14;
  int hammerDamage = 28;
  int maxHealth = 6;
  double playerSpeed = 210;
  double defenseChance = 0.0;

  RangedWeapon rangedWeapon = RangedWeapon.bolter;
  MeleeWeapon meleeWeapon = MeleeWeapon.sword;
  bool usingMelee = false;

  double joystickSize = 80;
  double buttonSize = 42;
  double currentZoom = 0.85;

  bool soundEnabled = true;
  bool musicEnabled = true;
  double soundVolume = 0.8;
  double musicVolume = 0.45;

  List<HighScoreEntry> highScores = [];
  List<GameSave> saves = [];

  final double mapWidth = 1200;
  final double mapHeight = 2000;
  final double cellSize = 60;
  double get safeRadius => cellSize * 5.5;
  Vector2 get playerSpawnPos => Vector2(mapWidth / 2, mapHeight / 2 + 360);

  bool secretBossUnlockedThisLevel = false;
  bool secretBossSpawned = false;
  bool secretBossDefeated = false;
  double cornerStandTimer = 0;
  bool hasDashAbility = false;
  double dashCooldown = 0;
  double dashActive = 0;
  bool _everReached11 = false;
  bool _everReached21 = false;

  // AUDIO: BGM never shares player with SFX
  AudioPlayer? _bgmPlayer;
  final List<AudioPlayer> _sfxPool = [];
  static const int _sfxPoolSize = 6;
  int _sfxIdx = 0;

  final TextPaint hudPaint = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
  );

  int get overallLevel => (currentFloor - 1) * 5 + currentLevel;
  bool get unlockedRifle => overallLevel >= 11 || _everReached11;
  bool get unlockedShotgun => overallLevel >= 21 || _everReached21;
  bool get unlockedAxe => overallLevel >= 11 || _everReached11;
  bool get unlockedHammer => overallLevel >= 21 || _everReached21;

  void _checkUnlocks() {
    if (overallLevel >= 11) _everReached11 = true;
    if (overallLevel >= 21) _everReached21 = true;
  }

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2(mapWidth, mapHeight);
    camera.viewfinder.zoom = currentZoom;
    await initAudio();
    await loadPersistedData();
  }

  Future<void> initAudio() async {
    for (int i = 0; i < _sfxPoolSize; i++) {
      _sfxPool.add(AudioPlayer());
    }
  }

  Future<void> _playSfx(String file) async {
    if (!soundEnabled) return;
    try {
      final p = _sfxPool[_sfxIdx % _sfxPoolSize];
      _sfxIdx++;
      await p.stop();
      await p.setVolume(soundVolume);
      await p.play(AssetSource('sounds/$file'));
    } catch (_) {
      try {
        final p = AudioPlayer();
        await p.setVolume(soundVolume);
        await p.play(AssetSource('sounds/$file'));
      } catch (_) {}
    }
  }

  void playShoot() => _playSfx('shoot.mp3');
  void playMelee() => _playSfx('melee.mp3');
  void playClick() => _playSfx('click.mp3');

  Future<void> startMusic() async {
    if (!musicEnabled) return;
    try {
      if (_bgmPlayer != null) {
        await _bgmPlayer!.setVolume(musicVolume);
        // already playing — just update volume
        final st = _bgmPlayer!.state;
        if (st == PlayerState.playing) return;
      }
      await stopMusic();
      _bgmPlayer = AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(musicVolume);
      await _bgmPlayer!.play(AssetSource('sounds/bgm.mp3'));
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _bgmPlayer?.stop();
      await _bgmPlayer?.dispose();
    } catch (_) {}
    _bgmPlayer = null;
  }

  void applyMusicSetting() {
    if (musicEnabled && isPlaying) {
      startMusic();
    } else if (!musicEnabled) {
      stopMusic();
    }
  }

  Future<void> loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hs = prefs.getString('high_scores');
      if (hs != null) {
        final list = jsonDecode(hs) as List<dynamic>;
        highScores = list.map((e) => HighScoreEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      final sv = prefs.getString('game_saves');
      if (sv != null) {
        final list = jsonDecode(sv) as List<dynamic>;
        saves = list.map((e) => GameSave.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
  }

  Future<void> _persistScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('high_scores', jsonEncode(highScores.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _persistSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('game_saves', jsonEncode(saves.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  int _currentPlaySeconds() {
    if (playStartTime == null) return _savedPlaySeconds;
    return _savedPlaySeconds + DateTime.now().difference(playStartTime!).inSeconds;
  }

  Future<void> saveGame() async {
    if (!isPlaying) return;
    final save = GameSave(
      name: playerName,
      floor: currentFloor,
      level: currentLevel,
      score: score,
      health: player.health,
      maxHealth: maxHealth,
      bolterDamage: bolterDamage,
      rifleDamage: rifleDamage,
      shotgunDamage: shotgunDamage,
      swordDamage: swordDamage,
      axeDamage: axeDamage,
      hammerDamage: hammerDamage,
      playerSpeed: playerSpeed,
      defenseChance: defenseChance,
      ranged: rangedWeapon.name,
      melee: meleeWeapon.name,
      usingMelee: usingMelee,
      hasDash: hasDashAbility,
      ever11: _everReached11,
      ever21: _everReached21,
      playSeconds: _currentPlaySeconds(),
      dateIso: DateTime.now().toIso8601String(),
    );
    saves.insert(0, save);
    if (saves.length > 8) saves = saves.take(8).toList();
    await _persistSaves();
    playClick();
  }

  void loadSave(GameSave s) {
    playerName = s.name;
    currentFloor = s.floor;
    currentLevel = s.level;
    score = s.score;
    maxHealth = s.maxHealth;
    bolterDamage = s.bolterDamage;
    rifleDamage = s.rifleDamage;
    shotgunDamage = s.shotgunDamage;
    swordDamage = s.swordDamage;
    axeDamage = s.axeDamage;
    hammerDamage = s.hammerDamage;
    playerSpeed = s.playerSpeed;
    defenseChance = s.defenseChance;
    rangedWeapon = RangedWeapon.values.firstWhere((e) => e.name == s.ranged, orElse: () => RangedWeapon.bolter);
    meleeWeapon = MeleeWeapon.values.firstWhere((e) => e.name == s.melee, orElse: () => MeleeWeapon.sword);
    usingMelee = s.usingMelee;
    hasDashAbility = s.hasDash;
    _everReached11 = s.ever11;
    _everReached21 = s.ever21;
    _savedPlaySeconds = s.playSeconds;
    playStartTime = DateTime.now();
    isPlaying = true;
    isPaused = false;
    portalSpawned = false;
    nearPortal = false;
    secretBossUnlockedThisLevel = false;
    secretBossSpawned = false;
    cornerStandTimer = 0;
    dashCooldown = 0;
    dashActive = 0;
    currentZoom = 0.85;
    _clearEverything();
    _startLevel();
    // restore HP after player created
    player.health = s.health.clamp(1, maxHealth);
    player.maxHealth = maxHealth;
    for (final o in ['mainMenu', 'loadSave', 'settings', 'nameInput', 'gameOver', 'levelComplete', 'upgrade', 'victory', 'records', 'backpack']) {
      overlays.remove(o);
    }
    startMusic();
  }

  void addScoreEntry({bool completed = false}) {
    playSeconds = _currentPlaySeconds();
    highScores.add(HighScoreEntry(
      playerName, score, playSeconds,
      floor: currentFloor, level: currentLevel, completed: completed,
    ));
    highScores.sort((a, b) => b.score.compareTo(a.score));
    if (highScores.length > 15) highScores = highScores.take(15).toList();
    _persistScores();
  }
    List<Vector2> getEnemySpawnPointsRaw() {
    switch (currentFloor) {
      case 1:
        return [
          Vector2(180, 280), Vector2(1020, 280), Vector2(180, 900), Vector2(1020, 900),
          Vector2(600, 550), Vector2(350, 1400), Vector2(850, 1400), Vector2(600, 1100),
        ];
      case 2:
        return [
          Vector2(150, 220), Vector2(1050, 220), Vector2(150, 1000), Vector2(1050, 1000),
          Vector2(600, 450), Vector2(600, 1300), Vector2(400, 700), Vector2(800, 700),
        ];
      case 3:
        return [
          Vector2(220, 320), Vector2(980, 320), Vector2(220, 1600), Vector2(980, 1600),
          Vector2(600, 900), Vector2(180, 900), Vector2(1020, 900), Vector2(600, 500),
        ];
      case 4:
        return [
          Vector2(160, 250), Vector2(1040, 250), Vector2(160, 1700), Vector2(1040, 1700),
          Vector2(600, 700), Vector2(380, 1200), Vector2(820, 1200), Vector2(600, 1500),
        ];
      default:
        return [
          Vector2(200, 320), Vector2(1000, 320), Vector2(200, 1600), Vector2(1000, 1600),
          Vector2(600, 500), Vector2(380, 1000), Vector2(820, 1000), Vector2(600, 1400),
        ];
    }
  }

  List<Vector2> getEnemySpawnPoints() {
    final spawn = playerSpawnPos;
    return getEnemySpawnPointsRaw().where((p) => p.distanceTo(spawn) > safeRadius).toList();
  }

  bool isInSafeZone(Vector2 pos, {double extra = 0}) => pos.distanceTo(playerSpawnPos) < safeRadius + extra;

  void openNameInput() {
    overlays.remove('mainMenu');
    overlays.add('nameInput');
  }

  void openLoadSave() {
    overlays.remove('mainMenu');
    overlays.add('loadSave');
  }

  void confirmNameAndStart(String name) {
    playerName = name.trim().isEmpty ? 'Inquisitor' : name.trim();
    overlays.remove('nameInput');
    startGame();
  }

  void startGame() {
    isPlaying = true;
    isPaused = false;
    score = 0;
    currentFloor = 1;
    currentLevel = 1;
    portalSpawned = false;
    isBossLevel = false;
    isMiniBossLevel = false;
    nearPortal = false;
    playStartTime = DateTime.now();
    playSeconds = 0;
    _savedPlaySeconds = 0;
    _everReached11 = false;
    _everReached21 = false;
    secretBossUnlockedThisLevel = false;
    secretBossSpawned = false;
    secretBossDefeated = false;
    cornerStandTimer = 0;
    hasDashAbility = false;
    dashCooldown = 0;
    dashActive = 0;
    bolterDamage = 8;
    rifleDamage = 18;
    shotgunDamage = 10;
    swordDamage = 12;
    axeDamage = 14;
    hammerDamage = 28;
    maxHealth = 6;
    playerSpeed = 210;
    defenseChance = 0.0;
    currentZoom = 0.85;
    rangedWeapon = RangedWeapon.bolter;
    meleeWeapon = MeleeWeapon.sword;
    usingMelee = false;
    _clearEverything();
    _startLevel();
    for (final o in ['mainMenu', 'nameInput', 'settings', 'gameOver', 'levelComplete', 'upgrade', 'victory', 'records', 'backpack', 'loadSave']) {
      overlays.remove(o);
    }
    startMusic();
  }

  void _clearEverything() {
    world.removeAll(world.children.toList());
    camera.viewport.children.whereType<JoystickComponent>().toList().forEach((c) => c.removeFromParent());
    camera.viewport.children.whereType<HudButtonComponent>().toList().forEach((c) => c.removeFromParent());
    camera.viewport.children.whereType<HudLabel>().toList().forEach((c) => c.removeFromParent());
    portalButton = null;
    dashButton = null;
  }

  CircleComponent _btn(Color c, double r) => CircleComponent(radius: r, paint: Paint()..color = c);

  void _startLevel() {
    enemiesSpawned = 0;
    enemiesAlive = 0;
    portalSpawned = false;
    nearPortal = false;
    isBossLevel = currentLevel == 5;
    isMiniBossLevel = currentLevel == 3;
    spawnTimer = 0;
    spawnInterval = max(0.5, 1.3 - (currentFloor * 0.1) - (currentLevel * 0.06));
    secretBossUnlockedThisLevel = false;
    secretBossSpawned = false;
    cornerStandTimer = 0;
    _checkUnlocks();

    world.add(Floor(size: Vector2(mapWidth, mapHeight))..priority = 0);
    _createWalls();
    _createObstacles();
    for (final pos in getEnemySpawnPoints()) {
      world.add(EnemySpawnPortal(position: pos)..priority = 3);
    }
    world.add(PlayerSpawnPoint(position: playerSpawnPos.clone())..priority = 3);

    moveJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.38, paint: Paint()..color = const Color(0xFF8B0000)),
      background: CircleComponent(radius: joystickSize, paint: Paint()..color = const Color(0xFF2F2F2F).withOpacity(0.75)),
      margin: const EdgeInsets.only(left: 28, bottom: 35),
    );
    attackJoystick = JoystickComponent(
      knob: CircleComponent(radius: joystickSize * 0.35, paint: Paint()..color = const Color(0xFF00BCD4)),
      background: CircleComponent(radius: joystickSize * 0.95, paint: Paint()..color = const Color(0xFF006064).withOpacity(0.7)),
      margin: const EdgeInsets.only(right: 28, bottom: 35),
    );

    final br = (buttonSize * 0.55).clamp(18.0, 36.0);

    switchWeaponButton = HudButtonComponent(
      button: _btn(Colors.grey[800]!, br),
      buttonDown: _btn(Colors.grey, br),
      margin: const EdgeInsets.only(right: 32, bottom: 160),
      onPressed: () {
        if (isPlaying && !isPaused) {
          usingMelee = !usingMelee;
          playClick();
        }
      },
    );
    backpackButton = HudButtonComponent(
      button: _btn(const Color(0xFF5D4037), br * 0.93),
      buttonDown: _btn(const Color(0xFF8D6E63), br * 0.93),
      margin: const EdgeInsets.only(right: 32, top: 150),
      onPressed: () {
        if (isPlaying) {
          isPaused = true;
          playClick();
          overlays.add('backpack');
        }
      },
    );
    settingsButton = HudButtonComponent(
      button: _btn(const Color(0xFF37474F), br * 0.93),
      buttonDown: _btn(Colors.blueGrey, br * 0.93),
      margin: const EdgeInsets.only(right: 32, top: 90),
      onPressed: () {
        if (isPlaying) {
          isPaused = true;
          playClick();
          overlays.add('settings');
        }
      },
    );
    zoomInButton = HudButtonComponent(
      button: _btn(const Color(0xFF455A64), br * 0.85),
      buttonDown: _btn(Colors.blueGrey[400]!, br * 0.85),
      margin: const EdgeInsets.only(left: 28, top: 90),
      onPressed: () {
        currentZoom = (currentZoom + 0.12).clamp(0.55, 1.5);
        camera.viewfinder.zoom = currentZoom;
        playClick();
      },
    );
    zoomOutButton = HudButtonComponent(
      button: _btn(const Color(0xFF455A64), br * 0.85),
      buttonDown: _btn(Colors.blueGrey[400]!, br * 0.85),
      margin: const EdgeInsets.only(left: 28, top: 150),
      onPressed: () {
        currentZoom = (currentZoom - 0.12).clamp(0.55, 1.5);
        camera.viewfinder.zoom = currentZoom;
        playClick();
      },
    );

    player = Player(moveJoystick);
    world.add(player);
    camera.viewport.add(moveJoystick);
    camera.viewport.add(attackJoystick);
    camera.viewport.add(switchWeaponButton);
    camera.viewport.add(backpackButton);
    camera.viewport.add(settingsButton);
    camera.viewport.add(zoomInButton);
    camera.viewport.add(zoomOutButton);
    camera.viewport.add(HudLabel(text: '+', margin: const EdgeInsets.only(left: 40, top: 98)));
    camera.viewport.add(HudLabel(text: '-', margin: const EdgeInsets.only(left: 42, top: 158)));
    camera.viewport.add(HudLabel(text: 'S', margin: const EdgeInsets.only(right: 48, top: 98)));
    camera.viewport.add(HudLabel(text: 'B', margin: const EdgeInsets.only(right: 48, top: 158)));
    camera.viewport.add(HudLabel(text: 'A', margin: const EdgeInsets.only(right: 48, bottom: 168)));
    camera.viewport.add(HudLabel(text: 'M', margin: const EdgeInsets.only(left: 58, bottom: 50)));
    camera.viewport.add(HudLabel(text: 'F', margin: const EdgeInsets.only(right: 58, bottom: 50)));
    if (hasDashAbility) _ensureDashButton();
    camera.follow(player);
    camera.viewfinder.zoom = currentZoom;

    if (isBossLevel) {
      _spawnBosses();
    } else if (isMiniBossLevel) {
      enemiesToSpawn = 1;
      enemiesAlive = 1;
      enemiesSpawned = 1;
      world.add(MiniBoss(floor: currentFloor, position: Vector2(mapWidth / 2, mapHeight / 2 - 220))..priority = 24);
    } else {
      enemiesToSpawn = 6 + (currentLevel * 2) + (currentFloor * 3);
    }
  }

  void showPortalButton() {
    if (portalButton != null) return;
    portalButton = HudButtonComponent(
      button: _btn(const Color(0xFFE91E63), 32),
      buttonDown: _btn(const Color(0xFFF48FB1), 32),
      margin: const EdgeInsets.only(bottom: 200),
      anchor: Anchor.bottomCenter,
      onPressed: () {
        if (isPlaying && !isPaused && portalSpawned) goToNextLevel();
      },
    );
    camera.viewport.add(portalButton!);
    camera.viewport.add(HudLabel(text: 'P', margin: const EdgeInsets.only(bottom: 210)));
  }

  void hidePortalButton() {
    portalButton?.removeFromParent();
    portalButton = null;
  }

  void _ensureDashButton() {
    if (dashButton != null) return;
    dashButton = HudButtonComponent(
      button: _btn(const Color(0xFF6A1B9A), 26),
      buttonDown: _btn(const Color(0xFF9C27B0), 26),
      margin: const EdgeInsets.only(left: 28, top: 210),
      onPressed: activateDash,
    );
    camera.viewport.add(dashButton!);
    camera.viewport.add(HudLabel(text: 'U', margin: const EdgeInsets.only(left: 40, top: 218)));
  }

  void activateDash() {
    if (!hasDashAbility || dashCooldown > 0 || dashActive > 0 || !isPlaying || isPaused) return;
    dashActive = 2.0;
    dashCooldown = 6.0;
  }

  void _spawnSecretBoss() {
    secretBossSpawned = true;
    secretBossUnlockedThisLevel = false;
    cornerStandTimer = 0;
    enemiesAlive++;
    enemiesToSpawn++;
    enemiesSpawned++;
    world.add(TentacleBoss(position: Vector2(mapWidth / 2, mapHeight / 2 - 120))..priority = 28);
  }

  void onSecretBossKilled() {
    secretBossDefeated = true;
    hasDashAbility = true;
    score += 6666;
    enemiesAlive = max(0, enemiesAlive - 1);
    _ensureDashButton();
  }

  void _spawnBosses() {
    enemiesToSpawn = 1;
    enemiesAlive = 1;
    enemiesSpawned = 1;
    world.add(Boss(floor: currentFloor, position: Vector2(mapWidth / 2 - 140, mapHeight / 2 - 240))..priority = 25);
    if (overallLevel >= 15) {
      enemiesToSpawn++;
      enemiesAlive++;
      enemiesSpawned++;
      world.add(KnightBoss(floor: currentFloor, position: Vector2(mapWidth / 2 + 140, mapHeight / 2 - 240))..priority = 25);
    }
    if (overallLevel == 25) {
      enemiesToSpawn++;
      enemiesAlive++;
      enemiesSpawned++;
      world.add(KingBoss(position: Vector2(mapWidth / 2, mapHeight / 2 - 380))..priority = 26);
    }
  }

  void _createWalls() {
    const t = 48.0;
    final brown = const Color(0xFF5D4037);
    void border(Vector2 p, Vector2 s) => world.add(Wall(position: p, size: s, color: brown)..priority = 5);
    border(Vector2(0, 0), Vector2(mapWidth, t));
    border(Vector2(0, mapHeight - t), Vector2(mapWidth, t));
    border(Vector2(0, 0), Vector2(t, mapHeight));
    border(Vector2(mapWidth - t, 0), Vector2(t, mapHeight));
    void inner(Vector2 p, Vector2 s) {
      if (isInSafeZone(p + s / 2, extra: 50)) return;
      world.add(Wall(position: p, size: s, color: brown)..priority = 5);
    }
    switch (currentFloor) {
      case 1:
        inner(Vector2(480, 850), Vector2(240, 32));
        break;
      case 2:
        inner(Vector2(360, 180), Vector2(32, 560));
        inner(Vector2(800, 180), Vector2(32, 560));
        inner(Vector2(360, 1100), Vector2(32, 560));
        inner(Vector2(800, 1100), Vector2(32, 560));
        inner(Vector2(180, 880), Vector2(240, 32));
        inner(Vector2(780, 880), Vector2(240, 32));
        break;
      case 3:
        inner(Vector2(520, 240), Vector2(32, 520));
        inner(Vector2(650, 240), Vector2(32, 520));
        inner(Vector2(520, 1200), Vector2(32, 520));
        inner(Vector2(650, 1200), Vector2(32, 520));
        inner(Vector2(180, 900), Vector2(300, 32));
        inner(Vector2(720, 900), Vector2(300, 32));
        break;
      case 4:
        inner(Vector2(240, 280), Vector2(220, 32));
        inner(Vector2(740, 280), Vector2(220, 32));
        inner(Vector2(240, 600), Vector2(32, 240));
        inner(Vector2(920, 600), Vector2(32, 240));
        inner(Vector2(380, 920), Vector2(360, 32));
        inner(Vector2(240, 1250), Vector2(32, 280));
        inner(Vector2(920, 1250), Vector2(32, 280));
        inner(Vector2(300, 1620), Vector2(480, 32));
        break;
      case 5:
        for (final p in [
          Vector2(220, 400), Vector2(920, 400), Vector2(220, 900),
          Vector2(920, 900), Vector2(220, 1400), Vector2(920, 1400)
        ]) {
          inner(p, Vector2(60, 60));
        }
        inner(Vector2(520, 240), Vector2(120, 44));
        inner(Vector2(520, 1700), Vector2(120, 44));
        break;
    }
  }

  void _createObstacles() {
    List<Vector2> positions;
    switch (currentFloor) {
      case 1:
        positions = [Vector2(320, 700), Vector2(880, 1050), Vector2(600, 1300)];
        break;
      case 2:
        positions = [Vector2(520, 400), Vector2(680, 1200), Vector2(260, 1300), Vector2(940, 600)];
        break;
      case 3:
        positions = [Vector2(380, 580), Vector2(820, 580), Vector2(380, 1300), Vector2(820, 1300)];
        break;
      case 4:
        positions = [Vector2(450, 480), Vector2(750, 780), Vector2(520, 1300), Vector2(260, 950), Vector2(940, 950)];
        break;
      default:
        positions = [Vector2(400, 650), Vector2(800, 650), Vector2(400, 1250), Vector2(800, 1250)];
        break;
    }
    for (final pos in positions) {
      if (isInSafeZone(pos, extra: 30)) continue;
      world.add(Obstacle(position: pos)..priority = 5);
    }
  }

  void _spawnOneEnemy() {
    if (enemiesSpawned >= enemiesToSpawn) return;
    final points = getEnemySpawnPoints();
    if (points.isEmpty) return;
    enemiesSpawned++;
    enemiesAlive++;
    final enemy = Enemy(floor: currentFloor, type: _chooseEnemyType());
    enemy.position = points[Random().nextInt(points.length)].clone();
    enemy.priority = 30;
    world.add(enemy);
  }

  EnemyType _chooseEnemyType() {
    final roll = Random().nextDouble();
    final lvl = overallLevel;
    if (lvl >= 20) {
      if (roll < 0.25) return EnemyType.dog;
      if (roll < 0.50) return EnemyType.shieldedShooter;
      if (roll < 0.70) return EnemyType.shielded;
      if (roll < 0.85) return EnemyType.shooter;
      return EnemyType.melee;
    } else if (lvl >= 11) {
      if (roll < 0.30) return EnemyType.dog;
      if (roll < 0.50) return EnemyType.melee;
      if (roll < 0.70) return EnemyType.shooter;
      return EnemyType.shielded;
    } else if (currentFloor <= 2) {
      return roll < 0.55 ? EnemyType.melee : EnemyType.shooter;
    }
    if (roll < 0.35) return EnemyType.melee;
    if (roll < 0.70) return EnemyType.shooter;
    return EnemyType.shielded;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying || isPaused) return;
    if (dashCooldown > 0) dashCooldown = max(0, dashCooldown - dt);
    if (dashActive > 0) dashActive = max(0, dashActive - dt);

    if (!isBossLevel && !isMiniBossLevel && !secretBossSpawned && enemiesSpawned < enemiesToSpawn) {
      spawnTimer += dt;
      if (spawnTimer >= spawnInterval) {
        spawnTimer = 0;
        _spawnOneEnemy();
      }
    }

    if (portalSpawned) {
      bool near = false;
      for (final p in world.children.whereType<Portal>()) {
        if (player.position.distanceTo(p.position) < 100) {
          near = true;
          break;
        }
      }
      if (near && !nearPortal) {
        nearPortal = true;
        showPortalButton();
      } else if (!near && nearPortal) {
        nearPortal = false;
        hidePortalButton();
      }
    }

    if (secretBossUnlockedThisLevel && !secretBossSpawned && portalSpawned) {
      final inCorner = player.position.x < 140 && player.position.y < 140;
      if (inCorner) {
        cornerStandTimer += dt;
        if (cornerStandTimer >= 33) _spawnSecretBoss();
      } else {
        cornerStandTimer = 0;
      }
    }
  }

  void onEnemyKilled() {
    enemiesAlive = max(0, enemiesAlive - 1);
    score += (isBossLevel || isMiniBossLevel) ? 180 + (currentFloor * 60) : 12 + (currentFloor * 6);
    if (enemiesAlive <= 0 && enemiesSpawned >= enemiesToSpawn && !portalSpawned) {
      portalSpawned = true;
      world.add(Portal(position: Vector2(mapWidth / 2, mapHeight / 2))..priority = 9);
      if (isBossLevel) secretBossUnlockedThisLevel = true;
    }
  }

  void goToNextLevel() {
    isPlaying = false;
    hidePortalButton();
    nearPortal = false;
    if (currentFloor == 5 && currentLevel == 5) {
      stopMusic();
      addScoreEntry(completed: true);
      overlays.add('victory');
      return;
    }
    if (currentLevel == 5) {
      overlays.add('upgrade');
      return;
    }
    currentLevel++;
    overlays.add('levelComplete');
  }

  void applyUpgrade(String type) {
    switch (type) {
      case 'bolter':
        bolterDamage += 5;
        rifleDamage += 4;
        shotgunDamage += 3;
        break;
      case 'sword':
        swordDamage += 5;
        axeDamage += 4;
        hammerDamage += 6;
        break;
      case 'health':
        maxHealth += 2;
        break;
      case 'speed':
        playerSpeed += 28;
        break;
      case 'defense':
        defenseChance = min(0.45, defenseChance + 0.13);
        break;
    }
    currentFloor++;
    currentLevel = 1;
    overlays.remove('upgrade');
    overlays.add('levelComplete');
  }

  void nextLevel() {
    overlays.remove('levelComplete');
    _clearEverything();
    isPlaying = true;
    isPaused = false;
    _startLevel();
  }

  void openSettings() {
    overlays.remove('mainMenu');
    overlays.add('settings');
  }

  void closeSettings() {
    overlays.remove('settings');
    isPaused = false;
  }

  void closeBackpack() {
    overlays.remove('backpack');
    isPaused = false;
  }

  void exitMatch() {
    stopMusic();
    isPlaying = false;
    isPaused = false;
    hidePortalButton();
    addScoreEntry(completed: false);
    _clearEverything();
    for (final o in ['settings', 'gameOver', 'levelComplete', 'upgrade', 'victory', 'records', 'nameInput', 'backpack', 'loadSave']) {
      overlays.remove(o);
    }
    overlays.add('mainMenu');
  }

  void backToMenu() {
    stopMusic();
    isPlaying = false;
    isPaused = false;
    _clearEverything();
    for (final o in ['settings', 'gameOver', 'levelComplete', 'upgrade', 'victory', 'records', 'nameInput', 'backpack', 'loadSave']) {
      overlays.remove(o);
    }
    overlays.add('mainMenu');
  }

  void showGameOver() {
    stopMusic();
    isPlaying = false;
    hidePortalButton();
    addScoreEntry(completed: false);
    overlays.add('gameOver');
  }

  bool get areOtherBossesAlive =>
      world.children.whereType<Boss>().isNotEmpty || world.children.whereType<KnightBoss>().isNotEmpty;

  String get currentWeaponName {
    if (usingMelee) {
      switch (meleeWeapon) {
        case MeleeWeapon.sword:
          return 'SWORD';
        case MeleeWeapon.axe:
          return 'AXE';
        case MeleeWeapon.hammer:
          return 'HAMMER';
      }
    }
    switch (rangedWeapon) {
      case RangedWeapon.bolter:
        return 'BOLTER';
      case RangedWeapon.rifle:
        return 'RIFLE';
      case RangedWeapon.shotgun:
        return 'SHOTGUN';
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isPlaying) return;
    hudPaint.render(canvas, 'Floor $currentFloor | Lvl $currentLevel', Vector2(14, 14));
    hudPaint.render(canvas, 'Score: $score', Vector2(14, 36));
    hudPaint.render(canvas, 'HP: ${player.health}/${player.maxHealth}', Vector2(14, 58));
    final status = isBossLevel
        ? 'BOSS'
        : (isMiniBossLevel ? 'MINI-BOSS' : (secretBossSpawned ? 'SECRET' : 'Enemies: $enemiesAlive'));
    hudPaint.render(canvas, status, Vector2(14, 80));
    hudPaint.render(canvas, currentWeaponName, Vector2(14, 102));
    final sec = _currentPlaySeconds();
    hudPaint.render(
      canvas,
      'Time ${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}',
      Vector2(14, 124),
    );
    if (secretBossUnlockedThisLevel && !secretBossSpawned && cornerStandTimer > 0) {
      hudPaint.render(canvas, '??? ${cornerStandTimer.toStringAsFixed(0)}/33', Vector2(14, 146));
    }
    if (hasDashAbility) {
      if (dashActive > 0) {
        hudPaint.render(canvas, 'DASH!', Vector2(14, 168));
      } else if (dashCooldown > 0) {
        hudPaint.render(canvas, 'U CD ${dashCooldown.toStringAsFixed(1)}', Vector2(14, 168));
      }
    }
  }
}

class HudLabel extends PositionComponent with HasGameReference<InquisitorGame> {
  final String text;
  final EdgeInsets margin;
  HudLabel({required this.text, required this.margin}) : super(priority: 200);

  @override
  void onMount() {
    super.onMount();
    final size = game.size;
    double x = margin.left;
    double y = margin.top;
    if (margin.right > 0) x = size.x - margin.right - 12;
    if (margin.bottom > 0) y = size.y - margin.bottom - 12;
    if (margin.left == 0 && margin.right == 0) x = size.x / 2 - 6;
    position = Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset.zero);
  }
}

mixin SmartMover on PositionComponent, HasGameReference<InquisitorGame> {
  double stuckTimer = 0;
  Vector2? avoidDir;
  double strafeSign = 1;
  double rethinkTimer = 0;

  void smartMove(Vector2 target, double speed, double dt, {double radius = 30, bool kite = false, double preferDist = 0}) {
    rethinkTimer -= dt;
    if (rethinkTimer <= 0) {
      rethinkTimer = 0.4 + Random().nextDouble() * 0.5;
      strafeSign = Random().nextBool() ? 1.0 : -1.0;
    }
    var toTarget = target - position;
    final dist = toTarget.length;
    if (dist < 1) return;
    var desired = toTarget / dist;
    if (kite && preferDist > 0) {
      if (dist < preferDist * 0.75) {
        desired = -desired;
      } else if (dist < preferDist * 1.15) {
        desired = Vector2(-desired.y, desired.x) * strafeSign;
      }
    }
    Vector2 sep = Vector2.zero();
    for (final e in game.world.children.whereType<Enemy>()) {
      if (identical(e, this)) continue;
      final d = position.distanceTo(e.position);
      if (d > 0 && d < radius * 2.4) {
        sep += (position - e.position).normalized() * ((radius * 2.4 - d) / (radius * 2.4));
      }
    }
    if (sep.length2 > 0.01) desired = (desired + sep.normalized() * 0.55).normalized();
    if (avoidDir != null) {
      stuckTimer -= dt;
      if (stuckTimer <= 0) {
        avoidDir = null;
      } else {
        desired = (desired * 0.35 + avoidDir! * 0.65).normalized();
      }
    }
    final next = position + desired * speed * dt;
    if (_canStand(next, radius)) {
      position = next;
    } else {
      final slide1 = Vector2(-desired.y, desired.x);
      final slide2 = Vector2(desired.y, -desired.x);
      final n1 = position + slide1 * speed * dt;
      final n2 = position + slide2 * speed * dt;
      if (_canStand(n1, radius)) {
        position = n1;
        avoidDir = slide1;
        stuckTimer = 0.55;
      } else if (_canStand(n2, radius)) {
        position = n2;
        avoidDir = slide2;
        stuckTimer = 0.55;
      } else {
        final back = position - desired * speed * dt * 0.6;
        if (_canStand(back, radius)) position = back;
        position.x = position.x.clamp(80, game.mapWidth - 80);
        position.y = position.y.clamp(80, game.mapHeight - 80);
        avoidDir = Vector2(Random().nextDouble() - 0.5, Random().nextDouble() - 0.5).normalized();
        stuckTimer = 0.7;
      }
    }
  }

  bool _canStand(Vector2 pos, double radius) {
    if (pos.x < 70 + radius || pos.x > game.mapWidth - 70 - radius) return false;
    if (pos.y < 70 + radius || pos.y > game.mapHeight - 70 - radius) return false;
    for (final w in game.world.children.whereType<Wall>()) {
      final r = w.toAbsoluteRect();
      if (Rect.fromLTRB(r.left - radius, r.top - radius, r.right + radius, r.bottom + radius).contains(pos.toOffset())) return false;
    }
    for (final o in game.world.children.whereType<Obstacle>()) {
      if (pos.distanceTo(o.position) < radius + 32) return false;
    }
    return true;
  }

  void pushOutOfWalls(double radius) {
    for (final w in game.world.children.whereType<Wall>()) {
      final r = w.toAbsoluteRect();
      if (Rect.fromLTRB(r.left - radius, r.top - radius, r.right + radius, r.bottom + radius).contains(position.toOffset())) {
        final dx = position.x - r.center.dx;
        final dy = position.y - r.center.dy;
        if (dx.abs() > dy.abs()) {
          position.x += dx > 0 ? 14 : -14;
        } else {
          position.y += dy > 0 ? 14 : -14;
        }
      }
    }
  }
}

class EnemySpawnPortal extends PositionComponent {
  double flicker = 0;
  EnemySpawnPortal({required Vector2 position}) : super(position: position, size: Vector2(48, 48), anchor: Anchor.center, priority: 3);
  @override
  void update(double dt) {
    super.update(dt);
    flicker += dt * 4;
  }
  @override
  void render(Canvas canvas) {
    final a = 0.45 + 0.4 * sin(flicker);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 18, Paint()..color = Color.fromRGBO(255, 140, 0, a));
  }
}

class PlayerSpawnPoint extends PositionComponent {
  PlayerSpawnPoint({required Vector2 position}) : super(position: position, size: Vector2(56, 56), anchor: Anchor.center, priority: 3);
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 22, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.75));
  }
}

class Floor extends PositionComponent {
  Floor({required Vector2 size}) : super(size: size, position: Vector2.zero(), priority: 0);
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFFB0BEC5));
    final grid = Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
    }
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  final Color color;
  Wall({required Vector2 position, required Vector2 size, required this.color}) : super(position: position, size: size, priority: 5);
  @override
  Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void render(Canvas canvas) => canvas.drawRect(size.toRect(), Paint()..color = color);
}

class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({required Vector2 position}) : super(position: position, size: Vector2(56, 56), anchor: Anchor.center, priority: 5);
  @override
  Future<void> onLoad() async => add(RectangleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)), Paint()..color = const Color(0xFF6D4C41));
  }
}

class Portal extends PositionComponent with CollisionCallbacks {
  Portal({required Vector2 position}) : super(position: position, size: Vector2(88, 88), anchor: Anchor.center, priority: 9);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void render(Canvas canvas) {
    canvas.drawCircle((size / 2).toOffset(), 38, Paint()..color = const Color(0xFFE91E63).withOpacity(0.85));
  }
}
// ====================== MENUS ======================
class BackpackMenu extends StatelessWidget {
  final InquisitorGame game;
  const BackpackMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('РЮКЗАК', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
              Text(game.playerName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              _s('HP', '${game.player.health}/${game.maxHealth}'),
              _s('Скорость', '${game.playerSpeed.toInt()}'),
              _s('Защита', '${(game.defenseChance * 100).toInt()}%'),
              if (game.hasDashAbility) _s('U', 'DASH'),
              const SizedBox(height: 12),
              const Text('Дальний', style: TextStyle(color: Color(0xFFFFD700))),
              Wrap(spacing: 8, children: [
                _w('Болтер', true, !game.usingMelee && game.rangedWeapon == RangedWeapon.bolter, () {
                  game.rangedWeapon = RangedWeapon.bolter;
                  game.usingMelee = false;
                }),
                _w('Винтовка', game.unlockedRifle, !game.usingMelee && game.rangedWeapon == RangedWeapon.rifle, () {
                  game.rangedWeapon = RangedWeapon.rifle;
                  game.usingMelee = false;
                }),
                _w('Дробовик', game.unlockedShotgun, !game.usingMelee && game.rangedWeapon == RangedWeapon.shotgun, () {
                  game.rangedWeapon = RangedWeapon.shotgun;
                  game.usingMelee = false;
                }),
              ]),
              const Text('Ближний', style: TextStyle(color: Color(0xFFFFD700))),
              Wrap(spacing: 8, children: [
                _w('Меч', true, game.usingMelee && game.meleeWeapon == MeleeWeapon.sword, () {
                  game.meleeWeapon = MeleeWeapon.sword;
                  game.usingMelee = true;
                }),
                _w('Топор', game.unlockedAxe, game.usingMelee && game.meleeWeapon == MeleeWeapon.axe, () {
                  game.meleeWeapon = MeleeWeapon.axe;
                  game.usingMelee = true;
                }),
                _w('Молот', game.unlockedHammer, game.usingMelee && game.meleeWeapon == MeleeWeapon.hammer, () {
                  game.meleeWeapon = MeleeWeapon.hammer;
                  game.usingMelee = true;
                }),
              ]),
              const Spacer(),
              ElevatedButton(onPressed: game.closeBackpack, child: const Text('ЗАКРЫТЬ')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _s(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.white70)),
          Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _w(String n, bool u, bool sel, VoidCallback f) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: sel ? const Color(0xFFB8860B) : (u ? const Color(0xFF2A2A2A) : const Color(0xFF151515)),
        ),
        onPressed: u ? f : null,
        child: Text(u ? n : '🔒 $n', style: TextStyle(color: u ? Colors.white : Colors.white24)),
      );
}

class NameInputMenu extends StatefulWidget {
  final InquisitorGame game;
  const NameInputMenu(this.game, {super.key});
  @override
  State<NameInputMenu> createState() => _NameInputMenuState();
}

class _NameInputMenuState extends State<NameInputMenu> {
  final c = TextEditingController();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ИМЯ ИНКВИЗИТОРА', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
              TextField(
                controller: c,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Имя...', hintStyle: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(onPressed: () => widget.game.confirmNameAndStart(c.text), child: const Text('НАЧАТЬ')),
              TextButton(
                onPressed: () {
                  widget.game.overlays.remove('nameInput');
                  widget.game.overlays.add('mainMenu');
                },
                child: const Text('НАЗАД', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenu extends StatefulWidget {
  final InquisitorGame game;
  const MainMenu(this.game, {super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final symbols = <_MS>[];
  final _rnd = Random();
  static const _chars = '01アイウエオカキクケコサシスセソタチツテトナニヌネノABCDEFXYZ';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    for (int i = 0; i < 70; i++) {
      symbols.add(_MS(_rnd.nextDouble(), _rnd.nextDouble(), 0.25 + _rnd.nextDouble() * 1.2, _chars[_rnd.nextInt(_chars.length)], 0.2 + _rnd.nextDouble() * 0.7));
    }
    _controller.addListener(() {
      setState(() {
        for (final s in symbols) {
          s.y += s.speed * 0.013;
          if (s.y > 1.15) {
            s.y = -0.1;
            s.x = _rnd.nextDouble();
            s.char = _chars[_rnd.nextInt(_chars.length)];
            s.opacity = 0.2 + _rnd.nextDouble() * 0.7;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MP(symbols))),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SOUL OF THE\nINQUISITOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    shadows: [Shadow(color: Colors.redAccent, blurRadius: 14)],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('by Инквизитор Данте', style: TextStyle(color: Color(0xFFB8860B), fontSize: 14)),
                const SizedBox(height: 40),
                _btn('НАЧАТЬ ИГРУ', () {
                  widget.game.playClick();
                  widget.game.openNameInput();
                }),
                const SizedBox(height: 12),
                _btn('ЗАГРУЗИТЬ СОХРАНЕНИЕ', () {
                  widget.game.playClick();
                  widget.game.openLoadSave();
                }),
                const SizedBox(height: 12),
                _btn('РЕКОРДЫ', () {
                  widget.game.playClick();
                  widget.game.overlays.remove('mainMenu');
                  widget.game.overlays.add('records');
                }),
                const SizedBox(height: 12),
                _btn('НАСТРОЙКИ', () {
                  widget.game.playClick();
                  widget.game.openSettings();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          side: const BorderSide(color: Color(0xFFB8860B), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFFFFD700))),
      ),
    );
  }
}

class _MS {
  double x, y, speed, opacity;
  String char;
  _MS(this.x, this.y, this.speed, this.char, this.opacity);
}

class _MP extends CustomPainter {
  final List<_MS> symbols;
  _MP(this.symbols);
  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final s in symbols) {
      tp.text = TextSpan(
        text: s.char,
        style: TextStyle(color: Color.fromRGBO(0, 255, 70, s.opacity), fontSize: 14 + s.speed * 4, fontFamily: 'monospace'),
      );
      tp.layout();
      tp.paint(canvas, Offset(s.x * size.width, s.y * size.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LoadSaveMenu extends StatelessWidget {
  final InquisitorGame game;
  const LoadSaveMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('ЗАГРУЗИТЬ СОХРАНЕНИЕ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: game.saves.isEmpty
                  ? const Center(child: Text('Нет сохранений', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: game.saves.length,
                      itemBuilder: (_, i) {
                        final s = game.saves[i];
                        return Card(
                          color: const Color(0xFF1A1A1A),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            title: Text(s.name, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Этаж ${s.floor} / Ур. ${s.level}  •  Очки ${s.score}\n${s.dateStr}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.play_arrow, color: Color(0xFFFFD700)),
                            onTap: () {
                              game.playClick();
                              game.loadSave(s);
                            },
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  game.overlays.remove('loadSave');
                  game.overlays.add('mainMenu');
                },
                child: const Text('НАЗАД'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordsMenu extends StatelessWidget {
  final InquisitorGame game;
  const RecordsMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Text('РЕКОРДЫ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold)),
            Expanded(
              child: game.highScores.isEmpty
                  ? const Center(child: Text('Пока пусто', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: game.highScores.length,
                      itemBuilder: (_, i) {
                        final e = game.highScores[i];
                        return ListTile(
                          title: Text('${i + 1}. ${e.name}', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(e.progressStr, style: TextStyle(color: e.completed ? const Color(0xFFFFD700) : Colors.white54, fontSize: 12)),
                          trailing: Text('${e.score}\n${e.timeStr}', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('records');
                game.overlays.add('mainMenu');
              },
              child: const Text('НАЗАД'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsMenu extends StatefulWidget {
  final InquisitorGame game;
  const SettingsMenu(this.game, {super.key});
  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  String? _saveMsg;

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('НАСТРОЙКИ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Джойстик: ${g.joystickSize.toInt()}', style: const TextStyle(color: Colors.white)),
              Slider(value: g.joystickSize, min: 55, max: 120, divisions: 13, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.joystickSize = v)),
              Text('Кнопки: ${g.buttonSize.toInt()}', style: const TextStyle(color: Colors.white)),
              Slider(value: g.buttonSize, min: 28, max: 65, divisions: 8, activeColor: const Color(0xFFFFD700), onChanged: (v) => setState(() => g.buttonSize = v)),
              SwitchListTile(
                title: const Text('Звуки', style: TextStyle(color: Colors.white)),
                value: g.soundEnabled,
                activeColor: const Color(0xFFFFD700),
                onChanged: (v) => setState(() => g.soundEnabled = v),
              ),
              Text('Громкость эффектов: ${(g.soundVolume * 100).toInt()}%', style: const TextStyle(color: Colors.white70)),
              Slider(value: g.soundVolume, min: 0, max: 1, activeColor: const Color(0xFFFFD700), onChanged: g.soundEnabled ? (v) => setState(() => g.soundVolume = v) : null),
              SwitchListTile(
                title: const Text('Музыка', style: TextStyle(color: Colors.white)),
                value: g.musicEnabled,
                activeColor: const Color(0xFFFFD700),
                onChanged: (v) {
                  setState(() {
                    g.musicEnabled = v;
                    g.applyMusicSetting();
                  });
                },
              ),
              Text('Громкость музыки: ${(g.musicVolume * 100).toInt()}%', style: const TextStyle(color: Colors.white70)),
              Slider(
                value: g.musicVolume,
                min: 0,
                max: 1,
                activeColor: const Color(0xFFFFD700),
                onChanged: g.musicEnabled
                    ? (v) {
                        setState(() {
                          g.musicVolume = v;
                          g._bgmPlayer?.setVolume(v);
                        });
                      }
                    : null,
              ),
              if (g.isPlaying) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () async {
                      await g.saveGame();
                      setState(() => _saveMsg = 'Сохранено!');
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _saveMsg = null);
                      });
                    },
                    child: const Text('СОХРАНИТЬ ИГРУ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (_saveMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_saveMsg!, style: const TextStyle(color: Colors.greenAccent)),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () {
                      g.playClick();
                      g.exitMatch();
                    },
                    child: const Text('ВЫХОД ИЗ МАТЧА', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const Spacer(),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFB8860B)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  onPressed: () {
                    g.playClick();
                    if (g.isPlaying) {
                      g.closeSettings();
                    } else {
                      g.backToMenu();
                    }
                  },
                  child: Text(g.isPlaying ? 'НАЗАД В БОЙ' : 'НАЗАД', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LevelCompleteMenu extends StatelessWidget {
  final InquisitorGame game;
  const LevelCompleteMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('УРОВЕНЬ ПРОЙДЕН', style: TextStyle(color: Colors.greenAccent, fontSize: 26, fontWeight: FontWeight.bold)),
            Text('Очки: ${game.score}', style: const TextStyle(color: Colors.white)),
            ElevatedButton(onPressed: game.nextLevel, child: const Text('ДАЛЬШЕ')),
          ],
        ),
      ),
    );
  }
}

class UpgradeMenu extends StatelessWidget {
  final InquisitorGame game;
  const UpgradeMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('УЛУЧШЕНИЕ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            ElevatedButton(onPressed: () => game.applyUpgrade('bolter'), child: const Text('Урон дальнего')),
            ElevatedButton(onPressed: () => game.applyUpgrade('sword'), child: const Text('Урон ближнего')),
            ElevatedButton(onPressed: () => game.applyUpgrade('health'), child: const Text('Здоровье')),
            ElevatedButton(onPressed: () => game.applyUpgrade('speed'), child: const Text('Скорость')),
            ElevatedButton(onPressed: () => game.applyUpgrade('defense'), child: const Text('Защита')),
          ],
        ),
      ),
    );
  }
}

class VictoryMenu extends StatelessWidget {
  final InquisitorGame game;
  const VictoryMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.93),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ИСПЫТАНИЕ ПРОЙДЕНО', style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            Text('${game.playerName}: ${game.score}', style: const TextStyle(color: Colors.white)),
            ElevatedButton(onPressed: game.backToMenu, child: const Text('МЕНЮ')),
          ],
        ),
      ),
    );
  }
}

class GameOverMenu extends StatelessWidget {
  final InquisitorGame game;
  const GameOverMenu(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ИНКВИЗИТОР ПАЛ', style: TextStyle(color: Colors.redAccent, fontSize: 26, fontWeight: FontWeight.bold)),
            Text('${game.playerName}: ${game.score}', style: const TextStyle(color: Colors.white)),
            Text('Этаж ${game.currentFloor} / Ур. ${game.currentLevel}', style: const TextStyle(color: Colors.white54)),
            ElevatedButton(onPressed: game.openNameInput, child: const Text('СНОВА')),
            ElevatedButton(onPressed: game.backToMenu, child: const Text('МЕНЮ')),
          ],
        ),
      ),
    );
  }
}
// ====================== PLAYER ======================
class Player extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final JoystickComponent moveJoystick;
  late int health;
  late int maxHealth;
  double attackTimer = 0;
  Vector2 aimDir = Vector2(0, -1); // last aim / attack direction

  Player(this.moveJoystick) : super(size: Vector2(72, 80), anchor: Anchor.center, priority: 15);

  @override
  Future<void> onLoad() async {
    maxHealth = game.maxHealth;
    health = maxHealth;
    position = game.playerSpawnPos.clone();
    add(CircleHitbox(radius: 28));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final spd = game.playerSpeed * (game.dashActive > 0 ? 1.30 : 1.0);
    if (moveJoystick.direction != JoystickDirection.idle) {
      position.add(moveJoystick.relativeDelta * spd * dt);
    }
    // aim: prefer attack stick, else move stick
    if (game.attackJoystick.direction != JoystickDirection.idle) {
      final d = game.attackJoystick.relativeDelta;
      if (d.length2 > 0.01) aimDir = d.normalized();
    } else if (moveJoystick.direction != JoystickDirection.idle) {
      final d = moveJoystick.relativeDelta;
      if (d.length2 > 0.01) aimDir = d.normalized();
    }
    position.x = position.x.clamp(70, game.mapWidth - 70);
    position.y = position.y.clamp(70, game.mapHeight - 70);
    if (game.attackJoystick.direction != JoystickDirection.idle) {
      attackTimer += dt;
      if (attackTimer >= _cd()) {
        attackTimer = 0;
        _atk();
      }
    } else {
      attackTimer = 0;
    }
  }

  double _cd() {
    if (game.usingMelee) {
      switch (game.meleeWeapon) {
        case MeleeWeapon.sword:
          return 0.42;
        case MeleeWeapon.axe:
          return 0.58;
        case MeleeWeapon.hammer:
          return 0.75;
      }
    }
    switch (game.rangedWeapon) {
      case RangedWeapon.bolter:
        return 0.30;
      case RangedWeapon.rifle:
        return 0.55;
      case RangedWeapon.shotgun:
        return 0.70;
    }
  }

  void _atk() {
    if (game.usingMelee) {
      game.playMelee();
    } else {
      game.playShoot();
    }
    final d = aimDir.length2 < 0.01 ? Vector2(0, -1) : aimDir;
    if (game.usingMelee) {
      switch (game.meleeWeapon) {
        case MeleeWeapon.sword:
          game.world.add(MeleeAttack(position: position + d * 40, direction: d, radius: 38, damage: game.swordDamage, color: const Color(0xFF00E5FF))..priority = 13);
          break;
        case MeleeWeapon.axe:
          game.world.add(MeleeAttack(position: position.clone(), direction: d, radius: 78, damage: game.axeDamage, color: const Color(0xFFFF6D00))..priority = 13);
          break;
        case MeleeWeapon.hammer:
          game.world.add(MeleeAttack(position: position + d * 24, direction: d, radius: 82, damage: game.hammerDamage, color: const Color(0xFFFFD600))..priority = 13);
          break;
      }
    } else {
      switch (game.rangedWeapon) {
        case RangedWeapon.bolter:
          game.world.add(Bullet(position: position.clone(), direction: d, damage: game.bolterDamage, color: const Color(0xFFFFD700), speed: 520)..priority = 13);
          break;
        case RangedWeapon.rifle:
          game.world.add(Bullet(position: position.clone(), direction: d, damage: game.rifleDamage, color: const Color(0xFFFF8A65), speed: 680, radius: 5)..priority = 13);
          break;
        case RangedWeapon.shotgun:
          final base = atan2(d.y, d.x);
          for (final o in [-0.28, 0.0, 0.28]) {
            final a = base + o;
            game.world.add(Bullet(position: position.clone(), direction: Vector2(cos(a), sin(a)), damage: game.shotgunDamage, color: const Color(0xFFFFAB40), speed: 440, radius: 6)..priority = 13);
          }
          break;
      }
    }
  }

  void takeDamage(int amount) {
    if (game.dashActive > 1.5) return;
    if (Random().nextDouble() < game.defenseChance) return;
    health -= amount;
    if (health <= 0) {
      health = 0;
      game.showGameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    if (game.dashActive > 0) {
      canvas.drawCircle(Offset(cx, cy), 44, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.28));
    }
    // body faces aim slightly (flip if aiming left)
    final facingLeft = aimDir.x < -0.15;
    canvas.save();
    if (facingLeft) {
      canvas.translate(cx, cy);
      canvas.scale(-1, 1);
      canvas.translate(-cx, -cy);
    }
    WHDraw.inquisitor(canvas, cx: cx, cy: cy, s: 1.2, cape: true);
    canvas.restore();

    // weapon rotated toward aim (0 = right in draw space → offset by -pi/2 for "up" default art)
    final ang = atan2(aimDir.y, aimDir.x);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);
    // weapons drawn pointing to +X after rotation
    if (game.usingMelee) {
      switch (game.meleeWeapon) {
        case MeleeWeapon.sword:
          WHDraw.powerSword(canvas, 0, 0, 1.15);
          break;
        case MeleeWeapon.axe:
          WHDraw.chainAxe(canvas, 0, 0, 1.15);
          break;
        case MeleeWeapon.hammer:
          WHDraw.thunderHammer(canvas, 0, 0, 1.15);
          break;
      }
    } else {
      switch (game.rangedWeapon) {
        case RangedWeapon.bolter:
          WHDraw.bolter(canvas, 0, 0, 1.1);
          break;
        case RangedWeapon.rifle:
          WHDraw.rifle(canvas, 0, 0, 1.1);
          break;
        case RangedWeapon.shotgun:
          WHDraw.shotgun(canvas, 0, 0, 1.1);
          break;
      }
    }
    canvas.restore();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!game.isPlaying || game.isPaused) return;
    if (other is Wall || other is Obstacle) {
      position -= (intersectionPoints.first - position).normalized() * 6;
    }
    if (other is Enemy || other is EnemyBullet || other is BossProjectile) {
      takeDamage(other is Enemy && other.type == EnemyType.dog ? 2 : 1);
      other.removeFromParent();
      if (other is Enemy) game.onEnemyKilled();
    }
    if (other is Boss || other is KnightBoss || other is KingBoss || other is MiniBoss || other is TentacleBoss) {
      takeDamage(1);
    }
  }
}

class Bullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final int damage;
  final double speed;
  Bullet({
    required super.position,
    required this.direction,
    required this.damage,
    Color color = const Color(0xFFFFD700),
    this.speed = 500,
    double radius = 7,
  }) : super(radius: radius, anchor: Anchor.center, paint: Paint()..color = color, priority: 13);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * speed * dt);
    if (position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) removeFromParent();
    if (other is Enemy) {
      if (other.type == EnemyType.shielded || other.type == EnemyType.shieldedShooter) {
        removeFromParent();
        return;
      }
      other.removeFromParent();
      game.onEnemyKilled();
      removeFromParent();
    }
    if (other is Boss) {
      other.takeDamage(damage);
      removeFromParent();
    }
    if (other is KnightBoss) {
      other.takeDamage(damage);
      removeFromParent();
    }
    if (other is KingBoss) {
      other.takeDamage(damage);
      removeFromParent();
    }
    if (other is MiniBoss) {
      other.takeDamage(damage);
      removeFromParent();
    }
    if (other is TentacleBoss) {
      other.takeDamage(damage);
      removeFromParent();
    }
  }
}

class MeleeAttack extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  final int damage;
  double life = 0.2;
  MeleeAttack({
    required super.position,
    required this.direction,
    required double radius,
    required this.damage,
    required Color color,
  }) : super(radius: radius, anchor: Anchor.center, paint: Paint()..color = color.withOpacity(0.45), priority: 13);

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      other.removeFromParent();
      game.onEnemyKilled();
    }
    if (other is Obstacle) other.removeFromParent();
    if (other is Boss) other.takeDamage(damage);
    if (other is KnightBoss) other.takeDamage(damage);
    if (other is KingBoss) other.takeDamage(damage);
    if (other is MiniBoss) other.takeDamage(damage);
    if (other is TentacleBoss) other.takeDamage(damage);
  }
}

class EnemyBullet extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  EnemyBullet({required super.position, required this.direction})
      : super(radius: 9, anchor: Anchor.center, paint: Paint()..color = const Color(0xFF76FF03), priority: 22);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * 160 * dt);
    if (position.x < 0 || position.x > game.mapWidth || position.y < 0 || position.y > game.mapHeight) {
      removeFromParent();
    }
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) removeFromParent();
  }
}

class BossProjectile extends CircleComponent with HasGameReference<InquisitorGame>, CollisionCallbacks {
  final Vector2 direction;
  BossProjectile({required super.position, required this.direction})
      : super(radius: 12, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFF1744), priority: 22);
  @override
  Future<void> onLoad() async => add(CircleHitbox());
  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;
    position.add(direction * 185 * dt);
    if (position.x < -80 || position.x > game.mapWidth + 80 || position.y < -80 || position.y > game.mapHeight + 80) {
      removeFromParent();
    }
  }
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) removeFromParent();
  }
}

class Enemy extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  final EnemyType type;
  late final double speed;
  double shootTimer = 0;
  double meleeTimer = 0;

  Enemy({required this.floor, required this.type}) : super(size: Vector2(68, 78), anchor: Anchor.center, priority: 30);

  @override
  Future<void> onLoad() async {
    switch (type) {
      case EnemyType.shooter:
        speed = 55 + floor * 6.0;
        break;
      case EnemyType.melee:
        speed = 85 + floor * 9.0;
        break;
      case EnemyType.shielded:
        speed = 42 + floor * 4.5;
        break;
      case EnemyType.dog:
        speed = 145 + floor * 12.0;
        size = Vector2(58, 44);
        break;
      case EnemyType.shieldedShooter:
        speed = 48 + floor * 5.0;
        break;
    }
    add(CircleHitbox(radius: type == EnemyType.dog ? 20 : 26));
  }

  Vector2 _aimAtPlayer() {
    final toP = game.player.position - position;
    final dist = toP.length;
    if (dist < 1) return Vector2(0, -1);
    final lead = game.moveJoystick.relativeDelta * (dist / 280);
    return (toP + lead).normalized();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final dist = position.distanceTo(game.player.position);
    final isRanged = type == EnemyType.shooter || type == EnemyType.shieldedShooter;
    smartMove(game.player.position, speed, dt, radius: 26, kite: isRanged, preferDist: isRanged ? 280.0 : 0.0);
    pushOutOfWalls(26);
    if (isRanged) {
      final interval = dist < 160 ? 0.55 : (dist < 320 ? 0.95 : 1.55);
      shootTimer += dt;
      if (shootTimer >= interval) {
        shootTimer = 0;
        game.world.add(EnemyBullet(position: position.clone(), direction: _aimAtPlayer())..priority = 22);
      }
    }
    if (type == EnemyType.melee || type == EnemyType.dog || type == EnemyType.shielded) {
      final hitRange = type == EnemyType.dog ? 55.0 : 70.0;
      final interval = dist < 100 ? 0.45 : 0.85;
      meleeTimer += dt;
      if (meleeTimer >= interval && dist < hitRange) {
        meleeTimer = 0;
        game.player.takeDamage(type == EnemyType.dog ? 2 : 1);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 12;
      final n = (position - intersectionPoints.first).normalized();
      avoidDir = Vector2(-n.y, n.x);
      stuckTimer = 0.55;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    switch (type) {
      case EnemyType.dog:
        WHDraw.chaosHound(canvas, cx, cy);
        break;
      case EnemyType.shooter:
        WHDraw.cultistShooter(canvas, cx, cy, 1.1);
        break;
      case EnemyType.melee:
        WHDraw.cultistMelee(canvas, cx, cy, 1.1);
        break;
      case EnemyType.shielded:
        WHDraw.shieldedMarine(canvas, cx, cy, 1.1);
        break;
      case EnemyType.shieldedShooter:
        WHDraw.shieldedMarine(canvas, cx, cy, 1.05, accent: const Color(0xFF00BCD4));
        WHDraw.bolter(canvas, cx - 8, cy, 0.85);
        break;
    }
  }
}
// ====================== BOSSES ======================
class MiniBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  late int maxHp, currentHp;
  double shootTimer = 0;
  MiniBoss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(92, 102), anchor: Anchor.center, priority: 24);

  @override
  Future<void> onLoad() async {
    maxHp = ((220 + floor * 90) / 2).round();
    currentHp = maxHp;
    add(CircleHitbox(radius: 40));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final dist = position.distanceTo(game.player.position);
    smartMove(game.player.position, 52 + floor * 4.0, dt, radius: 40, kite: true, preferDist: 260);
    pushOutOfWalls(40);
    final interval = dist < 200 ? 0.75 : 1.35;
    shootTimer += dt;
    if (shootTimer >= interval) {
      shootTimer = 0;
      final toP = (game.player.position - position).normalized();
      final base = atan2(toP.y, toP.x);
      for (final o in [-0.3, 0.0, 0.3]) {
        final a = base + o;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
      }
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    if (currentHp <= 0) {
      removeFromParent();
      game.onEnemyKilled();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 16;
      stuckTimer = 0.65;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.cultistShooter(canvas, cx, cy, 1.5);
    WHDraw.shotgun(canvas, cx + 4, cy, 1.3);
    final hpP = (currentHp / maxHp).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 38, -30, 76 * hpP, 9), Paint()..color = const Color(0xFFFF8A65));
  }
}

class Boss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  late int maxHp, currentHp;
  double attackTimer = 0;
  Boss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(112, 122), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    maxHp = 220 + floor * 90;
    currentHp = maxHp;
    add(CircleHitbox(radius: 48));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final dist = position.distanceTo(game.player.position);
    smartMove(game.player.position, 42 + floor * 5.0, dt, radius: 48);
    pushOutOfWalls(48);
    final interval = dist < 220 ? 1.05 : 1.9;
    attackTimer += dt;
    if (attackTimer >= interval) {
      attackTimer = 0;
      for (int i = 0; i < 8; i++) {
        final a = (i / 8) * 2 * pi;
        game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
      }
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    if (currentHp <= 0) {
      removeFromParent();
      game.onEnemyKilled();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 18;
      stuckTimer = 0.75;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.hereticBoss(canvas, cx, cy, 1.5);
    final hpP = (currentHp / maxHp).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 46, -34, 92 * hpP, 11), Paint()..color = const Color(0xFFE53935));
  }
}

class KnightBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  final int floor;
  late int maxHp, currentHp;
  double meleeTimer = 0;
  KnightBoss({required this.floor, required Vector2 position})
      : super(position: position, size: Vector2(105, 115), anchor: Anchor.center, priority: 25);

  @override
  Future<void> onLoad() async {
    maxHp = 280 + floor * 100;
    currentHp = maxHp;
    add(CircleHitbox(radius: 46));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final dist = position.distanceTo(game.player.position);
    smartMove(game.player.position, 78 + floor * 8.0, dt, radius: 46);
    pushOutOfWalls(46);
    final interval = dist < 130 ? 0.4 : 0.8;
    meleeTimer += dt;
    if (meleeTimer >= interval && dist < 110) {
      meleeTimer = 0;
      game.player.takeDamage(2);
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    if (currentHp <= 0) {
      removeFromParent();
      game.onEnemyKilled();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 18;
      stuckTimer = 0.75;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    WHDraw.knightBoss(canvas, cx, cy, 1.45);
    final hpP = (currentHp / maxHp).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 44, -32, 88 * hpP, 10), Paint()..color = const Color(0xFF78909C));
  }
}

class KingBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  late int maxHp, currentHp, phaseHp;
  int phase = 1;
  double meleeTimer = 0, phase2Timer = 0;
  int phase2VolleyCount = 0;
  KingBoss({required Vector2 position})
      : super(position: position, size: Vector2(140, 150), anchor: Anchor.center, priority: 26);

  @override
  Future<void> onLoad() async {
    phaseHp = 400;
    maxHp = phaseHp * 2;
    currentHp = maxHp;
    add(CircleHitbox(radius: 58));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    final dist = position.distanceTo(game.player.position);
    smartMove(game.player.position, phase == 1 ? 100.0 : 38.0, dt, radius: 58);
    pushOutOfWalls(58);
    if (phase == 1) {
      final interval = dist < 140 ? 0.38 : 0.65;
      meleeTimer += dt;
      if (meleeTimer >= interval && dist < 115) {
        meleeTimer = 0;
        game.player.takeDamage(3);
      }
    } else {
      phase2Timer += dt;
      if (phase2VolleyCount > 0) {
        if (phase2Timer >= 0.35) {
          phase2Timer = 0;
          _volley();
          phase2VolleyCount--;
        }
      } else if (phase2Timer >= 3.0) {
        phase2Timer = 0;
        phase2VolleyCount = 2;
        _volley();
      }
    }
  }

  void _volley() {
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * pi;
      game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
    }
  }

  void takeDamage(int amount) {
    if (game.areOtherBossesAlive) return;
    currentHp -= amount;
    if (currentHp <= 0) {
      removeFromParent();
      game.onEnemyKilled();
      return;
    }
    if (phase == 1 && currentHp <= phaseHp) {
      phase = 2;
      phase2Timer = 0;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 20;
      stuckTimer = 0.85;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;
    final inv = game.areOtherBossesAlive;
    WHDraw.kingBossDraw(canvas, cx, cy, 1.55);
    if (inv) {
      canvas.drawCircle(Offset(cx, cy), 66, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 4);
    }
    final p2 = ((currentHp - phaseHp).clamp(0, phaseHp)) / phaseHp;
    final p1 = (currentHp.clamp(0, phaseHp)) / phaseHp;
    canvas.drawRect(Rect.fromLTWH(cx - 55, -56, 110 * p2, 9), Paint()..color = const Color(0xFFFFD700));
    canvas.drawRect(Rect.fromLTWH(cx - 55, -44, 110 * p1, 9), Paint()..color = const Color(0xFFE53935));
  }
}

class TentacleBoss extends PositionComponent with HasGameReference<InquisitorGame>, CollisionCallbacks, SmartMover {
  static const int maxHpConst = 6666;
  int currentHp = maxHpConst;
  int phase = 1;
  double phaseTimer = 0, anim = 0;
  int meleeHitsLeft = 0;
  double meleeGap = 0;
  TentacleBoss({required Vector2 position})
      : super(position: position, size: Vector2(150, 150), anchor: Anchor.center, priority: 28);

  @override
  Future<void> onLoad() async => add(CircleHitbox(radius: 58));

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying || game.isPaused) return;
    anim += dt;
    final dist = position.distanceTo(game.player.position);
    smartMove(game.player.position, phase == 1 ? 45.0 : 30.0, dt, radius: 58);
    pushOutOfWalls(58);
    if (phase == 1) {
      phaseTimer += dt;
      if (phaseTimer >= 1.8) {
        phaseTimer = 0;
        for (int i = 0; i < 12; i++) {
          final a = (i / 12) * 2 * pi + anim * 0.3;
          game.world.add(BossProjectile(position: position.clone(), direction: Vector2(cos(a), sin(a)))..priority = 22);
        }
      }
      if (currentHp <= maxHpConst ~/ 2) {
        phase = 2;
        phaseTimer = 0;
        meleeHitsLeft = 6;
        meleeGap = 0;
      }
    } else {
      if (meleeHitsLeft > 0) {
        meleeGap += dt;
        if (meleeGap >= 0.55) {
          meleeGap = 0;
          meleeHitsLeft--;
          game.world.add(TentacleSlam(position: position.clone(), radius: game.cellSize * 2.2)..priority = 27);
          if (dist < game.cellSize * 2.2 + 35) game.player.takeDamage(2);
        }
      } else {
        phaseTimer += dt;
        if (phaseTimer >= 2.2) {
          phaseTimer = 0;
          meleeHitsLeft = 6;
          meleeGap = 0;
        }
      }
    }
  }

  void takeDamage(int amount) {
    currentHp -= amount;
    if (currentHp <= 0) {
      currentHp = 0;
      removeFromParent();
      game.onSecretBossKilled();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall || other is Obstacle) {
      position += (position - intersectionPoints.first).normalized() * 20;
      stuckTimer = 0.85;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2, t = anim;
    for (int i = 0; i < 8; i++) {
      final baseA = (i / 8) * 2 * pi + t * 0.6;
      final wave = sin(t * 3 + i) * 20;
      final path = Path()..moveTo(cx, cy);
      for (int s = 1; s <= 6; s++) {
        final f = s / 6;
        final ang = baseA + sin(t * 2 + s * 0.4 + i) * 0.35;
        path.lineTo(cx + cos(ang) * (30 + f * 60 + wave * f), cy + sin(ang) * (30 + f * 60 + wave * f));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(const Color(0xFF1A0033), const Color(0xFF4A148C), 0.4 + 0.3 * sin(t + i))!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 76, height: 68), Paint()..color = const Color(0xFF12001F));
    canvas.drawCircle(Offset(cx, cy - 6), 15, Paint()..color = const Color(0xFF0D0D0D));
    canvas.drawCircle(Offset(cx, cy - 6), 10, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(cx + 3, cy - 8), 3.5, Paint()..color = Colors.white);
    final hpP = (currentHp / maxHpConst).clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(cx - 58, -38, 116 * hpP, 12), Paint()..color = phase == 1 ? const Color(0xFF9C27B0) : const Color(0xFFFF1744));
  }
}

class TentacleSlam extends CircleComponent {
  double life = 0.35;
  TentacleSlam({required Vector2 position, required double radius})
      : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF9C27B0).withOpacity(0.35),
          priority: 27,
        );

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    paint.color = Color.fromRGBO(156, 39, 176, (life / 0.35 * 0.4).clamp(0.0, 0.4));
    if (life <= 0) removeFromParent();
  }
}
