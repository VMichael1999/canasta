import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/deals/deals_screen.dart';
import '../features/help/help_screen.dart';
import '../features/home/home_screen.dart';
import '../features/location/location_screen.dart';
import '../features/navigation/ui/navigation_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/order_done/order_done_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/product_detail/product_detail_screen.dart';
import '../features/product_list/product_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/rate/rate_screen.dart';
import '../features/search/search_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/tracking/tracking_screen.dart';
import '../shared/cart_bubble_scope.dart';
import '../shared/floating_cart_bubble.dart' show ModalWatcher;
import 'navigation.dart';
import 'scaffold_with_nav_bar.dart';

final GoRouter canastaRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: [ModalWatcher()],
  // `--dart-define=INITIAL_ROUTE=/cart` abre directamente otra pantalla (útil para pruebas)
  initialLocation:
      const String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/splash'),
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/location',
      builder: (context, state) => const LocationScreen(),
    ),

    // StatefulShellRoute with 4 tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeScreen(
                onAddProduct: (key, id) =>
                    CartBubbleScope.flyToBubble(context, key, id),
              ),
            ),
          ],
        ),
        // Tab 1: Categories
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cats',
              builder: (context, state) => const CategoriesScreen(),
            ),
            GoRoute(
              path: '/categories',
              redirect: (context, state) => '/cats',
            ),
          ],
        ),
        // Tab 2: Orders
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
            ),
          ],
        ),
        // Tab 3: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Top-level pushed screens with CartBubble overlay where specified
    GoRoute(
      path: '/list',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: const Duration(milliseconds: 120),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        child: ProductListScreen(
          onAddProduct: (key, id) =>
              CartBubbleScope.flyToBubble(context, key, id),
        ),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => SearchScreen(
        onAddProduct: (key, id) =>
            CartBubbleScope.flyToBubble(context, key, id),
      ),
    ),
    GoRoute(
      path: '/deals',
      builder: (context, state) => DealsScreen(
        onAddProduct: (key, id) =>
            CartBubbleScope.flyToBubble(context, key, id),
      ),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'avocado';
        return ProductDetailScreen(
          productId: id,
          onAddProduct: (key, pid) =>
              CartBubbleScope.flyToBubble(context, key, pid),
        );
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/order-done',
      builder: (context, state) => const OrderDoneScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingScreen(),
    ),
    GoRoute(
      path: '/navigation',
      builder: (context, state) => const NavigationScreen(),
    ),
    GoRoute(
      path: '/rate',
      builder: (context, state) => const RateScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpScreen(),
    ),
  ],
);
