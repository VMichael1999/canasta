import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/assets.dart';
import '../../core/typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bagDropAnimation;
  late Animation<double> _motoAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _bagDropAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.bounceOut),
    );

    _motoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeInOutCubic),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 3400), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1A4FE0),
              Color(0xFF1240BE),
              Color(0xFF0B2A73),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Bag Animation
            AnimatedBuilder(
              animation: _bagDropAnimation,
              builder: (context, child) {
                final dropVal = _bagDropAnimation.value;
                return Transform.translate(
                  offset: Offset(0, -200 * (1 - dropVal)),
                  child: Opacity(
                    opacity: dropVal.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        CaAssets.bag,
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        bottom: 30,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            CaAssets.logo,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title and Subtitle
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      children: const [
                        Text(
                          'Canasta',
                          style: CaTypography.display,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Lo fresco, a tu puerta',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scooter crossing with white trail
            AnimatedBuilder(
              animation: _motoAnimation,
              builder: (context, child) {
                final val = _motoAnimation.value;
                final screenW = MediaQuery.of(context).size.width;
                final x = -100 + val * (screenW + 200);

                return Positioned(
                  bottom: 120,
                  left: x,
                  child: child!,
                );
              },
              child: Image.asset(
                CaAssets.scooter,
                width: 90,
                height: 70,
                fit: BoxFit.contain,
              ),
            ),

            // Skip button
            Positioned(
              top: 56,
              right: 22,
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Saltar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
