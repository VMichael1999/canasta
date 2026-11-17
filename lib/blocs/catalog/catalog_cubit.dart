import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/catalog_data.dart';
import '../../domain/models/category.dart';
import '../../domain/models/product.dart';

enum SortOption {
  rec('rec', 'Recomendados'),
  priceAsc('price_asc', 'Menor precio'),
  priceDesc('price_desc', 'Mayor precio'),
  discDesc('disc_desc', 'Mayor descuento');

  const SortOption(this.key, this.label);
  final String key;
  final String label;
}

class CatalogState extends Equatable {
  const CatalogState({
    this.selectedCategoryId = 'fru',
    this.selectedSub = 'Todas',
    this.sortOption = SortOption.rec,
    this.isLoading = false,
  });

  final String selectedCategoryId;
  final String selectedSub;
  final SortOption sortOption;
  final bool isLoading;

  Category get selectedCategory =>
      CatalogData.getCategoryById(selectedCategoryId) ??
      CatalogData.categories.first;

  List<Product> get categoryProducts {
    var list = CatalogData.products.where((p) => p.cat == selectedCategoryId).toList();
    if (selectedSub != 'Todas' && selectedSub != 'Todos' && selectedSub != 'Todo') {
      list = list.where((p) => p.sub == selectedSub).toList();
    }

    switch (sortOption) {
      case SortOption.rec:
        // Keep catalog order
        break;
      case SortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.discDesc:
        list.sort((a, b) => b.discountPct.compareTo(a.discountPct));
        break;
    }
    return list;
  }

  CatalogState copyWith({
    String? selectedCategoryId,
    String? selectedSub,
    SortOption? sortOption,
    bool? isLoading,
  }) {
    return CatalogState(
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedSub: selectedSub ?? this.selectedSub,
      sortOption: sortOption ?? this.sortOption,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        selectedCategoryId,
        selectedSub,
        sortOption,
        isLoading,
      ];
}

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit() : super(const CatalogState());

  void selectCategory(String categoryId) {
    final cat = CatalogData.getCategoryById(categoryId);
    final firstSub = cat?.subs.first ?? 'Todas';
    emit(state.copyWith(
      selectedCategoryId: categoryId,
      selectedSub: firstSub,
    ));
  }

  void selectSubcategory(String sub) {
    emit(state.copyWith(isLoading: true));
    // simulate 250ms skeleton loading per prompt
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!isClosed) {
        emit(state.copyWith(selectedSub: sub, isLoading: false));
      }
    });
  }

  void setSortOption(SortOption option) {
    emit(state.copyWith(sortOption: option));
  }
}
