import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/session/session_bloc.dart';
import '../../core/haptics.dart';
import '../../core/tokens.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
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
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) context.go('/home');
      });
    } else {
      CaHaptics.heavyImpact();
      setState(() {
        _errorMessage =
            'Ese código no es correcto. Revisa el SMS e inténtalo otra vez.';
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
    final phone = context.watch<SessionBloc>().state.phone;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Verifica tu número',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escribe el código de 6 dígitos que enviamos al +51 $phone.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: tokens.ink2,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),

              // 6 OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _isSuccess
                            ? tokens.green
                            : (_errorMessage != null ? tokens.bad : tokens.ink),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _isSuccess ? tokens.greenSoft : tokens.chip,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isSuccess
                                ? tokens.green
                                : (_errorMessage != null
                                    ? tokens.bad
                                    : tokens.border),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: tokens.blue,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _verifyCode();
                          }
                        } else if (index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.bad,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Reenviar countdown
              Center(
                child: Text(
                  _resendCountdown > 0
                      ? 'Reenviar código en ${_resendCountdown}s'
                      : '¿No recibiste el código? Reenviar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _resendCountdown > 0 ? tokens.ink3 : tokens.blue,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Hint box with test code
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.soft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: tokens.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'En este prototipo, el código es 482913. Puedes tocar «Pegar código».',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Paste code button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _pasteTestCode,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tokens.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Pegar código (482913)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
