import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/sirkula_repository.dart';
import '../../services/validators.dart';
import '../shared/profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAssignCollectorDialog(PickupOrderModel order, SirkulaRepository repo) {
    final activeCollectors = repo.collectors;
    if (activeCollectors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada akun Kader BSU aktif. Tetapkan peran Kader di tab Pengguna terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    UserModel selectedCollector = activeCollectors.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Tugaskan Kader - ${order.orderNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alamat: ${order.pickupAddress}', style: const TextStyle(fontSize: 12.5)),
              Text('Jadwal: ${order.scheduledDate.day}-${order.scheduledDate.month}-${order.scheduledDate.year} (${order.timeSlot})', style: const TextStyle(fontSize: 12.5)),
              const SizedBox(height: 14),
              const Text('Pilih Kader / Kurir Penjemput:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedCollector.id,
                isExpanded: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_pin, color: AppTheme.primaryGreen)),
                items: activeCollectors
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${repo.getBsuName(c.bsuAffiliation)})'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedCollector = activeCollectors.firstWhere((c) => c.id == val);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                repo.assignCollector(
                  orderId: order.id,
                  collectorId: selectedCollector.id,
                  collectorName: selectedCollector.name,
                  collectorPhone: selectedCollector.phone,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Petugas ${selectedCollector.name} berhasil ditugaskan!'),
                    backgroundColor: AppTheme.primaryMedium,
                  ),
                );
              },
              child: const Text('Konfirmasi Penugasan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResolveDisputeDialog(PickupOrderModel order, SirkulaRepository repo) {
    final noteController = TextEditingController(text: 'Hasil rekonsiliasi timbangan bersama pengurus BSU disetujui.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Penyelesaian Sengketa - ${order.orderNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keberatan Warga: ${order.disputeReason ?? "-"}', style: const TextStyle(fontSize: 12.5, color: AppTheme.statusDisputed, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              maxLength: 150,
              inputFormatters: InputGuards.notes,
              decoration: const InputDecoration(labelText: 'Catatan Rekonsiliasi Pengurus BSU'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () {
              repo.resolveDispute(
                orderId: order.id,
                finalItems: order.items,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sengketa diselesaikan! Warga dapat mengonfirmasi ulang hasil ukur.'),
                  backgroundColor: AppTheme.primaryMedium,
                ),
              );
            },
            child: const Text('Selesaikan Sengketa'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, SirkulaRepository repo, UserModel targetUser) {
    UserRole currentRole = targetUser.role;
    final validBsuIds = repo.bsuList.map((b) => b.id).toSet();
    String? bsuId = validBsuIds.contains(targetUser.bsuAffiliation)
        ? targetUser.bsuAffiliation
        : (repo.bsuList.isNotEmpty ? repo.bsuList.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Ubah Role: ${targetUser.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${targetUser.email}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF546E7A))),
              const SizedBox(height: 14),
              const Text('Tetapkan Peran Baru:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<UserRole>(
                value: currentRole,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: UserRole.citizen, child: Text('Warga / Nasabah')),
                  DropdownMenuItem(value: UserRole.collector, child: Text('Kader / Kurir BSU')),
                  DropdownMenuItem(value: UserRole.adminBsu, child: Text('Admin Pengelola BSU')),
                  DropdownMenuItem(value: UserRole.adminPlatform, child: Text('Admin Platform (DLH)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => currentRole = val);
                  }
                },
              ),
              if (currentRole == UserRole.collector || currentRole == UserRole.adminBsu) ...[
                const SizedBox(height: 12),
                const Text('Afiliasi BSU:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: bsuId,
                  isExpanded: true,
                  items: repo.bsuList.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                  onChanged: (b) => setDialogState(() => bsuId = b),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final err = await repo.updateUserRole(
                  targetUser.id,
                  currentRole,
                  bsuAffiliation: (currentRole == UserRole.collector || currentRole == UserRole.adminBsu) ? bsuId : null,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(err ?? 'Peran ${targetUser.name} diperbarui menjadi ${currentRole.name}.'),
                    backgroundColor: err == null ? AppTheme.primaryMedium : Colors.red,
                  ),
                );
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementTab(BuildContext context, SirkulaRepository repo) {
    final users = repo.users;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: AppTheme.primaryGreen, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role-Based Access Control (RBAC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        'Kelola otorisasi warga, kader penjemput, admin BSU, dan koordinator kota.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF37474F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...users.map((u) {
            final isCurrent = repo.currentUser?.id == u.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: u.isActive
                      ? AppTheme.primaryGreen.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.2),
                  child: Icon(
                    u.role == UserRole.citizen
                        ? Icons.person
                        : (u.role == UserRole.collector ? Icons.two_wheeler : Icons.admin_panel_settings),
                    color: u.isActive ? AppTheme.primaryGreen : Colors.grey,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        u.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8E6C9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Anda', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${u.email} • ${u.phone}', style: const TextStyle(fontSize: 11, color: Color(0xFF607D8B))),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: Text(
                            u.roleDisplayName,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryMedium),
                          ),
                        ),
                        if (u.bsuAffiliation != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Mitra: ${repo.getBsuName(u.bsuAffiliation)}',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF00695C)),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: u.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            u.isActive ? 'Aktif' : 'Non-Aktif',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: u.isActive ? const Color(0xFF2E7D32) : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Kelola Akun',
                  onSelected: (val) async {
                    if (val == 'role') {
                      _showEditRoleDialog(context, repo, u);
                    } else if (val == 'toggle') {
                      final messenger = ScaffoldMessenger.of(context);
                      final err = await repo.toggleUserStatus(u.id);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(err ?? 'Status pengguna ${u.name} diubah.'),
                          backgroundColor: err == null ? AppTheme.primaryMedium : Colors.red,
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'role',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: AppTheme.primaryMedium),
                          SizedBox(width: 8),
                          Text('Ubah Role Akun'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(u.isActive ? Icons.block : Icons.check, size: 18, color: u.isActive ? Colors.red : Colors.green),
                          SizedBox(width: 8),
                          Text(u.isActive ? 'Non-Aktifkan Akun' : 'Aktifkan Akun'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final repo = SirkulaRepository();

    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final orders = repo.orders;
        final kpi = repo.computeKpiMetrics();

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard Pengelola BSU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Monitoring Operasional & Dampak Pilot KMM', style: TextStyle(fontSize: 11, color: Color(0xFF607D8B))),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Muat Ulang Data Cloud',
                icon: const Icon(Icons.refresh, color: AppTheme.primaryMedium),
                onPressed: () async {
                  await repo.loadUsers();
                  await repo.loadCloudData();
                },
              ),
              IconButton(
                tooltip: 'Ganti Peran / Profil',
                icon: const Icon(Icons.account_circle_outlined, color: AppTheme.primaryMedium),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: const Color(0xFF78909C),
              tabs: const [
                Tab(icon: Icon(Icons.assignment), text: 'Pesanan'),
                Tab(icon: Icon(Icons.manage_accounts), text: 'Pengguna'),
                Tab(icon: Icon(Icons.analytics), text: 'Dampak Pilot'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Order Assignment & Disputes
              orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inbox_outlined, size: 52, color: Color(0xFF90A4AE)),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada pesanan penjemputan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pesanan dari warga akan tampil di sini untuk penugasan kader atau resolusi sengketa.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF607D8B)),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Muat Ulang'),
                              onPressed: () => repo.loadCloudData(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final isUnassigned = order.status == OrderStatus.waitingPartnerConfirmation;
                  final isDisputed = order.status == OrderStatus.disputed;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDisputed
                                      ? const Color(0xFFFFEBEE)
                                      : (isUnassigned ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.status.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDisputed
                                        ? AppTheme.statusDisputed
                                        : (isUnassigned ? const Color(0xFFE65100) : AppTheme.primaryGreen),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Warga: ${order.citizenName} (${order.citizenPhone})', style: const TextStyle(fontSize: 12)),
                          Text('Alamat: ${order.pickupAddress}', style: const TextStyle(fontSize: 12, color: Color(0xFF546E7A))),
                          Text('Jadwal: ${order.scheduledDate.day}-${order.scheduledDate.month}-${order.scheduledDate.year} · ${order.timeSlot}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF616161))),
                          Text('Komoditas: ${order.commoditiesSummary}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          if (order.collectorName != null)
                            Text('Kader Bertugas: ${order.collectorName}', style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryMedium)),
                          if (isDisputed) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Keberatan Warga: ${order.disputeReason}', style: const TextStyle(fontSize: 11, color: AppTheme.statusDisputed, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isUnassigned)
                                FilledButton(
                                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                                  onPressed: () => _showAssignCollectorDialog(order, repo),
                                  child: const Text('Tugaskan Kader', style: TextStyle(fontSize: 12)),
                                ),
                              if (isDisputed)
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.statusDisputed,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () => _showResolveDisputeDialog(order, repo),
                                  child: const Text('Rekonsiliasi Sengketa', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // TAB 2: RBAC User & Role Management
              _buildUserManagementTab(context, repo),

              // TAB 3: Pilot KPI & Impact Dashboard (Section 7.D)
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rancangan Indikator Dampak Pilot (Bab 7.D)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
                        SizedBox(height: 2),
                        Text(
                          'Data terverifikasi pilot 8 minggu di wilayah kelurahan/RW mitra Kota Yogyakarta.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF455A64)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Environmental Impact Metrics
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Botol PET Terhimpun',
                        value: '${kpi.totalPetKg.toStringAsFixed(1)} Kg',
                        subtitle: 'Bersih & siap daur ulang',
                        icon: Icons.recycling,
                        color: AppTheme.petBlue,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Jelantah Terkumpul',
                        value: '${kpi.totalJelantahLiter.toStringAsFixed(1)} L',
                        subtitle: 'Tersaring masuk offtaker',
                        icon: Icons.water_drop,
                        color: AppTheme.jelantahGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Service KPIs
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Penyelesaian Pesanan',
                        value: '${kpi.completionRatePercent.toStringAsFixed(0)}%',
                        subtitle: '${kpi.completedOrders} dari ${kpi.totalOrders} pesanan (Target ≥85%)',
                        icon: Icons.check_circle_outline,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Warga Aktif',
                        value: '${kpi.activeHouseholdRatePercent.toStringAsFixed(0)}%',
                        subtitle: '${kpi.activeHouseholds} dari ${kpi.registeredHouseholds} KK (Target ≥70%)',
                        icon: Icons.people_outline,
                        color: const Color(0xFF00796B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Kelengkapan Verifikasi',
                        value: '${kpi.verificationCompletenessRate.toStringAsFixed(0)}%',
                        subtitle: 'Data ukur, mutu & foto lengkap (Target ≥95%)',
                        icon: Icons.verified_user_outlined,
                        color: const Color(0xFF5E35B1),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Peningkatan Skor Kuis',
                        value: '+${kpi.quizScoreImprovement.toStringAsFixed(0)} Poin',
                        subtitle: 'Pre: ${kpi.preTestScoreAvg}% → Post: ${kpi.postTestScoreAvg}%',
                        icon: Icons.trending_up,
                        color: const Color(0xFFD81B60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Export & Tariff Actions
                  OutlinedButton.icon(
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Atur Tarif Poin Komoditas BSU'),
                    onPressed: () => _showEditRateDialog(repo),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Ekspor Laporan Rekapitulasi (CSV)'),
                    onPressed: () => _exportRecapCsv(repo),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditRateDialog(SirkulaRepository repo) {
    if (repo.bsuList.isEmpty) return;
    String bsuId = repo.bsuList.first.id;
    String commodityKey = 'jelantah';
    final rateCtrl = TextEditingController(
      text: repo.getPointsPerUnit(bsuId, commodityKey, fallback: 1000).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Atur Tarif Komoditas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: bsuId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mitra BSU'),
                items: repo.bsuList
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() {
                      bsuId = v;
                      rateCtrl.text = repo
                          .getPointsPerUnit(bsuId, commodityKey, fallback: commodityKey == 'jelantah' ? 1000 : 3500)
                          .toString();
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: commodityKey,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Komoditas'),
                items: const [
                  DropdownMenuItem(value: 'jelantah', child: Text('Minyak Jelantah (per Liter)')),
                  DropdownMenuItem(value: 'pet_bottle', child: Text('Botol Plastik PET (per Kg)')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() {
                      commodityKey = v;
                      rateCtrl.text = repo
                          .getPointsPerUnit(bsuId, commodityKey, fallback: v == 'jelantah' ? 1000 : 3500)
                          .toString();
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: InputGuards.integerRate,
                decoration: const InputDecoration(labelText: 'Poin Dasar per Unit'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final pts = int.tryParse(rateCtrl.text.trim()) ?? 0;
                Navigator.pop(ctx);
                final err = await repo.updateCommodityRate(
                  bsuId: bsuId,
                  commodityKey: commodityKey,
                  newPointsPerUnit: pts,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(err ?? 'Tarif baru ($pts poin) disimpan tanpa mengubah transaksi lama.'),
                    backgroundColor: err == null ? AppTheme.primaryMedium : AppTheme.statusDisputed,
                  ),
                );
              },
              child: const Text('Simpan Tarif'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportRecapCsv(SirkulaRepository repo) async {
    try {
      final csv = repo.generateRecapCsv();
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'laporan_sirkula_$stamp.csv';
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv, flush: true);

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Laporan Siap Diekspor',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Berkas: $fileName (${repo.orders.length} order, ${repo.users.length} pengguna)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csv,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_all_rounded, size: 18),
                        label: const Text('Salin CSV'),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: csv));
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Isi laporan CSV disalin ke clipboard.'),
                              backgroundColor: AppTheme.primaryMedium,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Simpan / Bagikan'),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(file.path, mimeType: 'text/csv')],
                              subject: 'Laporan Rekapitulasi SIRKULA-JOGJA',
                              text: 'Terlampir laporan rekapitulasi SIRKULA-JOGJA ($fileName).',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor laporan: $e'),
          backgroundColor: AppTheme.statusDisputed,
        ),
      );
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECEFF1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF78909C))),
          ],
        ),
      ),
    );
  }
}