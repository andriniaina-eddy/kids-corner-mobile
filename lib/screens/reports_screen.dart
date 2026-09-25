import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _topProducts = [];
  List<dynamic> _shopsValuation = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/reports');
      setState(() {
        _summary = response['summary'] as Map<String, dynamic>;
        _topProducts = response['topProducts'] as List<dynamic>;
        _shopsValuation = response['shopsValuation'] as List<dynamic>;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _money(dynamic value) => '${(value as num).toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapports')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('30 derniers jours', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 10),
                  StatCard(
                    label: "Chiffre d'affaires",
                    value: _money(_summary['revenue'] ?? 0),
                    color: AppTheme.primary,
                    icon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 10),
                  StatCard(
                    label: 'Marge brute (${_summary['margin_rate'] ?? 0}%)',
                    value: _money(_summary['margin'] ?? 0),
                    color: AppTheme.success,
                    icon: Icons.trending_up_rounded,
                  ),
                  const SizedBox(height: 10),
                  StatCard(
                    label: 'Valeur du stock (CMUP)',
                    value: _money(_summary['stock_value'] ?? 0),
                    color: Colors.blueGrey,
                    icon: Icons.inventory_outlined,
                  ),
                  const SizedBox(height: 10),
                  StatCard(
                    label: 'Rotation des stocks',
                    value: '${_summary['stock_rotation'] ?? 0}×',
                    color: AppTheme.warning,
                    icon: Icons.autorenew_rounded,
                  ),
                  const SizedBox(height: 24),
                  Text('Top produits', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: _topProducts.isEmpty
                          ? [const Padding(padding: EdgeInsets.all(16), child: Text('Aucune vente sur cette période.'))]
                          : _topProducts
                              .map((item) => ListTile(
                                    title: Text(item['product'] as String),
                                    subtitle: Text('${item['quantity']} unité(s)'),
                                    trailing: Text(_money(item['revenue']), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Valorisation par boutique', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: _shopsValuation.isEmpty
                          ? [const Padding(padding: EdgeInsets.all(16), child: Text('Aucune boutique.'))]
                          : _shopsValuation
                              .map((row) => ListTile(
                                    title: Text(row['shop'] as String),
                                    subtitle: Text('${row['stock_units']} unité(s)'),
                                    trailing: Text(_money(row['stock_value']), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
