import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/address/address_cubit.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/checkout/checkout_bloc.dart';
import '../../blocs/live_order/live_order_bloc.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../domain/models/courier.dart';
import '../../domain/models/order.dart';
import '../../domain/models/slot.dart';
import '../../shared/address_picker_sheet.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';
import '../../shared/slide_to_pay_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _noteController = TextEditingController();
  int _cashAmount = 0;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showSlotPicker(BuildContext context) {
    final tokens = context.tokens;
    int selectedDay = 0;
    int selectedHour = 10;

    final days = [
      'Hoy',
      'Mañana',
      'Pasado mañana',
      'En 3 días',
      'En 4 días',
      'En 5 días',
      'En 6 días',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setSheetState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8DCE5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Programa tu entrega',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige el día y una franja de una hora.',
                        style: TextStyle(fontSize: 14, color: tokens.ink2),
                      ),
                      const SizedBox(height: 8),

                      // Dual wheels: Day and Hour
                      SizedBox(
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF0FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            Row(
                              children: [
                                // Day wheel
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 40,
                                    diameterRatio: 3,
                                    perspective: 0.002,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (i) {
                                      setSheetState(() => selectedDay = i);
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                          builder: (
                                            BuildContext context,
                                            int index,
                                          ) {
                                            if (index < 0 ||
                                                index >= days.length)
                                              return null;
                                            final isSel = selectedDay == index;
                                            return Center(
                                              child: Text(
                                                days[index],
                                                style: TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight:
                                                      isSel
                                                          ? FontWeight.w700
                                                          : FontWeight.w400,
                                                  color:
                                                      isSel
                                                          ? tokens.blue
                                                          : tokens.ink2,
                                                ),
                                              ),
                                            );
                                          },
                                          childCount: days.length,
                                        ),
                                  ),
                                ),

                                // Hour wheel
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 40,
                                    diameterRatio: 3,
                                    perspective: 0.002,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (i) {
                                      setSheetState(() => selectedHour = 8 + i);
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                          builder: (
                                            BuildContext context,
                                            int index,
                                          ) {
                                            if (index < 0 || index > 13)
                                              return null;
                                            final int h = 8 + index;
                                            final slot = DeliverySlot(
                                              dayIndex: 0,
                                              hour: h,
                                            );
                                            final isSel = selectedHour == h;
                                            return Center(
                                              child: Text(
                                                slot.label,
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight:
                                                      isSel
                                                          ? FontWeight.w700
                                                          : FontWeight.w400,
                                                  color:
                                                      isSel
                                                          ? tokens.blue
                                                          : tokens.ink2,
                                                ),
                                              ),
                                            );
                                          },
                                          childCount: 14,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () {
                                  context.read<CheckoutBloc>().add(
                                    const CheckoutSlotPicked(null),
                                  );
                                  Navigator.of(ctx).pop();
                                  AppToast.show(
                                    context,
                                    'Entrega: Lo antes posible (35 a 50 min)',
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: tokens.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Lo antes posible',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  final slot = DeliverySlot(
                                    dayIndex: selectedDay,
                                    hour: selectedHour,
                                  );
                                  context.read<CheckoutBloc>().add(
                                    CheckoutSlotPicked(slot),
                                  );
                                  Navigator.of(ctx).pop();
                                  AppToast.show(
                                    context,
                                    'Entrega programada: ${slot.label}',
                                  );
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
                                  'Elegir horario',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _onCompleteOrder(
    BuildContext context,
    double total,
    String payMethod,
    double tip,
  ) {
    final cartState = context.read<CartBloc>().state;
    final address = context.read<AddressCubit>().state.selectedAddress;

    // Create completed order
    final newOrder = OrderModel(
      id: 'CA-${DateTime.now().millisecondsSinceEpoch % 100000}',
      items: cartState.lines,
      status: OrderStatus.onTheWay,
      subtotal: cartState.subtotal,
      discount: cartState.discount,
      fee: cartState.fee,
      tip: tip,
      total: total,
      addressLine: '${address.shortLine}, ${address.district}',
      paymentMethod:
          payMethod == 'yape'
              ? 'Yape'
              : payMethod == 'plin'
              ? 'Plin'
              : payMethod == 'cash'
              ? 'Efectivo'
              : 'Visa •••• 4821',
      courier: Courier.defaultCourier,
      createdAt: DateTime.now(),
    );

    // Update blocs
    context.read<OrdersCubit>().addOrder(newOrder);
    context.read<LiveOrderBloc>().add(LiveOrderSetOrder(newOrder));
    context.read<CartBloc>().add(const CartCleared());

    CaHaptics.heavyImpact();
    context.go('/order-done');
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
      body: Padding(
        padding: EdgeInsets.only(
          top: (MediaQuery.of(context).padding.top - 6).clamp(0.0, 80.0),
        ),
        child: Column(
          children: [
            // Top bar (.top3): flecha sin caja, título centrado
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Semantics(
                      button: true,
                      label: 'Volver',
                      child: SizedBox(
                        width: 34,
                        height: 44,
                        child: OverflowBox(
                          alignment: Alignment.centerRight,
                          minWidth: 44,
                          maxWidth: 44,
                          child: Center(
                            child: AppSvgIcon(
                              'back',
                              size: 24,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Confirma tu pedido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                        letterSpacing: -0.18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Entrega
                    Text(
                      'Entrega',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Column(
                        children: [
                          // Address row
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => AddressPickerSheet.show(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tokens.blueSoft,
                                    ),
                                    alignment: Alignment.center,
                                    child: AppSvgIcon(
                                      'pin',
                                      size: 18,
                                      color: tokens.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${address.tag} · ${address.shortLine}',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${address.district}${address.reference.isNotEmpty ? ' · ${address.reference}' : ''}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: tokens.ink2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppSvgIcon(
                                    'chev',
                                    size: 16,
                                    color: tokens.ink3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(color: tokens.line, height: 1),

                          // Delivery slot row
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showSlotPicker(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tokens.blueSoft,
                                    ),
                                    alignment: Alignment.center,
                                    child: AppSvgIcon(
                                      'clock',
                                      size: 18,
                                      color: tokens.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          checkoutState.slot != null
                                              ? checkoutState.slot!.label
                                              : 'Lo antes posible · 35 a 50 min',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          checkoutState.slot != null
                                              ? 'Programado'
                                              : 'Toca para programar',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: tokens.ink2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppSvgIcon(
                                    'chev',
                                    size: 16,
                                    color: tokens.ink3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section: Método de pago
                    Text(
                      'Método de pago',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tokens.line),
                      ),
                      child: Column(
                        children: [
                          _buildPayOption(
                            id: 'card',
                            icon: const AppSvgIcon(
                              'card',
                              size: 20,
                              color: Color(0xFF1A4FE0),
                            ),
                            title: 'Visa •••• 4821',
                            subtitle: 'Débito',
                            selectedId: checkoutState.paymentMethod,
                            tokens: tokens,
                          ),
                          Divider(color: tokens.line, height: 1),
                          _buildPayOption(
                            id: 'yape',
                            icon: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF820AD1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Y',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            title: 'Yape',
                            subtitle: 'Desde tu app',
                            selectedId: checkoutState.paymentMethod,
                            tokens: tokens,
                          ),
                          Divider(color: tokens.line, height: 1),
                          _buildPayOption(
                            id: 'plin',
                            icon: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A3FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'P',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            title: 'Plin',
                            subtitle: 'Desde tu app',
                            selectedId: checkoutState.paymentMethod,
                            tokens: tokens,
                          ),
                          Divider(color: tokens.line, height: 1),
                          _buildPayOption(
                            id: 'cash',
                            icon: const AppSvgIcon(
                              'cash',
                              size: 20,
                              color: Color(0xFF1A4FE0),
                            ),
                            title: 'Efectivo',
                            subtitle: 'Paga al recibir',
                            selectedId: checkoutState.paymentMethod,
                            tokens: tokens,
                          ),

                          // If cash selected, show chips
                          if (checkoutState.paymentMethod == 'cash') ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¿Con cuánto pagas?',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: tokens.ink2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children:
                                        [0, 50, 100, 200].map((v) {
                                          final isSelected = _cashAmount == v;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() => _cashAmount = v);
                                                CaHaptics.selectionClick();
                                                if (v > 0 && v < finalTotal) {
                                                  AppToast.show(
                                                    context,
                                                    'Elige un monto mayor a ${formatPen(finalTotal)}.',
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isSelected
                                                          ? tokens.blue
                                                          : tokens.chip,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  v == 0
                                                      ? 'Monto exacto'
                                                      : 'S/ $v',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : tokens.ink,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section: Propina para el repartidor
                    Text(
                      'Propina para el repartidor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children:
                          [0, 2, 3, 5].map((tipVal) {
                            final isSel = checkoutState.tip == tipVal;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<CheckoutBloc>().add(
                                      CheckoutTipChanged(tipVal.toDouble()),
                                    );
                                    CaHaptics.selectionClick();
                                    if (tipVal > 0) {
                                      AppToast.show(
                                        context,
                                        'Gracias. Carlos recibe toda la propina.',
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSel ? tokens.blue : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isSel ? tokens.blue : tokens.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      tipVal == 0 ? 'Ahora no' : 'S/ $tipVal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            isSel
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                        color:
                                            isSel ? Colors.white : tokens.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El 100 % de la propina es para Carlos, tu repartidor.',
                      style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                    ),
                    const SizedBox(height: 22),

                    // Section: Instrucciones
                    Text(
                      'Instrucciones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Por ejemplo, tocar el intercomunicador 302',
                        hintStyle: TextStyle(fontSize: 14, color: tokens.ink3),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: tokens.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: tokens.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: tokens.blue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section: Resumen
                    Text(
                      'Resumen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Product thumbnails (.cthumbs)
                    Row(
                      children: [
                        ...cartState.lines.take(5).map((l) {
                          return Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: tokens.chip,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(
                              CaAssets.product(l.product.id),
                              fit: BoxFit.contain,
                            ),
                          );
                        }),
                        if (cartState.lines.length > 5) ...[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: tokens.blueSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+${cartState.lines.length - 5}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: tokens.blue,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '${cartState.units} productos',
                          style: TextStyle(fontSize: 13, color: tokens.ink2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Summary breakdown
                    _buildSummaryRow('Subtotal', cartState.subtotal, tokens),
                    const SizedBox(height: 8),
                    if (cartState.discount > 0) ...[
                      _buildSummaryRow(
                        'Descuento (${cartState.coupon?.code ?? ''})',
                        -cartState.discount,
                        tokens,
                        isDiscount: true,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildSummaryRow(
                      'Delivery',
                      cartState.fee,
                      tokens,
                      isFree: cartState.fee == 0,
                    ),
                    if (checkoutState.tip > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Propina',
                        checkoutState.tip.toDouble(),
                        tokens,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Divider(color: tokens.line, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        Text(
                          formatPen(finalTotal),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: tokens.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Pay Bar (.paybar)
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 38),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4D0A1E5A),
                    blurRadius: 24,
                    spreadRadius: -18,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: SlideToPayButton(
                totalAmount: finalTotal,
                paymentMethod: checkoutState.paymentMethod,
                onCompleted:
                    () => _onCompleteOrder(
                      context,
                      finalTotal,
                      checkoutState.paymentMethod,
                      checkoutState.tip.toDouble(),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayOption({
    required String id,
    required Widget icon,
    required String title,
    required String subtitle,
    required String selectedId,
    required CaTokens tokens,
  }) {
    final isSelected = id == selectedId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.read<CheckoutBloc>().add(CheckoutPaymentChanged(id));
        CaHaptics.selectionClick();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 32, height: 32, child: Center(child: icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: tokens.ink2),
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
                  color: isSelected ? tokens.blue : tokens.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child:
                  isSelected
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
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    CaTokens tokens, {
    bool isDiscount = false,
    bool isFree = false,
  }) {
    String valueStr = formatPen(amount.abs());
    if (isDiscount) valueStr = '− $valueStr';
    if (isFree) valueStr = 'Gratis';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: tokens.ink2)),
        Text(
          valueStr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: (isDiscount || isFree) ? tokens.green : tokens.ink,
          ),
        ),
      ],
    );
  }
}
