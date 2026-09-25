import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';

class SaleDetailScreen extends StatefulWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _sale;
  bool _canCancel = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/sales/${widget.saleId}');
      setState(() {
        _sale = response['sale'] as Map<String, dynamic>;
        _canCancel = response['canCancel'] as bool? ?? false;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cette vente ?'),
        content: const Text('Le stock vendu sera restitué.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Annuler la vente')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.post('/sales/${widget.saleId}/cancel');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Vente annulée, stock restitué.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = _sale;

    return Scaffold(
      appBar: AppBar(title: Text(sale?['sale_number'] as String? ?? '')),
      body: _isLoading || sale == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${sale['shop']} · ${sale['customer'] ?? 'Client de passage'}', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List<Map<String, dynamic>>.from(sale['items'] as List).map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${item['product_name']} × ${item['quantity']}')),
                                  Text('${item['line_total']} €', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )),
                        const Divider(height: 24),
                        _summaryRow('Sous-total', '${sale['subtotal']} €'),
                        _summaryRow('Remise', '-${sale['discount']} €'),
                        _summaryRow('Total', '${sale['total']} €', bold: true),
                        _summaryRow('Marge', '${(sale['margin'] as num).toStringAsFixed(2)} €', color: AppTheme.success),
                      ],
                    ),
                  ),
                ),
                if (_canCancel) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger)),
                    child: const Text('Annuler la vente'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
