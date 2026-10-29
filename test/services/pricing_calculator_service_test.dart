import 'package:flutter_test/flutter_test.dart';
import 'package:kazi/services/pricing_calculator_service.dart';

void main() {
  group('PricingCalculatorService Tests', () {
    test('getBaseHourlyRate returns correct category rates', () {
      expect(PricingCalculatorService.getBaseHourlyRate('Cleaning'), 250.0);
      expect(PricingCalculatorService.getBaseHourlyRate('Plumbing'), 500.0);
      expect(PricingCalculatorService.getBaseHourlyRate('Electrical'), 500.0);
      expect(PricingCalculatorService.getBaseHourlyRate('Gardening'), 200.0);
      expect(
        PricingCalculatorService.getBaseHourlyRate('UnknownCategory'),
        250.0,
      );
    });

    test('getComplexityMultiplier returns correct multipliers', () {
      expect(PricingCalculatorService.getComplexityMultiplier('simple'), 1.0);
      expect(
        PricingCalculatorService.getComplexityMultiplier('moderate'),
        1.3,
      );
      expect(PricingCalculatorService.getComplexityMultiplier('complex'), 1.6);
      expect(PricingCalculatorService.getComplexityMultiplier('unknown'), 1.0);
    });

    test('calculateRecommendation calculates accurate recommendation', () {
      final rec = PricingCalculatorService.calculateRecommendation(
        category: 'Cleaning',
        estimatedHours: 2.0,
        workerCount: 1,
        complexity: 'simple',
        isUrgent: false,
      );

      // Base: 250 * 2 hrs * 1 worker * 1.0 = 500
      expect(rec.baseHourlyRate, 250.0);
      expect(rec.complexityMultiplier, 1.0);
      expect(rec.urgencyMultiplier, 1.0);
      expect(rec.recommendedTotalSalary, 500.0);
      expect(rec.totalLaborHours, 2.0);
      expect(rec.recommendedHourlyRatePerWorker, 250.0);
      expect(rec.minSalary, 430.0); // 500 * 0.85 = 425 -> rounded to nearest 10 = 430
      expect(rec.maxSalary, 630.0); // 500 * 1.25 = 625 -> rounded to nearest 10 = 630
    });

    test('calculateRecommendation handles urgency and multiple workers', () {
      final rec = PricingCalculatorService.calculateRecommendation(
        category: 'Plumbing',
        estimatedHours: 3.0,
        workerCount: 2,
        complexity: 'moderate',
        isUrgent: true,
      );

      // 500 * 3 hrs * 2 workers * 1.3 complexity * 1.15 urgency = 4485 -> rounded to 4500
      expect(rec.baseHourlyRate, 500.0);
      expect(rec.complexityMultiplier, 1.3);
      expect(rec.urgencyMultiplier, 1.15);
      expect(rec.totalLaborHours, 6.0);
      expect(rec.recommendedTotalSalary, 4500.0);
    });

    test('evaluateWage classifies below market rate correctly', () {
      final eval = PricingCalculatorService.evaluateWage(
        salaryKES: 100.0, // 100 / 2hrs = 50 KES/hr (well below 150 min threshold)
        estimatedHours: 2.0,
        workerCount: 1,
        category: 'Cleaning',
      );

      expect(eval.status, WageStatus.belowMarket);
      expect(eval.effectiveHourlyRatePerWorker, 50.0);
      expect(eval.label, 'Below Market Average');
      expect(eval.recommendedSalary, 500.0);
    });

    test('evaluateWage classifies fair market rate correctly', () {
      final eval = PricingCalculatorService.evaluateWage(
        salaryKES: 500.0, // 250 KES/hr for Cleaning simple
        estimatedHours: 2.0,
        workerCount: 1,
        category: 'Cleaning',
      );

      expect(eval.status, WageStatus.fairMarket);
      expect(eval.effectiveHourlyRatePerWorker, 250.0);
      expect(eval.label, 'Fair Market Rate');
    });

    test('evaluateWage classifies competitive (above market) rate correctly', () {
      final eval = PricingCalculatorService.evaluateWage(
        salaryKES: 800.0, // 400 KES/hr for Cleaning (recommended ~250 KES/hr)
        estimatedHours: 2.0,
        workerCount: 1,
        category: 'Cleaning',
      );

      expect(eval.status, WageStatus.aboveMarket);
      expect(eval.effectiveHourlyRatePerWorker, 400.0);
      expect(eval.label, 'Competitive Rate');
    });
  });
}
