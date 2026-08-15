import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/complete_phone_profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/employer/boost_screen.dart';
import 'screens/employer/employer_dashboard.dart';
import 'screens/employer/employer_job_detail_screen.dart';
import 'screens/employer/post_job_screen.dart';
import 'screens/employer/view_applicants_screen.dart';
import 'screens/jobseeker/checkin_screen.dart';
import 'screens/jobseeker/job_detail_screen.dart';
import 'screens/jobseeker/jobseeker_home.dart';
import 'screens/jobseeker/my_applications_screen.dart';
import 'screens/jobseeker/profile_screen.dart';
import 'screens/jobseeker/wallet_screen.dart';
import 'screens/shared/chat_list_screen.dart';
import 'screens/shared/chat_screen.dart';
import 'screens/shared/dispute_screen.dart';
import 'screens/shared/notification_settings_screen.dart';
import 'screens/shared/onboarding_screen.dart';
import 'screens/shared/role_selection_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/shared/settings_screen.dart';
import 'screens/shared/splash_screen.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'utils/app_strings.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (error, stack) {
    debugPrint('Firebase startup initialization failed: $error\n$stack');
  }

  runApp(const ProviderScope(child: KaziApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeDeferredServices());
  });
}

Future<void> _initializeDeferredServices() async {
  try {
    await Future.wait([
      NotificationService.initialize(),
      AnalyticsService.initialize(),
    ]);
  } catch (error, stack) {
    debugPrint('Deferred service initialization failed: $error\n$stack');
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/auth/phone',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PhoneLoginScreen(role: extra?['role'] as String? ?? 'jobseeker');
      },
    ),
    GoRoute(
      path: '/auth/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return OtpScreen(
          verificationId: extra['verificationId'] as String? ?? '',
          phoneNumber: extra['phoneNumber'] as String? ?? '',
          role: extra['role'] as String? ?? 'jobseeker',
        );
      },
    ),
    GoRoute(
      path: '/auth/complete-profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CompletePhoneProfileScreen(
          role: extra?['role'] as String? ?? 'jobseeker',
        );
      },
    ),
    GoRoute(
      path: '/auth/register',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RegistrationScreen(
          role: extra?['role'] as String? ?? 'jobseeker',
        );
      },
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return LoginScreen(role: extra?['role'] as String? ?? 'jobseeker');
      },
    ),
    GoRoute(
      path: '/employer/home',
      builder: (context, state) => const EmployerDashboardScreen(),
    ),
    GoRoute(
      path: '/employer/post-job',
      builder: (context, state) => const PostJobScreen(),
    ),
    GoRoute(
      path: '/employer/job/:jobId',
      builder: (context, state) =>
          EmployerJobDetailScreen(jobId: state.pathParameters['jobId'] ?? ''),
    ),
    GoRoute(
      path: '/employer/job/:jobId/applicants',
      builder: (context, state) =>
          ViewApplicantsScreen(jobId: state.pathParameters['jobId'] ?? ''),
    ),
    GoRoute(
      path: '/employer/job/:jobId/boost',
      builder: (context, state) =>
          BoostScreen(jobId: state.pathParameters['jobId'] ?? ''),
    ),
    GoRoute(
      path: '/jobseeker/home',
      builder: (context, state) => const JobSeekerHomeScreen(),
    ),
    GoRoute(
      path: '/jobseeker/job/:jobId',
      builder: (context, state) =>
          JobDetailScreen(jobId: state.pathParameters['jobId'] ?? ''),
    ),
    GoRoute(
      path: '/jobseeker/applications',
      builder: (context, state) => const MyApplicationsScreen(),
    ),
    GoRoute(
      path: '/jobseeker/wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ProfileScreen(roleHint: extra?['role'] as String?);
      },
    ),
    GoRoute(
      path: '/jobseeker/profile',
      redirect: (context, state) => '/profile',
    ),
    GoRoute(
      path: '/jobseeker/checkin',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return CheckInScreen(
          jobId: extra['jobId'] as String? ?? '',
          jobTitle: extra['jobTitle'] as String? ?? '',
          jobLat: (extra['jobLat'] as num?)?.toDouble() ?? 0,
          jobLng: (extra['jobLng'] as num?)?.toDouble() ?? 0,
        );
      },
    ),
    GoRoute(path: '/jobseeker/chat', redirect: (context, state) => '/chat'),
    GoRoute(
      path: '/jobseeker/chat/:chatId',
      redirect: (context, state) => '/chat/${state.pathParameters['chatId']}',
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ChatListScreen(roleHint: extra?['role'] as String?);
      },
    ),
    GoRoute(
      path: '/chat/:chatId',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return ChatScreen(
          chatId: state.pathParameters['chatId'] ?? '',
          otherUserId: extra['otherUserId'] as String? ?? '',
          otherUserName: extra['otherUserName'] as String? ?? 'User',
          otherUserPhoto: extra['otherUserPhoto'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/dispute',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return DisputeScreen(
          jobId: extra['jobId'] as String? ?? '',
          applicationId: extra['applicationId'] as String? ?? '',
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: Center(
      child: Text(state.error?.toString() ?? AppStrings.errorUnknown),
    ),
  ),
);

class KaziApp extends ConsumerWidget {
  const KaziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: switch (themeMode) {
        ThemeModeOption.system => ThemeMode.system,
        ThemeModeOption.light => ThemeMode.light,
        ThemeModeOption.dark => ThemeMode.dark,
      },
      routerConfig: appRouter,
    );
  }
}
