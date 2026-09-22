import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import '../widgets/stat_card.dart';
import 'super_admin_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/dashboard');
      if (!mounted) return;
      setState(() => _stats = response['stats'] as Map<String, dynamic>);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StatCard(
                    label: 'Admins en attente',
                    value: '${stats['pending_admins'] ?? 0}',
                    color: AppTheme.warning,
                    icon: Icons.hourglass_top_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    label: 'Admins approuvés',
                    value: '${stats['approved_admins'] ?? 0}',
                    color: AppTheme.success,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    label: 'Total des Admins',
                    value: '${stats['total_admins'] ?? 0}',
                    color: Colors.blueGrey,
                    icon: Icons.groups_outlined,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
                    ),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Gérer les comptes Admins'),
                  ),
                ],
              ),
      ),
    );
  }
}
