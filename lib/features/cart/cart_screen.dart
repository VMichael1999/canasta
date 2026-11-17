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
import '../../core/weight.dart';
import '../../domain/models/cart_item.dart';
import '../../shared/ca_tab_bar.dart';
import '../../shared/address_picker_sheet.dart';
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
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DCE5),
                      borderRadius: BorderRadius.circular(3),
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
                    letterSpacing: -0.3,
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                      borderSide: BorderSide(color: tokens.blue, width: 1.5),
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
                    child: const Text(
                      'Aplicar código',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
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
        final unitsCount = state.units;
        final unitsLabel =
            '$unitsCount ${unitsCount == 1 ? 'producto' : 'productos'}';

        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: const CaTabBar(activeIndex: 0),
          body: Padding(
            padding: EdgeInsets.only(
              top: (MediaQuery.of(context).padding.top - 6).clamp(0.0, 80.0),
            ),
            child: Column(
              children: [
                // Top bar (.top3): padding 56 22 10, flecha sin caja, título + conteo
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
                                child: AppSvgIcon('back',
                                    size: 24, color: tokens.ink),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi carrito',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                                letterSpacing: -0.18,
                              ),
                            ),
                            if (!isEmpty)
                              Text(
                                unitsLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: tokens.ink2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isEmpty)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isEditing = !_isEditing;
                              _selectedItems.clear();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              _isEditing ? 'Listo' : 'Editar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: tokens.blue,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Main body
                Expanded(
                  child: isEmpty
                      ? _buildEmptyState(context, tokens)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Free Delivery Progress Banner (.frb)
                              FreeDeliveryProgress(
                                missingAmount: state.missingForFree,
                                progress: state.freeDeliveryProgress,
                                hasFreeDelivery: state.hasFreeDelivery,
                              ),
                              const SizedBox(height: 12),

                              // Items list (.clist)
                              ListView.separated(
                                padding: EdgeInsets.zero,
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
                              Divider(color: tokens.line, height: 1),

                              // Edit Mode Bulk Delete Button
                              if (_isEditing) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _selectedItems.isEmpty
                                        ? null
                                        : () {
                                            final toRemove =
                                                _selectedItems.toList();
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
                                                context.read<CartBloc>().add(
                                                    const CartUndoRemove());
                                              },
                                            );
                                          },
                                    icon: AppSvgIcon('trash',
                                        size: 18,
                                        color: _selectedItems.isEmpty
                                            ? tokens.ink3
                                            : tokens.bad),
                                    label: Text(
                                      _selectedItems.isEmpty
                                          ? 'Quitar seleccionados'
                                          : 'Quitar ${_selectedItems.length} seleccionado${_selectedItems.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                        color: _selectedItems.isEmpty
                                            ? tokens.ink3
                                            : tokens.bad,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: _selectedItems.isEmpty
                                            ? tokens.border
                                            : tokens.bad,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),

                              // Scratch Coupon Card (.cp)
                              ScratchCouponCard(
                                isScratched: state.scratched,
                                isApplied: state.coupon?.code == 'CANASTA10',
                                onScratched: () {
                                  context
                                      .read<CartBloc>()
                                      .add(const CartCouponScratched());
                                },
                                onApply: () {
                                  context.read<CartBloc>().add(
                                      const CartCouponApplied('CANASTA10'));
                                  AppToast.show(
                                    context,
                                    'Cupón CANASTA10 aplicado: 10 % de descuento.',
                                  );
                                },
                              ),
                              const SizedBox(height: 14),

                              // Promo Code button (.row.promo)
                              GestureDetector(
                                onTap: () => _showDiscountSheet(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: tokens.line),
                                  ),
                                  child: Row(
                                    children: [
                                      AppSvgIcon('tag',
                                          size: 22, color: tokens.blue),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          state.coupon != null
                                              ? '${state.coupon!.code} aplicado · ${state.coupon!.pct} % dscto'
                                              : 'Agregar código de descuento',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w500,
                                            color: tokens.blue,
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
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: tokens.bad,
                                            ),
                                          ),
                                        )
                                      else
                                        AppSvgIcon('chev',
                                            size: 18, color: tokens.blue),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Summary breakdown (.sum)
                              _buildBreakdownRow(
                                  'Subtotal', state.subtotal, tokens),
                              const SizedBox(height: 10),
                              if (state.discount > 0) ...[
                                _buildBreakdownRow(
                                  'Descuento (${state.coupon?.code ?? ''})',
                                  -state.discount,
                                  tokens,
                                  isDiscount: true,
                                ),
                                const SizedBox(height: 10),
                              ],
                              _buildBreakdownRow(
                                'Delivery',
                                state.fee,
                                tokens,
                                isFree: state.fee == 0,
                              ),
                              const SizedBox(height: 12),
                              Divider(color: tokens.line, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    formatPen(state.total),
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: tokens.ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Delivery address card (.card.addrc)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: tokens.line),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      alignment: Alignment.centerLeft,
                                      child: AppSvgIcon('pin',
                                          size: 22, color: tokens.blue),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Entregar en',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: tokens.ink2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  '${address.shortLine}, ${address.district}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: tokens.ink,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              AppSvgIcon('down',
                                                  size: 14, color: tokens.ink),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          GestureDetector(
                                            onTap: () =>
                                                AddressPickerSheet.show(
                                                    context),
                                            child: Text(
                                              'Cambiar dirección',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: tokens.blue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppSvgIcon('chev',
                                        size: 18, color: tokens.ink3),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Checkout button (.btn.big)
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Ir a pagar',
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      AppSvgIcon('arrow',
                                          size: 20, color: Colors.white),
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.blueSoft,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                CaAssets.bag,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega frutas, verduras o lo que necesites para la semana.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: tokens.ink2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
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
      direction:
          _isEditing ? DismissDirection.none : DismissDirection.horizontal,
      background: Container(
        color: tokens.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const AppSvgIcon('heart', size: 24, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: tokens.bad,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const AppSvgIcon('trash', size: 24, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          CaHaptics.mediumImpact();
          context.read<FavoritesCubit>().toggle(p.id);
          AppToast.show(
            context,
            '${p.name} guardado en favoritos.',
          );
          return false;
        } else {
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox when editing (.ck)
            if (_isEditing) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedItems.remove(p.id);
                    } else {
                      _selectedItems.add(p.id);
                    }
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 26, right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? tokens.blue : Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: isSelected
                        ? null
                        : Border.all(color: tokens.border, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ],

            // 76px Product Image (.th)
            GestureDetector(
              onTap: () => context.push('/product/${p.id}'),
              child: Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  CaAssets.product(p.id),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name & unit (.tx)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.isKg ? formatWeight(item.quantity) : p.unit,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Price (.pp) and Stepper (.act)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      if (p.hasDiscount) ...[
                        Text(
                          formatPen(p.oldPrice * item.quantity),
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.ink3,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        formatPen(item.total),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
    if (isDiscount) valueStr = '− $valueStr';
    if (isFree) valueStr = 'Gratis';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: tokens.ink2,
          ),
        ),
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
