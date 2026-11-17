import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/money.dart';
import '../core/tokens.dart';

/// Barra de delivery gratis (.frb): texto arriba, pista de 6 px y la motito
/// encima que avanza. Al llegar a S/ 80 se vuelve verde.
class FreeDeliveryProgress extends StatelessWidget {
  const FreeDeliveryProgress({
    super.key,
    required this.missingAmount,
    required this.progress,
    required this.hasFreeDelivery,
  });

  final double missingAmount;
  final double progress; // 0..1
  final bool hasFreeDelivery;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fill = hasFreeDelivery ? tokens.green : tokens.blue;
    final textColor =
        hasFreeDelivery ? tokens.green : const Color(0xFF2B3B6E);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: hasFreeDelivery ? tokens.greenSoft : tokens.blueSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            hasFreeDelivery
                ? const TextSpan(
                    text: '¡Tienes delivery gratis!',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  )
                : TextSpan(
                    children: [
                      const TextSpan(text: 'Te faltan '),
                      TextSpan(
                        text: formatPen(missingAmount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' para el delivery gratis'),
                    ],
                  ),
            style: TextStyle(fontSize: 13.5, height: 1.35, color: textColor),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final x = progress.clamp(0.0, 1.0) * w;
              return SizedBox(
                height: 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: w,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: x,
                      height: 6,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      left: x - 20,
                      top: -17,
                      width: 40,
                      height: 30,
                      child: Image.asset(CaAssets.scooter, fit: BoxFit.contain),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
