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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header row: "¿Cuánto llevas?" & "1.5 kg"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '¿Cuánto llevas?',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
              Text(
                formatWeight(_val),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Slider Track and Thumb
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final thumbLeft = (frac * trackWidth - 15).clamp(0.0, trackWidth - 30);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) {
                  setState(() => _isDragging = true);
                  _updatePosition(d.localPosition.dx, trackWidth);
                },
                onPanUpdate: (d) {
                  _updatePosition(d.localPosition.dx, trackWidth);
                },
                onPanEnd: (_) {
                  setState(() => _isDragging = false);
                },
                onPanCancel: () {
                  setState(() => _isDragging = false);
                },
                child: SizedBox(
                  height: 36,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Inactive Track
                      Container(
                        height: 6,
                        width: trackWidth,
                        decoration: BoxDecoration(
                          color: tokens.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // Active Track
                      Container(
                        height: 6,
                        width: frac * trackWidth,
                        decoration: BoxDecoration(
                          color: tokens.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // Thumb (30px glass/styled thumb that stretches slightly when dragging)
                      Positioned(
                        left: thumbLeft,
                        child: AnimatedScale(
                          scale: _isDragging ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: tokens.blue, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: tokens.blue.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tokens.blue,
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
          const SizedBox(height: 8),

          // Tick marks: 250 g · 1 kg · 2 kg · 3 kg
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTick('250 g', tokens),
              _buildTick('1 kg', tokens),
              _buildTick('2 kg', tokens),
              _buildTick('3 kg', tokens),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTick(String text, CaTokens tokens) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.ink3,
      ),
    );
  }
}
