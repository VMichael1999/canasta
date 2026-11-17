import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';

class OrderDoneScreen extends StatelessWidget {
  const OrderDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final orders = context.watch<OrdersCubit>().state.orders;
    final order = orders.isNotEmpty ? orders.first : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),
              // Animated check icon / seal
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.greenSoft,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: tokens.green,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                '¡Pedido confirmado!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estamos preparando tus productos frescos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: tokens.ink2,
                ),
              ),
              const SizedBox(height: 32),

              // Order detail card
              if (order != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: tokens.chip,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tokens.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Número de pedido',
                              style: TextStyle(fontSize: 13.5, color: tokens.ink2)),
                          Text(
                            order.id,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hora estimada',
                              style: TextStyle(fontSize: 13.5, color: tokens.ink2)),
                          Text(
                            'Hoy, en 35 a 50 min',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Método de pago',
                              style: TextStyle(fontSize: 13.5, color: tokens.ink2)),
                          Text(
                            order.paymentMethod,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total pagado',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          Text(
                            formatPen(order.total),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Primary: Seguir mi pedido
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go('/tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Seguir mi pedido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary: Volver al inicio
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Volver al inicio',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink2,
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
