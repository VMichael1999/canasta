import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../app/navigation.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import '../core/assets.dart';
import '../core/haptics.dart';
import '../core/money.dart';
import '../core/tokens.dart';
import '../domain/models/cart_item.dart';
import 'app_svg_icon.dart';
import 'app_toast.dart';
import 'fly_animator.dart';
import 'qty_stepper.dart';

/// Número de hojas/diálogos abiertos: la burbuja se oculta debajo de ellos.
final ValueNotifier<int> modalOpenCount = ValueNotifier<int>(0);

class ModalWatcher extends NavigatorObserver {
  void _delta(Route<dynamic> r, int d) {
    if (r is PopupRoute) {
      Future.microtask(
          () => modalOpenCount.value = (modalOpenCount.value + d).clamp(0, 99));
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _delta(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _delta(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _delta(route, -1);
}

/// Rutas donde se muestra la burbuja (BUBBLE del HTML).
bool bubbleVisibleOn(String path) =>
    path == '/home' ||
    path == '/cats' ||
    path == '/list' ||
    path == '/search' ||
    path == '/deals' ||
    path.startsWith('/product/');

/// Burbuja flotante del carrito (vidrio): vive encima del router, así que la
/// posición (lado y alto) se comparte entre pantallas.
class FloatingCartBubble extends StatefulWidget {
  const FloatingCartBubble({super.key, required this.router});

  final GoRouter router;

  @override
  State<FloatingCartBubble> createState() => FloatingCartBubbleState();
}

class FloatingCartBubbleState extends State<FloatingCartBubble>
    with TickerProviderStateMixin {
  static const double _h = 64;
  static const double _step = 28; // miniaturas de 44 px solapadas 16 px

  bool _right = true;
  double? _y;
  double? _dragLeft; // posición libre mientras se arrastra
  bool _flying = false;
  String? _newId;

  // gesto
  Offset? _down;
  double _y0 = 0;
  String? _mode; // drag | thumb | peek
  String? _thumbId;
  Offset _thumbD = Offset.zero;
  bool _thumbBye = false;
  Timer? _lp;

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  String _lastTotal = '';
  String _prevTotal = '';
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  String get _path {
    final cfg = widget.router.routerDelegate.currentConfiguration;
    // con `push` la ruta visible es la última coincidencia imperativa
    final last = cfg.matches.isEmpty ? null : cfg.matches.last;
    if (last is ImperativeRouteMatch) return last.matches.uri.path;
    return cfg.uri.path;
  }
  bool get _isProduct => _path.startsWith('/product/');

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRoute);
    modalOpenCount.addListener(_onRoute);
  }

  void _onRoute() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRoute);
    modalOpenCount.removeListener(_onRoute);
    _lp?.cancel();
    _pop.dispose();
    _roll.dispose();
    super.dispose();
  }

  // ---------- geometría ----------
  double _screenH(BuildContext c) => MediaQuery.of(c).size.height;
  double _screenW(BuildContext c) => MediaQuery.of(c).size.width;
  double _minY() => 120;
  double _maxY(BuildContext c) =>
      _screenH(c) - (_isProduct ? 186 : 102) - _h;
  double _defY(BuildContext c) =>
      _screenH(c) - (_isProduct ? 186 : 102) - _h;
  double _topFor(BuildContext c) =>
      (_y ?? _defY(c)).clamp(_minY(), math.max(_minY(), _maxY(c)));

