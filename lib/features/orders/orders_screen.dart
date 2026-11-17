import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../domain/models/order.dart';
import '../../shared/app_toast.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = context.watch<OrdersCubit>().state;
    final currentSegment = state.selectedSegment;
    final orders = state.currentSegmentOrders;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mis pedidos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segment Control: En curso / Anteriores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tokens.chip,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.read<OrdersCubit>().setSegment('now');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: currentSegment == 'now'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: currentSegment == 'now'
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'En curso',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: currentSegment == 'now'
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: currentSegment == 'now'
                                  ? tokens.ink
                                  : tokens.ink2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.read<OrdersCubit>().setSegment('past');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: currentSegment == 'past'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: currentSegment == 'past'
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Anteriores',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: currentSegment == 'past'
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: currentSegment == 'past'
                                  ? tokens.ink
                                  : tokens.ink2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orders list
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Text(
                        'No tienes pedidos en esta sección.',
                        style: TextStyle(fontSize: 14.5, color: tokens.ink2),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(context, order, tokens);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, OrderModel order, CaTokens tokens) {
    final isLive = order.status != OrderStatus.delivered;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & status tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedido #${order.id.replaceAll('CA-', '')}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive ? tokens.blueSoft : tokens.chip,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLive ? 'En camino' : 'Entregado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLive ? tokens.blue : tokens.ink2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thumbnails
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tokens.chip,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    CaAssets.product(item.product.id),
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Total and item count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} productos · ${formatPen(order.total)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink2,
                ),
              ),
              if (!isLive && order.rated)
                Row(
                  children: List.generate(
                    order.ratingStars,
                    (_) => Icon(Icons.star_rounded,
                        size: 16, color: tokens.sun),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            children: [
              if (isLive)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/tracking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Seguir pedido',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                )
              else ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context
                          .read<CartBloc>()
                          .add(CartReordered(order.items));
                      AppToast.show(
                        context,
                        'Agregamos ${order.items.length} productos a tu carrito.',
                        actionLabel: 'Ver carrito',
                        onAction: () => context.push('/cart'),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: tokens.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Volver a pedir'),
                  ),
                ),
                const SizedBox(width: 10),
                if (!order.rated)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push('/rate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.blueSoft,
                        foregroundColor: tokens.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Calificar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.push('/help'),
                      child: Text('Ayuda',
                          style: TextStyle(
                              color: tokens.ink2,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
