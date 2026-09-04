import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  pending,
  paymentPending,
  accepted,
  inProgress,
  completed,
  declined,
  cancelled,
}

class ApplicationModel {
  final String id;
  final String jobId;
  final String workerId;
  final String workerName;
  final String workerPhoto;
  final double workerRating;
  final String workerNeighborhood;
  final List<String> skills;
  final String bio;
  final double distance;
  final int totalJobsCompleted;
  final ApplicationStatus status;
  final DateTime appliedAt;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.workerName,
    required this.workerPhoto,
    required this.workerRating,
    required this.workerNeighborhood,
    required this.skills,
    required this.bio,
    required this.distance,
    required this.totalJobsCompleted,
    required this.status,
    required this.appliedAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    final statusStr = map['status'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'payment_pending' => ApplicationStatus.paymentPending,
      'accepted' => ApplicationStatus.accepted,
      'in_progress' => ApplicationStatus.inProgress,
      'completed' => ApplicationStatus.completed,
      'declined' => ApplicationStatus.declined,
      'cancelled' => ApplicationStatus.cancelled,
      _ => ApplicationStatus.pending,
    };

    return ApplicationModel(
      id: id,
      jobId: map['jobId'] as String? ?? '',
      workerId: map['workerId'] as String? ?? '',
      workerName: map['workerName'] as String? ?? 'Worker',
      workerPhoto: map['workerPhoto'] as String? ?? '',
      workerRating: (map['workerRating'] as num?)?.toDouble() ?? 0.0,
      workerNeighborhood: map['workerNeighborhood'] as String? ?? 'Unknown',
      skills: List<String>.from(map['skills'] ?? []),
      bio: map['bio'] as String? ?? '',
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      totalJobsCompleted: map['totalJobsCompleted'] as int? ?? 0,
      status: status,
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'workerId': workerId,
      'workerName': workerName,
      'workerPhoto': workerPhoto,
      'workerRating': workerRating,
      'workerNeighborhood': workerNeighborhood,
      'skills': skills,
      'bio': bio,
      'distance': distance,
      'totalJobsCompleted': totalJobsCompleted,
      'status': switch (status) {
        ApplicationStatus.paymentPending => 'payment_pending',
        ApplicationStatus.accepted => 'accepted',
        ApplicationStatus.inProgress => 'in_progress',
        ApplicationStatus.completed => 'completed',
        ApplicationStatus.declined => 'declined',
        ApplicationStatus.cancelled => 'cancelled',
        ApplicationStatus.pending => 'pending',
      },
      'appliedAt': Timestamp.fromDate(appliedAt),
    };
  }
}
