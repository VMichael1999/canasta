import 'package:flutter/material.dart';
import 'floating_cart_bubble.dart';

/// Da acceso a la burbuja global del carrito (vive encima del router) para
/// lanzar el vuelo del producto desde cualquier pantalla.
class CartBubbleScope extends InheritedWidget {
  const CartBubbleScope({
    super.key,
    required this.bubbleKey,
    required super.child,
  });

  final GlobalKey<FloatingCartBubbleState> bubbleKey;

  static CartBubbleScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CartBubbleScope>();
  }

  /// Vuela la ilustración del producto hasta la primera miniatura de la burbuja.
  static void flyToBubble(
    BuildContext context,
    GlobalKey sourceKey,
    String productId,
  ) {
    final scope = CartBubbleScope.of(context);
    scope?.bubbleKey.currentState?.flyFrom(sourceKey, productId);
  }

  @override
  bool updateShouldNotify(CartBubbleScope oldWidget) =>
      bubbleKey != oldWidget.bubbleKey;
}
