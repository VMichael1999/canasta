import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/haptics.dart';
import '../core/tokens.dart';
import 'app_svg_icon.dart';

/// Cupón del día (.cp): tarjeta crema cubierta por una capa plateada que se
/// raspa con el dedo (trazo de 46 px). Al descubrir más del 50 % la capa se
/// desvanece, vibra y aparece «Usar».
class ScratchCouponCard extends StatefulWidget {
  const ScratchCouponCard({
    super.key,
    required this.isScratched,
    required this.onScratched,
    required this.onApply,
    this.isApplied = false,
  });

  final bool isScratched;
  final bool isApplied;
  final VoidCallback onScratched;
  final VoidCallback onApply;

  @override
  State<ScratchCouponCard> createState() => _ScratchCouponCardState();
}

class _ScratchCouponCardState extends State<ScratchCouponCard>
    with SingleTickerProviderStateMixin {
  static const double _cell = 6;
  final List<List<Offset>> _strokes = [];
  List<bool>? _grid;
  int _cols = 0, _rows = 0, _cleared = 0;
  bool _touched = false;
  bool _revealed = false;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void initState() {
    super.initState();
    _revealed = widget.isScratched;
    if (_revealed) _fade.value = 1;
  }

  @override
  void didUpdateWidget(ScratchCouponCard old) {
    super.didUpdateWidget(old);
    if (widget.isScratched && !_revealed) {
      _revealed = true;
      _fade.value = 1;
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _ensureGrid(Size size) {
    if (_grid != null) return;
    _cols = (size.width / _cell).ceil();
    _rows = (size.height / _cell).ceil();
    _grid = List<bool>.filled(_cols * _rows, false);
  }

  void _mark(Offset p, Size size) {
    _ensureGrid(size);
    const r = 23.0;
    final x0 = math.max(0, ((p.dx - r) / _cell).floor());
    final x1 = math.min(_cols - 1, ((p.dx + r) / _cell).floor());
    final y0 = math.max(0, ((p.dy - r) / _cell).floor());
    final y1 = math.min(_rows - 1, ((p.dy + r) / _cell).floor());
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final c = Offset((x + .5) * _cell, (y + .5) * _cell);
        if ((c - p).distance <= r && !_grid![y * _cols + x]) {
          _grid![y * _cols + x] = true;
          _cleared++;
        }
      }
    }
  }

  void _segment(Offset a, Offset b, Size size) {
    final d = (b - a).distance;
    final n = math.max(1, (d / 8).ceil());
    for (var i = 0; i <= n; i++) {
      _mark(Offset.lerp(a, b, i / n)!, size);
    }
  }

  void _checkReveal() {
    if (_revealed || _grid == null) return;
    if (_cleared / (_cols * _rows) > .5) {
      _revealed = true;
      HapticFeedback.vibrate();
      CaHaptics.mediumImpact();
      _fade.forward().then((_) => widget.onScratched());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      height: 76,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          // 110deg
          begin: Alignment(-.94, -.34),
          end: Alignment(.94, .34),
          colors: [Color(0xFFFFF6E5), Color(0xFFFFEBC7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF7DDAB), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon('gift',
                          size: 20, color: Color(0xFFC77700)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cupón del día',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF8A6A2F),
                            ),
                          ),
                          Text(
                            'CANASTA10 · 10 % dscto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5A3C00),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_revealed && widget.isApplied)
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: tokens.greenSoft,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Aplicado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.green,
                          ),
                        ),
                      )
                    else if (_revealed)
                      GestureDetector(
                        onTap: widget.onApply,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: tokens.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Usar',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // capa plateada
            if (!widget.isScratched || _fade.value < 1)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _fade,
                  builder: (context, _) {
                    if (_fade.value >= 1) return const SizedBox.shrink();
                    return Opacity(
                      opacity: 1 - _fade.value,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final size = c.biggest;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanDown: (d) {
                              if (_revealed) return;
                              setState(() {
                                _touched = true;
                                _strokes.add([d.localPosition]);
                                _mark(d.localPosition, size);
                              });
                            },
                            onPanUpdate: (d) {
                              if (_revealed || _strokes.isEmpty) return;
                              setState(() {
                                final last = _strokes.last.last;
                                _strokes.last.add(d.localPosition);
                                _segment(last, d.localPosition, size);
                              });
                              _checkReveal();
                            },
                            onPanEnd: (_) => _checkReveal(),
                            child: CustomPaint(
                              size: size,
                              painter: _ScratchPainter(strokes: _strokes),
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _touched ? 0 : 1,
                                  child: const Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppSvgIcon('scratch',
                                            size: 20,
                                            color: Color(0xFF3D4A6E)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Raspa para descubrir tu cupón',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF3D4A6E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
  _ScratchPainter({required this.strokes});

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          const [Color(0xFFC9D3E6), Color(0xFFE8EDF6), Color(0xFFB9C5DC)],
          const [0, .5, 1],
        ),
    );
    // destellos (260 puntos de 2 px a 35 % de blanco)
    final rnd = math.Random(7);
    final sparkle = Paint()..color = const Color(0x59FFFFFF);
    for (var i = 0; i < 130; i++) {
      canvas.drawRect(
        Rect.fromLTWH(rnd.nextDouble() * size.width,
            rnd.nextDouble() * size.height, 1, 1),
        sparkle,
      );
    }

    final clear = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 46;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 23, Paint()..blendMode = BlendMode.clear);
      } else {
        final path = Path()..moveTo(s.first.dx, s.first.dy);
        for (final p in s.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, clear);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchPainter old) => true;
}
