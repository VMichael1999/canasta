import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../shared/app_svg_icon.dart';
import '../tracking/chat_sheet.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _currentStep = 1; // 1: Issue, 2: Products, 3: Resolution, 4: Done
  String? _selectedIssue;
  final Set<String> _selectedProductIds = {};
  String _selectedResolution = 'wallet';

  final List<Map<String, String>> _issues = [
    {'id': 'miss', 'icon': 'box', 'name': 'Faltó un producto'},
    {'id': 'bad', 'icon': 'alert', 'name': 'Llegó en mal estado'},
    {'id': 'wrong', 'icon': 'swap', 'name': 'Recibí otro producto'},
    {'id': 'pay', 'icon': 'card', 'name': 'Problema con el pago'},
    {'id': 'late', 'icon': 'clock', 'name': 'Mi pedido se retrasa'},
  ];

  final List<Map<String, String>> _resolutions = [
    {
      'id': 'wallet',
      'icon': 'wallet',
      'name': 'Saldo Canasta',
      'desc': 'Al instante, para tu próxima compra',
    },
    {
      'id': 'refund',
      'icon': 'card',
      'name': 'Devolución a tu tarjeta',
      'desc': 'De 3 a 5 días hábiles',
    },
    {
      'id': 'resend',
      'icon': 'truck',
      'name': 'Envíenmelo de nuevo',
      'desc': 'Llega hoy, sin costo',
    },
  ];

  void _showChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const ChatSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final orders = context.watch<OrdersCubit>().state.orders;
    final order = orders.isNotEmpty ? orders.first : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(
          top: (MediaQuery.of(context).padding.top - 6).clamp(0.0, 80.0),
        ),
        child: Column(
          children: [
            // Top Bar (.top3)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_currentStep > 1 && _currentStep < 4) {
                        setState(() => _currentStep--);
                      } else {
                        context.pop();
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 34,
                      height: 44,
                      child: OverflowBox(
                        alignment: Alignment.centerRight,
                        minWidth: 44,
                        maxWidth: 44,
                        child: Center(
                          child: AppSvgIcon('arrowl', size: 24, color: tokens.ink),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Ayuda con tu pedido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.01 * 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: order == null
                    ? const Center(child: Text('No hay pedidos activos.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildStepContent(order, tokens)),
                          if (_currentStep == 2)
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _selectedProductIds.isNotEmpty
                                    ? () => setState(() => _currentStep = 3)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tokens.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Continuar',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          if (_currentStep == 3)
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () =>
                                    setState(() => _currentStep = 4),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tokens.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Enviar solicitud',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(dynamic order, CaTokens tokens) {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pedido ${order.id}',
                style: TextStyle(fontSize: 13.5, color: tokens.ink2)),
            const SizedBox(height: 2),
            Text(
              '¿Qué pasó?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _issues.length,
                separatorBuilder: (_, __) =>
                    Divider(color: tokens.line, height: 1),
                itemBuilder: (context, index) {
                  final issue = _issues[index];
                  return InkWell(
                    onTap: () {
                      _selectedIssue = issue['id'];
                      if (issue['id'] == 'pay' || issue['id'] == 'late') {
                        setState(() => _currentStep = 4);
                      } else {
                        setState(() => _currentStep = 2);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          AppSvgIcon(issue['icon']!,
                              size: 22, color: tokens.blue),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              issue['name']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                          AppSvgIcon('chev', size: 16, color: tokens.ink3),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Prefiero chatear button
            GestureDetector(
              onTap: () => _showChat(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.line),
                ),
                child: Row(
                  children: [
                    AppSvgIcon('chat', size: 22, color: tokens.blue),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prefiero chatear',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Te respondemos en menos de 5 min',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSvgIcon('chev', size: 16, color: tokens.ink3),
                  ],
                ),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _issues.firstWhere(
                  (i) => i['id'] == _selectedIssue)['name']!,
              style: TextStyle(fontSize: 13.5, color: tokens.ink2),
            ),
            const SizedBox(height: 2),
            Text(
              '¿Qué productos?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: order.items.length,
                separatorBuilder: (_, __) =>
                    Divider(color: tokens.line, height: 1),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  final isSel =
                      _selectedProductIds.contains(item.product.id);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSel) {
                          _selectedProductIds.remove(item.product.id);
                        } else {
                          _selectedProductIds.add(item.product.id);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: tokens.chip,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              CaAssets.product(item.product.id),
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatPen(item.total),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tokens.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSel ? tokens.blue : Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: isSel
                                  ? null
                                  : Border.all(
                                      color: tokens.border, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: isSel
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case 3:
        final selectedAmt = order.items
            .where((it) => _selectedProductIds.contains(it.product.id))
            .fold(0.0, (acc, it) => acc + it.total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo lo resolvemos?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Te devolvemos ${formatPen(selectedAmt)} por ${_selectedProductIds.length} producto${_selectedProductIds.length > 1 ? 's' : ''}.',
              style: TextStyle(fontSize: 14, color: tokens.ink2),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.line),
              ),
              child: Column(
                children: _resolutions.map((res) {
                  final isSel = _selectedResolution == res['id'];
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedResolution = res['id']!);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          AppSvgIcon(res['icon']!,
                              size: 22, color: tokens.blue),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  res['name']!,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  res['desc']!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: tokens.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? tokens.blue : tokens.border,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: isSel
                                ? Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tokens.blue,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.green,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Listo, ya lo resolvimos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedResolution == 'wallet'
                    ? 'Tienes saldo Canasta para tu próxima compra.'
                    : 'Devolveremos el monto a tu tarjeta en 3 a 5 días hábiles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: tokens.ink2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.line),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ticket',
                            style: TextStyle(fontSize: 14, color: tokens.ink2)),
                        const Text('T-8419',
                            style: TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pedido',
                            style: TextStyle(fontSize: 14, color: tokens.ink2)),
                        Text(order.id,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Volver a mis pedidos',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => _showChat(context),
                  child: Text('Escribir a soporte',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink2)),
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
