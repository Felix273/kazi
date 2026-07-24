import 'package:cloud_firestore/cloud_firestore.dart';

enum RatingType { employerToWorker, workerToEmployer }

class RatingModel {
  final String id;
  final String jobId;
  final String reviewerId;
  final String revieweeId;
  final int stars;
  final String comment;
  final RatingType type;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.revieweeId,
    required this.stars,
    required this.comment,
    required this.type,
    required this.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map, String id) {
    final typeStr = map['type'] as String? ?? 'employer_to_worker';
    final type = typeStr == 'worker_to_employer'
        ? RatingType.workerToEmployer
        : RatingType.employerToWorker;

    return RatingModel(
      id: id,
      jobId: map['jobId'] as String? ?? '',
      reviewerId: map['reviewerId'] as String? ?? '',
      revieweeId: map['revieweeId'] as String? ?? '',
      stars: map['stars'] as int? ?? 0,
      comment: map['comment'] as String? ?? '',
      type: type,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'stars': stars,
      'comment': comment,
      'type': type == RatingType.workerToEmployer
          ? 'worker_to_employer'
          : 'employer_to_worker',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
