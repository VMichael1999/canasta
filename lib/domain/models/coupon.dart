import 'package:equatable/equatable.dart';

class Coupon extends Equatable {
  const Coupon({
    required this.code,
    required this.pct,
    this.maxDiscount = 15.0,
    this.description = '',
  });

  final String code;
  final int pct;
  final double maxDiscount;
  final String description;

  double calculateDiscount(double subtotal) {
    final raw = subtotal * pct / 100.0;
    return raw > maxDiscount ? maxDiscount : raw;
  }

  @override
  List<Object?> get props => [code, pct, maxDiscount, description];
}
