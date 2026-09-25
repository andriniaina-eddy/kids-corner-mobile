import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';

class _OrderLine {
  int? productId;
  final TextEditingController quantity = TextEditingController(text: '1');
  final TextEditingController unitCost = TextEditingController(text: '0');
}

class PurchaseOrderCreateScreen extends StatefulWidget {
  const PurchaseOrderCreateScreen({super.key});

  @override
  State<PurchaseOrderCreateScreen> createState() => _PurchaseOrderCreateScreenState();
}

class _PurchaseOrderCreateScreenState extends State<PurchaseOrderCreateScreen> {
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _shops = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _products = [];

  int? _shopId;
  int? _supplierId;
  final _notesController = TextEditingController();
  final List<_OrderLine> _lines = [_OrderLine()];

  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final line in _lines) {
      line.quantity.dispose();
      line.unitCost.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/purchase-orders/create-data');
      setState(() {
        _shops = List<Map<String, dynamic>>.from(response['shops'] as List);
        _suppliers = List<Map<String, dynamic>>.from(response['suppliers'] as List);
        _products = List<Map<String, dynamic>>.from(response['products'] as List);
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _onProductChange(_OrderLine line) {
    final product = _products.firstWhere((p) => p['id'] == line.productId, orElse: () => {});
    if (product.isNotEmpty) {
      line.unitCost.text = '${product['purchase_price'] ?? 0}';
    }
  }

  void _addLine() => setState(() => _lines.add(_OrderLine()));

  void _removeLine(int index) {
    if (_lines.length == 1) return;
    setState(() {
      _lines[index].quantity.dispose();
      _lines[index].unitCost.dispose();
      _lines.removeAt(index);
    });
  }

  Future<void> _submit() async {
    setState(() => _errors = {});

    if (_shopId == null || _supplierId == null) {
      setState(() => _errors['general'] = 'Sélectionnez une boutique et un fournisseur.');
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final line in _lines) {
      final qty = int.tryParse(line.quantity.text) ?? 0;
      final cost = double.tryParse(line.unitCost.text) ?? 0;
      if (line.productId == null || qty <= 0) {
        setState(() => _errors['items'] = 'Renseignez un produit et une quantité valide pour chaque ligne.');
        return;
      }
      items.add({'product_id': line.productId, 'quantity_ordered': qty, 'unit_cost': cost});
    }

    setState(() => _isSubmitting = true);

    try {
      final api = context.read<ApiService>();
      await api.post('/purchase-orders', {
        'shop_id': _shopId,
        'supplier_id': _supplierId,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'items': items,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, 'Bon de commande créé.');
    } on ApiException catch (e) {
      setState(() => _errors['general'] = e.message);
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
      appBar: AppBar(title: const Text('Nouveau bon de commande')),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_errors['general'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(_errors['general']!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<int>(
                  value: _shopId,
                  decoration: const InputDecoration(labelText: 'Boutique de destination'),
                  items: _shops.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['name'] as String))).toList(),
                  onChanged: (value) => setState(() => _shopId = value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _supplierId,
                  decoration: const InputDecoration(labelText: 'Fournisseur'),
                  items: _suppliers.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['name'] as String))).toList(),
                  onChanged: (value) => setState(() => _supplierId = value),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Produits commandés', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(onPressed: _addLine, icon: const Icon(Icons.add, size: 18), label: const Text('Ajouter')),
                  ],
                ),
                ..._lines.asMap().entries.map((entry) {
                  final index = entry.key;
                  final line = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            value: line.productId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Produit'),
                            items: _products
                                .map((p) => DropdownMenuItem(value: p['id'] as int, child: Text(p['name'] as String, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (value) => setState(() {
                              line.productId = value;
                              _onProductChange(line);
                            }),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: line.quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantité'))),
                              const SizedBox(width: 10),
                              Expanded(child: TextField(controller: line.unitCost, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Coût unitaire'))),
                              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeLine(index)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_errors['items'] != null) Text(_errors['items']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 14),
                TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optionnel)'), maxLines: 2),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Créer le bon de commande'),
                ),
              ],
            ),
    );
  }
}
