import 'package:equatable/equatable.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartItemAdded extends CartEvent {
  const CartItemAdded(this.product, {this.quantity = 1.0});

  final Product product;
  final double quantity;

  @override
  List<Object?> get props => [product, quantity];
}

class CartItemQtyChanged extends CartEvent {
  const CartItemQtyChanged(this.productId, this.quantity);

  final String productId;
  final double quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class CartUndoRemove extends CartEvent {
  const CartUndoRemove();
}

class CartMultipleRemoved extends CartEvent {
  const CartMultipleRemoved(this.productIds);

  final List<String> productIds;

  @override
  List<Object?> get props => [productIds];
}

class CartCouponApplied extends CartEvent {
  const CartCouponApplied(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class CartCouponRemoved extends CartEvent {
  const CartCouponRemoved();
}

class CartCouponScratched extends CartEvent {
  const CartCouponScratched();
}

class CartReordered extends CartEvent {
  const CartReordered(this.items);

  final List<CartItem> items;

  @override
  List<Object?> get props => [items];
}

class CartCleared extends CartEvent {
  const CartCleared();
}
