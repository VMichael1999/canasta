import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/initial_data.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/coupon.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({List<CartItem>? initialItems})
      : super(CartState(lines: initialItems ?? InitialData.initialCart)) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemQtyChanged>(_onQtyChanged);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartUndoRemove>(_onUndoRemove);
    on<CartMultipleRemoved>(_onMultipleRemoved);
    on<CartCouponApplied>(_onCouponApplied);
    on<CartCouponRemoved>(_onCouponRemoved);
    on<CartCouponScratched>(_onCouponScratched);
    on<CartReordered>(_onReordered);
    on<CartCleared>(_onCleared);
  }

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final current = List<CartItem>.from(state.lines);
    final idx = current.indexWhere((l) => l.product.id == event.product.id);

    if (idx >= 0) {
      final updatedQty = current[idx].quantity + event.quantity;
      current[idx] = current[idx].copyWith(quantity: updatedQty);
    } else {
      current.insert(
        0,
        CartItem(product: event.product, quantity: event.quantity),
      );
    }

    emit(state.copyWith(lines: current, lastAddedId: event.product.id));
  }

  void _onQtyChanged(CartItemQtyChanged event, Emitter<CartState> emit) {
    final current = List<CartItem>.from(state.lines);
    final idx = current.indexWhere((l) => l.product.id == event.productId);

    if (idx >= 0) {
      if (event.quantity <= 0.001) {
        final removed = current.removeAt(idx);
        emit(state.copyWith(lines: current, undoItem: removed));
      } else {
        current[idx] = current[idx].copyWith(quantity: event.quantity);
        emit(state.copyWith(lines: current));
      }
    }
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final current = List<CartItem>.from(state.lines);
    final idx = current.indexWhere((l) => l.product.id == event.productId);
    if (idx >= 0) {
      final removed = current.removeAt(idx);
      emit(state.copyWith(lines: current, undoItem: removed));
    }
  }

  void _onUndoRemove(CartUndoRemove event, Emitter<CartState> emit) {
    if (state.undoItem != null) {
      final current = [state.undoItem!, ...state.lines];
      emit(state.copyWith(lines: current, undoItem: null));
    } else if (state.undoList != null && state.undoList!.isNotEmpty) {
      final current = [...state.undoList!, ...state.lines];
      emit(state.copyWith(lines: current, undoList: null));
    }
  }

  void _onMultipleRemoved(CartMultipleRemoved event, Emitter<CartState> emit) {
    final toRemove = event.productIds.toSet();
    final removed = state.lines.where((l) => toRemove.contains(l.product.id)).toList();
    final remaining = state.lines.where((l) => !toRemove.contains(l.product.id)).toList();
    emit(state.copyWith(lines: remaining, undoList: removed));
  }

  void _onCouponApplied(CartCouponApplied event, Emitter<CartState> emit) {
    final codeClean = event.code.trim().toUpperCase();
    final match = InitialData.availableCoupons.firstWhere(
      (c) => c.code == codeClean,
      orElse: () => const Coupon(code: '', pct: 0),
    );

    if (match.code.isNotEmpty) {
      emit(state.copyWith(coupon: match));
    }
  }

  void _onCouponRemoved(CartCouponRemoved event, Emitter<CartState> emit) {
    emit(state.copyWith(clearCoupon: true));
  }

  void _onCouponScratched(CartCouponScratched event, Emitter<CartState> emit) {
    emit(state.copyWith(scratched: true));
  }

  void _onReordered(CartReordered event, Emitter<CartState> emit) {
    final current = List<CartItem>.from(state.lines);
    for (final item in event.items) {
      final idx = current.indexWhere((l) => l.product.id == item.product.id);
      if (idx >= 0) {
        current[idx] = current[idx].copyWith(quantity: current[idx].quantity + item.quantity);
      } else {
        current.add(item);
      }
    }
    emit(state.copyWith(lines: current));
  }

  void _onCleared(CartCleared event, Emitter<CartState> emit) {
    emit(state.copyWith(lines: const []));
  }
}
