import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/live_order/live_order_bloc.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../core/weight.dart';
import '../../core/tokens.dart';
import '../../shared/ca_tab_bar.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';
import '../../shared/illustrated_map.dart';
import 'dart:math' as math;
import '../navigation/ui/map_preview.dart';
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
              order.id,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} productos · ${formatPen(order.total)}',
              style: TextStyle(fontSize: 14, color: tokens.ink2),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: order.items.length,
                separatorBuilder: (_, __) =>
                    Divider(color: tokens.line, height: 1),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  final p = item.product;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: tokens.chip,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            CaAssets.product(p.id),
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.isKg
                                    ? '${item.quantity} kg'
                                    : '${item.quantity.toInt()} und',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: tokens.ink2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatPen(item.total),
                          style: TextStyle(
                            fontSize: 14.5,
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
            Divider(color: tokens.line, height: 1),
            const SizedBox(height: 14),
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
                    fontSize: 19,
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


  // ---------- utilidades de formato ----------
  static String _clock(int minutes) {
    final m = ((minutes % 1440) + 1440) % 1440;
    final h = m ~/ 60, mm = m % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${mm.toString().padLeft(2, '0')}';
  }

  static String _ampm(int minutes) {
    final m = ((minutes % 1440) + 1440) % 1440;
    return m >= 720 ? 'p. m.' : 'a. m.';
  }

  static int _nowMin() {
    final d = DateTime.now();
    return d.hour * 60 + d.minute;
  }

  static const _stepNames = [
    'Pedido hecho',
    'Confirmado',
    'En camino',
    'Entregado',
  ];

  String _kmLabel(LiveOrderState s, {bool unit = true}) {
    if (s.stage >= 3) return 'Entregado';
    if (s.stage < 2) return 'En tienda';
    final km = LiveOrderBloc.totalKm * (1 - s.routeProgress);
    return unit ? 'A ${km.toStringAsFixed(1)} km' : '${km.toStringAsFixed(1)} km';
  }

  double _mapProgress(LiveOrderState s) =>
      s.stage < 2 ? 0 : (s.stage >= 3 ? 1 : s.routeProgress);

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
            'Tu pedido llegó. ¡Buen provecho!',
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
        final topPad = math.max(MediaQuery.of(context).padding.top - 6, 0.0);
        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar:
              _isFullscreenMap ? null : const CaTabBar(activeIndex: 2),
          body: Stack(
            children: [
              _buildMain(context, state, tokens, topPad),
            ],
          ),
        );
      },
    );
  }

  // ---------- pantalla principal ----------
  Widget _buildMain(BuildContext context, LiveOrderState state, CaTokens tokens,
      double topPad) {
    final order = state.order;
    final arrive = _nowMin() + state.minsLeft;
    final delivered = state.stage >= 3;
    final onTheWay = state.stage == 2;

    return Stack(
      children: [
        // contenido (scroll con padding superior 112 como el HTML)
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, topPad + 56, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // .eta
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              delivered ? 'Entregado' : 'Llega hoy',
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: tokens.ink,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 2),
                              child: delivered
                                  ? Text(
                                      '¡Llegó!',
                                      style: TextStyle(
                                        fontSize: 38,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.14,
                                        color: tokens.blue,
                                      ),
                                    )
                                  : Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: _clock(arrive)),
                                          const WidgetSpan(
                                              child: SizedBox(width: 5)),
                                          TextSpan(
                                            text: _ampm(arrive),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: TextStyle(
                                        fontSize: 38,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.14,
                                        color: tokens.blue,
                                      ),
                                    ),
                            ),
                            if (delivered)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: GestureDetector(
                                  onTap: () => context.push('/rate'),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: tokens.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Calificar pedido',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    onTheWay
                                        ? 'Faltan ${state.minsLeft} min'
                                        : 'Hora estimada de llegada',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: tokens.ink2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AppSvgIcon('info',
                                      size: 14, color: tokens.ink2),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        height: 112,
                        child: _CourierIllustration(
                          delivered: delivered,
                          moving: onTheWay,
                        ),
                      ),
                    ],
                  ),
                ),

                // .steps
                _buildSteps(state, tokens),

                // .tmap
                GestureDetector(
                  onTap: () => context.push('/navigation'),
                  child: Semantics(
                    button: true,
                    label: 'Ver mapa en pantalla completa',
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: tokens.line),
                      ),
                      child: IllustratedMap(
                        mapChild: GoogleMapPreview(
                          showRoute: true,
                          progress: _mapProgress(state),
                        ),
                        progress: _mapProgress(state),
                        kmLabel: _kmLabel(state),
                        showExpandButton: true,
                        radius: 18,
                        onExpand: () => context.push('/navigation'),
                      ),
                    ),
                  ),
                ),

                // .cour
                const SizedBox(height: 14),
                _buildCourierCard(context, state, tokens, glass: false),

                // .sec + .otiles
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Resumen del pedido',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.27,
                          color: tokens.ink,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showOrderDetailsSheet(context, state),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Ver detalle',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: tokens.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTiles(order, tokens),

                // .needh
                Container(
                  margin: const EdgeInsets.only(top: 18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.line),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: AppSvgIcon('headset', size: 26, color: tokens.ink),
                      ),
                      const SizedBox(width: 12),
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
                            Text(
                              'Estamos para ti 24/7',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/help'),
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: tokens.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Contactar soporte',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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

        // .top3 fijo
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(22, topPad, 22, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.canPop() ? context.pop() : context.go('/orders'),
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    label: 'Volver',
                    child: SizedBox(
                      width: 34,
                      height: 44,
                      child: OverflowBox(
                        alignment: Alignment.centerRight,
                        minWidth: 44,
                        maxWidth: 44,
                        child: Center(
                          child: AppSvgIcon('arrowl', size: 24, color: tokens.ink),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      'Seguimiento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.18,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pedido #${order.id.replaceAll('CA-', '')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Botón fijo «Pedido recibido» desactivado por ahora: la confirmación
        // se hace desde el aviso «Calificar» al llegar el pedido.
        // Positioned(
        //   left: 0,
        //   right: 0,
        //   bottom: 0,
        //   child: Container(
        //     padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       border: Border(top: BorderSide(color: tokens.border)),
        //     ),
        //     child: _ReceivedButton(
        //       enabled: delivered,
        //       onTap: () {
        //         CaHaptics.heavyImpact();
        //         context.push('/rate');
        //       },
        //     ),
        //   ),
        // ),
      ],
    );
  }

  // ---------- pasos (.steps) ----------
  Widget _buildSteps(LiveOrderState state, CaTokens tokens) {
    final st = state.stage;
    final nw = st >= 3 ? 4 : math.max(1, st);
    final f = math.min(1.0, (nw + (st == 2 ? state.routeProgress * .98 : 0)) / 3);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 18),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return SizedBox(
            height: 26 + 8 + 11.5 * 1.35 + 2,
            child: Stack(
              children: [
                Positioned(
                  left: w * .125,
                  right: w * .125,
                  top: 12,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E6EF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: w * .125,
                  top: 12,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 900),
                    width: w * .75 * f,
                    height: 3,
                    decoration: BoxDecoration(
                      color: tokens.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var k = 0; k < 4; k++)
                      Expanded(
                        child: _StepDot(
                          label: _stepNames[k],
                          state: k < nw ? 1 : (k == nw ? 2 : 0),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- tarjeta del repartidor ----------
  Widget _buildCourierCard(
      BuildContext context, LiveOrderState state, CaTokens tokens,
      {required bool glass}) {
    final courier = state.order.courier;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: glass ? Colors.white.withValues(alpha: .55) : Colors.white,
        borderRadius: BorderRadius.circular(glass ? 20 : 16),
        border: glass ? null : Border.all(color: tokens.line),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE5EDFF),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(CaAssets.rider, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!glass)
                  Text(
                    'Tu repartidor',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: tokens.ink2,
                    ),
                  ),
                Text(
                  courier.name,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: tokens.sun),
                    const SizedBox(width: 3),
                    Text(
                      '${courier.rating}',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: tokens.ink2,
                      ),
                    ),
                    Text(
                      ' (${courier.reviewsCount})',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: tokens.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => AppToast.show(context,
                'Llamando a ${courier.name.split(' ')[0]}… (llamada simulada)'),
            child: Semantics(
              button: true,
              label: 'Llamar',
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tokens.blueSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppSvgIcon('phone', size: 19, color: tokens.blue),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showChat(context),
            child: Semantics(
              button: true,
              label: 'Chatear',
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tokens.blueSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppSvgIcon('chat', size: 19, color: tokens.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- miniaturas del resumen (.otiles) ----------
  Widget _buildTiles(dynamic order, CaTokens tokens) {
    final items = order.items as List;
    final shown = items.take(4).toList();
    final more = items.length - 4;
    return LayoutBuilder(builder: (context, c) {
      // siempre el tamaño de 5 columnas, aunque haya pocos productos
      final w = (c.maxWidth - 4 * 8) / 5;
      Widget tile(Widget inner, String label) => SizedBox(
            width: w,
            child: Column(
              children: [
                Container(
                  width: w,
                  height: w,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.line),
                  ),
                  child: inner,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, height: 1.35, color: tokens.ink2),
                ),
              ],
            ),
          );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            tile(
              Image.asset(CaAssets.product(shown[i].product.id), fit: BoxFit.contain),
              _tileText(shown[i]),
            ),
          ],
          if (more > 0) ...[
            const SizedBox(width: 8),
            tile(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('+$more',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: tokens.ink)),
                  Text('productos',
                      style: TextStyle(fontSize: 11, height: 1.35, color: tokens.ink2)),
                ],
              ),
              ' ',
            ),
          ],
        ],
      );
    });
  }

  String _tileText(dynamic item) {
    final p = item.product;
    final q = item.quantity as double;
    if (p.isKg) return formatWeight(q);
    final u = p.unit as String;
    if (u == 'und' || u.contains('und')) {
      return '${q > 1 ? '${q.toInt()} ' : ''}$u';
    }
    return '${q > 1 ? '${q.toInt()} × ' : ''}$u';
  }
}

