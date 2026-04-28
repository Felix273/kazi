class UserModel {
  final String id;
  final String phoneNumber;
  final String? email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String userType;
  final String? profilePhoto;
  final String? bio;
  final String? locationName;
  final String verificationStatus;
  final bool isVerified;
  final double averageRating;
  final int totalReviews;
  final int totalJobsCompleted;
  final bool isOnline;
  final WorkerProfileModel? workerProfile;
  final EmployerProfileModel? employerProfile;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.userType,
    this.profilePhoto,
    this.bio,
    this.locationName,
    required this.verificationStatus,
    required this.isVerified,
    required this.averageRating,
    required this.totalReviews,
    required this.totalJobsCompleted,
    required this.isOnline,
    this.workerProfile,
    this.employerProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      userType: json['user_type'] as String? ?? 'worker',
      profilePhoto: json['profile_photo'] as String?,
      bio: json['bio'] as String?,
      locationName: json['location_name'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'unverified',
      isVerified: json['is_verified'] as bool? ?? false,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      totalJobsCompleted: json['total_jobs_completed'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      workerProfile: json['worker_profile'] != null
          ? WorkerProfileModel.fromJson(json['worker_profile'])
          : null,
      employerProfile: json['employer_profile'] != null
          ? EmployerProfileModel.fromJson(json['employer_profile'])
          : null,
    );
  }

  bool get isWorker => userType == 'worker' || userType == 'both';
  bool get isEmployer => userType == 'employer' || userType == 'both';
  bool get needsOnboarding => firstName.isEmpty;
}

class WorkerProfileModel {
  final bool isAvailable;
  final double? hourlyRate;
  final List<SkillModel> skills;
  final int experienceYears;
  final bool isSubscribed;

  const WorkerProfileModel({
    required this.isAvailable,
    this.hourlyRate,
    required this.skills,
    required this.experienceYears,
    required this.isSubscribed,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    return WorkerProfileModel(
      isAvailable: json['is_available'] as bool? ?? true,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => SkillModel.fromJson(s))
              .toList() ??
          [],
      experienceYears: json['experience_years'] as int? ?? 0,
      isSubscribed: json['is_subscribed'] as bool? ?? false,
    );
  }
}

class EmployerProfileModel {
  final String companyName;
  final String companyDescription;
  final bool isBusiness;

  const EmployerProfileModel({
    required this.companyName,
    required this.companyDescription,
    required this.isBusiness,
  });

  factory EmployerProfileModel.fromJson(Map<String, dynamic> json) {
    return EmployerProfileModel(
      companyName: json['company_name'] as String? ?? '',
      companyDescription: json['company_description'] as String? ?? '',
      isBusiness: json['is_business'] as bool? ?? false,
    );
  }
}

class SkillModel {
  final int id;
  final String name;
  final String category;
  final String? icon;

  const SkillModel({
    required this.id,
    required this.name,
    required this.category,
    this.icon,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String?,
    );
  }
}
