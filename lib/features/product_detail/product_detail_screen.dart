import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/address/address_cubit.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/favorites/favorites_cubit.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../data/catalog_data.dart';
import '../../shared/ca_tab_bar.dart';
import '../../shared/address_picker_sheet.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';
import '../../shared/product_card.dart';
import '../../shared/qty_stepper.dart';
import '../../shared/weight_slider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.onAddProduct,
  });

  final String productId;
  final void Function(GlobalKey key, String productId)? onAddProduct;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _imgController = PageController();
  final GlobalKey _mainImageKey = GlobalKey();
  int _currentImg = 0;
  double _selectedQty = 1.0;

  @override
  void initState() {
    super.initState();
    final p = CatalogData.getProductById(widget.productId);
    final inCartQty = context.read<CartBloc>().state.quantityOf(widget.productId);
    _selectedQty = inCartQty > 0 ? inCartQty : (p?.step ?? 1.0);
  }

  /// Primera franja de entrega de hoy (firstSlotH del HTML).
  String _firstSlot() {
    final now = DateTime.now();
    final h = (((now.hour * 60 + now.minute) + 60) / 60).ceil().clamp(8, 20);
    final end = h + 1;
    return '${h % 12 == 0 ? 12 : h % 12}:00 – ${end % 12 == 0 ? 12 : end % 12}:00 ${end >= 12 ? 'p. m.' : 'a. m.'}';
  }

  List<List<String>> _getBenefits(String cat) {
    if (cat == 'fru') {
      return [
        ['leaf', '100 % natural', 'Sin químicos ni aditivos'],
        ['shield', 'Rico en nutrientes', 'Vitaminas y fibra'],
        ['sprout', 'Del productor', 'Elegido a mano para ti'],
      ];
    } else if (cat == 'ver') {
      return [
        ['leaf', '100 % natural', 'Sin químicos ni aditivos'],
        ['shield', 'Lavado y seleccionado', 'Listo para cocinar'],
        ['sprout', 'Del productor', 'Cosecha de la semana'],
      ];
    } else {
      return [
        ['checkc', 'Calidad garantizada', 'O te devolvemos tu dinero'],
        ['shield', 'Bien empacado', 'Llega en perfecto estado'],
        ['truck', 'Entrega rápida', 'En menos de 1 hora'],
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final p = CatalogData.getProductById(widget.productId);

    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    final isFav = context.watch<FavoritesCubit>().isFavorite(p.id);
    final address = context.watch<AddressCubit>().state.selectedAddress;
    final inCartQty = context.watch<CartBloc>().state.quantityOf(p.id);
    final isInCart = inCartQty > 0;

    final totalPrice = p.price * _selectedQty;
    final benefits = _getBenefits(p.cat);
    final similar = CatalogData.products
        .where((x) => x.cat == p.cat && x.id != p.id)
        .take(5)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CaTabBar(activeIndex: 0),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Image Carousel Header (.pdimg: height 400, 3 slides, 4 puntos)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 400 + (MediaQuery.of(context).padding.top - 62).clamp(0.0, 40.0),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _imgController,
                        itemCount: 3,
                        onPageChanged: (i) => setState(() => _currentImg = i),
                        itemBuilder: (context, index) {
                          Widget img = Image.asset(
                            CaAssets.product(p.id),
                            fit: BoxFit.contain,
                          );
                          if (index == 1) {
                            img = Transform.rotate(
                              angle: -0.2094, // -12 deg
                              child: Transform.scale(scale: 0.9, child: img),
                            );
                          } else if (index == 2) {
                            img = Transform.scale(scale: 1.15, child: img);
                          }
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(70, 110, 70, 30),
                            child: Center(
                              child: KeyedSubtree(
                                key: index == 0 ? _mainImageKey : null,
                                child: img,
                              ),
                            ),
                          );
                        },
                      ),

                      // .pdots: 4 puntos de 6 px; el activo en azul
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentImg == i
                                    ? tokens.blue
                                    : const Color(0xFFD5DCEB),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // .rtop: volver, corazón y compartir
                      Positioned(
                        left: 22,
                        right: 22,
                        top: (MediaQuery.of(context).padding.top - 6)
                            .clamp(0.0, 80.0),
                        child: Row(
                          children: [
                            _RoundBtn(
                              label: 'Volver',
                              onTap: () => context.pop(),
                              child: AppSvgIcon('arrowl',
                                  size: 21, color: tokens.ink),
                            ),
                            const Spacer(),
                            _RoundBtn(
                              label: 'Favorito',
                              onTap: () {
                                CaHaptics.lightImpact();
                                context.read<FavoritesCubit>().toggle(p.id);
                                AppToast.show(
                                  context,
                                  !isFav
                                      ? 'Guardado en favoritos.'
                                      : 'Quitado de favoritos.',
                                );
                              },
                              child: AppSvgIcon(
                                'heart',
                                size: 21,
                                color: isFav ? tokens.bad : tokens.ink,
                                filled: isFav,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _RoundBtn(
                              label: 'Compartir',
                              onTap: () {
                                CaHaptics.lightImpact();
                                AppToast.show(context, 'Enlace copiado.');
                              },
                              child: AppSvgIcon('share',
                                  size: 21, color: tokens.ink),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Info Body (.pdi)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Fresh Tag (.pdn)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          if (p.fresh)
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 9),
                              decoration: BoxDecoration(
                                color: tokens.greenSoft,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Fresco',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Ratings (.pdr): Stars + 4.8 + (356 reseñas)
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (k) => Padding(
                                padding: EdgeInsets.only(left: k == 0 ? 0 : 1),
                                child: AppSvgIcon(
                                  k < p.rating.round() ? 'star' : 'staro',
                                  size: 15,
                                  color: tokens.sun,
                                  filled: k < p.rating.round(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.rating.toString(),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${p.reviewsCount} reseñas)',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Price & Stepper row (.pdp)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    formatPen(p.price),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: tokens.ink,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  Text(
                                    '/${p.isKg ? 'kg' : p.unit == 'und' ? 'und' : p.unit}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: tokens.ink2,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              if (p.hasDiscount)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        formatPen(p.oldPrice),
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough,
                                          color: tokens.ink3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        height: 22,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7),
                                        decoration: BoxDecoration(
                                          color: tokens.greenSoft,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${p.discountPct} % dscto',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          // Large Stepper for unit products (.stp.lg)
                          if (!p.isKg)
                            QtyStepper(
                              product: p,
                              quantity: _selectedQty,
                              style: StepperStyle.detailLarge,
                              onChanged: (newQty) {
                                setState(() => _selectedQty = newQty);
                              },
                            ),
                        ],
                      ),

                      // Weight Slider (.wsl for kg products)
                      if (p.isKg) ...[
                        const SizedBox(height: 18),
                        WeightSlider(
                          currentKg: _selectedQty,
                          onChanged: (val) {
                            setState(() => _selectedQty = val);
                          },
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Delivery Estimate Box (.pdd)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: tokens.blueSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              alignment: Alignment.center,
                              child: AppSvgIcon('truck',
                                  size: 20, color: tokens.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: 'Entrega ',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: tokens.ink2,
                                        fontFamily: 'Inter',
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'hoy, ${_firstSlot()}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: tokens.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${address.shortLine}, ${address.district}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            color: tokens.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      AppSvgIcon('down',
                                          size: 15, color: tokens.ink),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => AddressPickerSheet.show(context),
                              child: Text(
                                'Cambiar',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Detalles del producto (.pdh)
                      Text(
                        'Detalles del producto',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: benefits.map((b) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tokens.greenSoft,
                                    ),
                                    alignment: Alignment.center,
                                    child: AppSvgIcon(b[0],
                                        size: 20, color: tokens.green),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    b[1],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    b[2],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: tokens.ink2,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // También te puede gustar (.pdh + .hrow)
                      if (similar.isNotEmpty) ...[
                        Text(
                          'También te puede gustar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 236,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: similar.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = similar[index];
                              return SizedBox(
                                width: 158,
                                child: ProductCard(
                                  product: item,
                                  onTap: () =>
                                      context.push('/product/${item.id}'),
                                  onAddWithGlobalKey: (key, prod) {
                                    widget.onAddProduct?.call(key, prod.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed Bottom Bar (.pdbar: height 58 big button with cart icon, text, and total pen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
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
              child: SizedBox(
                height: 58,
                child: p.inStock
                    ? ElevatedButton(
                        onPressed: () {
                          CaHaptics.lightImpact();
                          if (_selectedQty > inCartQty) {
                            widget.onAddProduct?.call(_mainImageKey, p.id);
                          }
                          context.read<CartBloc>().add(
                                isInCart
                                    ? CartItemQtyChanged(p.id, _selectedQty)
                                    : CartItemAdded(p, quantity: _selectedQty),
                              );
                          AppToast.show(
                            context,
                            isInCart
                                ? 'Carrito actualizado.'
                                : '${p.name} en tu carrito.',
                            actionLabel: 'Ver carrito',
                            onAction: () => context.push('/cart'),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                        ),
                        child: Row(
                          children: [
                            const AppSvgIcon('cart',
                                size: 20, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isInCart
                                    ? 'Actualizar carrito'
                                    : 'Agregar al carrito',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              formatPen(totalPrice),
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () {
                          AppToast.show(
                            context,
                            'Te avisamos apenas vuelva.',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: tokens.border, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppSvgIcon('bell', size: 20, color: tokens.ink),
                            const SizedBox(width: 10),
                            Text(
                              'Avísame cuando vuelva',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Botón redondo de 44 px con anillo de 1 px (.ib).
class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.child,
    required this.onTap,
    required this.label,
  });

  final Widget child;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: tokens.border),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
