import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/phone_entry_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/registration_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/jobs/screens/job_list_screen.dart';
import '../features/jobs/screens/job_detail_screen.dart';
import '../features/jobs/screens/post_job_screen.dart';
import '../features/jobs/screens/job_applications_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/kyc_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';

class AppRouter {
  late final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneEntryScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OTPScreen(phoneNumber: state.extra as String),
      ),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegistrationScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const JobListScreen()),
          GoRoute(
            path: '/jobs/:jobId',
            builder: (_, state) => JobDetailScreen(jobId: state.pathParameters['jobId']!),
          ),
          GoRoute(path: '/post-job', builder: (_, __) => const PostJobScreen()),
          GoRoute(
            path: '/jobs/:jobId/applications',
            builder: (_, state) => JobApplicationsScreen(jobId: state.pathParameters['jobId']!),
          ),
          GoRoute(
            path: '/chat/:roomId',
            builder: (_, state) => ChatScreen(roomId: state.pathParameters['roomId']!),
          ),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
          GoRoute(path: '/profile/kyc', builder: (_, __) => const KycScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
