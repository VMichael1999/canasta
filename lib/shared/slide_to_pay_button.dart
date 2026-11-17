import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/haptics.dart';
import '../core/money.dart';
import '../core/tokens.dart';
import 'app_svg_icon.dart';

/// Botón deslizable para pagar: arrastra el pulgar hasta el final.
/// Si lo sueltas antes, vuelve con resorte y muestra una pista.
class SlideToPayButton extends StatefulWidget {
  const SlideToPayButton({
    super.key,
    required this.totalAmount,
    required this.paymentMethod,
    required this.onCompleted,
    this.enabled = true,
  });

  final double totalAmount;
  final String paymentMethod;
  final VoidCallback onCompleted;
  final bool enabled;

  @override
  State<SlideToPayButton> createState() => _SlideToPayButtonState();
}

class _SlideToPayButtonState extends State<SlideToPayButton>
    with TickerProviderStateMixin {
  static const double _thumb = 52;
  double _x = 0; // 0..max
  bool _drag = false;
  bool _paying = false;
  String? _hint;
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  String get _payingText {
    if (widget.paymentMethod == 'yape') return 'Aprobando en Yape…';
    if (widget.paymentMethod == 'plin') return 'Aprobando en Plin…';
    return 'Procesando pago…';
  }

  void _end(double max) {
    if (_paying) return;
    if (_x >= max * .88) {
      HapticFeedback.mediumImpact();
      setState(() {
        _paying = true;
        _drag = false;
        _x = max;
        _hint = null;
      });
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) widget.onCompleted();
      });
    } else {
      setState(() {
        _drag = false;
        _x = 0;
        _hint = 'Desliza hasta el final para pagar.';
      });
      Future<void>.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && !_paying) setState(() => _hint = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_hint!, style: TextStyle(fontSize: 13, color: tokens.ink2)),
          ),
        LayoutBuilder(builder: (context, c) {
          final max = c.maxWidth - _thumb - 12;
          final frac = max <= 0 ? 0.0 : (_x / max).clamp(0.0, 1.0);
          final bg = _paying ? tokens.green : tokens.blueSoft;
          return Semantics(
            button: true,
            label: 'Desliza para pagar ${formatPen(widget.totalAmount)}',
            onTap: widget.enabled && !_paying
                ? () {
                    setState(() {
                      _x = max;
                    });
                    _end(max);
                  }
                : null,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: _paying ? tokens.green : const Color(0xFFD3DEFB),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // estela de progreso: degradado azul que sigue al pulgar
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _x + _thumb + 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: _paying
                              ? [tokens.green, const Color(0xFF34C77B)]
                              : const [Color(0xFF1A4FE0), Color(0xFF6C93FF)],
                        ),
                      ),
                    ),
                  ),
                  // título + flechas: una sola línea centrada en el espacio libre
                  Positioned(
                    left: _thumb + 18,
                    right: 18,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _paying
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(_payingText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ],
                            )
                          : Opacity(
                              opacity: (1 - frac * 1.4).clamp(0.0, 1.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Desliza para pagar',
                                        style: TextStyle(
                                          color: Color(0xFF0B2A73),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    const SizedBox(width: 2),
                                    AnimatedBuilder(
                                      animation: _shimmer,
                                      builder: (context, _) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (var i = 0; i < 3; i++)
                                            Opacity(
                                              opacity: reduce
                                                  ? .6
                                                  : (0.25 +
                                                          .75 *
                                                              (1 -
                                                                  (((_shimmer.value * 3) - i) % 3)
                                                                      .abs()
                                                                      .clamp(0.0, 1.0)))
                                                      .clamp(0.25, 1.0),
                                              child: const Icon(
                                                Icons.chevron_right_rounded,
                                                size: 20,
                                                color: Color(0xFF1A4FE0),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  // pulgar
                  AnimatedPositioned(
                    duration: _drag ? Duration.zero : const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    left: 6 + _x,
                    top: 6,
                    child: GestureDetector(
                      onHorizontalDragStart: widget.enabled && !_paying
                          ? (_) => setState(() {
                                _drag = true;
                                _hint = null;
                              })
                          : null,
                      onHorizontalDragUpdate: widget.enabled && !_paying
                          ? (d) {
                              final before = (_x / max * 4).floor();
                              setState(() => _x = (_x + d.delta.dx).clamp(0.0, max));
                              if ((_x / max * 4).floor() != before) CaHaptics.selectionClick();
                            }
                          : null,
                      onHorizontalDragEnd: (_) => _end(max),
                      onHorizontalDragCancel: () => _end(max),
                      child: Container(
                        width: _thumb,
                        height: _thumb,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x4D1A4FE0),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _paying
                            ? Icon(Icons.check_rounded, color: tokens.green, size: 28)
                            : AppSvgIcon(frac > .6 ? 'arrow' : 'lock',
                                size: 22, color: tokens.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
