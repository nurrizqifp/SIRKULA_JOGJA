class CommodityRuleModel {
  final String key;             // 'jelantah' | 'pet_bottle'
  final String name;            // 'Minyak Jelantah Rumah Tangga'
  final String unit;            // 'liter' | 'kg'
  final int basePointsPerUnit;  // e.g. 1000 (per liter), 3500 (per kg)
  final String iconName;
  final String preparationTips; // Petunjuk pemilahan sebelum dijemput
  final double minQuantity;

  const CommodityRuleModel({
    required this.key,
    required this.name,
    required this.unit,
    required this.basePointsPerUnit,
    required this.iconName,
    required this.preparationTips,
    this.minQuantity = 1.0,
  });

  static const List<CommodityRuleModel> defaults = [
    CommodityRuleModel(
      key: 'jelantah',
      name: 'Minyak Jelantah Rumah Tangga',
      unit: 'Liter',
      basePointsPerUnit: 1000,
      iconName: 'oil_barrel',
      minQuantity: 1.0,
      preparationTips:
          'Saring sisa remah makanan, dinginkan minyak, lalu masukkan ke dalam botol/jeriken plastik tertutup rapat dan tidak bocor.',
    ),
    CommodityRuleModel(
      key: 'pet_bottle',
      name: 'Botol Plastik PET Bening/Warna',
      unit: 'Kg',
      basePointsPerUnit: 3500,
      iconName: 'recycling',
      minQuantity: 0.5,
      preparationTips:
          'Kosongkan cairan hingga tuntas, bilas jika ada residu manis, lepaskan tutup dan label jika memungkinkan, lalu pipihkan untuk menghemat ruang.',
    ),
  ];
}

class QualityMultiplier {
  final double factor;
  final String label;
  final String description;

  const QualityMultiplier({
    required this.factor,
    required this.label,
    required this.description,
  });

  static const QualityMultiplier excellent = QualityMultiplier(
    factor: 1.1,
    label: 'Kualitas A (Sangat Baik / +10% Bonus)',
    description: 'Material sangat bersih, disaring rapi, dan botol sudah pipih sempurna.',
  );

  static const QualityMultiplier standard = QualityMultiplier(
    factor: 1.0,
    label: 'Kualitas B (Standar BSU / 100%)',
    description: 'Material memenuhi syarat penerimaan standar mitra tanpa kendala.',
  );

  static const QualityMultiplier correction = QualityMultiplier(
    factor: 0.8,
    label: 'Kualitas C (Perlu Koreksi / -20%)',
    description: 'Material masih agak kotor atau butuh penyortiran ulang oleh kader.',
  );

  static const List<QualityMultiplier> all = [excellent, standard, correction];
}
