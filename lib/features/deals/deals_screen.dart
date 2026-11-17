import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/tokens.dart';
import '../../data/catalog_data.dart';
import '../../shared/flip_counter.dart';
import '../../shared/product_card.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key, this.onAddProduct});

  final void Function(GlobalKey key, String productId)? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final dealProducts =
        CatalogData.dealsIds.map((id) => CatalogData.getProductById(id)!).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Blue Header with giant "%" in background
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: tokens.navy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: tokens.navy),
                  // Giant "%" background
                  Positioned(
                    right: -20,
                    bottom: -30,
                    child: Text(
                      '%',
                      style: TextStyle(
                        fontSize: 220,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.08),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 60, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: const [
                            Text('🔥', style: TextStyle(fontSize: 22)),
                            SizedBox(width: 8),
                            Text(
                              'Ofertas del día',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Precios especiales que vencen a medianoche',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: const [
                            Text(
                              'Terminan en  ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            FlipCounter(isLight: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2-column Grid of Deals
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 230,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = dealProducts[index];
                  return ProductCard(
                    product: p,
                    onTap: () => context.push('/product/${p.id}'),
                    onAddWithGlobalKey: (key, prod) {
                      onAddProduct?.call(key, prod.id);
                    },
                  );
                },
                childCount: dealProducts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