/// Punto de un paso: 0 pendiente, 1 hecho (azul con check), 2 ahora (anillo azul que late).
class _StepDot extends StatelessWidget {
  const _StepDot({required this.label, required this.state});

  final String label;
  final int state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(state: state, size: 26),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.35,
            fontWeight: state == 2 ? FontWeight.w600 : FontWeight.w500,
            color: state >= 1 ? tokens.ink : tokens.ink2,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.state, required this.size, this.live = false});

  final int state;
  final double size;
  final bool live;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.state == 2 && !widget.live) _c.repeat();
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.state == 2 && !widget.live) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = widget.live ? Colors.transparent : Colors.white;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pulse = widget.state == 2 && !widget.live
            ? (1 - (2 * (_c.value - .5)).abs()) // 0..1..0
            : 0.0;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.state == 1
                  ? tokens.blue
                  : widget.state == 2
                      ? Colors.white
                      : (widget.live
                          ? const Color(0x1F0F1324)
                          : const Color(0xFFD7DCE6)),
              boxShadow: [
                if (!widget.live)
                  BoxShadow(color: bg, spreadRadius: 3),
                if (pulse > 0)
                  BoxShadow(
                    color: tokens.blue.withValues(alpha: .15 * pulse),
                    spreadRadius: 3 + 4 * pulse,
                  ),
              ],
            ),
            child: widget.state == 1
                ? const Center(
                    child: AppSvgIcon('check', size: 14, color: Colors.white),
                  )
                : widget.state == 2
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: tokens.blue, width: 7),
                        ),
                      )
                    : null,
          ),
        );
      },
    );
  }
}

