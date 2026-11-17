import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'floating_cart_bubble.dart';
import 'fly_animator.dart';

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

  static void flyToBubble(
    BuildContext context,
    GlobalKey sourceKey,
    String productId,
  ) {
    final scope = CartBubbleScope.of(context);
    final target = scope?.bubbleKey.currentState?.bubbleTargetOffset ??
        Offset(MediaQuery.of(context).size.width - 70, 640);

    FlyAnimator.flyToBubble(
      context: context,
      sourceKey: sourceKey,
      productId: productId,
      targetOffset: target,
      onComplete: () {
        scope?.bubbleKey.currentState?.pop();
      },
    );
  }

  @override
  bool updateShouldNotify(CartBubbleScope oldWidget) =>
      bubbleKey != oldWidget.bubbleKey;
}

class CartBubbleOverlayWrapper extends StatefulWidget {
  const CartBubbleOverlayWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<CartBubbleOverlayWrapper> createState() =>
      _CartBubbleOverlayWrapperState();
}

class _CartBubbleOverlayWrapperState extends State<CartBubbleOverlayWrapper> {
  final GlobalKey<FloatingCartBubbleState> _bubbleKey =
      GlobalKey<FloatingCartBubbleState>();

  @override
  Widget build(BuildContext context) {
    return CartBubbleScope(
      bubbleKey: _bubbleKey,
      child: Stack(
        children: [
          widget.child,
          FloatingCartBubble(
            key: _bubbleKey,
            onTap: () => context.push('/cart'),
          ),
        ],
      ),
    );
  }
}
