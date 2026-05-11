import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/api_client.dart';

// Events
abstract class KYCEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitKYCEvent extends KYCEvent {
  final String idNumber;
  final String? idPhotoPath;

  SubmitKYCEvent({required this.idNumber, this.idPhotoPath});

  @override
  List<Object?> get props => [idNumber, idPhotoPath];
}

// States
abstract class KYCState extends Equatable {
  @override
  List<Object?> get props => [];
}

class KYCInitial extends KYCState {}
class KYCLoading extends KYCState {}
class KYCSuccess extends KYCState {
  final String message;
  KYCSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
class KYCError extends KYCState {
  final String error;
  KYCError(this.error);
  @override
  List<Object?> get props => [error];
}

// Bloc
class KYCBloc extends Bloc<KYCEvent, KYCState> {
  final ApiClient _apiClient;

  KYCBloc(this._apiClient) : super(KYCInitial()) {
    on<SubmitKYCEvent>((event, emit) async {
      emit(KYCLoading());
      try {
        final response = await _apiClient.submitKYC(
          idNumber: event.idNumber,
          idPhotoPath: event.idPhotoPath,
        );
        if (response.statusCode == 200) {
          emit(KYCSuccess(response.data['detail'] ?? 'KYC submitted successfully.'));
        } else {
          emit(KYCError(response.data['detail'] ?? 'Failed to submit KYC.'));
        }
      } catch (e) {
        emit(KYCError(e.toString()));
      }
    });
  }
}
