import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/tokens.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/illustrated_map.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _page = PageController();
  int _i = 0;

  static const _slides = [
    (
      'Lo fresco del mercado, en tu puerta',
      'Frutas, verduras y todo lo de la semana, elegido a mano y entregado en menos de una hora.',
    ),
    (
      'Arma tu canasta en segundos',
      'Toca «+» y míralo volar a tu carrito. Lo ves todo en una burbuja, sin salir de donde estás.',
    ),
    (
      'Síguelo en vivo hasta tu casa',
      'Ve al repartidor en el mapa, chatea con él y recibe tu pedido a la hora que elegiste.',
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_i < 2) {
      _page.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: const Cubic(.4, 0, .1, 1),
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final top = MediaQuery.of(context).padding.top;
    // el HTML deja 110 px sobre la ilustración con una barra de estado de 54
    final topPad = math.max(top + 48, 110.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (context, k) {
              final s = _slides[k];
              return Padding(
                padding: EdgeInsets.only(top: topPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 470,
                      margin: const EdgeInsets.symmetric(horizontal: 22),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFEEF3FF), Color(0xFFF8FAFF)],
                        ),
                      ),
                      child: _Illustration(index: k, active: _i == k),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.$1,
                            style: TextStyle(
                              fontSize: 29,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.87,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 292),
                            child: Text(
                              s.$2,
                              style: TextStyle(
                                fontSize: 15.5,
                                height: 1.5,
                                color: tokens.ink2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Saltar
          Positioned(
            top: math.max(top + 6, 60),
            right: 22,
            child: GestureDetector(
              onTap: () => context.go('/login'),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Saltar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: tokens.ink2,
                  ),
                ),
              ),
            ),
          ),

          // pie: puntos + botón
          Positioned(
            left: 22,
            right: 22,
            bottom: 48,
            child: Row(
              children: [
                Row(
                  children: [
                    for (var k = 0; k < 3; k++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.only(right: k < 2 ? 6 : 0),
                        width: k == _i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: k == _i ? tokens.blue : const Color(0xFFD5DCEB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: GestureDetector(
                    onTap: _next,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: tokens.blue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _i == 2 ? 'Empezar' : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ilustraciones de las 3 diapositivas (396 × 470).
class _Illustration extends StatelessWidget {
  const _Illustration({required this.index, required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return _Basket(active: active);
      case 1:
        return _PhoneDemo(active: active);
      default:
        return _MapDemo(active: active);
    }
  }
}

/// Entrada con rebote: opacity 0, translateY 30, scale .6 → normal.
class _PopIn extends StatelessWidget {
  const _PopIn({
    required this.active,
    required this.delay,
    required this.child,
  });

  final bool active;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$active-$delay'),
      tween: Tween(begin: 0, end: active ? 1 : 1),
      duration: Duration(milliseconds: 600 + (delay * 1000).round()),
      curve: Interval(
        delay / (0.6 + delay),
        1,
        curve: const Cubic(.3, 1.5, .5, 1),
      ),
      builder: (context, t, ch) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Transform.scale(scale: .6 + .4 * t, child: ch),
        ),
      ),
      child: child,
    );
  }
}

class _Basket extends StatelessWidget {
  const _Basket({required this.active});
  final bool active;

  static const _items = [
    ('broccoli', 40.0, 60.0, 0.0, 96.0),
    ('tomato', 156.0, 34.0, 0.0, 96.0),
    ('apple', 266.0, 66.0, 0.0, 96.0),
    ('carrot', 30.0, 200.0, -14.0, 96.0),
    ('banana', 290.0, 208.0, 16.0, 96.0),
    ('lettuce', 110.0, 118.0, 0.0, 80.0),
    ('orange', 220.0, 130.0, 0.0, 80.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 396 / 2 - 165,
          top: 470 / 2 - 165,
          width: 330,
          height: 330,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFDCE6FF),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: 396 / 2 - 120,
          top: 150,
          width: 240,
          height: 240,
          child: Image.asset(CaAssets.bag, fit: BoxFit.contain),
        ),
        for (var k = 0; k < _items.length; k++)
          Positioned(
            left: _items[k].$2,
            top: _items[k].$3,
            width: _items[k].$5,
            height: _items[k].$5,
            child: _PopIn(
              active: active,
              delay: k * .08,
              child: Transform.rotate(
                angle: _items[k].$4 * math.pi / 180,
                child: Image.asset(CaAssets.product(_items[k].$1),
                    fit: BoxFit.contain),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhoneDemo extends StatefulWidget {
  const _PhoneDemo({required this.active});
  final bool active;

  @override
  State<_PhoneDemo> createState() => _PhoneDemoState();
}

class _PhoneDemoState extends State<_PhoneDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  void _start() {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted && widget.active) _c.repeat();
    });
  }

  @override
  void didUpdateWidget(_PhoneDemo old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _start();
    } else if (!widget.active) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 396 / 2 - 125,
          top: 40,
          width: 250,
          height: 440,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 46, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF0F1324), spreadRadius: 7),
                    BoxShadow(
                      color: Color(0x660A1E5A),
                      blurRadius: 40,
                      spreadRadius: -20,
                      offset: Offset(0, 30),
                    ),
                  ],
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 109 / 120,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final id in const ['avocado', 'milk', 'eggs', 'bread'])
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tokens.line),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Image.asset(CaAssets.product(id),
                                  fit: BoxFit.contain),
                            ),
                            Positioned(
                              right: -14,
                              bottom: -22,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: tokens.blue,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const AppSvgIcon('plus',
                                    size: 15, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // burbuja con total
              Positioned(
                right: -26,
                bottom: 44,
                height: 56,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                  decoration: BoxDecoration(
                    color: tokens.blue,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xB31A4FE0),
                        blurRadius: 26,
                        spreadRadius: -12,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      for (final id in const ['avocado', 'milk', 'bread'])
                        Align(
                          widthFactor: id == 'bread' ? 1 : .55,
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: tokens.blue, width: 2),
                            ),
                            child: Image.asset(CaAssets.product(id),
                                fit: BoxFit.contain),
                          ),
                        ),
                      const SizedBox(width: 10),
                      const Text(
                        'S/ 16.20',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // huevos que vuelan hacia la burbuja
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            double dx, dy, sc, rot, op;
            if (t <= .55) {
              final u = Curves.easeInOut.transform(t / .55);
              dx = 70 * u;
              dy = -60 * u;
              sc = 1 - .2 * u;
              rot = 10 * u;
              op = 1;
            } else if (t <= .85) {
              final u = (t - .55) / .3;
              dx = 70 + 20 * u;
              dy = -60 + 200 * u;
              sc = .8 - .5 * u;
              rot = 10 + 10 * u;
              op = 1 - u;
            } else {
              dx = 90;
              dy = 140;
              sc = .3;
              rot = 20;
              op = 0;
            }
            return Positioned(
              left: 396 / 2 - 125 + 150,
              top: 40 + 230,
              width: 60,
              height: 60,
              child: Opacity(
                opacity: widget.active ? op : 0,
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.rotate(
                    angle: rot * math.pi / 180,
                    child: Transform.scale(
                      scale: sc,
                      child: Image.asset(CaAssets.product('eggs'),
                          fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MapDemo extends StatefulWidget {
  const _MapDemo({required this.active});
  final bool active;

  @override
  State<_MapDemo> createState() => _MapDemoState();
}

class _MapDemoState extends State<_MapDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_MapDemo old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _c.repeat(reverse: true);
    } else if (!widget.active) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      children: [
        const Positioned.fill(
          child: IllustratedMap(
            showExpandButton: false,
            showRoute: false,
            showMarker: false,
            opacity: .55,
          ),
        ),
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_c.value);
            return Positioned(
              left: 150 + 60 * t,
              top: 200 - 70 * t,
              width: 110,
              height: 84,
              child: child!,
            );
          },
          child: Image.asset(CaAssets.scooter, fit: BoxFit.contain),
        ),
        Positioned(
          left: 22,
          bottom: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0x050F1324), offset: Offset(0, 1)),
                BoxShadow(
                  color: Color(0x470F1324),
                  blurRadius: 24,
                  spreadRadius: -18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Llega en',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: tokens.ink2,
                  ),
                ),
                Text(
                  '12 min',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.48,
                    color: tokens.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
