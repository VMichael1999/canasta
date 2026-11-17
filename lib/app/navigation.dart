import 'package:flutter/material.dart';

/// Navigator raíz compartido (hojas, burbuja del carrito, toasts).
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
