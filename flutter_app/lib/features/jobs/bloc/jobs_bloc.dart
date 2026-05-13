import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/api_client.dart';
import '../models/job_model.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class JobsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadJobsEvent extends JobsEvent {
  final String category;
  LoadJobsEvent({this.category = 'all'});
  @override
  List<Object?> get props => [category];
}

class RefreshJobsEvent extends JobsEvent {
  final String category;
  RefreshJobsEvent({this.category = 'all'});
  @override
  List<Object?> get props => [category];
}

class FilterByCategoryEvent extends JobsEvent {
  final String category;
  FilterByCategoryEvent(this.category);
  @override
  List<Object?> get props => [category];
}

class LoadMoreJobsEvent extends JobsEvent {
  final String category;
  LoadMoreJobsEvent({this.category = 'all'});
  @override
  List<Object?> get props => [category];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class JobsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class JobsInitialState extends JobsState {}

class JobsLoadingState extends JobsState {}

class JobsRefreshingState extends JobsState {
  final List<JobModel> currentJobs;
  final String category;
  JobsRefreshingState(this.currentJobs, this.category);
  @override
  List<Object?> get props => [currentJobs, category];
}

class JobsLoadedState extends JobsState {
  final List<JobModel> jobs;
  final String category;
  final bool hasMore;
  final int currentPage;

  JobsLoadedState({
    required this.jobs,
    required this.category,
    this.hasMore = false,
    this.currentPage = 1,
  });

  JobsLoadedState copyWith({
    List<JobModel>? jobs,
    String? category,
    bool? hasMore,
    int? currentPage,
  }) {
    return JobsLoadedState(
      jobs: jobs ?? this.jobs,
      category: category ?? this.category,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [jobs, category, hasMore, currentPage];
}

class JobsErrorState extends JobsState {
  final String message;
  JobsErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class JobsBloc extends Bloc<JobsEvent, JobsState> {
  final ApiClient _api;

  JobsBloc(this._api) : super(JobsInitialState()) {
    on<LoadJobsEvent>(_onLoadJobs);
    on<RefreshJobsEvent>(_onRefreshJobs);
    on<FilterByCategoryEvent>(_onFilterByCategory);
    on<LoadMoreJobsEvent>(_onLoadMoreJobs);
  }

  Future<void> _onLoadJobs(LoadJobsEvent event, Emitter<JobsState> emit) async {
    emit(JobsLoadingState());
    try {
      final response = await _api.getJobs(
        filters: event.category != 'all' ? {'category': event.category} : null,
      );
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
      final jobs = results.map((j) => JobModel.fromJson(j)).toList();
      emit(JobsLoadedState(
        jobs: jobs,
        category: event.category,
        hasMore: data['next'] != null,
        currentPage: 1,
      ));
    } catch (e) {
      emit(JobsErrorState('Failed to load jobs. Check your connection.'));
    }
  }

  Future<void> _onRefreshJobs(RefreshJobsEvent event, Emitter<JobsState> emit) async {
    final current = state;
    if (current is JobsLoadedState) {
      emit(JobsRefreshingState(current.jobs, current.category));
    }
    try {
      final response = await _api.getJobs(
        filters: event.category != 'all' ? {'category': event.category} : null,
      );
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
      final jobs = results.map((j) => JobModel.fromJson(j)).toList();
      emit(JobsLoadedState(
        jobs: jobs,
        category: event.category,
        hasMore: data['next'] != null,
        currentPage: 1,
      ));
    } catch (e) {
      emit(JobsErrorState('Failed to refresh jobs.'));
    }
  }

  Future<void> _onFilterByCategory(FilterByCategoryEvent event, Emitter<JobsState> emit) async {
    emit(JobsLoadingState());
    try {
      final response = await _api.getJobs(
        filters: event.category != 'all' ? {'category': event.category} : null,
      );
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
      final jobs = results.map((j) => JobModel.fromJson(j)).toList();
      emit(JobsLoadedState(
        jobs: jobs,
        category: event.category,
        hasMore: data['next'] != null,
        currentPage: 1,
      ));
    } catch (e) {
      emit(JobsErrorState('Failed to filter jobs.'));
    }
  }

  Future<void> _onLoadMoreJobs(LoadMoreJobsEvent event, Emitter<JobsState> emit) async {
    final current = state;
    if (current is! JobsLoadedState || !current.hasMore) return;

    try {
      final nextPage = current.currentPage + 1;
      final response = await _api.getJobs(filters: {
        if (event.category != 'all') 'category': event.category,
        'page': nextPage,
      });
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      final newJobs = results.map((j) => JobModel.fromJson(j)).toList();
      emit(current.copyWith(
        jobs: [...current.jobs, ...newJobs],
        hasMore: data['next'] != null,
        currentPage: nextPage,
      ));
    } catch (e) {
      // Keep current state on load more failure
    }
  }
}
