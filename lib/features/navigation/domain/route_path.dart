import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteStep {
  const RouteStep({required this.maneuver, this.street, required this.distanceM});
  final String maneuver;
  final String? street;
  final double distanceM;

  /// Extrae la calle del texto de Google («… en Av. Z hacia …», «… hacia Av. X», «… por Ca. Y»).
  static String? streetFrom(String? text) {
    if (text == null || text.isEmpty) return null;
    final en = RegExp(r' en (.+?) hacia ').firstMatch(text);
    if (en != null) return en.group(1)!.trim();
    final hacia = RegExp(r'hacia (.+)$').firstMatch(text);
    if (hacia != null) return hacia.group(1)!.trim();
    final por = RegExp(r'por (.+)$').firstMatch(text);
    if (por != null) return por.group(1)!.trim();
    return null;
  }
}

class RoadRoute {
  const RoadRoute({required this.points, required this.steps, required this.minutes});
  final List<LatLng> points;
  final List<RouteStep> steps;
  final int minutes;
}

/// Polilínea con distancias acumuladas en metros (aprox. equirectangular).
class RoutePath {
  RoutePath(this.points, {this.steps = const []}) {
    _cum = [0];
    for (var i = 1; i < points.length; i++) {
      _cum.add(_cum.last + _dist(points[i - 1], points[i]));
    }
    final sum = steps.fold<double>(0, (a, s) => a + s.distanceM);
    final k = sum > 0 ? total / sum : 1.0;
    var acc = 0.0;
    stepStarts = [];
    for (final s in steps) {
      stepStarts.add(acc * k);
      acc += s.distanceM;
    }
  }

  final List<LatLng> points;
  final List<RouteStep> steps;
  late final List<double> _cum;
  late final List<double> stepStarts;

  static double _dist(LatLng a, LatLng b) {
    final dy = (b.latitude - a.latitude) * 111320;
    final dx = (b.longitude - a.longitude) *
        111320 *
        math.cos(a.latitude * math.pi / 180);
    return math.sqrt(dx * dx + dy * dy);
  }

  double get total => _cum.last;

  int segmentAt(double d) {
    d = d.clamp(0.0, total);
    for (var i = 1; i < _cum.length; i++) {
      if (d <= _cum[i]) return i - 1;
    }
    return math.max(0, points.length - 2);
  }

  LatLng positionAt(double d) {
    d = d.clamp(0.0, total);
    final i = segmentAt(d);
    final len = _cum[i + 1] - _cum[i];
    final t = len == 0 ? 0.0 : (d - _cum[i]) / len;
    final a = points[i], b = points[i + 1];
    return LatLng(a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t);
  }

  double headingOfSegment(int i) {
    i = i.clamp(0, points.length - 2);
    final a = points[i], b = points[i + 1];
    final north = (b.latitude - a.latitude) * 111320;
    final east = (b.longitude - a.longitude) *
        111320 *
        math.cos(a.latitude * math.pi / 180);
    return (math.atan2(east, north) * 180 / math.pi + 360) % 360;
  }

  /// Ángulo con signo en el vértice i+1: + derecha, − izquierda.
  double turnAngle(int i) {
    if (i + 2 >= points.length) return 0;
    var d = headingOfSegment(i + 1) - headingOfSegment(i);
    while (d > 180) d -= 360;
    while (d <= -180) d += 360;
    return d;
  }

  List<double> get corners => [for (var i = 1; i < _cum.length - 1; i++) _cum[i]];
  double cumulativeAt(int i) => _cum[i];
}

List<LatLng> decodePolyline(String encoded) {
  final out = <LatLng>[];
  var index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    int shift = 0, result = 0, b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    out.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return out;
}
