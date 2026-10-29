enum WageStatus {
  belowMarket,
  fairMarket,
  aboveMarket,
}

class PricingRecommendation {
  final double baseHourlyRate;
  final double complexityMultiplier;
  final double urgencyMultiplier;
  final double recommendedTotalSalary;
  final double minSalary;
  final double maxSalary;
  final double totalLaborHours;
  final double recommendedHourlyRatePerWorker;

  const PricingRecommendation({
    required this.baseHourlyRate,
    required this.complexityMultiplier,
    required this.urgencyMultiplier,
    required this.recommendedTotalSalary,
    required this.minSalary,
    required this.maxSalary,
    required this.totalLaborHours,
    required this.recommendedHourlyRatePerWorker,
  });
}

class WageEvaluation {
  final double effectiveHourlyRatePerWorker;
  final WageStatus status;
  final String label;
  final String message;
  final double recommendedSalary;

  const WageEvaluation({
    required this.effectiveHourlyRatePerWorker,
    required this.status,
    required this.label,
    required this.message,
    required this.recommendedSalary,
  });
}

class PricingCalculatorService {
  static const Map<String, double> categoryBaseHourlyRates = {
    'Cleaning': 250.0,
    'Plumbing': 500.0,
    'Electrical': 500.0,
    'Delivery': 250.0,
    'Security': 300.0,
    'Cooking': 300.0,
    'Childcare': 250.0,
    'Painting': 400.0,
    'Carpentry': 400.0,
    'Gardening': 200.0,
    'Driving': 300.0,
    'Events': 400.0,
    'Casual Labour': 200.0,
  };

  static const Map<String, double> complexityMultipliers = {
    'simple': 1.0,
    'moderate': 1.3,
    'complex': 1.6,
  };

  static const double urgencyMultiplierValue = 1.15;
  static const double minimumFairHourlyRate = 150.0;
  static const double defaultBaseHourlyRate = 250.0;

  static double getBaseHourlyRate(String category) {
    return categoryBaseHourlyRates[category] ?? defaultBaseHourlyRate;
  }

  static double getComplexityMultiplier(String complexity) {
    return complexityMultipliers[complexity.toLowerCase()] ?? 1.0;
  }

  static PricingRecommendation calculateRecommendation({
    required String category,
    required double estimatedHours,
    int workerCount = 1,
    String complexity = 'simple',
    bool isUrgent = false,
  }) {
    final validHours = estimatedHours > 0 ? estimatedHours : 1.0;
    final validWorkers = workerCount > 0 ? workerCount : 1;

    final baseRate = getBaseHourlyRate(category);
    final complexityFactor = getComplexityMultiplier(complexity);
    final urgencyFactor = isUrgent ? urgencyMultiplierValue : 1.0;

    final calculatedTotal =
        baseRate * validHours * validWorkers * complexityFactor * urgencyFactor;

    // Round total salary to nearest 50 KES for clean presentation
    final roundedTotal = (calculatedTotal / 50).round() * 50.0;
    final rawMin = roundedTotal * 0.85;
    final rawMax = roundedTotal * 1.25;

    final minSalary = (rawMin / 10).round() * 10.0;
    final maxSalary = (rawMax / 10).round() * 10.0;

    final totalLaborHours = validHours * validWorkers;
    final hourlyRatePerWorker = roundedTotal / totalLaborHours;

    return PricingRecommendation(
      baseHourlyRate: baseRate,
      complexityMultiplier: complexityFactor,
      urgencyMultiplier: urgencyFactor,
      recommendedTotalSalary: roundedTotal < 100.0 ? 100.0 : roundedTotal,
      minSalary: minSalary < 100.0 ? 100.0 : minSalary,
      maxSalary: maxSalary < roundedTotal ? roundedTotal : maxSalary,
      totalLaborHours: totalLaborHours,
      recommendedHourlyRatePerWorker: hourlyRatePerWorker,
    );
  }

  static WageEvaluation evaluateWage({
    required double salaryKES,
    required double estimatedHours,
    int workerCount = 1,
    required String category,
    String complexity = 'simple',
    bool isUrgent = false,
  }) {
    final validHours = estimatedHours > 0 ? estimatedHours : 1.0;
    final validWorkers = workerCount > 0 ? workerCount : 1;
    final totalLaborHours = validHours * validWorkers;

    final effectiveHourlyRate = salaryKES / totalLaborHours;

    final recommendation = calculateRecommendation(
      category: category,
      estimatedHours: validHours,
      workerCount: validWorkers,
      complexity: complexity,
      isUrgent: isUrgent,
    );

    final fairThreshold = recommendation.recommendedHourlyRatePerWorker * 0.85;
    final competitiveThreshold =
        recommendation.recommendedHourlyRatePerWorker * 1.15;

    if (effectiveHourlyRate < minimumFairHourlyRate ||
        effectiveHourlyRate < fairThreshold) {
      return WageEvaluation(
        effectiveHourlyRatePerWorker: effectiveHourlyRate,
        status: WageStatus.belowMarket,
        label: 'Below Market Average',
        message:
            'This pay rate (KES ${effectiveHourlyRate.toStringAsFixed(0)}/hr) is lower than the typical market rate for $category. Offering fair pay attracts better applicants faster.',
        recommendedSalary: recommendation.recommendedTotalSalary,
      );
    } else if (effectiveHourlyRate >= competitiveThreshold) {
      return WageEvaluation(
        effectiveHourlyRatePerWorker: effectiveHourlyRate,
        status: WageStatus.aboveMarket,
        label: 'Competitive Rate',
        message:
            'Great offer! KES ${effectiveHourlyRate.toStringAsFixed(0)}/hr per worker is above average and will attract top-rated workers quickly.',
        recommendedSalary: recommendation.recommendedTotalSalary,
      );
    } else {
      return WageEvaluation(
        effectiveHourlyRatePerWorker: effectiveHourlyRate,
        status: WageStatus.fairMarket,
        label: 'Fair Market Rate',
        message:
            'KES ${effectiveHourlyRate.toStringAsFixed(0)}/hr aligns well with standard $category rates in Nairobi.',
        recommendedSalary: recommendation.recommendedTotalSalary,
      );
    }
  }
}
