import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/assets.dart';

/// El producto vuela por una curva de Bézier cuadrática hasta la burbuja
/// (680 ms, `cubic-bezier(.45,.05,.4,1)`): escala del tamaño de la imagen a
/// 44 px y gira 22°.
class FlyAnimator {
  static void fly({
    required OverlayState overlay,
    required Rect from,
    required Offset to,
    required double toSize,
    required String productId,
    required VoidCallback onComplete,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (context) => _FlyWidget(
            from: from,
            to: to,
            toSize: toSize,
            productId: productId,
            onEnd: () {
              entry.remove();
              onComplete();
            },
          ),
    );
    overlay.insert(entry);
  }
}

class _FlyWidget extends StatefulWidget {
  const _FlyWidget({
    required this.from,
    required this.to,
    required this.toSize,
    required this.productId,
    required this.onEnd,
  });

  final Rect from;
  final Offset to;
  final double toSize;
  final String productId;
  final VoidCallback onEnd;

  @override
  State<_FlyWidget> createState() => _FlyWidgetState();
}

class _FlyWidgetState extends State<_FlyWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: const Cubic(.45, .05, .4, 1),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) => widget.onEnd());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p0 = widget.from.center;
    final p2 = widget.to;
    final s0 = math.min(widget.from.width, 120.0);
    final cx = (p0.dx + p2.dx) / 2 + (p2.dx > p0.dx ? -40 : 40);
    final cy = math.min(p0.dy, p2.dy) - 140;
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final t = _a.value;
        final u = 1 - t;
        final x = u * u * p0.dx + 2 * u * t * cx + t * t * p2.dx;
        final y = u * u * p0.dy + 2 * u * t * cy + t * t * p2.dy;
        final size = s0 + (widget.toSize - s0) * t;
        return Positioned(
          left: x - size / 2,
          top: y - size / 2,
          width: size,
          height: size,
          child: IgnorePointer(
            child: Opacity(
              opacity: _c.value > 0.97 ? .6 : 1,
              child: Transform.rotate(
                angle: t * 22 * math.pi / 180,
                child: Image.asset(
                  CaAssets.product(widget.productId),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
