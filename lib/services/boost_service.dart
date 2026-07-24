import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BoostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'africa-south1',
  );

  static Future<Map<String, dynamic>> boostJob({
    required String jobId,
    required String tier,
    required int amount,
  }) async {
    final expectedAmount = switch (tier) {
      'Basic' => 50,
      'Standard' => 100,
      'Premium' => 200,
      _ => throw ArgumentError('Unknown boost tier.'),
    };
    if (amount != expectedAmount) {
      throw ArgumentError('The boost price does not match the selected tier.');
    }

    try {
      final result = await _functions
          .httpsCallable('initiateBoostPayment')
          .call({'jobId': jobId, 'tier': tier});
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Unable to start boost payment.');
    }
  }

  static Future<bool> isJobBoosted(String jobId) async {
    final document = await _firestore.collection('jobs').doc(jobId).get();
    final data = document.data();
    final expiresAt = data?['boostExpiresAt'] as Timestamp?;
    return data?['isBoosted'] == true &&
        expiresAt != null &&
        expiresAt.toDate().isAfter(DateTime.now());
  }

  static Stream<Map<String, dynamic>> getBoostStatus(String jobId) {
    return _firestore.collection('jobs').doc(jobId).snapshots().map((document) {
      final data = document.data() ?? const <String, dynamic>{};
      final expiresAt = data['boostExpiresAt'] as Timestamp?;
      final active =
          data['isBoosted'] == true &&
          expiresAt != null &&
          expiresAt.toDate().isAfter(DateTime.now());
      return {
        'isBoosted': active,
        'tier': active ? data['boostTier'] ?? '' : '',
        'expiresAt': expiresAt,
        'amount': data['boostAmountKES'] ?? 0,
      };
    });
  }
}
