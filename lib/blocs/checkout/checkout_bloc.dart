import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/slot.dart';

enum CheckoutStatus { idle, holding, paying, done, error }

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class CheckoutSlotPicked extends CheckoutEvent {
  const CheckoutSlotPicked(this.slot);
  final DeliverySlot? slot;

  @override
  List<Object?> get props => [slot];
}

class CheckoutPaymentChanged extends CheckoutEvent {
  const CheckoutPaymentChanged(this.paymentMethod);
  final String paymentMethod;

  @override
  List<Object?> get props => [paymentMethod];
}

class CheckoutCashChanged extends CheckoutEvent {
  const CheckoutCashChanged(this.cashAmount);
  final double cashAmount;

  @override
  List<Object?> get props => [cashAmount];
}

class CheckoutTipChanged extends CheckoutEvent {
  const CheckoutTipChanged(this.tip);
  final double tip;

  @override
  List<Object?> get props => [tip];
}

class CheckoutNoteChanged extends CheckoutEvent {
  const CheckoutNoteChanged(this.note);
  final String note;

  @override
  List<Object?> get props => [note];
}

class CheckoutHoldStarted extends CheckoutEvent {
  const CheckoutHoldStarted();
}

class CheckoutHoldProgressChanged extends CheckoutEvent {
  const CheckoutHoldProgressChanged(this.progress);
  final double progress;

  @override
  List<Object?> get props => [progress];
}

class CheckoutHoldCancelled extends CheckoutEvent {
  const CheckoutHoldCancelled();
}

class CheckoutHoldCompleted extends CheckoutEvent {
  const CheckoutHoldCompleted();
}

class CheckoutReset extends CheckoutEvent {
  const CheckoutReset();
}

class CheckoutState extends Equatable {
  const CheckoutState({
    this.slot,
    this.paymentMethod = 'card',
    this.cashAmount = 0.0,
    this.tip = 3.0,
    this.note = '',
    this.status = CheckoutStatus.idle,
    this.holdProgress = 0.0,
    this.errorMessage,
  });

  final DeliverySlot? slot;
  final String paymentMethod;
  final double cashAmount;
  final double tip;
  final String note;
  final CheckoutStatus status;
  final double holdProgress;
  final String? errorMessage;

  CheckoutState copyWith({
    DeliverySlot? slot,
    bool clearSlot = false,
    String? paymentMethod,
    double? cashAmount,
    double? tip,
    String? note,
    CheckoutStatus? status,
    double? holdProgress,
    String? errorMessage,
  }) {
    return CheckoutState(
      slot: clearSlot ? null : (slot ?? this.slot),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashAmount: cashAmount ?? this.cashAmount,
      tip: tip ?? this.tip,
      note: note ?? this.note,
      status: status ?? this.status,
      holdProgress: holdProgress ?? this.holdProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        slot,
        paymentMethod,
        cashAmount,
        tip,
        note,
        status,
        holdProgress,
        errorMessage,
      ];
}

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc() : super(const CheckoutState()) {
    on<CheckoutSlotPicked>((event, emit) {
      emit(state.copyWith(slot: event.slot, clearSlot: event.slot == null));
    });
    on<CheckoutPaymentChanged>((event, emit) {
      emit(state.copyWith(paymentMethod: event.paymentMethod));
    });
    on<CheckoutCashChanged>((event, emit) {
      emit(state.copyWith(cashAmount: event.cashAmount));
    });
    on<CheckoutTipChanged>((event, emit) {
      emit(state.copyWith(tip: event.tip));
    });
    on<CheckoutNoteChanged>((event, emit) {
      emit(state.copyWith(note: event.note));
    });
    on<CheckoutHoldStarted>((event, emit) {
      emit(state.copyWith(status: CheckoutStatus.holding, holdProgress: 0.0));
    });
    on<CheckoutHoldProgressChanged>((event, emit) {
      emit(state.copyWith(holdProgress: event.progress));
    });
    on<CheckoutHoldCancelled>((event, emit) {
      emit(state.copyWith(status: CheckoutStatus.idle, holdProgress: 0.0));
    });
    on<CheckoutHoldCompleted>((event, emit) {
      emit(state.copyWith(status: CheckoutStatus.paying, holdProgress: 1.0));
    });
    on<CheckoutReset>((event, emit) {
      emit(const CheckoutState());
    });
  }
}
