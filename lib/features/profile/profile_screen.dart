import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/favorites/favorites_cubit.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../blocs/session/session_bloc.dart';
import '../../core/tokens.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifOffers = true;
  bool _notifOrders = true;

  void _showLogoutDialog(BuildContext context) {
    final tokens = context.tokens;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¿Cerrar sesión?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu carrito y direcciones guardadas seguirán aquí cuando vuelvas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: tokens.ink2),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.read<SessionBloc>().add(const SignedOut());
                  Navigator.of(ctx).pop();
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.bad,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text('Cerrar sesión',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancelar',
                    style: TextStyle(fontSize: 15, color: tokens.ink2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = context.watch<SessionBloc>().state.user;
    final totalOrders = context.watch<OrdersCubit>().state.orders.length;
    final favCount = context.watch<FavoritesCubit>().state.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 110),
          child: Column(
            children: [
              // User Header: Initials Avatar + Michael Dev + michaeldev@gmail.com
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.blue,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: tokens.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: tokens.ink2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+51 ${user.phone}',
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.ink3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Row: Pedidos (3) / Ahorrado (S/ 24.50) / Favoritos (N)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: tokens.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildStatCol('Pedidos', '$totalOrders', tokens),
                    Container(width: 1, height: 32, color: tokens.border),
                    _buildStatCol('Ahorrado', 'S/ 24.50', tokens),
                    Container(width: 1, height: 32, color: tokens.border),
                    _buildStatCol('Favoritos', '$favCount', tokens),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu list
              _buildMenuItem(
                icon: 'pin',
                title: 'Direcciones guardadas',
                subtitle: 'Casa, Trabajo',
                tokens: tokens,
                onTap: () => context.push('/location'),
              ),
              _buildMenuItem(
                icon: 'card',
                title: 'Métodos de pago',
                subtitle: 'Visa •••• 4821',
                tokens: tokens,
                onTap: () {
                  AppToast.show(context, 'Visa •••• 4821 activa.');
                },
              ),
              _buildMenuItem(
                icon: 'heart',
                title: 'Mis favoritos',
                subtitle: '$favCount productos guardados',
                tokens: tokens,
                onTap: () => context.push('/search'),
              ),
              _buildMenuItem(
                icon: 'tag',
                title: 'Cupones de descuento',
                subtitle: '3 disponibles',
                tokens: tokens,
                onTap: () => context.push('/cart'),
              ),
              _buildMenuItem(
                icon: 'help',
                title: 'Centro de ayuda',
                subtitle: 'Preguntas frecuentes y soporte',
                tokens: tokens,
                onTap: () => context.push('/help'),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Notification switches
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifOrders,
                activeColor: tokens.blue,
                title: Text(
                  'Estado de mis pedidos',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
                subtitle: Text(
                  'Notificar cuando la moto esté cerca',
                  style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                ),
                onChanged: (val) => setState(() => _notifOrders = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifOffers,
                activeColor: tokens.blue,
                title: Text(
                  'Ofertas del día',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
                subtitle: Text(
                  'Avisos de descuentos en frutas y verduras',
                  style: TextStyle(fontSize: 12.5, color: tokens.ink2),
                ),
                onChanged: (val) => setState(() => _notifOffers = val),
              ),

              const SizedBox(height: 24),

              // Cerrar sesión
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: Icon(Icons.logout, color: tokens.bad, size: 18),
                  label: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.bad,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tokens.bad.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _buildStatCol(String label, String value, CaTokens tokens) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: tokens.ink2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required String subtitle,
    required CaTokens tokens,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.chip,
        ),
        alignment: Alignment.center,
        child: AppSvgIcon(icon, size: 19, color: tokens.ink),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: tokens.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.5, color: tokens.ink2),
      ),
      trailing:
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: tokens.ink3),
      onTap: onTap,
    );
  }
}
