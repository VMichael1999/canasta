import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/search/search_cubit.dart';
import '../../core/assets.dart';
import '../../core/money.dart';
import '../../core/tokens.dart';
import '../../data/catalog_data.dart';
import '../../shared/app_svg_icon.dart';
import '../../shared/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.onAddProduct});

  final void Function(GlobalKey key, String productId)? onAddProduct;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: tokens.chip,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                AppSvgIcon('search', size: 18, color: tokens.ink2),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Busca palta, leche, pan…',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: tokens.ink3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    onChanged: (val) {
                      context.read<SearchCubit>().search(val);
                    },
                    onSubmitted: (val) {
                      context.read<SearchCubit>().submitQuery(val);
                    },
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      context.read<SearchCubit>().clearQuery();
                    },
                    child: Icon(Icons.close_rounded,
                        size: 18, color: tokens.ink2),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            final query = state.query;

            // If empty search, show Recent & Most searched
            if (query.isEmpty) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recientes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Búsquedas recientes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        if (state.recent.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              context.read<SearchCubit>().clearRecent();
                            },
                            child: Text(
                              'Borrar',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: tokens.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (state.recent.isEmpty)
                      Text(
                        'Aquí verás lo que busques.',
                        style: TextStyle(fontSize: 14, color: tokens.ink2),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.recent.map((term) {
                          return ActionChip(
                            avatar: Icon(Icons.history,
                                size: 16, color: tokens.ink2),
                            label: Text(term),
                            backgroundColor: tokens.chip,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(19),
                              side: BorderSide.none,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: tokens.ink,
                            ),
                            onPressed: () {
                              _controller.text = term;
                              context.read<SearchCubit>().search(term);
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 28),

                    // Lo más buscado
                    Text(
                      'Lo más buscado',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...['banana', 'avocado', 'milk', 'eggs', 'bread'].asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final p = CatalogData.getProductById(entry.value)!;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.ink3,
                                ),
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tokens.chip,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                CaAssets.product(p.id),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                        subtitle: Text(
                          '${p.isKg ? '1 kg' : p.unit} · ${formatPen(p.price)}',
                          style: TextStyle(fontSize: 13, color: tokens.ink2),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: tokens.ink3),
                        onTap: () {
                          context.push('/product/${p.id}');
                        },
                      );
                    }),
                  ],
                ),
              );
            }

            // Results grid or Empty state
            if (state.results.isEmpty) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 40, 22, 110),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.chip,
                        ),
                        alignment: Alignment.center,
                        child: AppSvgIcon('search', size: 28, color: tokens.ink3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No encontramos «$query»',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Revisa cómo se escribe o prueba con algo parecido.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: tokens.ink2),
                    ),
                    const SizedBox(height: 32),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quizás te sirva',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 230,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: CatalogData.popularIds.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final id = CatalogData.popularIds[index];
                          final p = CatalogData.getProductById(id)!;
                          return SizedBox(
                            width: 150,
                            child: ProductCard(
                              product: p,
                              onTap: () => context.push('/product/${p.id}'),
                              onAddWithGlobalKey: (key, prod) {
                                widget.onAddProduct?.call(key, prod.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 110),
              itemCount: state.results.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 230,
              ),
              itemBuilder: (context, index) {
                final p = state.results[index];
                return ProductCard(
                  product: p,
                  onTap: () => context.push('/product/${p.id}'),
                  onAddWithGlobalKey: (key, prod) {
                    widget.onAddProduct?.call(key, prod.id);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
