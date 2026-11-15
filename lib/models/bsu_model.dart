class BsuPartnerModel {
  final String id;
  final String name;
  final String kelurahan;
  final String kemantren;
  final String address;
  final double latitude;
  final double longitude;
  final String operationalContact;
  final String operatingHours;
  final List<String> acceptedCommodities;
  final int activeCollectorCount;
  final bool isVerified;
  final double rating;

  BsuPartnerModel({
    required this.id,
    required this.name,
    required this.kelurahan,
    required this.kemantren,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.operationalContact,
    required this.operatingHours,
    required this.acceptedCommodities,
    required this.activeCollectorCount,
    this.isVerified = true,
    this.rating = 4.8,
  });

  bool accepts(String commodityKey) {
    return acceptedCommodities.contains(commodityKey);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kelurahan': kelurahan,
    'kemantren': kemantren,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'operationalContact': operationalContact,
    'operatingHours': operatingHours,
    'acceptedCommodities': acceptedCommodities,
    'activeCollectorCount': activeCollectorCount,
    'isVerified': isVerified,
    'rating': rating,
  };

  factory BsuPartnerModel.fromJson(Map<String, dynamic> json) {
    return BsuPartnerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      kelurahan: json['kelurahan'] ?? '',
      kemantren: json['kemantren'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -7.7956,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 110.3695,
      operationalContact: json['operationalContact'] ?? '',
      operatingHours: json['operatingHours'] ?? '',
      acceptedCommodities: List<String>.from(json['acceptedCommodities'] ?? []),
      activeCollectorCount: json['activeCollectorCount'] ?? 0,
      isVerified: json['isVerified'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }
}
