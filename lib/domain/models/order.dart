import 'package:equatable/equatable.dart';
import 'cart_item.dart';
import 'courier.dart';
import 'slot.dart';

enum OrderStatus {
  placed,
  confirmed,
  onTheWay,
  delivered,
}

class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.fee,
    required this.tip,
    required this.discount,
    required this.total,
    required this.createdAt,
    required this.status,
    required this.addressLine,
    required this.paymentMethod,
    this.slot,
    this.etaMinutes = 11,
    this.courier = Courier.defaultCourier,
    this.rated = false,
    this.ratingStars = 0,
    this.ratingTags = const [],
    this.ratingComment = '',
  });

  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double fee;
  final double tip;
  final double discount;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;
  final String addressLine;
  final String paymentMethod;
  final DeliverySlot? slot;
  final int etaMinutes;
  final Courier courier;
  final bool rated;
  final int ratingStars;
  final List<String> ratingTags;
  final String ratingComment;

  int get stage {
    switch (status) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.onTheWay:
        return 2;
      case OrderStatus.delivered:
        return 3;
    }
  }

  OrderModel copyWith({
    String? id,
    List<CartItem>? items,
    double? subtotal,
    double? fee,
    double? tip,
    double? discount,
    double? total,
    DateTime? createdAt,
    OrderStatus? status,
    String? addressLine,
    String? paymentMethod,
    DeliverySlot? slot,
    int? etaMinutes,
    Courier? courier,
    bool? rated,
    int? ratingStars,
    List<String>? ratingTags,
    String? ratingComment,
  }) {
    return OrderModel(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      fee: fee ?? this.fee,
      tip: tip ?? this.tip,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      addressLine: addressLine ?? this.addressLine,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      slot: slot ?? this.slot,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      courier: courier ?? this.courier,
      rated: rated ?? this.rated,
      ratingStars: ratingStars ?? this.ratingStars,
      ratingTags: ratingTags ?? this.ratingTags,
      ratingComment: ratingComment ?? this.ratingComment,
    );
  }

  @override
  List<Object?> get props => [
        id,
        items,
        subtotal,
        fee,
        tip,
        discount,
        total,
        createdAt,
        status,
        addressLine,
        paymentMethod,
        slot,
        etaMinutes,
        courier,
        rated,
        ratingStars,
        ratingTags,
        ratingComment,
      ];
}
