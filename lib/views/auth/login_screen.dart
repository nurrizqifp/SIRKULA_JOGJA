import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/sirkula_repository.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart';
import '../../services/validators.dart';
import '../citizen/citizen_home_screen.dart';
import '../collector/collector_home_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final otpCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool otpSent = false;
    bool busy = false;
    String? dialogErr;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(otpSent ? 'Atur Ulang Kata Sandi' : 'Lupa Kata Sandi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  otpSent
                      ? 'Masukkan kode OTP dari email ${emailCtrl.text.trim()} dan kata sandi baru Anda.'
                      : 'Masukkan email terdaftar untuk menerima kode atur ulang kata sandi.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF455A64)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  enabled: !otpSent && !busy,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Alamat Email'),
                ),
                if (otpSent) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: otpCtrl,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kode OTP dari Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    enabled: !busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi Baru (min. 8, besar/kecil/angka)',
                    ),
                  ),
                ],
                if (dialogErr != null) ...[
                  const SizedBox(height: 10),
                  Text(dialogErr!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      final emailErr = Validators.email(email);
                      if (emailErr != null) {
                        setDialogState(() => dialogErr = emailErr);
                        return;
                      }
                      if (!otpSent) {
                        setDialogState(() {
                          busy = true;
                          dialogErr = null;
                        });
                        try {
                          await SirkulaRepository().sendPasswordResetOtp(email);
                          setDialogState(() {
                            busy = false;
                            otpSent = true;
                          });
                        } catch (e) {
                          setDialogState(() {
                            busy = false;
                            dialogErr = 'Gagal mengirim OTP: $e';
                          });
                        }
                      } else {
                        final otpErr = Validators.otp(otpCtrl.text);
                        final passErr = Validators.password(passCtrl.text, email: email);
                        if (otpErr != null || passErr != null) {
                          setDialogState(() => dialogErr = otpErr ?? passErr);
                          return;
                        }
                        setDialogState(() {
                          busy = true;
                          dialogErr = null;
                        });
                        try {
                          await SirkulaRepository().verifyRecoveryAndUpdatePassword(
                            email: email,
                            token: otpCtrl.text,
                            newPassword: passCtrl.text,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Kata sandi berhasil diperbarui. Silakan masuk dengan kata sandi baru.'),
                              backgroundColor: AppTheme.primaryMedium,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() {
                            busy = false;
                            dialogErr = 'Kode OTP tidak valid atau gagal memperbarui kata sandi.';
                          });
                        }
                      }
                    },
              child: busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(otpSent ? 'Simpan Kata Sandi' : 'Kirim Kode OTP'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Mohon isi email dan kata sandi Anda.');
      return;
    }
    final emailError = Validators.email(email);
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = SirkulaRepository();
    try {
      await repo.login(email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (repo.currentUser != null) {
        if (!repo.currentUser!.isActive) {
          await repo.logout();
          if (!mounted) return;
          setState(() => _errorMessage = 'Akun Anda dinonaktifkan oleh administrator.');
          return;
        }
        _navigateByUserRole(repo.currentUser!);
      } else {
        setState(() => _errorMessage = 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.');
      }
    } on AuthApiException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed') || e.code == 'email_not_confirmed') {
        try {
          await repo.resendSignupOtp(email);
        } catch (_) {}
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email.toLowerCase())),
        );
        return;
      }
      setState(() {
        _isLoading = false;
        if (msg.contains('invalid login credentials')) {
          _errorMessage = 'Email atau kata sandi salah. Silakan periksa kembali.';
        } else if (msg.contains('rate limit')) {
          _errorMessage = 'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal masuk: $e';
      });
    }
  }

  void _navigateByUserRole(UserModel user) {
    Widget targetScreen;
    switch (user.role) {
      case UserRole.citizen:
        targetScreen = const CitizenMainNavigation();
        break;
      case UserRole.collector:
        targetScreen = const CollectorHomeScreen();
        break;
      case UserRole.adminBsu:
      case UserRole.adminPlatform:
        targetScreen = const AdminDashboardScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.recycling_rounded,
                      size: 64,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SIRKULA-JOGJA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistem Integrasi Jemput Sampah Terpilah, Reward Jelantah-Botol & Edukasi Lingkar Hijau Jogja',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF546E7A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Form Fields
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Email',
                    hintText: 'nama@domain.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryMedium),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryMedium),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text('Lupa Kata Sandi?'),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),

                // Login Button
                FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Masuk ke SIRKULA-JOGJA'),
                ),
                const SizedBox(height: 12),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Warga baru di Kota Jogja?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          color: AppTheme.primaryMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Context footer
                const Center(
                  child: Text(
                    'Program Kreativitas Mahasiswa (PKM) 2026\nUniversitas Muhammadiyah Yogyakarta',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
