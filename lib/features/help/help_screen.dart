import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/tokens.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _currentStep = 1; // 1: Issue, 2: Products, 3: Resolution, 4: Done
  String? _selectedIssue;
  final Set<String> _selectedProductIds = {};
  String? _selectedResolution;

  final List<String> _issues = [
    'Faltó un producto',
    'Llegó en mal estado',
    'Recibí otro producto',
    'Problema con el pago',
    'Mi pedido se retrasa',
  ];

  final List<String> _resolutions = [
    'Saldo Canasta al instante',
    'Devolución a tu tarjeta en 3 a 5 días',
    'Envíenmelo de nuevo sin costo',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final order = context.watch<OrdersCubit>().state.orders.first;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 4) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Ayuda con tu pedido',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              if (_currentStep < 4) ...[
                Row(
                  children: List.generate(3, (index) {
                    final isPassed = index + 1 <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isPassed ? tokens.blue : tokens.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
              ],

              Expanded(child: _buildStepContent(order, tokens)),

              // Action button
              if (_currentStep < 4)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canProceed()
                        ? () {
                            setState(() {
                              _currentStep++;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep == 3 ? 'Confirmar solución' : 'Continuar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

  bool _canProceed() {
    if (_currentStep == 1) return _selectedIssue != null;
    if (_currentStep == 2) return _selectedProductIds.isNotEmpty;
    if (_currentStep == 3) return _selectedResolution != null;
    return true;
  }

  Widget _buildStepContent(dynamic order, CaTokens tokens) {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué pasó con tu pedido?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona el motivo para ayudarte rápidamente.',
              style: TextStyle(fontSize: 14.5, color: tokens.ink2),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _issues.length,
                separatorBuilder: (_, __) =>
                    Divider(color: tokens.line, height: 1),
                itemBuilder: (context, index) {
                  final issue = _issues[index];
                  final isSel = _selectedIssue == issue;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      issue,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? tokens.blue : tokens.ink,
                      ),
                    ),
                    trailing: isSel
                        ? Icon(Icons.check_circle, color: tokens.blue)
                        : null,
                    onTap: () => setState(() => _selectedIssue = issue),
                  );
                },
              ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Con qué productos tuviste el problema?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Marca uno o varios productos de tu pedido.',
              style: TextStyle(fontSize: 14.5, color: tokens.ink2),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: order.items.length,
                separatorBuilder: (_, __) =>
                    Divider(color: tokens.line, height: 1),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  final isSel = _selectedProductIds.contains(item.product.id);

                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isSel,
                    activeColor: tokens.blue,
                    secondary: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: tokens.chip,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        CaAssets.product(item.product.id),
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: Text(
                      item.product.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedProductIds.add(item.product.id);
                        } else {
                          _selectedProductIds.remove(item.product.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo prefieres resolverlo?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige la opción que mejor se acomode a ti.',
              style: TextStyle(fontSize: 14.5, color: tokens.ink2),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _resolutions.length,
                separatorBuilder: (_, __) =>
                    Divider(color: tokens.line, height: 1),
                itemBuilder: (context, index) {
                  final res = _resolutions[index];
                  final isSel = _selectedResolution == res;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      res,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? tokens.blue : tokens.ink,
                      ),
                    ),
                    trailing: isSel
                        ? Icon(Icons.check_circle, color: tokens.blue)
                        : null,
                    onTap: () => setState(() => _selectedResolution = res),
                  );
                },
              ),
            ),
          ],
        );

      case 4:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.greenSoft,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.check_circle_rounded,
                    size: 50, color: tokens.green),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Listo, ya lo resolvimos!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generamos el ticket de soporte T-8419 con la solución elegida: $_selectedResolution.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: tokens.ink2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Volver al inicio',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
