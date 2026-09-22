import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';

class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  State<ProductsManagementScreen> createState() => _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  List<Product> _products = [];
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
      final response = await api.get('/products');
      setState(() {
        _products = (response['products'] as List<dynamic>)
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
        _shops = (response['shops'] as List<dynamic>)
            .map((json) => Shop.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openForm({Product? product}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _ProductFormSheet(product: product, shops: _shops),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text('« ${product.name} » sera déplacé dans la Corbeille, avec son historique conservé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.delete('/products/${product.id}');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Produit supprimé.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue produits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun produit.')))])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${product.sku ?? 'Sans SKU'} · Achat ${product.purchasePrice.toStringAsFixed(2)} € · Vente ${product.salePrice.toStringAsFixed(2)} €',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (product.totalStock > 0 ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${product.totalStock} ${product.unit}',
                                  style: TextStyle(
                                    color: product.totalStock > 0 ? AppTheme.success : AppTheme.danger,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _openForm(product: product);
                                  if (value == 'delete') _delete(product);
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                ],
                              ),
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

class _InitialStockRow {
  int? shopId;
  final TextEditingController quantity = TextEditingController(text: '0');
  final TextEditingController threshold = TextEditingController(text: '5');
}

class _ProductFormSheet extends StatefulWidget {
  final Product? product;
  final List<Shop> shops;

  const _ProductFormSheet({this.product, required this.shops});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _sku = TextEditingController(text: widget.product?.sku ?? '');
  late final TextEditingController _unit = TextEditingController(text: widget.product?.unit ?? 'unite');
  late final TextEditingController _purchasePrice =
      TextEditingController(text: widget.product?.purchasePrice.toString() ?? '0');
  late final TextEditingController _salePrice = TextEditingController(text: widget.product?.salePrice.toString() ?? '0');

  final List<_InitialStockRow> _stockRows = [];
  bool _isSubmitting = false;
  Map<String, String> _errors = {};

  bool get _isCreating => widget.product == null;

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _unit.dispose();
    _purchasePrice.dispose();
    _salePrice.dispose();
    for (final row in _stockRows) {
      row.quantity.dispose();
      row.threshold.dispose();
    }
    super.dispose();
  }

  void _addStockRow() {
    if (_stockRows.length >= widget.shops.length) return;
    setState(() => _stockRows.add(_InitialStockRow()));
  }

  void _removeStockRow(int index) {
    setState(() {
      _stockRows[index].quantity.dispose();
      _stockRows[index].threshold.dispose();
      _stockRows.removeAt(index);
    });
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errors = {};
    });

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      'unit': _unit.text.trim().isEmpty ? 'unite' : _unit.text.trim(),
      'purchase_price': double.tryParse(_purchasePrice.text) ?? 0,
      'sale_price': double.tryParse(_salePrice.text) ?? 0,
    };

    if (_isCreating && _stockRows.isNotEmpty) {
      payload['initial_stocks'] = _stockRows
          .where((row) => row.shopId != null)
          .map((row) => {
                'shop_id': row.shopId,
                'quantity': int.tryParse(row.quantity.text) ?? 0,
                'alert_threshold': int.tryParse(row.threshold.text) ?? 5,
              })
          .toList();
    }

    try {
      final api = context.read<ApiService>();
      if (_isCreating) {
        await api.post('/products', payload);
      } else {
        await api.put('/products/${widget.product!.id}', payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, _isCreating ? 'Produit créé.' : 'Produit mis à jour.');
    } on ApiException catch (e) {
      setState(() {
        _errors = {
          'name': e.errorFor('name') ?? '',
          'sku': e.errorFor('sku') ?? '',
          'purchase_price': e.errorFor('purchase_price') ?? '',
          'sale_price': e.errorFor('sale_price') ?? '',
        }..removeWhere((k, v) => v.isEmpty);
        if (_errors.isEmpty) _errors['general'] = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isCreating ? 'Nouveau produit' : 'Modifier le produit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_errors['general'] != null) ...[
              const SizedBox(height: 10),
              Text(_errors['general']!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: InputDecoration(labelText: 'Nom', errorText: _errors['name'])),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _sku, decoration: InputDecoration(labelText: 'SKU (optionnel)', errorText: _errors['sku'])),
                ),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _unit, decoration: const InputDecoration(labelText: 'Unité'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _purchasePrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: "Prix d'achat", errorText: _errors['purchase_price']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _salePrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Prix de vente', errorText: _errors['sale_price']),
                  ),
                ),
              ],
            ),
            if (_isCreating) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Stock initial (optionnel)', style: TextStyle(color: Colors.grey.shade700)),
                  TextButton.icon(
                    onPressed: _addStockRow,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Boutique'),
                  ),
                ],
              ),
              ..._stockRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          value: row.shopId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Boutique'),
                          items: widget.shops
                              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (value) => setState(() => row.shopId = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: row.quantity,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qté'),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeStockRow(index)),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
