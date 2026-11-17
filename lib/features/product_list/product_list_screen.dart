import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../../core/assets.dart';
import '../../core/tokens.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/product_card.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key, this.onAddProduct});

  final void Function(GlobalKey key, String productId)? onAddProduct;

  void _showSortSheet(BuildContext context) {
    final tokens = context.tokens;
    final cubit = context.read<CatalogCubit>();
    final currentSort = cubit.state.sortOption;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              'Ordenar por',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...SortOption.values.map((opt) {
              final isSel = opt == currentSort;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? tokens.blue : tokens.ink,
                  ),
                ),
                trailing: isSel
                    ? Icon(Icons.check, color: tokens.blue, size: 20)
                    : null,
                onTap: () {
                  cubit.setSortOption(opt);
                  Navigator.of(ctx).pop();
                },
              );
            }),
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
          body: CustomScrollView(
            slivers: [
              // Header SliverAppBar with Category Composition
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: AppSvgIcon('search', size: 20, color: tokens.ink),
                    onPressed: () => context.push('/search'),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  background: Container(
                    color: tokens.chip,
                    padding: const EdgeInsets.only(top: 40),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 140,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (int i = 0;
                              i < cat.previewProductIds.length && i < 3;
                              i++)
                            Positioned(
                              left: i * 36.0,
                              top: i * 10.0,
                              child: Image.asset(
                                CaAssets.product(cat.previewProductIds[i]),
                                width: 70,
                                height: 70,
                                fit: BoxFit.contain,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Subcategories Chips & Sort Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subcategories Chips
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          scrollDirection: Axis.horizontal,
                          itemCount: cat.subs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final sub = cat.subs[index];
                            final isSel = state.selectedSub == sub;

                            return ChoiceChip(
                              label: Text(sub),
                              selected: isSel,
                              onSelected: (_) {
                                context
                                    .read<CatalogCubit>()
                                    .selectSubcategory(sub);
                              },
                              selectedColor: tokens.blue,
                              backgroundColor: tokens.chip,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : tokens.ink,
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(19),
                              ),
                              showCheckmark: false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Count & Order by
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${products.length} productos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink2,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showSortSheet(context),
                              child: Row(
                                children: [
                                  Text(
                                    state.sortOption.label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.tune_rounded,
                                      size: 16, color: tokens.blue),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // Product Grid with Skeleton loading
              if (state.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 220,
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
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 230,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = products[index];
                        return ProductCard(
                          product: p,
                          onTap: () => context.push('/product/${p.id}'),
                          onAddWithGlobalKey: (key, prod) {
                            onAddProduct?.call(key, prod.id);
                          },
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
