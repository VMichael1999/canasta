import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../blocs/live_order/live_order_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/tokens.dart';
import '../bloc/navigation_bloc.dart';
import '../data/road_route_repository.dart';
import '../domain/route_path.dart';
import 'car_3d.dart';
import 'nav_widgets.dart';
import 'pin_icon.dart';

const navOrigin = LatLng(-12.1118, -77.0218);
const navDestination = LatLng(-12.1203, -77.0299);

const kNavMapStyle = '[{"featureType":"poi","stylers":[{"visibility":"off"}]},'
    '{"featureType":"transit","stylers":[{"visibility":"off"}]},'
    '{"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#EEF1F5"}]},'
    '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#BFD9F2"}]}]';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationBloc(repository: RoadRouteRepository())
        ..add(const NavigationStarted(navOrigin, navDestination)),
      child: const _NavView(),
    );
  }
}

class _NavView extends StatefulWidget {
  const _NavView();

  @override
  State<_NavView> createState() => _NavViewState();
}

class _NavViewState extends State<_NavView> {
  final Completer<GoogleMapController> _ctrl = Completer();
  GoogleMapController? _map;
  BitmapDescriptor? _motoIcon;
  BitmapDescriptor? _pin;
  bool _modelReady = false;
  bool _settled = false;
  Offset? _carPos;
  bool _syncing = false;
  double _yaw = 0;
  Offset? _down;
  bool _moved = false;

