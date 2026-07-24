import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/rating_model.dart';
import '../models/user_model.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<UserModel?> getUserProfile() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(null);
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      return data == null ? null : UserModel.fromMap(data, snapshot.id);
    });
  }

  static Future<UserModel?> getUserById(String userId) async {
    final document = await _firestore.collection('users').doc(userId).get();
    final data = document.data();
    return data == null ? null : UserModel.fromMap(data, document.id);
  }

  static Future<void> updateProfile(UserModel user) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId != user.uid) {
      throw StateError('You can only update your own profile.');
    }
    await _firestore.collection('users').doc(user.uid).update({
      'name': user.name.trim(),
      'phone': user.phone.trim(),
      'email': user.email,
      'photoUrl': user.photoUrl,
      'neighborhood': user.neighborhood?.trim(),
      'lat': user.lat,
      'lng': user.lng,
      'skills': user.skills ?? const <String>[],
      'bio': user.bio?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setAvailability(bool available) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw StateError('User not authenticated.');
    await _firestore.collection('users').doc(userId).update({
      'isAvailable': available,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> uploadID(String idNumber, String imageUrl) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw StateError('User not authenticated.');
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('identityVerifications').doc(userId),
      {
        'userId': userId,
        'idNumber': idNumber.trim(),
        'idPhotoUrl': imageUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.update(_firestore.collection('users').doc(userId), {
      'verificationStatus': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Stream<List<RatingModel>> getUserRatings(String userId) {
    return _firestore
        .collection('ratings')
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RatingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Future<int> getCompletedJobsCount(String userId) async {
    final snapshot = await _firestore
        .collection('applications')
        .where('workerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();
    return snapshot.docs.length;
  }

  static Future<double> getAverageRating(String userId) async {
    final snapshot = await _firestore
        .collection('ratings')
        .where('revieweeId', isEqualTo: userId)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    final total = snapshot.docs.fold<int>(
      0,
      (totalStars, doc) =>
          totalStars + ((doc.data()['stars'] as num?)?.toInt() ?? 0),
    );
    return total / snapshot.docs.length;
  }
}
