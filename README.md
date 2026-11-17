<div align="center">

<img src="assets/brand/app_icon_1024.png" width="110" alt="Logo de Canasta" />

# Canasta

**Lo fresco, a tu puerta.** App de supermercado a domicilio para Lima, hecha en Flutter.

![Flutter](https://img.shields.io/badge/Flutter-3.29-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?logo=dart&logoColor=white)
![BLoC](https://img.shields.io/badge/estado-BLoC-1A4FE0)
![go_router](https://img.shields.io/badge/navegaci%C3%B3n-go__router-1A4FE0)
![Google Maps](https://img.shields.io/badge/Google%20Maps-SDK-4285F4?logo=googlemaps&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-15%2B-000000?logo=apple&logoColor=white)
![Android](https://img.shields.io/badge/Android-soportado-3DDC84?logo=android&logoColor=white)
![UI](https://img.shields.io/badge/idioma-espa%C3%B1ol-F2C94C)

</div>

---

## Capturas

| Ingreso | Inicio | Categorías | Producto | Carrito |
| :---: | :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/login.png" width="160" /> | <img src="docs/screenshots/home.png" width="160" /> | <img src="docs/screenshots/categories.png" width="160" /> | <img src="docs/screenshots/product.png" width="160" /> | <img src="docs/screenshots/cart.png" width="160" /> |

| Dirección | Confirmar pedido | Pedido confirmado | Seguimiento | Navegación |
| :---: | :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/location.png" width="160" /> | <img src="docs/screenshots/checkout.png" width="160" /> | <img src="docs/screenshots/order.png" width="160" /> | <img src="docs/screenshots/tracking.png" width="160" /> | <img src="docs/screenshots/nav.png" width="160" /> |

## Qué incluye

- **Compra completa:** inicio, categorías con transición animada, listas por subcategoría, detalle con selector de peso, buscador y ofertas.
- **Carrito:** burbuja flotante global con vuelo del producto, cupón «rasca y gana» y barra de delivery gratis.
- **Checkout:** dirección, horario programado, métodos de pago (Visa, Yape, Plin, efectivo), propina y botón de **deslizar para pagar**.
- **Pedido confirmado:** animación de la moto, cuenta regresiva y paso automático al seguimiento.
- **Seguimiento en vivo:** etapas del pedido, mapa de Google con la ruta, datos del repartidor y calificación al recibir.
- **Modo navegación 2D / 3D:** ruta real (Routes API), instrucciones giro a giro, cámara que sigue a la moto y moto 3D (`.glb`).
- **Dirección:** selector de ubicación con marcador personalizado sobre Google Maps.

## Arquitectura

```
lib/
├── app/         # MaterialApp, router (go_router) y navegación global
├── blocs/       # Cart, Checkout, LiveOrder, Orders, Address, Catalog…
├── core/        # tokens de diseño, tipografía, utilidades
├── data/        # catálogo y datos de ejemplo
├── domain/      # modelos
├── features/    # una carpeta por pantalla / flujo
└── shared/      # widgets reutilizables (burbuja, steppers, slider de pago…)
```

- **Estado:** `flutter_bloc` + `equatable`.
- **Rutas:** `go_router` con `StatefulShellRoute` para la barra inferior.
- **Diseño:** tokens propios y tipografía Inter, fiel al prototipo HTML.

## Cómo ejecutarlo

Requisitos: Flutter 3.29+ y una API key de Google Maps (Maps SDK y Routes API habilitados).

```bash
git clone https://github.com/vmichael1999/canasta.git
cd canasta
flutter pub get

# Clave de Google Maps (no se versiona)
cp .env.example .env                                   # completa GOOGLE_MAPS_API_KEY
cp ios/Flutter/Env.xcconfig.example ios/Flutter/Env.xcconfig   # idem, para iOS

flutter run
```

Para abrir directamente una pantalla en desarrollo:

```bash
flutter run --dart-define=INITIAL_ROUTE=/tracking
```

> Los archivos `.env` y `ios/Flutter/Env.xcconfig` están en `.gitignore`: nunca subas tu clave.

## Autor

Hecho por [@vmichael1999](https://github.com/vmichael1999).
