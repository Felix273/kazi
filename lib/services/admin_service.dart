import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'africa-south1',
  );

  static Future<Map<String, dynamic>> getAdminMetrics() async {
    final usersCountSnap = await _firestore.collection('users').count().get();
    final jobsCountSnap =
        await _firestore
            .collection('jobs')
            .where('status', isEqualTo: 'open')
            .count()
            .get();
    final disputesCountSnap =
        await _firestore
            .collection('disputes')
            .where('status', isEqualTo: 'open')
            .count()
            .get();
    final pendingVerificationsSnap =
        await _firestore
            .collection('identityVerifications')
            .where('status', isEqualTo: 'pending')
            .count()
            .get();

    return {
      'totalUsers': usersCountSnap.count ?? 0,
      'openJobs': jobsCountSnap.count ?? 0,
      'openDisputes': disputesCountSnap.count ?? 0,
      'pendingVerifications': pendingVerificationsSnap.count ?? 0,
    };
  }

  static Stream<List<Map<String, dynamic>>> getPendingVerifications() {
    return _firestore
        .collection('identityVerifications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  static Stream<List<Map<String, dynamic>>> getAllDisputes() {
    return _firestore
        .collection('disputes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  static Stream<List<Map<String, dynamic>>> getAdminAlerts() {
    return _firestore
        .collection('adminAlerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  static Future<void> reviewUserVerification({
    required String userId,
    required bool approved,
    String? rejectionReason,
  }) async {
    try {
      await _functions.httpsCallable('reviewUserVerification').call({
        'userId': userId,
        'approved': approved,
        'rejectionReason': rejectionReason,
      });
    } on FirebaseFunctionsException catch (error) {
      throw StateError(
        error.message ?? 'Failed to review user identity verification.',
      );
    }
  }

  static Future<Map<String, dynamic>> sendBroadcastNotification({
    required String title,
    required String body,
  }) async {
    try {
      final userDocs =
          await _firestore
              .collection('users')
              .where('fcmToken', isNull: false)
              .limit(500)
              .get();

      final tokens =
          userDocs.docs
              .map((doc) => doc.data()['fcmToken'] as String?)
              .whereType<String>()
              .where((token) => token.isNotEmpty)
              .toList();

      if (tokens.isEmpty) {
        return {'successCount': 0, 'failureCount': 0};
      }

      final result = await _functions
          .httpsCallable('sendBulkNotification')
          .call({'title': title, 'body': body, 'tokens': tokens});

      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw StateError(
        error.message ?? 'Failed to send broadcast notification.',
      );
    }
  }
}
