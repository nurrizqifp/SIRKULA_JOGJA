class KpiImpactMetrics {
  final double totalPetKg;
  final double totalJelantahLiter;
  final int totalOrders;
  final int completedOrders;
  final int disputedOrders;
  final int registeredHouseholds;
  final int activeHouseholds;
  final double verificationCompletenessRate;
  final double preTestScoreAvg;
  final double postTestScoreAvg;
  final double repeatTransactionRate;

  KpiImpactMetrics({
    required this.totalPetKg,
    required this.totalJelantahLiter,
    required this.totalOrders,
    required this.completedOrders,
    required this.disputedOrders,
    required this.registeredHouseholds,
    required this.activeHouseholds,
    required this.verificationCompletenessRate,
    required this.preTestScoreAvg,
    required this.postTestScoreAvg,
    required this.repeatTransactionRate,
  });

  double get completionRatePercent {
    if (totalOrders == 0) return 0.0;
    return (completedOrders / totalOrders) * 100.0;
  }

  double get activeHouseholdRatePercent {
    if (registeredHouseholds == 0) return 0.0;
    return (activeHouseholds / registeredHouseholds) * 100.0;
  }

  double get quizScoreImprovement {
    return postTestScoreAvg - preTestScoreAvg;
  }
}
