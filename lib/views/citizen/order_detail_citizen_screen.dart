import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/sirkula_repository.dart';
import '../../services/reward_calculator.dart';

class OrderDetailCitizenScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailCitizenScreen({super.key, required this.orderId});

  @override
  State<OrderDetailCitizenScreen> createState() => _OrderDetailCitizenScreenState();
}

class _OrderDetailCitizenScreenState extends State<OrderDetailCitizenScreen> {
  final _disputeReasonController = TextEditingController();

  void _showDisputeDialog(PickupOrderModel order, SirkulaRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Keberatan Timbangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jelaskan alasan perbedaan timbangan atau mutu yang tidak sesuai dengan hasil pengukuran petugas BSU:',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _disputeReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Contoh: Menurut timbangan rumah 4 liter, tapi tercatat 3 liter...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.statusDisputed),
            onPressed: () {
              if (_disputeReasonController.text.trim().isNotEmpty) {
                repo.citizenDisputeMeasurement(
                  orderId: order.id,
                  reason: _disputeReasonController.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keberatan berhasil diajukan. Status berubah menjadi Disengketakan.'),
                    backgroundColor: AppTheme.statusDisputed,
                  ),
                );
              }
            },
            child: const Text('Kirim Keberatan'),
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
        final order = repo.orders.firstWhere(
          (o) => o.id == widget.orderId,
          orElse: () => repo.orders.first,
        );

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

        final isWaitingConfirm = order.status == OrderStatus.waitingCitizenConfirmation;

        return Scaffold(
          appBar: AppBar(
            title: Text(order.orderNumber),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card with Status
              Card(
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status.displayName,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Mitra BSU: ${order.bsuName}', style: const TextStyle(fontSize: 13)),
                      Text(
                        'Jadwal Jemput: ${order.scheduledDate.day}-${order.scheduledDate.month}-${order.scheduledDate.year} · ${order.timeSlot}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
                      ),
                      Text('Titik Jemput: ${order.pickupAddress}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF546E7A))),
                      if (order.accessNotes != null && order.accessNotes!.isNotEmpty)
                        Text('Catatan: ${order.accessNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status Stepper (Tahapan Layanan)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alur Tahapan Penjemputan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 12),
                      _buildTimelineTile('Pemesanan Diterima BSU', true, 'BSU menerima permintaan jemput'),
                      _buildTimelineTile('Petugas Ditugaskan', order.status.stepIndex >= 2, order.collectorName != null ? 'Ditugaskan: ${order.collectorName}' : 'Menunggu alokasi kader'),
                      _buildTimelineTile('Penjemputan & Penimbangan', order.status.stepIndex >= 3, 'Pengukuran aktual & foto bukti'),
                      _buildTimelineTile('Konfirmasi Hasil oleh Warga', order.status.stepIndex >= 4, 'Validasi bersama sebelum poin cair'),
                      _buildTimelineTile('Selesai & Poin Dikreditkan', order.status == OrderStatus.completed, 'Poin masuk buku besar reward ledger', isLast: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dispute Alert Banner
              if (order.status == OrderStatus.disputed) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.report_problem, color: AppTheme.statusDisputed, size: 20),
                          SizedBox(width: 8),
                          Text('Pesanan Disengketakan', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.statusDisputed)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Alasan: ${order.disputeReason ?? "-"}', style: const TextStyle(fontSize: 12.5)),
                      const SizedBox(height: 4),
                      const Text(
                        'Poin belum dikreditkan ke dompet reward sampai pengurus BSU menyelesaikan rekonsiliasi timbangan.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF616161)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Measurement & Point Verification Details (Mockup 8.B & 8.C)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rincian Material & Hasil Ukur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          if (order.items.any((i) => i.verifiedQuantity != null))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Sudah Ditimbang', style: TextStyle(color: AppTheme.primaryMedium, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBE7).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item.commodityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('${item.basePoints} poin/${item.unit}', style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Perkiraan awal: ${item.estimatedQuantity} ${item.unit}', style: const TextStyle(fontSize: 12, color: Color(0xFF616161))),
                                if (item.verifiedQuantity != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.scale, size: 16, color: AppTheme.primaryGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Hasil Ukur Petugas: ${item.verifiedQuantity} ${item.unit}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Pengali Mutu: ${item.qualityFactor}x (${item.qualityNotes ?? "-"})',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF455A64)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Perhitungan Poin: ${RewardCalculator.explainCalculation(verifiedQuantity: item.verifiedQuantity!, unit: item.unit, basePointsPerUnit: item.basePoints, qualityMultiplier: item.qualityFactor)}',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      if (order.items.any((i) => i.verifiedQuantity != null)) ...[
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Poin yang Diperoleh:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '${order.totalCalculatedPoints} Poin',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons for Citizen Confirmation
              if (isWaitingConfirm) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Konfirmasi Hasil & Terima Poin'),
                  onPressed: () {
                    repo.citizenConfirmMeasurement(order.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Poin sebesar ${order.totalCalculatedPoints} berhasil masuk ke Reward Ledger Anda!'),
                        backgroundColor: AppTheme.primaryMedium,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.statusDisputed),
                  icon: const Icon(Icons.announcement_outlined),
                  label: const Text('Ajukan Keberatan / Perbedaan Timbang'),
                  onPressed: () => _showDisputeDialog(order, repo),
                ),
                const SizedBox(height: 8),
                const Text(
                  '*Poin baru masuk ke saldo dompet setelah Anda mengonfirmasi hasil pengukuran petugas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF78909C)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineTile(String title, bool isDone, String subtitle, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? AppTheme.primaryGreen : Colors.grey.shade400,
              size: 20,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isDone ? AppTheme.primaryGreen : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.5,
                  color: isDone ? const Color(0xFF263238) : Colors.grey.shade600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
