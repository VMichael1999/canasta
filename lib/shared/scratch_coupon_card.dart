import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/haptics.dart';
import '../core/tokens.dart';

class ScratchCouponCard extends StatefulWidget {
  const ScratchCouponCard({
    super.key,
    required this.isScratched,
    required this.onScratched,
    required this.onApply,
  });

  final bool isScratched;
  final VoidCallback onScratched;
  final VoidCallback onApply;

  @override
  State<ScratchCouponCard> createState() => _ScratchCouponCardState();
}

class _ScratchCouponCardState extends State<ScratchCouponCard> {
  final List<Offset> _scratchPoints = [];
  bool _revealed = false;
  double _scratchedFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _revealed = widget.isScratched;
  }

  void _addPoint(Offset localPos, Size size) {
    if (_revealed) return;
    setState(() {
      _scratchPoints.add(localPos);
    });

    // Approximate scratch percentage based on sample points density
    final totalArea = size.width * size.height;
    final scratchedAreaEstimate = _scratchPoints.length * (46.0 * 20.0);
    _scratchedFraction = (scratchedAreaEstimate / totalArea).clamp(0.0, 1.0);

    if (_scratchedFraction > 0.45 && !_revealed) {
      _revealed = true;
      CaHaptics.heavyImpact();
      widget.onScratched();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      height: 94,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6), // Crema
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE8A3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Revealed content under scratch layer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEBA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🎉', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Cupón del día · 10 % dscto',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'CANASTA10',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F1324),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Usar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            // Silver scratch foil overlay (if not revealed)
            if (!_revealed)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanDown: (d) => _addPoint(d.localPosition, constraints.biggest),
                      onPanUpdate: (d) => _addPoint(d.localPosition, constraints.biggest),
                      child: CustomPaint(
                        size: constraints.biggest,
                        painter: _ScratchPainter(points: _scratchPoints),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                'Raspa aquí para tu cupón diario',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.ink2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  _ScratchPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Silver foil base
    final foilPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [
          const Color(0xFFD6DAE3),
          const Color(0xFFF1F3F7),
          const Color(0xFFCBD1DC),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), foilPaint);

    // Clear scratched paths
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 46.0;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 23.0, clearPaint);
      if (i > 0) {
        canvas.drawLine(points[i - 1], points[i], clearPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchPainter oldDelegate) => true;
}
