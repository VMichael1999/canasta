import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/live_order/live_order_bloc.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/tokens.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/app_toast.dart';

class RateScreen extends StatefulWidget {
  const RateScreen({super.key});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int _stars = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentCtrl = TextEditingController();

  final List<String> _goodTags = [
    'Llegó a tiempo',
    'Productos frescos',
    'Bien empacado',
    'Repartidor amable',
    'Buen precio',
  ];

  final List<String> _badTags = [
    'Llegó tarde',
    'Producto en mal estado',
    'Faltó un producto',
    'Mal empacado',
    'Repartidor poco amable',
  ];

  String get _reactionWord {
    switch (_stars) {
      case 1:
        return 'Muy mala';
      case 2:
        return 'Mala';
      case 3:
        return 'Regular';
      case 4:
        return 'Buena';
      case 5:
        return '¡Excelente!';
      default:
        return 'Toca una estrella';
    }
  }

  void _onStarTapped(int star) {
    CaHaptics.selectionClick();
    setState(() {
      final wasGood = _stars >= 4;
      final isGood = star >= 4;
      if (wasGood != isGood) {
        _selectedTags.clear();
      }
      _stars = star;
    });
  }

  void _submit() {
    CaHaptics.mediumImpact();
    context.read<OrdersCubit>().rateOrder(
          context.read<LiveOrderBloc>().state.order.id,
          _stars,
          _selectedTags.toList(),
          _commentCtrl.text.trim(),
        );

    if (_stars < 4) {
      AppToast.show(
        context,
        'Gracias. Revisaremos lo que pasó.',
        actionLabel: 'Pedir ayuda',
        onAction: () => context.push('/help'),
      );
    } else {
      AppToast.show(context, '¡Gracias! Le pasamos tus estrellas a Carlos.');
    }

    context.read<OrdersCubit>().setSegment('past');
    context.go('/orders');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentTags = _stars >= 4 ? _goodTags : _badTags;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(
          top: (MediaQuery.of(context).padding.top - 6).clamp(0.0, 80.0),
        ),
        child: Column(
          children: [
            // Top Bar (.top3)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AppSvgIcon('x', size: 24, color: tokens.ink),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Califica tu pedido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink,
                        letterSpacing: -0.01 * 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
                child: Column(
                  children: [
                    // Header with Avatar
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.blueSoft,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          CaAssets.rider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '¿Cómo estuvo tu pedido?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CA-87654 · entregado por Carlos',
                      style: TextStyle(fontSize: 13.5, color: tokens.ink2),
                    ),
                    const SizedBox(height: 24),

                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNum = index + 1;
                        final isFilled = starNum <= _stars;

                        return GestureDetector(
                          onTap: () => _onStarTapped(starNum),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              isFilled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 44,
                              color: isFilled
                                  ? const Color(0xFFF59E0B)
                                  : tokens.ink3,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _reactionWord,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 26),

                    if (_stars > 0) ...[
                    // Tags
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _stars >= 4
                            ? '¿Qué te gustó?'
                            : '¿Qué podemos mejorar?',
                        style: TextStyle(
                          fontSize: 14,
                          color: tokens.ink2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            CaHaptics.selectionClick();
                            setState(() {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? tokens.blue : tokens.chip,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? Colors.white : tokens.ink,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Optional Comment
                    TextField(
                      controller: _commentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Cuéntanos más (opcional)',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: tokens.ink3,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: tokens.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: tokens.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: tokens.blue, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    ],
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _stars == 0 ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(0xFFB9C9F5),
                          disabledForegroundColor: Colors.white,
                          backgroundColor: tokens.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Enviar calificación',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
