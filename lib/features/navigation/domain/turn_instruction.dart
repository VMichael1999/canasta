import 'route_path.dart';

enum TurnType { left, right, straight, destination }

class TurnInstruction {
  const TurnInstruction(this.type, this.distanceM, this.street);
  final TurnType type;
  final double distanceM;
  final String? street;

  String get distanceLabel => roundDistance(distanceM);

  String get text {
    final on = street != null ? ' en $street' : '';
    switch (type) {
      case TurnType.left:
        return 'Gira a la izquierda$on';
      case TurnType.right:
        return 'Gira a la derecha$on';
      case TurnType.straight:
        return street != null ? 'Continúa por $street' : 'Continúa recto';
      case TurnType.destination:
        return 'Llegas a tu destino';
    }
  }
}

String roundDistance(double m) {
  if (m < 1000) {
    final r = (m / 10).round() * 10;
    return '${r < 10 ? 10 : r} m';
  }
  return '${(m / 1000).toStringAsFixed(1)} km';
}

class TurnInstructionBuilder {
  static TurnType _type(String m) {
    if (m.contains('LEFT')) return TurnType.left;
    if (m.contains('RIGHT')) return TurnType.right;
    return TurnType.straight;
  }

  /// Próxima maniobra a partir de [traveled].
  static TurnInstruction current(RoutePath path, double traveled) {
    if (path.steps.isNotEmpty) {
      for (var i = 0; i < path.steps.length; i++) {
        if (path.stepStarts[i] > traveled + 1) {
          final s = path.steps[i];
          return TurnInstruction(
              _type(s.maneuver), path.stepStarts[i] - traveled, s.street);
        }
      }
      return TurnInstruction(TurnType.destination, path.total - traveled, null);
    }
    final seg = path.segmentAt(traveled);
    if (seg + 2 >= path.points.length) {
      return TurnInstruction(TurnType.destination, path.total - traveled, null);
    }
    final a = path.turnAngle(seg);
    final t = a.abs() < 15 ? TurnType.straight : (a > 0 ? TurnType.right : TurnType.left);
    return TurnInstruction(t, path.cumulativeAt(seg + 1) - traveled, null);
  }

  static TurnInstruction? next(RoutePath path, double traveled) {
    final c = current(path, traveled);
    if (c.type == TurnType.destination) return null;
    return current(path, traveled + c.distanceM + 2);
  }

  static String? road(RoutePath path, double traveled) {
    if (path.steps.isEmpty) return null;
    String? st;
    for (var i = 0; i < path.steps.length; i++) {
      if (path.stepStarts[i] <= traveled) st = path.steps[i].street ?? st;
    }
    return st;
  }
}
