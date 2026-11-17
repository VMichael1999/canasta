import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/address/address_cubit.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/checkout/checkout_bloc.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../domain/models/order.dart';
import '../../domain/models/slot.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/hold_to_pay_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showSlotPicker(BuildContext context) {
    final tokens = context.tokens;
    int selectedDay = 0;
    int selectedHour = 10;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: 380,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Elegir horario de entrega',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context
                          .read<CheckoutBloc>()
                          .add(const CheckoutSlotPicked(null));
                      Navigator.of(ctx).pop();
                    },
                    child: Text(
                      'Lo antes posible',
                      style: TextStyle(
                        color: tokens.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Wheel Selectors (Day and Hour Slot)
              Expanded(
                child: Row(
                  children: [
                    // Day column
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 44,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) {
                          setSheetState(() => selectedDay = i);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (BuildContext context, int index) {
                            if (index < 0 || index >= 7) return null;
                            final label = index == 0
                                ? 'Hoy'
                                : (index == 1 ? 'Mañana' : 'Día +$index');
                            return Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: selectedDay == index
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selectedDay == index
                                      ? tokens.blue
                                      : tokens.ink2,
                                ),
                              ),
                            );
                          },
                          childCount: 7,
                        ),
                      ),
                    ),
                    // Hour column
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 44,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (i) {
                          setSheetState(() => selectedHour = 8 + i);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (BuildContext context, int index) {
                            if (index < 0 || index > 12) return null;
                            final int h = 8 + index;
                            final slot = DeliverySlot(dayIndex: 0, hour: h);
                            return Center(
                              child: Text(
                                slot.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: selectedHour == h
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selectedHour == h
                                      ? tokens.blue
                                      : tokens.ink2,
                                ),
                              ),
                            );
                          },
                          childCount: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CheckoutBloc>().add(
                          CheckoutSlotPicked(
                            DeliverySlot(
                              dayIndex: selectedDay,
                              hour: selectedHour,
                            ),
                          ),
                        );
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirmar horario',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final address = context.watch<AddressCubit>().state.selectedAddress;
    final cartState = context.watch<CartBloc>().state;
    final checkoutState = context.watch<CheckoutBloc>().state;

    final finalTotal = cartState.total + checkoutState.tip;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Confirma tu pedido',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entrega Section
                  Text(
                    'Entrega',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.blueSoft,
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon('pin',
                                size: 18, color: tokens.blue),
                          ),
                          title: Text(
                            '${address.tag} · ${address.shortLine}',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          subtitle: Text(
                            '${address.district}${address.reference.isNotEmpty ? ' · ${address.reference}' : ''}',
                            style:
                                TextStyle(fontSize: 12.5, color: tokens.ink2),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: tokens.ink3),
                          onTap: () => context.push('/location'),
                        ),
                        Divider(color: tokens.line, height: 1),
                        ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.blueSoft,
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon('clock',
                                size: 18, color: tokens.blue),
                          ),
                          title: Text(
                            checkoutState.slot != null
                                ? checkoutState.slot!.label
                                : 'Lo antes posible · 35 a 50 min',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          subtitle: Text(
                            checkoutState.slot != null
                                ? 'Entrega programada'
                                : 'Toca para programar horario',
                            style:
                                TextStyle(fontSize: 12.5, color: tokens.ink2),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: tokens.ink3),
                          onTap: () => _showSlotPicker(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Método de pago Section
                  Text(
                    'Método de pago',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Column(
                      children: [
                        _buildPaymentOption(
                          context,
                          id: 'card',
                          icon: 'card',
                          title: 'Visa •••• 4821',
                          subtitle: 'Tarjeta de débito',
                          current: checkoutState.paymentMethod,
                          tokens: tokens,
                        ),
                        Divider(color: tokens.line, height: 1),
                        _buildPaymentOption(
                          context,
                          id: 'yape',
                          icon: 'phone',
                          title: 'Yape',
                          subtitle: 'Pago rápido desde tu app',
                          current: checkoutState.paymentMethod,
                          tokens: tokens,
                        ),
                        Divider(color: tokens.line, height: 1),
                        _buildPaymentOption(
                          context,
                          id: 'plin',
                          icon: 'phone',
                          title: 'Plin',
                          subtitle: 'Pago sin comisiones',
                          current: checkoutState.paymentMethod,
                          tokens: tokens,
                        ),
                        Divider(color: tokens.line, height: 1),
                        _buildPaymentOption(
                          context,
                          id: 'cash',
                          icon: 'wallet',
                          title: 'Efectivo',
                          subtitle: 'Paga al repartidor al recibir',
                          current: checkoutState.paymentMethod,
                          tokens: tokens,
                        ),
                      ],
                    ),
                  ),

                  // Cash change options (if cash selected)
                  if (checkoutState.paymentMethod == 'cash') ...[
                    const SizedBox(height: 14),
                    Text(
                      '¿Con cuánto pagas?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [0.0, 50.0, 100.0, 200.0].map((amt) {
                        final isSel = checkoutState.cashAmount == amt;
                        final label = amt == 0.0 ? 'Monto exacto' : 'S/ ${amt.toInt()}';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSel,
                            onSelected: (_) {
                              context
                                  .read<CheckoutBloc>()
                                  .add(CheckoutCashChanged(amt));
                            },
                            selectedColor: tokens.blue,
                            backgroundColor: tokens.chip,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : tokens.ink,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(19),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Propina Section
                  Text(
                    'Propina para el repartidor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [0.0, 2.0, 3.0, 5.0].map((tip) {
                      final isSel = checkoutState.tip == tip;
                      final label = tip == 0.0 ? 'Ahora no' : 'S/ ${tip.toInt()}';
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(child: Text(label)),
                            selected: isSel,
                            onSelected: (_) {
                              context
                                  .read<CheckoutBloc>()
                                  .add(CheckoutTipChanged(tip));
                            },
                            selectedColor: tokens.blue,
                            backgroundColor: tokens.chip,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : tokens.ink,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            showCheckmark: false,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El 100 % de la propina es para Carlos, tu repartidor.',
                    style: TextStyle(fontSize: 12, color: tokens.ink2),
                  ),
                  const SizedBox(height: 24),

                  // Instrucciones / Notas
                  Text(
                    'Instrucciones de entrega',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Dejar en portería, timbre no funciona…',
                      hintStyle:
                          TextStyle(fontSize: 14, color: tokens.ink3),
                      filled: true,
                      fillColor: tokens.chip,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resumen del pedido
                  Text(
                    'Resumen del pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Product Thumbnails Row
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cartState.lines.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = cartState.lines[index];
                        return Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: tokens.chip,
                            borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 16),
                  _buildSummaryRow('Subtotal', cartState.subtotal, tokens),
                  if (cartState.discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Descuento',
                      -cartState.discount,
                      tokens,
                      isDiscount: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildSummaryRow('Delivery', cartState.fee, tokens,
                      isFree: cartState.fee == 0),
                  if (checkoutState.tip > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                        'Propina', checkoutState.tip, tokens),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total a pagar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: tokens.ink,
                        ),
                      ),
                      Text(
                        formatPen(finalTotal),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: tokens.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Fixed Bottom Hold To Pay Button
            Positioned(
              left: 22,
              right: 22,
              bottom: 24,
              child: HoldToPayButton(
                totalAmount: finalTotal,
                paymentMethod: checkoutState.paymentMethod,
                onCompleted: () {
                  // Create order and add to OrdersCubit
                  final newOrder = OrderModel(
                    id: 'CA-87655',
                    items: List.from(cartState.lines),
                    subtotal: cartState.subtotal,
                    fee: cartState.fee,
                    tip: checkoutState.tip,
                    discount: cartState.discount,
                    total: finalTotal,
                    createdAt: DateTime.now(),
                    status: OrderStatus.confirmed,
                    addressLine: '${address.tag} · ${address.shortLine}',
                    paymentMethod: checkoutState.paymentMethod == 'card'
                        ? 'Visa •••• 4821'
                        : checkoutState.paymentMethod.toUpperCase(),
                    slot: checkoutState.slot,
                  );

                  context.read<OrdersCubit>().addOrder(newOrder);
                  context.read<CartBloc>().add(const CartCleared());
                  context.go('/order-done');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required String id,
    required String icon,
    required String title,
    required String subtitle,
    required String current,
    required CaTokens tokens,
  }) {
    final isSel = current == id;

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.blueSoft,
        ),
        alignment: Alignment.center,
        child: AppSvgIcon(icon, size: 18, color: tokens.blue),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
          color: tokens.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: tokens.ink2),
      ),
      trailing: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSel ? tokens.blue : tokens.border,
            width: isSel ? 6 : 1.5,
          ),
        ),
      ),
      onTap: () {
        context.read<CheckoutBloc>().add(CheckoutPaymentChanged(id));
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    CaTokens tokens, {
    bool isDiscount = false,
    bool isFree = false,
  }) {
    String valueStr = formatPen(amount.abs());
    if (isDiscount) valueStr = '-$valueStr';
    if (isFree) valueStr = 'Gratis';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: tokens.ink2)),
        Text(
          valueStr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: (isDiscount || isFree) ? tokens.green : tokens.ink,
          ),
        ),
      ],
    );
  }
}
