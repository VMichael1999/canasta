import 'dart:math';
import 'package:equatable/equatable.dart';
import '../../data/initial_data.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/coupon.dart';

class CartState extends Equatable {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.scratched = false,
    this.lastAddedId,
    this.undoItem,
    this.undoList,
  });

  final List<CartItem> lines;
  final Coupon? coupon;
  final bool scratched;
  final String? lastAddedId;
  final CartItem? undoItem;
  final List<CartItem>? undoList;

  double get subtotal =>
      lines.fold<double>(0.0, (sum, item) => sum + item.total);

  double get discount {
    if (coupon == null) return 0.0;
    return coupon!.calculateDiscount(subtotal);
  }

  double get fee =>
      (subtotal - discount >= InitialData.freeDeliveryThreshold || subtotal == 0)
          ? 0.0
          : InitialData.deliveryFee;

  double get total => max(0.0, subtotal - discount + fee);

  int get units => lines.fold<int>(
        0,
        (sum, item) => sum + (item.product.isKg ? 1 : item.quantity.toInt()),
      );

  double get missingForFree =>
      max(0.0, InitialData.freeDeliveryThreshold - (subtotal - discount));

  bool get hasFreeDelivery =>
      (subtotal - discount) >= InitialData.freeDeliveryThreshold && subtotal > 0;

  double get freeDeliveryProgress {
    if (subtotal == 0) return 0.0;
    final current = subtotal - discount;
    if (current >= InitialData.freeDeliveryThreshold) return 1.0;
    return (current / InitialData.freeDeliveryThreshold).clamp(0.0, 1.0);
  }

  double quantityOf(String productId) {
    try {
      final item = lines.firstWhere((l) => l.product.id == productId);
      return item.quantity;
    } catch (_) {
      return 0.0;
    }
  }

  CartState copyWith({
    List<CartItem>? lines,
    Coupon? coupon,
    bool clearCoupon = false,
    bool? scratched,
    String? lastAddedId,
    CartItem? undoItem,
    List<CartItem>? undoList,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
      scratched: scratched ?? this.scratched,
      lastAddedId: lastAddedId,
      undoItem: undoItem,
      undoList: undoList,
    );
  }

  @override
  List<Object?> get props => [
        lines,
        coupon,
        scratched,
        lastAddedId,
        undoItem,
        undoList,
      ];
}
