import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role; // 'employer' or 'jobseeker'
  final String? email;
  final String? photoUrl;
  final String? neighborhood;
  final double? lat;
  final double? lng;
  final List<String>? skills;
  final String? bio;
  final String verificationStatus;
  final bool isVerified;
  final double averageRating;
  final int totalJobsCompleted;
  final bool isAvailable;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.photoUrl,
    this.neighborhood,
    this.lat,
    this.lng,
    this.skills,
    this.bio,
    this.verificationStatus = 'not_submitted',
    this.isVerified = false,
    this.averageRating = 0.0,
    this.totalJobsCompleted = 0,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? 'jobseeker',
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      neighborhood: map['neighborhood'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      skills: List<String>.from(map['skills'] ?? []),
      bio: map['bio'] as String?,
      verificationStatus:
          map['verificationStatus'] as String? ?? 'not_submitted',
      isVerified: map['isVerified'] as bool? ?? false,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalJobsCompleted: map['totalJobsCompleted'] as int? ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'email': email,
      'photoUrl': photoUrl,
      'neighborhood': neighborhood,
      'lat': lat,
      'lng': lng,
      'skills': skills,
      'bio': bio,
      'verificationStatus': verificationStatus,
      'isVerified': isVerified,
      'averageRating': averageRating,
      'totalJobsCompleted': totalJobsCompleted,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? role,
    String? email,
    String? photoUrl,
    String? neighborhood,
    double? lat,
    double? lng,
    List<String>? skills,
    String? bio,
    String? verificationStatus,
    bool? isVerified,
    double? averageRating,
    int? totalJobsCompleted,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      neighborhood: neighborhood ?? this.neighborhood,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isVerified: isVerified ?? this.isVerified,
      averageRating: averageRating ?? this.averageRating,
      totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
