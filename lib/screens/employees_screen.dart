import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../models/shop.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/error_helper.dart';
import '../utils/theme.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Employee> _employees = [];
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
      final response = await api.get('/employees');
      setState(() {
        _employees = (response['employees'] as List<dynamic>)
            .map((json) => Employee.fromJson(json as Map<String, dynamic>))
            .toList();
        _shops = (response['shops'] as List<dynamic>)
            .map((json) => Shop.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openForm({Employee? employee}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _EmployeeFormSheet(employee: employee, shops: _shops),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet employé ?'),
        content: Text('« ${employee.name} » perdra définitivement l\'accès à l\'application.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.delete('/employees/${employee.id}');
      if (!mounted) return;
      showSuccessSnackBar(context, 'Employé supprimé.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employés')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel employé'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _employees.isEmpty
                ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun employé.')))])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(employee.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') _openForm(employee: employee);
                                      if (value == 'delete') _delete(employee);
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                      PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                children: employee.shops
                                    .map((shop) => Chip(
                                          label: Text(shop.name, style: const TextStyle(fontSize: 12)),
                                          visualDensity: VisualDensity.compact,
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 10),
                              _ActiveToggle(employee: employee, onChanged: _load),
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

class _ActiveToggle extends StatefulWidget {
  final Employee employee;
  final VoidCallback onChanged;

  const _ActiveToggle({required this.employee, required this.onChanged});

  @override
  State<_ActiveToggle> createState() => _ActiveToggleState();
}

class _ActiveToggleState extends State<_ActiveToggle> {
  bool _isToggling = false;

  Future<void> _toggle() async {
    setState(() => _isToggling = true);
    try {
      final api = context.read<ApiService>();
      await api.patch('/employees/${widget.employee.id}/toggle-active');
      widget.onChanged();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isToggling ? null : _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: widget.employee.isActive ? AppTheme.success.withOpacity(0.12) : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.employee.isActive ? 'Actif' : 'Inactif',
          style: TextStyle(
            color: widget.employee.isActive ? AppTheme.success : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmployeeFormSheet extends StatefulWidget {
  final Employee? employee;
  final List<Shop> shops;

  const _EmployeeFormSheet({this.employee, required this.shops});

  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.employee?.name ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.employee?.email ?? '');
  final TextEditingController _password = TextEditingController();
  late Set<int> _selectedShopIds = widget.employee?.shops.map((s) => s.id).toSet() ?? {};

  bool _isSubmitting = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errors = {};
    });

    if (_selectedShopIds.isEmpty) {
      setState(() {
        _errors['shop_ids'] = 'Sélectionnez au moins une boutique.';
        _isSubmitting = false;
      });
      return;
    }

    final payload = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      if (_password.text.isNotEmpty || widget.employee == null) 'password': _password.text,
      'shop_ids': _selectedShopIds.toList(),
    };

    try {
      final api = context.read<ApiService>();
      if (widget.employee == null) {
        await api.post('/employees', payload);
      } else {
        await api.put('/employees/${widget.employee!.id}', payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, widget.employee == null ? 'Employé créé.' : 'Employé mis à jour.');
    } on ApiException catch (e) {
      setState(() {
        _errors = {
          'name': e.errorFor('name') ?? '',
          'email': e.errorFor('email') ?? '',
          'password': e.errorFor('password') ?? '',
          'shop_ids': e.errorFor('shop_ids') ?? '',
        }..removeWhere((k, v) => v.isEmpty);
        if (_errors.isEmpty) _errors['general'] = e.message;
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
              widget.employee == null ? 'Nouvel employé' : "Modifier l'employé",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_errors['general'] != null) ...[
              const SizedBox(height: 10),
              Text(_errors['general']!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: InputDecoration(labelText: 'Nom', errorText: _errors['name'])),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Email', errorText: _errors['email']),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.employee == null ? 'Mot de passe' : 'Nouveau mot de passe (optionnel)',
                errorText: _errors['password'],
              ),
            ),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('Boutiques assignées', style: TextStyle(color: Colors.grey.shade700))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.shops.map((shop) {
                final selected = _selectedShopIds.contains(shop.id);
                return FilterChip(
                  label: Text(shop.name),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    value ? _selectedShopIds.add(shop.id) : _selectedShopIds.remove(shop.id);
                  }),
                );
              }).toList(),
            ),
            if (_errors['shop_ids'] != null) ...[
              const SizedBox(height: 6),
              Text(_errors['shop_ids']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
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
