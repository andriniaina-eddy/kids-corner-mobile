import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import '../widgets/stat_card.dart';
import 'employees_screen.dart';
import 'inventory_shops_screen.dart';
import 'products_management_screen.dart';
import 'shops_management_screen.dart';
import 'stock_takes_screen.dart';
import 'transfers_list_screen.dart';
import 'trash_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
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
      setState(() => _data = response);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = _data?['role'] as String?;
    final stats = (_data?['stats'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Bonjour, ${user?.name ?? ''}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (user?.companyName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(user!.companyName!, style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  const SizedBox(height: 20),
                  if (role == 'admin') ..._buildAdminCards(stats),
                  if (role == 'employee') ..._buildEmployeeCards(stats),
                  if (role == 'admin') ..._buildAdminManagementSection(),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildAdminCards(Map<String, dynamic> stats) {
    return [
      StatCard(
        label: 'Boutiques',
        value: '${stats['shops_count'] ?? 0}',
        color: AppTheme.primary,
        icon: Icons.storefront_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InventoryShopsScreen()),
        ),
      ),
      const SizedBox(height: 12),
      StatCard(
        label: 'Employés',
        value: '${stats['employees_count'] ?? 0}',
        color: Colors.blueAccent,
        icon: Icons.people_outline,
      ),
      const SizedBox(height: 12),
      StatCard(
        label: 'Produits au catalogue',
        value: '${stats['products_count'] ?? 0}',
        color: Colors.purple,
        icon: Icons.category_outlined,
      ),
      const SizedBox(height: 12),
      StatCard(
        label: 'Stocks sous seuil',
        value: '${stats['low_stock_count'] ?? 0}',
        color: AppTheme.danger,
        icon: Icons.warning_amber_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InventoryShopsScreen()),
        ),
      ),
      const SizedBox(height: 12),
      StatCard(
        label: 'Transferts en attente',
        value: '${stats['pending_transfers'] ?? 0}',
        color: AppTheme.warning,
        icon: Icons.swap_horiz_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransfersListScreen()),
        ),
      ),
    ];
  }

  List<Widget> _buildEmployeeCards(Map<String, dynamic> stats) {
    return [
      StatCard(
        label: 'Boutiques assignées',
        value: '${stats['assigned_shops'] ?? 0}',
        color: AppTheme.primary,
        icon: Icons.storefront_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InventoryShopsScreen()),
        ),
      ),
      const SizedBox(height: 12),
      StatCard(
        label: 'Stocks sous seuil',
        value: '${stats['low_stock_count'] ?? 0}',
        color: AppTheme.danger,
        icon: Icons.warning_amber_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InventoryShopsScreen()),
        ),
      ),
      const SizedBox(height: 12),
      StatCard(
        label: 'Transferts en attente',
        value: '${stats['pending_transfers'] ?? 0}',
        color: AppTheme.warning,
        icon: Icons.swap_horiz_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransfersListScreen()),
        ),
      ),
    ];
  }

  List<Widget> _buildAdminManagementSection() {
    return [
      const SizedBox(height: 28),
      Text('Gestion', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _ManagementTile(
        icon: Icons.storefront_outlined,
        label: 'Boutiques',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopsManagementScreen())),
      ),
      _ManagementTile(
        icon: Icons.people_outline,
        label: 'Employés',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmployeesScreen())),
      ),
      _ManagementTile(
        icon: Icons.category_outlined,
        label: 'Catalogue produits',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductsManagementScreen())),
      ),
      _ManagementTile(
        icon: Icons.fact_check_outlined,
        label: 'Inventaires mensuels',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockTakesScreen())),
      ),
      _ManagementTile(
        icon: Icons.delete_outline,
        label: 'Corbeille',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrashScreen())),
      ),
    ];
  }
}

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ManagementTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
