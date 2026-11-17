import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';

/// Splash «La canasta sale en moto» (6.5 s). Línea de tiempo del HTML:
/// bolsa cae (0.12 s) · productos llegan en arco (0.9–2.2 s) · sello (2.15 s) ·
/// llega el repartidor (2.75 s) · la bolsa salta a la caja (3.5 s) ·
/// la moto acelera (4.12 s) · marca letra por letra (4.9 s) · Bienvenida (6.5 s).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const double _totalMs = 6500;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6500),
  );
  Timer? _timer;
  bool _reduce = false;
  bool _started = false;
  final Set<int> _fired = {};
  late final Stopwatch _clock = Stopwatch()..start();

  // (id, desde, hasta dentro del grupo, giro)
  static const _items = [
    ('apple', Offset(-90, 250), Offset(44, 44), -14.0),
    ('milk', Offset(220, -140), Offset(80, 22), 6.0),
    ('bread', Offset(540, 300), Offset(118, 46), -8.0),
    ('carrot', Offset(520, -60), Offset(150, 34), 18.0),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduce = MediaQuery.of(context).disableAnimations;
    if (_reduce) {
      _timer = Timer(const Duration(milliseconds: 1100), _go);
    } else {
      for (final p in const ['apple', 'milk', 'bread', 'carrot']) {
        precacheImage(AssetImage(CaAssets.product(p)), context);
      }
      precacheImage(AssetImage(CaAssets.bag), context);
      precacheImage(AssetImage(CaAssets.scooter), context);
      precacheImage(AssetImage(CaAssets.logo), context);
      _c.forward();
      _c.addListener(_haptics);
      _timer = Timer(const Duration(milliseconds: 6500), _go);
    }
  }

  void _haptics() {
    final ms = _c.value * _totalMs;
    void once(int id, double at, VoidCallback f) {
      if (ms >= at && _fired.add(id)) f();
    }

    for (var k = 0; k < 4; k++) {
      once(k, 900 + k * 260 + 540.0, HapticFeedback.selectionClick);
    }
    once(10, 2440, HapticFeedback.mediumImpact);
    once(11, 4000, HapticFeedback.lightImpact);
  }

  void _go() {
    if (mounted) context.go('/onboarding');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  double get _ms => _c.value * _totalMs;

  /// Progreso 0..1 de un tramo [delay, delay+dur] (ms).
  double _p(double delay, double dur, [Curve curve = Curves.linear]) =>
      curve.transform(((_ms - delay) / dur).clamp(0.0, 1.0));

  static Offset _arc(Offset a, Offset b, double lift, double t) {
    final c = Offset((a.dx + b.dx) / 2, math.min(a.dy, b.dy) - lift);
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_reduce) return _staticSplash();
    // el HTML se diseñó en 440 × 956
    final kx = size.width / 440, ky = size.height / 956;

    return Scaffold(
      backgroundColor: const Color(0xFF1A4FE0),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => _frame(size, kx, ky),
        ),
      ),
    );
  }

  Widget _frame(Size size, double kx, double ky) {
    final ms = _ms;
    final w = size.width, h = size.height;

    // --- bolsa: caída con rebote ---
    double groupDy;
    {
      final t = _p(120, 760, const Cubic(.5, 0, .6, 1));
      if (t < .72) {
        groupDy = -620 + (16 + 620) * (t / .72);
      } else if (t < .86) {
        groupDy = 16 + (-10 - 16) * ((t - .72) / .14);
      } else {
        groupDy = -10 + 10 * ((t - .86) / .14);
      }
    }
    // aplastes de la bolsa
    var sx = 1.0, sy = 1.0;
    {
      final t = _p(640, 300);
      if (t > 0 && t < 1) {
        final u = t < .5 ? t / .5 : 1 - (t - .5) / .5;
        sx *= 1 + .1 * u;
        sy *= 1 - .14 * u;
      }
      for (var k = 0; k < 4; k++) {
        final tt = _p(900 + k * 260 + 540.0, 320);
        if (tt > 0 && tt < 1) {
          if (tt < .4) {
            final u = tt / .4;
            sx *= 1 + .07 * u;
            sy *= 1 - .08 * u;
          } else if (tt < .75) {
            final u = (tt - .4) / .35;
            sx *= 1.07 + (.98 - 1.07) * u;
            sy *= .92 + (1.03 - .92) * u;
          } else {
            final u = (tt - .75) / .25;
            sx *= .98 + .02 * u;
            sy *= 1.03 - .03 * u;
          }
        }
      }
    }

    // --- salto de la bolsa a la caja ---
    final jump = _p(3500, 520, const Cubic(.4, 0, .3, 1));
    Offset jumpOff = Offset.zero;
    double jumpScale = 1, jumpOpacity = 1;
    if (jump > 0) {
      jumpOff = _arc(Offset.zero, const Offset(-136, 50), 130, jump);
      jumpScale = 1 - .78 * jump;
      jumpOpacity = jump < .85 ? 1 : 1 - (jump - .85) / .15;
    }

    // --- sello ---
    final sealT = _p(2150, 420, const Cubic(.5, 0, .4, 1));
    double sealScale, sealRot, sealOp;
    if (sealT <= 0) {
      sealScale = 2.6;
      sealRot = -28;
      sealOp = 0;
    } else if (sealT < .7) {
      final u = sealT / .7;
      sealScale = 2.6 + (.9 - 2.6) * u;
      sealRot = -28 + 32 * u;
      sealOp = u;
    } else {
      final u = (sealT - .7) / .3;
      sealScale = .9 + .1 * u;
      sealRot = 4 - 4 * u;
      sealOp = 1;
    }
    final ring = _p(2440, 700, const Cubic(.2, .8, .2, 1));
    final glowT = _p(2420, 900);
    final glow = glowT <= 0 || glowT >= 1
        ? .35
        : glowT < .25
            ? .35 + .65 * (glowT / .25)
            : 1 - .65 * ((glowT - .25) / .75);
    // temblor
    Offset shake = Offset.zero;
    {
      final t = _p(2440, 240);
      if (t > 0 && t < 1) {
        const pts = [
          Offset(0, 0),
          Offset(-4, 3),
          Offset(4, -2),
          Offset(-2, 1),
          Offset(0, 0),
        ];
        final f = t * 4;
        final i = f.floor().clamp(0, 3);
        shake = Offset.lerp(pts[i], pts[i + 1], f - i)!;
      }
    }

    // --- moto ---
    double motoX;
    {
      final inT = _p(2750, 700, const Cubic(.2, .7, .3, 1));
      final outT = _p(4120, 900, const Cubic(.6, 0, .85, .5));
      if (outT > 0) {
        motoX = outT < .18
            ? -14 * (outT / .18)
            : -14 + (560 + 14) * ((outT - .18) / .82);
      } else if (inT <= 0) {
        motoX = -230;
      } else if (inT < .82) {
        motoX = -230 + 244 * (inT / .82);
      } else {
        motoX = 14 - 14 * ((inT - .82) / .18);
      }
    }
    double motoRot = 0, motoSx = 1, motoSy = 1;
    {
      final t = _p(2750, 700);
      if (t > 0 && t < 1) {
        motoRot = t < .85 ? -4 * (t / .85) : -4 + 4 * ((t - .85) / .15);
      }
      final b = _p(4000, 300);
      if (b > 0 && b < 1) {
        if (b < .35) {
          final u = b / .35;
          motoSx = 1 + .06 * u;
          motoSy = 1 - .05 * u;
        } else if (b < .7) {
          final u = (b - .35) / .35;
          motoSx = 1.06 - .08 * u;
          motoSy = .95 + .08 * u;
        } else {
          final u = (b - .7) / .3;
          motoSx = .98 + .02 * u;
          motoSy = 1.03 - .03 * u;
        }
      }
    }

    // --- estela ---
    final trailT = _p(4260, 1500, Curves.easeOut);
    final trailPath = Path()
      ..moveTo(-30, 640)
      ..cubicTo(110, 600, 290, 690, 480, 612);

    // --- marca ---
    final brandMs = ms - 4900;
    final logoT = Curves.linear.transform((brandMs / 750).clamp(0.0, 1.0));
    final logoE = const Cubic(.3, 1.5, .5, 1).transform(logoT);
    final tagT = Curves.ease.transform(((brandMs - 750) / 500).clamp(0.0, 1.0));
    final hintOp = ms < 1600 ? 0.0 : (ms >= 4900 ? 0.0 : ((ms - 1600) / 1000).clamp(0.0, 1.0));

    Widget item(int k) {
      final it = _items[k];
      final d = 900 + k * 260.0;
      final t = _p(d, 560, const Cubic(.35, 0, .25, 1));
      final from = Offset(it.$2.dx - 125 - 38, it.$2.dy - 382 - 38);
      final to = Offset(it.$3.dx - 38, it.$3.dy - 38);
      final pos = _arc(from, to, 150, t);
      final rot = it.$4 * (1 - t) * 3 + it.$4;
      final sc = 1.25 - .25 * t;
      final op = ms < d ? 0.0 : (t < .06 ? t * 16 : 1.0);
      return Positioned(
        left: pos.dx * kx,
        top: pos.dy * ky,
        width: 76 * kx,
        height: 76 * kx,
        child: Opacity(
          opacity: op.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: rot * math.pi / 180,
            child: Transform.scale(
              scale: sc,
              child: Image.asset(CaAssets.product(it.$1), fit: BoxFit.contain),
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // cielo
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -.32),
                radius: 1.2,
                colors: [Color(0xFF3E6BF0), Color(0xFF1A4FE0), Color(0xFF1240BE)],
                stops: [0, .46, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: -.1 * w,
          right: -.1 * w,
          bottom: -.18 * h,
          height: .46 * h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0F37A8).withValues(alpha: .55),
              borderRadius:
                  BorderRadius.all(Radius.elliptical(w * .6, h * .23)),
            ),
          ),
        ),
        // brillo
        Positioned(
          left: w / 2 - 260,
          top: 470 * ky - 260,
          width: 520,
          height: 520,
          child: Opacity(
            opacity: glow,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x8C96BEFF),
                  Color(0x0096BEFF),
                ], stops: [0, .65]),
              ),
            ),
          ),
        ),
        // partículas
        for (var k = 0; k < 16; k++) _particle(k, h),

        // estela de luz
        Positioned.fill(
          child: CustomPaint(
            painter: _TrailPainter(
              path: trailPath,
              progress: trailT,
              sx: w / 440,
              sy: h / 956,
            ),
          ),
        ),

        // capa que tiembla: bolsa + moto
        Positioned.fill(
          child: Transform.translate(
            offset: shake,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // grupo bolsa (190 × 230)
                Positioned(
                  left: 125 * kx,
                  top: 382 * ky,
                  width: 190 * kx,
                  height: 230 * ky,
                  child: Opacity(
                    opacity: ms < 120 ? 0 : jumpOpacity.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, groupDy) + jumpOff,
                      child: Transform.scale(
                        scale: jumpScale,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var k = 0; k < 4; k++) item(k),
                            Positioned(
                              left: 0,
                              bottom: 0,
                              width: 190 * kx,
                              height: 190 * kx,
                              child: Transform(
                                alignment: Alignment.bottomCenter,
                                transform: Matrix4.diagonal3Values(sx, sy, 1),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: Image.asset(CaAssets.bag,
                                          fit: BoxFit.contain),
                                    ),
                                    Positioned(
                                      left: 95 * kx - 31,
                                      top: 84,
                                      width: 62,
                                      height: 62,
                                      child: Opacity(
                                        opacity: sealOp.clamp(0.0, 1.0),
                                        child: Transform.rotate(
                                          angle: sealRot * math.pi / 180,
                                          child: Transform.scale(
                                            scale: sealScale,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Image.asset(CaAssets.logo,
                                                  fit: BoxFit.contain),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // onda del sello
                            Positioned(
                              left: 95 * kx - 35,
                              top: 115 - 35,
                              width: 70,
                              height: 70,
                              child: Opacity(
                                opacity: ring <= 0 ? 0 : (.9 * (1 - ring)),
                                child: Transform.scale(
                                  scale: .3 + 3.1 * ring,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xE6FFFFFF),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // moto
                Positioned(
                  left: 30 * kx + motoX * kx,
                  top: 478 * ky,
                  width: 180 * kx,
                  height: 135 * kx,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Transform(
                          alignment: const Alignment(0, .8),
                          transform: Matrix4.identity()
                            ..rotateZ(motoRot * math.pi / 180)
                            ..scale(motoSx, motoSy),
                          child: Image.asset(CaAssets.scooter,
                              fit: BoxFit.contain),
                        ),
                      ),
                      for (var k = 0; k < 3; k++) _puff(k),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // marca
        Positioned(
          left: 0,
          right: 0,
          top: 330 * ky,
          child: IgnorePointer(
            child: Column(
              children: [
                Opacity(
                  opacity: brandMs > 0 ? 1 : 0,
                  child: Transform.rotate(
                    angle: -20 * math.pi / 180 * (1 - logoE),
                    child: Transform.scale(
                      scale: logoE.clamp(0.0, 1.2),
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: Image.asset(CaAssets.logo, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var k = 0; k < 7; k++) _letter('Canasta'[k], k, brandMs),
                  ],
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: tagT,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - tagT)),
                    child: const Text(
                      'Lo fresco, a tu puerta',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xD9FFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // pista
        Positioned(
          left: 0,
          right: 0,
          bottom: 46,
          child: IgnorePointer(
            child: Opacity(
              opacity: hintOp * .55,
              child: const Text(
                'Toca para saltar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _letter(String ch, int k, double brandMs) {
    final t = const Cubic(.2, 1.3, .4, 1)
        .transform(((brandMs - 250 - k * 45) / 500).clamp(0.0, 1.0));
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 28 * (1 - t)),
        child: Transform.rotate(
          angle: 8 * math.pi / 180 * (1 - t),
          child: Text(
            ch,
            style: const TextStyle(
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -2.34,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _puff(int k) {
    final t = _p(4180 + k * 70, 600);
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    double dx, dy, sc, op;
    if (t < .3) {
      final u = t / .3;
      dx = -10 * u;
      dy = -6 * u;
      sc = .4 + .6 * u;
      op = .8 * u;
    } else {
      final u = (t - .3) / .7;
      dx = -10 + (-40 - k * 16 + 10) * u;
      dy = -6 + (-18 - k * 6 + 6) * u;
      sc = 1 + .6 * u;
      op = .8 * (1 - u);
    }
    final sz = [26.0, 20.0, 16.0][k];
    final left = [-6.0, 4.0, 12.0][k];
    final bottom = [8.0, 14.0, 4.0][k];
    return Positioned(
      left: left,
      bottom: bottom,
      child: Opacity(
        opacity: op.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: sc,
            child: Container(
              width: sz,
              height: sz,
              decoration: const BoxDecoration(
                color: Color(0xD9FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _particle(int k, double h) {
    final x = (k * 61) % 430;
    final d = 6 + (k % 5) * 1.6;
    final sz = 4.0 + (k % 4) * 3;
    final sec = _clock.elapsedMilliseconds / 1000;
    final phase = ((sec + k * .7) / d) % 1.0;
    final y = h + 20 - phase * 1000 - sz;
    final leaf = k % 3 == 0;
    return Positioned(
      left: x.toDouble(),
      top: y,
      child: Transform.rotate(
        angle: phase * 220 * math.pi / 180,
        child: Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            color: leaf ? const Color(0x8C78E6AA) : const Color(0x59FFFFFF),
            borderRadius: leaf
                ? const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  )
                : BorderRadius.circular(sz),
          ),
        ),
      ),
    );
  }

  Widget _staticSplash() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A4FE0),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Image.asset(CaAssets.logo, fit: BoxFit.contain),
            ),
            const SizedBox(height: 22),
            const Text(
              'Canasta',
              style: TextStyle(
                fontSize: 52,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -2.34,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lo fresco, a tu puerta',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xD9FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.path,
    required this.progress,
    required this.sx,
    required this.sy,
  });

  final Path path;
  final double progress, sx, sy;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas.save();
    canvas.scale(sx, sy);
    final m = path.computeMetrics().first;
    // dibujo hasta el 55 % y luego se desvanece
    final draw = (progress / .55).clamp(0.0, 1.0);
    final op = progress < .55 ? .9 : .9 * (1 - (progress - .55) / .45);
    final p = m.extractPath(0, m.length * draw);
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white.withValues(alpha: op)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.progress != progress;
}
