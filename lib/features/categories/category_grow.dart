import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Transición «hero» del HTML (`.grow`): la imagen de la tarjeta de categoría
/// crece desde su lugar hasta la cabecera (0,0 · ancho × 270) de la lista.
///
/// [onCovered] se llama cuando la imagen ya llenó la cabecera (momento de
/// abrir la lista); después el overlay se desvanece y se elimina solo.
class CategoryGrow {
  CategoryGrow._();

  static void run(
    BuildContext context, {
    required Rect from,
    required Rect artTo,
    required Widget art,
    required VoidCallback onCovered,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final width = MediaQuery.of(context).size.width;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => _Grow(
            from: from,
            to: Rect.fromLTWH(0, 0, width, 270),
            artTo: artTo,
            art: art,
            onCovered: onCovered,
            onDone: () => entry.remove(),
          ),
    );
    overlay.insert(entry);
  }
}

class _Grow extends StatefulWidget {
  const _Grow({
    required this.from,
    required this.to,
    required this.artTo,
    required this.art,
    required this.onCovered,
    required this.onDone,
  });

  final Rect from, to, artTo;
  final Widget art;
  final VoidCallback onCovered, onDone;

  @override
  State<_Grow> createState() => _GrowState();
}

class _GrowState extends State<_Grow> with TickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  static const _curve = Cubic(.5, 0, .15, 1);

  @override
  void initState() {
    super.initState();
    _grow.forward().whenComplete(() async {
      if (!mounted) return;
      widget.onCovered();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      await _fade.forward();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _grow.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_grow, _fade]),
      builder: (context, _) {
        final t = _curve.transform(_grow.value);
        final r = Rect.lerp(widget.from, widget.to, t)!;
        final art = Rect.lerp(widget.from, widget.artTo, t)!;
        return Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 1 - _fade.value,
              child: Stack(
                children: [
                  // El fondo se difumina y se aclara; solo viajan los productos.
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: 10 * t,
                        sigmaY: 10 * t,
                      ),
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: .94 * t),
                      ),
                    ),
                  ),
                  Positioned.fromRect(rect: art, child: widget.art),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
