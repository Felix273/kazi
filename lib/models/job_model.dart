import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<String> requirements;
  final double salaryKES;
  final int duration;
  final String durationType;
  final DateTime startDate;
  final bool isUrgent;
  final String employerId;
  final String employerName;
  final String employerPhone;
  final GeoPoint location;
  final String neighborhood;
  final String geohash;
  final String status;
  final int applicantCount;
  final DateTime createdAt;
  final DateTime? hiredAt;
  final DateTime? completedAt;
  final String? hiredWorkerId;
  final String? hiredWorkerName;
  final double? distanceKm;

  const JobModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.requirements,
    required this.salaryKES,
    required this.duration,
    required this.durationType,
    required this.startDate,
    required this.isUrgent,
    required this.employerId,
    required this.employerName,
    required this.employerPhone,
    required this.location,
    required this.neighborhood,
    required this.geohash,
    required this.status,
    required this.applicantCount,
    required this.createdAt,
    this.hiredAt,
    this.completedAt,
    this.hiredWorkerId,
    this.hiredWorkerName,
    this.distanceKm,
  });

  factory JobModel.fromMap(
    Map<String, dynamic> map,
    String id, {
    double? distanceKm,
  }) {
    return JobModel(
      id: id,
      title: map['title'] as String? ?? 'Job',
      category: map['category'] as String? ?? 'Cleaning',
      description: map['description'] as String? ?? '',
      requirements: List<String>.from(map['requirements'] ?? const []),
      salaryKES: (map['salaryKES'] as num?)?.toDouble() ?? 0,
      duration: (map['duration'] as num?)?.toInt() ?? 1,
      durationType: map['durationType'] as String? ?? 'hours',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUrgent: map['isUrgent'] as bool? ?? false,
      employerId: map['employerId'] as String? ?? '',
      employerName: map['employerName'] as String? ?? 'Employer',
      employerPhone: map['employerPhone'] as String? ?? '',
      location: map['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      neighborhood: map['neighborhood'] as String? ?? 'Unknown',
      geohash: map['geohash'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      applicantCount: (map['applicantCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hiredAt: (map['hiredAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      hiredWorkerId: map['hiredWorkerId'] as String?,
      hiredWorkerName: map['hiredWorkerName'] as String?,
      distanceKm: distanceKm ?? (map['distanceKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'requirements': requirements,
      'salaryKES': salaryKES,
      'employerPaysKES': employerPays,
      'workerEarnsKES': workerEarns,
      'platformFeeKES': platformFee,
      'duration': duration,
      'durationType': durationType,
      'startDate': Timestamp.fromDate(startDate),
      'isUrgent': isUrgent,
      'employerId': employerId,
      'employerName': employerName,
      'employerPhone': employerPhone,
      'location': location,
      'neighborhood': neighborhood,
      'geohash': geohash,
      'status': status,
      'applicantCount': applicantCount,
      'createdAt': Timestamp.fromDate(createdAt),
      if (hiredAt != null) 'hiredAt': Timestamp.fromDate(hiredAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (hiredWorkerId != null) 'hiredWorkerId': hiredWorkerId,
      if (hiredWorkerName != null) 'hiredWorkerName': hiredWorkerName,
    };
  }

  JobModel copyWith({
    String? title,
    String? category,
    String? description,
    List<String>? requirements,
    double? salaryKES,
    int? duration,
    String? durationType,
    DateTime? startDate,
    bool? isUrgent,
    String? employerId,
    String? employerName,
    String? employerPhone,
    GeoPoint? location,
    String? neighborhood,
    String? geohash,
    String? status,
    int? applicantCount,
    DateTime? createdAt,
    DateTime? hiredAt,
    DateTime? completedAt,
    String? hiredWorkerId,
    String? hiredWorkerName,
    double? distanceKm,
  }) {
    return JobModel(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      salaryKES: salaryKES ?? this.salaryKES,
      duration: duration ?? this.duration,
      durationType: durationType ?? this.durationType,
      startDate: startDate ?? this.startDate,
      isUrgent: isUrgent ?? this.isUrgent,
      employerId: employerId ?? this.employerId,
      employerName: employerName ?? this.employerName,
      employerPhone: employerPhone ?? this.employerPhone,
      location: location ?? this.location,
      neighborhood: neighborhood ?? this.neighborhood,
      geohash: geohash ?? this.geohash,
      status: status ?? this.status,
      applicantCount: applicantCount ?? this.applicantCount,
      createdAt: createdAt ?? this.createdAt,
      hiredAt: hiredAt ?? this.hiredAt,
      completedAt: completedAt ?? this.completedAt,
      hiredWorkerId: hiredWorkerId ?? this.hiredWorkerId,
      hiredWorkerName: hiredWorkerName ?? this.hiredWorkerName,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  double get employerPays => salaryKES * 1.10;
  double get workerEarns => salaryKES * 0.95;
  double get platformFee => salaryKES * 0.15;
}
