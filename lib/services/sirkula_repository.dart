import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/bsu_model.dart';
import '../models/order_model.dart';
import '../models/reward_model.dart';
import '../models/kpi_model.dart';
import 'haversine_service.dart';

class SirkulaRepository extends ChangeNotifier {
  static final SirkulaRepository _instance = SirkulaRepository._internal();
  factory SirkulaRepository() => _instance;

  SirkulaRepository._internal() {
    _initializeDemoData();
  }

  final _supabase = Supabase.instance.client;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  List<UserModel> get users => List.unmodifiable(_demoUsers);

  final List<BsuPartnerModel> _bsuList = [];
  List<BsuPartnerModel> get bsuList => List.unmodifiable(_bsuList);

  final List<PickupOrderModel> _orders = [];
  List<PickupOrderModel> get orders => List.unmodifiable(_orders);

  final List<RewardLedgerEntry> _ledger = [];
  List<RewardLedgerEntry> get ledger => List.unmodifiable(_ledger);

  final List<RewardCatalogItem> _rewards = [];
  List<RewardCatalogItem> get rewards => List.unmodifiable(_rewards);

  final List<RedemptionCoupon> _coupons = [];
  List<RedemptionCoupon> get coupons => List.unmodifiable(_coupons);

  final Map<String, int> _quizScores = {}; // quizId -> score
  Map<String, int> get quizScores => Map.unmodifiable(_quizScores);

  int getBalanceForUser(String userId) {
    final userLedger = _ledger.where((e) => e.userId == userId);
    if (userLedger.isEmpty) return 0;
    return userLedger.last.balanceAfter;
  }

  int get citizenBalance {
    if (_currentUser == null) return 0;
    return getBalanceForUser(_currentUser!.id);
  }

  List<UserModel> get collectors =>
      _demoUsers.where((u) => u.role == UserRole.collector && u.isActive).toList();

  // ----------------------------------------------------
  // AUTHENTICATION & PRODUCTION USER MANAGEMENT (SUPABASE)
  // ----------------------------------------------------
  Future<void> initSession() async {
    try {
      final sbUser = _supabase.auth.currentUser;
      if (sbUser != null) {
        final profile = await _fetchOrBuildProfile(sbUser);
        if (!profile.isActive) {
          await logout();
          return;
        }
        _currentUser = profile;
        await loadUsers();
        await loadCloudData();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<UserModel> _fetchOrBuildProfile(User sbUser) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', sbUser.id)
          .maybeSingle();

      if (response != null) {
        final roleStr = response['role'] as String? ?? 'citizen';
        UserRole role;
        switch (roleStr) {
          case 'collector':
            role = UserRole.collector;
            break;
          case 'adminBsu':
          case 'admin_bsu':
            role = UserRole.adminBsu;
            break;
          case 'adminPlatform':
          case 'admin_platform':
            role = UserRole.adminPlatform;
            break;
          default:
            role = UserRole.citizen;
        }
        final u = UserModel(
          id: sbUser.id,
          name: response['full_name'] ?? sbUser.email?.split('@').first ?? 'Warga Sirkula',
          email: sbUser.email ?? response['email'] ?? '',
          phone: response['phone'] ?? '-',
          role: role,
          primaryAddress: response['primary_address'] ?? 'Kota Yogyakarta',
          latitude: (response['latitude'] as num?)?.toDouble() ?? -7.7892,
          longitude: (response['longitude'] as num?)?.toDouble() ?? 110.3640,
          accessNotes: response['access_notes'],
          hasPrivacyConsent: response['has_privacy_consent'] ?? true,
          consentDate: response['consent_at'] != null ? DateTime.tryParse(response['consent_at']) : null,
          bsuAffiliation: response['bsu_affiliation'],
          isActive: response['is_active'] ?? true,
        );
        _syncToLocalUserList(u);
        return u;
      }
    } catch (_) {}

    // Fallback ke metadata Supabase Auth
    final meta = sbUser.userMetadata ?? {};
    final roleStr = meta['role'] as String? ?? 'citizen';
    UserRole role;
    switch (roleStr) {
      case 'collector':
        role = UserRole.collector;
        break;
      case 'adminBsu':
      case 'admin_bsu':
        role = UserRole.adminBsu;
        break;
      case 'adminPlatform':
      case 'admin_platform':
        role = UserRole.adminPlatform;
        break;
      default:
        role = UserRole.citizen;
    }

    final u = UserModel(
      id: sbUser.id,
      name: meta['full_name'] ?? meta['name'] ?? sbUser.email?.split('@').first ?? 'Warga Sirkula',
      email: sbUser.email ?? '',
      phone: meta['phone'] ?? '-',
      role: role,
      primaryAddress: meta['primary_address'] ?? 'Kota Yogyakarta',
      latitude: -7.7892,
      longitude: 110.3640,
      accessNotes: meta['access_notes'] ?? '',
      hasPrivacyConsent: true,
      consentDate: DateTime.now(),
      isActive: true,
    );
    _syncToLocalUserList(u);
    return u;
  }

  void _syncToLocalUserList(UserModel u) {
    final idx = _demoUsers.indexWhere((item) => item.id == u.id || item.email.toLowerCase() == u.email.toLowerCase());
    if (idx != -1) {
      _demoUsers[idx] = u;
    } else {
      _demoUsers.add(u);
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final res = await _supabase.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    if (res.user != null) {
      final profile = await _fetchOrBuildProfile(res.user!);
      if (!profile.isActive) {
        await logout();
        throw const AuthException('Akun Anda telah dinonaktifkan oleh admin.');
      }
      _currentUser = profile;
      await loadUsers();
      await loadCloudData();
      notifyListeners();
    }
    return res;
  }

  /// Verifikasi kode OTP yang dikirim ke email saat pendaftaran.
  Future<AuthResponse> verifyEmailOtp(String email, String token) async {
    final res = await _supabase.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
      token: token.trim(),
    );
    if (res.user != null) {
      _currentUser = await _fetchOrBuildProfile(res.user!);
      await loadUsers();
      await loadCloudData();
      notifyListeners();
    }
    return res;
  }

  Future<void> resendSignupOtp(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
    );
  }

