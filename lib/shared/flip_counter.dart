import 'dart:async';
import 'package:flutter/material.dart';

class FlipCounter extends StatefulWidget {
  const FlipCounter({super.key, this.isLight = false});

  final bool isLight;

  @override
  State<FlipCounter> createState() => _FlipCounterState();
}

class _FlipCounterState extends State<FlipCounter> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(_calculateRemaining);
      }
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _remaining = endOfDay.difference(now);
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    // Individual digits matching HTML prototype: .flip .dg (20x26, r=6)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDigit(hours[0]),
        const SizedBox(width: 2),
        _buildDigit(hours[1]),
        _buildSeparator(),
        _buildDigit(minutes[0]),
        const SizedBox(width: 2),
        _buildDigit(minutes[1]),
        _buildSeparator(),
        _buildDigit(seconds[0]),
        const SizedBox(width: 2),
        _buildDigit(seconds[1]),
      ],
    );
  }

  Widget _buildDigit(String d) {
    return Container(
      width: 19,
      height: 25,
      decoration: BoxDecoration(
        color: widget.isLight ? Colors.white : const Color(0xFF121A33),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Middle split seam line matching .flip .dg::after
          Positioned(
            left: 0,
            right: 0,
            top: 12,
            child: Container(
              height: 1,
              color: widget.isLight
                  ? const Color(0x1A0B2A73)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Text(
            d,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: widget.isLight
                  ? const Color(0xFF0B2A73)
                  : Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: widget.isLight
              ? Colors.white
              : const Color(0xFF0F1324),
          height: 1.0,
        ),
      ),
    );
  }
}
