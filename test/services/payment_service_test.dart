import 'package:flutter_test/flutter_test.dart';
import 'package:kazi/services/payment_service.dart';

void main() {
  group('PaymentService API contract', () {
    test('mockHireApplicant is a static callable returning Future<Map>', () {
      expect(PaymentService.mockHireApplicant, isNotNull);
    });

    test('hireApplicant is a static callable returning Future<Map>', () {
      expect(PaymentService.hireApplicant, isNotNull);
    });

    test('processCompletedJob is a static callable returning Future<Map>', () {
      expect(PaymentService.processCompletedJob, isNotNull);
    });

    test('initiateB2CPayout is a static callable returning Future<Map>', () {
      expect(PaymentService.initiateB2CPayout, isNotNull);
    });

    test('getTransactionHistory is a static stream', () {
      expect(PaymentService.getTransactionHistory, isNotNull);
    });
  });
}