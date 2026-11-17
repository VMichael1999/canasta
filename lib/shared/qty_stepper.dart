import 'package:flutter/material.dart';
import '../core/haptics.dart';
import '../core/tokens.dart';
import '../core/weight.dart';
import '../domain/models/product.dart';
import 'app_svg_icon.dart';

enum StepperStyle {
  cardPill,
  cartSmall,
  detailLarge,
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.product,
    required this.quantity,
    required this.onChanged,
    this.style = StepperStyle.cardPill,
  });

  final Product product;
  final double quantity;
  final ValueChanged<double> onChanged;
  final StepperStyle style;

  String get _label {
    if (product.isKg) {
      return formatWeight(quantity);
    }
    return quantity.toInt().toString();
  }

  void _decrement() {
    CaHaptics.selectionClick();
    final step = product.step;
    final next = (quantity - step).clamp(0.0, 99.0);
    onChanged(double.parse(next.toStringAsFixed(2)));
  }

  void _increment() {
    CaHaptics.selectionClick();
    final step = product.step;
    final next = (quantity + step).clamp(0.0, 99.0);
    onChanged(double.parse(next.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    switch (style) {
      case StepperStyle.cardPill:
        // .stp dentro de .pc: botones de 25 px, cantidad mínima de 14 px.
        return Container(
          height: 30,
          decoration: BoxDecoration(
            color: tokens.blue,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _decrement,
                child: const SizedBox(
                  width: 25,
                  height: 30,
                  child: Center(
                    child: AppSvgIcon('minus', size: 15, color: Colors.white),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 14),
                child: Text(
                  _label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _increment,
                child: const SizedBox(
                  width: 25,
                  height: 30,
                  child: Center(
                    child: AppSvgIcon('plus', size: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );

      case StepperStyle.cartSmall:
        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _decrement,
                child: SizedBox(
                  width: 30,
                  height: 32,
                  child: Center(
                    child: AppSvgIcon('minus', size: 15, color: tokens.ink),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 22),
                child: Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _increment,
                child: SizedBox(
                  width: 30,
                  height: 32,
                  child: Center(
                    child: AppSvgIcon('plus', size: 15, color: tokens.ink),
                  ),
                ),
              ),
            ],
          ),
        );

      case StepperStyle.detailLarge:
        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _decrement,
                child: SizedBox(
                  width: 44,
                  height: 46,
                  child: Center(
                    child: AppSvgIcon('minus', size: 18, color: tokens.ink),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 26),
                child: Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _increment,
                child: SizedBox(
                  width: 44,
                  height: 46,
                  child: Center(
                    child: AppSvgIcon('plus', size: 18, color: tokens.ink),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
