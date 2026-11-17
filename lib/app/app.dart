import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../blocs/address/address_cubit.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/catalog/catalog_cubit.dart';
import '../blocs/checkout/checkout_bloc.dart';
import '../blocs/favorites/favorites_cubit.dart';
import '../blocs/live_order/live_order_bloc.dart';
import '../blocs/orders/orders_cubit.dart';
import '../blocs/search/search_cubit.dart';
import '../blocs/session/session_bloc.dart';
import '../core/theme.dart';
import '../shared/cart_bubble_scope.dart';
import '../shared/floating_cart_bubble.dart';
import 'router.dart';

final GlobalKey<FloatingCartBubbleState> _bubbleKey =
    GlobalKey<FloatingCartBubbleState>();

class CanastaApp extends StatelessWidget {
  const CanastaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>(
          create: (_) => SessionBloc(),
        ),
        BlocProvider<AddressCubit>(
          create: (_) => AddressCubit(),
        ),
        BlocProvider<CatalogCubit>(
          create: (_) => CatalogCubit(),
        ),
        BlocProvider<CartBloc>(
          create: (_) => CartBloc(),
        ),
        BlocProvider<FavoritesCubit>(
          create: (_) => FavoritesCubit(),
        ),
        BlocProvider<OrdersCubit>(
          create: (_) => OrdersCubit(),
        ),
        BlocProvider<SearchCubit>(
          create: (_) => SearchCubit(),
        ),
        BlocProvider<CheckoutBloc>(
          create: (_) => CheckoutBloc(),
        ),
        BlocProvider<LiveOrderBloc>(
          create: (_) => LiveOrderBloc(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Canasta',
        debugShowCheckedModeBanner: false,
        theme: CaTheme.light,
        routerConfig: canastaRouter,
        builder: (context, child) => CartBubbleScope(
          bubbleKey: _bubbleKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              FloatingCartBubble(key: _bubbleKey, router: canastaRouter),
            ],
          ),
        ),
        locale: const Locale('es', 'PE'),
        supportedLocales: const [
          Locale('es', 'PE'),
          Locale('es', '419'),
          Locale('es', ''),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