  Future<void> sendPasswordResetOtp(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  Future<void> verifyRecoveryAndUpdatePassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _supabase.auth.verifyOTP(
      type: OtpType.recovery,
      email: email.trim().toLowerCase(),
      token: token.trim(),
    );
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    await logout();
  }

  Future<AuthResponse> registerCitizen({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String accessNotes,
    required bool consentGranted,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Role TIDAK dikirim dari klien; server selalu menetapkan 'citizen'.
    final res = await _supabase.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'full_name': name.trim(),
        'phone': phone.trim(),
        'primary_address': address.trim(),
        'access_notes': accessNotes.trim(),
      },
    );

    // Jika konfirmasi email aktif, session null sampai OTP diverifikasi.
    if (res.session != null && res.user != null) {
      _currentUser = await _fetchOrBuildProfile(res.user!);
      await loadCloudData();
      notifyListeners();
    }

    return res;
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    _currentUser = null;
    _orders.clear();
    _ledger.clear();
    _coupons.clear();
    _quizScores.clear();
    _demoUsers.clear();
    notifyListeners();
  }

  // ----------------------------------------------------
  // ADMIN USER & ROLE MANAGEMENT (RBAC)
  // ----------------------------------------------------
  static String _roleToDb(UserRole r) => r.name; // citizen|collector|adminBsu|adminPlatform

  UserRole _roleFromDb(String? s) {
    switch (s) {
      case 'collector':
        return UserRole.collector;
      case 'adminBsu':
      case 'admin_bsu':
        return UserRole.adminBsu;
      case 'adminPlatform':
      case 'admin_platform':
        return UserRole.adminPlatform;
      default:
        return UserRole.citizen;
    }
  }

  bool get _isAdmin =>
      _currentUser?.role == UserRole.adminBsu || _currentUser?.role == UserRole.adminPlatform;

  /// Memuat daftar pengguna dari Supabase (hanya untuk admin; dibatasi RLS).
  Future<void> loadUsers() async {
    if (!_isAdmin) return;
    try {
      final rows = await _supabase.from('profiles').select().order('created_at');
      _demoUsers
        ..clear()
        ..addAll((rows as List).map((r) => UserModel(
              id: r['id'],
              name: r['full_name'] ?? '-',
              email: r['email'] ?? '',
              phone: r['phone'] ?? '-',
              role: _roleFromDb(r['role']),
              primaryAddress: r['primary_address'] ?? '-',
              latitude: (r['latitude'] as num?)?.toDouble() ?? -7.7892,
              longitude: (r['longitude'] as num?)?.toDouble() ?? 110.3640,
              accessNotes: r['access_notes'],
              hasPrivacyConsent: r['has_privacy_consent'] ?? true,
              consentDate: r['consent_at'] != null ? DateTime.tryParse(r['consent_at']) : null,
              bsuAffiliation: r['bsu_affiliation'],
              isActive: r['is_active'] ?? true,
            )));
      notifyListeners();
    } catch (_) {}
  }

  /// Mengembalikan null jika sukses, atau pesan error.
  Future<String?> updateUserRole(String userId, UserRole newRole, {String? bsuAffiliation}) async {
    final me = _currentUser;
    if (me == null || !_isAdmin) return 'Anda tidak memiliki hak akses.';
    if (me.id == userId) return 'Anda tidak dapat mengubah peran akun Anda sendiri.';
    final index = _demoUsers.indexWhere((u) => u.id == userId);
    if (index == -1) return 'Pengguna tidak ditemukan.';
    final target = _demoUsers[index];

    if (me.role == UserRole.adminBsu) {
      if (newRole == UserRole.adminBsu || newRole == UserRole.adminPlatform) {
        return 'Admin BSU hanya dapat menetapkan peran Warga atau Kader.';
      }
      if (target.role == UserRole.adminBsu || target.role == UserRole.adminPlatform) {
        return 'Admin BSU tidak dapat mengubah akun administrator.';
      }
    }
    if ((newRole == UserRole.collector || newRole == UserRole.adminBsu) &&
        (bsuAffiliation == null || bsuAffiliation.isEmpty)) {
      return 'Afiliasi BSU wajib dipilih untuk Kader/Admin BSU.';
    }
    final affiliation =
        (newRole == UserRole.collector || newRole == UserRole.adminBsu) ? bsuAffiliation : null;

    try {
      await _supabase.from('profiles').update({
        'role': _roleToDb(newRole),
        'bsu_affiliation': affiliation,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      return 'Gagal menyimpan ke server: $e';
    }
    _demoUsers[index] = target.copyWith(role: newRole, bsuAffiliation: affiliation);
    notifyListeners();
    return null;
  }

  Future<String?> toggleUserStatus(String userId) async {
    final me = _currentUser;
    if (me == null || !_isAdmin) return 'Anda tidak memiliki hak akses.';
    if (me.id == userId) return 'Anda tidak dapat menonaktifkan akun Anda sendiri.';
    final index = _demoUsers.indexWhere((u) => u.id == userId);
    if (index == -1) return 'Pengguna tidak ditemukan.';
    final target = _demoUsers[index];
    if (me.role == UserRole.adminBsu &&
        (target.role == UserRole.adminBsu || target.role == UserRole.adminPlatform)) {
      return 'Admin BSU tidak dapat mengubah akun administrator.';
    }
    try {
      await _supabase.from('profiles').update({
        'is_active': !target.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      return 'Gagal menyimpan ke server: $e';
    }
    _demoUsers[index] = target.copyWith(isActive: !target.isActive);
    notifyListeners();
    return null;
  }

  // ----------------------------------------------------
  // CLOUD DATA SYNC (SUPABASE POSTGRESQL)
  // ----------------------------------------------------
  Future<void> loadCloudData() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      // 1. Load BSU & komoditas yang diterima
      final bsuRows = await _supabase.from('bsu_units').select().eq('is_active', true);
      final bsuCommRows = await _supabase.from('bsu_commodities').select().eq('is_active', true);
      final Map<String, List<String>> commByBsu = {};
      for (final r in (bsuCommRows as List)) {
        final bid = r['bsu_id']?.toString() ?? '';
        final ckey = r['commodity_key']?.toString() ?? '';
        if (bid.isNotEmpty && ckey.isNotEmpty) {
          commByBsu.putIfAbsent(bid, () => []).add(ckey);
        }
      }
      if ((bsuRows as List).isNotEmpty) {
        _bsuList
          ..clear()
          ..addAll(bsuRows.map((b) {
            final id = b['id'].toString();
            return BsuPartnerModel(
              id: id,
              name: b['name'] ?? '-',
              kelurahan: b['kelurahan'] ?? '-',
              kemantren: b['kemantren'] ?? '-',
              address: b['address'] ?? '-',
              latitude: (b['latitude'] as num?)?.toDouble() ?? -7.7890,
              longitude: (b['longitude'] as num?)?.toDouble() ?? 110.3601,
              operationalContact: b['operational_contact'] ?? '-',
              operatingHours: b['operating_hours'] ?? '08.00 - 15.00 WIB',
              acceptedCommodities: commByBsu[id] ?? const ['jelantah', 'pet_bottle'],
              activeCollectorCount: 2,
              rating: 4.8,
            );
          }));
      }
    } catch (_) {}

    try {
      // 2. Load Rewards
      final rwdRows = await _supabase.from('rewards').select().eq('is_active', true);
      if ((rwdRows as List).isNotEmpty) {
        _rewards
          ..clear()
          ..addAll(rwdRows.map((r) => RewardCatalogItem(
                id: r['id'].toString(),
                partnerId: r['partner_id']?.toString() ?? '',
                name: r['name'] ?? '-',
                category: r['category'] ?? 'Sembako',
                pointsCost: (r['points_cost'] as num?)?.toInt() ?? 0,
                stock: (r['stock'] as num?)?.toInt() ?? 0,
                description: r['description'] ?? '',
                iconKey: r['icon_key'] ?? 'eco',
                providerName: r['provider_name'] ?? 'Mitra BSU',
              )));
      }
    } catch (_) {}

    try {
      // 3. Load Pickup Orders & Order Items
      final ordRows = await _supabase
          .from('pickup_orders')
          .select()
          .order('created_at', ascending: false);
      final itemRows = await _supabase.from('order_items').select();
      final Map<String, List<OrderItemModel>> itemsByOrder = {};
      for (final ir in (itemRows as List)) {
        final oid = ir['order_id']?.toString() ?? '';
        if (oid.isEmpty) continue;
        itemsByOrder.putIfAbsent(oid, () => []).add(OrderItemModel(
              commodityKey: ir['commodity_key'] ?? '',
              commodityName: ir['commodity_name'] ?? '',
              unit: ir['unit'] ?? '',
              estimatedQuantity: (ir['estimated_quantity'] as num?)?.toDouble() ?? 0,
              verifiedQuantity: (ir['verified_quantity'] as num?)?.toDouble(),
              qualityFactor: (ir['quality_factor'] as num?)?.toDouble() ?? 1.0,
              qualityNotes: ir['quality_notes'],
              photoProofUrl: ir['photo_proof_path'],
              basePoints: (ir['points_per_unit'] as num?)?.toInt() ?? 1000,
            ));
      }

      _orders
        ..clear()
        ..addAll((ordRows as List).map((o) {
          final oid = o['id'].toString();
          final citizenId = o['citizen_id'].toString();
          final bsuId = o['bsu_id'].toString();
          final collectorId = o['assigned_collector_id']?.toString();
          final citizen = _demoUsers.where((u) => u.id == citizenId).firstOrNull;
          final collector = collectorId == null
              ? null
              : _demoUsers.where((u) => u.id == collectorId).firstOrNull;
          final bsu = _bsuList.where((b) => b.id == bsuId).firstOrNull;
          return PickupOrderModel(
            id: oid,
            orderNumber: o['order_number'] ?? oid,
            citizenId: citizenId,
            citizenName: citizen?.name ?? 'Warga Sirkula',
            citizenPhone: citizen?.phone ?? '-',
            bsuId: bsuId,
            bsuName: bsu?.name ?? 'Mitra BSU',
            pickupAddress: o['pickup_address'] ?? '-',
            latitude: (o['latitude'] as num?)?.toDouble() ?? -7.7892,
            longitude: (o['longitude'] as num?)?.toDouble() ?? 110.3640,
            accessNotes: o['access_notes'],
            scheduledDate: DateTime.tryParse(o['scheduled_date']?.toString() ?? '') ?? DateTime.now(),
            timeSlot: o['time_slot'] ?? '-',
            status: OrderStatus.values.firstWhere(
              (s) => s.name == o['status'],
              orElse: () => OrderStatus.waitingPartnerConfirmation,
            ),
            items: itemsByOrder[oid] ?? [],
            collectorId: collectorId,
            collectorName: collector?.name,
            collectorPhone: collector?.phone,
            disputeReason: o['dispute_reason'],
            createdAt: DateTime.tryParse(o['created_at']?.toString() ?? '') ?? DateTime.now(),
            completedAt: o['completed_at'] != null
                ? DateTime.tryParse(o['completed_at'].toString())
                : null,
          );
        }));
    } catch (_) {}

    try {
      // 4. Load Point Ledger
      final ldgRows = await _supabase
          .from('point_ledger')
          .select()
          .order('created_at', ascending: true);
      _ledger
        ..clear()
        ..addAll((ldgRows as List).map((l) => RewardLedgerEntry(
              id: l['id'].toString(),
              userId: l['user_id'].toString(),
              orderId: l['order_id']?.toString(),
              type: LedgerType.values.firstWhere(
                (t) => t.name == l['type'],
                orElse: () => LedgerType.creditOrder,
              ),
              points: (l['points'] as num?)?.toInt() ?? 0,
              balanceAfter: (l['balance_after'] as num?)?.toInt() ?? 0,
              description: l['description'] ?? '',
              actorName: l['actor_name'] ?? 'Sistem',
              timestamp: DateTime.tryParse(l['created_at']?.toString() ?? '') ?? DateTime.now(),
            )));
    } catch (_) {}

    try {
      // 5. Load Redemptions
      final rdmRows = await _supabase
          .from('redemptions')
          .select()
          .order('redeemed_at', ascending: false);
      _coupons
        ..clear()
        ..addAll((rdmRows as List).map((c) => RedemptionCoupon(
              id: c['id'].toString(),
              rewardId: c['reward_id'].toString(),
              rewardName: c['reward_name'] ?? '',
              pointsSpent: (c['points_spent'] as num?)?.toInt() ?? 0,
              redemptionCode: c['redemption_code'] ?? '',
              redeemedAt: DateTime.tryParse(c['redeemed_at']?.toString() ?? '') ?? DateTime.now(),
              validUntil: DateTime.tryParse(c['valid_until']?.toString() ?? '') ??
                  DateTime.now().add(const Duration(days: 30)),
              isClaimed: c['status'] == 'used',
            )));
    } catch (_) {}

    try {
      // 6. Load Quiz Attempts milik user aktif
      final quizRows = await _supabase
          .from('quiz_attempts')
          .select()
          .eq('user_id', user.id);
      _quizScores.clear();
      for (final q in (quizRows as List)) {
        final qid = q['quiz_id']?.toString() ?? '';
        final score = (q['best_score'] as num?)?.toInt() ?? 0;
        if (qid.isNotEmpty) _quizScores[qid] = score;
      }
    } catch (_) {}

    notifyListeners();
  }

  // ----------------------------------------------------
  // BSU & DISTANCE (HAVERSINE)
  // ----------------------------------------------------
  List<BsuPartnerModel> getBsusSortedByDistance() {
    final userLat = _currentUser?.latitude ?? -7.7892;
    final userLon = _currentUser?.longitude ?? 110.3640;

    final list = List<BsuPartnerModel>.from(_bsuList);
    list.sort((a, b) {
      final distA = HaversineService.calculateDistanceKm(
        lat1: userLat,
        lon1: userLon,
        lat2: a.latitude,
        lon2: a.longitude,
      );
      final distB = HaversineService.calculateDistanceKm(
        lat1: userLat,
        lon1: userLon,
        lat2: b.latitude,
        lon2: b.longitude,
      );
      return distA.compareTo(distB);
    });
    return list;
  }

  double getDistanceToBsu(BsuPartnerModel bsu) {
    final userLat = _currentUser?.latitude ?? -7.7892;
    final userLon = _currentUser?.longitude ?? 110.3640;
    return HaversineService.calculateDistanceKm(
      lat1: userLat,
      lon1: userLon,
      lat2: bsu.latitude,
      lon2: bsu.longitude,
    );
  }

  // ----------------------------------------------------
  // ORDER CREATION & LIFECYCLE
  // ----------------------------------------------------
  Future<PickupOrderModel> createOrder({
    required String bsuId,
    required DateTime scheduledDate,
    required String timeSlot,
    required String pickupAddress,
    required String accessNotes,
    required List<OrderItemModel> items,
  }) async {
    final bsu = _bsuList.firstWhere((b) => b.id == bsuId, orElse: () => throw ArgumentError('BSU tidak ditemukan.'));
    final user = _currentUser;
    if (user == null) throw StateError('Sesi berakhir. Silakan masuk kembali.');
    if (user.role != UserRole.citizen) throw StateError('Hanya akun Warga yang dapat membuat penjemputan.');
    if (!user.isActive) throw StateError('Akun dinonaktifkan.');
    if (items.isEmpty) throw ArgumentError('Pilih minimal satu komoditas.');
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    if (scheduledDate.isBefore(dayStart) || scheduledDate.isAfter(dayStart.add(const Duration(days: 30)))) {
      throw ArgumentError('Tanggal penjemputan harus dalam 30 hari ke depan.');
    }
    for (final i in items) {
      if (!bsu.acceptedCommodities.contains(i.commodityKey)) {
        throw ArgumentError('${bsu.name} tidak menerima ${i.commodityName}.');
      }
      if (i.estimatedQuantity < 1 || i.estimatedQuantity > 100) {
        throw ArgumentError('Estimasi ${i.commodityName} harus 1–100 ${i.unit}.');
      }
    }
    final randomNum = 1000 + _orders.length + 1;
    final orderNumber = 'SRK-202611-00$randomNum';
    final inserted = await _supabase
        .from('pickup_orders')
        .insert({
          'order_number': orderNumber,
          'citizen_id': user.id,
          'bsu_id': bsu.id,
          'pickup_address': pickupAddress,
          'latitude': user.latitude,
          'longitude': user.longitude,
          'access_notes': accessNotes,
          'scheduled_date': scheduledDate.toIso8601String().split('T').first,
          'time_slot': timeSlot,
          'status': OrderStatus.waitingPartnerConfirmation.name,
        })
        .select()
        .single();

    final orderId = inserted['id'].toString();
    await _supabase.from('order_items').insert(
          items
              .map((i) => {
                    'order_id': orderId,
                    'commodity_key': i.commodityKey,
                    'commodity_name': i.commodityName,
                    'unit': i.unit,
                    'estimated_quantity': i.estimatedQuantity,
                    'points_per_unit': i.basePoints,
                    'quality_factor': i.qualityFactor,
                  })
              .toList(),
        );

    final order = PickupOrderModel(
      id: orderId,
      orderNumber: orderNumber,
      citizenId: user.id,
      citizenName: user.name,
      citizenPhone: user.phone,
      bsuId: bsu.id,
      bsuName: bsu.name,
      pickupAddress: pickupAddress,
      latitude: user.latitude,
      longitude: user.longitude,
      accessNotes: accessNotes,
      scheduledDate: scheduledDate,
      timeSlot: timeSlot,
      status: OrderStatus.waitingPartnerConfirmation,
      items: items,
      createdAt: DateTime.tryParse(inserted['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  Future<void> _persistOrderUpdate(String orderId, Map<String, dynamic> fields) async {
    try {
      await _supabase.from('pickup_orders').update(fields).eq('id', orderId);
    } catch (_) {}
  }

  Future<void> _persistOrderItems(String orderId, List<OrderItemModel> items) async {
    try {
      for (final item in items) {
        await _supabase
            .from('order_items')
            .update({
              'verified_quantity': item.verifiedQuantity,
              'quality_factor': item.qualityFactor,
              'quality_notes': item.qualityNotes,
              'photo_proof_path': item.photoProofUrl,
            })
            .eq('order_id', orderId)
            .eq('commodity_key', item.commodityKey);
      }
    } catch (_) {}
  }

  Future<void> _persistLedgerEntry(RewardLedgerEntry entry) async {
    try {
      await _supabase.from('point_ledger').insert({
        'id': entry.id,
        'user_id': entry.userId,
        'order_id': entry.orderId,
        'type': entry.type == LedgerType.adminAdjustment ? 'adjustment' : entry.type.name,
        'points': entry.points,
        'balance_after': entry.balanceAfter,
        'description': entry.description,
        'actor_name': entry.actorName,
      });
    } catch (_) {}
  }

  void assignCollector({
    required String orderId,
    required String collectorId,
    required String collectorName,
    required String collectorPhone,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.assigned,
        collectorId: collectorId,
        collectorName: collectorName,
        collectorPhone: collectorPhone,
      );
      _persistOrderUpdate(orderId, {
        'status': OrderStatus.assigned.name,
        'assigned_collector_id': collectorId,
      });
      notifyListeners();
    }
  }

  void startPickup(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      if (_orders[index].status != OrderStatus.assigned) return;
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.inPickup,
      );
      _persistOrderUpdate(orderId, {'status': OrderStatus.inPickup.name});
      notifyListeners();
    }
  }

  /// Kader submits verified measurements on the field
  void submitMeasurement({
    required String orderId,
    required List<OrderItemModel> verifiedItems,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      if (_orders[index].status != OrderStatus.inPickup) return;
      if (verifiedItems.isEmpty ||
          verifiedItems.any((i) => i.verifiedQuantity == null || i.verifiedQuantity! <= 0 || i.verifiedQuantity! > 1000)) {
        throw ArgumentError('Jumlah terverifikasi harus lebih dari 0 dan maksimal 1000.');
      }
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.waitingCitizenConfirmation,
        items: verifiedItems,
      );
      _persistOrderItems(orderId, verifiedItems);
      _persistOrderUpdate(orderId, {'status': OrderStatus.waitingCitizenConfirmation.name});
      notifyListeners();
    }
  }

  /// Citizen reviews and confirms the weighing results -> Poin credited to Reward Ledger!
  void citizenConfirmMeasurement(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      // Cegah kredit ganda & akses lintas pengguna.
      if (order.status != OrderStatus.waitingCitizenConfirmation) return;
      if (_currentUser == null || order.citizenId != _currentUser!.id) return;
      if (order.items.any((i) => i.verifiedQuantity == null || i.verifiedQuantity! <= 0)) return;
      final pointsEarned = order.totalCalculatedPoints;
      final newBalance = getBalanceForUser(order.citizenId) + pointsEarned;

      final now = DateTime.now();
      _orders[index] = order.copyWith(
        status: OrderStatus.completed,
        completedAt: now,
      );

      // Record in audited Reward Ledger
      final ledgerEntry = RewardLedgerEntry(
        id: 'ldg_${now.millisecondsSinceEpoch}',
        userId: order.citizenId,
        orderId: order.id,
        type: LedgerType.creditOrder,
        points: pointsEarned,
        balanceAfter: newBalance,
        description:
            'Reward penjemputan ${order.orderNumber} (${order.items.map((i) => '${i.verifiedQuantity} ${i.unit} ${i.commodityName} [Mutu ${i.qualityFactor}x]').join(', ')})',
        actorName: order.collectorName ?? 'Kader BSU',
        timestamp: now,
      );
      _ledger.add(ledgerEntry);

      _persistOrderUpdate(orderId, {
        'status': OrderStatus.completed.name,
        'completed_at': now.toIso8601String(),
      });
      _persistLedgerEntry(ledgerEntry);

      notifyListeners();
    }
  }

  /// Citizen raises dispute if measurement disagrees
  void citizenDisputeMeasurement({
    required String orderId,
    required String reason,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      if (_orders[index].status != OrderStatus.waitingCitizenConfirmation) return;
      if (reason.trim().length < 10) {
        throw ArgumentError('Alasan sanggahan minimal 10 karakter.');
      }
      final trimmed = reason.trim();
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.disputed,
        disputeReason: trimmed,
      );
      _persistOrderUpdate(orderId, {
        'status': OrderStatus.disputed.name,
        'dispute_reason': trimmed,
      });
      notifyListeners();
    }
  }

  /// Admin resolves dispute
  void resolveDispute({
    required String orderId,
    required List<OrderItemModel> finalItems,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.waitingCitizenConfirmation,
        items: finalItems,
        disputeReason: null,
      );
      _persistOrderItems(orderId, finalItems);
      _persistOrderUpdate(orderId, {
        'status': OrderStatus.waitingCitizenConfirmation.name,
        'dispute_reason': null,
      });
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // REWARD REDEMPTION
  // ----------------------------------------------------
  bool redeemReward(String rewardId) {
    if (_currentUser == null || !_currentUser!.isActive) return false;
    final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
    if (rewardIndex == -1) return false;
    final reward = _rewards[rewardIndex];

    if (reward.stock <= 0 || citizenBalance < reward.pointsCost) {
      return false;
    }

    final now = DateTime.now();
    final newBalance = citizenBalance - reward.pointsCost;
    _rewards[rewardIndex] = reward.copyWith(stock: reward.stock - 1);

    final couponCode = 'SRK-RWD-${1000 + _coupons.length + 1}';
    final coupon = RedemptionCoupon(
      id: 'cpn_${now.millisecondsSinceEpoch}',
      rewardId: reward.id,
      rewardName: reward.name,
      pointsSpent: reward.pointsCost,
      redemptionCode: couponCode,
      redeemedAt: now,
      validUntil: now.add(const Duration(days: 30)),
    );
    _coupons.insert(0, coupon);

    final ledgerEntry = RewardLedgerEntry(
      id: 'ldg_${now.millisecondsSinceEpoch}',
      userId: _currentUser!.id,
      type: LedgerType.debitRedeem,
      points: -reward.pointsCost,
      balanceAfter: newBalance,
      description: 'Penukaran reward: ${reward.name} (Kode: $couponCode)',
      actorName: _currentUser!.name,
      timestamp: now,
    );
    _ledger.add(ledgerEntry);

    _persistRedemption(coupon, _currentUser!.id);
    _persistLedgerEntry(ledgerEntry);

    notifyListeners();
    return true;
  }

  Future<void> _persistRedemption(RedemptionCoupon c, String userId) async {
    try {
      await _supabase.from('redemptions').insert({
        'id': c.id,
        'user_id': userId,
        'reward_id': c.rewardId,
        'reward_name': c.rewardName,
        'points_spent': c.pointsSpent,
        'redemption_code': c.redemptionCode,
        'status': 'active',
        'valid_until': c.validUntil.toIso8601String(),
        'redeemed_at': c.redeemedAt.toIso8601String(),
      });
    } catch (_) {}
  }

  // ----------------------------------------------------
  // EDUCATION & QUIZ
  // ----------------------------------------------------
  /// Mencatat skor kuis dan memberikan bonus 50 poin (hanya 1x per quizId jika skor >= 60).
  bool recordQuizScore(String quizId, int score) {
    final user = _currentUser;
    if (user == null) return false;

    final alreadyAttempted = _quizScores.containsKey(quizId);
    final prevScore = _quizScores[quizId] ?? 0;
    if (score > prevScore) {
      _quizScores[quizId] = score;
    }

    bool bonusGranted = false;
    if (!alreadyAttempted && score >= 60) {
      const bonusPoints = 50;
      final now = DateTime.now();
      final newBalance = getBalanceForUser(user.id) + bonusPoints;
      final ledgerEntry = RewardLedgerEntry(
        id: 'ldg_${now.millisecondsSinceEpoch}',
        userId: user.id,
        type: LedgerType.creditEducation,
        points: bonusPoints,
        balanceAfter: newBalance,
        description: 'Bonus literasi 5 Aksi Mas JOS (Skor: $score%)',
        actorName: 'Akademi Mas JOS',
        timestamp: now,
      );
      _ledger.add(ledgerEntry);
      _persistLedgerEntry(ledgerEntry);
      bonusGranted = true;
    }

    _persistQuizAttempt(user.id, quizId, _quizScores[quizId] ?? score, bonusGranted || alreadyAttempted);
    notifyListeners();
    return bonusGranted;
  }

  Future<void> _persistQuizAttempt(String userId, String quizId, int bestScore, bool bonusClaimed) async {
    try {
      await _supabase.from('quiz_attempts').upsert({
        'user_id': userId,
        'quiz_id': quizId,
        'best_score': bestScore,
        'bonus_claimed': bonusClaimed,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,quiz_id');
    } catch (_) {}
  }

  // ----------------------------------------------------
  // KPI IMPACT METRICS
  // ----------------------------------------------------
  KpiImpactMetrics computeKpiMetrics() {
    double totalPet = 0;
    double totalJelantah = 0;
    int completed = 0;
    int disputed = 0;
    int verifiedComplete = 0;
    final Map<String, int> ordersPerCitizen = {};

    for (final o in _orders) {
      ordersPerCitizen[o.citizenId] = (ordersPerCitizen[o.citizenId] ?? 0) + 1;
      if (o.status == OrderStatus.completed) {
        completed++;
        for (final item in o.items) {
          if (item.commodityKey == 'pet_bottle') {
            totalPet += (item.verifiedQuantity ?? 0);
          } else if (item.commodityKey == 'jelantah') {
            totalJelantah += (item.verifiedQuantity ?? 0);
          }
        }
      }
      if (o.status == OrderStatus.disputed) disputed++;
      if (o.items.every((i) => i.verifiedQuantity != null && i.photoProofUrl != null)) {
        verifiedComplete++;
      }
    }

    final registeredCitizens = _demoUsers.where((u) => u.role == UserRole.citizen).length;
    final activeCitizens = ordersPerCitizen.keys.length;
    final repeatCitizens = ordersPerCitizen.values.where((c) => c >= 2).length;
    final repeatRate = activeCitizens == 0 ? 0.0 : (repeatCitizens / activeCitizens) * 100.0;
    final completenessRate = _orders.isEmpty ? 100.0 : (verifiedComplete / _orders.length) * 100.0;

    final quizAvg = _quizScores.isEmpty
        ? 0.0
        : _quizScores.values.reduce((a, b) => a + b) / _quizScores.length;

    return KpiImpactMetrics(
      totalPetKg: totalPet,
      totalJelantahLiter: totalJelantah,
      totalOrders: _orders.length,
      completedOrders: completed,
      disputedOrders: disputed,
      registeredHouseholds: registeredCitizens,
      activeHouseholds: activeCitizens,
      verificationCompletenessRate: completenessRate,
      preTestScoreAvg: 0.0,
      postTestScoreAvg: quizAvg,
      repeatTransactionRate: repeatRate,
    );
  }

  String _csvEscape(Object? value) {
    final s = (value ?? '').toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Menghasilkan laporan rekapitulasi lengkap berformat CSV untuk rekonsiliasi BSU & DLH.
  String generateRecapCsv() {
    final kpi = computeKpiMetrics();
    final now = DateTime.now();
    final buf = StringBuffer();

    buf.writeln('LAPORAN REKAPITULASI SIRKULA-JOGJA');
    buf.writeln('Dicetak Pada,${_csvEscape(now.toIso8601String())}');
    buf.writeln('Diekspor Oleh,${_csvEscape(_currentUser?.name ?? "Admin")}');
    buf.writeln();

    buf.writeln('RINGKASAN KPI DAMPAK');
    buf.writeln('Metrik,Nilai');
    buf.writeln('Total Order,${kpi.totalOrders}');
    buf.writeln('Order Selesai,${kpi.completedOrders}');
    buf.writeln('Order Sengketa,${kpi.disputedOrders}');
    buf.writeln('Total Botol PET (Kg),${kpi.totalPetKg.toStringAsFixed(2)}');
    buf.writeln('Total Minyak Jelantah (Liter),${kpi.totalJelantahLiter.toStringAsFixed(2)}');
    buf.writeln('KK Terdaftar,${kpi.registeredHouseholds}');
    buf.writeln('KK Aktif,${kpi.activeHouseholds}');
    buf.writeln('Kelengkapan Verifikasi (%),${kpi.verificationCompletenessRate.toStringAsFixed(1)}');
    buf.writeln('Repeat Transaction Rate (%),${kpi.repeatTransactionRate.toStringAsFixed(1)}');
    buf.writeln();

    buf.writeln('DETAIL TRANSAKSI PENJEMPUTAN');
    buf.writeln('No Order,Tanggal,Slot Waktu,Warga,BSU,Kader,Status,Detail Komoditas,Total Poin,Catatan Sengketa');
    for (final o in _orders) {
      final itemsText = o.items
          .map((i) => '${i.commodityName}: est ${i.estimatedQuantity} ${i.unit}, ver ${i.verifiedQuantity ?? "-"} ${i.unit} (${i.qualityFactor}x)')
          .join(' | ');
      buf.writeln([
        o.orderNumber,
        o.scheduledDate.toIso8601String().split('T').first,
        o.timeSlot,
        o.citizenName,
        o.bsuName,
        o.collectorName ?? '-',
        o.status.displayName,
        itemsText,
        o.totalCalculatedPoints,
        o.disputeReason ?? '-',
      ].map(_csvEscape).join(','));
    }
    buf.writeln();

    buf.writeln('REKAPITULASI PENGGUNA');
    buf.writeln('Nama,Email,Peran,Afiliasi BSU,Status Aktif,Saldo Poin');
    for (final u in _demoUsers) {
      buf.writeln([
        u.name,
        u.email,
        u.roleDisplayName,
        u.bsuAffiliation ?? '-',
        u.isActive ? 'Aktif' : 'Nonaktif',
        getBalanceForUser(u.id),
      ].map(_csvEscape).join(','));
    }

    return buf.toString();
  }

  // ----------------------------------------------------
  // PRODUCTION INITIALIZATION (Mulai Bersih dari 0)
  // ----------------------------------------------------
  final List<UserModel> _demoUsers = [];

  void _initializeDemoData() {
    _currentUser = null; // Tidak ada user login default
    _orders.clear();
    _ledger.clear();
    _coupons.clear();

    // Data Master Mitra BSU Yogyakarta (fallback sebelum cloud selesai dimuat)
    _bsuList.addAll([
      BsuPartnerModel(
        id: '11111111-1111-4111-8111-111111111101',
        name: 'Bank Sampah Lintas Winongo',
        kelurahan: 'Bumijo',
        kemantren: 'Jetis',
        address: 'Kampung Badran RT 02 RW 11, Bumijo, Jetis, Kota Yogyakarta',
        latitude: -7.7890,
        longitude: 110.3601,
        operationalContact: '0857-9998-8811 (Kader Bu Sri)',
        operatingHours: 'Senin - Sabtu (08.00 - 15.00 WIB)',
        acceptedCommodities: ['jelantah', 'pet_bottle'],
        activeCollectorCount: 4,
        rating: 4.9,
      ),
      BsuPartnerModel(
        id: '11111111-1111-4111-8111-111111111102',
        name: 'BSU Asri Mandiri Sagan',
        kelurahan: 'Terban',
        kemantren: 'Gondokusuman',
        address: 'Jl. Sagan Baru No. 12, Terban, Gondokusuman, Kota Yogyakarta',
        latitude: -7.7795,
        longitude: 110.3770,
        operationalContact: '0813-2800-4411 (Pak Bambang)',
        operatingHours: 'Selasa, Kamis, Sabtu (08.30 - 14.30 WIB)',
        acceptedCommodities: ['jelantah', 'pet_bottle'],
        activeCollectorCount: 3,
        rating: 4.8,
      ),
      BsuPartnerModel(
        id: '11111111-1111-4111-8111-111111111103',
        name: 'BSU Hijau Lestari Prenggan',
        kelurahan: 'Prenggan',
        kemantren: 'Kotagede',
        address: 'Jl. Mondorakan No. 45, Prenggan, Kotagede, Kota Yogyakarta',
        latitude: -7.8280,
        longitude: 110.3985,
        operationalContact: '0821-3456-7890 (Bu Warsiti)',
        operatingHours: 'Senin - Jumat (09.00 - 15.00 WIB)',
        acceptedCommodities: ['pet_bottle'],
        activeCollectorCount: 2,
        rating: 4.7,
      ),
      BsuPartnerModel(
        id: '11111111-1111-4111-8111-111111111104',
        name: 'BSU Berkah Suryodiningratan',
        kelurahan: 'Suryodiningratan',
        kemantren: 'Mantrijeron',
        address: 'Jl. Suryodiningratan No. 28, Mantrijeron, Kota Yogyakarta',
        latitude: -7.8185,
        longitude: 110.3620,
        operationalContact: '0877-6655-4433 (Pak Haryanto)',
        operatingHours: 'Rabu & Sabtu (08.00 - 13.00 WIB)',
        acceptedCommodities: ['jelantah', 'pet_bottle'],
        activeCollectorCount: 3,
        rating: 4.9,
      ),
    ]);

    // Katalog Reward Resmi Mitra BSU
    _rewards.addAll([
      RewardCatalogItem(
        id: 'rwd_1',
        partnerId: 'bsu_winongo',
        name: 'Minyak Goreng Sawit 1 Liter',
        category: 'Sembako',
        pointsCost: 5500,
        stock: 50,
        description: 'Minyak goreng kemasan 1 liter kualitas SNI dari mitra offtaker BSU.',
        iconKey: 'oil',
        providerName: 'Koperasi BSU Lintas Winongo',
      ),
      RewardCatalogItem(
        id: 'rwd_2',
        partnerId: 'bsu_winongo',
        name: 'Beras Premium 2.5 Kg',
        category: 'Sembako',
        pointsCost: 9500,
        stock: 30,
        description: 'Beras putih pulen kemasan higienis produk UMKM pangan lokal Jogja.',
        iconKey: 'rice',
        providerName: 'BSU Asri Mandiri',
      ),
      RewardCatalogItem(
        id: 'rwd_3',
        partnerId: 'bsu_winongo',
        name: 'Voucher Belanja Sembako Rp 10.000',
        category: 'Voucher',
        pointsCost: 3500,
        stock: 100,
        description: 'Kupon belanja kebutuhan dapur di warung kelontong mitra BSU RW 11.',
        iconKey: 'coupon',
        providerName: 'Bank Sampah Lintas Winongo',
      ),
      RewardCatalogItem(
        id: 'rwd_4',
        partnerId: 'bsu_winongo',
        name: 'Token Listrik PLN Rp 20.000',
        category: 'Voucher',
        pointsCost: 7000,
        stock: 25,
        description: 'Token prabayar PLN resmi dikirimkan langsung ke nomor meteran warga.',
        iconKey: 'electric',
        providerName: 'Mitra CSR SIRKULA',
      ),
      RewardCatalogItem(
        id: 'rwd_5',
        partnerId: 'bsu_winongo',
        name: 'Paket 3 Bibit Sayuran & Kompos',
        category: 'Lingkungan',
        pointsCost: 2000,
        stock: 50,
        description: 'Bibit sayuran dan kompos organik hasil olahan komposter BSU.',
        iconKey: 'eco',
        providerName: 'Kebun Bibit BSU Winongo',
      ),
    ]);
  }
}
