import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/sirkula_repository.dart';
import '../../services/validators.dart';
import '../citizen/citizen_home_screen.dart';
import '../collector/collector_home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../models/user_model.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    final repo = SirkulaRepository();
    try {
      await repo.verifyEmailOtp(widget.email, _codeController.text);
      if (!mounted) return;
      final user = repo.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Verifikasi gagal. Silakan coba lagi.';
        });
        return;
      }
      Widget target;
      switch (user.role) {
        case UserRole.citizen:
          target = const CitizenMainNavigation();
          break;
        case UserRole.collector:
          target = const CollectorHomeScreen();
          break;
        case UserRole.adminBsu:
        case UserRole.adminPlatform:
          target = const AdminDashboardScreen();
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email terverifikasi. Selamat datang di SIRKULA-JOGJA!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => target),
        (route) => false,
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      final m = e.message.toLowerCase();
      setState(() {
        _isLoading = false;
        _errorMessage = (m.contains('expired') || m.contains('invalid'))
            ? 'Kode salah atau sudah kedaluwarsa. Periksa kembali atau kirim ulang kode.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal verifikasi: $e';
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await SirkulaRepository().resendSignupOtp(widget.email);
      if (!mounted) return;
      setState(() => _infoMessage = 'Kode baru telah dikirim ke ${widget.email}.');
      _startCooldown();
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message.toLowerCase().contains('rate')
          ? 'Terlalu sering meminta kode. Tunggu beberapa saat lalu coba lagi.'
          : e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Gagal mengirim ulang kode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 64, color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              const Text(
                'Masukkan Kode Verifikasi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 8),
              Text(
                'Kami telah mengirim kode verifikasi ke\n${widget.email}\nPeriksa kotak masuk atau folder spam.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF546E7A)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: InputGuards.otp,
                style: const TextStyle(fontSize: 24, letterSpacing: 6),
                decoration: const InputDecoration(labelText: 'Kode Verifikasi', counterText: ''),
                validator: Validators.otp,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              ],
              if (_infoMessage != null) ...[
                const SizedBox(height: 8),
                Text(_infoMessage!, style: const TextStyle(color: AppTheme.primaryMedium, fontSize: 13), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verifikasi & Masuk'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _cooldown == 0 ? _resend : null,
                child: Text(_cooldown == 0 ? 'Kirim Ulang Kode' : 'Kirim ulang dalam $_cooldown detik'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
