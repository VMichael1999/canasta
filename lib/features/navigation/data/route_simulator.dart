import 'dart:async';
import '../domain/route_path.dart';

/// Recorrido simulado (cámbialo por GPS real): emite metros recorridos cada 50 ms.
class RouteSimulator {
  RouteSimulator(this.path);
  final RoutePath path;

  Stream<double> run() async* {
    // el viaje dura ~16 s sin importar el largo real
    const tick = Duration(milliseconds: 50);
    final base = path.total / (16000 / 50);
    var d = 0.0;
    final corners = path.corners;
    while (d < path.total) {
      final nearCorner = corners.any((c) => (c - d).abs() <= 50 && c >= d - 5);
      d += base * (nearCorner ? .45 : 1.0);
      yield d.clamp(0.0, path.total);
      await Future<void>.delayed(tick);
    }
    yield path.total;
  }
}
