import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/address/address_cubit.dart';
import '../../core/tokens.dart';
import '../../domain/models/address.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';
import '../../shared/illustrated_map.dart';
import '../navigation/ui/map_preview.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  void _showAddAddressSheet(BuildContext context) {
    final tokens = context.tokens;
    final addressCtrl = TextEditingController();
    final districtCtrl = TextEditingController(text: 'Miraflores');
    final refCtrl = TextEditingController();
    String selectedTag = 'Casa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
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
                  'Agregar dirección',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 16),

                // Tag selector (Casa, Trabajo, Otro)
                Row(
                  children: ['Casa', 'Trabajo', 'Otro'].map((tag) {
                    final isSel = selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: isSel,
                        onSelected: (_) {
                          setSheetState(() => selectedTag = tag);
                        },
                        selectedColor: tokens.blueSoft,
                        backgroundColor: tokens.chip,
                        labelStyle: TextStyle(
                          color: isSel ? tokens.blue : tokens.ink,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dirección (calle y número / dpto)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: districtCtrl,
                  decoration: InputDecoration(
                    labelText: 'Distrito (ej: Miraflores, San Isidro)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(
                    labelText: 'Referencia (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (addressCtrl.text.trim().isEmpty) return;
                      final newAddr = Address(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        tag: selectedTag,
                        line: addressCtrl.text.trim(),
                        district: districtCtrl.text.trim(),
                        reference: refCtrl.text.trim(),
                      );
                      context.read<AddressCubit>().addAddress(newAddr);
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Guardar dirección',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCoverageSheet(BuildContext context, String district) {
    final tokens = context.tokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DCE5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // .zoneart
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 150,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    .6063, .3576, .0361, 0, 0, //
                    .1063, .8576, .0361, 0, 0,
                    .1063, .3576, .5361, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: IllustratedMap(
                          showExpandButton: false,
                          showRoute: false,
                          showMarker: false,
                          opacity: .7,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: tokens.bad,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33E0412F),
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const AppSvgIcon('x',
                              size: 22, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aún no llegamos a $district',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Hoy entregamos en Miraflores, San Isidro, Barranco, Surco, San Borja, Lince y alrededores. Estamos creciendo cada mes.',
              style: TextStyle(fontSize: 14.5, height: 1.35, color: tokens.ink2),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                AppToast.show(context,
                    'Listo. Te escribimos apenas lleguemos a tu zona.');
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: tokens.blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Avísame cuando lleguemos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.border, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Usar otra dirección',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (context.mounted) {
        context.read<AddressCubit>().dismissCoverageWarning();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final top = MediaQuery.of(context).padding.top;

    return BlocConsumer<AddressCubit, AddressState>(
      listenWhen: (a, b) =>
          !a.hasCoverageWarning && b.hasCoverageWarning,
      listener: (context, state) =>
          _showCoverageSheet(context, state.coverageWarningDistrict ?? 'tu zona'),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // .lmapw: 520 px de mapa
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 520,
                child: IllustratedMap(
                  showExpandButton: false,
                  showRoute: false,
                  showMarker: false,
                  mapChild: GoogleMapPreview(zoom: 16),
                ),
              ),
              // .top2.clear: volver
              Positioned(
                top: (top - 4) < 58 ? 58 : top - 4,
                left: 22,
                child: GestureDetector(
                  onTap: () => context.canPop() ? context.pop() : context.go('/login'),
                  child: Semantics(
                    button: true,
                    label: 'Volver',
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.border),
                      ),
                      alignment: Alignment.center,
                      child: AppSvgIcon('arrowl', size: 21, color: tokens.ink),
                    ),
                  ),
                ),
              ),

              // .locsheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4D0A1E5A),
                        blurRadius: 30,
                        spreadRadius: -18,
                        offset: Offset(0, -14),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8DCE5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Text(
                          '¿Dónde te entregamos?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.44,
                            color: tokens.ink,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Elige una dirección guardada o usa tu ubicación.',
                          style: TextStyle(
                              fontSize: 14.5, height: 1.35, color: tokens.ink2),
                        ),
                      ),
                      // .lbtn
                      _AddrTile(
                        top: 18,
                        icon: 'locate',
                        title: 'Usar mi ubicación actual',
                        subtitle: 'Av. José Pardo 450, Miraflores',
                        soft: true,
                        onTap: () {
                          context
                              .read<AddressCubit>()
                              .selectAddress(state.addresses.first);
                          AppToast.show(context, 'Te ubicamos en Miraflores.');
                        },
                      ),
                      for (final a in state.addresses)
                        _AddrTile(
                          top: 10,
                          icon: a.tag == 'Casa' ? 'home' : 'brief',
                          title: a.tag,
                          subtitle: '${a.line}, ${a.district}',
                          selected: state.selectedAddress.id == a.id,
                          onTap: () =>
                              context.read<AddressCubit>().selectAddress(a),
                        ),
                      // .addnew
                      GestureDetector(
                        onTap: () => _showAddAddressSheet(context),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
                          child: Row(
                            children: [
                              AppSvgIcon('plus', size: 18, color: tokens.blue),
                              const SizedBox(width: 6),
                              Text(
                                'Agregar dirección',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: tokens.blue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Entregar aquí',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddrTile extends StatelessWidget {
  const _AddrTile({
    required this.top,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.soft = false,
    this.selected = false,
  });

  final double top;
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool soft;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: soft ? tokens.blueSoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundDecoration: soft
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? tokens.blue : tokens.line,
                    width: selected ? 1.5 : 1,
                  ),
                ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: soft ? tokens.blue : tokens.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AppSvgIcon(icon,
                    size: 20, color: soft ? Colors.white : tokens.blue),
              ),
              const SizedBox(width: 12),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: tokens.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                AppSvgIcon('checkc', size: 22, color: tokens.blue),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pin azul que flota 8 px arriba y abajo (1.6 s).
class _FloatingPin extends StatefulWidget {
  const _FloatingPin();

  @override
  State<_FloatingPin> createState() => _FloatingPinState();
}

class _FloatingPinState extends State<_FloatingPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
        final dy = -8 * (1 - (2 * (_c.value - .5)).abs() * 1.0);
        final up = -8 * math.sin(_c.value * math.pi);
        return SizedBox(
          width: 44,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 14,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0x400A1E5A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, up + 0 * dy),
                child: _PinIcon(color: tokens.blue),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PinIcon extends StatelessWidget {
  const _PinIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(44, 44), painter: _PinPainter(color));
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);
    // M12 21.5 s-7-6-7-11.5 a7 7 0 0 1 14 0 c0 5.5-7 11.5-7 11.5z
    final path = Path()
      ..moveTo(12, 21.5)
      ..cubicTo(12, 21.5, 5, 15.5, 5, 10)
      ..arcToPoint(const Offset(19, 10),
          radius: const Radius.circular(7), clockwise: true)
      ..cubicTo(19, 15.5, 12, 21.5, 12, 21.5)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(const Offset(12, 10), 2.6, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}
