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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBox(hours),
        _buildSeparator(),
        _buildBox(minutes),
        _buildSeparator(),
        _buildBox(seconds),
      ],
    );
  }

  Widget _buildBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: widget.isLight
            ? Colors.white
            : const Color(0xFF121A33), // toast dark color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
          color: widget.isLight ? const Color(0xFF0B2A73) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: widget.isLight ? Colors.white : const Color(0xFF121A33),
        ),
      ),
    );
  }
}
