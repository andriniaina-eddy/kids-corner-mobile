import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier> _suppliers = [];
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
      final response = await api.get('/suppliers');
      final suppliers = (response['suppliers'] as List<dynamic>)
          .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _suppliers = suppliers);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openForm({Supplier? supplier}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _SupplierFormSheet(supplier: supplier),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce fournisseur ?'),
        content: Text('« ${supplier.name} » sera archivé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.delete('/suppliers/${supplier.id}');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Fournisseur supprimé.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseurs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _suppliers.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun fournisseur.')))])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _suppliers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final supplier = _suppliers[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${supplier.contactName ?? '—'}\n${supplier.email ?? supplier.phone ?? ''} · ${supplier.purchaseOrdersCount} commande(s)',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _openForm(supplier: supplier);
                              if (value == 'delete') _delete(supplier);
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

class _SupplierFormSheet extends StatefulWidget {
  final Supplier? supplier;
  const _SupplierFormSheet({this.supplier});

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.supplier?.name ?? '');
  late final TextEditingController _contactName = TextEditingController(text: widget.supplier?.contactName ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.supplier?.email ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.supplier?.phone ?? '');

  bool _isSubmitting = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _contactName.dispose();
    _email.dispose();
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
      'contact_name': _contactName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
    };

    try {
      final api = context.read<ApiService>();
      if (widget.supplier == null) {
        await api.post('/suppliers', payload);
      } else {
        await api.put('/suppliers/${widget.supplier!.id}', payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, widget.supplier == null ? 'Fournisseur créé.' : 'Fournisseur mis à jour.');
    } on ApiException catch (e) {
      setState(() => _errors = {'name': e.errorFor('name') ?? '', 'email': e.errorFor('email') ?? ''}..removeWhere((k, v) => v.isEmpty));
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
            Text(widget.supplier == null ? 'Nouveau fournisseur' : 'Modifier le fournisseur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: InputDecoration(labelText: 'Nom', errorText: _errors['name'])),
            const SizedBox(height: 12),
            TextField(controller: _contactName, decoration: const InputDecoration(labelText: 'Contact (optionnel)')),
            const SizedBox(height: 12),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', errorText: _errors['email'])),
            const SizedBox(height: 12),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone')),
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