  double _width(CartState s) {
    final n = math.min(3, s.lines.length);
    final stack = 44.0 + (n - 1) * _step + (s.lines.length > 3 ? _step : 0);
    double measure(String t, TextStyle st) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: st),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      return tp.width;
    }

    final units = s.units;
    final text = math.max(
      74.0,
      math.max(
            measure(
              formatPen(s.subtotal - s.discount),
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -.32,
              ),
            ),
            measure(
              '$units ${units == 1 ? 'producto' : 'productos'}',
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ) +
          2,
    );
    return 10 + stack + 10 + text + 18;
  }

  double _leftFor(BuildContext c, CartState s) {
    final w = _width(s);
    return _right ? _screenW(c) - 14 - w : 14;
  }

  /// Centro de la primera miniatura (destino del vuelo).
  Offset _firstThumbCenter(BuildContext c, CartState s) {
    final w = _width(s);
    final left = _right ? _screenW(c) - 14 - w : 14.0;
    // en el borde izquierdo el orden se invierte: miniaturas a la derecha
    final stackW = 44.0 +
        (math.min(3, s.lines.length) - 1) * _step +
        (s.lines.length > 3 ? _step : 0);
    final x = _right ? left + 10 + 22 : left + w - 10 - stackW + 22;
    return Offset(x, _topFor(c) + 10 + 22);
  }

  // ---------- API pública ----------
  void flyFrom(GlobalKey source, String productId) {
    final ro = source.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) {
      _arrive();
      return;
    }
    final topLeft = ro.localToGlobal(Offset.zero);
    final rect = topLeft & ro.size;
    final reduce = MediaQuery.of(context).disableAnimations;
    final visible = bubbleVisibleOn(_path);
    _flying = true;
    setState(() => _newId = productId);
    if (reduce || !visible) {
      _flying = false;
      _arrive();
      return;
    }
    // el estado del carrito se actualiza en el siguiente frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlay = rootNavigatorKey.currentState?.overlay;
      if (overlay == null) {
        _flying = false;
        _arrive();
        return;
      }
      final state = context.read<CartBloc>().state;
      final target = _firstThumbCenter(context, state);
      _launchFly(overlay, rect, target, productId);
    });
  }

  void _launchFly(
      OverlayState overlay, Rect from, Offset to, String productId) {
    FlyAnimator.fly(
      overlay: overlay,
      from: from,
      to: to,
      toSize: 44,
      productId: productId,
      onComplete: () {
        _flying = false;
        _arrive();
      },
    );
    setState(() {});
  }

  void _arrive() {
    if (!mounted) return;
    CaHaptics.lightImpact();
    setState(() {});
    _pop.forward(from: 0);
  }

  void _syncTotal(String t) {
    if (_lastTotal.isEmpty) {
      _lastTotal = t;
      return;
    }
    if (t != _lastTotal) {
      _prevTotal = _lastTotal;
      _lastTotal = t;
      _roll.forward(from: 0);
    }
  }

  // ---------- gestos ----------
  void _onDown(PointerDownEvent e, CartState s, String? thumb) {
    _down = e.position;
    _y0 = _topFor(context);
    _mode = null;
    _thumbId = thumb;
    _thumbD = Offset.zero;
    _lp?.cancel();
    _lp = Timer(const Duration(milliseconds: 480), () {
      if (_down != null && _mode == null) {
        _mode = 'peek';
        CaHaptics.mediumImpact();
        _showPeek();
      }
    });
  }

  void _onMove(PointerMoveEvent e, CartState s) {
    if (_down == null) return;
    final d = e.position - _down!;
    if (_mode == null && d.distance > 8) {
      _lp?.cancel();
      _mode = (_thumbId != null && d.dy < -8 && d.dy.abs() > d.dx.abs())
          ? 'thumb'
          : 'drag';
      if (_mode == 'drag') {
        _dragLeft = _leftFor(context, s);
      }
    }
    if (_mode == 'drag') {
      setState(() {
        _y = _y0 + d.dy;
        final w = _width(s);
        _dragLeft = (_leftFor(context, s) + d.dx)
            .clamp(6.0, _screenW(context) - w - 6);
      });
    } else if (_mode == 'thumb') {
      setState(() {
        _thumbD = d;
        final bye = d.distance > 70;
        if (bye && !_thumbBye) CaHaptics.selectionClick();
        _thumbBye = bye;
      });
    }
  }

  void _onUp(PointerUpEvent e, CartState s) {
    if (_down == null) return;
    _lp?.cancel();
    final d = e.position - _down!;
    final mode = _mode;
    _down = null;
    _mode = null;
    if (mode == 'drag') {
      final w = _width(s);
      final cx = (_dragLeft ?? _leftFor(context, s)) + w / 2;
      setState(() {
        _right = cx >= _screenW(context) / 2;
        _y = _topFor(context);
        _dragLeft = null;
      });
      CaHaptics.selectionClick();
      return;
    }
    if (mode == 'thumb') {
      final id = _thumbId;
      final bye = d.distance > 70;
      setState(() {
        _thumbD = Offset.zero;
        _thumbBye = false;
        _thumbId = null;
      });
      if (bye && id != null) _removeThumb(id, s);
      return;
    }
    if (mode == 'peek') return;
    _openCart(s);
  }

  void _removeThumb(String id, CartState s) {
    final line = s.lines.firstWhere((l) => l.product.id == id);
    final old = line.quantity;
    CaHaptics.mediumImpact();
    final bloc = context.read<CartBloc>();
    bloc.add(CartItemRemoved(id));
    final overlayCtx = rootNavigatorKey.currentContext;
    if (overlayCtx != null) {
      AppToast.show(
        overlayCtx,
        'Quitaste ${line.product.name.toLowerCase()}.',
        actionLabel: 'Deshacer',
        onAction: () => bloc.add(CartItemAdded(line.product, quantity: old)),
      );
    }
  }

  void _openCart(CartState s) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      widget.router.push('/cart');
      return;
    }
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      widget.router.push('/cart');
      return;
    }
    final w = _width(s);
    final c = Offset(_leftFor(context, s) + w / 2, _topFor(context) + _h / 2);
    _MorphOverlay.run(
      overlay: overlay,
      center: c,
      onCovered: () => widget.router.push('/cart'),
    );
  }

  void _showPeek() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: const Color(0x2E0A1024),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (c, a, b) => const SizedBox.shrink(),
      transitionBuilder: (c, anim, _, __) {
        final t = Curves.easeOutCubic.transform(anim.value);
        return Align(
          alignment: Alignment.bottomCenter,
          child: FractionalTranslation(
            translation: Offset(0, 1.05 * (1 - t)),
            child: _PeekSheet(
              onGoCart: () {
                Navigator.of(c).pop();
                widget.router.push('/cart');
              },
            ),
          ),
        );
      },
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final show = bubbleVisibleOn(_path);
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, s) {
        final visible =
            show && s.lines.isNotEmpty && modalOpenCount.value == 0;
        if (!visible) return const SizedBox.shrink();
        final total = formatPen(s.subtotal - s.discount);
        _syncTotal(total);
        final top3 = s.lines.take(3).toList();
        final left = _dragLeft ?? _leftFor(context, s);
        final dragging = _mode == 'drag';
        final w = _width(s);
        final bubble = _buildBubble(context, s, top3, total, w);
        return AnimatedPositioned(
          duration: dragging ? Duration.zero : const Duration(milliseconds: 350),
          curve: const Cubic(.3, 1.4, .5, 1),
          left: left,
          top: dragging ? (_y ?? _defY(context)) : _topFor(context),
          width: w,
          height: _h,
          child: Material(
            type: MaterialType.transparency,
            child: ScaleTransition(
            scale: TweenSequence<double>([
              TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 1.08)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 40),
              TweenSequenceItem(
                  tween: Tween(begin: 1.08, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 60),
            ]).animate(_pop),
            child: bubble,
          ),
          ),
        );
      },
    );
  }

  Widget _buildBubble(BuildContext context, CartState s, List<CartItem> top3,
      String total, double w) {
    final tokens = context.tokens;
    final more = s.lines.length - 3;
    final stackW = 44.0 + (top3.length - 1) * _step + (more > 0 ? _step : 0);
    final units = s.units;

    final thumbs = SizedBox(
      width: stackW,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // z-index: el primero queda encima
          if (more > 0)
            Positioned(
              left: top3.length * _step,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.blueSoft,
                  shape: BoxShape.circle,
                  boxShadow: _thumbShadow,
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$more',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.blue,
                  ),
                ),
              ),
            ),
          for (var k = top3.length - 1; k >= 0; k--)
            Positioned(
              left: k * _step,
              child: _thumb(top3[k], k),
            ),
        ],
      ),
    );

    final text = SizedBox(
      width: w - 10 - stackW - 10 - 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            _right ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            '$units ${units == 1 ? 'producto' : 'productos'}',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.15,
              fontWeight: FontWeight.w500,
              color: tokens.ink2,
            ),
          ),
          _RollingTotal(
            controller: _roll,
            previous: _prevTotal,
            current: total,
            alignEnd: !_right,
          ),
        ],
      ),
    );

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        // ¿tocó una miniatura? (hit-test simple por posición local)
        final box = context.findRenderObject() as RenderBox?;
        String? thumb;
        if (box != null) {
          final local = e.localPosition;
          // e.localPosition es relativo al Listener, que ocupa toda la burbuja
          final startX = _right ? 10.0 : w - 10 - stackW;
          for (var k = 0; k < top3.length; k++) {
            final x0 = _right ? startX + k * _step : startX + k * _step;
            if (local.dx >= x0 &&
                local.dx <= x0 + 44 &&
                local.dy >= 10 &&
                local.dy <= 54) {
              thumb = top3[k].product.id;
              break;
            }
          }
        }
        _onDown(e, s, thumb);
      },
      onPointerMove: (e) => _onMove(e, s),
      onPointerUp: (e) => _onUp(e, s),
      onPointerCancel: (_) {
        _lp?.cancel();
        _down = null;
        _mode = null;
        setState(() {
          _dragLeft = null;
          _thumbD = Offset.zero;
          _thumbBye = false;
        });
      },
      child: Semantics(
        button: true,
        label: 'Abrir carrito',
        onTap: () => _openCart(s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: _h,
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x730A1E5A),
                    blurRadius: 40,
                    spreadRadius: -18,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: _right ? 10 : 18,
                right: _right ? 18 : 10,
              ),
              child: Row(
                textDirection: _right ? TextDirection.ltr : TextDirection.rtl,
                children: [
                  thumbs,
                  const SizedBox(width: 10),
                  text,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _thumbShadow = [
    BoxShadow(color: Color(0xF2FFFFFF), spreadRadius: 2),
    BoxShadow(
      color: Color(0x4D0A1E5A),
      blurRadius: 10,
      spreadRadius: -4,
      offset: Offset(0, 4),
    ),
  ];

  Widget _thumb(CartItem item, int k) {
    final tokens = context.tokens;
    final isDragging = _mode == 'thumb' && _thumbId == item.product.id;
    final waiting = _flying && k == 0;
    final isNew = _newId == item.product.id && k == 0;
    Widget circle = Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: _thumbShadow,
      ),
      child: ColorFiltered(
        colorFilter: isDragging && _thumbBye
            ? const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ])
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: Image.asset(CaAssets.product(item.product.id),
            fit: BoxFit.contain),
      ),
    );
    final showQty = !item.product.isKg && item.quantity > 1;
    circle = Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        if (showQty)
          Positioned(
            right: -5,
            bottom: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: tokens.blue,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                '×${item.quantity.toInt()}',
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
    if (isDragging) {
      return Transform.translate(
        offset: _thumbD,
        child: Opacity(
          opacity: _thumbBye ? .5 : 1,
          child: Transform.scale(scale: 1.25, child: circle),
        ),
      );
    }
    if (isNew) {
      circle = TweenAnimationBuilder<double>(
        key: ValueKey('new-${item.product.id}-${item.quantity}-$_flying'),
        tween: Tween(begin: .3, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: const Cubic(.3, 1.6, .5, 1),
        builder: (c, v, ch) => Transform.scale(scale: v, child: ch),
        child: circle,
      );
    }
    return AnimatedScale(
      scale: waiting ? .92 : 1,
      duration: const Duration(milliseconds: 200),
      child: circle,
    );
  }
}

