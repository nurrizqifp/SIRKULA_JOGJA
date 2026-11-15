import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/sirkula_repository.dart';
import '../../models/order_model.dart';
import '../../models/bsu_model.dart';
import '../../models/commodity_model.dart';
import 'order_detail_citizen_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  final String? preselectedBsuId;

  const CreateOrderScreen({super.key, this.preselectedBsuId});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _jelantahQtyController = TextEditingController(text: '3.0');
  final _petQtyController = TextEditingController(text: '2.5');

  String? _selectedBsuId;
  bool _pickJelantah = true;
  bool _pickPet = true;
  DateTime? _selectedDate;
  String _selectedTimeSlot = 'Pagi (08.00 - 11.00 WIB)';
  bool _isSubmitting = false;
  String? _validationError;

  final List<String> _timeSlots = const [
    'Pagi (08.00 - 11.00 WIB)',
    'Siang (13.00 - 15.00 WIB)',
  ];

  @override
  void initState() {
    super.initState();
    final repo = SirkulaRepository();
    _addressController.text = repo.currentUser?.primaryAddress ?? '';
    _notesController.text = repo.currentUser?.accessNotes ?? '';

    final sortedBsus = repo.getBsusSortedByDistance();
    if (widget.preselectedBsuId != null && sortedBsus.any((b) => b.id == widget.preselectedBsuId)) {
      _selectedBsuId = widget.preselectedBsuId;
    } else if (sortedBsus.isNotEmpty) {
      _selectedBsuId = sortedBsus.first.id;
    }

    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _submitOrder() async {
    if (!_pickJelantah && !_pickPet) {
      setState(() => _validationError = 'Pilih minimal satu jenis sampah (Jelantah atau Botol PET).');
      return;
    }

    if (_selectedBsuId == null) {
      setState(() => _validationError = 'Pilih Bank Sampah Unit (BSU) mitra.');
      return;
    }

    if (_selectedDate == null) {
      setState(() => _validationError = 'Pilih tanggal jadwal penjemputan.');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      setState(() => _validationError = 'Alamat penjemputan tidak boleh kosong.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    final repo = SirkulaRepository();
    final items = <OrderItemModel>[];

    if (_pickJelantah) {
      final qty = double.tryParse(_jelantahQtyController.text) ?? 1.0;
      items.add(
        OrderItemModel(
          commodityKey: 'jelantah',
          commodityName: 'Minyak Jelantah',
          unit: 'Liter',
          estimatedQuantity: qty,
          basePoints: 1000,
        ),
      );
    }

    if (_pickPet) {
      final qty = double.tryParse(_petQtyController.text) ?? 1.0;
      items.add(
        OrderItemModel(
          commodityKey: 'pet_bottle',
          commodityName: 'Botol Plastik PET',
          unit: 'Kg',
          estimatedQuantity: qty,
          basePoints: 3500,
        ),
      );
    }

    final order = await repo.createOrder(
      bsuId: _selectedBsuId!,
      scheduledDate: _selectedDate!,
      timeSlot: _selectedTimeSlot,
      pickupAddress: _addressController.text.trim(),
      accessNotes: _notesController.text.trim(),
      items: items,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesanan ${order.orderNumber} berhasil dibuat!'),
        backgroundColor: AppTheme.primaryMedium,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailCitizenScreen(orderId: order.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = SirkulaRepository();
    final bsus = repo.getBsusSortedByDistance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemesanan Penjemputan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STEP 1: Pilih Komoditas
            const Text(
              '1. Pilih Komoditas Sampah Terpilah',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 8),

            // Jelantah Selector Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: _pickJelantah ? AppTheme.jelantahGold : const Color(0xFFE0E0E0),
                  width: _pickJelantah ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _pickJelantah,
                          activeColor: AppTheme.jelantahGold,
                          onChanged: (v) => setState(() => _pickJelantah = v ?? false),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.jelantahLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.water_drop, color: AppTheme.jelantahGold, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minyak Jelantah Rumah Tangga',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Satuan: Liter · Poin dasar: 1.000 poin/liter',
                                style: TextStyle(fontSize: 11, color: Color(0xFF616161)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_pickJelantah) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Text('Perkiraan volume:', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _jelantahQtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                suffixText: 'L',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: AppTheme.jelantahGold),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Panduan: Saring sisa makanan, simpan dalam jeriken/wadah plastik tertutup rapat & tidak bocor.',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF5D4037)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Botol PET Selector Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: _pickPet ? AppTheme.petBlue : const Color(0xFFE0E0E0),
                  width: _pickPet ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _pickPet,
                          activeColor: AppTheme.petBlue,
                          onChanged: (v) => setState(() => _pickPet = v ?? false),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.petLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.recycling, color: AppTheme.petBlue, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Botol Plastik PET (Bening & Warna)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Satuan: Kg · Poin dasar: 3.500 poin/kg',
                                style: TextStyle(fontSize: 11, color: Color(0xFF616161)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_pickPet) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Text('Perkiraan berat:', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _petQtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                suffixText: 'Kg',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: AppTheme.petBlue),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Panduan: Buang seluruh sisa cairan, bilas jika manis, dan pipihkan botol untuk menghemat tempat.',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF01579B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // STEP 2: Pilih BSU Mitra
            const Text(
              '2. Pilih Bank Sampah Unit (BSU) Mitra',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBsuId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Mitra Pengumpul Wilayah Anda',
                prefixIcon: Icon(Icons.storefront, color: AppTheme.primaryMedium),
              ),
              items: bsus.map((bsu) {
                final dist = repo.getDistanceToBsu(bsu);
                return DropdownMenuItem<String>(
                  value: bsu.id,
                  child: Text(
                    '${bsu.name} (${dist.toStringAsFixed(1)} km)',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedBsuId = val),
            ),
            const SizedBox(height: 6),
            const Text(
              '*Jarak dihitung garis lurus (formula Haversine) sebagai estimasi terdekat.',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF78909C), fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),

            // STEP 3: Jadwal & Waktu Jemput
            const Text(
              '3. Tentukan Jadwal Penjemputan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFCFD8DC)),
              ),
              leading: const Icon(Icons.calendar_month, color: AppTheme.primaryMedium),
              title: Text(
                _selectedDate == null
                    ? 'Pilih Tanggal'
                    : 'Tanggal: ${_selectedDate!.day} - ${_selectedDate!.month} - ${_selectedDate!.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: const Text('Klik untuk ubah tanggal', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedTimeSlot,
              decoration: const InputDecoration(
                labelText: 'Rentang Jam Penjemputan',
                prefixIcon: Icon(Icons.access_time, color: AppTheme.primaryMedium),
              ),
              items: _timeSlots
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) => setState(() => _selectedTimeSlot = val!),
            ),
            const SizedBox(height: 20),

            // STEP 4: Konfirmasi Alamat & Catatan Akses
            const Text(
              '4. Alamat & Titik Penjemputan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat Rumah Warga',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryMedium),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Akses Lokasi (Opsional)',
                hintText: 'Contoh: Sebelah barat pos ronda, gang sempit',
                prefixIcon: Icon(Icons.edit_note, color: AppTheme.primaryMedium),
              ),
            ),

            if (_validationError != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _validationError!,
                  style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Submit Button
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitOrder,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Kirim Pemesanan ke BSU'),
            ),
          ],
        ),
      ),
    );
  }
}
