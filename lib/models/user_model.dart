enum UserRole {
  citizen,   // Warga / Nasabah
  collector, // Kader / Kurir BSU
  adminBsu,  // Admin Bank Sampah Unit
  adminPlatform // Admin Platform Kota Yogyakarta
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String primaryAddress;
  final double latitude;
  final double longitude;
  final String? accessNotes;
  final bool hasPrivacyConsent;
  final DateTime? consentDate;
  final String? bsuAffiliation;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.primaryAddress,
    required this.latitude,
    required this.longitude,
    this.accessNotes,
    this.hasPrivacyConsent = true,
    this.consentDate,
    this.bsuAffiliation,
    this.isActive = true,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? primaryAddress,
    double? latitude,
    double? longitude,
    String? accessNotes,
    bool? hasPrivacyConsent,
    DateTime? consentDate,
    String? bsuAffiliation,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accessNotes: accessNotes ?? this.accessNotes,
      hasPrivacyConsent: hasPrivacyConsent ?? this.hasPrivacyConsent,
      consentDate: consentDate ?? this.consentDate,
      bsuAffiliation: bsuAffiliation ?? this.bsuAffiliation,
      isActive: isActive ?? this.isActive,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.citizen:
        return 'Warga / Nasabah';
      case UserRole.collector:
        return 'Kader / Kurir BSU';
      case UserRole.adminBsu:
        return 'Admin Pengelola BSU';
      case UserRole.adminPlatform:
        return 'Administrator Platform';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name,
    'primaryAddress': primaryAddress,
    'latitude': latitude,
    'longitude': longitude,
    'accessNotes': accessNotes,
    'hasPrivacyConsent': hasPrivacyConsent,
    'consentDate': consentDate?.toIso8601String(),
    'bsuAffiliation': bsuAffiliation,
    'isActive': isActive,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.citizen,
      ),
      primaryAddress: json['primaryAddress'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -7.7956,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 110.3695,
      accessNotes: json['accessNotes'],
      hasPrivacyConsent: json['hasPrivacyConsent'] ?? true,
      consentDate: json['consentDate'] != null ? DateTime.parse(json['consentDate']) : null,
      bsuAffiliation: json['bsuAffiliation'],
      isActive: json['isActive'] ?? true,
    );
  }
}
