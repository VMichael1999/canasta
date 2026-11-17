import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../shared/app_svg_icon.dart';

class OrderDoneScreen extends StatelessWidget {
  const OrderDoneScreen({super.key});

  static String _eta() {
    String c(int m) {
      m = ((m % 1440) + 1440) % 1440;
      final h = m ~/ 60;
      return '${h % 12 == 0 ? 12 : h % 12}:${(m % 60).toString().padLeft(2, '0')}';
    }

    final d = DateTime.now();
    final n = d.hour * 60 + d.minute;
    final e = (n + 50) % 1440;
    return 'Hoy, ${c(n + 35)} a ${c(n + 50)} ${e >= 720 ? 'p. m.' : 'a. m.'}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final orders = context.watch<OrdersCubit>().state.orders;
    final order = orders.isNotEmpty ? orders.first : null;

    final items = order?.items.take(4).toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const _AutoRedirect(seconds: 10),
              const SizedBox(height: 10),

              // Escenario animado (.dnst): productos → bolsa → sello → moto se la lleva
              SizedBox(
                height: 280,
                child: OverflowBox(
                  minWidth: MediaQuery.of(context).size.width,
                  maxWidth: MediaQuery.of(context).size.width,
                  minHeight: 280,
                  maxHeight: 280,
                  child: _DoneStage(ids: [for (final x in items) x.product.id]),
                ),
              ),
              const SizedBox(height: 14),

              // Green check circle (.okc)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.green,
                  boxShadow: [
                    BoxShadow(color: tokens.greenSoft, spreadRadius: 10),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                '¡Pedido confirmado!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                  letterSpacing: -0.03 * 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estamos armando tu canasta. Te avisamos cuando salga el repartidor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: tokens.ink2,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),

              // Order detail card (.card.dnc)
              if (order != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pedido',
                              style: TextStyle(
                                  fontSize: 14, color: tokens.ink2)),
                          Text(
                            order.id,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Llega',
                              style: TextStyle(
                                  fontSize: 14, color: tokens.ink2)),
                          Text(
                            order.slot != null
                                ? order.slot!.label
                                : _eta(),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pago',
                              style: TextStyle(
                                  fontSize: 14, color: tokens.ink2)),
                          Text(
                            order.paymentMethod,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: tokens.line, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          Text(
                            formatPen(order.total),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Button 1: Seguir mi pedido
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/tracking'),
                  icon: const AppSvgIcon('truck',
                      size: 20, color: Colors.white),
                  label: const Text(
                    'Seguir mi pedido',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Button 2: Volver al inicio
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Volver al inicio',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Escenario del HTML (.dnst): 440 × 280. Todo en ms.
class _DoneStage extends StatefulWidget {
  const _DoneStage({required this.ids});
  final List<String> ids;

  @override
  State<_DoneStage> createState() => _DoneStageState();
}

class _DoneStageState extends State<_DoneStage>
    with SingleTickerProviderStateMixin {
  static const double _total = 4200;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _p(double delay, double dur, [Curve c = Curves.linear]) =>
      c.transform(((_c.value * _total - delay) / dur).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) _c.value = 1;
    final w = MediaQuery.of(context).size.width;
    final k = w / 440;
    return SizedBox(
      width: w,
      height: 280,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // moto
          final mt = _p(1500, 1600, const Cubic(.5, 0, .3, 1));
          double motoX;
          if (mt < .5) {
            motoX = -200 + 320 * (mt / .5);
          } else {
            motoX = 120 + 350 * ((mt - .5) / .5);
          }
          // bolsa se va con la moto
          final bt = _p(2150, 900, const Cubic(.6, 0, .4, 1));
          final seal = _p(1150, 400, const Cubic(.3, 1.6, .5, 1));
          final trail = _p(2300, 1200, Curves.easeOut);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 36,
                height: 2,
                child: CustomPaint(painter: _RoadPainter()),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(trail, k),
                ),
              ),
              // bolsa (con sello)
              Positioned(
                left: 150 * k,
                bottom: 36,
                width: 140 * k,
                height: 140 * k,
                child: Opacity(
                  opacity: 1 - bt,
                  child: Transform.translate(
                    offset: Offset(330 * k * bt, -10 * bt),
                    child: Transform.scale(
                      scale: 1 - .6 * bt,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Image.asset(CaAssets.bag, fit: BoxFit.contain),
                          ),
                          Positioned(
                            left: 70 * k - 22,
                            top: 64,
                            width: 44,
                            height: 44,
                            child: Transform.scale(
                              scale: seal,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(CaAssets.logo, fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // cuando la moto se va, aparece la marca en el centro
              Positioned.fill(
                child: Center(
                  child: Builder(builder: (context) {
                    final t = _p(3000, 600, const Cubic(.3, 1.5, .5, 1));
                    final halo = _p(3000, 900, Curves.easeOut);
                    if (t <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - halo).clamp(0.0, 1.0) * .6,
                            child: Container(
                              width: 90 + 120 * halo,
                              height: 90 + 120 * halo,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x261A4FE0),
                              ),
                            ),
                          ),
                          Transform.rotate(
                            angle: -.25 * (1 - t),
                            child: Transform.scale(
                              scale: t,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x4D0A1E5A),
                                      blurRadius: 24,
                                      offset: Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: Image.asset(CaAssets.logo, fit: BoxFit.contain),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              // productos que caen dentro
              for (var i = 0; i < widget.ids.length && i < 4; i++) _item(i, k),
              // moto
              Positioned(
                left: motoX * k,
                bottom: 30,
                width: 170 * k,
                height: 128 * k,
                child: Image.asset(CaAssets.scooter, fit: BoxFit.contain),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item(int i, double k) {
    const lefts = [160.0, 200.0, 180.0, 220.0];
    final t = _p(200 + i * 150.0, 500, const Cubic(.5, 0, .75, 0));
    if (t <= 0 && _c.value * _total < 200 + i * 150.0) return const SizedBox.shrink();
    final op = t >= 1 ? 0.0 : 1.0;
    return Positioned(
      left: lefts[i] * k,
      top: -80 + 200 * t,
      width: 62 * k,
      height: 62 * k,
      child: Opacity(
        opacity: op * (1 - t * .0),
        child: Transform.scale(
          scale: 1 - .3 * t,
          child: Image.asset(CaAssets.product(widget.ids[i]), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFDCE2EE)..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 1), Offset(x + 18, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.t, this.k);
  final double t, k;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    canvas.save();
    canvas.scale(k, 1);
    final base = size.height - 60 - 40;
    final path = Path()
      ..moveTo(440, base + 24)
      ..cubicTo(300, base + 10, 160, base + 34, -20, base + 18);
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..color = const Color(0xFF1A4FE0).withValues(alpha: .4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.t != t;
}


/// Cuenta regresiva arriba: al llegar a 0 lleva a «Seguir mi pedido».
/// Tocarla la cancela para quedarse en esta pantalla.
class _AutoRedirect extends StatefulWidget {
  const _AutoRedirect({required this.seconds});
  final int seconds;

  @override
  State<_AutoRedirect> createState() => _AutoRedirectState();
}

class _AutoRedirectState extends State<_AutoRedirect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  );
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) {
      if (mounted && !_cancelled) context.go('/tracking');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final left = (widget.seconds * (1 - _c.value)).ceil();
        return GestureDetector(
          onTap: () {
            if (_cancelled) return;
            setState(() => _cancelled = true);
            _c.stop();
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _cancelled ? .5 : 1,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: t.blueSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _cancelled ? 1 : _c.value,
                          strokeWidth: 3,
                          color: t.blue,
                          backgroundColor: Colors.white,
                        ),
                        Text('${_cancelled ? '·' : left}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: t.blue,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _cancelled
                        ? 'Te quedas aquí'
                        : 'Seguimos tu pedido en ${left}s · toca para quedarte',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: t.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
