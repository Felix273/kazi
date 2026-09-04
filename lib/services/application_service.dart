import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/application_model.dart';

class ApplicationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ApplicationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final ApplicationService instance = ApplicationService();

  static String applicationId(String jobId, String workerId) {
    return '${jobId}_$workerId';
  }

  Future<String> applyToJob({
    required String jobId,
    double distanceKm = 0,
  }) async {
    final workerId = _auth.currentUser?.uid;
    if (workerId == null) throw StateError('User is not authenticated.');

    await _auth.currentUser?.getIdToken(true);

    final jobRef = _firestore.collection('jobs').doc(jobId);
    final userRef = _firestore.collection('users').doc(workerId);
    final appRef =
        _firestore.collection('applications').doc(applicationId(jobId, workerId));

    await _firestore.runTransaction((transaction) async {
      final jobDoc = await transaction.get(jobRef);
      final userDoc = await transaction.get(userRef);
      final existingApp = await transaction.get(appRef);

      if (!jobDoc.exists || jobDoc.data() == null) {
        throw StateError('The job no longer exists.');
      }
      if (!userDoc.exists || userDoc.data() == null) {
        throw StateError('Complete your profile before applying.');
      }
      if (existingApp.exists) {
        throw StateError('You have already applied for this job.');
      }

      final job = jobDoc.data()!;
      final worker = userDoc.data()!;
      if (job['status'] != 'open') {
        throw StateError('This job is no longer accepting applications.');
      }
      if (job['employerId'] == workerId) {
        throw StateError('You cannot apply for your own job.');
      }
      if (worker['role'] != 'jobseeker') {
        throw StateError('Only job seekers can apply for jobs.');
      }

      transaction.set(appRef, {
        'jobId': jobId,
        'workerId': workerId,
        'workerName': worker['name'] ?? 'Worker',
        'workerPhoto': worker['photoUrl'] ?? '',
        'workerRating': worker['averageRating'] ?? 0,
        'workerNeighborhood': worker['neighborhood'] ?? 'Unknown',
        'skills': worker['skills'] ?? const <String>[],
        'bio': worker['bio'] ?? '',
        'isVerified': worker['isVerified'] ?? false,
        'distance': distanceKm,
        'totalJobsCompleted': worker['totalJobsCompleted'] ?? 0,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'jobTitle': job['title'] ?? 'Job',
        'jobCategory': job['category'] ?? 'Other',
        'jobNeighborhood': job['neighborhood'] ?? 'Unknown',
        'jobSalary': job['salaryKES'] ?? 0,
        'employerId': job['employerId'],
        'employerName': job['employerName'] ?? 'Employer',
      });
      transaction.update(jobRef, {
        'applicantCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return appRef.id;
  }

  Future<bool> hasApplied(String jobId) async {
    final workerId = _auth.currentUser?.uid;
    if (workerId == null) return false;
    final doc =
        await _firestore.collection('applications').doc(applicationId(jobId, workerId)).get();
    return doc.exists;
  }

  Stream<List<ApplicationModel>> watchWorkerApplications() {
    final workerId = _auth.currentUser?.uid;
    if (workerId == null) return Stream.value(const []);
    return _firestore
        .collection('applications')
        .where('workerId', isEqualTo: workerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
