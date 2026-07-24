import 'package:flutter/material.dart';

class AppConstants {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGold = Color(0xFFFFD600);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF43A047);

  // App Info
  static const String appName = 'Kazi';
  static const String tagline = 'Work Starts Here';
  static const String version = '1.0.0+1';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String applicationsCollection = 'applications';
  static const String transactionsCollection = 'transactions';
  static const String walletsCollection = 'wallets';
  static const String ratingsCollection = 'ratings';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  static const String checkinsCollection = 'checkins';

  // Roles
  static const String roleEmployer = 'employer';
  static const String roleJobseeker = 'jobseeker';

  // Job Statuses
  static const String statusOpen = 'open';
  static const String statusHired = 'hired';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Application Statuses
  static const String appStatusPending = 'pending';
  static const String appStatusAccepted = 'accepted';
  static const String appStatusDeclined = 'declined';

  // Transaction Types
  static const String txEarning = 'earning';
  static const String txWithdrawal = 'withdrawal';

  // Rating Types
  static const String ratingEmployerToWorker = 'employer_to_worker';
  static const String ratingWorkerToEmployer = 'worker_to_employer';

  // Commission Structure
  static const double employerFeePercent = 0.10; // 10%
  static const double workerFeePercent = 0.05; // 5%
  static const double platformFeePercent = 0.15; // 15%

  // Location
  static const double defaultSearchRadius = 5.0; // km
  static const List<double> searchRadii = [1, 3, 5, 10, 50];
  static const double nairobiLat = -1.2921;
  static const double nairobiLng = 36.8219;

  // Job Categories
  static const List<String> jobCategories = [
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Delivery',
    'Security',
    'Cooking',
    'Childcare',
    'Painting',
    'Carpentry',
    'Gardening',
    'Driving',
    'Events',
    'Casual Labour',
  ];

  // Nairobi Neighborhoods
  static const List<String> nairobiNeighborhoods = [
    'Westlands',
    'CBD',
    'Kilimani',
    'Karen',
    'Eastlands',
    'Kasarani',
    'Lavington',
    'Parklands',
    'Thika Rd',
    'Kileleshwa',
    'Langata',
    'Hurlingham',
    'Kensington',
    'Spring Valley',
    'Muthaiga',
    'Runda',
    'Gigiri',
    'Loresho',
    'Kitisuru',
  ];

  // Key names in SharedPreferences
  static const String prefFirstLaunch = 'first_launch';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefUserRole = 'user_role';
  static const String prefLanguage = 'preferred_language';
  static const String prefThemeMode = 'preferred_theme_mode';
  static const String prefSearchRadius = 'preferred_search_radius';

  // Phone validation
  static const int phoneLength = 9;
  static const String phonePrefix = '+254';
  static final RegExp phoneRegex = RegExp(r'^\d{9}$');

  // Notification Channels
  static const String notificationChannelId = 'kazi_notifications';
  static const String notificationChannelName = 'Kazi Notifications';

  // Limits
  static const int maxRequirements = 10;
  static const int maxBioLength = 150;
  static const int maxReviewLength = 500;
  static const int maxJobsPerPage = 20;
  static const int maxTransactionsPerPage = 50;

  // Public support contact. Supply with:
  // flutter run --dart-define=SUPPORT_WHATSAPP=2547XXXXXXXX
  static const String supportWhatsAppNumber = String.fromEnvironment(
    'SUPPORT_WHATSAPP',
  );
}
