import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/sirkula_repository.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
          const SizedBox(height: 24),

          // Logout Button
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari Sesi'),
            onPressed: () async {
              await repo.logout();
              if (!context.mounted) return;
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
              'SIRKULA-JOGJA v1.0.0+1 (MVP Pilot KMM AST-PTMA 2026)\nTeknologi: Flutter Android + Supabase Cloud',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
            ),
          ),
        ],
      ),
    );
  }
}