/// Moto (o bolsa al entregar) con las líneas de velocidad y un leve vaivén.
class _CourierIllustration extends StatefulWidget {
  const _CourierIllustration({required this.delivered, required this.moving});

  final bool delivered;
  final bool moving;

  @override
  State<_CourierIllustration> createState() => _CourierIllustrationState();
}

class _CourierIllustrationState extends State<_CourierIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final bob = -2 * (1 - (2 * (_c.value - .5)).abs());
        Widget speed(double top, double left, double w, double delay) {
          final t = (_c.value + delay) % 1.0;
          final op = t < .5 ? t * 1.2 : (1 - t) * 1.2;
          return Positioned(
            top: top,
            left: left + 10 - 24 * t,
            child: Opacity(
              opacity: op.clamp(0.0, 1.0),
              child: Container(
                width: w,
                height: 3,
                decoration: BoxDecoration(
                  color: tokens.blue.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.moving && !widget.delivered) ...[
              speed(52, -6, 26, 0),
              speed(66, 4, 18, .4),
            ],
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, bob),
                child: Image.asset(
                  widget.delivered ? CaAssets.bag : CaAssets.scooter,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


/// Botón de confirmación del cliente: se habilita cuando el repartidor llegó.
class _ReceivedButton extends StatelessWidget {
  const _ReceivedButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 56,
      decoration: BoxDecoration(
        color: enabled ? t.blue : const Color(0xFFE9ECF3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: t.blue.withValues(alpha: .35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pedido recibido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : t.ink2,
                  ),
                ),
                if (!enabled)
                  Text(
                    'Disponible cuando llegue tu repartidor',
                    style: TextStyle(fontSize: 11.5, color: t.ink2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
