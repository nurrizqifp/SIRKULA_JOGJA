import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/sirkula_repository.dart';
import '../../services/validators.dart';
import '../citizen/citizen_home_screen.dart';
import 'otp_verification_screen.dart';

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
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _submitted = false;

  bool _consentGranted = true;
  bool _isLoading = false;
  String? _errorMessage;

  Widget _buildPasswordRules(String pwd) {
    final rules = [
      ('Min. 8 karakter', pwd.length >= 8),
      ('Huruf besar (A-Z)', RegExp(r'[A-Z]').hasMatch(pwd)),
      ('Huruf kecil (a-z)', RegExp(r'[a-z]').hasMatch(pwd)),
      ('Angka (0-9)', RegExp(r'[0-9]').hasMatch(pwd)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: rules.map((r) {
        final ok = r.$2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: ok ? AppTheme.primaryMedium : const Color(0xFF78909C),
            ),
            const SizedBox(width: 4),
            Text(
              r.$1,
              style: TextStyle(
                fontSize: 11.5,
                color: ok ? AppTheme.primaryMedium : const Color(0xFF607D8B),
                fontWeight: ok ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

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
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    if (!_consentGranted) {
      setState(() => _errorMessage = 'Anda harus menyetujui pemrosesan data pribadi (UU PDP No. 27/2022).');
      return;
    }

    final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final email = _emailController.text.trim().toLowerCase();
    final phone = Validators.normalizePhone(_phoneController.text.trim());
    final address = _addressController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = SirkulaRepository();
    try {
      final res = await repo.registerCitizen(
        name: name,
        email: email,
        password: _passwordController.text,
        phone: phone,
        address: address,
        accessNotes: _accessNotesController.text.trim(),
        consentGranted: _consentGranted,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Supabase menyamarkan email yang sudah terdaftar: identities kosong.
      final identities = res.user?.identities;
      if (res.user != null && identities != null && identities.isEmpty) {
        setState(() {
          _errorMessage = 'Email $email sudah terdaftar. Anda tidak dapat mendaftar lagi, silakan masuk.';
        });
        return;
      }

      if (repo.currentUser != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CitizenMainNavigation()),
          (route) => false,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
        );
      }
    } on AuthApiException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      setState(() {
        _isLoading = false;
        if (msg.contains('already registered') || msg.contains('already exists') || e.code == 'user_already_exists') {
          _errorMessage = 'Email $email sudah terdaftar. Anda tidak dapat mendaftar lagi, silakan masuk.';
        } else if (msg.contains('rate limit') || e.code == 'over_email_send_rate_limit') {
          _errorMessage = 'Terlalu banyak permintaan email. Tunggu beberapa saat lalu coba lagi.';
        } else if (msg.contains('password')) {
          _errorMessage = 'Kata sandi ditolak server: ${e.message}';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal mendaftar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldMode = _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.onUnfocus;
    return Scaffold(
      appBar: AppBar(title: const Text('Pendaftaran Warga Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ayo Bersama Kelola Sampah Jogja',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 4),
              const Text(
                'Daftarkan rumah tangga Anda untuk layanan penjemputan jelantah dan botol plastik PET. Kode verifikasi akan dikirim ke email Anda.',
                style: TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                autovalidateMode: fieldMode,
                inputFormatters: InputGuards.name,
                decoration: const InputDecoration(labelText: 'Nama Lengkap / Kepala Keluarga'),
                validator: Validators.name,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autovalidateMode: fieldMode,
                inputFormatters: InputGuards.email,
                decoration: const InputDecoration(labelText: 'Alamat Email Aktif'),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autovalidateMode: fieldMode,
                inputFormatters: InputGuards.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp / HP',
                  hintText: '081234567890',
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                autovalidateMode: fieldMode,
                inputFormatters: InputGuards.address,
                decoration: const InputDecoration(
                  labelText: 'Alamat Rumah Lengkap (RT/RW/Kelurahan)',
                  hintText: 'Contoh: Kampung Badran RT 04 RW 11, Bumijo, Jetis',
                ),
                validator: Validators.address,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accessNotesController,
                maxLength: 150,
                inputFormatters: InputGuards.notes,
                decoration: const InputDecoration(
                  labelText: 'Catatan Akses Lokasi (Opsional)',
                  hintText: 'Contoh: Masuk gang depan pos ronda, rumah pagar hitam',
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                autovalidateMode: fieldMode,
                inputFormatters: InputGuards.password,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => Validators.password(v, email: _emailController.text),
              ),
              const SizedBox(height: 6),
              _buildPasswordRules(_passwordController.text),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                autovalidateMode: fieldMode,
                inputFormatters: InputGuards.password,
                decoration: const InputDecoration(labelText: 'Ulangi Kata Sandi'),
                validator: (v) => v != _passwordController.text ? 'Kata sandi tidak sama.' : null,
              ),
              const SizedBox(height: 16),
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
                          const Text('Persetujuan Pemrosesan Data Pribadi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          const Text(
                            'Saya menyetujui nomor kontak dan lokasi digunakan terbatas untuk layanan penjemputan sampah terpilah sesuai UU PDP No. 27/2022.',
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
                Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Daftar & Kirim Kode Verifikasi'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}