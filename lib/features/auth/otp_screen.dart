import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/session/session_bloc.dart';
import '../../core/haptics.dart';
import '../../core/tokens.dart';
import '../../shared/app_svg_icon.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _countdownTimer;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _resendCountdown = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _verifyCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    if (code == '482913') {
      CaHaptics.mediumImpact();
      setState(() {
        _isSuccess = true;
        _errorMessage = null;
      });
      context.read<SessionBloc>().add(OtpEntered(code));
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) context.go('/location');
      });
    } else {
      CaHaptics.heavyImpact();
      _shake.forward(from: 0);
      setState(() {
        _errorMessage =
            'Ese código no es correcto. Revisa el SMS e inténtalo otra vez.';
      });
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes.first.requestFocus();
      });
    }
  }

  void _pasteTestCode() {
    const code = '482913';
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = code[i];
    }
    _verifyCode();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final top = MediaQuery.of(context).padding.top;
    final phone = context.watch<SessionBloc>().state.phone.isEmpty
        ? '987 654 321'
        : context.watch<SessionBloc>().state.phone;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // .scroll (padding-top 110) + .auth (padding-top 110)
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                22, (top + 48).clamp(110.0, 140.0) + 118, 22, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 14),
                  child: Text(
                    'Verifica tu número',
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.65,
                      color: tokens.ink,
                    ),
                  ),
                ),
                Text(
                  'Escribe el código de 6 dígitos que enviamos al +51 $phone.',
                  style: TextStyle(
                      fontSize: 14.5, height: 1.35, color: tokens.ink2),
                ),
                // .otp
                AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final t = _shake.value;
                    final dx = t == 0 || t == 1
                        ? 0.0
                        : 8 * (t < .2 ? -t / .2 : t < .4 ? -1 + 2 * (t - .2) / .2 : t < .6 ? 1 - 2 * (t - .4) / .2 : t < .8 ? -1 + 2 * (t - .6) / .2 : 1 - (t - .8) / .2);
                    return Transform.translate(offset: Offset(dx, 0), child: child);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: Row(
                      children: List.generate(11, (k) {
                        if (k.isOdd) return const SizedBox(width: 9);
                        final index = k ~/ 2;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: _OtpBox(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              ok: _isSuccess,
                              onChanged: (val) {
                                if (val.isNotEmpty && index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (val.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                                _verifyCode();
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                // .err
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 18),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _errorMessage ?? '',
                      style: TextStyle(fontSize: 13, color: tokens.bad),
                    ),
                  ),
                ),
                // .resend
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 20),
                  child: _resendCountdown > 0
                      ? Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Reenviar código en '),
                              TextSpan(
                                text:
                                    '0:${_resendCountdown.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: tokens.ink,
                                ),
                              ),
                            ],
                          ),
                          style: TextStyle(fontSize: 14, color: tokens.ink2),
                        )
                      : GestureDetector(
                          onTap: _startCountdown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Reenviar código',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: tokens.blue,
                              ),
                            ),
                          ),
                        ),
                ),
                // .hintbox
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: tokens.blueSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: AppSvgIcon('info', size: 19, color: tokens.blue),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'En este prototipo, el código es '),
                              TextSpan(
                                text: '482913',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                  text: '. Puedes tocar «Pegar código».'),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: Color(0xFF2B3B6E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // .btn.line
                GestureDetector(
                  onTap: _pasteTestCode,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tokens.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Pegar código',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // .top2: botón volver
          Positioned(
            left: 22,
            top: top - 4 < 58 ? 58 : top - 4,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Semantics(
                button: true,
                label: 'Volver',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.border),
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon('arrowl', size: 21, color: tokens.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.ok,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool ok;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: ok ? tokens.greenSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ok
                  ? tokens.green
                  : (focused ? tokens.blue : tokens.border),
              width: ok ? 1.5 : (focused ? 2 : 1),
            ),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ok ? tokens.green : tokens.ink,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              isCollapsed: true,
            ),
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}
