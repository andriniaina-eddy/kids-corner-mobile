import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> with SingleTickerProviderStateMixin {
  List<TrashedShop> _shops = [];
  List<TrashedProduct> _products = [];
  bool _isLoading = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/trash');
      setState(() {
        _shops = (response['shops'] as List<dynamic>)
            .map((json) => TrashedShop.fromJson(json as Map<String, dynamic>))
            .toList();
        _products = (response['products'] as List<dynamic>)
            .map((json) => TrashedProduct.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreShop(TrashedShop shop) async {
    try {
      final api = context.read<ApiService>();
      await api.post('/trash/shops/${shop.id}/restore');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Boutique restaurée.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _purgeShop(TrashedShop shop) async {
    final confirmed = await _confirmPurge(
      'Supprimer définitivement « ${shop.name} » ?',
      "Cette action est IRRÉVERSIBLE et effacera aussi tout son historique : inventaire, mouvements de stock, "
          "inventaires mensuels, et tout transfert impliquant cette boutique.",
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.delete('/trash/shops/${shop.id}');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Boutique supprimée définitivement.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _restoreProduct(TrashedProduct product) async {
    try {
      final api = context.read<ApiService>();
      await api.post('/trash/products/${product.id}/restore');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Produit restauré.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _purgeProduct(TrashedProduct product) async {
    final confirmed = await _confirmPurge(
      'Supprimer définitivement « ${product.name} » ?',
      'Cette action est IRRÉVERSIBLE et effacera aussi tout son historique : stock dans toutes les boutiques, '
          'mouvements, et ses lignes dans tout transfert passé.',
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.delete('/trash/products/${product.id}');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Produit supprimé définitivement.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  Future<bool?> _confirmPurge(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corbeille'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Boutiques (${_shops.length})'),
            Tab(text: 'Produits (${_products.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _shops.isEmpty
                      ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucune boutique archivée.')))])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _shops.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final shop = _shops[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${shop.code} · supprimée le ${shop.deletedAt}\n${shop.inventoriesCount} référence(s)'),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'restore') _restoreShop(shop);
                                    if (value == 'purge') _purgeShop(shop);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'restore', child: Text('Restaurer')),
                                    PopupMenuItem(value: 'purge', child: Text('Supprimer définitivement')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  _products.isEmpty
                      ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun produit archivé.')))])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${product.sku ?? 'Sans SKU'} · supprimé le ${product.deletedAt}'),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'restore') _restoreProduct(product);
                                    if (value == 'purge') _purgeProduct(product);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'restore', child: Text('Restaurer')),
                                    PopupMenuItem(value: 'purge', child: Text('Supprimer définitivement')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
