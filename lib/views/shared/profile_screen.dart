import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/sirkula_repository.dart';
import '../auth/login_screen.dart';
import '../citizen/citizen_home_screen.dart';
import '../collector/collector_home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'mockup_gallery_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _switchRole(BuildContext context, SirkulaRepository repo, UserRole role) {
    repo.switchDemoUser(role);
    Widget nextScreen;
    switch (role) {
      case UserRole.citizen:
        nextScreen = const CitizenMainNavigation();
        break;
      case UserRole.collector:
        nextScreen = const CollectorHomeScreen();
        break;
      case UserRole.adminBsu:
      case UserRole.adminPlatform:
        nextScreen = const AdminDashboardScreen();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = SirkulaRepository();
    final user = repo.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan Akun'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryLight.withOpacity(0.3),
                    child: const Icon(Icons.person, size: 36, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Pengguna SIRKULA',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF607D8B)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user?.roleDisplayName ?? 'Warga',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User details
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: AppTheme.primaryMedium),
                  title: const Text('Nomor WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(user?.phone ?? '-', style: const TextStyle(fontSize: 12)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryMedium),
                  title: const Text('Alamat Penjemputan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(user?.primaryAddress ?? '-', style: const TextStyle(fontSize: 12)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryMedium),
                  title: const Text('Status Privasi UU PDP No. 27/2022', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Persetujuan pemrosesan data jemput aktif & terlindungi.', style: TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32))),
                  trailing: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Switch Demo Account (for review & presentation)
          const Text(
            'Ganti Peran Demo (Simulasi Antar-Aktor):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: AppTheme.primaryGreen),
                  title: const Text('Peran 1: Warga / Nasabah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pesan penjemputan, cek poin, konfirmasi timbang, kuis Mas JOS.', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () => _switchRole(context, repo, UserRole.citizen),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.two_wheeler, color: Color(0xFFE65100)),
                  title: const Text('Peran 2: Kader / Kurir BSU', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Lihat tugas jemput, isi hasil timbang & pengali mutu di lapangan.', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () => _switchRole(context, repo, UserRole.collector),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF00796B)),
                  title: const Text('Peran 3: Pengurus BSU & Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Tugaskan kader, tangani sengketa, dan monitor KPI pilot KMM.', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () => _switchRole(context, repo, UserRole.adminBsu),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Mockup Gallery Button
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Lihat Desain Mockup Bab 8 Proposal'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MockupGalleryScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Logout Button
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari Sesi'),
            onPressed: () {
              repo.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 20),

          // App Version Information
          const Center(
            child: Text(
              'SIRKULA-JOGJA v1.0.0+1 (MVP Pilot KMM AST-PTMA 2026)\nTeknologi: Flutter Android + Laravel REST API',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
            ),
          ),
        ],
      ),
    );
  }
}
