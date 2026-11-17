import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/catalog/catalog_cubit.dart';
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
    final cartUnits = context.watch<CartBloc>().state.units;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Categorías',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () => context.push('/cart'),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.blueSoft,
                    ),
                    alignment: Alignment.center,
                    child: AppSvgIcon('cart', size: 20, color: tokens.blue),
                  ),
                  if (cartUnits > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.blue,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '$cartUnits',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
          child: Column(
            children: [
              // Search input
              GestureDetector(
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
                      Text(
                        'Busca en todas las categorías…',
                        style: TextStyle(
                          fontSize: 14,
                          color: tokens.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2-column Grid of Categories
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: CatalogData.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 200,
                ),
                itemBuilder: (context, index) {
                  final cat = CatalogData.categories[index];
                  return _CategoryCard(category: cat);
                },
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
          context.push('/list');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CaTokens.catRadius),
          border: Border.all(color: tokens.line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Composition of 2-4 products stacked
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 120,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0;
                          i < category.previewProductIds.length && i < 4;
                          i++) ...[
                        _buildProductInStack(
                          category.previewProductIds[i],
                          i,
                          category.previewProductIds.length,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Name and Chevron
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: tokens.blue,
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Subtitle
            Text(
              category.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: tokens.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInStack(String id, int index, int total) {
    double left = 20;
    double top = 10;
    double scale = 1.0;

    if (total >= 4) {
      if (index == 0) {
        left = 4;
        top = 28;
        scale = 0.85;
      } else if (index == 1) {
        left = 28;
        top = 4;
        scale = 1.0;
      } else if (index == 2) {
        left = 60;
        top = 18;
        scale = 0.9;
      } else {
        left = 40;
        top = 45;
        scale = 0.8;
      }
    } else if (total == 2) {
      if (index == 0) {
        left = 8;
        top = 16;
      } else {
        left = 50;
        top = 22;
      }
    }

    return Positioned(
      left: left,
      top: top,
      child: Transform.scale(
        scale: scale,
        child: Image.asset(
          CaAssets.product(id),
          width: 52,
          height: 52,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
