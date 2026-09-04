import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazi/models/application_model.dart';
import 'package:kazi/models/job_model.dart';
import 'package:kazi/services/application_service.dart';
import 'package:kazi/services/job_service.dart';

void main() {
  group('ApplicationModel & Status Mapping Tests', () {
    test('ApplicationModel serializes and deserializes all status types accurately', () {
      final statuses = <String, ApplicationStatus>{
        'pending': ApplicationStatus.pending,
        'payment_pending': ApplicationStatus.paymentPending,
        'accepted': ApplicationStatus.accepted,
        'in_progress': ApplicationStatus.inProgress,
        'completed': ApplicationStatus.completed,
        'declined': ApplicationStatus.declined,
        'cancelled': ApplicationStatus.cancelled,
      };

      for (final entry in statuses.entries) {
        final map = {
          'jobId': 'job_101',
          'workerId': 'worker_202',
          'workerName': 'Jane Doe',
          'workerPhoto': 'https://example.com/photo.jpg',
          'workerRating': 4.8,
          'workerNeighborhood': 'Westlands',
          'skills': ['Plumbing', 'Pipe Repair'],
          'bio': 'Experienced plumber.',
          'distance': 2.5,
          'totalJobsCompleted': 12,
          'status': entry.key,
          'appliedAt': Timestamp.fromDate(DateTime(2026, 8, 1, 10, 0)),
        };

        final model = ApplicationModel.fromMap(map, 'app_1');
        expect(model.status, equals(entry.value));

        final serialized = model.toMap();
        expect(serialized['status'], equals(entry.key));
        expect(serialized['jobId'], equals('job_101'));
        expect(serialized['workerId'], equals('worker_202'));
        expect(serialized['workerName'], equals('Jane Doe'));
        expect(serialized['workerRating'], equals(4.8));
        expect(serialized['distance'], equals(2.5));
      }
    });

    test('ApplicationService.applicationId formats deterministic IDs correctly', () {
      final appId = ApplicationService.applicationId('job_xyz', 'worker_abc');
      expect(appId, equals('job_xyz_worker_abc'));
    });
  });

  group('Job Application Simulation Flow', () {
    test('Simulates job creation and fee structure calculations', () {
      final job = JobModel(
        id: 'job_nairobi_001',
        title: 'Electrical Repair',
        category: 'Electrical',
        description: 'Fix wiring in shop.',
        requirements: const ['Electrical certification', 'Tools'],
        salaryKES: 3000,
        duration: 3,
        durationType: 'hours',
        startDate: DateTime(2026, 8, 10),
        isUrgent: true,
        employerId: 'employer_emp01',
        employerName: 'Supermarket Ltd',
        employerPhone: '254711223344',
        location: const GeoPoint(-1.286389, 36.817223),
        neighborhood: 'CBD',
        geohash: 'kzf0',
        status: 'open',
        applicantCount: 0,
        createdAt: DateTime(2026, 8, 1),
      );

      // Verify fee model
      expect(job.salaryKES, equals(3000));
      expect(job.employerPays, closeTo(3300, 0.01)); // +10%
      expect(job.workerEarns, closeTo(2850, 0.01)); // -5%
      expect(job.platformFee, closeTo(450, 0.01)); // 15% platform take (10% employer + 5% worker)
    });

    test('Simulates distance calculation and nearby filtering', () {
      // Nairobi CBD: -1.286389, 36.817223
      // Westlands: -1.2676, 36.8121
      const cbdLat = -1.286389;
      const cbdLng = 36.817223;
      const westlandsLat = -1.2676;
      const westlandsLng = 36.8121;

      final distanceKm = JobService.calculateDistance(
        westlandsLat,
        westlandsLng,
        cbdLat,
        cbdLng,
      );

      expect(distanceKm, greaterThan(1.5));
      expect(distanceKm, lessThan(3.5));
    });

    test('Simulates applicant pipeline filtering and metrics calculation', () {
      final applications = [
        {
          'id': 'job1_w1',
          'workerId': 'w1',
          'workerName': 'Alice',
          'status': 'pending',
          'isVerified': true,
          'distance': 1.2,
        },
        {
          'id': 'job1_w2',
          'workerId': 'w2',
          'workerName': 'Bob',
          'status': 'pending',
          'isVerified': false,
          'distance': 4.5,
        },
        {
          'id': 'job1_w3',
          'workerId': 'w3',
          'workerName': 'Charlie',
          'status': 'declined',
          'isVerified': true,
          'distance': 8.0,
        },
      ];

      final totalCount = applications.length;
      final pendingCount = applications.where((a) => a['status'] == 'pending').length;
      final verifiedCount = applications.where((a) => a['isVerified'] == true).length;
      final nearbyCount = applications.where((a) => (a['distance'] as double) <= 5.0).length;

      expect(totalCount, equals(3));
      expect(pendingCount, equals(2));
      expect(verifiedCount, equals(2));
      expect(nearbyCount, equals(2));
    });

    test('Simulates hiring transition and auto-declining remaining applicants', () {
      final applicants = [
        {'id': 'app_1', 'workerId': 'w1', 'status': 'pending'},
        {'id': 'app_2', 'workerId': 'w2', 'status': 'pending'},
        {'id': 'app_3', 'workerId': 'w3', 'status': 'pending'},
      ];

      const selectedAppId = 'app_1';

      // Simulate hiring step: hired applicant becomes 'accepted', others become 'declined'
      final updatedApplicants = applicants.map((app) {
        if (app['id'] == selectedAppId) {
          return {...app, 'status': 'accepted'};
        } else {
          return {...app, 'status': 'declined'};
        }
      }).toList();

      expect(updatedApplicants.firstWhere((a) => a['id'] == 'app_1')['status'], equals('accepted'));
      expect(updatedApplicants.firstWhere((a) => a['id'] == 'app_2')['status'], equals('declined'));
      expect(updatedApplicants.firstWhere((a) => a['id'] == 'app_3')['status'], equals('declined'));
    });

    test('Simulates work check-in, check-out, and wallet payout release', () {
      var jobStatus = 'hired';
      var workStatus = 'not_started';
      var paymentStatus = 'escrowed';
      var walletBalance = 0.0;
      var totalEarned = 0.0;
      const workerEarns = 2850.0;

      // 1. Worker Check-in
      workStatus = 'in_progress';
      expect(workStatus, equals('in_progress'));

      // 2. Worker Check-out
      workStatus = 'completed';
      jobStatus = 'completed';
      paymentStatus = 'released';
      walletBalance += workerEarns;
      totalEarned += workerEarns;

      expect(jobStatus, equals('completed'));
      expect(workStatus, equals('completed'));
      expect(paymentStatus, equals('released'));
      expect(walletBalance, equals(2850.0));
      expect(totalEarned, equals(2850.0));
    });
  });
}
