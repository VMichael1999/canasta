import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/address/address_cubit.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../../blocs/session/session_bloc.dart';
import '../../core/assets.dart';
import '../../core/tokens.dart';
import '../../data/catalog_data.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/flip_counter.dart';
import '../../shared/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onAddProduct});

  final void Function(GlobalKey key, String productId)? onAddProduct;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  final List<String> _searchPlaceholders = [
    'Busca palta, leche, pan…',
    'Busca plátano de seda…',
    'Busca huevos de granja…',
    'Busca manzana roja…',
  ];
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Comida sana, vida sana',
      'subtitle': 'Hasta 30 % dscto en frutas de estación',
      'bg': const Color(0xFF0B2A73),
      'image': CaAssets.banner1,
    },
    {
      'title': 'Víveres frescos en tu puerta',
      'subtitle': 'Directo del productor a tu casa en minutos',
      'bg': const Color(0xFF1E9E5A),
      'image': CaAssets.banner2,
    },
    {
      'title': 'Delivery gratis desde S/ 80',
      'subtitle': 'En menos de 1 hora garantizado',
      'bg': const Color(0xFF1A4FE0),
      'image': CaAssets.banner3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (_bannerController.hasClients) {
        final next = (_bannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    _placeholderTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (mounted) {
        setState(() {
          _placeholderIndex =
              (_placeholderIndex + 1) % _searchPlaceholders.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _placeholderTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final address = context.watch<AddressCubit>().state.selectedAddress;
    final user = context.watch<SessionBloc>().state.user;
    final cartUnits = context.watch<CartBloc>().state.units;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: "Entregar en" + Address + Bell with dot
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/location'),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Entregar en',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.ink2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down,
                                  size: 16, color: tokens.blue),
                            ],
                          ),
                          Text(
                            '${address.tag} · ${address.shortLine}',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.chip,
                          ),
                          alignment: Alignment.center,
                          child: AppSvgIcon('bell', size: 20, color: tokens.ink),
                        ),
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.bad,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Greeting & Header with cart icon badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user.firstName} 👋',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¿Qué quieres pedir hoy?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: tokens.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/cart'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.blueSoft,
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon('cart',
                                size: 22, color: tokens.blue),
                          ),
                          if (cartUnits > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tokens.blue,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  '$cartUnits',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: tokens.chip,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        AppSvgIcon('search', size: 19, color: tokens.ink2),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _searchPlaceholders[_placeholderIndex],
                              key: ValueKey(_placeholderIndex),
                              style: TextStyle(
                                fontSize: 14,
                                color: tokens.ink3,
                              ),
                            ),
                          ),
                        ),
                        AppSvgIcon('filter', size: 18, color: tokens.ink2),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Banner Carousel (auto-scrolling)
              SizedBox(
                height: 140,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: _banners.length,
                  onPageChanged: (i) => setState(() => _bannerIndex = i),
                  itemBuilder: (context, index) {
                    final b = _banners[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Container(
                        decoration: BoxDecoration(
                          color: b['bg'],
                          borderRadius: BorderRadius.circular(CaTokens.bannerRadius),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    b['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    b['subtitle'],
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              b['image'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // 4 Trust badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTrustBadge('Entrega rápida', const Color(0xFFE8EEFF),
                        const Color(0xFF1A4FE0), Icons.flash_on_rounded),
                    _buildTrustBadge('Mejor calidad', const Color(0xFFE3F6EC),
                        const Color(0xFF1E9E5A), Icons.verified_rounded),
                    _buildTrustBadge('Cambios fáciles', const Color(0xFFFFF1DF),
                        const Color(0xFFF08C00), Icons.swap_horiz_rounded),
                    _buildTrustBadge('Pago seguro', const Color(0xFFEEEAFE),
                        const Color(0xFF5B4BDB), Icons.security_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categories Header & Horizontal Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/cats'),
                      child: Text(
                        'Ver todas',
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
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: CatalogData.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final cat = CatalogData.categories[index];
                    final previewId = cat.previewProductIds.first;

                    return GestureDetector(
                      onTap: () {
                        if (cat.id == 'off') {
                          context.push('/deals');
                        } else {
                          context.read<CatalogCubit>().selectCategory(cat.id);
                          context.push('/list');
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.chip,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              CaAssets.product(previewId),
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Productos Populares Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Productos populares',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/cats'),
                      child: Text(
                        'Ver más',
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
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: CatalogData.popularIds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final id = CatalogData.popularIds[index];
                    final p = CatalogData.getProductById(id)!;

                    return SizedBox(
                      width: 160,
                      child: ProductCard(
                        product: p,
                        onTap: () => context.push('/product/${p.id}'),
                        onAddWithGlobalKey: (key, prod) {
                          widget.onAddProduct?.call(key, prod.id);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Deals Section with Flip Counter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ofertas del día',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vencen hoy a las 23:59:59',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: tokens.ink2,
                          ),
                        ),
                      ],
                    ),
                    const FlipCounter(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: CatalogData.dealsIds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final id = CatalogData.dealsIds[index];
                    final p = CatalogData.getProductById(id)!;

                    return SizedBox(
                      width: 160,
                      child: ProductCard(
                        product: p,
                        onTap: () => context.push('/product/${p.id}'),
                        onAddWithGlobalKey: (key, prod) {
                          widget.onAddProduct?.call(key, prod.id);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Banner Delivery gratis desde S/ 80 con moto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.chip,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        CaAssets.scooter,
                        width: 60,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery gratis en tu compra',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'En todos los pedidos desde S/ 80.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: tokens.blue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(
      String label, Color bgColor, Color iconColor, IconData icon) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1324),
          ),
        ),
      ],
    );
  }
}
