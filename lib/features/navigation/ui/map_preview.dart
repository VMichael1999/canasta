import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/road_route_repository.dart';
import '../domain/route_path.dart';
import 'pin_icon.dart';
import 'navigation_screen.dart' show navOrigin, navDestination, kNavMapStyle;

final RoadRouteRepository sharedRouteRepo = RoadRouteRepository();

/// Mapa de Google de solo lectura (sin gestos) para Seguimiento y Dirección.
class GoogleMapPreview extends StatefulWidget {
  const GoogleMapPreview({
    super.key,
    this.progress,
    this.showRoute = false,
    this.center = navDestination,
    this.zoom = 15.6,
    this.showDestination = true,
  });

  final bool showDestination;

  /// 0..1 posición de la moto sobre la ruta (null = sin moto).
  final double? progress;
  final bool showRoute;
  final LatLng center;
  final double zoom;

  @override
  State<GoogleMapPreview> createState() => _GoogleMapPreviewState();
}

class _GoogleMapPreviewState extends State<GoogleMapPreview> {
  RoutePath? _path;
  BitmapDescriptor? _icon;
  BitmapDescriptor? _pin;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await rootBundle.load('assets/images/moto_topv.png');
    _pin = await PinIcon.load();
    _icon = BitmapDescriptor.bytes(data.buffer.asUint8List(), width: 30, height: 60);
    if (widget.showRoute) {
      final r = await sharedRouteRepo.route(navOrigin, navDestination);
      _path = r != null
          ? RoutePath(r.points, steps: r.steps)
          : RoutePath([navOrigin, LatLng(navOrigin.latitude, navDestination.longitude), navDestination]);
      _fit();
    }
    if (mounted) setState(() {});
  }

  void _fit() {
    final m = _map, p = _path;
    if (m == null || p == null) return;
    final pts = p.points;
    final b = LatLngBounds(
      southwest: LatLng(pts.map((e) => e.latitude).reduce(math.min), pts.map((e) => e.longitude).reduce(math.min)),
      northeast: LatLng(pts.map((e) => e.latitude).reduce(math.max), pts.map((e) => e.longitude).reduce(math.max)),
    );
    m.moveCamera(CameraUpdate.newLatLngBounds(b, 36));
  }

  @override
  Widget build(BuildContext context) {
    final p = _path;
    final polylines = <Polyline>{};
    final markers = <Marker>{
      if (widget.showDestination && _pin != null)
        Marker(
          markerId: const MarkerId('dest'),
          position: navDestination,
          icon: _pin!,
          anchor: PinIcon.anchor,
        ),
    };
    if (p != null && widget.showRoute) {
      final d = (widget.progress ?? 0) * p.total;
      final seg = p.segmentAt(d);
      final pos = p.positionAt(d);
      final rest = [pos, ...p.points.sublist(seg + 1)];
      polylines.addAll({
        Polyline(polylineId: const PolylineId('c'), points: rest, color: Colors.white, width: 10, zIndex: 1),
        Polyline(polylineId: const PolylineId('r'), points: rest, color: const Color(0xFF1A4FE0), width: 6, zIndex: 2,
            startCap: Cap.roundCap, endCap: Cap.roundCap, jointType: JointType.round),
      });
      if (widget.progress != null && _icon != null) {
        markers.add(Marker(
          markerId: const MarkerId('moto'),
          position: pos,
          icon: _icon!,
          rotation: p.headingOfSegment(seg),
          flat: true,
          anchor: const Offset(.5, .5),
        ));
      }
    }
    return AbsorbPointer(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: widget.center, zoom: widget.zoom),
        style: kNavMapStyle,
        onMapCreated: (c) {
          _map = c;
          _fit();
        },
        markers: markers,
        polylines: polylines,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        tiltGesturesEnabled: false,
      ),
    );
  }
}
