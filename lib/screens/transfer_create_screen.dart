import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';

class _TransferItemForm {
  int? productId;
  final TextEditingController quantityController = TextEditingController(text: '1');
}

class TransferCreateScreen extends StatefulWidget {
  const TransferCreateScreen({super.key});

  @override
  State<TransferCreateScreen> createState() => _TransferCreateScreenState();
}

class _TransferCreateScreenState extends State<TransferCreateScreen> {
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  List<Shop> _sourceShops = [];
  List<Shop> _targetShops = [];
  List<Product> _products = [];

  int? _sourceShopId;
  int? _targetShopId;
  final _noteController = TextEditingController();
  final List<_TransferItemForm> _items = [_TransferItemForm()];

  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final item in _items) {
      item.quantityController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/transfers/create-data');
      setState(() {
        _sourceShops = (response['sourceShops'] as List<dynamic>)
            .map((json) => Shop.fromJson(json as Map<String, dynamic>))
            .toList();
        _targetShops = (response['targetShops'] as List<dynamic>)
            .map((json) => Shop.fromJson(json as Map<String, dynamic>))
            .toList();
        _products = (response['products'] as List<dynamic>)
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  List<Shop> get _availableTargetShops =>
      _targetShops.where((shop) => shop.id != _sourceShopId).toList();

  void _addItem() {
    setState(() => _items.add(_TransferItemForm()));
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    setState(() {
      _items[index].quantityController.dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    setState(() => _errors = {});

    if (_sourceShopId == null || _targetShopId == null) {
      setState(() => _errors['shops'] = 'Sélectionnez une boutique source et une boutique cible.');
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final item in _items) {
      final quantity = int.tryParse(item.quantityController.text) ?? 0;
      if (item.productId == null || quantity <= 0) {
        setState(() => _errors['items'] = 'Renseignez un produit et une quantité valide pour chaque ligne.');
        return;
      }
      items.add({'product_id': item.productId, 'quantity': quantity});
    }

    setState(() => _isSubmitting = true);

    try {
      final api = context.read<ApiService>();
      await api.post('/transfers', {
        'shop_source_id': _sourceShopId,
        'shop_target_id': _targetShopId,
        if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
        'items': items,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, 'Transfert créé avec succès.');
    } on ApiException catch (e) {
      setState(() {
        _errors = {
          'shops': e.errorFor('shop_source_id') ?? e.errorFor('shop_target_id') ?? '',
          'items': e.errorFor('items') ?? '',
        }..removeWhere((key, value) => value.isEmpty);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau transfert')),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_errors['general'] != null) ...[
                  _ErrorBanner(message: _errors['general']!),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<int>(
                  value: _sourceShopId,
                  decoration: const InputDecoration(labelText: 'Boutique source'),
                  items: _sourceShops
                      .map((shop) => DropdownMenuItem(value: shop.id, child: Text('${shop.name} (${shop.code})')))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _sourceShopId = value;
                    if (_targetShopId == value) _targetShopId = null;
                  }),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _targetShopId,
                  decoration: const InputDecoration(labelText: 'Boutique cible'),
                  items: _availableTargetShops
                      .map((shop) => DropdownMenuItem(value: shop.id, child: Text('${shop.name} (${shop.code})')))
                      .toList(),
                  onChanged: _sourceShopId == null ? null : (value) => setState(() => _targetShopId = value),
                ),
                if (_errors['shops'] != null) ...[
                  const SizedBox(height: 6),
                  Text(_errors['shops']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Produits à transférer', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              value: item.productId,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Produit'),
                              items: _products
                                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (value) => setState(() => item.productId = value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: item.quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Qté'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _items.length > 1 ? () => _removeItem(index) : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_errors['items'] != null) ...[
                  Text(_errors['items']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note (optionnel)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Créer le transfert'),
                ),
              ],
            ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }
}
