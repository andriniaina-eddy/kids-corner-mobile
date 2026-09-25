import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';

class _CartLine {
  final int productId;
  final String productName;
  int? variantId;
  String? variantName;
  int quantity;
  double unitPrice;
  final List<Map<String, dynamic>> variants;

  _CartLine({
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    this.quantity = 1,
    required this.unitPrice,
    this.variants = const [],
  });
}

class SaleCreateScreen extends StatefulWidget {
  const SaleCreateScreen({super.key});

  @override
  State<SaleCreateScreen> createState() => _SaleCreateScreenState();
}

class _SaleCreateScreenState extends State<SaleCreateScreen> {
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _shops = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];

  int? _shopId;
  int? _customerId;
  String _paymentMethod = 'especes';
  final _discountController = TextEditingController(text: '0');
  final List<_CartLine> _cart = [];

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/sales/create-data');
      setState(() {
        _shops = List<Map<String, dynamic>>.from(response['shops'] as List);
        _customers = List<Map<String, dynamic>>.from(response['customers'] as List);
        _products = List<Map<String, dynamic>>.from(response['products'] as List);
        if (_shops.length == 1) _shopId = _shops.first['id'] as int;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _openAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _ProductPickerSheet(
        products: _products,
        onSelected: (product, variant) {
          setState(() {
            final variants = List<Map<String, dynamic>>.from(product['variants'] as List? ?? []);
            _cart.add(_CartLine(
              productId: product['id'] as int,
              productName: product['name'] as String,
              variantId: variant?['id'] as int?,
              variantName: variant?['name'] as String?,
              unitPrice: double.tryParse('${variant?['sale_price'] ?? product['sale_price']}') ?? 0,
              variants: variants,
            ));
          });
        },
      ),
    );
  }

  void _removeLine(int index) => setState(() => _cart.removeAt(index));

  double get _subtotal => _cart.fold(0, (sum, line) => sum + line.unitPrice * line.quantity);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  Future<void> _submit() async {
    if (_shopId == null) {
      setState(() => _errorMessage = 'Sélectionnez une boutique.');
      return;
    }
    if (_cart.isEmpty) {
      setState(() => _errorMessage = 'Le panier est vide.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final api = context.read<ApiService>();
      final response = await api.post('/sales', {
        'shop_id': _shopId,
        if (_customerId != null) 'customer_id': _customerId,
        'payment_method': _paymentMethod,
        'discount': _discount,
        'items': _cart
            .map((line) => {
                  'product_id': line.productId,
                  if (line.variantId != null) 'variant_id': line.variantId,
                  'quantity': line.quantity,
                  'unit_price': line.unitPrice,
                })
            .toList(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, 'Vente ${response['sale_number']} enregistrée.');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.errorFor('items') ?? e.errorFor('shop_id') ?? e.message);
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
      appBar: AppBar(title: const Text('Nouvelle vente')),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      DropdownButtonFormField<int>(
                        value: _shopId,
                        decoration: const InputDecoration(labelText: 'Boutique'),
                        items: _shops.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['name'] as String))).toList(),
                        onChanged: (value) => setState(() => _shopId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _customerId,
                        decoration: const InputDecoration(labelText: 'Client (optionnel)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Client de passage')),
                          ..._customers.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name'] as String))),
                        ],
                        onChanged: (value) => setState(() => _customerId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(labelText: 'Paiement'),
                        items: const [
                          DropdownMenuItem(value: 'especes', child: Text('Espèces')),
                          DropdownMenuItem(value: 'carte', child: Text('Carte bancaire')),
                          DropdownMenuItem(value: 'virement', child: Text('Virement')),
                          DropdownMenuItem(value: 'autre', child: Text('Autre')),
                        ],
                        onChanged: (value) => setState(() => _paymentMethod = value ?? 'especes'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Panier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          OutlinedButton.icon(
                            onPressed: _openAddProductSheet,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajouter un produit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._cart.asMap().entries.map((entry) {
                        final index = entry.key;
                        final line = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(line.variantName != null ? '${line.productName} — ${line.variantName}' : line.productName),
                            subtitle: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    initialValue: '${line.quantity}',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, labelText: 'Qté'),
                                    onChanged: (value) => setState(() => line.quantity = int.tryParse(value) ?? 1),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue: '${line.unitPrice}',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(isDense: true, labelText: 'Prix'),
                                    onChanged: (value) => setState(() => line.unitPrice = double.tryParse(value) ?? 0),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${(line.unitPrice * line.quantity).toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _removeLine(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (_cart.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Panier vide.', style: TextStyle(color: Colors.grey.shade400))),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Remise globale (€)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${_total.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Enregistrer la vente'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProductPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final void Function(Map<String, dynamic> product, Map<String, dynamic>? variant) onSelected;

  const _ProductPickerSheet({required this.products, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = products[index];
            final variants = List<Map<String, dynamic>>.from(product['variants'] as List? ?? []);

            if (variants.isEmpty) {
              return ListTile(
                title: Text(product['name'] as String),
                subtitle: Text('${product['sale_price']} €'),
                onTap: () {
                  onSelected(product, null);
                  Navigator.pop(context);
                },
              );
            }

            return ExpansionTile(
              title: Text(product['name'] as String),
              children: variants
                  .map((variant) => ListTile(
                        title: Text(variant['name'] as String),
                        subtitle: Text('${variant['sale_price'] ?? product['sale_price']} €'),
                        onTap: () {
                          onSelected(product, variant);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }
}
