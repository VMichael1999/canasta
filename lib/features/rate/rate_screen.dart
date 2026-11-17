import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/orders/orders_cubit.dart';
import '../../core/assets.dart';
import '../../core/haptics.dart';
import '../../core/tokens.dart';
import '../../shared/app_toast.dart';

class RateScreen extends StatefulWidget {
  const RateScreen({super.key});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int _stars = 5;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentCtrl = TextEditingController();

  final List<String> _goodTags = [
    'Llegó a tiempo',
    'Productos frescos',
    'Buen trato',
    'Todo completo',
  ];

  final List<String> _badTags = [
    'Llegó tarde',
    'Producto en mal estado',
    'Faltó algo',
    'Trato poco amable',
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
        return '';
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
          'CA-87511',
          _stars,
          _selectedTags.toList(),
          _commentCtrl.text.trim(),
        );

    if (_stars < 4) {
      AppToast.show(
        context,
        'Lamentamos tu mala experiencia.',
        actionLabel: 'Pedir ayuda',
        onAction: () => context.push('/help'),
      );
    } else {
      AppToast.show(context, '¡Gracias por calificar!');
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentTags = _stars >= 4 ? _goodTags : _badTags;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Califica tu pedido',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Courier avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Image.asset(
                  CaAssets.rider,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Carlos Huamán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
              Text(
                'Tu repartidor en este pedido',
                style: TextStyle(fontSize: 13, color: tokens.ink2),
              ),
              const SizedBox(height: 24),

              // 5 Stars
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
                        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 42,
                        color: tokens.sun,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),

              // Reaction word
              Text(
                _reactionWord,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _stars >= 4 ? tokens.green : tokens.bad,
                ),
              ),
              const SizedBox(height: 24),

              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: currentTags.map((tag) {
                  final isSel = _selectedTags.contains(tag);
                  return ChoiceChip(
                    label: Text(tag),
                    selected: isSel,
                    onSelected: (_) {
                      CaHaptics.selectionClick();
                      setState(() {
                        if (isSel) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    selectedColor: tokens.blueSoft,
                    backgroundColor: tokens.chip,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? tokens.blue : tokens.ink,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Comment TextField
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Cuéntanos más detalles (opcional)…',
                  hintStyle: TextStyle(fontSize: 14, color: tokens.ink3),
                  filled: true,
                  fillColor: tokens.chip,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Enviar calificación',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
