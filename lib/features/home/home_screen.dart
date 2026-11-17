import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/address/address_cubit.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../../blocs/session/session_bloc.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/tokens.dart';
import '../../data/catalog_data.dart';
import '../../shared/address_picker_sheet.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';
import '../../shared/flip_counter.dart';
import '../../shared/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onAddProduct});

  final void Function(GlobalKey key, String productId)? onAddProduct;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController =
      PageController(viewportFraction: 408 / 418);
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  final List<String> _searchSuggestions = [
    'palta',
    'leche fresca',
    'pan integral',
    'huevos',
    'fresas',
    'detergente',
  ];

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Comida sana,\nvida sana',
      'subtitle': 'Hasta 30 % dscto',
      'colors': [Color(0xFF0B2A73), Color(0xFF123C9C), Color(0xFF1A4FE0)],
      'stops': [0.0, 0.6, 1.0],
      'isLightText': true,
      'btnBg': Colors.white,
      'btnTextColor': Color(0xFF0F1324),
      'image': CaAssets.banner1,
      'imgBottom': -14.0,
      'imgRight': 4.0,
      'imgHeight': 184.0,
      'route': '/deals',
    },
    {
      'title': 'Víveres frescos\nen tu puerta',
      'subtitle': '20 % en tu primer pedido',
      'colors': [Color(0xFF0E6B3E), Color(0xFF1E9E5A)],
      'stops': [0.0, 1.0],
      'isLightText': true,
      'btnBg': Colors.white,
      'btnTextColor': Color(0xFF0F1324),
      'image': CaAssets.banner2,
      'imgBottom': 12.0,
      'imgRight': -14.0,
      'imgWidth': 230.0,
      'route': '/cats',
    },
    {
      'title': 'Delivery gratis\ndesde S/ 80',
      'subtitle': 'En menos de 1 hora',
      'colors': [Color(0xFFDCE7FF), Color(0xFFBDD0FF)],
      'stops': [0.0, 1.0],
      'isLightText': false,
      'btnBg': Color(0xFF1A4FE0),
      'btnTextColor': Colors.white,
      'image': CaAssets.banner3,
      'imgBottom': 6.0,
      'imgRight': 8.0,
      'imgHeight': 160.0,
      'route': '/cats',
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

  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
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
              // Top Bar (.hhd pad): Deliver to + Address + Bell button
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Address Button (.dl)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => AddressPickerSheet.show(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppSvgIcon('pin', size: 22, color: tokens.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Entregar en',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w400,
                                      color: tokens.ink2,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${address.shortLine}, ${address.district}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                            color: tokens.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      AppSvgIcon('down', size: 16, color: tokens.ink),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Notification Bell Button (.ib.bell)
                    GestureDetector(
                      onTap: () {
                        CaHaptics.lightImpact();
                        AppToast.show(
                          context,
                          'Tu pedido CA-87654 está en camino.',
                          actionLabel: 'Ver',
                          onAction: () => context.push('/tracking'),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: tokens.border, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon('bell', size: 21, color: tokens.ink),
                          ),
                          Positioned(
                            top: 11,
                            right: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tokens.bad,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Greeting & Cart Header (.hg pad)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${user.firstName} 👋',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w400,
                              color: tokens.ink2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¿Qué quieres pedir\nhoy?',
                            style: TextStyle(
                              fontSize: 24,
                              height: 1.22,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Cart Button (.cartb)
                    GestureDetector(
                      onTap: () => context.push('/cart'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: tokens.border, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon('cart', size: 22, color: tokens.ink),
                          ),
                          if (cartUnits > 0)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  color: tokens.blue,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$cartUnits',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.0,
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

              // Search Bar (.srch pad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tokens.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        AppSvgIcon('search', size: 20, color: tokens.ink2),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RotatingHint(words: _searchSuggestions),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: AppSvgIcon('filter', size: 19, color: tokens.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Banners Carousel (.bnw, .bns, .bn, .bdots)
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: SizedBox(
                height: 172,
                child: PageView.builder(
                  padEnds: false,
                  controller: _bannerController,
                  itemCount: _banners.length,
                  onPageChanged: (i) => setState(() => _bannerIndex = i),
                  itemBuilder: (context, index) {
                    final b = _banners[index];
                    final isLight = b['isLightText'] as bool;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        height: 172,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: b['colors'] as List<Color>,
                            stops: b['stops'] as List<double>?,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(CaTokens.bannerRadius),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          children: [
                            // Right Illustration
                            Positioned(
                              right: b['imgRight'] as double? ?? 0,
                              bottom: b['imgBottom'] as double? ?? 0,
                              child: Image.asset(
                                b['image'] as String,
                                width: b['imgWidth'] as double?,
                                height: b['imgHeight'] as double?,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ),

                            // Text Content (.bn .bt)
                            Positioned(
                              left: 20,
                              top: 18,
                              right: 130,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    b['title'] as String,
                                    style: TextStyle(
                                      fontSize: 20,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                      color: isLight ? Colors.white : tokens.navy,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b['subtitle'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: isLight
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : tokens.navy.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Button (.bb)
                                  GestureDetector(
                                    onTap: () {
                                      final route = b['route'] as String;
                                      context.push(route);
                                    },
                                    child: IntrinsicWidth(
                                      child: Container(
                                      height: 34,
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      decoration: BoxDecoration(
                                        color: b['btnBg'] as Color,
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Comprar',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: b['btnTextColor'] as Color,
                                        ),
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
                    );
                  },
                ),
              ),
              ),

              // Animated Carousel Dots (.bdots)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _banners.length,
                    (k) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: _bannerIndex == k ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _bannerIndex == k
                            ? tokens.blue
                            : const Color(0xFFD5DCEB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4 Trust Badges (.trust pad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTrustBadge('truck', 'Entrega rápida',
                          const Color(0xFFE8EEFF), const Color(0xFF1A4FE0)),
                    ),
                    Expanded(
                      child: _buildTrustBadge('shield', 'Mejor calidad',
                          const Color(0xFFE3F6EC), const Color(0xFF1E9E5A)),
                    ),
                    Expanded(
                      child: _buildTrustBadge('swap', 'Cambios fáciles',
                          const Color(0xFFFFF1DF), const Color(0xFFF08C00)),
                    ),
                    Expanded(
                      child: _buildTrustBadge('lock', 'Pago seguro',
                          const Color(0xFFEEEAFE), const Color(0xFF5B4BDB)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categorías Header (.sec pad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Categorías',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                          letterSpacing: -0.27,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/cats'),
                      child: Text(
                        'Ver todo',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Categories Row (.hcats: 56x56 images, no circle behind them!)
              SizedBox(
                height: 60 + 6 + 22,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: CatalogData.categories.take(7).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final c = CatalogData.categories[index];
                    final previewId = c.homeArtId ?? 'apple';
                    final shortName = c.name.split(' ').first;

                    return GestureDetector(
                      onTap: () {
                        if (c.id == 'off') {
                          context.push('/deals');
                        } else {
                          context.read<CatalogCubit>().selectCategory(c.id);
                          context.push('/list');
                        }
                      },
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: Image.asset(
                                CaAssets.product(previewId),
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              shortName,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: tokens.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Productos Populares Section (.sec pad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Productos populares',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                          letterSpacing: -0.27,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<CatalogCubit>().selectCategory('fru');
                        context.push('/list');
                      },
                      child: Text(
                        'Ver todo',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Productos Populares Row (.hrow: 158px width each)
              SizedBox(
                height: 236,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: CatalogData.popularIds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final id = CatalogData.popularIds[index];
                    final p = CatalogData.getProductById(id)!;

                    return SizedBox(
                      width: 158,
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

              // Ofertas del Día Section (.sec pad deal)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ofertas del día',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                          letterSpacing: -0.27,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const FlipCounter(),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/deals'),
                      child: Text(
                        'Ver todo',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Ofertas Row (.hrow: 158px width each)
              SizedBox(
                height: 236,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: CatalogData.dealsIds.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final id = CatalogData.dealsIds[index];
                    final p = CatalogData.getProductById(id)!;

                    return SizedBox(
                      width: 158,
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
              const SizedBox(height: 22),

              // Bottom Delivery Banner (.fdel pad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GestureDetector(
                  onTap: () => context.push('/deals'),
                  child: Container(
                    height: 84,
                    padding: const EdgeInsets.fromLTRB(18, 0, 16, 0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF0FF), Color(0xFFDCE6FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Delivery gratis',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'En pedidos desde S/ 80',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF4A5683),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          CaAssets.scooter,
                          width: 100,
                          height: 76,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        AppSvgIcon('arrow', size: 20, color: tokens.blue),
                      ],
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

  Widget _buildTrustBadge(
      String iconName, String label, Color bgColor, Color iconColor) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: AppSvgIcon(iconName, size: 20, color: iconColor),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F1324),
          ),
        ),
      ],
    );
  }
}


/// «Busca [palabra]…»: la palabra sale hacia arriba (260 ms) y la nueva entra
/// desde abajo (300 ms), una después de la otra, como en el HTML.
class _RotatingHint extends StatefulWidget {
  const _RotatingHint({required this.words});

  final List<String> words;

  @override
  State<_RotatingHint> createState() => _RotatingHintState();
}

class _RotatingHintState extends State<_RotatingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _c.value = 1;
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) async {
      if (!mounted) return;
      await _c.animateTo(0, duration: Duration.zero);
      if (!mounted) return;
      _c.forward(from: 0);
    });
    _c.addListener(() {
      if (_c.value >= 0.4643 && _swapped == false && _c.value < 1) {
        _swapped = true;
        setState(() => _i = (_i + 1) % widget.words.length);
      }
      if (_c.value == 0) _swapped = false;
    });
  }

  bool _swapped = false;

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final base = TextStyle(fontSize: 15, color: tokens.ink3);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // 0..0.4643 sale (260 ms), 0.4643..1 entra (300 ms)
        final v = _c.value;
        double dy, op;
        if (v < 0.4643) {
          final t = v / 0.4643;
          dy = -12 * t;
          op = 1 - t;
        } else {
          final t = (v - 0.4643) / 0.5357;
          dy = 12 * (1 - t);
          op = t;
        }
        return Row(
          children: [
            Text('Busca ', style: base),
            Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(
                opacity: op.clamp(0.0, 1.0),
                child: Text(
                  widget.words[_i],
                  style: base.copyWith(color: tokens.ink2),
                ),
              ),
            ),
            Text('…', style: base),
          ],
        );
      },
    );
  }
}
