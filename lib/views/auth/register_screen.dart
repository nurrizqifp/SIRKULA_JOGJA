import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/sirkula_repository.dart';
import '../citizen/citizen_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _accessNotesController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _consentGranted = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Kebijakan Privasi Data', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pemberitahuan Pelindungan Data Pribadi (UU No. 27/2022)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                '1. Data yang Dikumpulkan: Nama, nomor telepon, alamat penjemputan sampah, dan titik koordinat rumah.\n\n'
                '2. Tujuan Penggunaan: Lokasi dan nomor kontak hanya digunakan untuk keperluan koordinasi penjemputan sampah terpilah (minyak jelantah dan botol PET) oleh kader BSU yang bertugas.\n\n'
                '3. Pembatasan Akses: Alamat lengkap rumah Anda TIDAK dipublikasikan secara terbuka di peta publik. Hanya kader/petugas yang ditugaskan resmi oleh BSU yang dapat melihat rincian lokasi saat jadwal penjemputan aktif.\n\n'
                '4. Hak Pengguna: Anda berhak memperbarui alamat atau meminta penonaktifan akun sewaktu-waktu sesuai tata kelola privasi sistem.',
                style: TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF37474F)),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Saya Pahami'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Mohon lengkapi seluruh kolom formulir.');
      return;
    }

    if (!_consentGranted) {
      setState(() => _errorMessage = 'Anda harus menyetujui pemrosesan data privasi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = SirkulaRepository();
    await repo.registerCitizen(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      accessNotes: _accessNotesController.text.trim(),
      consentGranted: _consentGranted,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registrasi warga berhasil! Selamat datang di SIRKULA-JOGJA.'),
        backgroundColor: AppTheme.primaryMedium,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CitizenMainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendaftaran Warga Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ayo Bersama Kelola Sampah Jogja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 4),
            const Text(
              'Daftarkan rumah tangga Anda untuk layanan penjemputan jelantah dan botol plastik PET.',
              style: TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap / Kepala Keluarga'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Alamat Email Aktif'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat Rumah Lengkap (RT/RW/Kelurahan)',
                hintText: 'Contoh: Kampung Badran RT 04 RW 11, Bumijo, Jetis',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accessNotesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Akses Lokasi (Opsional)',
                hintText: 'Contoh: Masuk gang depan pos ronda, rumah pagar hitam',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata Sandi Baru (Min. 8 Karakter)'),
            ),
            const SizedBox(height: 16),

            // Privacy consent box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _consentGranted,
                    activeColor: AppTheme.primaryMedium,
                    onChanged: (val) => setState(() => _consentGranted = val ?? false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Persetujuan Pemrosesan Data Pribadi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Saya menyetujui nomor kontak dan koordinat lokasi digunakan terbatas untuk layanan penjemputan sampah terpilah sesuai UU PDP No. 27/2022.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF455A64)),
                        ),
                        TextButton(
                          onPressed: _showPrivacyPolicyDialog,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('Baca Rincian Kebijakan Privasi', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Kirim Pendaftaran Warga'),
            ),
          ],
        ),
      ),
    );
  }
}
