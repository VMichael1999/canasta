import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/tokens.dart';

class IllustratedMap extends StatelessWidget {
  const IllustratedMap({
    super.key,
    required this.progress, // 0..1
    this.distanceKm = 1.4,
    this.showExpandButton = true,
    this.onExpand,
  });

  final double progress;
  final double distanceKm;
  final bool showExpandButton;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Base custom map drawing
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPainter(progress: progress, tokens: tokens),
            ),
          ),

          // Scooter overlay on animated position
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final routePoints = _MapPainter.getRoute(constraints.biggest);
                final currentPos = _calculatePositionAlongPath(routePoints, progress);

                return Stack(
                  children: [
                    // Scooter icon
                    Positioned(
                      left: currentPos.dx - 18,
                      top: currentPos.dy - 18,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.blue,
                          boxShadow: [
                            BoxShadow(
                              color: tokens.blue.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(
                          CaAssets.scooter,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Destination House Pin
                    if (routePoints.isNotEmpty)
                      Positioned(
                        left: routePoints.last.dx - 15,
                        top: routePoints.last.dy - 15,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.green,
                            boxShadow: [
                              BoxShadow(
                                color: tokens.green.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.home_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Distance Pill: "A 1.4 km"
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.blue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'A ${distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expand Button
          if (showExpandButton)
            Positioned(
              top: 14,
              right: 14,
              child: GestureDetector(
                onTap: onExpand,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.fullscreen_rounded,
                    size: 20,
                    color: tokens.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Offset _calculatePositionAlongPath(List<Offset> points, double progress) {
    if (points.isEmpty) return const Offset(100, 100);
    if (points.length == 1) return points.first;
    if (progress <= 0) return points.first;
    if (progress >= 1) return points.last;

    // Calculate total length
    double totalLength = 0;
    final segmentLengths = <double>[];
    for (int i = 0; i < points.length - 1; i++) {
      final len = (points[i + 1] - points[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    final targetDist = totalLength * progress;
    double accumulated = 0;
    for (int i = 0; i < segmentLengths.length; i++) {
      final segLen = segmentLengths[i];
      if (accumulated + segLen >= targetDist) {
        final remaining = targetDist - accumulated;
        final segFrac = (remaining / segLen).clamp(0.0, 1.0);
        return Offset.lerp(points[i], points[i + 1], segFrac)!;
      }
      accumulated += segLen;
    }
    return points.last;
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.progress, required this.tokens});

  final double progress;
  final CaTokens tokens;

  static List<Offset> getRoute(Size size) {
    final w = size.width;
    final h = size.height;
    return [
      Offset(w * 0.15, h * 0.25),
      Offset(w * 0.35, h * 0.25),
      Offset(w * 0.35, h * 0.60),
      Offset(w * 0.70, h * 0.60),
      Offset(w * 0.70, h * 0.80),
      Offset(w * 0.85, h * 0.80),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background terrain
    final bgPaint = Paint()..color = const Color(0xFFF3F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Green parks
    final parkPaint = Paint()..color = const Color(0xFFE5F5EB);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.1, w * 0.35, h * 0.35),
        const Radius.circular(16),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.65, w * 0.22, h * 0.25),
        const Radius.circular(14),
      ),
      parkPaint,
    );

    // City grid streets
    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Horizontal streets
    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), streetPaint);
    canvas.drawLine(Offset(0, h * 0.60), Offset(w, h * 0.60), streetPaint);
    canvas.drawLine(Offset(0, h * 0.80), Offset(w, h * 0.80), streetPaint);

    // Vertical streets
    canvas.drawLine(Offset(w * 0.35, 0), Offset(w * 0.35, h), streetPaint);
    canvas.drawLine(Offset(w * 0.70, 0), Offset(w * 0.70, h), streetPaint);

    // Route Polyline
    final routePoints = getRoute(size);
    final routePath = Path();
    routePath.moveTo(routePoints.first.dx, routePoints.first.dy);
    for (int i = 1; i < routePoints.length; i++) {
      routePath.lineTo(routePoints[i].dx, routePoints[i].dy);
    }

    final routeBgPaint = Paint()
      ..color = tokens.blue.withValues(alpha: 0.2)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, routeBgPaint);

    final routeActivePaint = Paint()
      ..color = tokens.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, routeActivePaint);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
