import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/bsu_model.dart';
import '../../services/sirkula_repository.dart';
import 'create_order_screen.dart';

class BsuDirectoryScreen extends StatefulWidget {
  const BsuDirectoryScreen({super.key});

  @override
  State<BsuDirectoryScreen> createState() => _BsuDirectoryScreenState();
}

class _BsuDirectoryScreenState extends State<BsuDirectoryScreen> {
  String _filterCommodity = 'Semua';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final repo = SirkulaRepository();
    final allBsus = repo.getBsusSortedByDistance();

    final filtered = allBsus.where((b) {
      final matchesSearch = b.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          b.kemantren.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          b.kelurahan.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesCommodity = _filterCommodity == 'Semua' ||
          (_filterCommodity == 'Jelantah' && b.accepts('jelantah')) ||
          (_filterCommodity == 'Botol PET' && b.accepts('pet_bottle'));

      return matchesSearch && matchesCommodity;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direktori Mitra Bank Sampah'),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari BSU, kelurahan, atau kemantren...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryMedium),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['Semua', 'Jelantah', 'Botol PET'].map((cat) {
                    final isSelected = _filterCommodity == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _filterCommodity = cat),
                        selectedColor: AppTheme.primaryMedium,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : const Color(0xFF37474F),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // BSU Cards List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Tidak ada BSU yang sesuai filter pencarian.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final bsu = filtered[index];
                      final distanceKm = repo.getDistanceToBsu(bsu);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.storefront, color: AppTheme.primaryGreen, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                bsu.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F5E9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.verified, size: 12, color: AppTheme.primaryGreen),
                                                  SizedBox(width: 3),
                                                  Text('Terverifikasi', style: TextStyle(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${bsu.kelurahan}, ${bsu.kemantren}, Kota Yogyakarta',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF607D8B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(bsu.address, style: const TextStyle(fontSize: 12, color: Color(0xFF455A64))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Color(0xFF757575)),
                                  const SizedBox(width: 4),
                                  Text(bsu.operatingHours, style: const TextStyle(fontSize: 11.5, color: Color(0xFF616161))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 14, color: Color(0xFF757575)),
                                  const SizedBox(width: 4),
                                  Text(bsu.operationalContact, style: const TextStyle(fontSize: 11.5, color: Color(0xFF616161))),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Jarak: ${distanceKm.toStringAsFixed(1)} km perkiraan',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                      ),
                                      Text(
                                        'Menerima: ${bsu.acceptedCommodities.map((c) => c == 'jelantah' ? 'Jelantah' : 'Botol PET').join(', ')}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                                      ),
                                    ],
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateOrderScreen(preselectedBsuId: bsu.id),
                                        ),
                                      );
                                    },
                                    child: const Text('Pilih BSU', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
