import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final double quantity;

  double get total => product.price * quantity;

  CartItem copyWith({
    Product? product,
    double? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}
