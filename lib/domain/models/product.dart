import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.cat,
    required this.sub,
    required this.unit,
    required this.price,
    this.oldPrice = 0.0,
    this.fresh = false,
    this.rating = 5.0,
    this.reviewsCount = 0,
    this.isKg = false,
    this.stock = 99,
  });

  final String id;
  final String name;
  final String cat;
  final String sub;
  final String unit;
  final double price;
  final double oldPrice;
  final bool fresh;
  final double rating;
  final int reviewsCount;
  final bool isKg;
  final int stock;

  bool get inStock => stock > 0;
  bool get hasDiscount => oldPrice > price;
  int get discountPct => hasDiscount ? (((1 - price / oldPrice) * 100).round()) : 0;
  double get step => isKg ? 0.25 : 1.0;

  @override
  List<Object?> get props => [
        id,
        name,
        cat,
        sub,
        unit,
        price,
        oldPrice,
        fresh,
        rating,
        reviewsCount,
        isKg,
        stock,
      ];
}
