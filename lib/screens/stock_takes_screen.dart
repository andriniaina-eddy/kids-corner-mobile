import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../models/stock_take.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';
import '../widgets/status_badge.dart';
import 'stock_take_detail_screen.dart';

class StockTakesScreen extends StatefulWidget {
  const StockTakesScreen({super.key});

  @override
  State<StockTakesScreen> createState() => _StockTakesScreenState();
}

class _StockTakesScreenState extends State<StockTakesScreen> {
  List<StockTake> _stockTakes = [];
  List<Shop> _shops = [];
  String _currentPeriod = '';
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
      final response = await api.get('/stock-takes');
      setState(() {
        _stockTakes = (response['stockTakes']['data'] as List<dynamic>)
            .map((json) => StockTake.fromJson(json as Map<String, dynamic>))
            .toList();
        _shops = (response['shops'] as List<dynamic>)
            .map((json) => Shop.fromJson(json as Map<String, dynamic>))
            .toList();
        _currentPeriod = response['currentPeriod'] as String;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateDialog() async {
    int? shopId;
    String period = _currentPeriod;
    String? error;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nouvel inventaire mensuel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: shopId,
                    decoration: InputDecoration(labelText: 'Boutique', errorText: error),
                    items: _shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (value) => setSheetState(() => shopId = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: period,
                    decoration: const InputDecoration(labelText: 'Période (AAAA-MM)'),
                    onChanged: (value) => period = value,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (shopId == null) {
                        setSheetState(() => error = 'Sélectionnez une boutique.');
                        return;
                      }
                      try {
                        final api = context.read<ApiService>();
                        await api.post('/stock-takes', {'shop_id': shopId, 'period': period});
                        if (context.mounted) Navigator.of(sheetContext).pop(true);
                      } on ApiException catch (e) {
                        setSheetState(() => error = e.errorFor('period') ?? e.message);
                      } catch (e) {
                        if (context.mounted) showErrorSnackBar(context, e);
                      }
                    },
                    child: const Text('Créer'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (created == true) _load();
  }

  Color _statusColor(String status) => status == 'completed' ? AppTheme.success : AppTheme.warning;
  String _statusLabel(String status) => status == 'completed' ? 'Clôturé' : 'En cours';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventaires mensuels')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stockTakes.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun inventaire mensuel.')))])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _stockTakes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final stockTake = _stockTakes[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(stockTake.shop, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(stockTake.periodLabel),
                          trailing: StatusBadge(label: _statusLabel(stockTake.status), color: _statusColor(stockTake.status)),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => StockTakeDetailScreen(stockTakeId: stockTake.id)),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
