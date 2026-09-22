import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';

class ShopsManagementScreen extends StatefulWidget {
  const ShopsManagementScreen({super.key});

  @override
  State<ShopsManagementScreen> createState() => _ShopsManagementScreenState();
}

class _ShopsManagementScreenState extends State<ShopsManagementScreen> {
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
      final response = await api.get('/shops');
      final shops = (response['shops'] as List<dynamic>)
          .map((json) => Shop.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _shops = shops);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openForm({Shop? shop}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _ShopFormSheet(shop: shop),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Shop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la boutique ?'),
        content: Text(
          'La boutique « ${shop.name} » sera déplacée dans la Corbeille. '
          'Vous pourrez la restaurer plus tard depuis là-bas.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.delete('/shops/${shop.id}');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Boutique supprimée.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boutiques')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _shops.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucune boutique.')))])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _shops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${shop.code}${shop.city != null ? ' · ${shop.city}' : ''}\n'
                            '${shop.employeesCount ?? 0} employé(s) · ${shop.inventoriesCount ?? 0} référence(s)',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _openForm(shop: shop);
                              if (value == 'delete') _delete(shop);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Modifier')),
                              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
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

class _ShopFormSheet extends StatefulWidget {
  final Shop? shop;
  const _ShopFormSheet({this.shop});

  @override
  State<_ShopFormSheet> createState() => _ShopFormSheetState();
}

class _ShopFormSheetState extends State<_ShopFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.shop?.name ?? '');
  late final TextEditingController _code = TextEditingController(text: widget.shop?.code ?? '');
  late final TextEditingController _address = TextEditingController(text: widget.shop?.address ?? '');
  late final TextEditingController _city = TextEditingController(text: widget.shop?.city ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.shop?.phone ?? '');

  bool _isSubmitting = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errors = {};
    });

    final payload = {
      'name': _name.text.trim(),
      'code': _code.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'phone': _phone.text.trim(),
    };

    try {
      final api = context.read<ApiService>();
      if (widget.shop == null) {
        await api.post('/shops', payload);
      } else {
        await api.put('/shops/${widget.shop!.id}', payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, widget.shop == null ? 'Boutique créée.' : 'Boutique mise à jour.');
    } on ApiException catch (e) {
      setState(() {
        _errors = {
          'name': e.errorFor('name') ?? '',
          'code': e.errorFor('code') ?? '',
        }..removeWhere((k, v) => v.isEmpty);
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
            Text(
              widget.shop == null ? 'Nouvelle boutique' : 'Modifier la boutique',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: InputDecoration(labelText: 'Nom', errorText: _errors['name'])),
            const SizedBox(height: 12),
            TextField(controller: _code, decoration: InputDecoration(labelText: 'Code', errorText: _errors['code'])),
            const SizedBox(height: 12),
            TextField(controller: _address, decoration: const InputDecoration(labelText: 'Adresse (optionnel)')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _city, decoration: const InputDecoration(labelText: 'Ville'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone'))),
              ],
            ),
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
