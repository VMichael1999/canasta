import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/catalog_data.dart';
import '../../shared/ca_tab_bar.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/flip_counter.dart';
import '../../shared/product_card.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key, this.onAddProduct});

  final void Function(GlobalKey key, String productId)? onAddProduct;

  @override
  Widget build(BuildContext context) {
    final dealProducts = CatalogData.dealsIds
        .map((id) => CatalogData.getProductById(id)!)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CaTabBar(activeIndex: 0),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Blue Header with gradient and giant "%" (.dhead)
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B2A73), Color(0xFF1A4FE0)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Giant "%" in background
                      Positioned(
                        right: -12,
                        top: 40,
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontSize: 210,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.08),
                            height: 1.0,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 110, 22, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fire icon container (.dfire)
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const AppSvgIcon('fire', size: 22, color: Colors.white),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Ofertas del día',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.03 * 30,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Precios especiales que vencen a medianoche',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Clock container (.dclock)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Terminan en',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const FlipCounter(isLight: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2-column Grid of Deals (.pgrid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 222,
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

          // Floating Top-left Back Button (.rtop.light)
          Positioned(
            top: 54,
            left: 22,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x240A1E5A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon('arrowl', size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
