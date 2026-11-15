import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/sirkula_repository.dart';
import 'views/auth/login_screen.dart';
import 'views/citizen/citizen_home_screen.dart';
import 'views/collector/collector_home_screen.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'models/user_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SirkulaJogjaApp());
}

class SirkulaJogjaApp extends StatelessWidget {
  const SirkulaJogjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIRKULA-JOGJA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const InitialRouterPage(),
    );
  }
}

class InitialRouterPage extends StatelessWidget {
  const InitialRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SirkulaRepository();
    final user = repo.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    switch (user.role) {
      case UserRole.citizen:
        return const CitizenMainNavigation();
      case UserRole.collector:
        return const CollectorHomeScreen();
      case UserRole.adminBsu:
      case UserRole.adminPlatform:
        return const AdminDashboardScreen();
    }
  }
}
