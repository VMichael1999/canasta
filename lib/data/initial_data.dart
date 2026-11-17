import '../domain/models/address.dart';
import '../domain/models/cart_item.dart';
import '../domain/models/courier.dart';
import '../domain/models/coupon.dart';
import '../domain/models/order.dart';
import '../domain/models/user_profile.dart';
import 'catalog_data.dart';

class InitialData {
  static const double deliveryFee = 4.90;
  static const double freeDeliveryThreshold = 80.00;

  static const UserProfile user = UserProfile(
    name: 'Michael Dev',
    firstName: 'Michael',
    email: 'michaeldev@gmail.com',
    phone: '987 654 321',
  );

  static const List<Address> addresses = [
    Address(
      id: 'casa',
      tag: 'Casa',
      line: 'Av. José Pardo 450, dpto. 302',
      district: 'Miraflores',
      reference: 'Frente al parque',
    ),
    Address(
      id: 'trab',
      tag: 'Trabajo',
      line: 'Calle Las Begonias 755, piso 8',
      district: 'San Isidro',
      reference: 'Recepción',
    ),
  ];

  static const List<String> coveredDistricts = [
    'Miraflores',
    'San Isidro',
    'Barranco',
    'Surco',
    'San Borja',
    'Lince',
    'Jesús María',
    'Magdalena',
  ];

  static const List<String> outOfCoverageDistricts = [
    'Chorrillos',
    'La Molina',
    'Callao',
  ];

  static bool isDistrictCovered(String district) {
    return coveredDistricts.any(
      (d) => d.toLowerCase() == district.trim().toLowerCase(),
    );
  }

  static List<CartItem> get initialCart {
    return [
      CartItem(
        product: CatalogData.getProductById('banana')!,
        quantity: 1.0,
      ),
      CartItem(
        product: CatalogData.getProductById('milk')!,
        quantity: 1.0,
      ),
      CartItem(
        product: CatalogData.getProductById('bread')!,
        quantity: 1.0,
      ),
    ];
  }

  static Set<String> get initialFavorites => {'avocado', 'eggs'};

  static List<Coupon> get availableCoupons => const [
        Coupon(
          code: 'CANASTA10',
          pct: 10,
          description: '10 % de descuento en toda tu compra',
        ),
        Coupon(
          code: 'FRESCO15',
          pct: 15,
          description: '15 % de descuento en frutas y verduras',
        ),
        Coupon(
          code: 'HOLA20',
          pct: 20,
          description: '20 % de descuento de bienvenida',
        ),
      ];

  static List<String> get recentSearches => [
        'Palta',
        'Leche fresca',
        'Huevos de granja',
      ];

  static List<OrderModel> get initialOrders {
    // 8 items for the live order:
    // banana (1), milk (2), bread (1), eggs (1), tomato (1), avocado (3), cheese (1), juice (1)
    final liveItems = [
      CartItem(product: CatalogData.getProductById('banana')!, quantity: 1),
      CartItem(product: CatalogData.getProductById('milk')!, quantity: 2),
      CartItem(product: CatalogData.getProductById('bread')!, quantity: 1),
      CartItem(product: CatalogData.getProductById('eggs')!, quantity: 1),
      CartItem(product: CatalogData.getProductById('tomato')!, quantity: 1),
      CartItem(product: CatalogData.getProductById('avocado')!, quantity: 3),
      CartItem(product: CatalogData.getProductById('cheese')!, quantity: 1),
      CartItem(product: CatalogData.getProductById('juice')!, quantity: 1),
    ];

    final liveSubtotal = liveItems.fold<double>(0, (sum, i) => sum + i.total);
    final liveFee = liveSubtotal >= freeDeliveryThreshold ? 0.0 : deliveryFee;

    final pastItems1 = [
      CartItem(product: CatalogData.getProductById('avocado')!, quantity: 2),
      CartItem(product: CatalogData.getProductById('milk')!, quantity: 1),
      CartItem(product: CatalogData.getProductById('bread')!, quantity: 1),
      CartItem(product: CatalogData.getProductById('cookies')!, quantity: 1),
    ];
    final pastSub1 = pastItems1.fold<double>(0, (sum, i) => sum + i.total);

    final pastItems2 = [
      CartItem(product: CatalogData.getProductById('banana')!, quantity: 1.5),
      CartItem(product: CatalogData.getProductById('apple')!, quantity: 1),
      CartItem(product: CatalogData.getProductById('yogurt')!, quantity: 2),
      CartItem(product: CatalogData.getProductById('water')!, quantity: 2),
      CartItem(product: CatalogData.getProductById('detergent')!, quantity: 1),
    ];
    final pastSub2 = pastItems2.fold<double>(0, (sum, i) => sum + i.total);

    return [
      OrderModel(
        id: 'CA-87654',
        items: liveItems,
        subtotal: liveSubtotal,
        fee: liveFee,
        tip: 3.0,
        discount: 0.0,
        total: liveSubtotal + liveFee + 3.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 9)),
        status: OrderStatus.onTheWay,
        addressLine: 'Av. José Pardo 450, dpto. 302, Miraflores',
        paymentMethod: 'Yape',
        etaMinutes: 11,
        courier: Courier.defaultCourier,
        rated: false,
      ),
      OrderModel(
        id: 'CA-87511',
        items: pastItems1,
        subtotal: pastSub1,
        fee: pastSub1 >= freeDeliveryThreshold ? 0.0 : deliveryFee,
        tip: 3.0,
        discount: 0.0,
        total: pastSub1 + (pastSub1 >= freeDeliveryThreshold ? 0.0 : deliveryFee) + 3.0,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        status: OrderStatus.delivered,
        addressLine: 'Av. José Pardo 450, dpto. 302, Miraflores',
        paymentMethod: 'Tarjeta de crédito',
        rated: false,
      ),
      OrderModel(
        id: 'CA-87302',
        items: pastItems2,
        subtotal: pastSub2,
        fee: pastSub2 >= freeDeliveryThreshold ? 0.0 : deliveryFee,
        tip: 3.0,
        discount: 0.0,
        total: pastSub2 + (pastSub2 >= freeDeliveryThreshold ? 0.0 : deliveryFee) + 3.0,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        status: OrderStatus.delivered,
        addressLine: 'Av. José Pardo 450, dpto. 302, Miraflores',
        paymentMethod: 'Yape',
        rated: true,
        ratingStars: 5,
        ratingTags: const ['Llegó a tiempo', 'Productos frescos'],
        ratingComment: 'Excelente servicio, todo impecable.',
      ),
    ];
  }
}
