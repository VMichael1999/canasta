import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/assets.dart';

/// Mapa ilustrado (port del SVG `MAPSVG` del HTML): viewBox 400×400 con
/// `preserveAspectRatio="xMidYMid slice"`.
class MapGeo {
  static const double box = 400;

  /// Ruta del repartidor (M70 300 L130 300 L150 250 L230 250 L250 190 L320 182 L338 128).
  static const List<Offset> routePts = [
    Offset(70, 300),
    Offset(130, 300),
    Offset(150, 250),
    Offset(230, 250),
    Offset(250, 190),
    Offset(320, 182),
    Offset(338, 128),
  ];

  static Path routePath() {
    final p = Path()..moveTo(routePts.first.dx, routePts.first.dy);
    for (final o in routePts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  static double get routeLength {
    var l = 0.0;
    for (var i = 1; i < routePts.length; i++) {
      l += (routePts[i] - routePts[i - 1]).distance;
    }
    return l;
  }

  /// Punto (y si va hacia la izquierda) a lo largo de la ruta.
  static (Offset, bool) at(double rp) {
    final total = routeLength;
    var d = rp.clamp(0.0, 1.0) * total;
    for (var i = 1; i < routePts.length; i++) {
      final seg = (routePts[i] - routePts[i - 1]).distance;
      if (d <= seg || i == routePts.length - 1) {
        final t = seg == 0 ? 0.0 : (d / seg).clamp(0.0, 1.0);
        final pt = Offset.lerp(routePts[i - 1], routePts[i], t)!;
        // dirección ligeramente adelante (pt2 del HTML)
        final ahead = math.min(total, rp * total + 2);
        var dd = ahead;
        Offset pt2 = pt;
        for (var j = 1; j < routePts.length; j++) {
          final s = (routePts[j] - routePts[j - 1]).distance;
          if (dd <= s || j == routePts.length - 1) {
            pt2 = Offset.lerp(routePts[j - 1], routePts[j],
                s == 0 ? 0.0 : (dd / s).clamp(0.0, 1.0))!;
            break;
          }
          dd -= s;
        }
        return (pt, pt2.dx < pt.dx);
      }
      d -= seg;
    }
    return (routePts.last, false);
  }
}

class IllustratedMap extends StatelessWidget {
  const IllustratedMap({
    super.key,
    this.progress = 0.5,
    this.distanceKm = 1.4,
    this.showExpandButton = true,
    this.onExpand,
    this.showRoute = true,
    this.showMarker = true,
    this.opacity = 1,
    this.bigMarker = false,
    this.kmLabel,
    this.zoom,
    this.cameraTarget,
    this.cameraAnchor = const Offset(220, 400),
    this.radius = 0,
    this.mapChild,
  });

  /// Si se define, reemplaza el dibujo ilustrado (p. ej. un mapa de Google).
  final Widget? mapChild;

  /// Avance de la ruta (0..1).
  final double progress;
  final double distanceKm;
  final bool showExpandButton;
  final VoidCallback? onExpand;
  final bool showRoute;
  final bool showMarker;
  final double opacity;
  final bool bigMarker;

  /// Texto de la pastilla de distancia; null = sin pastilla.
  final String? kmLabel;

  /// Si se define, el mapa se dibuja a `zoom`× y la cámara sigue a la moto.
  final double? zoom;
  final Offset? cameraTarget;
  final Offset cameraAnchor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: LayoutBuilder(
        builder: (context, c) {
          final size = c.biggest;
          final marker = MapGeo.at(progress);
          // transformación viewBox → pantalla
          late double s;
          late Offset origin;
          if (zoom != null) {
            s = zoom!;
            origin = Offset(
              cameraAnchor.dx - marker.$1.dx * s,
              cameraAnchor.dy - marker.$1.dy * s,
            );
          } else {
            s = math.max(size.width, size.height) / MapGeo.box;
            origin = Offset(
              (size.width - MapGeo.box * s) / 2,
              (size.height - MapGeo.box * s) / 2,
            );
          }
          Offset toScreen(Offset p) => origin + p * s;
          final mp = toScreen(marker.$1);
          final r = (bigMarker ? 22.0 : 18.0) * s;
          final w = (bigMarker ? 40.0 : 32.0) * s;
          final h = (bigMarker ? 30.0 : 24.0) * s;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (mapChild != null) Positioned.fill(child: mapChild!),
              if (mapChild == null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPainter(
                    scale: s,
                    origin: origin,
                    progress: progress,
                    showRoute: showRoute,
                    opacity: opacity,
                    showHome: showRoute,
                  ),
                ),
              ),
              if (showMarker && mapChild == null)
                Positioned(
                  left: mp.dx - r,
                  top: mp.dy - r,
                  width: r * 2,
                  height: r * 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFE3E8F2), width: math.max(1, s)),
                    ),
                    alignment: Alignment.center,
                    child: Transform.flip(
                      flipX: marker.$2,
                      child: Image.asset(
                        CaAssets.scooter,
                        width: w,
                        height: h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              if (kmLabel != null)
                Positioned(
                  left: size.width * .52,
                  top: 36,
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x050F1324),
                          offset: Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Color(0x470F1324),
                          blurRadius: 24,
                          spreadRadius: -18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      kmLabel!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1324),
                        height: 1,
                      ),
                    ),
                  ),
                ),
              if (showExpandButton)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: GestureDetector(
                    onTap: onExpand,
                    child: Semantics(
                      button: true,
                      label: 'Ver mapa en pantalla completa',
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x050F1324),
                              offset: Offset(0, 1),
                            ),
                            BoxShadow(
                              color: Color(0x470F1324),
                              blurRadius: 24,
                              spreadRadius: -18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const _ExpandIcon(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpandIcon extends StatelessWidget {
  const _ExpandIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(18, 18), painter: _ExpandPainter());
  }
}

