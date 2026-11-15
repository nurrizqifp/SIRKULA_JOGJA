enum OrderStatus {
  draft,
  waitingPartnerConfirmation,
  scheduled,
  assigned,
  inPickup,
  waitingCitizenConfirmation,
  completed,
  disputed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.draft:
        return 'Draf';
      case OrderStatus.waitingPartnerConfirmation:
        return 'Menunggu Konfirmasi BSU';
      case OrderStatus.scheduled:
        return 'Jadwal Ditetapkan';
      case OrderStatus.assigned:
        return 'Petugas Ditugaskan';
      case OrderStatus.inPickup:
        return 'Dalam Penjemputan';
      case OrderStatus.waitingCitizenConfirmation:
        return 'Menunggu Konfirmasi Warga';
      case OrderStatus.completed:
        return 'Selesai & Poin Diterima';
      case OrderStatus.disputed:
        return 'Disengketakan (Keberatan)';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.draft:
        return 0;
      case OrderStatus.waitingPartnerConfirmation:
        return 1;
      case OrderStatus.scheduled:
      case OrderStatus.assigned:
        return 2;
      case OrderStatus.inPickup:
        return 3;
      case OrderStatus.waitingCitizenConfirmation:
        return 4;
      case OrderStatus.completed:
        return 5;
      case OrderStatus.disputed:
      case OrderStatus.cancelled:
        return 4;
    }
  }
}

class OrderItemModel {
  final String commodityKey;    // 'jelantah' | 'pet_bottle'
  final String commodityName;
  final String unit;
  final double estimatedQuantity;
  final double? verifiedQuantity; // Hasil timbangan kader
  final double qualityFactor;     // 0.8, 1.0, 1.1
  final String? qualityNotes;
  final String? photoProofUrl;    // Foto timbangan / ember jelantah
  final int basePoints;

  OrderItemModel({
    required this.commodityKey,
    required this.commodityName,
    required this.unit,
    required this.estimatedQuantity,
    this.verifiedQuantity,
    this.qualityFactor = 1.0,
    this.qualityNotes,
    this.photoProofUrl,
    required this.basePoints,
  });

  int get calculatedPoints {
    if (verifiedQuantity == null) return 0;
    return ((verifiedQuantity! * basePoints) * qualityFactor).round();
  }

  Map<String, dynamic> toJson() => {
    'commodityKey': commodityKey,
    'commodityName': commodityName,
    'unit': unit,
    'estimatedQuantity': estimatedQuantity,
    'verifiedQuantity': verifiedQuantity,
    'qualityFactor': qualityFactor,
    'qualityNotes': qualityNotes,
    'photoProofUrl': photoProofUrl,
    'basePoints': basePoints,
  };

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    commodityKey: json['commodityKey'] ?? '',
    commodityName: json['commodityName'] ?? '',
    unit: json['unit'] ?? '',
    estimatedQuantity: (json['estimatedQuantity'] as num?)?.toDouble() ?? 0.0,
    verifiedQuantity: (json['verifiedQuantity'] as num?)?.toDouble(),
    qualityFactor: (json['qualityFactor'] as num?)?.toDouble() ?? 1.0,
    qualityNotes: json['qualityNotes'],
    photoProofUrl: json['photoProofUrl'],
    basePoints: json['basePoints'] ?? 0,
  );
}

class PickupOrderModel {
  final String id;
  final String orderNumber;      // e.g. "SRK-202611-0042"
  final String citizenId;
  final String citizenName;
  final String citizenPhone;
  final String bsuId;
  final String bsuName;
  final String pickupAddress;
  final double latitude;
  final double longitude;
  final String? accessNotes;
  final DateTime scheduledDate;
  final String timeSlot;         // "Pagi (08.00 - 11.00)" | "Siang (13.00 - 15.00)"
  final OrderStatus status;
  final List<OrderItemModel> items;
  final String? collectorId;
  final String? collectorName;
  final String? collectorPhone;
  final String? disputeReason;
  final DateTime createdAt;
  final DateTime? completedAt;

  PickupOrderModel({
    required this.id,
    required this.orderNumber,
    required this.citizenId,
    required this.citizenName,
    required this.citizenPhone,
    required this.bsuId,
    required this.bsuName,
    required this.pickupAddress,
    required this.latitude,
    required this.longitude,
    this.accessNotes,
    required this.scheduledDate,
    required this.timeSlot,
    required this.status,
    required this.items,
    this.collectorId,
    this.collectorName,
    this.collectorPhone,
    this.disputeReason,
    required this.createdAt,
    this.completedAt,
  });

  int get totalCalculatedPoints {
    return items.fold(0, (sum, item) => sum + item.calculatedPoints);
  }

  String get commoditiesSummary {
    return items.map((e) => '${e.commodityName} (${e.estimatedQuantity} ${e.unit})').join(', ');
  }

  PickupOrderModel copyWith({
    OrderStatus? status,
    List<OrderItemModel>? items,
    String? collectorId,
    String? collectorName,
    String? collectorPhone,
    String? disputeReason,
    DateTime? completedAt,
  }) {
    return PickupOrderModel(
      id: id,
      orderNumber: orderNumber,
      citizenId: citizenId,
      citizenName: citizenName,
      citizenPhone: citizenPhone,
      bsuId: bsuId,
      bsuName: bsuName,
      pickupAddress: pickupAddress,
      latitude: latitude,
      longitude: longitude,
      accessNotes: accessNotes,
      scheduledDate: scheduledDate,
      timeSlot: timeSlot,
      status: status ?? this.status,
      items: items ?? this.items,
      collectorId: collectorId ?? this.collectorId,
      collectorName: collectorName ?? this.collectorName,
      collectorPhone: collectorPhone ?? this.collectorPhone,
      disputeReason: disputeReason ?? this.disputeReason,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'citizenId': citizenId,
    'citizenName': citizenName,
    'citizenPhone': citizenPhone,
    'bsuId': bsuId,
    'bsuName': bsuName,
    'pickupAddress': pickupAddress,
    'latitude': latitude,
    'longitude': longitude,
    'accessNotes': accessNotes,
    'scheduledDate': scheduledDate.toIso8601String(),
    'timeSlot': timeSlot,
    'status': status.name,
    'items': items.map((e) => e.toJson()).toList(),
    'collectorId': collectorId,
    'collectorName': collectorName,
    'collectorPhone': collectorPhone,
    'disputeReason': disputeReason,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };
}
