import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canasta/blocs/cart/cart_bloc.dart';
import 'package:canasta/blocs/cart/cart_event.dart';
import 'package:canasta/blocs/cart/cart_state.dart';
import 'package:canasta/data/catalog_data.dart';
import 'package:canasta/domain/models/cart_item.dart';

void main() {
  group('CartBloc Business Logic Tests', () {
    final banana = CatalogData.getProductById('banana')!; // 4.90 per kg
    final avocado = CatalogData.getProductById('avocado')!; // 3.80 per unit
    final detergent = CatalogData.getProductById('detergent')!; // 19.90 per unit

    test('initial state has empty or default items', () {
      final bloc = CartBloc(initialItems: []);
      expect(bloc.state.lines, isEmpty);
      expect(bloc.state.subtotal, 0.0);
      expect(bloc.state.fee, 0.0);
      expect(bloc.state.missingForFree, 80.00);
      bloc.close();
    });

    blocTest<CartBloc, CartState>(
      'adds item and updates subtotal and units correctly',
      build: () => CartBloc(initialItems: []),
      act: (bloc) {
        bloc.add(CartItemAdded(avocado, quantity: 2));
      },
      expect: () => [
        predicate<CartState>((state) {
          return state.lines.length == 1 &&
              state.lines.first.product.id == 'avocado' &&
              state.lines.first.quantity == 2.0 &&
              (state.subtotal - 7.60).abs() < 0.01 &&
              state.units == 2;
        }),
      ],
    );

    blocTest<CartBloc, CartState>(
      'free delivery applies when subtotal after discount >= 80 soles',
      build: () => CartBloc(initialItems: []),
      act: (bloc) {
        // 5 detergents @ 19.90 = 99.50
        bloc.add(CartItemAdded(detergent, quantity: 5));
      },
      verify: (bloc) {
        expect(bloc.state.subtotal, 99.50);
        expect(bloc.state.fee, 0.0);
        expect(bloc.state.missingForFree, 0.0);
      },
    );

    blocTest<CartBloc, CartState>(
      'delivery fee is 4.90 when subtotal < 80 soles',
      build: () => CartBloc(initialItems: []),
      act: (bloc) {
        // 1 detergent @ 19.90
        bloc.add(CartItemAdded(detergent, quantity: 1));
      },
      verify: (bloc) {
        expect(bloc.state.subtotal, 19.90);
        expect(bloc.state.fee, 4.90);
        expect((bloc.state.missingForFree - 60.10).abs() < 0.01, isTrue);
        expect((bloc.state.total - (19.90 + 4.90)).abs() < 0.01, isTrue);
      },
    );

    blocTest<CartBloc, CartState>(
      'coupon discount caps at S/ 15.00 maximum',
      build: () => CartBloc(initialItems: []),
      act: (bloc) {
        // Subtotal: 10 * 19.90 = 199.00
        // Coupon 20% would be 39.80, but must be capped at 15.00
        bloc.add(CartItemAdded(detergent, quantity: 10));
        bloc.add(const CartCouponApplied('HOLA20'));
      },
      verify: (bloc) {
        expect(bloc.state.subtotal, 199.00);
        expect(bloc.state.discount, 15.00);
        expect((bloc.state.total - (199.00 - 15.00)).abs() < 0.01, isTrue);
      },
    );

    blocTest<CartBloc, CartState>(
      'removing item sets undoItem and allows undo',
      build: () => CartBloc(initialItems: [
        CartItem(product: banana, quantity: 1.0),
      ]),
      act: (bloc) {
        bloc.add(CartItemRemoved(banana.id));
        bloc.add(const CartUndoRemove());
      },
      expect: () => [
        predicate<CartState>((state) =>
            state.lines.isEmpty && state.undoItem?.product.id == 'banana'),
        predicate<CartState>((state) =>
            state.lines.length == 1 &&
            state.lines.first.product.id == 'banana' &&
            state.undoItem == null),
      ],
    );
  });
}
