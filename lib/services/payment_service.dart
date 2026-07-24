import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'africa-south1',
  );

  static Future<Map<String, dynamic>> hireApplicant({
    required String jobId,
    required String applicationId,
    required String workerId,
    required String phone,
  }) async {
    try {
      final result = await _functions.httpsCallable('initiateSTKPush').call({
        'jobId': jobId,
        'applicationId': applicationId,
        'workerId': workerId,
        'phone': phone,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Unable to start M-Pesa payment.');
    }
  }

  static Future<Map<String, dynamic>> initiateB2CPayout({
    required double amount,
    required String phone,
  }) async {
    try {
      final result = await _functions.httpsCallable('initiateB2CPayout').call({
        'amount': amount,
        'phone': phone,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Withdrawal failed.');
    }
  }

  static Future<Map<String, dynamic>> processCompletedJob(String jobId) async {
    try {
      final result = await _functions.httpsCallable('processJobPayment').call({
        'jobId': jobId,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Unable to process job payment.');
    }
  }

  static Stream<List<Map<String, dynamic>>> getTransactionHistory() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(const []);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
