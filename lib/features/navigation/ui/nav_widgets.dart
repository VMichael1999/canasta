import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/tokens.dart';
import '../../../shared/app_svg_icon.dart';
import '../domain/turn_instruction.dart';

IconData _icon(TurnType t) => switch (t) {
      TurnType.left => Icons.turn_left_rounded,
      TurnType.right => Icons.turn_right_rounded,
      TurnType.straight => Icons.straight_rounded,
      TurnType.destination => Icons.flag_rounded,
    };

class NavBanner extends StatelessWidget {
  const NavBanner({super.key, required this.instruction, this.next, this.road});

  final TurnInstruction instruction;
  final TurnInstruction? next;
  final String? road;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.navy,
      borderRadius: BorderRadius.circular(22),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (road != null)
              Text(road!, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5)),
            Row(
              children: [
                Icon(_icon(instruction.type), color: Colors.white, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(instruction.distanceLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                      Text(instruction.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14.5)),
                    ],
                  ),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(_icon(next!.type), color: const Color(0xB3FFFFFF), size: 18),
                const SizedBox(width: 6),
                Text('Luego ${next!.text.toLowerCase()}',
                    style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class ArrivalBanner extends StatelessWidget {
  const ArrivalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.green,
      borderRadius: BorderRadius.circular(22),
      elevation: 6,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Text('¡Llegaste a tu destino!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }
}

class MapGlassButton extends StatelessWidget {
  const MapGlassButton({super.key, required this.label, required this.onTap, this.icon});
  final String label;
  final String? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 44,
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            color: Colors.white.withValues(alpha: .92),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                AppSvgIcon(icon!, size: 18, color: context.tokens.blue),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F1324))),
            ]),
          ),
        ),
      ),
    );
  }
}

class NavBottomCard extends StatelessWidget {
  const NavBottomCard({
    super.key,
    required this.speed,
    required this.eta,
    required this.remaining,
    required this.arrival,
    required this.progress,
    required this.onClose,
  });

  final int speed, eta;
  final double remaining, progress;
  final DateTime arrival;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final h = arrival.hour % 12 == 0 ? 12 : arrival.hour % 12;
    final hm = '$h:${arrival.minute.toString().padLeft(2, '0')} ${arrival.hour >= 12 ? 'p. m.' : 'a. m.'}';
    return Material(
      color: Colors.white,
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 14, 22, 18 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: t.bad, width: 4),
                ),
                alignment: Alignment.center,
                child: Text('$speed',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$eta min',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: t.green)),
                  Text('${roundDistance(remaining)} · llegada $hm',
                      style: TextStyle(fontSize: 13, color: t.ink2)),
                ]),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: t.badSoft),
                  alignment: Alignment.center,
                  child: Icon(Icons.close_rounded, color: t.bad),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: t.chip,
                color: t.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArrivalSheet extends StatelessWidget {
  const ArrivalSheet({super.key, required this.distance, required this.onContinue, required this.onExit});
  final double distance;
  final VoidCallback onContinue, onExit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: Colors.white,
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 18, 22, 18 + MediaQuery.of(context).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Recorriste ${roundDistance(distance)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SlideToConfirm(label: 'Desliza: pedido recibido', onConfirmed: onContinue),
          TextButton(onPressed: onExit, child: Text('Salir de la navegación', style: TextStyle(color: t.ink2))),
        ]),
      ),
    );
  }
}

class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({super.key, required this.label, required this.onConfirmed});
  final String label;
  final VoidCallback onConfirmed;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _x = 0;
  bool _drag = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return LayoutBuilder(builder: (context, c) {
      final max = c.maxWidth - 56;
      return Container(
        height: 56,
        decoration: BoxDecoration(color: const Color(0xFF121A33), borderRadius: BorderRadius.circular(28)),
        child: Stack(children: [
          Center(
            child: Text('${widget.label}  ›››',
                style: const TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w600)),
          ),
          AnimatedPositioned(
            duration: _drag ? Duration.zero : const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            left: _x,
            child: GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _drag = true),
              onHorizontalDragUpdate: (d) => setState(() => _x = (_x + d.delta.dx).clamp(0.0, max)),
              onHorizontalDragEnd: (_) {
                if (_x > max * .85) {
                  HapticFeedback.mediumImpact();
                  widget.onConfirmed();
                }
                setState(() {
                  _drag = false;
                  _x = 0;
                });
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: t.blue, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
        ]),
      );
    });
  }
}
