import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/haptics.dart';

class FlyAnimator {
  static void flyToBubble({
    required BuildContext context,
    required GlobalKey sourceKey,
    required String productId,
    required Offset targetOffset,
    VoidCallback? onComplete,
  }) {
    final renderBox = sourceKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      onComplete?.call();
      return;
    }

    final startOffset = renderBox.localToGlobal(Offset.zero);
    final startSize = renderBox.size;
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyWidget(
        startOffset: startOffset,
        startSize: startSize,
        targetOffset: targetOffset,
        productId: productId,
        onAnimationEnd: () {
          entry.remove();
          CaHaptics.lightImpact();
          onComplete?.call();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _FlyWidget extends StatefulWidget {
  const _FlyWidget({
    required this.startOffset,
    required this.startSize,
    required this.targetOffset,
    required this.productId,
    required this.onAnimationEnd,
  });

  final Offset startOffset;
  final Size startSize;
  final Offset targetOffset;
  final String productId;
  final VoidCallback onAnimationEnd;

  @override
  State<_FlyWidget> createState() => _FlyWidgetState();
}

class _FlyWidgetState extends State<_FlyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.45, 0.05, 0.4, 1.0),
    );

    _controller.forward().then((_) {
      widget.onAnimationEnd();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final p0 = Offset(
      widget.startOffset.dx + widget.startSize.width / 2 - 22,
      widget.startOffset.dy + widget.startSize.height / 2 - 22,
    );
    final p2 = widget.targetOffset;
    final minTop = math.min(p0.dy, p2.dy);
    final p1 = Offset((p0.dx + p2.dx) / 2, minTop - 140);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        final currentPos = _quadraticBezier(p0, p1, p2, t);
        final currentScale = 1.0 - t * 0.45;
        final currentAngle = (22 * math.pi / 180) * math.sin(t * math.pi);

        return Positioned(
          left: currentPos.dx,
          top: currentPos.dy,
          child: Transform.rotate(
            angle: currentAngle,
            child: Transform.scale(
              scale: currentScale,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
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
