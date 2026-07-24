import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/job_model.dart';

class JobService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<JobModel>> getNearbyJobs({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
    String? category,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open');

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();
    final jobs = <JobModel>[];

    for (final document in snapshot.docs) {
      final data = document.data();
      final location = data['location'] as GeoPoint?;
      if (location == null) continue;

      final distanceKm = calculateDistance(
        latitude,
        longitude,
        location.latitude,
        location.longitude,
      );
      if (distanceKm > radiusInKm) continue;

      jobs.add(JobModel.fromMap(data, document.id, distanceKm: distanceKm));
    }

    jobs.sort((a, b) {
      if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
      return (a.distanceKm ?? double.infinity).compareTo(
        b.distanceKm ?? double.infinity,
      );
    });
    return jobs;
  }

  static Stream<List<JobModel>> subscribeToNearbyJobs({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
    String? category,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open');

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      final jobs = <JobModel>[];
      for (final document in snapshot.docs) {
        final data = document.data();
        final location = data['location'] as GeoPoint?;
        if (location == null) continue;
        final distanceKm = calculateDistance(
          latitude,
          longitude,
          location.latitude,
          location.longitude,
        );
        if (distanceKm <= radiusInKm) {
          jobs.add(JobModel.fromMap(data, document.id, distanceKm: distanceKm));
        }
      }
      jobs.sort((a, b) {
        if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
        return (a.distanceKm ?? double.infinity).compareTo(
          b.distanceKm ?? double.infinity,
        );
      });
      return jobs;
    });
  }

  static Future<JobModel?> getJob(String jobId) async {
    final doc = await _firestore.collection('jobs').doc(jobId).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobModel.fromMap(doc.data()!, doc.id);
  }

  static Stream<JobModel?> watchJob(String jobId) {
    return _firestore.collection('jobs').doc(jobId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : JobModel.fromMap(data, doc.id);
    });
  }

  static Future<void> updateJobStatus(String jobId, String status) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<JobModel>> getEmployerJobs(String employerId) {
    return _firestore
        .collection('jobs')
        .where('employerId', isEqualTo: employerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JobModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  static String generateGeohash(
    double latitude,
    double longitude, [
    int precision = 9,
  ]) {
    const alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';
    var latitudeRange = <double>[-90, 90];
    var longitudeRange = <double>[-180, 180];
    var evenBit = true;
    var bit = 0;
    var character = 0;
    final output = StringBuffer();

    while (output.length < precision) {
      final range = evenBit ? longitudeRange : latitudeRange;
      final value = evenBit ? longitude : latitude;
      final midpoint = (range[0] + range[1]) / 2;
      if (value >= midpoint) {
        character = (character << 1) | 1;
        range[0] = midpoint;
      } else {
        character <<= 1;
        range[1] = midpoint;
      }
      evenBit = !evenBit;
      bit++;

      if (bit == 5) {
        output.write(alphabet[character]);
        bit = 0;
        character = 0;
      }
    }

    return output.toString();
  }
}
