import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazi/models/application_model.dart';

void main() {
  group('ApplicationModel', () {
    final Map<String, dynamic> baseMap = {
      'jobId': 'job-1',
      'workerId': 'worker-1',
      'workerName': 'Jane Doe',
      'workerPhoto': 'https://example.com/photo.jpg',
      'workerRating': 4.5,
      'workerNeighborhood': 'Nairobi',
      'skills': ['cleaning', 'organizing'],
      'bio': 'Experienced cleaner.',
      'distance': 3.2,
      'totalJobsCompleted': 12,
      'status': 'accepted',
      'appliedAt': Timestamp.fromDate(DateTime(2026, 7, 20, 10, 0, 0)),
    };

    test('fromMap parses all fields correctly', () {
      final app = ApplicationModel.fromMap(baseMap, 'app-1');

      expect(app.id, 'app-1');
      expect(app.jobId, 'job-1');
      expect(app.workerId, 'worker-1');
      expect(app.workerName, 'Jane Doe');
      expect(app.workerPhoto, 'https://example.com/photo.jpg');
      expect(app.workerRating, 4.5);
      expect(app.workerNeighborhood, 'Nairobi');
      expect(app.skills, ['cleaning', 'organizing']);
      expect(app.bio, 'Experienced cleaner.');
      expect(app.distance, 3.2);
      expect(app.totalJobsCompleted, 12);
      expect(app.status, ApplicationStatus.accepted);
      expect(app.appliedAt, DateTime(2026, 7, 20, 10, 0, 0));
    });

    test('fromMap uses defaults for missing fields', () {
      final app = ApplicationModel.fromMap(const {}, 'app-2');

      expect(app.id, 'app-2');
      expect(app.jobId, '');
      expect(app.workerId, '');
      expect(app.workerName, 'Worker');
      expect(app.workerPhoto, '');
      expect(app.workerRating, 0.0);
      expect(app.workerNeighborhood, 'Unknown');
      expect(app.skills, isEmpty);
      expect(app.bio, '');
      expect(app.distance, 0.0);
      expect(app.totalJobsCompleted, 0);
      expect(app.status, ApplicationStatus.pending);
    });

    test('fromMap maps all status string values to enum', () {
      for (final entry in {
        'pending': ApplicationStatus.pending,
        'accepted': ApplicationStatus.accepted,
        'declined': ApplicationStatus.declined,
        'completed': ApplicationStatus.completed,
        'unknown': ApplicationStatus.pending,
        '': ApplicationStatus.pending,
      }.entries) {
        final app = ApplicationModel.fromMap(
          {...baseMap, 'status': entry.key},
          'app',
        );
        expect(app.status, entry.value, reason: "status '${entry.key}'");
      }
    });

    test('toMap serializes all fields correctly', () {
      final app = ApplicationModel.fromMap(baseMap, 'app-1');
      final map = app.toMap();

      expect(map['jobId'], 'job-1');
      expect(map['workerId'], 'worker-1');
      expect(map['workerName'], 'Jane Doe');
      expect(map['workerPhoto'], 'https://example.com/photo.jpg');
      expect(map['workerRating'], 4.5);
      expect(map['workerNeighborhood'], 'Nairobi');
      expect(map['skills'], ['cleaning', 'organizing']);
      expect(map['bio'], 'Experienced cleaner.');
      expect(map['distance'], 3.2);
      expect(map['totalJobsCompleted'], 12);
      expect(map['status'], 'accepted');
      expect(map['appliedAt'], Timestamp.fromDate(DateTime(2026, 7, 20, 10, 0, 0)));
    });

    test('toMap serializes status enum values correctly', () {
      for (final entry in {
        ApplicationStatus.pending: 'pending',
        ApplicationStatus.accepted: 'accepted',
        ApplicationStatus.declined: 'declined',
        ApplicationStatus.completed: 'completed',
      }.entries) {
        final app = ApplicationModel(
          id: 'app',
          jobId: 'job-1',
          workerId: 'worker-1',
          workerName: 'Jane Doe',
          workerPhoto: '',
          workerRating: 0,
          workerNeighborhood: 'Nairobi',
          skills: const [],
          bio: '',
          distance: 0,
          totalJobsCompleted: 0,
          status: entry.key,
          appliedAt: DateTime(2026, 7, 20),
        );
        expect(app.toMap()['status'], entry.value);
      }
    });

    test('round-trip fromMap -> toMap preserves data', () {
      final app = ApplicationModel.fromMap(baseMap, 'app-1');
      final map = app.toMap();

      final roundTrip = ApplicationModel.fromMap(map, app.id);
      expect(roundTrip.id, app.id);
      expect(roundTrip.jobId, app.jobId);
      expect(roundTrip.workerId, app.workerId);
      expect(roundTrip.workerName, app.workerName);
      expect(roundTrip.workerPhoto, app.workerPhoto);
      expect(roundTrip.workerRating, app.workerRating);
      expect(roundTrip.workerNeighborhood, app.workerNeighborhood);
      expect(roundTrip.skills, app.skills);
      expect(roundTrip.bio, app.bio);
      expect(roundTrip.distance, app.distance);
      expect(roundTrip.totalJobsCompleted, app.totalJobsCompleted);
      expect(roundTrip.status, app.status);
    });
  });
}
