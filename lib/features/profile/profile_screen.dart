import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/favorites/favorites_cubit.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../blocs/session/session_bloc.dart';
import '../../core/tokens.dart';
import '../../shared/address_picker_sheet.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifOrders = true;
  bool _notifOffers = true;
  bool _notifNews = false;

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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DCE5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '¿Cerrar sesión?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tu carrito queda guardado en este celular.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: tokens.ink2),
            ),
            const SizedBox(height: 22),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
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

  void _showPaymentMethodsSheet(BuildContext context) {
    final tokens = context.tokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DCE5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Métodos de pago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.line),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const AppSvgIcon('card',
                        size: 22, color: Color(0xFF1A4FE0)),
                    title: const Text('Visa •••• 4821',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Débito',
                        style: TextStyle(fontSize: 12.5)),
                  ),
                  Divider(color: tokens.line, height: 1),
                  ListTile(
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF820AD1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Y',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                    title: const Text('Yape',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Desde tu app',
                        style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponsSheet(BuildContext context) {
    final tokens = context.tokens;
    final coupons = [
      {'code': 'CANASTA10', 'pct': '10 % de descuento, hasta S/ 15'},
      {'code': 'FRESCO15', 'pct': '15 % de descuento, hasta S/ 15'},
      {'code': 'HOLA20', 'pct': '20 % de descuento, hasta S/ 15'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DCE5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cupones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            ...coupons.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tokens.blueSoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: AppSvgIcon('tag', size: 18, color: tokens.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['code']!,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                            Text(
                              c['pct']!,
                              style: TextStyle(
                                  fontSize: 12.5, color: tokens.ink2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final tokens = context.tokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DCE5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifOrders,
                activeColor: tokens.green,
                title: const Text('Estado de mis pedidos',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                onChanged: (val) {
                  setSheetState(() => _notifOrders = val);
                  setState(() => _notifOrders = val);
                },
              ),
              Divider(color: tokens.line, height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifOffers,
                activeColor: tokens.green,
                title: const Text('Ofertas del día',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                onChanged: (val) {
                  setSheetState(() => _notifOffers = val);
                  setState(() => _notifOffers = val);
                },
              ),
              Divider(color: tokens.line, height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifNews,
                activeColor: tokens.green,
                title: const Text('Novedades de Canasta',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                onChanged: (val) {
                  setSheetState(() => _notifNews = val);
                  setState(() => _notifNews = val);
                },
              ),
            ],
          ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header (.pfh)
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
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.email} · +51 ${user.phone}',
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.ink2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AppToast.show(context, 'Edición de perfil: pronto.');
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tokens.border),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon('edit', size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Stats Row (.pfs)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.line),
                ),
                child: Row(
                  children: [
                    _buildStatCol('Pedidos', '$totalOrders', tokens),
                    Container(width: 1, height: 63, color: tokens.line),
                    _buildStatCol('Ahorrado', 'S/ 28.40', tokens),
                    Container(width: 1, height: 63, color: tokens.line),
                    _buildStatCol('Favoritos', '$favCount', tokens),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Menu list (.mlist.big)
              _buildMenuItem(
                icon: 'pin',
                title: 'Mis direcciones',
                subtitle: '2 guardadas',
                tokens: tokens,
                onTap: () => AddressPickerSheet.show(context),
              ),
              _buildMenuItem(
                icon: 'card',
                title: 'Métodos de pago',
                subtitle: 'Visa •••• 4821, Yape',
                tokens: tokens,
                onTap: () => _showPaymentMethodsSheet(context),
              ),
              _buildMenuItem(
                icon: 'heart',
                title: 'Favoritos',
                subtitle: '$favCount productos',
                tokens: tokens,
                onTap: () => context.push('/search'),
              ),
              _buildMenuItem(
                icon: 'tag',
                title: 'Cupones',
                subtitle: 'CANASTA10 disponible',
                tokens: tokens,
                onTap: () => _showCouponsSheet(context),
              ),
              _buildMenuItem(
                icon: 'bell',
                title: 'Notificaciones',
                subtitle: 'Pedidos y ofertas',
                tokens: tokens,
                onTap: () => _showNotificationsSheet(context),
              ),
              _buildMenuItem(
                icon: 'help',
                title: 'Ayuda',
                subtitle: 'Preguntas frecuentes y chat',
                tokens: tokens,
                onTap: () => context.push('/help'),
              ),

              const SizedBox(height: 24),

              // Logout Button (.btn.ghost.red)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: AppSvgIcon('logout', size: 20, color: tokens.bad),
                  label: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.bad,
                    ),
                  ),
                  style: TextButton.styleFrom(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: tokens.ink,
                letterSpacing: -0.02 * 17,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                height: 1.35,
                fontSize: 12,
                color: tokens.ink2,
              ),
            ),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: tokens.line),
          ),
        ),
        child: Row(
          children: [
            AppSvgIcon(icon, size: 22, color: tokens.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      height: 1.35,
                      fontSize: 13,
                      color: tokens.ink2,
                    ),
                  ),
                ],
              ),
            ),
            AppSvgIcon('chev', size: 16, color: tokens.ink3),
          ],
        ),
      ),
    );
  }
}
