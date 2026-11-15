import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/kpi_model.dart';
import '../../services/sirkula_repository.dart';
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAssignCollectorDialog(PickupOrderModel order, SirkulaRepository repo) {
    String selectedCollector = 'Indrianingsih (Kader BSU Lintas Winongo)';
    String phone = '085799988811';

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
                value: selectedCollector,
                isExpanded: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_pin, color: AppTheme.primaryGreen)),
                items: const [
                  DropdownMenuItem(value: 'Indrianingsih (Kader BSU Lintas Winongo)', child: Text('Indrianingsih (Winongo)')),
                  DropdownMenuItem(value: 'Pak Bambang (Kader Sagan)', child: Text('Pak Bambang (Sagan)')),
                  DropdownMenuItem(value: 'Bu Warsiti (Kader Kotagede)', child: Text('Bu Warsiti (Kotagede)')),
                ],
                onChanged: (val) {
                  setDialogState(() {
                    selectedCollector = val!;
                    phone = val.contains('Indrianingsih') ? '085799988811' : '081328004411';
                  });
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
                  collectorId: 'usr_collector_assign',
                  collectorName: selectedCollector,
                  collectorPhone: phone,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Petugas $selectedCollector berhasil ditugaskan!'),
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
                Tab(icon: Icon(Icons.assignment), text: 'Manajemen Pesanan'),
                Tab(icon: Icon(Icons.analytics), text: 'Dampak & Indikator Pilot'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Order Assignment & Disputes
              ListView.builder(
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

              // TAB 2: Pilot KPI & Impact Dashboard (Section 7.D)
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

                  // Export Actions
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Ekspor Laporan Rekapitulasi (CSV/PDF)'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Laporan CSV/PDF berhasil disiapkan untuk kebutuhan rekonsiliasi DLH & mitra.'),
                          backgroundColor: AppTheme.primaryMedium,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
