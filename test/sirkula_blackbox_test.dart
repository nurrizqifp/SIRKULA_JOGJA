import 'package:flutter_test/flutter_test.dart';
import 'package:sirkula_jogja/models/order_model.dart';
import 'package:sirkula_jogja/models/user_model.dart';
import 'package:sirkula_jogja/services/haversine_service.dart';
import 'package:sirkula_jogja/services/sirkula_repository.dart';
import 'package:sirkula_jogja/services/validators.dart';

void main() {
  late SirkulaRepository repo;
  late UserModel citizen;
  late UserModel collectorA;
  late UserModel collectorB;
  late UserModel adminPlatform;
  late UserModel adminBsu;

  setUp(() {
    repo = SirkulaRepository();
    repo.resetForTest();

    citizen = UserModel(
      id: 'usr_citizen_1',
      name: 'Budi Santoso',
      email: 'budi@example.com',
      phone: '081234567890',
      role: UserRole.citizen,
      primaryAddress: 'Jl. Badran RT 02 RW 11, Bumijo, Yogyakarta',
      latitude: -7.7892,
      longitude: 110.3640,
      hasPrivacyConsent: true,
      isActive: true,
    );

    collectorA = UserModel(
      id: 'usr_collector_a',
      name: 'Indrianingsih',
      email: 'kader.a@example.com',
      phone: '085137334839',
      role: UserRole.collector,
      primaryAddress: 'Bumijo, Jetis',
      latitude: -7.7890,
      longitude: 110.3601,
      hasPrivacyConsent: true,
      bsuAffiliation: '11111111-1111-4111-8111-111111111101',
      isActive: true,
    );

    collectorB = UserModel(
      id: 'usr_collector_b',
      name: 'Bambang',
      email: 'kader.b@example.com',
      phone: '081328004411',
      role: UserRole.collector,
      primaryAddress: 'Terban, Gondokusuman',
      latitude: -7.7795,
      longitude: 110.3770,
      hasPrivacyConsent: true,
      bsuAffiliation: '11111111-1111-4111-8111-111111111102',
      isActive: true,
    );

    adminBsu = UserModel(
      id: 'usr_admin_bsu',
      name: 'Bu Sri',
      email: 'admin.bsu@example.com',
      phone: '085799988811',
      role: UserRole.adminBsu,
      primaryAddress: 'Bumijo, Jetis',
      latitude: -7.7890,
      longitude: 110.3601,
      hasPrivacyConsent: true,
      bsuAffiliation: '11111111-1111-4111-8111-111111111101',
      isActive: true,
    );

    adminPlatform = UserModel(
      id: 'usr_admin_platform',
      name: 'Nur Rizqi',
      email: 'nurrizqifebriansyah@gmail.com',
      phone: '08123456789',
      role: UserRole.adminPlatform,
      primaryAddress: 'Kota Yogyakarta',
      latitude: -7.7892,
      longitude: 110.3640,
      hasPrivacyConsent: true,
      isActive: true,
    );
  });

  group('Validasi Standar Indonesia (TC-01)', () {
    test('TC-01: Validasi nama, email, HP Indonesia, alamat RT/RW, password kuat, OTP', () {
      expect(Validators.name('Budi Santoso'), isNull);
      expect(Validators.name('A1'), isNotNull);

      expect(Validators.email('warga@jogja.id'), isNull);
      expect(Validators.email('bukan-email'), isNotNull);

      expect(Validators.normalizePhone('+62 812-3456-7890'), '081234567890');
      expect(Validators.phone('081234567890'), isNull);
      expect(Validators.phone('02112345'), isNotNull);

      expect(Validators.address('Kampung Badran RT 02 RW 11, Bumijo'), isNull);
      expect(Validators.address('Jalan Malioboro'), isNotNull); // Wajib RT/RW

      expect(Validators.password('Josjis123!', email: 'nurrizqi@gmail.com'), isNull);
      expect(Validators.password('lemah123'), isNotNull); // Tanpa huruf besar

      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('12ab'), isNotNull);
    });
  });

  group('Alur Pesanan, Verifikasi & Sengketa (TC-02 s.d. TC-08)', () {
    test('TC-02 & TC-03: Buat pesanan sesuai komoditas BSU dan tolak komoditas tidak didukung', () async {
      repo.setTestSession(citizen, users: [citizen, collectorA, collectorB]);

      // TC-02: BSU Winongo menerima jelantah & pet_bottle -> berhasil
      final order = await repo.createOrder(
        bsuId: '11111111-1111-4111-8111-111111111101',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '09:00 - 11:00 WIB',
        pickupAddress: citizen.primaryAddress,
        accessNotes: 'Depan pagar hijau',
        items: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 2.0,
            basePoints: 1000,
          ),
        ],
      );
      expect(order.status, OrderStatus.waitingPartnerConfirmation);
      expect(repo.orders.length, 1);

      // TC-03: BSU Kotagede (1103) hanya menerima pet_bottle -> jelantah harus ditolak
      await expectLater(
        repo.createOrder(
          bsuId: '11111111-1111-4111-8111-111111111103',
          scheduledDate: DateTime.now().add(const Duration(days: 1)),
          timeSlot: '09:00 - 11:00 WIB',
          pickupAddress: citizen.primaryAddress,
          accessNotes: '',
          items: [
            OrderItemModel(
              commodityKey: 'jelantah',
              commodityName: 'Minyak Jelantah',
              unit: 'Liter',
              estimatedQuantity: 2.0,
              basePoints: 1000,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('TC-04, TC-05, TC-06 & TC-12: Penugasan kader, timbang, konfirmasi warga & anti-duplikasi', () async {
      repo.setTestSession(citizen, users: [citizen, collectorA, collectorB, adminPlatform]);

      final order = await repo.createOrder(
        bsuId: '11111111-1111-4111-8111-111111111101',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '09:00 - 11:00 WIB',
        pickupAddress: citizen.primaryAddress,
        accessNotes: '',
        items: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 2.0,
            basePoints: 1000,
          ),
        ],
      );

      // Admin menugaskan collectorA
      repo.assignCollector(
        orderId: order.id,
        collectorId: collectorA.id,
        collectorName: collectorA.name,
        collectorPhone: collectorA.phone,
      );
      expect(repo.orders.first.status, OrderStatus.assigned);
      // TC-04: collectorId tercatat eksklusif untuk collectorA (bukan collectorB)
      expect(repo.orders.first.collectorId, collectorA.id);
      expect(repo.orders.first.collectorId == collectorB.id, isFalse);

      // TC-05: Kader mulai jemput & input berat terverifikasi + mutu 1.1x
      repo.startPickup(order.id);
      expect(repo.orders.first.status, OrderStatus.inPickup);

      repo.submitMeasurement(
        orderId: order.id,
        verifiedItems: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 2.0,
            verifiedQuantity: 2.5,
            qualityFactor: 1.1,
            qualityNotes: 'Bersih tersaring',
            photoProofUrl: 'dikonfirmasi-kader',
            basePoints: 1000,
          ),
        ],
      );
      expect(repo.orders.first.status, OrderStatus.waitingCitizenConfirmation);

      // TC-06 & TC-12: Warga konfirmasi 2x berturut-turut -> poin hanya masuk 1x (2.5 * 1000 * 1.1 = 2750)
      repo.citizenConfirmMeasurement(order.id);
      repo.citizenConfirmMeasurement(order.id);
      expect(repo.orders.first.status, OrderStatus.completed);
      expect(repo.getBalanceForUser(citizen.id), 2750);
      expect(repo.ledger.where((l) => l.orderId == order.id).length, 1);
    });

    test('TC-07: Warga menyanggah hasil timbang -> status disputed dan poin tidak masuk', () async {
      repo.setTestSession(citizen, users: [citizen, collectorA]);
      final order = await repo.createOrder(
        bsuId: '11111111-1111-4111-8111-111111111101',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '09:00 - 11:00 WIB',
        pickupAddress: citizen.primaryAddress,
        accessNotes: '',
        items: [
          OrderItemModel(
            commodityKey: 'pet_bottle',
            commodityName: 'Botol Plastik PET',
            unit: 'Kg',
            estimatedQuantity: 3.0,
            basePoints: 3500,
          ),
        ],
      );

      repo.assignCollector(
        orderId: order.id,
        collectorId: collectorA.id,
        collectorName: collectorA.name,
        collectorPhone: collectorA.phone,
      );
      repo.startPickup(order.id);
      repo.submitMeasurement(
        orderId: order.id,
        verifiedItems: [
          OrderItemModel(
            commodityKey: 'pet_bottle',
            commodityName: 'Botol Plastik PET',
            unit: 'Kg',
            estimatedQuantity: 3.0,
            verifiedQuantity: 1.0,
            qualityFactor: 0.8,
            basePoints: 3500,
          ),
        ],
      );

      repo.citizenDisputeMeasurement(
        orderId: order.id,
        reason: 'Timbangan aktual di rumah tadi 3 kg bukan 1 kg.',
      );
      expect(repo.orders.first.status, OrderStatus.disputed);
      expect(repo.getBalanceForUser(citizen.id), 0);
    });

    test('TC-08: Ubah tarif komoditas baru tidak mengubah poin transaksi yang sudah selesai', () async {
      repo.setTestSession(citizen, users: [citizen, collectorA, adminPlatform]);
      final order = await repo.createOrder(
        bsuId: '11111111-1111-4111-8111-111111111101',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '09:00 - 11:00 WIB',
        pickupAddress: citizen.primaryAddress,
        accessNotes: '',
        items: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 2.0,
            basePoints: 1000,
          ),
        ],
      );
      repo.assignCollector(
        orderId: order.id,
        collectorId: collectorA.id,
        collectorName: collectorA.name,
        collectorPhone: collectorA.phone,
      );
      repo.startPickup(order.id);
      repo.submitMeasurement(
        orderId: order.id,
        verifiedItems: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 2.0,
            verifiedQuantity: 2.0,
            qualityFactor: 1.0,
            basePoints: 1000,
          ),
        ],
      );
      repo.citizenConfirmMeasurement(order.id);
      expect(repo.getBalanceForUser(citizen.id), 2000);

      // Admin mengubah tarif jelantah menjadi 1500
      repo.setTestSession(adminPlatform, users: [citizen, collectorA, adminPlatform]);
      final err = await repo.updateCommodityRate(
        bsuId: '11111111-1111-4111-8111-111111111101',
        commodityKey: 'jelantah',
        newPointsPerUnit: 1500,
      );
      expect(err, isNull);
      expect(repo.getPointsPerUnit('11111111-1111-4111-8111-111111111101', 'jelantah'), 1500);
      // Saldo transaksi lama tetap 2000 (tidak retroaktif)
      expect(repo.getBalanceForUser(citizen.id), 2000);
    });
  });

  group('Reward, Kuis, RBAC, Haversine & Ekspor CSV (TC-09 s.d. TC-11 + ADM)', () {
    test('TC-09 & TC-10: Kuis bonus 1x klaim & penukaran reward mengurangi saldo & stok', () async {
      repo.setTestSession(citizen, users: [citizen, collectorA]);

      // TC-10: Submit kuis 2x -> bonus +50 hanya 1x
      expect(repo.recordQuizScore('quiz_masjos_01', 80), isTrue);
      expect(repo.recordQuizScore('quiz_masjos_01', 100), isFalse);
      expect(repo.getBalanceForUser(citizen.id), 50);

      // Tambah poin lewat 1 order selesai (2500 poin) agar cukup tukar rwd_5 (2000 poin)
      final order = await repo.createOrder(
        bsuId: '11111111-1111-4111-8111-111111111101',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '09:00 - 11:00 WIB',
        pickupAddress: citizen.primaryAddress,
        accessNotes: '',
        items: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 2.5,
            basePoints: 1000,
          ),
        ],
      );
      repo.assignCollector(
        orderId: order.id,
        collectorId: collectorA.id,
        collectorName: collectorA.name,
        collectorPhone: collectorA.phone,
      );
      repo.startPickup(order.id);
      repo.submitMeasurement(
        orderId: order.id,
        verifiedItems: [
          OrderItemModel(
            commodityKey: 'jelantah',
            commodityName: 'Minyak Jelantah',
            unit: 'Liter',
            estimatedQuantity: 2.5,
            verifiedQuantity: 2.5,
            qualityFactor: 1.0,
            basePoints: 1000,
          ),
        ],
      );
      repo.citizenConfirmMeasurement(order.id);
      expect(repo.getBalanceForUser(citizen.id), 2550);

      // TC-09: Tukar rwd_5 (2000 poin, stok awal 50)
      final ok = repo.redeemReward('rwd_5');
      expect(ok, isTrue);
      expect(repo.getBalanceForUser(citizen.id), 550);
      expect(repo.coupons.length, 1);
      expect(repo.rewards.firstWhere((r) => r.id == 'rwd_5').stock, 49);
    });

    test('ADM-01 & ADM-02: RBAC ubah role, blokir edit diri sendiri, eskalasi adminBsu & ekspor CSV', () async {
      repo.setTestSession(adminPlatform, users: [citizen, adminBsu, adminPlatform]);

      // Admin Platform tidak boleh ubah akun sendiri
      expect(await repo.updateUserRole(adminPlatform.id, UserRole.citizen), isNotNull);

      // Admin Platform ubah citizen menjadi collector
      final err = await repo.updateUserRole(
        citizen.id,
        UserRole.collector,
        bsuAffiliation: '11111111-1111-4111-8111-111111111101',
      );
      expect(err, isNull);
      expect(repo.users.firstWhere((u) => u.id == citizen.id).role, UserRole.collector);

      // Admin BSU tidak boleh mengangkat user menjadi adminPlatform
      repo.setTestSession(adminBsu, users: [citizen, adminBsu, adminPlatform]);
      expect(await repo.updateUserRole(citizen.id, UserRole.adminPlatform), isNotNull);

      // Ekspor CSV menghasilkan header & ringkasan KPI
      final csv = repo.generateRecapCsv();
      expect(csv, contains('LAPORAN REKAPITULASI SIRKULA-JOGJA'));
      expect(csv, contains('RINGKASAN KPI DAMPAK'));
      expect(csv, contains('REKAPITULASI PENGGUNA'));

      // Haversine distance non-negative & konsisten
      final d = HaversineService.calculateDistanceKm(
        lat1: -7.7892,
        lon1: 110.3640,
        lat2: -7.7890,
        lon2: 110.3601,
      );
      expect(d, greaterThan(0));
      expect(d, lessThan(2.0));
    });
  });
}
