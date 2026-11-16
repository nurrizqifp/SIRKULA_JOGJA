import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/sirkula_repository.dart';
import '../../models/order_model.dart';
import '../../models/bsu_model.dart';
import 'create_order_screen.dart';
import 'order_detail_citizen_screen.dart';
import 'wallet_screen.dart';
import 'education_screen.dart';
import 'bsu_directory_screen.dart';
import '../shared/profile_screen.dart';

class CitizenMainNavigation extends StatefulWidget {
  const CitizenMainNavigation({super.key});

  @override
  State<CitizenMainNavigation> createState() => _CitizenMainNavigationState();
}

class _CitizenMainNavigationState extends State<CitizenMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CitizenHomeScreen(),
    CitizenOrdersTab(),
    WalletScreen(),
    EducationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppTheme.primaryLight.withOpacity(0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryGreen),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars, color: AppTheme.primaryGreen),
            label: 'Poin',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: AppTheme.primaryGreen),
            label: 'Mas JOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryGreen),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SirkulaRepository();

    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final user = repo.currentUser;
        final balance = repo.citizenBalance;
        final activeOrders = repo.orders.where(
          (o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled,
        ).toList();
        final recentOrder = activeOrders.isNotEmpty ? activeOrders.first : (repo.orders.isNotEmpty ? repo.orders.first : null);
        final nearbyBsus = repo.getBsusSortedByDistance().take(3).toList();

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.eco, color: AppTheme.primaryMedium, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('SIRKULA-JOGJA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        user?.primaryAddress ?? 'Kota Yogyakarta',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF607D8B), fontWeight: FontWeight.normal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => repo.loadCloudData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Top Greeting & Total Points Card (Mockup 8.A)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF81C784),
                                child: Icon(Icons.person, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 10),
                                Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Warga SIRKULA',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user?.roleDisplayName ?? 'Warga / Nasabah',
                                    style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.recycling, color: Color(0xFFFFD54F), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${repo.orders.where((o) => o.citizenId == user?.id && o.status == OrderStatus.completed).length} Setoran',
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saldo Poin Terverifikasi',
                                style: TextStyle(color: Color(0xFFE8F5E9), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '$balance',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Poin',
                                    style: TextStyle(color: Color(0xFFFFD54F), fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300),
                              foregroundColor: const Color(0xFF3E2723),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Setor Sampah', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Action Buttons (Pesan Jemput, Tukar Poin, Belajar Mas JOS)
                Row(
                  children: [
                    _buildQuickAction(
                      context: context,
                      title: 'Pesan Jemput',
                      subtitle: 'Jelantah & Botol',
                      icon: Icons.local_shipping,
                      color: AppTheme.primaryMedium,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildQuickAction(
                      context: context,
                      title: 'Tukar Reward',
                      subtitle: 'Sembako & Pulsa',
                      icon: Icons.stars,
                      color: const Color(0xFFF57F17),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildQuickAction(
                      context: context,
                      title: 'Akademi Jogja',
                      subtitle: '5 Aksi Mas JOS',
                      icon: Icons.menu_book,
                      color: const Color(0xFF00796B),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EducationScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Active Order Tracker Banner (If any)
                if (recentOrder != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Penjemputan Terkini',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailCitizenScreen(orderId: recentOrder.id),
                            ),
                          );
                        },
                        child: const Text('Lihat Detail', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  _buildLiveOrderCard(context, recentOrder),
                  const SizedBox(height: 18),
                ],

                // 5 Aksi Mas JOS Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryMedium,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.nature_people, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gerakan Mas JOS Kota Yogyakarta',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
                            ),
                            const Text(
                              'Pilah di rumah, setor ke BSU, olah organik mandiri, habiskan makanan & cegah plastik!',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF37474F)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryMedium),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EducationScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nearby BSU Partners (Direktori BSU dengan Haversine)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Direktori Mitra BSU Terdekat',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BsuDirectoryScreen()),
                        );
                      },
                      child: Text('Lihat Semua (${nearbyBsus.length})', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                ...nearbyBsus.map((bsu) => _buildBsuCard(context, bsu, repo)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECEFF1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF78909C)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveOrderCard(BuildContext context, PickupOrderModel order) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.completed:
        statusColor = AppTheme.statusSuccess;
        break;
      case OrderStatus.waitingCitizenConfirmation:
        statusColor = AppTheme.statusWaitingConfirm;
        break;
      case OrderStatus.inPickup:
        statusColor = AppTheme.statusInTransit;
        break;
      case OrderStatus.assigned:
        statusColor = AppTheme.statusAssigned;
        break;
      case OrderStatus.disputed:
        statusColor = AppTheme.statusDisputed;
        break;
      default:
        statusColor = AppTheme.statusPending;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mitra: ${order.bsuName}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF455A64)),
            ),
            Text(
              'Komoditas: ${order.commoditiesSummary}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF455A64)),
            ),
            const SizedBox(height: 10),
            if (order.status == OrderStatus.waitingCitizenConfirmation)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_turned_in, color: Color(0xFF00838F), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Petugas selesai menimbang! Harap konfirmasi agar poin masuk.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF006064), fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00838F),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailCitizenScreen(orderId: order.id),
                          ),
                        );
                      },
                      child: const Text('Buka', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBsuCard(BuildContext context, BsuPartnerModel bsu, SirkulaRepository repo) {
    final distanceKm = repo.getDistanceToBsu(bsu);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.storefront, color: AppTheme.primaryGreen, size: 26),
        ),
        title: Text(bsu.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(bsu.address, style: const TextStyle(fontSize: 11.5, color: Color(0xFF607D8B)), maxLines: 1),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${distanceKm.toStringAsFixed(1)} km perkiraan',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.primaryMedium, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  bsu.acceptedCommodities.map((c) => c == 'jelantah' ? 'Jelantah' : 'Botol PET').join(' & '),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF37474F)),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFB0BEC5)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateOrderScreen(preselectedBsuId: bsu.id),
            ),
          );
        },
      ),
    );
  }
}

class CitizenOrdersTab extends StatelessWidget {
  const CitizenOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SirkulaRepository();

    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final orders = repo.orders;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat & Status Pesanan'),
          ),
          body: orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Belum ada pesanan penjemputan sampah.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                          );
                        },
                        child: const Text('Buat Pesanan Baru'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                          child: const Icon(Icons.receipt, color: AppTheme.primaryGreen),
                        ),
                        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${order.bsuName}\n${order.status.displayName} · ${order.scheduledDate.day}-${order.scheduledDate.month}-${order.scheduledDate.year}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailCitizenScreen(orderId: order.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Pesan Jemput'),
            backgroundColor: AppTheme.primaryMedium,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}
