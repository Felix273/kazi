import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/api_client.dart';

// Events
abstract class JobApplicationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchJobApplicationsEvent extends JobApplicationsEvent {
  final String jobId;
  FetchJobApplicationsEvent(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

class AcceptApplicationEvent extends JobApplicationsEvent {
  final String jobId;
  final String applicationId;

  AcceptApplicationEvent({required this.jobId, required this.applicationId});

  @override
  List<Object?> get props => [jobId, applicationId];
}

// States
abstract class JobApplicationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class JobApplicationsInitial extends JobApplicationsState {}
class JobApplicationsLoading extends JobApplicationsState {}
class JobApplicationsLoaded extends JobApplicationsState {
  final List<dynamic> applications;
  JobApplicationsLoaded(this.applications);
  @override
  List<Object?> get props => [applications];
}
class JobApplicationsError extends JobApplicationsState {
  final String error;
  JobApplicationsError(this.error);
  @override
  List<Object?> get props => [error];
}

class AcceptApplicationLoading extends JobApplicationsState {}
class AcceptApplicationSuccess extends JobApplicationsState {
  final String chatRoomId;
  AcceptApplicationSuccess(this.chatRoomId);
  @override
  List<Object?> get props => [chatRoomId];
}

// Bloc
class JobApplicationsBloc extends Bloc<JobApplicationsEvent, JobApplicationsState> {
  final ApiClient _apiClient;

  JobApplicationsBloc(this._apiClient) : super(JobApplicationsInitial()) {
    on<FetchJobApplicationsEvent>((event, emit) async {
      emit(JobApplicationsLoading());
      try {
        final response = await _apiClient.getJobApplications(event.jobId);
        emit(JobApplicationsLoaded(response.data));
      } catch (e) {
        emit(JobApplicationsError(e.toString()));
      }
    });

    on<AcceptApplicationEvent>((event, emit) async {
      emit(AcceptApplicationLoading());
      try {
        final response = await _apiClient.acceptApplication(event.jobId, event.applicationId);
        emit(AcceptApplicationSuccess(response.data['chat_room_id']));
      } catch (e) {
        emit(JobApplicationsError(e.toString()));
      }
    });
  }
}
