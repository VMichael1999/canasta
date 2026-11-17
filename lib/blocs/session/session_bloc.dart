import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/initial_data.dart';
import '../../domain/models/user_profile.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class PhoneSubmitted extends SessionEvent {
  const PhoneSubmitted(this.phone);
  final String phone;

  @override
  List<Object?> get props => [phone];
}

class OtpEntered extends SessionEvent {
  const OtpEntered(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

class SignedOut extends SessionEvent {
  const SignedOut();
}

class SessionState extends Equatable {
  const SessionState({
    this.user = InitialData.user,
    this.phone = '987 654 321',
    this.isVerified = true,
    this.errorMessage,
  });

  final UserProfile user;
  final String phone;
  final bool isVerified;
  final String? errorMessage;

  SessionState copyWith({
    UserProfile? user,
    String? phone,
    bool? isVerified,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      user: user ?? this.user,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [user, phone, isVerified, errorMessage];
}

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc() : super(const SessionState()) {
    on<PhoneSubmitted>((event, emit) {
      final digits = event.phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 9 || !digits.startsWith('9')) {
        emit(state.copyWith(
          errorMessage: 'Escribe un celular de 9 dígitos que empiece con 9.',
        ));
      } else {
        emit(state.copyWith(
          phone: event.phone,
          clearError: true,
        ));
      }
    });

    on<OtpEntered>((event, emit) {
      if (event.code == '482913') {
        emit(state.copyWith(
          isVerified: true,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          errorMessage:
              'Ese código no es correcto. Revisa el SMS e inténtalo otra vez.',
        ));
      }
    });

    on<SignedOut>((event, emit) {
      emit(state.copyWith(isVerified: false));
    });
  }
}
