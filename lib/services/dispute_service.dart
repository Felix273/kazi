import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DisputeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'africa-south1',
  );

  static Future<String> fileDispute({
    required String jobId,
    required String applicationId,
    required String reason,
    required String reasonLabel,
    required String description,
    required List<String> photoUrls,
  }) async {
    if (_auth.currentUser == null) throw StateError('User not authenticated.');
    try {
      final result = await _functions.httpsCallable('fileDispute').call({
        'jobId': jobId,
        'applicationId': applicationId,
        'reason': reason,
        'reasonLabel': reasonLabel,
        'description': description,
        'photoUrls': photoUrls,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return data['disputeId'] as String;
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Unable to file dispute.');
    }
  }

  static Stream<List<Map<String, dynamic>>> getUserDisputes(String userId) {
    return _firestore
        .collection('disputes')
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  static Stream<List<Map<String, dynamic>>> getJobDisputes(String jobId) {
    return _firestore
        .collection('disputes')
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  static Future<void> resolveDispute({
    required String disputeId,
    required String resolution,
    bool releasePayment = false,
  }) async {
    try {
      await _functions.httpsCallable('resolveDispute').call({
        'disputeId': disputeId,
        'resolution': resolution,
        'releasePayment': releasePayment,
      });
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Unable to resolve dispute.');
    }
  }
}
