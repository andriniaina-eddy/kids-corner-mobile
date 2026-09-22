import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import 'inventory_detail_screen.dart';

class InventoryShopsScreen extends StatefulWidget {
  const InventoryShopsScreen({super.key});

  @override
  State<InventoryShopsScreen> createState() => _InventoryShopsScreenState();
}

class _InventoryShopsScreenState extends State<InventoryShopsScreen> {
  List<Shop> _shops = [];
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
      final response = await api.get('/inventory/shops');
      final shops = (response['shops'] as List<dynamic>)
          .map((json) => Shop.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _shops = shops);
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
      appBar: AppBar(title: const Text('Inventaire')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _shops.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Aucune boutique accessible.')),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Text('${shop.productsCount ?? 0} références'),
                                const SizedBox(width: 12),
                                Text('${shop.totalQuantity ?? 0} unités'),
                              ],
                            ),
                          ),
                          trailing: (shop.lowStockCount ?? 0) > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${shop.lowStockCount} bas',
                                    style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                                  ),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => InventoryDetailScreen(shopId: shop.id, shopName: shop.name)),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
