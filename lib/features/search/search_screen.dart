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
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (.top2)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.border),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon('arrowl', size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tokens.border),
                      ),
                      child: Row(
                        children: [
                          AppSvgIcon('search', size: 20, color: tokens.ink2),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: tokens.ink,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Busca palta, leche, pan…',
                                hintStyle: TextStyle(
                                  fontSize: 14.5,
                                  color: tokens.ink3,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {});
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
                                setState(() {});
                                context.read<SearchCubit>().clearQuery();
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tokens.chip,
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.close_rounded,
                                    size: 16, color: tokens.ink2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: tokens.line, height: 1),

            // Body
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  final query = state.query;

                  // Empty query: Recientes + Más buscados
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
                                  fontSize: 16,
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
                              style: TextStyle(
                                  fontSize: 13.5, color: tokens.ink2),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.recent.map((term) {
                                return GestureDetector(
                                  onTap: () {
                                    _controller.text = term;
                                    setState(() {});
                                    context.read<SearchCubit>().search(term);
                                  },
                                  child: Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: tokens.chip,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppSvgIcon('clock',
                                            size: 16, color: tokens.ink2),
                                        const SizedBox(width: 7),
                                        Text(
                                          term,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            color: tokens.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 26),

                          // Lo más buscado (.pop)
                          Text(
                            'Lo más buscado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...['banana', 'avocado', 'milk', 'eggs', 'bread']
                              .asMap()
                              .entries
                              .map((entry) {
                            final rank = entry.key + 1;
                            final p =
                                CatalogData.getProductById(entry.value)!;

                            return InkWell(
                              onTap: () {
                                _controller.text = p.name;
                                setState(() {});
                                context.read<SearchCubit>().search(p.name);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: tokens.line),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      child: Text(
                                        '$rank',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: tokens.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: tokens.soft,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: Image.asset(
                                        CaAssets.product(p.id),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: tokens.ink,
                                            ),
                                          ),
                                          Text(
                                            '${p.isKg ? '1 kg' : p.unit} · ${formatPen(p.price)}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: tokens.ink2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppSvgIcon('chev',
                                        size: 18, color: tokens.ink3),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }

                  // Non-empty query: Results or Empty state
                  final results = state.results;

                  if (results.isEmpty) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 40, 22, 110),
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.blueSoft,
                            ),
                            alignment: Alignment.center,
                            child: AppSvgIcon('search',
                                size: 36, color: tokens.blue),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No encontramos «$query»',
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
                            style: TextStyle(
                              fontSize: 14,
                              color: tokens.ink2,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Quizás te sirva
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
                            height: 236,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final p = CatalogData.getProductById(
                                    CatalogData.popularIds[index])!;
                                return SizedBox(
                                  width: 158,
                                  child: ProductCard(
                                    product: p,
                                    onTap: () =>
                                        context.push('/product/${p.id}'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                        child: Text(
                          '${results.length} resultado${results.length > 1 ? 's' : ''} para «$query»',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: tokens.ink2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 236,
                          ),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final p = results[index];
                            return ProductCard(
                              product: p,
                              onTap: () => context.push('/product/${p.id}'),
                              onAddWithGlobalKey: (key, prod) {
                                widget.onAddProduct?.call(key, prod.id);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
