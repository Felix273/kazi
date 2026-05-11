import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/api_client.dart';

// Events
abstract class JobDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchJobDetailEvent extends JobDetailEvent {
  final String jobId;
  FetchJobDetailEvent(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

class ApplyForJobEvent extends JobDetailEvent {
  final String jobId;
  final String? coverNote;
  final double? proposedRate;

  ApplyForJobEvent({required this.jobId, this.coverNote, this.proposedRate});

  @override
  List<Object?> get props => [jobId, coverNote, proposedRate];
}

// States
abstract class JobDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class JobDetailInitial extends JobDetailState {}
class JobDetailLoading extends JobDetailState {}
class JobDetailLoaded extends JobDetailState {
  final Map<String, dynamic> job;
  JobDetailLoaded(this.job);
  @override
  List<Object?> get props => [job];
}
class JobDetailError extends JobDetailState {
  final String error;
  JobDetailError(this.error);
  @override
  List<Object?> get props => [error];
}

class JobApplying extends JobDetailState {}
class JobAppliedSuccess extends JobDetailState {}

// Bloc
class JobDetailBloc extends Bloc<JobDetailEvent, JobDetailState> {
  final ApiClient _apiClient;

  JobDetailBloc(this._apiClient) : super(JobDetailInitial()) {
    on<FetchJobDetailEvent>((event, emit) async {
      emit(JobDetailLoading());
      try {
        final response = await _apiClient.getJob(event.jobId);
        emit(JobDetailLoaded(response.data));
      } catch (e) {
        emit(JobDetailError(e.toString()));
      }
    });

    on<ApplyForJobEvent>((event, emit) async {
      final currentState = state;
      if (currentState is JobDetailLoaded) {
        emit(JobApplying());
        try {
          await _apiClient.applyForJob(
            event.jobId,
            coverNote: event.coverNote,
            proposedRate: event.proposedRate,
          );
          emit(JobAppliedSuccess());
          // Refresh job details
          add(FetchJobDetailEvent(event.jobId));
        } catch (e) {
          emit(JobDetailError(e.toString()));
          emit(currentState); // Return to loaded state
        }
      }
    });
  }
}
