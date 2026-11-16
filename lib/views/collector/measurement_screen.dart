import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/commodity_model.dart';
import '../../services/sirkula_repository.dart';
import '../../services/validators.dart';
import '../../services/reward_calculator.dart';

class MeasurementScreen extends StatefulWidget {
  final String orderId;

  const MeasurementScreen({super.key, required this.orderId});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  late PickupOrderModel _order;
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, double> _qualityFactors = {};
  final Map<int, TextEditingController> _notesControllers = {};
  bool _hasPhotoProof = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final repo = SirkulaRepository();
    _order = repo.orders.firstWhere((o) => o.id == widget.orderId);

    for (int i = 0; i < _order.items.length; i++) {
      final item = _order.items[i];
      _qtyControllers[i] = TextEditingController(
        text: (item.verifiedQuantity ?? item.estimatedQuantity).toString(),
      );
      _qualityFactors[i] = item.qualityFactor;
      _notesControllers[i] = TextEditingController(
        text: item.qualityNotes ?? (item.commodityKey == 'jelantah' ? 'Disaring bersih dalam jeriken' : 'Botol kering dan dipipihkan'),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    final repo = SirkulaRepository();

    final verifiedItems = <OrderItemModel>[];
    for (int i = 0; i < _order.items.length; i++) {
      final old = _order.items[i];
      final verifiedQty = double.tryParse((_qtyControllers[i]?.text ?? '').trim().replaceAll(',', '.'));
      if (verifiedQty == null || verifiedQty <= 0 || verifiedQty > 1000) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Berat/volume ${old.commodityName} harus angka lebih dari 0 dan maksimal 1000.'),
          backgroundColor: Colors.red,
        ));
        return;
      }
      final factor = _qualityFactors[i] ?? 1.0;
      final note = _notesControllers[i]?.text.trim();

      verifiedItems.add(
        OrderItemModel(
          commodityKey: old.commodityKey,
          commodityName: old.commodityName,
          unit: old.unit,
          estimatedQuantity: old.estimatedQuantity,
          verifiedQuantity: verifiedQty,
          qualityFactor: factor,
          qualityNotes: note,
          photoProofUrl: _hasPhotoProof ? 'dikonfirmasi-kader' : null,
          basePoints: old.basePoints,
        ),
      );
    }

    repo.submitMeasurement(
      orderId: _order.id,
      verifiedItems: verifiedItems,
    );

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hasil timbang tersimpan! Menunggu konfirmasi dari warga.'),
        backgroundColor: AppTheme.primaryMedium,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Timbang - ${_order.orderNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order & Citizen Info Banner
            Card(
              color: const Color(0xFFF1F8E9),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Warga: ${_order.citizenName} (${_order.citizenPhone})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('Alamat: ${_order.pickupAddress}', style: const TextStyle(fontSize: 12, color: Color(0xFF455A64))),
                    if (_order.accessNotes != null)
                      Text('Catatan: ${_order.accessNotes}', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Input Hasil Pengukuran Aktual & Mutu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen),
            ),
            const Text(
              'Timbang botol PET atau ukur volume minyak jelantah bersama warga.',
              style: TextStyle(fontSize: 12, color: Color(0xFF616161)),
            ),
            const SizedBox(height: 14),

            // Item Input Cards
            ...List.generate(_order.items.length, (i) {
              final item = _order.items[i];
              final currentFactor = _qualityFactors[i] ?? 1.0;
              final currentQty = double.tryParse(_qtyControllers[i]?.text ?? '') ?? 0.0;
              final previewPoints = RewardCalculator.calculate(
                verifiedQuantity: currentQty,
                basePointsPerUnit: item.basePoints,
                qualityMultiplier: currentFactor,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.commodityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Perkiraan warga: ${item.estimatedQuantity} ${item.unit}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quantity input
                      TextField(
                        controller: _qtyControllers[i],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: InputGuards.decimalQty,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Jumlah Terverifikasi (${item.unit})',
                          suffixText: item.unit,
                          prefixIcon: const Icon(Icons.scale, color: AppTheme.primaryMedium),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quality Multiplier Dropdown
                      const Text('Penilaian Kualitas & Kebersihan Material:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<double>(
                        value: currentFactor,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.grade, color: Color(0xFFF57F17)),
                        ),
                        items: QualityMultiplier.all.map((q) {
                          return DropdownMenuItem<double>(
                            value: q.factor,
                            child: Text(q.label, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _qualityFactors[i] = val ?? 1.0;
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      // Quality notes
                      TextField(
                        controller: _notesControllers[i],
                        maxLength: 150,
                        inputFormatters: InputGuards.notes,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Mutu / Alasan Koreksi',
                          hintText: 'Contoh: Minyak jernih disaring rapi, wadah bersih',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Live preview of points calculation
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE6EE9C)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimasi Poin Masuk:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(
                              '$previewPoints Poin',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Photo Proof Attachment Card (Mockup 8.E)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt, color: AppTheme.primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text('Foto Bukti Timbangan / Wadah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCFD8DC)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 36),
                            const SizedBox(height: 4),
                            Text(
                              _hasPhotoProof ? 'Foto bukti timbangan terlampir (bukti_ukur_${_order.orderNumber}.jpg)' : 'Ambil foto timbangan',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF455A64), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Simpan & Minta Konfirmasi Warga'),
            ),
          ],
        ),
      ),
    );
  }
}
