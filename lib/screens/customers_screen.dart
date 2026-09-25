import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
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
      final response = await api.get('/customers');
      final customers = (response['customers'] as List<dynamic>)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _customers = customers);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openForm({Customer? customer}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _CustomerFormSheet(customer: customer),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce client ?'),
        content: Text('« ${customer.name} » sera archivé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.delete('/customers/${customer.id}');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Client supprimé.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _customers.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun client.')))])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${customer.email ?? customer.phone ?? '—'} · ${customer.salesCount} vente(s)'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _openForm(customer: customer);
                              if (value == 'delete') _delete(customer);
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

class _CustomerFormSheet extends StatefulWidget {
  final Customer? customer;
  const _CustomerFormSheet({this.customer});

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.customer?.name ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.customer?.email ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.customer?.phone ?? '');

  bool _isSubmitting = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errors = {};
    });

    final payload = {'name': _name.text.trim(), 'email': _email.text.trim(), 'phone': _phone.text.trim()};

    try {
      final api = context.read<ApiService>();
      if (widget.customer == null) {
        await api.post('/customers', payload);
      } else {
        await api.put('/customers/${widget.customer!.id}', payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, widget.customer == null ? 'Client créé.' : 'Client mis à jour.');
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.customer == null ? 'Nouveau client' : 'Modifier le client', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: InputDecoration(labelText: 'Nom', errorText: _errors['name'])),
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
    );
  }
}
