import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazi/models/application_model.dart';
import 'package:kazi/services/application_service.dart';

void main() {
  group('ApplicationService.applicationId', () {
    test('combines jobId and workerId with underscore', () {
      expect(
        ApplicationService.applicationId('job-1', 'worker-1'),
        'job-1_worker-1',
      );
    });

    test('handles empty strings', () {
      expect(
        ApplicationService.applicationId('', ''),
        '_',
      );
    });

    test('preserves special characters', () {
      expect(
        ApplicationService.applicationId('job_123', 'worker-abc'),
        'job_123_worker-abc',
      );
    });

    test('is consistently reversible for same inputs', () {
      const jobId = 'abc123';
      const workerId = 'xyz789';
      final id = ApplicationService.applicationId(jobId, workerId);
      final parts = id.split('_');
      expect(parts.first, jobId);
      expect(parts.last, workerId);
    });
  });

  group('ApplicationService.applyToJob', () {
    final mockUser = MockUser(
      uid: 'worker-1',
      email: 'worker@example.com',
    );

    Future<ApplicationService> buildService({
      required FakeFirebaseFirestore firestore,
      bool signedIn = true,
      MockUser? user,
    }) async {
      final auth = MockFirebaseAuth(
        signedIn: signedIn,
        mockUser: user ?? mockUser,
      );
      return ApplicationService(firestore: firestore, auth: auth);
    }

    test('throws when user is not authenticated', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: false);
      final service = ApplicationService(firestore: firestore, auth: auth);

      expect(
        () => service.applyToJob(jobId: 'job-1'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'User is not authenticated.',
        )),
      );
    });

    test('throws when job no longer exists', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('worker-1')
          .set({'role': 'jobseeker'});

      final service = await buildService(firestore: firestore);

      expect(
        () => service.applyToJob(jobId: 'nonexistent-job'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'The job no longer exists.',
        )),
      );
    });

    test('throws when worker profile does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('jobs').doc('job-1').set({
        'status': 'open',
        'employerId': 'employer-1',
        'employerName': 'Employer',
        'title': 'Cleaning',
        'category': 'Cleaning',
        'neighborhood': 'Nairobi',
        'salaryKES': 1000,
      });

      final service = await buildService(firestore: firestore);

      expect(
        () => service.applyToJob(jobId: 'job-1'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'Complete your profile before applying.',
        )),
      );
    });

    test('throws when worker has already applied', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('jobs').doc('job-1').set({
        'status': 'open',
        'employerId': 'employer-1',
        'employerName': 'Employer',
        'title': 'Cleaning',
        'category': 'Cleaning',
        'neighborhood': 'Nairobi',
        'salaryKES': 1000,
      });
      await firestore.collection('users').doc('worker-1').set({
        'role': 'jobseeker',
      });
      await firestore
          .collection('applications')
          .doc('job-1_worker-1')
          .set({'status': 'pending'});

      final service = await buildService(firestore: firestore);

      expect(
        () => service.applyToJob(jobId: 'job-1'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'You have already applied for this job.',
        )),
      );
    });

    test('throws when job is not open', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('jobs').doc('job-1').set({
        'status': 'cancelled',
        'employerId': 'employer-1',
        'employerName': 'Employer',
        'title': 'Cleaning',
        'category': 'Cleaning',
        'neighborhood': 'Nairobi',
        'salaryKES': 1000,
      });
      await firestore.collection('users').doc('worker-1').set({
        'role': 'jobseeker',
      });

      final service = await buildService(firestore: firestore);

      expect(
        () => service.applyToJob(jobId: 'job-1'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'This job is no longer accepting applications.',
        )),
      );
    });

    test('throws when worker is the job employer', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('jobs').doc('job-1').set({
        'status': 'open',
        'employerId': 'worker-1',
        'employerName': 'Me',
        'title': 'Cleaning',
        'category': 'Cleaning',
        'neighborhood': 'Nairobi',
        'salaryKES': 1000,
      });
      await firestore.collection('users').doc('worker-1').set({
        'role': 'jobseeker',
      });

      final service = await buildService(firestore: firestore);

      expect(
        () => service.applyToJob(jobId: 'job-1'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'You cannot apply for your own job.',
        )),
      );
    });

    test('throws when user is not a jobseeker', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('jobs').doc('job-1').set({
        'status': 'open',
        'employerId': 'employer-1',
        'employerName': 'Employer',
        'title': 'Cleaning',
        'category': 'Cleaning',
        'neighborhood': 'Nairobi',
        'salaryKES': 1000,
      });
      await firestore.collection('users').doc('worker-1').set({
        'role': 'employer',
      });

      final service = await buildService(firestore: firestore);

      expect(
        () => service.applyToJob(jobId: 'job-1'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'Only job seekers can apply for jobs.',
        )),
      );
    });

    test(
      'successfully creates application and increments applicant count',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('jobs').doc('job-1').set({
          'status': 'open',
          'employerId': 'employer-1',
          'employerName': 'Acme Corp',
          'title': 'House cleaning',
          'category': 'Cleaning',
          'neighborhood': 'Westlands',
          'salaryKES': 2000,
          'applicantCount': 5,
        });
        await firestore.collection('users').doc('worker-1').set({
          'role': 'jobseeker',
          'name': 'Jane Doe',
          'photoUrl': 'https://example.com/photo.jpg',
          'averageRating': 4.7,
          'neighborhood': 'Nairobi',
          'skills': ['cleaning', 'organizing'],
          'bio': 'Experienced cleaner',
          'isVerified': true,
          'totalJobsCompleted': 20,
        });

        final service = await buildService(firestore: firestore);

        final appId = await service.applyToJob(
          jobId: 'job-1',
          distanceKm: 2.5,
        );

        expect(appId, 'job-1_worker-1');

        final appDoc =
            await firestore.collection('applications').doc(appId).get();
        expect(appDoc.exists, isTrue);

        final appData = appDoc.data()!;
        expect(appData['jobId'], 'job-1');
        expect(appData['workerId'], 'worker-1');
        expect(appData['workerName'], 'Jane Doe');
        expect(appData['workerPhoto'], 'https://example.com/photo.jpg');
        expect(appData['workerRating'], 4.7);
        expect(appData['workerNeighborhood'], 'Nairobi');
        expect(appData['skills'], ['cleaning', 'organizing']);
        expect(appData['bio'], 'Experienced cleaner');
        expect(appData['isVerified'], true);
        expect(appData['distance'], 2.5);
        expect(appData['totalJobsCompleted'], 20);
        expect(appData['status'], 'pending');
        expect(appData['jobTitle'], 'House cleaning');
        expect(appData['jobCategory'], 'Cleaning');
        expect(appData['jobNeighborhood'], 'Westlands');
        expect(appData['jobSalary'], 2000);
        expect(appData['employerId'], 'employer-1');
        expect(appData['employerName'], 'Acme Corp');

        final jobDoc = await firestore.collection('jobs').doc('job-1').get();
        expect(jobDoc.data()!['applicantCount'], 6);
      },
    );

    test('applies defaults when worker fields are missing', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('jobs').doc('job-1').set({
        'status': 'open',
        'employerId': 'employer-1',
        'employerName': 'Acme Corp',
        'title': 'House cleaning',
        'category': 'Cleaning',
        'neighborhood': 'Westlands',
        'salaryKES': 2000,
        'applicantCount': 0,
      });
      await firestore.collection('users').doc('worker-1').set({
        'role': 'jobseeker',
      });

      final service = await buildService(firestore: firestore);

      final appId = await service.applyToJob(jobId: 'job-1');
      final appData = (await firestore
              .collection('applications')
              .doc(appId)
              .get())
          .data()!;

      expect(appData['workerName'], 'Worker');
      expect(appData['workerPhoto'], '');
      expect(appData['workerRating'], 0);
      expect(appData['workerNeighborhood'], 'Unknown');
      expect(appData['skills'], <String>[]);
      expect(appData['bio'], '');
      expect(appData['isVerified'], false);
      expect(appData['totalJobsCompleted'], 0);
      expect(appData['jobTitle'], 'House cleaning');
      expect(appData['employerName'], 'Acme Corp');
    });
  });

  group('ApplicationService.hasApplied', () {
    test('returns true when application document exists', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('applications')
          .doc('job-1_worker-1')
          .set({'status': 'pending'});

      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'worker-1'),
      );
      final service = ApplicationService(firestore: firestore, auth: auth);

      expect(await service.hasApplied('job-1'), isTrue);
    });

    test('returns false when application document does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'worker-1'),
      );
      final service = ApplicationService(firestore: firestore, auth: auth);

      expect(await service.hasApplied('job-1'), isFalse);
    });

    test('returns false when user is not authenticated', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: false);
      final service = ApplicationService(firestore: firestore, auth: auth);

      expect(await service.hasApplied('job-1'), isFalse);
    });
  });

  group('ApplicationService.watchWorkerApplications', () {
    test('emits applications for the current worker', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('applications')
          .doc('job-1_worker-1')
          .set({
        'workerId': 'worker-1',
        'jobId': 'job-1',
        'status': 'pending',
        'appliedAt': Timestamp.fromDate(DateTime(2026, 7, 20)),
      });

      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'worker-1'),
      );
      final service = ApplicationService(firestore: firestore, auth: auth);

      final snapshot = await service.watchWorkerApplications().first;
      expect(snapshot, isNotEmpty);
      expect(snapshot.first.workerId, 'worker-1');
      expect(snapshot.first.status, ApplicationStatus.pending);
    });

    test('emits empty list when user is not authenticated', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: false);
      final service = ApplicationService(firestore: firestore, auth: auth);

      final snapshot = await service.watchWorkerApplications().first;
      expect(snapshot, isEmpty);
    });
  });
}
