import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Global navigator key for notification routing
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  // Initialize FCM on app startup
  static Future<void> initialize() async {
    if (_initialized) return;

    // Request permissions (iOS)
    await _requestPermissions();

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onMessageReceived);

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    // Check if app was opened from a terminated state via notification
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationNavigation(message);
      }
    });

    _initialized = true;
  }

  static Future<void> syncTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveTokenToFirestore(token);
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  // Save FCM token to user's Firestore document
  static Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Handle foreground message
  static Future<void> _onMessageReceived(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await sendLocalNotification(
      title: notification.title ?? 'Kazi',
      body: notification.body ?? '',
    );
  }

  // Handle notification tap when app is in background
  static void _onMessageOpened(RemoteMessage message) {
    debugPrint('Notification opened: ${message.notification?.title}');
    _handleNotificationNavigation(message);
  }

  // Navigate based on notification data
  static void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    debugPrint('Navigating for notification type: $type');

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'checkin':
      case 'job_completed':
      case 'KAZI_HIRED':
      case 'KAZI_PAYMENT':
        context.go('/jobseeker/home');
        break;
      case 'chat_message':
        final chatId = data['chatId'] as String?;
        context.go(chatId == null ? '/chat' : '/chat/$chatId');
        break;
      case 'rating_prompt':
        context.go('/jobseeker/home');
        break;
      case 'dispute_filed':
      case 'new_dispute':
        context.go('/settings');
        break;
      case 'KAZI_NEW_JOB':
        context.go('/jobseeker/home');
        break;
      default:
        context.go('/jobseeker/home');
        break;
    }
  }

  // Subscribe to topic (for broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Get current FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Delete the device token and remove the server-side token on logout.
  static Future<void> deleteToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await _messaging.deleteToken();
  }

  // Show a foreground in-app notification.
  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? sound,
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('Notification: $title - $body');
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
