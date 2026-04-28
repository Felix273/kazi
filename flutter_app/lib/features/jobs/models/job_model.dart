import '../../profile/models/user_model.dart';

class JobModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final double budget;
  final bool isNegotiable;
  final int durationValue;
  final String durationUnit;
  final String locationAddress;
  final double? latitude;
  final double? longitude;
  final String employerId;
  final String employerName;
  final String? employerPhoto;
  final String? assignedWorkerId;
  final int applicationCount;
  final DateTime createdAt;
  final DateTime? startsAt;
  final List<SkillModel> requiredSkills;
  final double? distanceKm;

  const JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.budget,
    required this.isNegotiable,
    required this.durationValue,
    required this.durationUnit,
    required this.locationAddress,
    this.latitude,
    this.longitude,
    required this.employerId,
    required this.employerName,
    this.employerPhoto,
    this.assignedWorkerId,
    required this.applicationCount,
    required this.createdAt,
    this.startsAt,
    required this.requiredSkills,
    this.distanceKm,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      budget: (json['budget'] as num).toDouble(),
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      durationValue: json['duration_value'] as int,
      durationUnit: json['duration_unit'] as String,
      locationAddress: json['location_address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      employerId: json['employer_id'] as String,
      employerName: json['employer_name'] as String? ?? '',
      employerPhoto: json['employer_photo'] as String?,
      assignedWorkerId: json['assigned_worker_id'] as String?,
      applicationCount: json['application_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at']) : null,
      requiredSkills: (json['required_skills'] as List<dynamic>?)
              ?.map((s) => SkillModel.fromJson(s))
              .toList() ??
          [],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  String get durationDisplay =>
      '$durationValue ${durationValue == 1 ? durationUnit.replaceAll('s', '') : durationUnit}';

  String get budgetDisplay => 'KES ${budget.toStringAsFixed(0)}';

  bool get isOpen => status == 'open';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
}

class JobApplicationModel {
  final String id;
  final String jobId;
  final String workerId;
  final String workerName;
  final String? workerPhoto;
  final double workerRating;
  final int workerTotalJobs;
  final bool workerIsVerified;
  final String status;
  final String? coverNote;
  final double? proposedRate;
  final DateTime createdAt;

  const JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.workerName,
    this.workerPhoto,
    required this.workerRating,
    required this.workerTotalJobs,
    required this.workerIsVerified,
    required this.status,
    this.coverNote,
    this.proposedRate,
    required this.createdAt,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['id'] as String,
      jobId: json['job'] as String,
      workerId: json['worker_id'] as String,
      workerName: json['worker_name'] as String? ?? '',
      workerPhoto: json['worker_photo'] as String?,
      workerRating: (json['worker_rating'] as num?)?.toDouble() ?? 0.0,
      workerTotalJobs: json['worker_total_jobs'] as int? ?? 0,
      workerIsVerified: json['worker_is_verified'] as bool? ?? false,
      status: json['status'] as String,
      coverNote: json['cover_note'] as String?,
      proposedRate: (json['proposed_rate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