class _ExpandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF0F1324)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.scale(size.width / 24);
    final path = Path()
      ..moveTo(14, 4.5)
      ..lineTo(19.5, 4.5)
      ..lineTo(19.5, 10)
      ..moveTo(19.5, 4.5)
      ..lineTo(13.5, 10.5)
      ..moveTo(10, 19.5)
      ..lineTo(4.5, 19.5)
      ..lineTo(4.5, 14)
      ..moveTo(4.5, 19.5)
      ..lineTo(10.5, 13.5);
    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.scale,
    required this.origin,
    required this.progress,
    required this.showRoute,
    required this.opacity,
    required this.showHome,
  });

  final double scale;
  final Offset origin;
  final double progress;
  final bool showRoute;
  final double opacity;
  final bool showHome;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    if (opacity < 1) {
      canvas.saveLayer(
        Rect.fromLTWH(-2000, -2000, 5000, 5000),
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }

    // el fondo cubre todo el recorte (más allá del viewBox)
    final bg = Paint()..color = const Color(0xFFEEF1F5);
    canvas.drawRect(Rect.fromLTWH(-2000, -2000, 5000, 5000), bg);

    // río
    final river = Path()
      ..moveTo(330, -10)
      ..cubicTo(300, 80, 360, 150, 330, 230)
      ..cubicTo(300, 310, 360, 360, 340, 420) // S → reflejo del control
      ..lineTo(420, 420)
      ..lineTo(420, -10)
      ..close();
    canvas.drawPath(river, Paint()..color = const Color(0xFFBFD9F2));

    // manzanas
    final block = Paint()..color = const Color(0xFFE3E7ED);
    for (final b in const [
      [40.0, 30.0, 90.0, 60.0],
      [160.0, 20.0, 70.0, 50.0],
      [30.0, 120.0, 70.0, 70.0],
      [190.0, 100.0, 80.0, 60.0],
      [60.0, 220.0, 60.0, 40.0],
      [180.0, 300.0, 90.0, 70.0],
      [40.0, 330.0, 80.0, 50.0],
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(b[0], b[1], b[2], b[3]), const Radius.circular(6)),
        block,
      );
    }
    // parques
    final park = Paint()..color = const Color(0xFFCDEBC6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(110, 140, 56, 44), const Radius.circular(8)),
        park);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(250, 300, 50, 60), const Radius.circular(8)),
        park);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(20, 260, 34, 40), const Radius.circular(6)),
        park);

    // calles y avenidas
    final st12 = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    for (final l in const [
      [0.0, 90.0, 400.0, 96.0],
      [0.0, 200.0, 330.0, 210.0],
      [0.0, 300.0, 320.0, 300.0],
      [0.0, 380.0, 330.0, 390.0],
    ]) {
      canvas.drawLine(Offset(l[0], l[1]), Offset(l[2], l[3]), st12);
    }
    final st10 = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    for (final l in const [
      [100.0, 0.0, 140.0, 400.0],
      [240.0, 0.0, 260.0, 400.0],
      [170.0, 0.0, 160.0, 400.0],
    ]) {
      canvas.drawLine(Offset(l[0], l[1]), Offset(l[2], l[3]), st10);
    }
    canvas.drawLine(
      const Offset(0, 150),
      const Offset(330, 140),
      Paint()
        ..color = const Color(0xE6FDE7B0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    if (showRoute) {
      final route = MapGeo.routePath();
      final blue = Paint()
        ..color = const Color(0xFF1A4FE0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      // ruta completa tenue
      canvas.drawPath(
          route, blue..color = const Color(0xFF1A4FE0).withValues(alpha: .25));
      // tramo que falta (desde la moto hasta la casa), sólido
      final metrics = route.computeMetrics().first;
      final from = progress.clamp(0.0, 1.0) * metrics.length;
      canvas.drawPath(
        metrics.extractPath(from, metrics.length),
        blue..color = const Color(0xFF1A4FE0),
      );
      // origen
      canvas.drawCircle(const Offset(70, 300), 9, Paint()..color = Colors.white);
      canvas.drawCircle(
        const Offset(70, 300),
        9,
        Paint()
          ..color = const Color(0xFF1A4FE0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    if (showHome) {
      canvas.save();
      canvas.translate(338, 128);
      canvas.drawCircle(Offset.zero, 16,
          Paint()..color = const Color(0xFF1E9E5A).withValues(alpha: .18));
      canvas.drawCircle(Offset.zero, 9, Paint()..color = const Color(0xFF1E9E5A));
      final house = Path()
        ..moveTo(-4, 1)
        ..relativeLineTo(0, -4)
        ..relativeLineTo(4, -3)
        ..relativeLineTo(4, 3)
        ..relativeLineTo(0, 4)
        ..close();
      canvas.drawPath(house, Paint()..color = Colors.white);
      canvas.restore();
    }

    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.progress != progress ||
      old.scale != scale ||
      old.origin != origin ||
      old.showRoute != showRoute ||
      old.opacity != opacity;
}

