import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazi/models/job_model.dart';

void main() {
  test('JobModel calculates the employer, worker, and platform amounts', () {
    final job = JobModel(
      id: 'job-1',
      title: 'House cleaning',
      category: 'Cleaning',
      description: 'Clean a two-bedroom house.',
      requirements: const ['Valid identification'],
      salaryKES: 1000,
      duration: 4,
      durationType: 'hours',
      startDate: DateTime(2026, 7, 21),
      isUrgent: false,
      employerId: 'employer-1',
      employerName: 'Employer',
      employerPhone: '254700000000',
      location: const GeoPoint(-1.2921, 36.8219),
      neighborhood: 'Nairobi',
      geohash: 'kzf0',
      status: 'open',
      applicantCount: 0,
      createdAt: DateTime(2026, 7, 20),
    );

    expect(job.employerPays, 1100);
    expect(job.workerEarns, 950);
    expect(job.platformFee, 150);
  });
}
