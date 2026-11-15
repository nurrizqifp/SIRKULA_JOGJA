enum LedgerType {
  creditOrder,      // Poin masuk dari hasil penjemputan sampah
  debitRedeem,      // Poin keluar untuk penukaran hadiah
  creditEducation,  // Poin apresiasi menyelesaikan modul/kuis
  adminAdjustment   // Koreksi saldo oleh admin BSU dengan audit trail
}

class RewardLedgerEntry {
  final String id;
  final String userId;
  final String? orderId;
  final LedgerType type;
  final int points;            // Positif untuk kredit, negatif untuk debit
  final int balanceAfter;
  final String description;
  final String actorName;
  final DateTime timestamp;

  RewardLedgerEntry({
    required this.id,
    required this.userId,
    this.orderId,
    required this.type,
    required this.points,
    required this.balanceAfter,
    required this.description,
    required this.actorName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'orderId': orderId,
    'type': type.name,
    'points': points,
    'balanceAfter': balanceAfter,
    'description': description,
    'actorName': actorName,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RewardLedgerEntry.fromJson(Map<String, dynamic> json) => RewardLedgerEntry(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    orderId: json['orderId'],
    type: LedgerType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => LedgerType.creditOrder,
    ),
    points: json['points'] ?? 0,
    balanceAfter: json['balanceAfter'] ?? 0,
    description: json['description'] ?? '',
    actorName: json['actorName'] ?? 'Sistem',
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class RewardCatalogItem {
  final String id;
  final String partnerId;
  final String name;
  final String category;       // 'Sembako', 'Voucher', 'Lingkungan'
  final int pointsCost;
  final int stock;
  final String description;
  final String iconKey;
  final String providerName;

  RewardCatalogItem({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.category,
    required this.pointsCost,
    required this.stock,
    required this.description,
    required this.iconKey,
    required this.providerName,
  });

  RewardCatalogItem copyWith({int? stock}) {
    return RewardCatalogItem(
      id: id,
      partnerId: partnerId,
      name: name,
      category: category,
      pointsCost: pointsCost,
      stock: stock ?? this.stock,
      description: description,
      iconKey: iconKey,
      providerName: providerName,
    );
  }
}

class RedemptionCoupon {
  final String id;
  final String rewardId;
  final String rewardName;
  final int pointsSpent;
  final String redemptionCode; // e.g. "SRK-RWD-9941"
  final DateTime redeemedAt;
  final DateTime validUntil;
  final bool isClaimed;

  RedemptionCoupon({
    required this.id,
    required this.rewardId,
    required this.rewardName,
    required this.pointsSpent,
    required this.redemptionCode,
    required this.redeemedAt,
    required this.validUntil,
    this.isClaimed = false,
  });
}
