import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/initial_data.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  FavoritesCubit() : super(InitialData.initialFavorites);

  void toggle(String productId) {
    final updated = Set<String>.from(state);
    if (updated.contains(productId)) {
      updated.remove(productId);
    } else {
      updated.add(productId);
    }
    emit(updated);
  }

  bool isFavorite(String productId) => state.contains(productId);
}
