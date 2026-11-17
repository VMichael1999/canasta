import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../blocs/orders/orders_cubit.dart';
import '../core/haptics.dart';
import '../core/tokens.dart';
import 'app_svg_icon.dart';

/// Tab bar plana y blanca del mockup (92 px, borde superior de 1 px).
/// Se usa en el shell y también en las pantallas que el HTML muestra con la
/// barra visible (Detalle, Carrito, Ofertas, Lista, Seguimiento).
class CaTabBar extends StatelessWidget {
  const CaTabBar({super.key, required this.activeIndex, this.onTap});

  final int activeIndex;

  /// Si es null navega con `go` a la ruta raíz de cada pestaña.
  final ValueChanged<int>? onTap;

  static const _tabs = [
    ('Inicio', 'home', '/home'),
    ('Categorías', 'grid', '/cats'),
    ('Pedidos', 'orders', '/orders'),
    ('Perfil', 'user', '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: tokens.line, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: _TabItem(
                label: _tabs[i].$1,
                icon: _tabs[i].$2,
                active: i == activeIndex,
                showBadge: i == 2,
                onTap: () {
                  CaHaptics.selectionClick();
                  if (onTap != null) {
                    onTap!(i);
                  } else {
                    context.go(_tabs[i].$3);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.showBadge,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool active;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = active ? tokens.blue : tokens.ink2;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TabIcon(name: icon, active: active, color: color),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (showBadge)
            BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) {
                final n = state.liveOrders.length;
                if (n == 0) return const SizedBox.shrink();
                return Positioned(
                  top: 0,
                  left: null,
                  right: null,
                  child: Transform.translate(
                    offset: const Offset(18, 0),
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 17, minHeight: 17),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: tokens.blue,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$n',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Ícono de 23 px; el activo va relleno de azul con trazo blanco (como el HTML).
class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.name, required this.active, required this.color});

  final String name;
  final bool active;
  final Color color;

  static final Map<String, Future<String>> _cache = {};

  @override
  Widget build(BuildContext context) {
    if (!active) return AppSvgIcon(name, size: 23, color: color);
    final future = _cache.putIfAbsent(
      name,
      () => rootBundle.loadString('assets/icons/i-$name.svg'),
    );
    return SizedBox(
      width: 23,
      height: 23,
      child: FutureBuilder<String>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) return AppSvgIcon(name, size: 23, color: color);
          final svg = snap.data!
              .replaceFirst('fill="none"', 'fill="#1A4FE0"')
              .replaceFirst('stroke="currentColor"', 'stroke="#FFFFFF"')
              .replaceFirst('stroke-width="2"', 'stroke-width="1.8"');
          return SvgPicture.string(svg, width: 23, height: 23);
        },
      ),
    );
  }
}
