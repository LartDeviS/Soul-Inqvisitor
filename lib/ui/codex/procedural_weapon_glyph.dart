import 'package:flutter/material.dart';
import '../../game/weapons/weapon_data.dart';

/// Tiny vector weapon silhouette. It is generated from code and requires no texture assets.
class ProceduralWeaponGlyph extends StatelessWidget {
  final WeaponOrdo ordo; final DamageType damageType; final double size;
  const ProceduralWeaponGlyph({super.key,required this.ordo,required this.damageType,this.size=36});
  @override Widget build(BuildContext context)=>SizedBox(width:size,height:size,child:CustomPaint(painter:_WeaponGlyphPainter(ordo,damageType)));
}
class _WeaponGlyphPainter extends CustomPainter {
  final WeaponOrdo ordo; final DamageType type; const _WeaponGlyphPainter(this.ordo,this.type);
  @override void paint(Canvas canvas,Size size){
    final accent=switch(ordo){WeaponOrdo.malleus=>const Color(0xFFB388FF),WeaponOrdo.hereticus=>const Color(0xFFFF7043),WeaponOrdo.xenos=>const Color(0xFF80CBC4),WeaponOrdo.common=>const Color(0xFFFFD54F)};
    final metal=Paint()..color=const Color(0xFF687078)..style=PaintingStyle.fill;
    final trim=Paint()..color=accent..style=PaintingStyle.stroke..strokeWidth=1.6..strokeCap=StrokeCap.round;
    final fill=Paint()..color=accent.withOpacity(.22);
    final w=size.width,h=size.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.08,h*.36,w*.68,h*.28),const Radius.circular(3)),metal);
    canvas.drawRect(Rect.fromLTWH(w*.62,h*.42,w*.31,h*.15),trim);
    canvas.drawRect(Rect.fromLTWH(w*.28,h*.61,w*.14,h*.24),metal);
    canvas.drawRect(Rect.fromLTWH(w*.13,h*.28,w*.20,h*.08),trim);
    canvas.drawCircle(Offset(w*.45,h*.5),w*.075,fill);
    if(type==DamageType.warp||ordo==WeaponOrdo.malleus){final p=Path()..moveTo(w*.45,h*.25)..lineTo(w*.51,h*.37)..lineTo(w*.45,h*.44)..lineTo(w*.39,h*.37)..close();canvas.drawPath(p,trim);}
    if(ordo==WeaponOrdo.hereticus){canvas.drawLine(Offset(w*.22,h*.24),Offset(w*.22,h*.76),trim);canvas.drawLine(Offset(w*.16,h*.31),Offset(w*.28,h*.31),trim);}
  }
  @override bool shouldRepaint(covariant _WeaponGlyphPainter old)=>old.ordo!=ordo||old.type!=type;
}
