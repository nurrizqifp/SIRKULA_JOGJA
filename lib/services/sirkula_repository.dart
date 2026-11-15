import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/bsu_model.dart';
import '../models/commodity_model.dart';
import '../models/order_model.dart';
import '../models/reward_model.dart';
import '../models/education_model.dart';
import '../models/kpi_model.dart';
import 'haversine_service.dart';
import 'reward_calculator.dart';

class SirkulaRepository extends ChangeNotifier {
  static final SirkulaRepository _instance = SirkulaRepository._internal();
  factory SirkulaRepository() => _instance;

  SirkulaRepository._internal() {
    _initializeDemoData();
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

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

  int get citizenBalance {
    if (_currentUser == null) return 0;
    final userLedger = _ledger.where((e) => e.userId == _currentUser!.id);
    if (userLedger.isEmpty) return 0;
    return userLedger.last.balanceAfter;
  }

  // ----------------------------------------------------
  // AUTHENTICATION & DEMO SWITCHER
  // ----------------------------------------------------
  Future<bool> login(String email, String password) async {
    final found = _demoUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => _demoUsers[0],
    );
    _currentUser = found;
    notifyListeners();
    return true;
  }

  void switchDemoUser(UserRole role) {
    _currentUser = _demoUsers.firstWhere((u) => u.role == role);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> registerCitizen({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String accessNotes,
    required bool consentGranted,
  }) async {
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: UserRole.citizen,
      primaryAddress: address,
      latitude: -7.7892 + (Random().nextDouble() * 0.01 - 0.005),
      longitude: 110.3640 + (Random().nextDouble() * 0.01 - 0.005),
      accessNotes: accessNotes,
      hasPrivacyConsent: consentGranted,
      consentDate: DateTime.now(),
    );
    _demoUsers.add(newUser);
    _currentUser = newUser;
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
    final bsu = _bsuList.firstWhere((b) => b.id == bsuId);
    final user = _currentUser!;
    final randomNum = 1000 + _orders.length + 1;
    final order = PickupOrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: 'SRK-202611-00$randomNum',
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
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    notifyListeners();
    return order;
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
      notifyListeners();
    }
  }

  void startPickup(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.inPickup,
      );
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
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.waitingCitizenConfirmation,
        items: verifiedItems,
      );
      notifyListeners();
    }
  }

  /// Citizen reviews and confirms the weighing results -> Poin credited to Reward Ledger!
  void citizenConfirmMeasurement(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      final pointsEarned = order.totalCalculatedPoints;
      final newBalance = citizenBalance + pointsEarned;

      _orders[index] = order.copyWith(
        status: OrderStatus.completed,
        completedAt: DateTime.now(),
      );

      // Record in audited Reward Ledger
      _ledger.add(
        RewardLedgerEntry(
          id: 'ldg_${DateTime.now().millisecondsSinceEpoch}',
          userId: order.citizenId,
          orderId: order.id,
          type: LedgerType.creditOrder,
          points: pointsEarned,
          balanceAfter: newBalance,
          description:
              'Reward penjemputan ${order.orderNumber} (${order.items.map((i) => '${i.verifiedQuantity} ${i.unit} ${i.commodityName} [Mutu ${i.qualityFactor}x]').join(', ')})',
          actorName: order.collectorName ?? 'Kader BSU',
          timestamp: DateTime.now(),
        ),
      );

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
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.disputed,
        disputeReason: reason,
      );
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
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // REWARD REDEMPTION
  // ----------------------------------------------------
  bool redeemReward(String rewardId) {
    final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
    if (rewardIndex == -1) return false;
    final reward = _rewards[rewardIndex];

    if (reward.stock <= 0 || citizenBalance < reward.pointsCost) {
      return false;
    }

    final newBalance = citizenBalance - reward.pointsCost;
    _rewards[rewardIndex] = reward.copyWith(stock: reward.stock - 1);

    final couponCode = 'SRK-RWD-${1000 + _coupons.length + 1}';
    _coupons.insert(
      0,
      RedemptionCoupon(
        id: 'cpn_${DateTime.now().millisecondsSinceEpoch}',
        rewardId: reward.id,
        rewardName: reward.name,
        pointsSpent: reward.pointsCost,
        redemptionCode: couponCode,
        redeemedAt: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 30)),
      ),
    );

    _ledger.add(
      RewardLedgerEntry(
        id: 'ldg_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.id,
        type: LedgerType.debitRedeem,
        points: -reward.pointsCost,
        balanceAfter: newBalance,
        description: 'Penukaran reward: ${reward.name} (Kode: $couponCode)',
        actorName: _currentUser!.name,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
    return true;
  }

  // ----------------------------------------------------
  // EDUCATION & QUIZ
  // ----------------------------------------------------
  void recordQuizScore(String quizId, int score) {
    _quizScores[quizId] = score;

    // Give bonus point for completing Mas JOS quiz
    final bonusPoints = 50;
    final newBalance = citizenBalance + bonusPoints;
    _ledger.add(
      RewardLedgerEntry(
        id: 'ldg_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.id,
        type: LedgerType.creditEducation,
        points: bonusPoints,
        balanceAfter: newBalance,
        description: 'Bonus literasi 5 Aksi Mas JOS (Skor: $score%)',
        actorName: 'Akademi Mas JOS',
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
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

    for (final o in _orders) {
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

    final completenessRate = _orders.isEmpty ? 100.0 : (verifiedComplete / _orders.length) * 100.0;

    return KpiImpactMetrics(
      totalPetKg: totalPet,
      totalJelantahLiter: totalJelantah,
      totalOrders: _orders.length,
      completedOrders: completed,
      disputedOrders: disputed,
      registeredHouseholds: 52,
      activeHouseholds: 41,
      verificationCompletenessRate: completenessRate,
      preTestScoreAvg: 58.5,
      postTestScoreAvg: 89.2,
      repeatTransactionRate: 64.0,
    );
  }

  // ----------------------------------------------------
  // DEMO DATA INITIALIZATION
  // ----------------------------------------------------
  final List<UserModel> _demoUsers = [
    UserModel(
      id: 'usr_warga_01',
      name: 'Nur Rizqi (Warga Mas JOS)',
      email: 'warga@sirkula.test',
      phone: '081234567890',
      role: UserRole.citizen,
      primaryAddress: 'Kampung Badran RT 04 RW 11, Kelurahan Bumijo, Kemantren Jetis',
      latitude: -7.7885,
      longitude: 110.3592,
      accessNotes: 'Rumah cat hijau dekat gapura masuk lorong barat.',
    ),
    UserModel(
      id: 'usr_kader_01',
      name: 'Indrianingsih (Kader BSU)',
      email: 'kader@sirkula.test',
      phone: '085799988811',
      role: UserRole.collector,
      primaryAddress: 'BSU Lintas Winongo, Kampung Badran, Jetis, Kota Yogyakarta',
      latitude: -7.7890,
      longitude: 110.3601,
      bsuAffiliation: 'bsu_winongo',
    ),
    UserModel(
      id: 'usr_admin_01',
      name: 'Aquila Sherpa (Pengurus BSU)',
      email: 'bsu@sirkula.test',
      phone: '087811223344',
      role: UserRole.adminBsu,
      primaryAddress: 'Kantor BSU Lintas Winongo Jetis',
      latitude: -7.7890,
      longitude: 110.3601,
      bsuAffiliation: 'bsu_winongo',
    ),
    UserModel(
      id: 'usr_platform_01',
      name: 'Admin DLH Kota Yogyakarta',
      email: 'admin@sirkula.test',
      phone: '081122334455',
      role: UserRole.adminPlatform,
      primaryAddress: 'Dinas Lingkungan Hidup Kota Yogyakarta',
      latitude: -7.7956,
      longitude: 110.3695,
    ),
  ];

  void _initializeDemoData() {
    _currentUser = _demoUsers[0]; // Default to Citizen

    _bsuList.addAll([
      BsuPartnerModel(
        id: 'bsu_winongo',
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
        id: 'bsu_sagan',
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
        id: 'bsu_kotagede',
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
        id: 'bsu_mantrijeron',
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

    // Initial Orders representing realistic workflow states
    _orders.addAll([
      PickupOrderModel(
        id: 'ord_101',
        orderNumber: 'SRK-202611-0038',
        citizenId: 'usr_warga_01',
        citizenName: 'Nur Rizqi',
        citizenPhone: '081234567890',
        bsuId: 'bsu_winongo',
        bsuName: 'Bank Sampah Lintas Winongo',
        pickupAddress: 'Kampung Badran RT 04 RW 11, Bumijo, Jetis',
        latitude: -7.7885,
        longitude: 110.3592,
        accessNotes: 'Masuk gang selatan gapura.',
        scheduledDate: DateTime.now().subtract(const Duration(days: 3)),
        timeSlot: 'Pagi (08.00 - 11.00 WIB)',
        status: OrderStatus.completed,
        items: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 3.0,
            verifiedQuantity: 3.5,
            qualityFactor: 1.1,
            qualityNotes: 'Sangat jernih, disaring rapi tanpa remah.',
            photoProofUrl: 'assets/mockups/Tugas dan verifikasi petugas.png',
            basePoints: 1000,
          ),
          OrderItemModel(
            commodityKey: 'pet_bottle',
            commodityName: 'Botol Plastik PET',
            unit: 'Kg',
            estimatedQuantity: 2.0,
            verifiedQuantity: 2.2,
            qualityFactor: 1.0,
            qualityNotes: 'Botol bersih dan kering.',
            photoProofUrl: 'assets/mockups/Konfirmasi hasil timbang.png',
            basePoints: 3500,
          ),
        ],
        collectorId: 'usr_kader_01',
        collectorName: 'Indrianingsih',
        collectorPhone: '085799988811',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      PickupOrderModel(
        id: 'ord_102',
        orderNumber: 'SRK-202611-0041',
        citizenId: 'usr_warga_01',
        citizenName: 'Nur Rizqi',
        citizenPhone: '081234567890',
        bsuId: 'bsu_winongo',
        bsuName: 'Bank Sampah Lintas Winongo',
        pickupAddress: 'Kampung Badran RT 04 RW 11, Bumijo, Jetis',
        latitude: -7.7885,
        longitude: 110.3592,
        scheduledDate: DateTime.now(),
        timeSlot: 'Pagi (08.00 - 11.00 WIB)',
        status: OrderStatus.waitingCitizenConfirmation,
        items: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 4.0,
            verifiedQuantity: 4.0,
            qualityFactor: 1.0,
            qualityNotes: 'Standar BSU, wadah jeriken aman.',
            photoProofUrl: 'assets/mockups/Tugas dan verifikasi petugas.png',
            basePoints: 1000,
          ),
        ],
        collectorId: 'usr_kader_01',
        collectorName: 'Indrianingsih',
        collectorPhone: '085799988811',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PickupOrderModel(
        id: 'ord_103',
        orderNumber: 'SRK-202611-0042',
        citizenId: 'usr_warga_01',
        citizenName: 'Nur Rizqi',
        citizenPhone: '081234567890',
        bsuId: 'bsu_winongo',
        bsuName: 'Bank Sampah Lintas Winongo',
        pickupAddress: 'Kampung Badran RT 04 RW 11, Bumijo, Jetis',
        latitude: -7.7885,
        longitude: 110.3592,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        timeSlot: 'Siang (13.00 - 15.00 WIB)',
        status: OrderStatus.assigned,
        items: [
          OrderItemModel(
            commodityKey: 'pet_bottle',
            commodityName: 'Botol Plastik PET',
            unit: 'Kg',
            estimatedQuantity: 3.5,
            basePoints: 3500,
          ),
        ],
        collectorId: 'usr_kader_01',
        collectorName: 'Indrianingsih',
        collectorPhone: '085799988811',
        createdAt: DateTime.now(),
      ),
    ]);

    // Initial Ledger
    _ledger.addAll([
      RewardLedgerEntry(
        id: 'ldg_001',
        userId: 'usr_warga_01',
        orderId: 'ord_101',
        type: LedgerType.creditOrder,
        points: 11550, // (3.5 * 1000 * 1.1 = 3850) + (2.2 * 3500 * 1.0 = 7700) = 11550
        balanceAfter: 11550,
        description: 'Poin penjemputan selesai SRK-202611-0038 (3.5L Jelantah [1.1x] & 2.2kg PET [1.0x])',
        actorName: 'Indrianingsih (Kader BSU)',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      RewardLedgerEntry(
        id: 'ldg_002',
        userId: 'usr_warga_01',
        type: LedgerType.creditEducation,
        points: 50,
        balanceAfter: 11600,
        description: 'Apresiasi kuis 5 Aksi Mas JOS',
        actorName: 'Akademi Mas JOS',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);

    // Reward Catalog Items
    _rewards.addAll([
      RewardCatalogItem(
        id: 'rwd_1',
        partnerId: 'bsu_winongo',
        name: 'Minyak Goreng Sawit 1 Liter',
        category: 'Sembako',
        pointsCost: 5500,
        stock: 24,
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
        stock: 15,
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
        stock: 40,
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
        stock: 10,
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
        stock: 35,
        description: 'Bibit cabai, tomat, terong dan kompos organik hasil olahan komposter BSU.',
        iconKey: 'eco',
        providerName: 'Kebun Bibit BSU Winongo',
      ),
    ]);
  }
}
