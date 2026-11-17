import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/live_order/live_order_bloc.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';
import '../../shared/illustrated_map.dart';
import 'chat_sheet.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isFullscreenMap = false;

  void _showChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const ChatSheet(),
      ),
    );
  }

  void _showOrderDetailsSheet(BuildContext context, LiveOrderState state) {
    final tokens = context.tokens;
    final order = state.order;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Detalle del pedido ${order.id}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: order.items.length,
                separatorBuilder: (_, __) =>
                    Divider(color: tokens.line, height: 1),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            CaAssets.product(item.product.id),
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item.product.name} × ${item.quantity.toInt()}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                        Text(
                          formatPen(item.total),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                Text(
                  formatPen(order.total),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tokens.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocConsumer<LiveOrderBloc, LiveOrderState>(
      listenWhen: (prev, curr) =>
          (!prev.nearAlertTriggered && curr.nearAlertTriggered) ||
          (!prev.deliveredAlertTriggered && curr.deliveredAlertTriggered),
      listener: (context, state) {
        if (state.deliveredAlertTriggered) {
          CaHaptics.heavyImpact();
          AppToast.show(
            context,
            '¡Tu pedido fue entregado!',
            actionLabel: 'Calificar',
            onAction: () => context.push('/rate'),
          );
        } else if (state.nearAlertTriggered) {
          CaHaptics.mediumImpact();
          AppToast.show(
            context,
            'Tu pedido está a 2 min. Ten listo tu celular.',
          );
        }
      },
      builder: (context, state) {
        final order = state.order;

        if (_isFullscreenMap) {
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: IllustratedMap(
                    progress: state.routeProgress,
                    distanceKm: state.distanceKm,
                    showExpandButton: false,
                  ),
                ),
                Positioned(
                  top: 54,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => setState(() => _isFullscreenMap = false),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.arrow_back, color: tokens.ink),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: _buildCourierCard(context, state, tokens),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Seguimiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(
                  child: Text(
                    order.id,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ETA and Arrival Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.stage >= 3 ? 'Entregado' : 'Llega hoy',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.ink2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.stage >= 3 ? '¡Listo!' : '3:40 p. m.',
                            style: CaTypography.eta,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: tokens.blueSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              state.stage >= 3
                                  ? 'Entregado con éxito'
                                  : 'Faltan ${state.minsLeft} min',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.blue,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline,
                                size: 14, color: tokens.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4 Steps Horizontal Tracker: Pedido hecho, Confirmado, En camino, Entregado
                  _buildStepsTracker(state.stage, tokens),
                  const SizedBox(height: 24),

                  // Illustrated Map preview (tap to expand)
                  SizedBox(
                    height: 200,
                    child: IllustratedMap(
                      progress: state.routeProgress,
                      distanceKm: state.distanceKm,
                      showExpandButton: true,
                      onExpand: () {
                        setState(() => _isFullscreenMap = true);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Repartidor Card
                  _buildCourierCard(context, state, tokens),
                  const SizedBox(height: 20),

                  // Resumen del pedido
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.chip,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Resumen del pedido',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showOrderDetailsSheet(context, state),
                              child: Text(
                                'Ver detalle',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Thumbnails
                        Row(
                          children: [
                            for (int i = 0;
                                i < order.items.length && i < 4;
                                i++) ...[
                              Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Image.asset(
                                  CaAssets.product(order.items[i].product.id),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                            if (order.items.length > 4)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+${order.items.length - 4}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Support box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.chip,
                          ),
                          alignment: Alignment.center,
                          child:
                              AppSvgIcon('help', size: 20, color: tokens.blue),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Necesitas ayuda?',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estamos para ti 24/7',
                                style: TextStyle(
                                    fontSize: 12.5, color: tokens.ink2),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/help'),
                          child: Text(
                            'Contactar',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepsTracker(int currentStage, CaTokens tokens) {
    final steps = ['Hecho', 'Confirmado', 'En camino', 'Entregado'];

    return Row(
      children: List.generate(steps.length, (index) {
        final isPassed = index <= currentStage;
        final isCurrent = index == currentStage;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      color: index == 0
                          ? Colors.transparent
                          : (isPassed ? tokens.blue : tokens.border),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed ? tokens.blue : tokens.border,
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 4,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : (index < currentStage
                              ? tokens.blue
                              : tokens.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isPassed ? FontWeight.w700 : FontWeight.w500,
                  color: isPassed ? tokens.ink : tokens.ink3,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCourierCard(
      BuildContext context, LiveOrderState state, CaTokens tokens) {
    final courier = state.order.courier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              CaAssets.rider,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu repartidor',
                  style: TextStyle(fontSize: 12, color: tokens.ink2),
                ),
                Text(
                  courier.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: tokens.sun),
                    const SizedBox(width: 3),
                    Text(
                      '${courier.rating} (${courier.reviewsCount}) · ${courier.vehicle} ${courier.plate}',
                      style: TextStyle(fontSize: 12, color: tokens.ink2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Call & Chat buttons
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  AppToast.show(context, 'Llamando a ${courier.name}…');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.blueSoft,
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon('phone', size: 18, color: tokens.blue),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showChat(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.blueSoft,
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon('chat', size: 18, color: tokens.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
