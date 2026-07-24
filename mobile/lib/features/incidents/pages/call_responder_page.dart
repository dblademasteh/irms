import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../features/contacts/cubit/contacts_cubit.dart';

class CallResponderPage extends StatefulWidget {
  const CallResponderPage({super.key});

  @override
  State<CallResponderPage> createState() => _CallResponderPageState();
}

class _CallResponderPageState extends State<CallResponderPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ContactsCubit>().loadContacts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: IrmsAppBar(
        title: 'Call',
        showBack: false,
      ),
      body: Column(
        children: [
          _buildEmergencyBanner(theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Search contacts or enter number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Expanded(
            child: BlocBuilder<ContactsCubit, ContactsState>(
              builder: (context, state) {
                if (state is ContactsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ContactsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Failed to load contacts', style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => context.read<ContactsCubit>().loadContacts(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ContactsLoaded) {
                  final contacts = state.contacts;
                  final categories = state.categories;
                  if (_searchQuery.isNotEmpty) {
                    return _buildSearchResults(contacts, categories, theme);
                  }
                  return _buildContactList(contacts, categories, theme);
                }
                return const Center(child: Text('No contacts available'));
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterContacts(List<Map<String, dynamic>> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    final q = _searchQuery.toLowerCase();
    return contacts.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString();
      final dept = (c['department'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(_searchQuery) || dept.contains(q);
    }).toList();
  }

  Widget _buildEmergencyBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _call('911'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emergency, size: 32, color: Colors.white),
            const SizedBox(width: 12),
            Column(
              children: [
                const Text(
                  'EMERGENCY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap to call 911',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> contacts, List<Map<String, dynamic>> categories, ThemeData theme) {
    final filtered = _filterContacts(contacts);
    if (filtered.isEmpty) {
      return _buildDirectCallCard(theme);
    }
    return _buildGroupedList(filtered, categories, theme);
  }

  Widget _buildDirectCallCard(ThemeData theme) {
    final number = _searchCtrl.text.trim();
    if (number.isEmpty || !RegExp(r'^[\d+\-\s]+$').hasMatch(number)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No contacts found', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        color: theme.colorScheme.primary,
        child: InkWell(
          onTap: () => _call(number),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Call this number?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                   child: Icon(Icons.call, color: IrmsColors.success, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactList(List<Map<String, dynamic>> contacts, List<Map<String, dynamic>> categories, ThemeData theme) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No emergency contacts available', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return _buildGroupedList(contacts, categories, theme);
  }

  Widget _buildGroupedList(List<Map<String, dynamic>> contacts, List<Map<String, dynamic>> categories, ThemeData theme) {
    final catMap = {for (final c in categories) c['id'] as String: c};

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final c in contacts) {
      final catId = c['category_id'] as String? ?? 'unknown';
      grouped.putIfAbsent(catId, () => []).add(c);
    }

    final catIds = grouped.keys.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        for (final catId in catIds) ...[
          Builder(builder: (context) {
            final cat = catMap[catId];
            final catName = cat?['name'] ?? 'Other';
            final catColor = cat != null ? Color(int.parse((cat['color'] ?? '#6B7280').replaceFirst('#', '0xFF'))) : Colors.grey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: catColor),
                  const SizedBox(width: 6),
                  Text(
                    catName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: catColor,
                    ),
                  ),
                ],
              ),
            );
          }),
          ...grouped[catId]!.map((c) => _ContactCard(contact: c, categories: categories)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final List<Map<String, dynamic>> categories;
  const _ContactCard({required this.contact, required this.categories});

  static const _iconMap = <String, IconData>{
    'local_police': Icons.local_police,
    'local_fire_department': Icons.local_fire_department,
    'medical_services': Icons.medical_services,
    'storm': Icons.storm,
    'electrical_services': Icons.electrical_services,
    'emergency': Icons.emergency,
    'phone': Icons.phone,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catId = contact['category_id'] as String?;

    String catName = 'Unknown';
    Color catColor = theme.colorScheme.primary;
    IconData catIcon = Icons.phone;

    if (catId != null) {
      for (final c in categories) {
        if (c['id'] == catId) {
          catName = c['name'] ?? 'Unknown';
          catColor = Color(int.parse((c['color'] ?? '#6B7280').replaceFirst('#', '0xFF')));
          catIcon = _iconMap[c['icon']] ?? Icons.phone;
          break;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _call(contact['phone'] ?? ''),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      contact['department'] ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      contact['phone'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
