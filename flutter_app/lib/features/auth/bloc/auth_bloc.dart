import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repositories/auth_repository.dart';
import '../../profile/models/user_model.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {}

class AuthRequestOTPEvent extends AuthEvent {
  final String phoneNumber;
  AuthRequestOTPEvent(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class AuthVerifyOTPEvent extends AuthEvent {
  final String phoneNumber;
  final String code;
  AuthVerifyOTPEvent(this.phoneNumber, this.code);
  @override
  List<Object?> get props => [phoneNumber, code];
}

class AuthCompleteRegistrationEvent extends AuthEvent {
  final Map<String, dynamic> data;
  AuthCompleteRegistrationEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class AuthLogoutEvent extends AuthEvent {}

class AuthUserUpdatedEvent extends AuthEvent {
  final UserModel user;
  AuthUserUpdatedEvent(this.user);
  @override
  List<Object?> get props => [user];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}
class AuthLoadingState extends AuthState {}
class AuthUnauthenticatedState extends AuthState {}

class AuthOTPSentState extends AuthState {
  final String phoneNumber;
  AuthOTPSentState(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class AuthOTPErrorState extends AuthState {
  final String message;
  AuthOTPErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthNeedsRegistrationState extends AuthState {
  final String phoneNumber;
  AuthNeedsRegistrationState(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class AuthAuthenticatedState extends AuthState {
  final UserModel user;
  AuthAuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthErrorState extends AuthState {
  final String message;
  AuthErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitialState()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthRequestOTPEvent>(_onRequestOTP);
    on<AuthVerifyOTPEvent>(_onVerifyOTP);
    on<AuthCompleteRegistrationEvent>(_onCompleteRegistration);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthUserUpdatedEvent>(_onUserUpdated);
  }

  Future<void> _onCheckStatus(
      AuthCheckStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await _authRepository
          .getStoredUser()
          .timeout(const Duration(seconds: 5));
      if (user != null) {
        emit(AuthAuthenticatedState(user));
      } else {
        emit(AuthUnauthenticatedState());
      }
    } catch (e) {
      print('AuthCheckStatus error: $e');
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onRequestOTP(
      AuthRequestOTPEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      await _authRepository.requestOTP(event.phoneNumber);
      emit(AuthOTPSentState(event.phoneNumber));
    } catch (e) {
      print('RequestOTP error: $e');
      emit(AuthOTPErrorState('Failed to send code. Check your connection.'));
    }
  }

  Future<void> _onVerifyOTP(
      AuthVerifyOTPEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final result =
          await _authRepository.verifyOTP(event.phoneNumber, event.code);
      print('OTP verified. isNewUser: ${result.isNewUser}');
      if (result.isNewUser) {
        emit(AuthNeedsRegistrationState(event.phoneNumber));
      } else {
        emit(AuthAuthenticatedState(result.user));
      }
    } catch (e, stack) {
      print('VerifyOTP error: $e');
      print('Stack: $stack');
      emit(AuthOTPErrorState('Verification failed: $e'));
    }
  }

  Future<void> _onCompleteRegistration(
      AuthCompleteRegistrationEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final user = await _authRepository.completeRegistration(event.data);
      emit(AuthAuthenticatedState(user));
    } catch (e) {
      print('CompleteRegistration error: $e');
      emit(AuthErrorState('Registration failed: $e'));
    }
  }

  Future<void> _onLogout(
      AuthLogoutEvent event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(AuthUnauthenticatedState());
  }

  void _onUserUpdated(
      AuthUserUpdatedEvent event, Emitter<AuthState> emit) {
    emit(AuthAuthenticatedState(event.user));
  }
}
