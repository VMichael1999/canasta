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
import '../../core/typography.dart';
import '../../data/catalog_data.dart';
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

  List<List<String>> _getBenefits(String cat) {
    if (cat == 'fru') {
      return [
        ['leaf', '100 % natural', 'Sin químicos ni aditivos'],
        ['shield', 'Rico en nutrientes', 'Vitaminas y fibra'],
        ['checkc', 'Del productor', 'Elegido a mano para ti'],
      ];
    } else if (cat == 'ver') {
      return [
        ['leaf', '100 % natural', 'Sin químicos ni aditivos'],
        ['shield', 'Lavado y seleccionado', 'Listo para cocinar'],
        ['checkc', 'Del productor', 'Cosecha de la semana'],
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top Bar with back, heart and share buttons
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.border),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.arrow_back, color: tokens.ink, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {
                      CaHaptics.lightImpact();
                      context.read<FavoritesCubit>().toggle(p.id);
                      AppToast.show(
                        context,
                        !isFav
                            ? '${p.name} guardado en favoritos.'
                            : 'Quitado de favoritos.',
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.border),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? tokens.bad : tokens.ink,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      AppToast.show(context, 'Enlace copiado al portapapeles.');
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.border),
                      ),
                      alignment: Alignment.center,
                      child: AppSvgIcon('share', size: 19, color: tokens.ink),
                    ),
                  ),
                  const SizedBox(width: 18),
                ],
              ),

              // Product Image Carousel with Dots
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      height: 260,
                      child: PageView.builder(
                        controller: _imgController,
                        itemCount: 3,
                        onPageChanged: (i) => setState(() => _currentImg = i),
                        itemBuilder: (context, index) {
                          return Center(
                            child: KeyedSubtree(
                              key: index == 0 ? _mainImageKey : null,
                              child: Image.asset(
                                CaAssets.product(p.id),
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Carousel dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImg == i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentImg == i ? tokens.blue : tokens.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Fresh Tag
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: tokens.ink,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          if (p.fresh)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: tokens.greenSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Fresco',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Ratings: ★ 4.8 (356 reseñas)
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 18, color: tokens.sun),
                          const SizedBox(width: 4),
                          Text(
                            p.rating.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${p.reviewsCount} reseñas)',
                            style: TextStyle(
                              fontSize: 13,
                              color: tokens.ink2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price & Stepper row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                formatPen(p.price),
                                style: CaTypography.price,
                              ),
                              Text(
                                '/${p.isKg ? 'kg' : p.unit}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: tokens.ink2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (p.hasDiscount) ...[
                                const SizedBox(width: 10),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tokens.greenSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${p.discountPct}% dscto',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.green,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                      const SizedBox(height: 20),

                      // Weight Slider (for kg products)
                      if (p.isKg) ...[
                        WeightSlider(
                          currentKg: _selectedQty,
                          onChanged: (val) {
                            setState(() => _selectedQty = val);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Delivery Estimate Box: Entrega hoy, 8:00 - 9:00 a. m. · dirección · Cambiar
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tokens.blueSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              alignment: Alignment.center,
                              child: AppSvgIcon('truck',
                                  size: 18, color: tokens.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Entrega hoy, 35 a 50 min',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${address.shortLine}, ${address.district}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tokens.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/location'),
                              child: Text(
                                'Cambiar',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Detalles del producto: 3 beneficios
                      Text(
                        'Detalles del producto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: benefits.map((b) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tokens.greenSoft,
                                    ),
                                    alignment: Alignment.center,
                                    child: AppSvgIcon(b[0],
                                        size: 20, color: tokens.green),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    b[1],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    b[2],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: tokens.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // También te puede gustar
                      if (similar.isNotEmpty) ...[
                        Text(
                          'También te puede gustar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 230,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: similar.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = similar[index];
                              return SizedBox(
                                width: 150,
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

          // Bottom Fixed Action Bar: "🛒 Agregar al carrito · S/ 3.80"
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: tokens.line)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: p.inStock
                      ? () {
                          CaHaptics.lightImpact();
                          widget.onAddProduct?.call(_mainImageKey, p.id);
                          context.read<CartBloc>().add(
                                CartItemAdded(p, quantity: _selectedQty),
                              );
                          AppToast.show(
                            context,
                            '${p.name} en tu carrito.',
                            actionLabel: 'Ver carrito',
                            onAction: () => context.push('/cart'),
                          );
                        }
                      : () {
                          AppToast.show(
                            context,
                            'Te avisamos cuando vuelva ${p.name.toLowerCase()}.',
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.inStock ? tokens.blue : tokens.chip,
                    foregroundColor: p.inStock ? Colors.white : tokens.ink2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          AppSvgIcon(
                            p.inStock ? 'cart' : 'bell',
                            size: 20,
                            color: p.inStock ? Colors.white : tokens.ink2,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            p.inStock
                                ? (isInCart
                                    ? 'Actualizar carrito'
                                    : 'Agregar al carrito')
                                : 'Avísame cuando vuelva',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: p.inStock ? Colors.white : tokens.ink,
                            ),
                          ),
                        ],
                      ),
                      if (p.inStock)
                        Text(
                          formatPen(totalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
