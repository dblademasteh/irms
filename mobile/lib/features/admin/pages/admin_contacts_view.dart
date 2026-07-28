import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/app_toast.dart';
import '../cubit/admin_cubit.dart';
import '../repo/admin_repo.dart';

class AdminContactsView extends StatefulWidget {
  final List<dynamic> contacts;
  final List<dynamic> categories;
  const AdminContactsView({super.key, required this.contacts, required this.categories});

  @override
  State<AdminContactsView> createState() => _AdminContactsViewState();
}

class _AdminContactsViewState extends State<AdminContactsView> {
  String? _selectedCategoryId;

  List<dynamic> get _filteredContacts {
    if (_selectedCategoryId == null) return widget.contacts;
    return widget.contacts.where((c) => c['category_id'] == _selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Filter by Category',
                    prefixIcon: const Icon(Icons.filter_list, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    ...categories.map<DropdownMenuItem<String>>((c) {
                      final cat = c as Map<String, dynamic>;
                      final color = Color(int.parse((cat['color'] ?? '#6B7280').replaceFirst('#', '0xFF')));
                      return DropdownMenuItem<String>(
                        value: cat['id'] as String,
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: color),
                            const SizedBox(width: 8),
                            Text(cat['name'] ?? ''),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _showCategorySheet(context),
                icon: const Icon(Icons.settings, size: 20),
                tooltip: 'Manage Categories',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _importContacts(context),
                icon: const Icon(Icons.upload_file, size: 20),
                tooltip: 'Import CSV/JSON',
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredContacts.isEmpty
              ? const Center(child: Text('No emergency contacts found.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _filteredContacts.length,
                  itemBuilder: (ctx, i) {
                    final contact = _filteredContacts[i] as Map<String, dynamic>;
                    return _ContactCard(contact: contact, categories: widget.categories);
                  },
                ),
        ),
      ],
    );
  }

  void _importContacts(BuildContext context) async {
    AppToast.info(context, 'CSV/JSON Import is ready for admin panel');
  }

  void _showCategorySheet(BuildContext context, {Map<String, dynamic>? category}) {
    final isEdit = category != null;
    final nameCtrl = TextEditingController(text: category?['name'] ?? '');
    final colorCtrl = TextEditingController(text: category?['color'] ?? '#6B7280');
    final orderCtrl = TextEditingController(text: (category?['sort_order'] ?? 0).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom,
          left: 24, right: 24, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            Text(isEdit ? 'Edit Category' : 'Add Category', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              autocorrect: false, enableSuggestions: false,
              autofillHints: const <String>[],
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Police Station',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: colorCtrl,
              autocorrect: false, enableSuggestions: false,
              autofillHints: const <String>[],
              decoration: InputDecoration(
                labelText: 'Color (hex)',
                hintText: '#2563EB',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: orderCtrl,
              autocorrect: false, enableSuggestions: false,
              autofillHints: const <String>[],
              decoration: InputDecoration(
                labelText: 'Sort Order',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (isEdit)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<AdminCubit>().deleteCategory(category['id']);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                if (isEdit) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        final order = int.tryParse(orderCtrl.text.trim()) ?? 0;
                        if (isEdit) {
                          context.read<AdminCubit>().updateCategory(category['id'], nameCtrl.text.trim(), 'phone', colorCtrl.text.trim(), order);
                        } else {
                          context.read<AdminCubit>().addCategory(nameCtrl.text.trim(), 'phone', colorCtrl.text.trim(), order);
                        }
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Category'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${category['name']}"? Contacts using it will lose their category.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              context.read<AdminCubit>().deleteCategory(category['id']).then((_) {
                AppToast.successOn(messenger, 'Category deleted successfully');
              }).catchError((err) {
                AppToast.errorOn(messenger, 'Failed to delete category: $err');
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final List<dynamic> categories;
  const _ContactCard({required this.contact, required this.categories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String categoryName = 'Unknown';
    final catId = contact['category_id'];
    if (catId != null) {
      for (final c in categories) {
        if ((c as Map<String, dynamic>)['id'] == catId) {
          categoryName = c['name'] ?? 'Unknown';
          break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child: Icon(Icons.business, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact['phone'] ?? 'No phone',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoryName.toUpperCase(),
                          style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              onPressed: () => _showContactSheet(context, contact: contact, categories: categories),
            ),
          ],
        ),
      ),
    );
  }
}

void _showContactSheet(BuildContext context, {Map<String, dynamic>? contact, List<dynamic> categories = const []}) {
  final isEdit = contact != null;
  final nameCtrl = TextEditingController(text: contact?['name'] ?? '');
  final phoneCtrl = TextEditingController(text: contact?['phone'] ?? '');
  final deptCtrl = TextEditingController(text: contact?['department'] ?? '');
  String? selectedCategoryId = contact?['category_id'];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (bottomSheetCtx) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom,
          left: 24, right: 24, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            Text(isEdit ? 'Edit Contact' : 'Add Emergency Contact', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              autocorrect: false, enableSuggestions: false,
              autofillHints: const <String>[],
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              autocorrect: false, enableSuggestions: false,
              autofillHints: const <String>[],
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deptCtrl,
              autocorrect: false, enableSuggestions: false,
              autofillHints: const <String>[],
              decoration: InputDecoration(
                labelText: 'Department (e.g. Police, Fire, Medical)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
              items: categories.map<DropdownMenuItem<String>>((c) {
                final cat = c as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: cat['id'] as String,
                  child: Text(cat['name'] ?? ''),
                );
              }).toList(),
              onChanged: (v) => setModalState(() => selectedCategoryId = v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (isEdit)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<AdminCubit>().deleteContact(contact['id']);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                if (isEdit) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty &&
                          phoneCtrl.text.trim().isNotEmpty &&
                          deptCtrl.text.trim().isNotEmpty &&
                          selectedCategoryId != null) {
                        if (isEdit) {
                          context.read<AdminCubit>().updateContact(contact['id'], nameCtrl.text.trim(), phoneCtrl.text.trim(), deptCtrl.text.trim(), selectedCategoryId!);
                        } else {
                          context.read<AdminCubit>().addContact(nameCtrl.text.trim(), phoneCtrl.text.trim(), deptCtrl.text.trim(), selectedCategoryId!);
                        }
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Contact'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

void showAddContactSheet(BuildContext context, {List<dynamic> categories = const []}) {
  _showContactSheet(context, categories: categories);
}
