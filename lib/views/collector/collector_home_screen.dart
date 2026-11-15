import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/sirkula_repository.dart';
import 'measurement_screen.dart';
import '../citizen/citizen_home_screen.dart';
import '../shared/profile_screen.dart';

class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final repo = SirkulaRepository();

    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final user = repo.currentUser;
        final allOrders = repo.orders;

        // Filter orders relevant for collector
        final assignedOrders = allOrders.where(
          (o) => o.status == OrderStatus.assigned || o.status == OrderStatus.inPickup,
        ).toList();

        final waitingConfirmOrders = allOrders.where(
          (o) => o.status == OrderStatus.waitingCitizenConfirmation,
        ).toList();

        final completedOrders = allOrders.where(
          (o) => o.status == OrderStatus.completed,
        ).toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard Kader BSU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${user?.name ?? "Kader BSU"} · BSU Lintas Winongo',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF607D8B)),
                ),
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
              tabs: [
                Tab(text: 'Tugas Jemput (${assignedOrders.length})'),
                Tab(text: 'Menunggu (${waitingConfirmOrders.length})'),
                Tab(text: 'Selesai (${completedOrders.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Assigned & In Pickup Orders
              _buildOrdersList(
                context,
                orders: assignedOrders,
                emptyMessage: 'Tidak ada tugas penjemputan baru saat ini.',
                repo: repo,
                isActionable: true,
              ),

              // TAB 2: Waiting Citizen Confirmation
              _buildOrdersList(
                context,
                orders: waitingConfirmOrders,
                emptyMessage: 'Tidak ada pesanan yang menunggu konfirmasi warga.',
                repo: repo,
                isActionable: false,
              ),

              // TAB 3: Completed Orders
              _buildOrdersList(
                context,
                orders: completedOrders,
                emptyMessage: 'Belum ada riwayat penjemputan yang selesai.',
                repo: repo,
                isActionable: false,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersList(
    BuildContext context, {
    required List<PickupOrderModel> orders,
    required String emptyMessage,
    required SirkulaRepository repo,
    required bool isActionable,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.task_alt, size: 54, color: Colors.grey),
              const SizedBox(height: 12),
              Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF757575))),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isInPickup = order.status == OrderStatus.inPickup;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        color: AppTheme.primaryLight.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF616161)),
                    const SizedBox(width: 6),
                    Text(order.citizenName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text('(${order.citizenPhone})', style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF616161)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(order.pickupAddress, style: const TextStyle(fontSize: 12, color: Color(0xFF455A64))),
                    ),
                  ],
                ),
                if (order.accessNotes != null && order.accessNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Catatan: ${order.accessNotes}',
                    style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF616161)),
                  ),
                ],
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Komoditas yang diminta:', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                        Text(order.commoditiesSummary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    if (isActionable) ...[
                      if (!isInPickup)
                        FilledButton.tonal(
                          onPressed: () => repo.startPickup(order.id),
                          child: const Text('Mulai Jemput', style: TextStyle(fontSize: 12)),
                        )
                      else
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MeasurementScreen(orderId: order.id),
                              ),
                            );
                          },
                          child: const Text('Input Timbangan', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
