import 'dart:async';
import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/road_route_repository.dart';
import '../data/route_simulator.dart';
import '../domain/route_path.dart';
import '../domain/turn_instruction.dart';

enum ViewMode { auto, forced2D, forced3D }

abstract class NavEvent {
  const NavEvent();
}

class NavigationStarted extends NavEvent {
  const NavigationStarted(this.origin, this.destination);
  final LatLng origin, destination;
}

class OverviewFinished extends NavEvent {
  const OverviewFinished();
}

class PositionTicked extends NavEvent {
  const PositionTicked(this.traveled);
  final double traveled;
}

class ViewToggled extends NavEvent {
  const ViewToggled();
}

class MapMovedByUser extends NavEvent {
  const MapMovedByUser();
}

class RecenterPressed extends NavEvent {
  const RecenterPressed();
}

sealed class NavState extends Equatable {
  const NavState();
  @override
  List<Object?> get props => [];
}

class NavLoading extends NavState {
  const NavLoading();
}

class NavOverview extends NavState {
  const NavOverview(this.destination, this.path);
  final LatLng destination;
  final RoutePath path;
  @override
  List<Object?> get props => [destination, path];
}

class NavDriving extends NavState {
  const NavDriving({
    required this.destination,
    required this.path,
    required this.traveled,
    required this.speedKmh,
    required this.etaMinutes,
    required this.arrivalTime,
    required this.instruction,
    required this.nextInstruction,
    required this.road,
    required this.viewMode,
    required this.is3D,
    required this.followPaused,
    this.approachNotice = false,
  });

  final LatLng destination;
  final RoutePath path;
  final double traveled;
  final int speedKmh;
  final int etaMinutes;
  final DateTime arrivalTime;
  final TurnInstruction instruction;
  final TurnInstruction? nextInstruction;
  final String? road;
  final ViewMode viewMode;
  final bool is3D;
  final bool followPaused;
  final bool approachNotice;

  LatLng get position => path.positionAt(traveled);
  double get heading => path.headingOfSegment(path.segmentAt(traveled));
  double get remaining => path.total - traveled;

  NavDriving copyWith({
    double? traveled,
    int? speedKmh,
    int? etaMinutes,
    DateTime? arrivalTime,
    TurnInstruction? instruction,
    TurnInstruction? nextInstruction,
    String? road,
    ViewMode? viewMode,
    bool? is3D,
    bool? followPaused,
    bool? approachNotice,
  }) =>
      NavDriving(
        destination: destination,
        path: path,
        traveled: traveled ?? this.traveled,
        speedKmh: speedKmh ?? this.speedKmh,
        etaMinutes: etaMinutes ?? this.etaMinutes,
        arrivalTime: arrivalTime ?? this.arrivalTime,
        instruction: instruction ?? this.instruction,
        nextInstruction: nextInstruction ?? this.nextInstruction,
        road: road ?? this.road,
        viewMode: viewMode ?? this.viewMode,
        is3D: is3D ?? this.is3D,
        followPaused: followPaused ?? this.followPaused,
        approachNotice: approachNotice ?? false,
      );

  @override
  List<Object?> get props => [traveled, speedKmh, etaMinutes, viewMode, is3D, followPaused, instruction.type, approachNotice];
}

class NavArrived extends NavState {
  const NavArrived(this.destination, this.path, this.heading);
  final LatLng destination;
  final RoutePath path;
  final double heading;
  @override
  List<Object?> get props => [destination, heading];
}

class NavigationBloc extends Bloc<NavEvent, NavState> {
  NavigationBloc({
    required this.repository,
    this.overviewDelay = const Duration(milliseconds: 1500),
    DateTime Function()? clock,
  })  : clock = clock ?? DateTime.now,
        super(const NavLoading()) {
    on<NavigationStarted>(_onStarted);
    on<OverviewFinished>(_onOverview);
    on<PositionTicked>(_onTick);
    on<ViewToggled>(_onToggle);
    on<MapMovedByUser>((e, emit) {
      final s = state;
      if (s is NavDriving && !s.followPaused) emit(s.copyWith(followPaused: true));
    });
    on<RecenterPressed>((e, emit) {
      final s = state;
      if (s is NavDriving) {
        emit(s.copyWith(followPaused: false, viewMode: ViewMode.auto, is3D: _auto3D(s.path, s.traveled)));
      }
    });
  }

