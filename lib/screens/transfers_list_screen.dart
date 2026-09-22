import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transfer.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import '../widgets/status_badge.dart';
import 'transfer_create_screen.dart';

class TransfersListScreen extends StatefulWidget {
  const TransfersListScreen({super.key});

  @override
  State<TransfersListScreen> createState() => _TransfersListScreenState();
}

class _TransfersListScreenState extends State<TransfersListScreen> {
  List<Transfer> _transfers = [];
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
      final response = await api.get('/transfers');
      final list = (response['transfers']['data'] as List<dynamic>)
          .map((json) => Transfer.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _transfers = list);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validate(Transfer transfer) async {
    final confirmed = await _confirm(
      'Valider ce transfert ?',
      'Le stock sera déduit de ${transfer.shopSource} et ajouté à ${transfer.shopTarget}.',
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.post('/transfers/${transfer.id}/validate');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Transfert validé, stocks mis à jour.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _cancel(Transfer transfer) async {
    final confirmed = await _confirm('Annuler ce transfert ?', 'Cette action est définitive.');
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.post('/transfers/${transfer.id}/cancel');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Transfert annulé.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Complété';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const TransferCreateScreen()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _transfers.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Aucun transfert pour le moment.')),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _transfers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final transfer = _transfers[index];
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
                                    child: Row(
                                      children: [
                                        Flexible(child: Text(transfer.shopSource, overflow: TextOverflow.ellipsis)),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6),
                                          child: Icon(Icons.arrow_forward, size: 16),
                                        ),
                                        Flexible(child: Text(transfer.shopTarget, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(
                                    label: _statusLabel(transfer.status),
                                    color: _statusColor(transfer.status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                transfer.items.map((i) => '${i.product} (${i.quantity})').join(', '),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Par ${transfer.createdBy} · ${transfer.createdAt}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                              if (transfer.isPending) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _cancel(transfer),
                                        child: const Text('Annuler'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () => _validate(transfer),
                                        child: const Text('Valider'),
                                      ),
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
