import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
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
  int? _expandedProductId;

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

  Future<void> _pickAndUploadImage(Product product) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    try {
      final api = context.read<ApiService>();
      await api.postMultipart('/products/${product.id}/image', picked.path);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Photo mise à jour.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  void _toggleVariants(Product product) {
    setState(() => _expandedProductId = _expandedProductId == product.id ? null : product.id);
  }

  Future<void> _openAddVariantSheet(Product product) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _VariantFormSheet(product: product, shops: _shops),
    );
    if (added == true) _load();
  }

  Future<void> _deleteVariant(ProductVariant variant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette variante ?'),
        content: Text('« ${variant.name} » sera supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.delete('/variants/${variant.id}');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Variante supprimée.');
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
                      final isExpanded = _expandedProductId == product.id;

                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: GestureDetector(
                                onTap: () => _pickAndUploadImage(product),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: product.imageUrl != null
                                        ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                        : Container(
                                            color: Colors.grey.shade100,
                                            child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                                          ),
                                  ),
                                ),
                              ),
                              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${product.sku ?? 'Sans SKU'} · Achat ${product.purchasePrice.toStringAsFixed(2)} € · Vente ${product.salePrice.toStringAsFixed(2)} €'
                                '${product.tracksBatches ? ' · Lots suivis' : ''}',
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
                            InkWell(
                              onTap: () => _toggleVariants(product),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Text('Variantes (${product.variants.length})', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    const Spacer(),
                                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade600, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded)
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ...product.variants.map((variant) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              Expanded(child: Text(variant.name)),
                                              Text('${variant.totalStock ?? 0} en stock', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18),
                                                onPressed: () => _deleteVariant(variant),
                                              ),
                                            ],
                                          ),
                                        )),
                                    OutlinedButton.icon(
                                      onPressed: () => _openAddVariantSheet(product),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Ajouter une variante'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
  late bool _tracksBatches = widget.product?.tracksBatches ?? false;

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
      'tracks_batches': _tracksBatches,
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
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _tracksBatches,
              onChanged: (value) => setState(() => _tracksBatches = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Suivre les lots et péremptions', style: TextStyle(fontSize: 14)),
            ),
            if (_isCreating) ...[
              const SizedBox(height: 12),
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

class _VariantFormSheet extends StatefulWidget {
  final Product product;
  final List<Shop> shops;

  const _VariantFormSheet({required this.product, required this.shops});

  @override
  State<_VariantFormSheet> createState() => _VariantFormSheetState();
}

class _VariantFormSheetState extends State<_VariantFormSheet> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _salePrice = TextEditingController();
  final List<_InitialStockRow> _stockRows = [];

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
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

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      'sale_price': _salePrice.text.trim().isEmpty ? null : double.tryParse(_salePrice.text),
      if (_stockRows.isNotEmpty)
        'initial_stocks': _stockRows
            .where((row) => row.shopId != null)
            .map((row) => {
                  'shop_id': row.shopId,
                  'quantity': int.tryParse(row.quantity.text) ?? 0,
                  'alert_threshold': int.tryParse(row.threshold.text) ?? 5,
                })
            .toList(),
    };

    try {
      final api = context.read<ApiService>();
      await api.post('/products/${widget.product.id}/variants', payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, 'Variante créée.');
    } on ApiException catch (e) {
      setState(() => _error = e.errorFor('name') ?? e.message);
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
            Text('Nouvelle variante — ${widget.product.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: InputDecoration(labelText: 'Nom (ex: "M / Blanc")', errorText: _error)),
            const SizedBox(height: 12),
            TextField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU (optionnel)')),
            const SizedBox(height: 12),
            TextField(
              controller: _salePrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Prix de vente (optionnel, sinon celui du produit)'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stock initial (optionnel)', style: TextStyle(color: Colors.grey.shade700)),
                TextButton.icon(onPressed: _addStockRow, icon: const Icon(Icons.add, size: 18), label: const Text('Boutique')),
              ],
            ),
            ..._stockRows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          value: row.shopId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Boutique'),
                          items: widget.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: (value) => setState(() => row.shopId = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: row.quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qté'))),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Créer la variante'),
            ),
          ],
        ),
      ),
    );
  }
}
