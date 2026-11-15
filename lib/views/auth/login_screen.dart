import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/sirkula_repository.dart';
import 'register_screen.dart';
import '../citizen/citizen_home_screen.dart';
import '../collector/collector_home_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'warga@sirkula.test');
  final _passwordController = TextEditingController(text: 'password');
  bool _isLoading = false;
  String? _errorMessage;

  void _selectQuickRole(UserRole role) {
    setState(() {
      switch (role) {
        case UserRole.citizen:
          _emailController.text = 'warga@sirkula.test';
          break;
        case UserRole.collector:
          _emailController.text = 'kader@sirkula.test';
          break;
        case UserRole.adminBsu:
          _emailController.text = 'bsu@sirkula.test';
          break;
        case UserRole.adminPlatform:
          _emailController.text = 'admin@sirkula.test';
          break;
      }
      _passwordController.text = 'password';
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = SirkulaRepository();
    final success = await repo.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && repo.currentUser != null) {
      _navigateByUserRole(repo.currentUser!);
    } else {
      setState(() => _errorMessage = 'Email atau password tidak sesuai.');
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

                // Quick Demo Role Switcher
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.touch_app, size: 16, color: AppTheme.primaryMedium),
                          SizedBox(width: 6),
                          Text(
                            'Pilih Akun Demo Cepat (Siap Uji & Presentasi):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildRoleChip(
                            label: 'Warga / Nasabah',
                            role: UserRole.citizen,
                            selectedEmail: 'warga@sirkula.test',
                          ),
                          _buildRoleChip(
                            label: 'Kader BSU',
                            role: UserRole.collector,
                            selectedEmail: 'kader@sirkula.test',
                          ),
                          _buildRoleChip(
                            label: 'Pengurus BSU',
                            role: UserRole.adminBsu,
                            selectedEmail: 'bsu@sirkula.test',
                          ),
                          _buildRoleChip(
                            label: 'Admin Kota Jogja',
                            role: UserRole.adminPlatform,
                            selectedEmail: 'admin@sirkula.test',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Fields
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryMedium),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryMedium),
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
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Warga baru di Kota Jogja? '),
                    GestureDetector(
                      onTap: () {
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

  Widget _buildRoleChip({
    required String label,
    required UserRole role,
    required String selectedEmail,
  }) {
    final isSelected = _emailController.text == selectedEmail;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectQuickRole(role),
      selectedColor: AppTheme.primaryMedium,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF2E7D32),
      ),
      side: const BorderSide(color: Color(0xFFA5D6A7)),
    );
  }
}