/// El total «rueda»: sube el número viejo y entra el nuevo (400 ms).
class _RollingTotal extends StatelessWidget {
  const _RollingTotal({
    required this.controller,
    required this.previous,
    required this.current,
    required this.alignEnd,
  });

  final AnimationController controller;
  final String previous;
  final String current;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = TextStyle(
      fontSize: 16,
      height: 19 / 16,
      fontWeight: FontWeight.w800,
      letterSpacing: -.32,
      color: tokens.ink,
    );
    return SizedBox(
      height: 19,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final running = controller.isAnimating && previous.isNotEmpty;
            if (!running) {
              return Align(
                alignment:
                    alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(current, style: style, maxLines: 1),
              );
            }
            final t = const Cubic(.3, 1.2, .5, 1).transform(controller.value);
            return OverflowBox(
              maxHeight: 38,
              alignment: alignEnd ? Alignment.topRight : Alignment.topLeft,
              child: Transform.translate(
                offset: Offset(0, -19 * t),
                child: Column(
                  crossAxisAlignment: alignEnd
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(previous, style: style, maxLines: 1),
                    Text(current, style: style, maxLines: 1),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Un círculo blanco crece desde la burbuja hasta cubrir la pantalla (380 ms),
/// navega al carrito y se desvanece (200 ms).
class _MorphOverlay {
  static void run({
    required OverlayState overlay,
    required Offset center,
    required VoidCallback onCovered,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MorphWidget(
        center: center,
        onCovered: onCovered,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _MorphWidget extends StatefulWidget {
  const _MorphWidget({
    required this.center,
    required this.onCovered,
    required this.onDone,
  });

  final Offset center;
  final VoidCallback onCovered;
  final VoidCallback onDone;

  @override
  State<_MorphWidget> createState() => _MorphWidgetState();
}

class _MorphWidgetState extends State<_MorphWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  double _fade = 1;

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) async {
      widget.onCovered();
      const steps = 12;
      for (var i = 1; i <= steps; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200 ~/ steps));
        if (!mounted) return;
        setState(() => _fade = 1 - i / steps);
      }
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = const Cubic(.5, 0, .2, 1).transform(_c.value);
          final r = 30 + (1100 - 30) * t;
          return Opacity(
            opacity: _fade,
            child: CustomPaint(
              size: Size.infinite,
              painter: _CirclePainter(widget.center, r),
            ),
          );
        },
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter(this.c, this.r);
  final Offset c;
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.r != r || old.c != c;
}

/// Vistazo (hoja de vidrio): cada línea con su stepper y «Ver carrito».
class _PeekSheet extends StatelessWidget {
  const _PeekSheet({required this.onGoCart});

  final VoidCallback onGoCart;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .84,
              ),
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                    color: Colors.white.withValues(alpha: .55), width: 1),
              ),
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, s) {
                  if (s.lines.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x400F1324),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Text(
                        'Tu canasta',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.3,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.units} productos · ${formatPen(s.subtotal - s.discount)}',
                        style: TextStyle(fontSize: 14.5, color: tokens.ink2),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            for (final l in s.lines)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Color(0x140F1324), width: 1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: .75),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Image.asset(
                                          CaAssets.product(l.product.id),
                                          fit: BoxFit.contain),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: tokens.ink,
                                            ),
                                          ),
                                          Text(
                                            formatPen(
                                                l.product.price * l.quantity),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: tokens.ink2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    QtyStepper(
                                      product: l.product,
                                      quantity: l.quantity,
                                      style: StepperStyle.cardPill,
                                      onChanged: (q) => context
                                          .read<CartBloc>()
                                          .add(CartItemQtyChanged(
                                              l.product.id, q)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: onGoCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Ver carrito',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const AppSvgIcon('arrow',
                                  size: 20, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
