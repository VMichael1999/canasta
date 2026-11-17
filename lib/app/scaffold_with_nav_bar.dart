import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/orders/orders_cubit.dart';
import '../core/haptics.dart';
import '../core/tokens.dart';
import '../shared/app_svg_icon.dart';
import '../shared/cart_bubble_scope.dart';
import '../shared/floating_cart_bubble.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  final GlobalKey<FloatingCartBubbleState> _bubbleKey =
      GlobalKey<FloatingCartBubbleState>();

  void _onItemTapped(int index) {
    CaHaptics.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentIndex = widget.navigationShell.currentIndex;

    return CartBubbleScope(
      bubbleKey: _bubbleKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            widget.navigationShell,
            FloatingCartBubble(
              key: _bubbleKey,
              onTap: () => context.push('/cart'),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: tokens.line, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  _NavBarItem(
                    index: 0,
                    currentIndex: currentIndex,
                    label: 'Inicio',
                    iconName: 'home',
                    onTap: () => _onItemTapped(0),
                  ),
                  _NavBarItem(
                    index: 1,
                    currentIndex: currentIndex,
                    label: 'Categorías',
                    iconName: 'grid',
                    onTap: () => _onItemTapped(1),
                  ),
                  BlocBuilder<OrdersCubit, OrdersState>(
                    builder: (context, state) {
                      final activeCount = state.liveOrders.length;
                      return _NavBarItem(
                        index: 2,
                        currentIndex: currentIndex,
                        label: 'Pedidos',
                        iconName: 'orders',
                        badgeCount: activeCount > 0 ? activeCount : null,
                        onTap: () => _onItemTapped(2),
                      );
                    },
                  ),
                  _NavBarItem(
                    index: 3,
                    currentIndex: currentIndex,
                    label: 'Perfil',
                    iconName: 'user',
                    onTap: () => _onItemTapped(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.iconName,
    this.badgeCount,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final String iconName;
  final int? badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isSelected = index == currentIndex;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppSvgIcon(
                      iconName,
                      size: 23,
                      color: isSelected ? tokens.blue : tokens.ink2,
                    ),
                    if (badgeCount != null)
                      Positioned(
                        top: -4,
                        right: -10,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 17,
                            minHeight: 17,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: tokens.blue,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? tokens.blue : tokens.ink2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
