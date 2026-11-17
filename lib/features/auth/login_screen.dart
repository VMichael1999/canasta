import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/session/session_bloc.dart';
import '../../core/assets.dart';
import '../../core/tokens.dart';
import '../../shared/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController(text: '987 654 321');
  String? _error;
  bool _sending = false;

  void _submit() {
    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length != 9 || !raw.startsWith('9')) {
      setState(() {
        _error = 'Escribe un celular de 9 dígitos que empiece con 9.';
      });
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    context.read<SessionBloc>().add(PhoneSubmitted(_phoneController.text));
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _sending = false);
      context.push('/otp');
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, (top + 48).clamp(110.0, 140.0), 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // .alogo 72 × 72
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(CaAssets.logo, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 14),
              child: Text(
                'Ingresa tu celular',
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
              'Te enviaremos un código por SMS para entrar. Sin contraseñas.',
              style: TextStyle(fontSize: 14.5, height: 1.35, color: tokens.ink2),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                'Número de celular',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink,
                ),
              ),
            ),
            // .phf
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _error != null ? tokens.bad : tokens.border,
                  width: _error != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: tokens.border, width: 1),
                      ),
                    ),
                    child: Text(
                      '🇵🇪 +51',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      onChanged: (v) {
                        final d = v.replaceAll(RegExp(r'\D'), '');
                        final t = d.length > 9 ? d.substring(0, 9) : d;
                        final parts = <String>[
                          t.substring(0, t.length.clamp(0, 3)),
                          if (t.length > 3) t.substring(3, t.length.clamp(3, 6)),
                          if (t.length > 6) t.substring(6),
                        ];
                        final f = parts.join(' ');
                        if (f != v) {
                          _phoneController.value = TextEditingValue(
                            text: f,
                            selection: TextSelection.collapsed(offset: f.length),
                          );
                        }
                        if (_error != null) setState(() => _error = null);
                      },
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .34,
                        color: tokens.ink,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // .err
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 18),
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  _error ?? '',
                  style: TextStyle(fontSize: 13, color: tokens.bad),
                ),
              ),
            ),
            // Continuar
            GestureDetector(
              onTap: _sending ? null : _submit,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: _sending ? const Color(0xFFB9C9F5) : tokens.blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _sending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                              backgroundColor: Color(0x59FFFFFF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Enviando código…',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            // .or
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Container(height: 1, color: tokens.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'o continúa con',
                      style: TextStyle(fontSize: 13, color: tokens.ink3),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: tokens.line)),
                ],
              ),
            ),
            // .socs
            Row(
              children: [
                for (final (i, name) in const ['Google', 'Apple'].indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.go('/location');
                        AppToast.show(context, 'Entraste con $name.');
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tokens.border),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              name == 'Google'
                                  ? 'assets/images/google_logo.png'
                                  : 'assets/images/apple_logo.png',
                              height: 20,
                              width: name == 'Google' ? 20 : 17,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Al continuar aceptas los Términos y la Política de privacidad.',
                style: TextStyle(fontSize: 12.5, height: 1.35, color: tokens.ink3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
