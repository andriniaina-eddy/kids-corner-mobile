import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/purchase_order.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const PurchaseOrderDetailScreen({super.key, required this.orderId});

  @override
  State<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _referenceNumber = '';
  String _supplier = '';
  String _shop = '';
  String _status = 'ordered';
  bool _canReceive = false;
  List<PurchaseOrderItem> _items = [];
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _batchControllers = {};
  final Map<int, TextEditingController> _expiryControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [..._quantityControllers.values, ..._batchControllers.values, ..._expiryControllers.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/purchase-orders/${widget.orderId}');
      final order = response['order'] as Map<String, dynamic>;
      final items = (order['items'] as List<dynamic>)
          .map((json) => PurchaseOrderItem.fromJson(json as Map<String, dynamic>))
          .toList();

      for (final item in items) {
        _quantityControllers[item.id] = TextEditingController(text: '${item.remaining}');
        _batchControllers[item.id] = TextEditingController();
        _expiryControllers[item.id] = TextEditingController();
      }

      setState(() {
        _referenceNumber = order['reference_number'] as String;
        _supplier = order['supplier'] as String;
        _shop = order['shop'] as String;
        _status = order['status'] as String;
        _canReceive = response['canReceive'] as bool? ?? false;
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickExpiryDate(int itemId) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      _expiryControllers[itemId]!.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _submitReception() async {
    setState(() => _isSubmitting = true);
    try {
      final api = context.read<ApiService>();
      final receptions = _items.map((item) {
        return {
          'item_id': item.id,
          'quantity_received': int.tryParse(_quantityControllers[item.id]!.text) ?? 0,
          if (_batchControllers[item.id]!.text.isNotEmpty) 'batch_number': _batchControllers[item.id]!.text,
          if (_expiryControllers[item.id]!.text.isNotEmpty) 'expiry_date': _expiryControllers[item.id]!.text,
        };
      }).toList();

      await api.post('/purchase-orders/${widget.orderId}/receive', {'receptions': receptions});
      if (!mounted) return;
      showSuccessSnackBar(context, 'Réception enregistrée, stocks mis à jour.');
      Navigator.of(context).pop();
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
      appBar: AppBar(title: Text(_referenceNumber)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('$_supplier · $_shop', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                ..._items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Commandé : ${item.quantityOrdered} · Reçu : ${item.quantityReceived} · Restant : ${item.remaining}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            if (_canReceive && item.remaining > 0) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _quantityControllers[item.id],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Qté reçue', isDense: true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _batchControllers[item.id],
                                      decoration: const InputDecoration(labelText: 'N° de lot', isDense: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _pickExpiryDate(item.id),
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Péremption (optionnel)', isDense: true),
                                  child: Text(_expiryControllers[item.id]!.text.isEmpty ? 'Non définie' : _expiryControllers[item.id]!.text),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )),
              ],
            ),
      bottomNavigationBar: _canReceive
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReception,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enregistrer la réception'),
              ),
            )
          : null,
    );
  }
}
