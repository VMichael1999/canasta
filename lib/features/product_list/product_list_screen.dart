import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../categories/categories_screen.dart' show buildCategoryArt;
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/tokens.dart';
import '../../domain/models/category.dart';
import '../../shared/ca_tab_bar.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/product_card.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key, this.onAddProduct});

  final void Function(GlobalKey key, String productId)? onAddProduct;

  void _showSortSheet(BuildContext context) {
    CaHaptics.lightImpact();
    final tokens = context.tokens;
    final cubit = context.read<CatalogCubit>();
    final currentSort = cubit.state.sortOption;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
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
                const SizedBox(height: 14),
                Text(
                  'Ordenar por',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: SortOption.values.length,
                  separatorBuilder:
                      (_, __) => Divider(color: tokens.line, height: 1),
                  itemBuilder: (context, index) {
                    final opt = SortOption.values[index];
                    final isSel = opt == currentSort;

                    return InkWell(
                      onTap: () {
                        CaHaptics.selectionClick();
                        cubit.setSortOption(opt);
                        Navigator.of(ctx).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? tokens.blue : tokens.ink,
                              ),
                            ),
                            if (isSel)
                              AppSvgIcon('check', size: 18, color: tokens.blue),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        final cat = state.selectedCategory;
        final products = state.categoryProducts;

        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: const CaTabBar(activeIndex: 1),
          body: CustomScrollView(
            slivers: [
              // Header (.lhead: height 270, bg #F4F6FB, catArt on right, title on left)
              SliverToBoxAdapter(
                child: Container(
                  height: 270,
                  color: const Color(0xFFF4F6FB),
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        // Back and search action buttons
                        Positioned(
                          top: 8,
                          left: 22,
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: tokens.border),
                              ),
                              alignment: Alignment.center,
                              child: AppSvgIcon(
                                'arrowl',
                                size: 21,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 22,
                          child: GestureDetector(
                            onTap: () => context.push('/search'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: tokens.border),
                              ),
                              alignment: Alignment.center,
                              child: AppSvgIcon(
                                'search',
                                size: 21,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                        ),

                        // Overlapping artwork (.lhim: 200x150 at top right)
                        Positioned(
                          right: 16,
                          top: 36,
                          width: 200,
                          height: 150,
                          child:
                              cat.id == 'off'
                                  ? _buildHeaderArt(cat)
                                  : buildCategoryArt(cat, tokens),
                        ),

                        // Title and subtitle at bottom left (.lht)
                        Positioned(
                          left: 22,
                          bottom: 18,
                          right: 22,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.ink,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cat.subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: tokens.ink2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Subcategories Chips & Sort Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subcategories Chips (.chips: 38 height, 19 radius)
                      if (cat.subs.isNotEmpty)
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            scrollDirection: Axis.horizontal,
                            itemCount: cat.subs.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final sub = cat.subs[index];
                              final isSel = state.selectedSub == sub;

                              return GestureDetector(
                                onTap: () {
                                  CaHaptics.selectionClick();
                                  context
                                      .read<CatalogCubit>()
                                      .selectSubcategory(sub);
                                },
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSel ? tokens.blue : Colors.white,
                                    borderRadius: BorderRadius.circular(19),
                                    border:
                                        isSel
                                            ? null
                                            : Border.all(
                                              color: tokens.border,
                                              width: 1,
                                            ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    sub,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : tokens.ink,
                                      fontWeight:
                                          isSel
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Count & Order by (.lbar pad)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${products.length} productos',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: tokens.ink2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showSortSheet(context),
                              child: Row(
                                children: [
                                  AppSvgIcon(
                                    'sort',
                                    size: 18,
                                    color: tokens.ink,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    state.sortOption.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Product Grid (.pgrid pad)
              if (state.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 222,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Container(
                        decoration: BoxDecoration(
                          color: tokens.chip,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      childCount: 4,
                    ),
                  ),
                )
              else if (products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.blueSoft,
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon(
                              'search',
                              size: 36,
                              color: tokens.blue,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Sin productos aquí',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Prueba con otra subcategoría.',
                            style: TextStyle(fontSize: 14, color: tokens.ink2),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 222,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final p = products[index];
                      return ProductCard(
                        product: p,
                        onTap: () => context.push('/product/${p.id}'),
                        onAddWithGlobalKey: (key, prod) {
                          onAddProduct?.call(key, prod.id);
                        },
                      );
                    }, childCount: products.length),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderArt(Category cat) {
    if (cat.id == 'off') {
      return Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2F6BFF), Color(0xFF1A4FE0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const AppSvgIcon('percent', size: 50, color: Colors.white),
        ),
      );
    }

    final arts = cat.previewProductIds;
    if (arts.length >= 4) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            top: 24,
            width: 75,
            height: 75,
            child: Image.asset(CaAssets.product(arts[0]), fit: BoxFit.contain),
          ),
          Positioned(
            left: 55,
            top: 6,
            width: 72,
            height: 72,
            child: Image.asset(CaAssets.product(arts[1]), fit: BoxFit.contain),
          ),
          Positioned(
            right: 8,
            top: 26,
            width: 70,
            height: 70,
            child: Image.asset(CaAssets.product(arts[2]), fit: BoxFit.contain),
          ),
          Positioned(
            left: 45,
            top: 55,
            width: 86,
            height: 86,
            child: Image.asset(CaAssets.product(arts[3]), fit: BoxFit.contain),
          ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 14,
          top: 14,
          width: 95,
          height: 95,
          child: Image.asset(CaAssets.product(arts[0]), fit: BoxFit.contain),
        ),
        if (arts.length > 1)
          Positioned(
            right: 14,
            top: 24,
            width: 90,
            height: 90,
            child: Image.asset(CaAssets.product(arts[1]), fit: BoxFit.contain),
          ),
      ],
    );
  }
}
