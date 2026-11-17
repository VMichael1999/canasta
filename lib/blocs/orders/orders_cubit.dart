import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/initial_data.dart';
import '../../domain/models/order.dart';

class OrdersState extends Equatable {
  const OrdersState({
    required this.orders,
    this.selectedSegment = 'now', // 'now' or 'past'
  });

  final List<OrderModel> orders;
  final String selectedSegment;

  List<OrderModel> get liveOrders =>
      orders.where((o) => o.status != OrderStatus.delivered).toList();

  List<OrderModel> get pastOrders =>
      orders.where((o) => o.status == OrderStatus.delivered).toList();

  List<OrderModel> get currentSegmentOrders =>
      selectedSegment == 'now' ? liveOrders : pastOrders;

  OrderModel? get activeLiveOrder {
    try {
      return orders.firstWhere((o) => o.status != OrderStatus.delivered);
    } catch (_) {
      return null;
    }
  }

  OrdersState copyWith({
    List<OrderModel>? orders,
    String? selectedSegment,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      selectedSegment: selectedSegment ?? this.selectedSegment,
    );
  }

  @override
  List<Object?> get props => [orders, selectedSegment];
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit()
      : super(OrdersState(orders: InitialData.initialOrders));

  void setSegment(String segment) {
    emit(state.copyWith(selectedSegment: segment));
  }

  void addOrder(OrderModel order) {
    final updated = [order, ...state.orders];
    emit(state.copyWith(orders: updated, selectedSegment: 'now'));
  }

  void rateOrder(String orderId, int stars, List<String> tags, String comment) {
    final updated = state.orders.map((o) {
      if (o.id == orderId) {
        // Al calificar, el pedido queda completado (pasa a «Anteriores»).
        return o.copyWith(
          status: OrderStatus.delivered,
          rated: true,
          ratingStars: stars,
          ratingTags: tags,
          ratingComment: comment,
        );
      }
      return o;
    }).toList();
    emit(state.copyWith(orders: updated));
  }
}
