import 'package:flutter/material.dart';
import 'category_grow.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../../blocs/session/session_bloc.dart';
import '../../core/assets.dart';
import '../../core/tokens.dart';
import '../../data/catalog_data.dart';
import '../../domain/models/category.dart';
import '../../shared/app_svg_icon.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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
              // Header (.hg pad): Hola, Michael + Categorías + Cart button (.cartb)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user.firstName} 👋',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: tokens.ink2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Categorías',
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
                              border: Border.all(
                                color: tokens.border,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon(
                              'cart',
                              size: 22,
                              color: tokens.ink,
                            ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.blue,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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
                          child: Text(
                            'Busca productos…',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: tokens.ink3,
                            ),
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: AppSvgIcon(
                            'filter',
                            size: 19,
                            color: tokens.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Categories 2-Column Grid (.cgrid pad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: CatalogData.categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 184,
                  ),
                  itemBuilder: (context, index) {
                    final cat = CatalogData.categories[index];
                    return _CategoryCard(category: cat);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: () {
        if (category.id == 'off') {
          context.push('/deals');
        } else {
          context.read<CatalogCubit>().selectCategory(category.id);
          final box = context.findRenderObject() as RenderBox?;
          if (box == null || !box.attached) {
            context.push('/list');
            return;
          }
          // Zona de la imagen dentro de la tarjeta (padding 12/10, alto 118).
          final o = box.localToGlobal(Offset.zero);
          final from = Rect.fromLTWH(
            o.dx + 12,
            o.dy + 10,
            box.size.width - 24,
            118,
          );
          final media = MediaQuery.of(context);
          // El SafeArea de esta pantalla ya consumió el padding: leer el de la vista.
          final view = View.of(context);
          final safeTop = view.padding.top / view.devicePixelRatio;
          // Destino: donde el HTML (.lhim) y la lista dibujan la imagen.
          final to = Rect.fromLTWH(
            media.size.width - 16 - 200,
            safeTop + 36,
            200,
            150,
          );
          CategoryGrow.run(
            context,
            from: from,
            artTo: to,
            art: buildCategoryArt(category, tokens),
            onCovered: () => context.push('/list'),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CaTokens.catRadius),
          border: Border.all(color: tokens.line, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Artwork Area (.cim: height 118)
            SizedBox(
              height: 118,
              width: double.infinity,
              child: buildCategoryArt(category, tokens),
            ),
            const SizedBox(height: 4),

            // Bottom Name, Subtitle and Chevron
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      Text(
                        category.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.ink2,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: AppSvgIcon('chev', size: 20, color: tokens.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Arte de una categoría (tarjeta y cabecera de la lista comparten composición).
Widget buildCategoryArt(Category cat, CaTokens tokens) {
  // Special banner for discounts: .offart (gradient #2F6BFF to #1A4FE0, rotated -4deg, i-percent icon)
  if (cat.id == 'off') {
    return Center(
      child: Transform.rotate(
        angle: -0.07, // -4 deg
        child: Transform.scale(
          scale: 0.84,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2F6BFF), Color(0xFF1A4FE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon('percent', size: 56, color: Colors.white),
          ),
        ),
      ),
    );
  }

  final arts = cat.previewProductIds;
  if (arts.length >= 4) {
    // .cart2.n4: c0: left 2%, top 18%, w 46%, h 60%
    //            c1: left 30%, top 4%, w 44%, h 56%
    //            c2: right 0, top 20%, w 42%, h 58%
    //            c3: left 20%, top 40%, w 58%, h 60% (zIndex 2)
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: w * 0.02,
              top: h * 0.18,
              width: w * 0.46,
              height: h * 0.60,
              child: Image.asset(
                CaAssets.product(arts[0]),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: w * 0.30,
              top: h * 0.04,
              width: w * 0.44,
              height: h * 0.56,
              child: Image.asset(
                CaAssets.product(arts[1]),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 0,
              top: h * 0.20,
              width: w * 0.42,
              height: h * 0.58,
              child: Image.asset(
                CaAssets.product(arts[2]),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: w * 0.20,
              top: h * 0.40,
              width: w * 0.58,
              height: h * 0.60,
              child: Image.asset(
                CaAssets.product(arts[3]),
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }

  // .cart2.n2: c0: left 6%, top 6%, w 56%, h 84%
  //            c1: right 4%, top 14%, w 52%, h 84%
  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: w * 0.06,
            top: h * 0.06,
            width: w * 0.56,
            height: h * 0.84,
            child: Image.asset(CaAssets.product(arts[0]), fit: BoxFit.contain),
          ),
          if (arts.length > 1)
            Positioned(
              right: w * 0.04,
              top: h * 0.14,
              width: w * 0.52,
              height: h * 0.84,
              child: Image.asset(
                CaAssets.product(arts[1]),
                fit: BoxFit.contain,
              ),
            ),
        ],
      );
    },
  );
}
