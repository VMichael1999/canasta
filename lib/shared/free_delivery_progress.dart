import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/money.dart';
import '../core/tokens.dart';

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasFreeDelivery ? tokens.greenSoft : tokens.blueSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                hasFreeDelivery ? '🎉 ' : '🛵 ',
                style: const TextStyle(fontSize: 16),
              ),
              Expanded(
                child: Text(
                  hasFreeDelivery
                      ? '¡Tienes delivery gratis!'
                      : 'Te faltan ${formatPen(missingAmount)} para el delivery gratis',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: hasFreeDelivery ? tokens.green : tokens.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final scooterOffset = (progress * (trackWidth - 24)).clamp(0.0, trackWidth - 24);

              return SizedBox(
                height: 22,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background track
                    Container(
                      height: 6,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // Progress fill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      height: 6,
                      width: progress * trackWidth,
                      decoration: BoxDecoration(
                        color: hasFreeDelivery ? tokens.green : tokens.blue,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // Scooter icon moving along track
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      left: scooterOffset,
                      top: 0,
                      child: Image.asset(
                        CaAssets.scooter,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
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
