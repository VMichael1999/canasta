import 'dart:async';
import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/initial_data.dart';
import '../../domain/models/order.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.sender, // 'user' or 'courier'
    required this.text,
    required this.time,
  });

  final String id;
  final String sender;
  final String text;
  final String time;

  bool get isUser => sender == 'user';

  @override
  List<Object?> get props => [id, sender, text, time];
}

abstract class LiveOrderEvent extends Equatable {
  const LiveOrderEvent();

  @override
  List<Object?> get props => [];
}

class LiveOrderTick extends LiveOrderEvent {
  const LiveOrderTick();
}

class LiveOrderSendMessage extends LiveOrderEvent {
  const LiveOrderSendMessage(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

class LiveOrderCourierNear extends LiveOrderEvent {
  const LiveOrderCourierNear();
}

class LiveOrderDelivered extends LiveOrderEvent {
  const LiveOrderDelivered();
}

class LiveOrderSetOrder extends LiveOrderEvent {
  const LiveOrderSetOrder(this.order);
  final OrderModel order;

  @override
  List<Object?> get props => [order];
}

class LiveOrderState extends Equatable {
  const LiveOrderState({
    required this.order,
    this.stage = 2, // 0: Pedido hecho, 1: Confirmado, 2: En camino, 3: Entregado
    this.routeProgress = 0.32, // 0..1
    this.distanceKm = 1.4,
    this.minsLeft = 11,
    this.nearAlertTriggered = false,
    this.deliveredAlertTriggered = false,
    this.chatMessages = const [
      ChatMessage(
        id: '1',
        sender: 'courier',
        text: '¡Hola Michael! Ya salí con tu pedido de Canasta. Llego en unos 11 min.',
        time: '3:29 p. m.',
      ),
    ],
    this.courierTyping = false,
  });

  final OrderModel order;
  final int stage;
  final double routeProgress;
  final double distanceKm;
  final int minsLeft;
  final bool nearAlertTriggered;
  final bool deliveredAlertTriggered;
  final List<ChatMessage> chatMessages;
  final bool courierTyping;

  LiveOrderState copyWith({
    OrderModel? order,
    int? stage,
    double? routeProgress,
    double? distanceKm,
    int? minsLeft,
    bool? nearAlertTriggered,
    bool? deliveredAlertTriggered,
    List<ChatMessage>? chatMessages,
    bool? courierTyping,
  }) {
    return LiveOrderState(
      order: order ?? this.order,
      stage: stage ?? this.stage,
      routeProgress: routeProgress ?? this.routeProgress,
      distanceKm: distanceKm ?? this.distanceKm,
      minsLeft: minsLeft ?? this.minsLeft,
      nearAlertTriggered: nearAlertTriggered ?? this.nearAlertTriggered,
      deliveredAlertTriggered:
          deliveredAlertTriggered ?? this.deliveredAlertTriggered,
      chatMessages: chatMessages ?? this.chatMessages,
      courierTyping: courierTyping ?? this.courierTyping,
    );
  }

  @override
  List<Object?> get props => [
        order,
        stage,
        routeProgress,
        distanceKm,
        minsLeft,
        nearAlertTriggered,
        deliveredAlertTriggered,
        chatMessages,
        courierTyping,
      ];
}

class LiveOrderBloc extends Bloc<LiveOrderEvent, LiveOrderState> {
  LiveOrderBloc()
      : super(LiveOrderState(order: InitialData.initialOrders.first)) {
    on<LiveOrderTick>(_onTick);
    on<LiveOrderSendMessage>(_onSendMessage);
    on<LiveOrderCourierNear>(_onCourierNear);
    on<LiveOrderDelivered>(_onDelivered);
    on<LiveOrderSetOrder>(_onSetOrder);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const LiveOrderTick());
    });
  }

  Timer? _timer;
  DateTime _start = DateTime.now();

  /// Distancia total de la ruta (KM del HTML).
  static const double totalKm = 2.1;

  static int minsFor(int stage, double rp) => stage >= 3
      ? 0
      : stage == 2
          ? math.max(1, ((1 - rp) * 16).ceil())
          : stage == 1
              ? 18
              : 24;

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _onSetOrder(LiveOrderSetOrder event, Emitter<LiveOrderState> emit) {
    _start = DateTime.now();
    emit(state.copyWith(
      order: event.order,
      routeProgress: 0,
      minsLeft: 24,
      distanceKm: totalKm,
      stage: 0,
      nearAlertTriggered: false,
      deliveredAlertTriggered: false,
    ));
  }

  /// Cada segundo: pedido hecho → confirmado (5 s) → en camino (12 s); luego la
  /// moto avanza 0.6 % por segundo. Al 86 % avisa; al 100 % entrega.
  void _onTick(LiveOrderTick event, Emitter<LiveOrderState> emit) {
    if (state.stage >= 3) return;
    final age = DateTime.now().difference(_start).inSeconds;

    if (state.stage == 0) {
      if (age > 5) {
        emit(state.copyWith(stage: 1, minsLeft: minsFor(1, 0)));
      }
      return;
    }
    if (state.stage == 1) {
      if (age > 12) {
        emit(state.copyWith(
            stage: 2, routeProgress: 0, minsLeft: minsFor(2, 0)));
      }
      return;
    }

    final prev = state.routeProgress;
    final next = math.min(1.0, prev + 0.006);
    var nearTriggered = state.nearAlertTriggered;
    var delivered = state.deliveredAlertTriggered;
    var stage = state.stage;
    if (prev < 0.86 && next >= 0.86 && !nearTriggered) {
      nearTriggered = true;
    }
    if (next >= 1.0) {
      delivered = true;
      stage = 3;
    }
    emit(state.copyWith(
      routeProgress: next,
      distanceKm: double.parse((totalKm * (1 - next)).toStringAsFixed(1)),
      minsLeft: minsFor(stage, next),
      stage: stage,
      nearAlertTriggered: nearTriggered,
      deliveredAlertTriggered: delivered,
    ));
  }

  void _onCourierNear(LiveOrderCourierNear event, Emitter<LiveOrderState> emit) {
    emit(state.copyWith(nearAlertTriggered: true));
  }

  void _onDelivered(LiveOrderDelivered event, Emitter<LiveOrderState> emit) {
    emit(state.copyWith(
      stage: 3,
      routeProgress: 1.0,
      distanceKm: 0.0,
      minsLeft: 0,
      deliveredAlertTriggered: true,
    ));
  }

  void _onSendMessage(
      LiveOrderSendMessage event, Emitter<LiveOrderState> emit) {
    final now = DateTime.now();
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final timeStr =
        '$hour12:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'p. m.' : 'a. m.'}';

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      text: event.text,
      time: timeStr,
    );

    final updated = [...state.chatMessages, userMsg];
    emit(state.copyWith(chatMessages: updated, courierTyping: true));

    // Simulate reply after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (isClosed) return;
      final replyText = _getAutomatedReply(event.text);
      final replyMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_c',
        sender: 'courier',
        text: replyText,
        time: timeStr,
      );
      emit(state.copyWith(
        chatMessages: [...state.chatMessages, replyMsg],
        courierTyping: false,
      ));
    });
  }

  String _getAutomatedReply(String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('bajo') || lower.contains('recibir')) {
      return '¡Perfecto! Te espero afuera.';
    } else if (lower.contains('302') || lower.contains('intercomunicador')) {
      return 'Entendido, toco el 302 en cuanto llegue.';
    } else if (lower.contains('recepción') || lower.contains('recepcion')) {
      return 'Listo, lo dejo con el personal de recepción con tu nombre.';
    }
    return '¡De acuerdo! Gracias por avisar.';
  }
}
