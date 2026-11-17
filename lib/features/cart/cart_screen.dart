import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/address/address_cubit.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/favorites/favorites_cubit.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../domain/models/cart_item.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';
import '../../shared/free_delivery_progress.dart';
import '../../shared/qty_stepper.dart';
import '../../shared/scratch_coupon_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isEditing = false;
  final Set<String> _selectedItems = {};

  void _showDiscountSheet(BuildContext context) {
    final tokens = context.tokens;
    final codeCtrl = TextEditingController();
    String? err;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Código de descuento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Escríbelo tal como te llegó. Prueba con FRESCO15.',
                  style: TextStyle(fontSize: 14, color: tokens.ink2),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Por ejemplo, FRESCO15',
                    errorText: err,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final code = codeCtrl.text.trim().toUpperCase();
                      if (code.isEmpty) {
                        setSheetState(() => err = 'Escribe un código.');
                        return;
                      }
                      if (code != 'FRESCO15' &&
                          code != 'CANASTA10' &&
                          code != 'HOLA20') {
                        setSheetState(() =>
                            err = 'El código «$code» no existe o ya venció.');
                        return;
                      }

                      context.read<CartBloc>().add(CartCouponApplied(code));
                      Navigator.of(ctx).pop();
                      AppToast.show(
                        context,
                        'Cupón $code aplicado.',
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
                    child: const Text('Aplicar código',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final address = context.watch<AddressCubit>().state.selectedAddress;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final isEmpty = state.lines.isEmpty;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi carrito',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${state.units} productos',
                  style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                ),
              ],
            ),
            actions: [
              if (!isEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      _selectedItems.clear();
                    });
                  },
                  child: Text(
                    _isEditing ? 'Listo' : 'Editar',
                    style: TextStyle(
                      color: tokens.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
            ],
          ),
          body: isEmpty
              ? _buildEmptyState(context, tokens)
              : SafeArea(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 10, 22, 160),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Free delivery progress
                            FreeDeliveryProgress(
                              missingAmount: state.missingForFree,
                              progress: state.freeDeliveryProgress,
                              hasFreeDelivery: state.hasFreeDelivery,
                            ),
                            const SizedBox(height: 20),

                            // Edit Mode Bulk Delete Button
                            if (_isEditing && _selectedItems.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final toRemove = _selectedItems.toList();
                                      context.read<CartBloc>().add(
                                            CartMultipleRemoved(toRemove),
                                          );
                                      final count = toRemove.length;
                                      setState(() {
                                        _selectedItems.clear();
                                        _isEditing = false;
                                      });
                                      AppToast.show(
                                        context,
                                        'Quitaste $count producto${count > 1 ? 's' : ''}.',
                                        actionLabel: 'Deshacer',
                                        onAction: () {
                                          context
                                              .read<CartBloc>()
                                              .add(const CartUndoRemove());
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    label: Text(
                                      'Quitar ${_selectedItems.length} seleccionado${_selectedItems.length > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: tokens.bad,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Items List (swipe left to remove, swipe right to favorite)
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.lines.length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: tokens.line, height: 1),
                              itemBuilder: (context, index) {
                                final item = state.lines[index];
                                return _buildCartRow(context, item, tokens);
                              },
                            ),
                            const SizedBox(height: 24),

                            // Scratch Coupon Card
                            ScratchCouponCard(
                              isScratched: state.scratched,
                              onScratched: () {
                                context
                                    .read<CartBloc>()
                                    .add(const CartCouponScratched());
                              },
                              onApply: () {
                                context
                                    .read<CartBloc>()
                                    .add(const CartCouponApplied('CANASTA10'));
                                AppToast.show(
                                  context,
                                  'Cupón CANASTA10 aplicado: 10 % de descuento.',
                                );
                              },
                            ),
                            const SizedBox(height: 18),

                            // Promo Code input banner
                            GestureDetector(
                              onTap: () => _showDiscountSheet(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: tokens.chip,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    AppSvgIcon('tag',
                                        size: 18, color: tokens.blue),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        state.coupon != null
                                            ? 'Cupón: ${state.coupon!.code} (-${state.coupon!.pct}%)'
                                            : 'Agregar código de descuento',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: state.coupon != null
                                              ? tokens.blue
                                              : tokens.ink,
                                        ),
                                      ),
                                    ),
                                    if (state.coupon != null)
                                      GestureDetector(
                                        onTap: () {
                                          context
                                              .read<CartBloc>()
                                              .add(const CartCouponRemoved());
                                          AppToast.show(
                                            context,
                                            'Quitaste el cupón.',
                                          );
                                        },
                                        child: Text(
                                          'Quitar',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.bad,
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(Icons.arrow_forward_ios_rounded,
                                          size: 14, color: tokens.ink3),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Order breakdown: Subtotal, Descuento, Delivery, Total
                            _buildBreakdownRow('Subtotal', state.subtotal, tokens),
                            const SizedBox(height: 8),
                            if (state.discount > 0) ...[
                              _buildBreakdownRow(
                                'Descuento',
                                -state.discount,
                                tokens,
                                isDiscount: true,
                              ),
                              const SizedBox(height: 8),
                            ],
                            _buildBreakdownRow(
                              'Delivery',
                              state.fee,
                              tokens,
                              isFree: state.fee == 0,
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: tokens.ink,
                                  ),
                                ),
                                Text(
                                  formatPen(state.total),
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

                      // Fixed Bottom Checkout Bar
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(color: tokens.line)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Delivery address label & change
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      AppSvgIcon('pin',
                                          size: 14, color: tokens.ink2),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Entregar en ${address.tag} · ${address.shortLine}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: tokens.ink2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/location'),
                                    child: Text(
                                      'Cambiar',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: tokens.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Checkout button: "Ir a pagar →"
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/checkout'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tokens.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Ir a pagar',
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            formatPen(state.total),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.arrow_forward_rounded,
                                              size: 18),
                                        ],
                                      ),
                                    ],
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
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, CaTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              CaAssets.bag,
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora nuestras categorías y agrega productos frescos de la mejor calidad.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: tokens.ink2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
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
                  elevation: 0,
                ),
                child: const Text(
                  'Empezar a comprar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartRow(BuildContext context, CartItem item, CaTokens tokens) {
    final p = item.product;
    final isSelected = _selectedItems.contains(p.id);

    return Dismissible(
      key: Key(p.id),
      direction: _isEditing ? DismissDirection.none : DismissDirection.horizontal,
      background: Container(
        color: tokens.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.favorite, color: Colors.white, size: 26),
      ),
      secondaryBackground: Container(
        color: tokens.bad,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right: toggle favorite
          CaHaptics.mediumImpact();
          context.read<FavoritesCubit>().toggle(p.id);
          AppToast.show(
            context,
            '${p.name} guardado en favoritos.',
          );
          return false; // return row back to position
        } else {
          // Swipe left: remove item with undo
          CaHaptics.mediumImpact();
          context.read<CartBloc>().add(CartItemRemoved(p.id));
          AppToast.show(
            context,
            'Quitaste ${p.name.toLowerCase()}.',
            actionLabel: 'Deshacer',
            onAction: () {
              context.read<CartBloc>().add(const CartUndoRemove());
            },
          );
          return true;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Selection checkbox (when editing)
            if (_isEditing) ...[
              Checkbox(
                value: isSelected,
                activeColor: tokens.blue,
                onChanged: (_) {
                  setState(() {
                    if (isSelected) {
                      _selectedItems.remove(p.id);
                    } else {
                      _selectedItems.add(p.id);
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
            ],

            // 76px Product Image
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: tokens.chip,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                CaAssets.product(p.id),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),

            // Name and unit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.isKg ? 'Por peso' : p.unit,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tokens.ink2,
                    ),
                  ),
                ],
              ),
            ),

            // Price top-right and Stepper bottom-right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPen(item.total),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 10),
                QtyStepper(
                  product: p,
                  quantity: item.quantity,
                  style: StepperStyle.cartSmall,
                  onChanged: (newQty) {
                    context
                        .read<CartBloc>()
                        .add(CartItemQtyChanged(p.id, newQty));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
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
        Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            color: tokens.ink2,
          ),
        ),
        Text(
          valueStr,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: (isDiscount || isFree) ? tokens.green : tokens.ink,
          ),
        ),
      ],
    );
  }
}
