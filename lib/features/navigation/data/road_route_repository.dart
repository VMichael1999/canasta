import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/route_path.dart';

/// Ruta real con la Routes API de Google (caché por destino).
class RoadRouteRepository {
  final Map<String, Future<RoadRoute?>> _cache = {};

  Future<RoadRoute?> route(LatLng origin, LatLng dest) {
    final key = '${origin.latitude},${origin.longitude}>${dest.latitude},${dest.longitude}';
    return _cache.putIfAbsent(key, () => _fetch(origin, dest));
  }

  Future<RoadRoute?> _fetch(LatLng o, LatLng d) async {
    final key = dotenv.maybeGet('GOOGLE_MAPS_API_KEY');
    if (key == null || key.isEmpty) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client
          .postUrl(Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'));
      req.headers
        ..set('Content-Type', 'application/json')
        ..set('X-Goog-Api-Key', key)
        ..set('X-Ios-Bundle-Identifier', 'com.canasta.app.canasta')
        ..set('X-Goog-FieldMask',
            'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.legs.steps.distanceMeters,routes.legs.steps.navigationInstruction');
      req.add(utf8.encode(jsonEncode({
        'origin': {'location': {'latLng': {'latitude': o.latitude, 'longitude': o.longitude}}},
        'destination': {'location': {'latLng': {'latitude': d.latitude, 'longitude': d.longitude}}},
        'travelMode': 'DRIVE',
        'languageCode': 'es',
      })));
      final res = await req.close().timeout(const Duration(seconds: 10));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) return null;
      final r = (jsonDecode(body)['routes'] as List).first as Map<String, dynamic>;
      final pts = decodePolyline(r['polyline']['encodedPolyline'] as String);
      final secs = int.tryParse((r['duration'] as String).replaceAll('s', '')) ?? 600;
      final steps = <RouteStep>[];
      for (final leg in (r['legs'] as List? ?? [])) {
        for (final s in (leg['steps'] as List? ?? [])) {
          final nav = s['navigationInstruction'] as Map<String, dynamic>?;
          steps.add(RouteStep(
            maneuver: (nav?['maneuver'] as String?) ?? 'STRAIGHT',
            street: RouteStep.streetFrom(nav?['instructions'] as String?),
            distanceM: ((s['distanceMeters'] as num?) ?? 0).toDouble(),
          ));
        }
      }
      if (pts.length < 2) return null;
      return RoadRoute(points: pts, steps: steps, minutes: (secs / 60).ceil());
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
