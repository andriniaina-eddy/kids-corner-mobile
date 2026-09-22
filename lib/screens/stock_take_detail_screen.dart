import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stock_take.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';

class StockTakeDetailScreen extends StatefulWidget {
  final int stockTakeId;
  const StockTakeDetailScreen({super.key, required this.stockTakeId});

  @override
  State<StockTakeDetailScreen> createState() => _StockTakeDetailScreenState();
}

class _StockTakeDetailScreenState extends State<StockTakeDetailScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _shopName = '';
  String _periodLabel = '';
  String _status = 'draft';
  bool _canComplete = false;
  List<StockTakeItem> _items = [];
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/stock-takes/${widget.stockTakeId}');
      final stockTake = response['stockTake'] as Map<String, dynamic>;
      final items = (response['items'] as List<dynamic>)
          .map((json) => StockTakeItem.fromJson(json as Map<String, dynamic>))
          .toList();

      for (final item in items) {
        _controllers[item.id] = TextEditingController(
          text: '${item.countedQuantity ?? item.systemQuantity}',
        );
      }

      setState(() {
        _shopName = (stockTake['shop'] as Map<String, dynamic>)['name'] as String;
        _periodLabel = stockTake['period_label'] as String;
        _status = stockTake['status'] as String;
        _canComplete = response['canComplete'] as bool? ?? false;
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _differenceFor(StockTakeItem item) {
    final text = _controllers[item.id]?.text;
    final counted = int.tryParse(text ?? '');
    if (counted == null) return null;
    return counted - item.systemQuantity;
  }

  Future<void> _complete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clôturer l'inventaire ?"),
        content: const Text('Les écarts constatés seront appliqués immédiatement aux stocks. Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final api = context.read<ApiService>();
      final counts = _items.map((item) {
        final counted = int.tryParse(_controllers[item.id]?.text ?? '') ?? item.systemQuantity;
        return {'item_id': item.id, 'counted_quantity': counted};
      }).toList();

      await api.post('/stock-takes/${widget.stockTakeId}/complete', {'counts': counts});
      if (!mounted) return;
      showSuccessSnackBar(context, 'Inventaire clôturé, stocks ajustés.');
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
    final isCompleted = _status == 'completed';

    return Scaffold(
      appBar: AppBar(title: Text(_shopName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_periodLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Chip(label: Text(isCompleted ? 'Clôturé' : 'En cours')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final difference = _differenceFor(item);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('Système : ${item.systemQuantity} ${item.unit}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _controllers[item.id],
                                enabled: !isCompleted,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                difference == null || difference == 0 ? '' : (difference > 0 ? '+$difference' : '$difference'),
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: difference == null || difference == 0
                                      ? Colors.grey
                                      : (difference > 0 ? Colors.green : Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_canComplete && !isCompleted)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _complete,
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Clôturer l'inventaire"),
                    ),
                  ),
              ],
            ),
    );
  }
}
