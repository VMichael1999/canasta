import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import '../core/assets.dart';
import '../core/haptics.dart';
import '../core/money.dart';
import '../core/tokens.dart';
import '../domain/models/product.dart';
import 'app_svg_icon.dart';
import 'qty_stepper.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddWithGlobalKey,
  });

  final Product product;
  final VoidCallback? onTap;
  final void Function(GlobalKey imageKey, Product product)? onAddWithGlobalKey;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final GlobalKey imageKey = GlobalKey();

  Product get product => widget.product;
  VoidCallback? get onTap => widget.onTap;
  void Function(GlobalKey, Product)? get onAddWithGlobalKey =>
      widget.onAddWithGlobalKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (prev, curr) =>
          prev.quantityOf(product.id) != curr.quantityOf(product.id),
      builder: (context, cartState) {
        final currentQty = cartState.quantityOf(product.id);
        final isOutOfStock = !product.inStock;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CaTokens.cardRadius),
              border: Border.all(color: tokens.line, width: 1),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image area (.pim: height 100-118, relative)
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Product Image with opacity if out of stock
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Opacity(
                            opacity: isOutOfStock ? 0.45 : 1.0,
                            child: KeyedSubtree(
                              key: imageKey,
                              child: Image.asset(
                                CaAssets.product(product.id),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shopping_basket,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Discount tag (.off: left: -2, top: -2, height: 22, radius 7, bg greensoft, color green)
                      if (product.hasDiscount)
                        Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            decoration: BoxDecoration(
                              color: tokens.greenSoft,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '-${product.discountPct}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tokens.green,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),

                      // Sold out badge (.soldout: left: 12, top: 12, height: 22, radius 7, bg #121A33, color #fff)
                      if (isOutOfStock)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121A33),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Agotado',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Product Name (.pc > b: 13.5px 600, single line ellipsis)
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),

                // Unit label (.pc > small: 12px ink2)
                Text(
                  product.isKg ? '1 kg' : product.unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 8),

                // Price and action row (.pr)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price column (.pp)
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatPen(product.price),
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                                letterSpacing: -0.15,
                                height: 1.05,
                              ),
                            ),
                            if (product.hasDiscount)
                              Text(
                                formatPen(product.oldPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.lineThrough,
                                  color: tokens.ink3,
                                  height: 1.05,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Action button: Avísame, Stepper, or Plus circle
                      if (isOutOfStock)
                        Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: tokens.chip,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Avísame',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink2,
                            ),
                          ),
                        )
                      else if (currentQty > 0)
                        QtyStepper(
                          product: product,
                          quantity: currentQty,
                          style: StepperStyle.cardPill,
                          onChanged: (newQty) {
                            if (newQty > currentQty) {
                              onAddWithGlobalKey?.call(imageKey, product);
                            }
                            context
                                .read<CartBloc>()
                                .add(CartItemQtyChanged(product.id, newQty));
                          },
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            CaHaptics.lightImpact();
                            onAddWithGlobalKey?.call(imageKey, product);
                            context
                                .read<CartBloc>()
                                .add(CartItemAdded(product, quantity: product.step));
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: tokens.blue,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const AppSvgIcon(
                              'plus',
                              size: 17,
                              color: Colors.white,
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
    );
  }
}