  // cámara suavizada
  double _bearing = 0, _zoom = 17.3, _tilt = 0;
  LatLng? _target;
  bool _camInit = false;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    final data = await rootBundle.load('assets/images/moto_topv.png');
    final icon = BitmapDescriptor.bytes(data.buffer.asUint8List(),
        width: 34, height: 68);
    final pin = await PinIcon.load();
    if (mounted) {
      setState(() {
        _motoIcon = icon;
        _pin = pin;
      });
    }
  }

  static double _shortest(double from, double to) {
    var d = (to - from) % 360;
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    return d;
  }

  static double _k(double rate) => 1 - math.exp(-0.05 * rate);

  Future<void> _onState(BuildContext context, NavState s) async {
    final map = _map;
    if (map == null) return;
    if (s is NavOverview) {
      final pts = s.path.points;
      final b = LatLngBounds(
        southwest: LatLng(pts.map((p) => p.latitude).reduce(math.min), pts.map((p) => p.longitude).reduce(math.min)),
        northeast: LatLng(pts.map((p) => p.latitude).reduce(math.max), pts.map((p) => p.longitude).reduce(math.max)),
      );
      map.animateCamera(CameraUpdate.newLatLngBounds(b, 90));
    } else if (s is NavDriving) {
      if (s.approachNotice && context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Te estás acercando')));
      }
      final pos = s.position;
      if (!_camInit) {
        _camInit = true;
        _target = pos;
        _bearing = s.heading;
      }
      if (!s.followPaused) {
        _bearing = (_bearing + _shortest(_bearing, s.heading) * _k(3.4) + 360) % 360;
        _zoom += ((s.is3D ? 17.8 : 17.3) - _zoom) * _k(3.4);
        _tilt += ((s.is3D ? 52.0 : 0.0) - _tilt) * _k(3.4);
        final mPerPx = 156543.03 * math.cos(pos.latitude * math.pi / 180) / math.pow(2, _zoom);
        final ahead = (s.is3D ? 172 : 122) * mPerPx;
        final rad = _bearing * math.pi / 180;
        final goal = LatLng(
          pos.latitude + ahead * math.cos(rad) / 111320,
          pos.longitude + ahead * math.sin(rad) / (111320 * math.cos(pos.latitude * math.pi / 180)),
        );
        final t = _target!;
        _target = LatLng(t.latitude + (goal.latitude - t.latitude) * _k(9),
            t.longitude + (goal.longitude - t.longitude) * _k(9));
        map.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target: _target!, zoom: _zoom, bearing: _bearing, tilt: _tilt)));
      }
      _yaw = -_shortest(_bearing, s.heading).clamp(-35.0, 35.0);
      _syncCar(pos);
    } else if (s is NavArrived) {
      if (mounted) context.read<LiveOrderBloc>().add(const LiveOrderDelivered());
      setState(() {
        _settled = false;
        _yaw = 0;
      });
      await map.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: s.destination, zoom: 18.2, bearing: s.heading, tilt: 52)));
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await _syncCar(s.destination);
      if (mounted) setState(() => _settled = true);
    }
  }

  Future<void> _syncCar(LatLng pos) async {
    final map = _map;
    if (map == null || _syncing) return;
    _syncing = true;
    try {
      final sc = await map.getScreenCoordinate(pos);
      final dpr = Platform.isAndroid ? MediaQuery.of(context).devicePixelRatio : 1.0;
      if (mounted) setState(() => _carPos = Offset(sc.x / dpr, sc.y / dpr));
    } catch (_) {}
    _syncing = false;
  }

  Set<Polyline> _lines(NavState s) {
    final RoutePath? path = switch (s) {
      NavOverview() => s.path,
      NavDriving() => s.path,
      NavArrived() => s.path,
      _ => null,
    };
    if (path == null) return {};
    final traveled = s is NavDriving ? s.traveled : (s is NavArrived ? path.total : 0.0);
    final seg = path.segmentAt(traveled);
    final pos = path.positionAt(traveled);
    final done = [...path.points.sublist(0, seg + 1), pos];
    final rest = [pos, ...path.points.sublist(seg + 1)];
    final c = context.tokens;
    Polyline pl(String id, List<LatLng> pts, Color col, int w, int z) => Polyline(
        polylineId: PolylineId(id),
        points: pts,
        color: col,
        width: w,
        zIndex: z,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap);
    return {
      pl('done', done, const Color(0xFFB9C0CE), 6, 1),
      pl('casing', rest, Colors.white, 12, 2),
      pl('rest', rest, c.blue, 7, 3),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<NavigationBloc, NavState>(
        listener: _onState,
        builder: (context, s) {
          final driving = s is NavDriving;
          final arrived = s is NavArrived;
          final is3D = driving && s.is3D;
          final show3D = _modelReady && _carPos != null && ((driving && is3D) || (arrived && _settled));
          LatLng? carLatLng;
          double heading = 0;
          if (s is NavDriving) {
            carLatLng = s.position;
            heading = s.heading;
          } else if (s is NavArrived) {
            carLatLng = s.destination;
            heading = s.heading;
          }
          final markers = <Marker>{
            if (_pin != null)
              Marker(
                markerId: const MarkerId('dest'),
                position: navDestination,
                icon: _pin!,
                anchor: PinIcon.anchor,
              ),
            if (carLatLng != null && _motoIcon != null)
              Marker(
                markerId: const MarkerId('moto'),
                position: carLatLng,
                icon: _motoIcon!,
                rotation: heading,
                flat: true,
                anchor: const Offset(.5, .5),
                alpha: show3D ? 0 : 1,
                zIndexInt: 5,
              ),
          };
          final top = MediaQuery.of(context).padding.top;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: (e) {
                    _down = e.position;
                    _moved = false;
                  },
                  onPointerMove: (e) {
                    if (!_moved && _down != null && (e.position - _down!).distance > 12) {
                      _moved = true;
                      if (driving) context.read<NavigationBloc>().add(const MapMovedByUser());
                    }
                  },
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(target: navOrigin, zoom: 14),
                    style: kNavMapStyle,
                    onMapCreated: (c) {
                      _map = c;
                      if (!_ctrl.isCompleted) _ctrl.complete(c);
                    },
                    markers: markers,
                    polylines: _lines(s),
                    buildingsEnabled: is3D || arrived,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    compassEnabled: false,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    scrollGesturesEnabled: driving,
                    zoomGesturesEnabled: driving,
                  ),
                ),
              ),
              // moto 3D encima del mapa
              if (_carPos != null)
                Positioned(
                  left: _carPos!.dx - 52,
                  top: _carPos!.dy - 65,
                  child: AnimatedOpacity(
                    opacity: show3D ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    child: Car3D(
                      yawDeg: _yaw,
                      onReady: () => setState(() => _modelReady = true),
                    ),
                  ),
                )
              else
                Positioned(
                  left: -300,
                  top: 0,
                  child: Opacity(
                    opacity: 0,
                    child: Car3D(
                      yawDeg: 0,
                      onReady: () => setState(() => _modelReady = true),
                    ),
                  ),
                ),

              // banner superior
              Positioned(
                left: 14,
                right: 14,
                top: top + 6,
                child: switch (s) {
                  NavDriving() => NavBanner(
                      instruction: s.instruction,
                      next: s.nextInstruction,
                      road: s.road,
                    ),
                  NavArrived() => const ArrivalBanner(),
                  _ => const SizedBox.shrink(),
                },
              ),
              // botones del mapa
              if (driving)
                Positioned(
                  right: 14,
                  top: top + 150,
                  child: Column(
                    children: [
                      MapGlassButton(
                        label: s.is3D ? '2D' : '3D',
                        onTap: () => context.read<NavigationBloc>().add(const ViewToggled()),
                      ),
                      if (s.followPaused) ...[
                        const SizedBox(height: 10),
                        MapGlassButton(
                          label: 'Recentrar',
                          icon: 'locate',
                          onTap: () => context.read<NavigationBloc>().add(const RecenterPressed()),
                        ),
                      ],
                    ],
                  ),
                ),
              // carga / vista general
              if (s is NavLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: .6),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              // hoja inferior
              if (driving)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: NavBottomCard(
                    speed: s.speedKmh,
                    eta: s.etaMinutes,
                    remaining: s.remaining,
                    arrival: s.arrivalTime,
                    progress: s.traveled / s.path.total,
                    onClose: () => _confirmExit(context),
                  ),
                ),
              if (arrived)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ArrivalSheet(
                    distance: s.path.total,
                    onContinue: () {
                      context.read<LiveOrderBloc>().add(const LiveOrderDelivered());
                      context.pushReplacement('/rate');
                    },
                    onExit: () => context.canPop() ? context.pop() : context.go('/tracking'),
                  ),
                ),
              if (!driving && !arrived)
                Positioned(
                  left: 14,
                  top: top + 6,
                  child: MapGlassButton(
                    label: 'Cerrar',
                    onTap: () => context.canPop() ? context.pop() : context.go('/tracking'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la navegación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.canPop() ? context.pop() : context.go('/tracking');
    }
  }
}
