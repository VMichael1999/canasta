import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pin de destino de Canasta: gota azul con degradado, anillo blanco, casita
/// en el centro y sombra elíptica en el suelo. La punta queda exactamente en la
/// coordenada: usar `anchor: PinIcon.anchor`.
class PinIcon {
  static const double _w = 56, _h = 72, _tipY = 60;
  static const Offset anchor = Offset(.5, _tipY / _h);
  static BitmapDescriptor? _cache;

  static Future<BitmapDescriptor> load() async {
    if (_cache != null) return _cache!;
    const double s = 3;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(s);
    const cx = _w / 2;

    // sombra en el suelo (centrada en la punta)
    c.drawOval(
      Rect.fromCenter(center: const Offset(cx, _tipY), width: 26, height: 9),
      Paint()
        ..color = const Color(0x590A1E5A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );

    // gota (punta en cx, _tipY)
    final body = Path()
      ..moveTo(cx, _tipY)
      ..cubicTo(cx, _tipY, cx - 21, _tipY - 21, cx - 21, 24)
      ..arcToPoint(const Offset(cx + 21, 24), radius: const Radius.circular(21), clockwise: true)
      ..cubicTo(cx + 21, _tipY - 21, cx, _tipY, cx, _tipY)
      ..close();
    final rect = Rect.fromLTWH(cx - 21, 3, 42, _tipY - 3);
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F7CFF), Color(0xFF1A4FE0), Color(0xFF123BB0)],
        ).createShader(rect),
    );
    c.drawPath(
      body,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    // brillo
    c.drawOval(
      Rect.fromLTWH(cx - 14, 8, 14, 8),
      Paint()..color = const Color(0x40FFFFFF),
    );
    // disco blanco + casita
    c.drawCircle(const Offset(cx, 24), 12.5, Paint()..color = Colors.white);
    final house = Path()
      ..moveTo(cx - 7, 25)
      ..lineTo(cx, 18)
      ..lineTo(cx + 7, 25)
      ..lineTo(cx + 7, 31)
      ..lineTo(cx + 2.4, 31)
      ..lineTo(cx + 2.4, 26.5)
      ..lineTo(cx - 2.4, 26.5)
      ..lineTo(cx - 2.4, 31)
      ..lineTo(cx - 7, 31)
      ..close();
    c.drawPath(house, Paint()..color = const Color(0xFF1A4FE0));

    final img = await rec.endRecording().toImage((_w * s).round(), (_h * s).round());
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    _cache = BitmapDescriptor.bytes(bytes, width: _w, height: _h);
    return _cache!;
  }
}
