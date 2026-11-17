import 'dart:async';
import 'package:flutter/material.dart';
import '../core/haptics.dart';
import '../core/tokens.dart';
import 'app_svg_icon.dart';

class HoldToPayButton extends StatefulWidget {
  const HoldToPayButton({
    super.key,
    required this.totalAmount,
    required this.paymentMethod,
    required this.onCompleted,
    this.enabled = true,
  });

  final double totalAmount;
  final String paymentMethod;
  final VoidCallback onCompleted;
  final bool enabled;

  @override
  State<HoldToPayButton> createState() => _HoldToPayButtonState();
}

class _HoldToPayButtonState extends State<HoldToPayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _holdTimer;
  bool _isPaying = false;
  bool _shake = false;
  String? _hintText;

  @override
  void initState() {
    super.initState();
    final durationMs = widget.paymentMethod == 'cash' ? 600 : 1000;
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(HoldToPayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paymentMethod != widget.paymentMethod) {
      final durationMs = widget.paymentMethod == 'cash' ? 600 : 1000;
      _animController.duration = Duration(milliseconds: durationMs);
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled || _isPaying) return;
    setState(() {
      _hintText = null;
      _shake = false;
    });

    CaHaptics.lightImpact();
    _animController.forward();

    _holdTimer = Timer(_animController.duration!, () {
      if (!mounted) return;
      CaHaptics.mediumImpact();
      setState(() {
        _isPaying = true;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        widget.onCompleted();
      });
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isPaying) return;
    _holdTimer?.cancel();
    if (_animController.value < 1.0) {
      _animController.reverse();
      CaHaptics.lightImpact();
      setState(() {
        _shake = true;
        _hintText = 'Mantén presionado hasta que el anillo se llene.';
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _shake = false);
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isPaying) return;
    _holdTimer?.cancel();
    _animController.reverse();
  }

  String get _buttonText {
    if (_isPaying) {
      if (widget.paymentMethod == 'yape') return 'Aprobando en Yape…';
      if (widget.paymentMethod == 'plin') return 'Aprobando en Plin…';
      return 'Procesando pago…';
    }
    return 'Mantén para pagar';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final progress = _animController.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hintText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _hintText!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.bad,
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          transform: Matrix4.translationValues(_shake ? 6.0 : 0.0, 0.0, 0.0),
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isPaying ? tokens.green : tokens.blue,
                borderRadius: BorderRadius.circular(CaTokens.payBtnRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CaTokens.payBtnRadius),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Darker fill expanding from left to right as you hold
                    if (!_isPaying)
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(color: tokens.blueDeep),
                      ),

                    // Button content: Lock ring on the left + Text + Price on the right
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Lock ring / spinner
                          if (_isPaying)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          else
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                                  ),
                                  const AppSvgIcon(
                                    'lock',
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 14),

                          // Text
                          Expanded(
                            child: Text(
                              _buttonText,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Arrow or check
                          const AppSvgIcon(
                            'arrow',
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
