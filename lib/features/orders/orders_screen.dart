import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../domain/models/order.dart';
import '../../shared/app_svg_icon.dart';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
              child: Text(
                'Mis pedidos',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                  letterSpacing: -0.02 * 26,
                ),
              ),
            ),

            // Segment control (.seg)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                height: 48,
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
                          CaHaptics.selectionClick();
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: currentSegment == 'now'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: currentSegment == 'now'
                                ? const [
                                    BoxShadow(
                                      color: Color(0x240A1E5A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
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
                                  : FontWeight.w600,
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
                          CaHaptics.selectionClick();
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: currentSegment == 'past'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: currentSegment == 'past'
                                ? const [
                                    BoxShadow(
                                      color: Color(0x240A1E5A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
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
                                  : FontWeight.w600,
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
            const SizedBox(height: 16),

            // Orders list
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tokens.blueSoft,
                              ),
                              alignment: Alignment.center,
                              child: AppSvgIcon(
                                currentSegment == 'now' ? 'truck' : 'orders',
                                size: 44,
                                color: tokens.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentSegment == 'now'
                                  ? 'Nada en camino'
                                  : 'Aún no tienes pedidos anteriores',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentSegment == 'now'
                                  ? 'Cuando hagas un pedido, lo verás aquí.'
                                  : 'Tus compras aparecerán aquí para volver a pedirlas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: tokens.ink2,
                              ),
                            ),
                            if (currentSegment == 'now') ...[
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: () => context.go('/home'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tokens.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                child: const Text(
                                  'Ir a comprar',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 110),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
          // Order ID & status (.oh)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLive ? 'En camino' : 'Hoy · Entregado',
                    style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                  ),
                ],
              ),
              if (isLive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.blueSoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${order.etaMinutes} min',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.blue,
                    ),
                  ),
                )
              else
                Text(
                  formatPen(order.total),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Tiles (.tiles)
          Row(
            children: [
              for (int i = 0; i < order.items.length && i < 5; i++)
                Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: tokens.soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    CaAssets.product(order.items[i].product.id),
                    fit: BoxFit.contain,
                  ),
                ),
              if (order.items.length > 5)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tokens.soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+${order.items.length - 5}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.blue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons (.ob)
          Row(
            children: [
              if (isLive) ...[
                ElevatedButton(
                  onPressed: () => context.push('/tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Seguir pedido',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => context.push('/help'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tokens.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  child: Text('Ayuda',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink)),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<CartBloc>().add(CartReordered(order.items));
                    AppToast.show(
                      context,
                      'Agregamos ${order.items.length} productos a tu carrito.',
                      actionLabel: 'Ver carrito',
                      onAction: () => context.push('/cart'),
                    );
                  },
                  icon: const AppSvgIcon('swap', size: 15, color: Colors.white),
                  label: const Text('Volver a pedir',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                if (!order.rated) ...[
                  OutlinedButton(
                    onPressed: () => context.push('/rate'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: tokens.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text('Calificar',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink)),
                  ),
                ] else ...[
                  Row(
                    children: List.generate(
                      order.ratingStars > 0 ? order.ratingStars : 5,
                      (_) => const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFF59E0B)),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/help'),
                  child: Text(
                    'Ayuda',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.blue,
                    ),
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
