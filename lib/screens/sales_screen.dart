import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import 'sale_create_screen.dart';
import 'sale_detail_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale> _sales = [];
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
      final response = await api.get('/sales');
      final sales = (response['sales']['data'] as List<dynamic>)
          .map((json) => Sale.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _sales = sales);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const SaleCreateScreen()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.point_of_sale),
        label: const Text('Nouvelle vente'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sales.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucune vente pour le moment.')))])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _sales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(sale.saleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${sale.shop} · ${sale.customer}\n${sale.itemsCount} article(s) · ${sale.soldAt ?? ''}'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${sale.total.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '+${sale.margin.toStringAsFixed(2)} €',
                                style: TextStyle(color: sale.margin >= 0 ? AppTheme.success : AppTheme.danger, fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id)),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
