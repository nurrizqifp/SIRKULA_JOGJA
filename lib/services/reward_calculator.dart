class RewardCalculator {
  /// Calculates total reward points based on verified quantity, base points per unit, and quality multiplier.
  /// Formula: Total Poin = (Kuantitas Terverifikasi × Poin Dasar Komoditas) × Pengali Kualitas
  static int calculate({
    required double verifiedQuantity,
    required int basePointsPerUnit,
    required double qualityMultiplier,
  }) {
    if (verifiedQuantity <= 0) return 0;
    final grossPoints = verifiedQuantity * basePointsPerUnit;
    final total = grossPoints * qualityMultiplier;
    return total.round();
  }

  /// Explanation string for citizen transparency
  static String explainCalculation({
    required double verifiedQuantity,
    required String unit,
    required int basePointsPerUnit,
    required double qualityMultiplier,
  }) {
    final total = calculate(
      verifiedQuantity: verifiedQuantity,
      basePointsPerUnit: basePointsPerUnit,
      qualityMultiplier: qualityMultiplier,
    );
    return '($verifiedQuantity $unit × $basePointsPerUnit poin) × pengali mutu $qualityMultiplier = $total poin';
  }
}
