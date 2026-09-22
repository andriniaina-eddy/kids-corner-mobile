import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _roleLabel(String? role) {
    switch (role) {
      case 'super_admin':
        return 'Super Administrateur';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Employé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primary,
            child: Text(
              (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
              style: const TextStyle(fontSize: 28, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade600)),
          ),
          if (user?.companyName != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(user!.companyName!, style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Chip(label: Text(_roleLabel(user?.role))),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout, color: AppTheme.danger),
            label: const Text('Se déconnecter', style: TextStyle(color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
