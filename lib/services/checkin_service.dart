import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';

class CheckinService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'africa-south1',
  );

  static Future<Map<String, dynamic>> checkIn(
    String jobId,
    GeoPoint location,
  ) async {
    final result = await _functions.httpsCallable('recordCheckIn').call({
      'jobId': jobId,
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> checkOut(
    String jobId,
    GeoPoint location,
  ) async {
    final result = await _functions.httpsCallable('recordCheckOut').call({
      'jobId': jobId,
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Stream<List<Map<String, dynamic>>> getCheckInHistory(String jobId) {
    return _firestore
        .collection('checkins')
        .where('jobId', isEqualTo: jobId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  static Future<ProximityResult> checkProximity(
    GeoPoint userLocation,
    GeoPoint jobLocation, {
    double maxRadiusKm = 0.5,
  }) async {
    final distanceInMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      jobLocation.latitude,
      jobLocation.longitude,
    );
    return ProximityResult(
      isWithinRange: distanceInMeters / 1000 <= maxRadiusKm,
      distanceMeters: distanceInMeters,
      distanceKm: distanceInMeters / 1000,
    );
  }

  static Future<String> getJobStatus(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 'not_applied';
    final application = await _firestore
        .collection('applications')
        .doc('${jobId}_$userId')
        .get();
    return application.data()?['status'] as String? ?? 'not_applied';
  }

  static Stream<Map<String, dynamic>> getJobStatusStream(String jobId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(const {'status': 'unknown'});
    return _firestore
        .collection('applications')
        .doc('${jobId}_$userId')
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          return data == null
              ? const {'status': 'not_applied'}
              : {'status': data['status'] ?? 'unknown', 'data': data};
        });
  }
}

class ProximityResult {
  final bool isWithinRange;
  final double distanceMeters;
  final double distanceKm;

  const ProximityResult({
    required this.isWithinRange,
    required this.distanceMeters,
    required this.distanceKm,
  });
}
