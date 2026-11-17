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

class ProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final imageKey = GlobalKey();

    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (prev, curr) =>
          prev.quantityOf(product.id) != curr.quantityOf(product.id),
      builder: (context, cartState) {
        final currentQty = cartState.quantityOf(product.id);

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CaTokens.cardRadius),
              border: Border.all(color: tokens.line, width: 1),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image area with discount tag
                Expanded(
                  child: Center(
                    child: Stack(
                      children: [
                        Center(
                          child: KeyedSubtree(
                            key: imageKey,
                            child: Image.asset(
                              CaAssets.product(product.id),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shopping_basket,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        if (product.hasDiscount)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.greenSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${product.discountPct}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.green,
                                ),
                              ),
                            ),
                          ),
                        if (!product.inStock)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: tokens.badSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Agotado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.bad,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Product Name
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 2),

                // Unit label
                Text(
                  product.isKg ? '1 kg' : product.unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: tokens.ink2,
                  ),
                ),
                const SizedBox(height: 8),

                // Price and action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Price column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatPen(product.price),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          if (product.hasDiscount)
                            Text(
                              formatPen(product.oldPrice),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.lineThrough,
                                color: tokens.ink3,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Add or Stepper button
                    if (!product.inStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tokens.chip,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Avísame',
                          style: TextStyle(
                            fontSize: 11.5,
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
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
