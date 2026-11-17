import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../core/haptics.dart';
import '../core/tokens.dart';
import '../core/weight.dart';

class WeightSlider extends StatefulWidget {
  const WeightSlider({
    super.key,
    required this.currentKg,
    required this.onChanged,
  });

  final double currentKg;
  final ValueChanged<double> onChanged;

  @override
  State<WeightSlider> createState() => _WeightSliderState();
}

class _WeightSliderState extends State<WeightSlider> {
  static const double minKg = 0.25;
  static const double maxKg = 3.0;
  static const double step = 0.25;

  late double _val;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _val = widget.currentKg;
  }

  @override
  void didUpdateWidget(WeightSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentKg != widget.currentKg) {
      _val = widget.currentKg;
    }
  }

  void _updatePosition(double localDx, double trackWidth) {
    final frac = (localDx / trackWidth).clamp(0.0, 1.0);
    final rawVal = minKg + frac * (maxKg - minKg);
    final stepped = (rawVal / step).round() * step;
    final clamped = stepped.clamp(minKg, maxKg);

    if (clamped != _val) {
      CaHaptics.selectionClick();
      setState(() {
        _val = clamped;
      });
      widget.onChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final frac = ((_val - minKg) / (maxKg - minKg)).clamp(0.0, 1.0);

    return Semantics(
      slider: true,
      label: 'Peso',
      value: formatWeight(_val),
      increasedValue: formatWeight((_val + step).clamp(minKg, maxKg)),
      decreasedValue: formatWeight((_val - step).clamp(minKg, maxKg)),
      onIncrease: () {
        final v = (_val + step).clamp(minKg, maxKg).toDouble();
        setState(() => _val = v);
        widget.onChanged(v);
      },
      onDecrease: () {
        final v = (_val - step).clamp(minKg, maxKg).toDouble();
        setState(() => _val = v);
        widget.onChanged(v);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: tokens.soft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            // .wsh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '¿Cuánto llevas?',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: tokens.ink2,
                  ),
                ),
                Text(
                  formatWeight(_val),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: tokens.ink,
                  ),
                ),
              ],
            ),
            // .wtrack: 36 px, margen 8 0 4
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (d) {
                      setState(() => _isDragging = true);
                      _updatePosition(d.localPosition.dx, w);
                    },
                    onPanUpdate: (d) => _updatePosition(d.localPosition.dx, w),
                    onPanEnd: (_) {
                      CaHaptics.lightImpact();
                      setState(() => _isDragging = false);
                    },
                    onPanCancel: () => setState(() => _isDragging = false),
                    onTapDown: (d) {
                      setState(() => _isDragging = true);
                      _updatePosition(d.localPosition.dx, w);
                    },
                    onTapUp: (_) => setState(() => _isDragging = false),
                    child: SizedBox(
                      height: 36,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 15,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCE2EE),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 15,
                            child: Container(
                              height: 6,
                              width: frac * w,
                              decoration: BoxDecoration(
                                color: tokens.blue,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          // pulgar de vidrio de 30 px que se estira al arrastrar
                          Positioned(
                            left: frac * w - 15,
                            top: 3,
                            child: AnimatedScale(
                              scale: _isDragging ? 1.12 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: Transform.scale(
                                scaleX: _isDragging ? 1.25 / 1.12 : 1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: .6),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: .8),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x590A1E5A),
                                            blurRadius: 12,
                                            spreadRadius: -2,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // .wtk
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final t in const ['250 g', '1 kg', '2 kg', '3 kg'])
                  Text(
                    t,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: tokens.ink3,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