  final RoadRouteRepository repository;
  final Duration overviewDelay;
  final DateTime Function() clock;
  Timer? _timer;
  StreamSubscription<double>? _sub;
  int _minutes = 8;
  bool _noticeShown = false;
  double _lastTraveled = 0;
  DateTime _lastAt = DateTime.now();

  static bool _auto3D(RoutePath p, double traveled) =>
      (p.total - traveled) < math.max(1012, p.total * 0.34);

  Future<void> _onStarted(NavigationStarted e, Emitter<NavState> emit) async {
    final road = await repository.route(e.origin, e.destination);
    final path = road != null
        ? RoutePath(road.points, steps: road.steps)
        : RoutePath([e.origin, LatLng(e.origin.latitude, e.destination.longitude), e.destination]);
    _minutes = road?.minutes ?? math.max(3, (path.total / 400).ceil());
    emit(NavOverview(e.destination, path));
    _timer = Timer(overviewDelay, () => add(const OverviewFinished()));
  }

  void _onOverview(OverviewFinished e, Emitter<NavState> emit) {
    final s = state;
    if (s is! NavOverview) return;
    emit(_driving(s.destination, s.path, 0, ViewMode.auto, false, 0));
    _lastAt = clock();
    _sub = RouteSimulator(s.path).run().listen((d) => add(PositionTicked(d)));
  }

  NavDriving _driving(LatLng dest, RoutePath p, double traveled, ViewMode mode, bool paused, int speed) {
    final eta = math.max(1, (_minutes * (p.total - traveled) / p.total).ceil());
    final is3D = mode == ViewMode.auto ? _auto3D(p, traveled) : mode == ViewMode.forced3D;
    return NavDriving(
      destination: dest,
      path: p,
      traveled: traveled,
      speedKmh: speed,
      etaMinutes: eta,
      arrivalTime: clock().add(Duration(minutes: eta)),
      instruction: TurnInstructionBuilder.current(p, traveled),
      nextInstruction: TurnInstructionBuilder.next(p, traveled),
      road: TurnInstructionBuilder.road(p, traveled),
      viewMode: mode,
      is3D: is3D,
      followPaused: paused,
    );
  }

  void _onTick(PositionTicked e, Emitter<NavState> emit) {
    final s = state;
    if (s is! NavDriving) return;
    if (e.traveled >= s.path.total - 0.5) {
      _sub?.cancel();
      emit(NavArrived(s.destination, s.path, s.path.headingOfSegment(s.path.points.length - 2)));
      return;
    }
    final now = clock();
    final dt = now.difference(_lastAt).inMilliseconds / 1000;
    var speed = s.speedKmh;
    if (dt > 0.2) {
      // el recorrido simulado dura ~16 s: se escala a ~46 km/h
      final mps = (e.traveled - _lastTraveled) / dt;
      speed = (46 * mps / (s.path.total / 16)).round().clamp(0, 60);
      _lastTraveled = e.traveled;
      _lastAt = now;
    }
    var next = _driving(s.destination, s.path, e.traveled, s.viewMode, s.followPaused, speed);
    if (s.viewMode == ViewMode.auto && next.is3D && !s.is3D && !_noticeShown) {
      _noticeShown = true;
      next = next.copyWith(approachNotice: true);
    }
    emit(next);
  }

  void _onToggle(ViewToggled e, Emitter<NavState> emit) {
    final s = state;
    if (s is! NavDriving) return;
    final to3D = !s.is3D;
    emit(s.copyWith(is3D: to3D, viewMode: to3D ? ViewMode.forced3D : ViewMode.forced2D));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _sub?.cancel();
    return super.close();
  }
}
