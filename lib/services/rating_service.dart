import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/rating_model.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> submitRating({
    required String jobId,
    required String revieweeId,
    required int stars,
    required String comment,
    required RatingType type,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw StateError('User not authenticated.');
    if (stars < 1 || stars > 5) {
      throw ArgumentError.value(stars, 'stars', 'Rating must be from 1 to 5.');
    }

    final ratingId = '${jobId}_$userId';
    final rating = RatingModel(
      id: ratingId,
      jobId: jobId,
      reviewerId: userId,
      revieweeId: revieweeId,
      stars: stars,
      comment: comment.trim(),
      type: type,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('ratings').doc(ratingId).set({
      ...rating.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<RatingModel>> getRatingsForJob(String jobId) {
    return _firestore
        .collection('ratings')
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RatingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Future<bool> hasRatedJob(String jobId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    final document = await _firestore
        .collection('ratings')
        .doc('${jobId}_$userId')
        .get();
    return document.exists;
  }
}
