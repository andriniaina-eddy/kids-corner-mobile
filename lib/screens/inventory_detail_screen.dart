import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';

class InventoryDetailScreen extends StatefulWidget {
  final int shopId;
  final String shopName;

  const InventoryDetailScreen({super.key, required this.shopId, required this.shopName});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  List<InventoryLine> _lines = [];
  List<InventoryProduct> _availableProducts = [];
  bool _canAddProduct = false;
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
      final response = await api.get('/inventory/shops/${widget.shopId}');
      final lines = (response['inventories'] as List<dynamic>)
          .map((json) => InventoryLine.fromJson(json as Map<String, dynamic>))
          .toList();
      final available = (response['availableProducts'] as List<dynamic>? ?? [])
          .map((json) => InventoryProduct.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _lines = lines;
        _availableProducts = available;
        _canAddProduct = response['canAddProduct'] as bool? ?? false;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAdjustSheet(InventoryLine line) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AdjustStockSheet(inventoryId: line.id, productName: line.product.name),
    );

    if (result == true) {
      _load();
    }
  }

  Future<void> _openAddProductSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _AddProductSheet(shopId: widget.shopId, availableProducts: _availableProducts),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
        actions: [
          if (_canAddProduct)
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              tooltip: 'Ajouter un produit',
              onPressed: _openAddProductSheet,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _lines.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Aucun produit en stock dans cette boutique.')),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(line.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${line.quantity} ${line.product.unit}'
                            '${line.product.sku != null ? ' · ${line.product.sku}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (line.isLow)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Bas', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                                ),
                              IconButton(
                                icon: const Icon(Icons.tune_rounded),
                                onPressed: () => _openAdjustSheet(line),
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

class _AdjustStockSheet extends StatefulWidget {
  final int inventoryId;
  final String productName;

  const _AdjustStockSheet({required this.inventoryId, required this.productName});

  @override
  State<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends State<_AdjustStockSheet> {
  String _type = 'in';
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _quantityError;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      setState(() => _quantityError = 'Quantité invalide.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _quantityError = null;
    });

    try {
      final api = context.read<ApiService>();
      await api.post('/inventory/${widget.inventoryId}/adjust', {
        'type': _type,
        'quantity': quantity,
        if (_reasonController.text.trim().isNotEmpty) 'reason': _reasonController.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, 'Stock ajusté avec succès.');
    } on ApiException catch (e) {
      setState(() => _quantityError = e.errorFor('quantity') ?? e.message);
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Entrée'),
                  selected: _type == 'in',
                  onSelected: (_) => setState(() => _type = 'in'),
                  selectedColor: AppTheme.success.withOpacity(0.15),
                  labelStyle: TextStyle(color: _type == 'in' ? AppTheme.success : Colors.black87),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Sortie'),
                  selected: _type == 'out',
                  onSelected: (_) => setState(() => _type = 'out'),
                  selectedColor: AppTheme.danger.withOpacity(0.15),
                  labelStyle: TextStyle(color: _type == 'out' ? AppTheme.danger : Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Quantité', errorText: _quantityError),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Motif (optionnel)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _type == 'in' ? AppTheme.success : AppTheme.danger,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

class _AddProductSheet extends StatefulWidget {
  final int shopId;
  final List<InventoryProduct> availableProducts;

  const _AddProductSheet({required this.shopId, required this.availableProducts});

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  int? _productId;
  final _quantityController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_productId == null) {
      setState(() => _error = 'Sélectionnez un produit.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      await api.post('/inventory/shops/${widget.shopId}/products', {
        'product_id': _productId,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'alert_threshold': int.tryParse(_thresholdController.text) ?? 5,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, "Produit ajouté à l'inventaire.");
    } on ApiException catch (e) {
      setState(() => _error = e.errorFor('product_id') ?? e.message);
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Ajouter un produit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (widget.availableProducts.isEmpty)
            const Text('Tous les produits du catalogue sont déjà présents dans cette boutique.')
          else ...[
            DropdownButtonFormField<int>(
              value: _productId,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'Produit', errorText: _error),
              items: widget.availableProducts
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (value) => setState(() => _productId = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantité initiale'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _thresholdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Seuil d'alerte"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Ajouter'),
            ),
          ],
        ],
      ),
    );
  }
}
