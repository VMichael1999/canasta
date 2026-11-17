import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/catalog_data.dart';
import '../../data/initial_data.dart';
import '../../domain/models/product.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.recent = const [],
  });

  final String query;
  final List<Product> results;
  final List<String> recent;

  @override
  List<Object?> get props => [query, results, recent];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit()
      : super(SearchState(recent: InitialData.recentSearches));

  static String normalize(String input) {
    var s = input.toLowerCase();
    const map = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    map.forEach((key, value) {
      s = s.replaceAll(key, value);
    });
    return s;
  }

  void search(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      emit(SearchState(query: '', results: const [], recent: state.recent));
      return;
    }

    final normQ = normalize(cleanQuery);
    final results = CatalogData.products.where((p) {
      final normName = normalize(p.name);
      final normCat = normalize(CatalogData.getCategoryById(p.cat)?.name ?? '');
      final normSub = normalize(p.sub);
      return normName.contains(normQ) ||
          normCat.contains(normQ) ||
          normSub.contains(normQ);
    }).toList();

    emit(SearchState(
      query: cleanQuery,
      results: results,
      recent: state.recent,
    ));
  }

  void submitQuery(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final updatedRecent = [
      clean,
      ...state.recent.where((r) => r.toLowerCase() != clean.toLowerCase()),
    ].take(5).toList();

    emit(SearchState(
      query: clean,
      results: state.results,
      recent: updatedRecent,
    ));
  }

  void clearRecent() {
    emit(SearchState(
      query: state.query,
      results: state.results,
      recent: const [],
    ));
  }

  void clearQuery() {
    emit(SearchState(
      query: '',
      results: const [],
      recent: state.recent,
    ));
  }
}
