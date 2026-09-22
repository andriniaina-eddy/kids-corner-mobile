import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import '../widgets/status_badge.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  List<PendingAdmin> _admins = [];
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
      final response = await api.get('/super-admin/admins');
      final admins = (response['admins']['data'] as List<dynamic>)
          .map((json) => PendingAdmin.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _admins = admins);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(PendingAdmin admin) async {
    try {
      final api = context.read<ApiService>();
      await api.post('/super-admin/admins/${admin.id}/approve');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Compte approuvé.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _reject(PendingAdmin admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter cette demande ?'),
        content: Text('« ${admin.companyName} » ne pourra pas se connecter.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Rejeter')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.post('/super-admin/admins/${admin.id}/reject');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Demande rejetée.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comptes Admins')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _admins.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucune demande pour le moment.')))])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _admins.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final admin = _admins[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(admin.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${admin.name} · ${admin.email}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(label: _statusLabel(admin.statusValidation), color: _statusColor(admin.statusValidation)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Inscrit le ${admin.createdAt}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              if (admin.statusValidation == 'pending') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(onPressed: () => _reject(admin), child: const Text('Rejeter')),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(onPressed: () => _approve(admin), child: const Text('Approuver')),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
