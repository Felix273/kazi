import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Initialize analytics
  static Future<void> initialize() async {
    // Set analytics collection to enabled
    await _analytics.setAnalyticsCollectionEnabled(true);

    // Set default session timeout
    await _analytics.setSessionTimeoutDuration(const Duration(minutes: 30));

    debugPrint('Analytics initialized');
  }

  /// Log a screen view event
  static Future<void> logScreenView({required String screenName}) async {
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {'screen_name': screenName, 'screen_class': screenName},
    );
  }

  /// Log user registration/onboarding completion
  static Future<void> logOnboardingCompleted({required String role}) async {
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {
        'role': role, // 'employer' or 'jobseeker'
      },
    );
  }

  /// Log role selection
  static Future<void> logRoleSelected({required String role}) async {
    await _analytics.logEvent(
      name: 'role_selected',
      parameters: {'role': role},
    );
  }

  /// Log first job post
  static Future<void> logFirstJobPosted({
    required String jobId,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'first_job_posted',
      parameters: {'job_id': jobId, 'category': category},
    );
  }

  /// Log job posted event
  static Future<void> logJobPosted({
    required String jobId,
    required String category,
    required int salary,
  }) async {
    await _analytics.logEvent(
      name: 'job_posted',
      parameters: {'job_id': jobId, 'category': category, 'salary_kes': salary},
    );
  }

  /// Log job application
  static Future<void> logJobApplied({
    required String jobId,
    required String workerId,
  }) async {
    await _analytics.logEvent(
      name: 'first_application',
      parameters: {'job_id': jobId, 'worker_id': workerId},
    );
  }

  /// Log first payment received
  static Future<void> logFirstPayment({
    required String jobId,
    required double amount,
  }) async {
    await _analytics.logEvent(
      name: 'first_payment',
      parameters: {'job_id': jobId, 'amount_kes': amount},
    );
  }

  /// Log wallet withdrawal
  static Future<void> logWalletWithdrawal({
    required double amount,
    required String method,
  }) async {
    await _analytics.logEvent(
      name: 'wallet_withdrawal',
      parameters: {
        'amount_kes': amount,
        'method': method, // 'mpesa', 'bank', etc.
      },
    );
  }

  /// Log payment initiated via M-Pesa
  static Future<void> logPaymentInitiated({
    required String jobId,
    required double amount,
    required String type, // 'job_payment', 'boost', etc.
  }) async {
    await _analytics.logEvent(
      name: 'payment_initiated',
      parameters: {'job_id': jobId, 'amount_kes': amount, 'type': type},
    );
  }

  /// Log successful M-Pesa payment
  static Future<void> logPaymentSuccess({
    required String jobId,
    required double amount,
    required String type,
  }) async {
    await _analytics.logEvent(
      name: 'payment_success',
      parameters: {'job_id': jobId, 'amount_kes': amount, 'type': type},
    );
  }

  /// Log failed M-Pesa payment
  static Future<void> logPaymentFailed({
    required String jobId,
    required String error,
  }) async {
    await _analytics.logEvent(
      name: 'payment_failed',
      parameters: {'job_id': jobId, 'error_message': error},
    );
  }

  /// Log boost purchase
  static Future<void> logBoostPurchased({
    required String jobId,
    required String tier,
    required int amount,
  }) async {
    await _analytics.logEvent(
      name: 'boost_purchased',
      parameters: {'job_id': jobId, 'tier': tier, 'amount_kes': amount},
    );
  }

  /// Log dispute filed
  static Future<void> logDisputeFiled({
    required String disputeId,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'dispute_filed',
      parameters: {'dispute_id': disputeId, 'reason': reason},
    );
  }

  /// Log rating submitted
  static Future<void> logRatingSubmitted({
    required String jobId,
    required double rating,
  }) async {
    await _analytics.logEvent(
      name: 'rating_submitted',
      parameters: {'job_id': jobId, 'rating': rating},
    );
  }

  /// Set user properties for analytics
  static Future<void> setUserProperties({
    required String userId,
    required String role,
    required String neighborhood,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'role', value: role);
    await _analytics.setUserProperty(name: 'neighborhood', value: neighborhood);
  }

  /// Log custom event
  static Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Get analytics observer for GoRouter
  static FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }
}
