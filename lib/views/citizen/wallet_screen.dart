import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/sirkula_repository.dart';
import '../../models/reward_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Semua';

  final List<String> _categories = const ['Semua', 'Sembako', 'Voucher', 'Lingkungan'];

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

  void _showRedeemSuccessDialog(RewardCatalogItem reward, SirkulaRepository repo) {
    final success = repo.redeemReward(reward.id);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poin tidak mencukupi atau stok reward habis.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final latestCoupon = repo.coupons.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 48),
            SizedBox(height: 8),
            Text('Penukaran Berhasil!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Anda menukarkan: ${reward.name}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Column(
                children: [
                  const Text('KODE TOKEN PENUKARAN', style: TextStyle(fontSize: 11, color: Color(0xFF558B2F), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    latestCoupon.redemptionCode,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.qr_code_2, size: 84, color: AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  const Text('Tunjukkan kode/QR ini kepada petugas BSU untuk mengambil barang.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: Color(0xFF616161))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Simpan di Kupon Saya'),
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
        final balance = repo.citizenBalance;
        final ledgerEntries = repo.ledger.reversed.toList();
        final coupons = repo.coupons;

        final filteredRewards = _selectedCategory == 'Semua'
            ? repo.rewards
            : repo.rewards.where((r) => r.category == _selectedCategory).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dompet Poin & Katalog Reward'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: const Color(0xFF78909C),
              tabs: const [
                Tab(icon: Icon(Icons.card_giftcard), text: 'Katalog Reward'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Buku Besar Poin'),
                Tab(icon: Icon(Icons.confirmation_number), text: 'Kupon Saya'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Balance Card (Mockup 8.C)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo Poin Aktif Anda', style: TextStyle(color: Color(0xFFE8F5E9), fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$balance',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            const Text('Poin', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Text('1.000 Poin ≈ Rp 5.500 nilai sembako mitra', style: TextStyle(color: Color(0xFFC8E6C9), fontSize: 10.5)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1: Katalog Reward
                    ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (_) => setState(() => _selectedCategory = cat),
                                  selectedColor: AppTheme.primaryGreen,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : const Color(0xFF37474F),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Reward Item Cards
                        ...filteredRewards.map((reward) {
                          final canAfford = balance >= reward.pointsCost;
                          final hasStock = reward.stock > 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGreen, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reward.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(reward.description, style: const TextStyle(fontSize: 11.5, color: Color(0xFF616161))),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF3E0),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${reward.pointsCost} Poin',
                                                style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('Sisa stok: ${reward.stock}', style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: canAfford && hasStock ? AppTheme.primaryGreen : Colors.grey.shade400,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: canAfford && hasStock ? () => _showRedeemSuccessDialog(reward, repo) : null,
                                    child: Text(hasStock ? 'Tukar' : 'Habis', style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                    // TAB 2: Buku Besar Poin (Reward Ledger)
                    ledgerEntries.isEmpty
                        ? const Center(child: Text('Belum ada transaksi poin.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: ledgerEntries.length,
                            itemBuilder: (context, index) {
                              final entry = ledgerEntries[index];
                              final isCredit = entry.points > 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                    child: Icon(
                                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isCredit ? AppTheme.primaryGreen : Colors.red,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(entry.description, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    '${entry.timestamp.day}-${entry.timestamp.month}-${entry.timestamp.year} ${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')} WIB · Aktor: ${entry.actorName}',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF78909C)),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isCredit ? "+" : ""}${entry.points}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isCredit ? AppTheme.primaryGreen : Colors.red,
                                        ),
                                      ),
                                      Text('Saldo: ${entry.balanceAfter}', style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    // TAB 3: Kupon Saya
                    coupons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.confirmation_number_outlined, size: 54, color: Colors.grey),
                                const SizedBox(height: 10),
                                const Text('Belum ada kupon yang ditukarkan.'),
                                TextButton(
                                  onPressed: () => _tabController.animateTo(0),
                                  child: const Text('Buka Katalog Reward'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: coupons.length,
                            itemBuilder: (context, index) {
                              final c = coupons[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(c.rewardName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5E9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('Aktif', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Kode: ${c.redemptionCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen)),
                                      Text('Berlaku hingga: ${c.validUntil.day}-${c.validUntil.month}-${c.validUntil.year}', style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
