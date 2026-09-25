import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/purchase_order.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import '../widgets/status_badge.dart';
import 'purchase_order_create_screen.dart';
import 'purchase_order_detail_screen.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  List<PurchaseOrder> _orders = [];
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
      final response = await api.get('/purchase-orders');
      final orders = (response['orders']['data'] as List<dynamic>)
          .map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final _statusColors = {
    'draft': Colors.grey,
    'ordered': AppTheme.warning,
    'partially_received': Colors.blueAccent,
    'received': AppTheme.success,
    'cancelled': AppTheme.danger,
  };

  final _statusLabels = {
    'draft': 'Brouillon',
    'ordered': 'Commandé',
    'partially_received': 'Reçu partiel',
    'received': 'Reçu',
    'cancelled': 'Annulé',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bons de commande')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PurchaseOrderCreateScreen()),
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
            : _orders.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun bon de commande.')))])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(order.referenceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${order.supplier} · ${order.shop}\n${order.totalCost.toStringAsFixed(2)} €'),
                          isThreeLine: true,
                          trailing: StatusBadge(
                            label: _statusLabels[order.status] ?? order.status,
                            color: _statusColors[order.status] ?? Colors.grey,
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PurchaseOrderDetailScreen(orderId: order.id)),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
