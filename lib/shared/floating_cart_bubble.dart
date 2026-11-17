import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/cart/cart_event.dart';
import '../blocs/cart/cart_state.dart';
import '../core/assets.dart';
import '../core/haptics.dart';
import '../core/money.dart';
import '../core/tokens.dart';
import '../domain/models/cart_item.dart';
import 'app_toast.dart';
import 'qty_stepper.dart';

class FloatingCartBubble extends StatefulWidget {
  const FloatingCartBubble({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<FloatingCartBubble> createState() => FloatingCartBubbleState();
}

class FloatingCartBubbleState extends State<FloatingCartBubble>
    with SingleTickerProviderStateMixin {
  double _dy = 640;
  bool _isRightSide = true;
  bool _isDragging = false;
  late AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 1.0,
      upperBound: 1.10,
    );
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void pop() {
    _popController.forward().then((_) => _popController.reverse());
  }

  Offset get bubbleTargetOffset {
    final screenSize = MediaQuery.of(context).size;
    final x = _isRightSide ? screenSize.width - 70 : 30.0;
    return Offset(x, _dy + 10);
  }

  void _showQuickPeek(BuildContext context, CartState cartState) {
    CaHaptics.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickPeekSheet(cartState: cartState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final screenSize = MediaQuery.of(context).size;

    return BlocConsumer<CartBloc, CartState>(
      listenWhen: (prev, curr) => prev.lines.length != curr.lines.length || prev.total != curr.total,
      listener: (context, state) {
        pop();
      },
      builder: (context, cartState) {
        if (cartState.lines.isEmpty) return const SizedBox.shrink();

        final lines = cartState.lines;
        final top3 = lines.take(3).toList();
        final remainingCount = lines.length - 3;

        final bubbleWidth = 190.0 + (top3.length - 1) * 26.0;

        return Positioned(
          left: _isRightSide ? null : 16,
          right: _isRightSide ? 16 : null,
          top: _dy.clamp(90.0, screenSize.height - 180.0),
          child: ScaleTransition(
            scale: _popController,
            child: GestureDetector(
              onTap: widget.onTap,
              onLongPress: () => _showQuickPeek(context, cartState),
              onPanStart: (_) {
                setState(() => _isDragging = true);
              },
              onPanUpdate: (details) {
                setState(() {
                  _dy += details.delta.dy;
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                  // Snap to nearest edge
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    _isRightSide = true;
                  } else if (details.velocity.pixelsPerSecond.dx < -200) {
                    _isRightSide = false;
                  }
                });
                CaHaptics.selectionClick();
              },
              child: AnimatedScale(
                scale: _isDragging ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  height: 64,
                width: bubbleWidth,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: tokens.line, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _isRightSide
                      ? [
                          // Stacked thumbnails
                          _buildStackedThumbnails(top3, remainingCount, tokens),
                          const SizedBox(width: 8),
                          // Price & units
                          _buildPriceColumn(cartState, tokens, CrossAxisAlignment.end),
                        ]
                      : [
                          // Price & units
                          _buildPriceColumn(cartState, tokens, CrossAxisAlignment.start),
                          const SizedBox(width: 8),
                          // Stacked thumbnails
                          _buildStackedThumbnails(top3, remainingCount, tokens),
                        ],
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildStackedThumbnails(
    List<CartItem> top3,
    int remainingCount,
    CaTokens tokens,
  ) {
    return SizedBox(
      height: 44,
      width: 44.0 + (top3.length - 1) * 26.0 + (remainingCount > 0 ? 26.0 : 0.0),
      child: Stack(
        children: [
          for (int i = 0; i < top3.length; i++)
            Positioned(
              left: i * 26.0,
              child: _ThumbnailDragItem(item: top3[i]),
            ),
          if (remainingCount > 0)
            Positioned(
              left: top3.length * 26.0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.chip,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceColumn(
    CartState cartState,
    CaTokens tokens,
    CrossAxisAlignment alignment,
  ) {
    final unitsStr =
        '${cartState.units} producto${cartState.units > 1 ? 's' : ''}';

    return Column(
      crossAxisAlignment: alignment,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          unitsStr,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: tokens.ink2,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            formatPen(cartState.total),
            key: ValueKey(cartState.total),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: tokens.blue,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThumbnailDragItem extends StatefulWidget {
  const _ThumbnailDragItem({required this.item});

  final CartItem item;

  @override
  State<_ThumbnailDragItem> createState() => _ThumbnailDragItemState();
}

class _ThumbnailDragItemState extends State<_ThumbnailDragItem> {
  double _dragDy = 0.0;

  @override
  Widget build(BuildContext context) {
    final isRemovedThreshold = _dragDy < -60;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragDy += details.delta.dy;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragDy < -70) {
          final p = widget.item.product;
          context.read<CartBloc>().add(CartItemRemoved(p.id));
          CaHaptics.mediumImpact();
          AppToast.show(
            context,
            'Quitaste ${p.name.toLowerCase()}.',
            actionLabel: 'Deshacer',
            onAction: () {
              context.read<CartBloc>().add(const CartUndoRemove());
            },
          );
        }
        setState(() {
          _dragDy = 0.0;
        });
      },
      child: Transform.translate(
        offset: Offset(0, _dragDy.clamp(-90.0, 0.0)),
        child: Opacity(
          opacity: isRemovedThreshold ? 0.4 : 1.0,
          child: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Image.asset(
                    CaAssets.product(widget.item.product.id),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (widget.item.quantity > 1)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A4FE0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '×${widget.item.quantity.toInt()}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPeekSheet extends StatelessWidget {
  const _QuickPeekSheet({required this.cartState});

  final CartState cartState;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Title & items count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vistazo del carrito',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
              Text(
                '${cartState.units} productos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product rows
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: cartState.lines.length,
              separatorBuilder: (_, __) => Divider(color: tokens.line, height: 1),
              itemBuilder: (context, index) {
                final item = cartState.lines[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          CaAssets.product(item.product.id),
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: tokens.ink,
                              ),
                            ),
                            Text(
                              formatPen(item.product.price),
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      QtyStepper(
                        product: item.product,
                        quantity: item.quantity,
                        style: StepperStyle.cartSmall,
                        onChanged: (newQty) {
                          context
                              .read<CartBloc>()
                              .add(CartItemQtyChanged(item.product.id, newQty));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Go to cart button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/cart');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ver mi carrito',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    formatPen(cartState.total),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
