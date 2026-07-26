import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../../../core/dio_client.dart';
import '../cubit/admin_cubit.dart';
import 'admin_contacts_view.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: IrmsAppBar(
        title: 'Command Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminCubit>().loadData(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 600;
          return isWide ? _buildWideLayout(theme) : _buildNarrowLayout(theme);
        },
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget? _buildFab(BuildContext context) {
    final state = context.read<AdminCubit>().state;
    final categories = state is AdminLoaded ? state.categories : <dynamic>[];

    switch (_selectedIndex) {
      case 2:
        return FloatingActionButton.extended(
          onPressed: () => showAddContactSheet(context, categories: categories),
          icon: const Icon(Icons.add),
          label: const Text('Add Contact'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () => _showCreateCodeSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Create Code'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () => _showAddBarangaySheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Barangay'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        );
      case 5:
        return FloatingActionButton.extended(
          heroTag: 'incidents_fab',
          onPressed: () => _showBroadcastSheet(context),
          icon: const Icon(Icons.campaign),
          label: const Text('Broadcast'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        );
      case 6:
        return FloatingActionButton.extended(
          heroTag: 'units_fab',
          onPressed: () => _showAddUnitSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Unit'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        );
      default:
        return null;
    }
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          labelType: NavigationRailLabelType.all,
          backgroundColor: theme.colorScheme.surface,
          leading: const SizedBox(height: 8),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Analytics')),
            NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
            NavigationRailDestination(icon: Icon(Icons.contact_phone_outlined), selectedIcon: Icon(Icons.contact_phone), label: Text('Contacts')),
            NavigationRailDestination(icon: Icon(Icons.vpn_key_outlined), selectedIcon: Icon(Icons.vpn_key), label: Text('Codes')),
            NavigationRailDestination(icon: Icon(Icons.location_city_outlined), selectedIcon: Icon(Icons.location_city), label: Text('Barangays')),
            NavigationRailDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning_amber), label: Text('Incidents')),
            NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Units')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildContent(theme)),
      ],
    );
  }

  Widget _buildNarrowLayout(ThemeData theme) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _CompactTab(label: 'Analytics', icon: Icons.bar_chart, isSelected: _selectedIndex == 0, onTap: () => setState(() => _selectedIndex = 0)),
              _CompactTab(label: 'Users', icon: Icons.people_outline, isSelected: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
              _CompactTab(label: 'Contacts', icon: Icons.contact_phone, isSelected: _selectedIndex == 2, onTap: () => setState(() => _selectedIndex = 2)),
              _CompactTab(label: 'Codes', icon: Icons.vpn_key, isSelected: _selectedIndex == 3, onTap: () => setState(() => _selectedIndex = 3)),
              _CompactTab(label: 'Barangays', icon: Icons.location_city, isSelected: _selectedIndex == 4, onTap: () => setState(() => _selectedIndex = 4)),
              _CompactTab(label: 'Incidents', icon: Icons.warning_amber, isSelected: _selectedIndex == 5, onTap: () => setState(() => _selectedIndex = 5)),
              _CompactTab(label: 'Units', icon: Icons.local_shipping, isSelected: _selectedIndex == 6, onTap: () => setState(() => _selectedIndex = 6)),
            ],
          ),
        ),
        Expanded(child: _buildContent(theme)),
      ],
    );
  }

  Widget _CompactTab({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (ctx, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<dynamic> users = [];
        Map<String, dynamic> analytics = {};
        List<dynamic> contacts = [];
        List<dynamic> categories = [];
        List<dynamic> inviteCodes = [];
        List<dynamic> barangays = [];
        List<dynamic> incidents = [];
        List<dynamic> units = [];
        String? error;

        if (state is AdminLoaded) {
          users = state.users;
          analytics = state.analytics;
          contacts = state.contacts;
          categories = state.categories;
          inviteCodes = state.inviteCodes;
          barangays = state.barangays;
          incidents = state.incidents;
          units = state.units;
        } else if (state is AdminError) {
          error = state.message;
          users = state.previousUsers ?? [];
          analytics = state.previousAnalytics ?? {};
          contacts = state.previousContacts ?? [];
          categories = state.previousCategories ?? [];
          inviteCodes = state.previousInviteCodes ?? [];
          barangays = state.previousBarangays ?? [];
          incidents = state.previousIncidents ?? [];
          units = state.previousUnits ?? [];
        }

        if (error != null && users.isEmpty && analytics.isEmpty && contacts.isEmpty) {
          return _buildError(theme, error);
        }

        switch (_selectedIndex) {
          case 0:
            if (analytics.isEmpty) return const Center(child: Text('No analytics data.'));
            return _AnalyticsView(analytics: analytics, onExport: () => _showExportSheet(context));
          case 1:
            if (users.isEmpty) return const Center(child: Text('No users found.'));
            return _UsersView(users: users, incidents: incidents);
          case 2:
            return AdminContactsView(contacts: contacts, categories: categories);
          case 3:
            return _InviteCodesView(codes: inviteCodes);
          case 5:
            return _IncidentsAdminView(incidents: incidents);
          case 6:
            return _UnitsView(units: units);
          default:
            return _BarangaysView(barangays: barangays);
        }
      },
    );
  }

  void _showBroadcastSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetCtx) => _BroadcastSheetBody(ctrl: ctrl),
    );
  }

  Widget _buildError(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Error loading data', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<AdminCubit>().loadData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCreateCodeSheet(BuildContext context) {
    String selectedRole = 'dispatcher';
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                    borderRadius: BorderRadius.circular(2.5)
                  ),
                ),
              ),
              Text('Generate Invite Code', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('This code will let a new user register with the selected role.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'dispatcher', label: Text('Dispatcher'), icon: Icon(Icons.headset_mic_outlined, size: 18)),
                  ButtonSegment(value: 'admin', label: Text('Admin'), icon: Icon(Icons.admin_panel_settings_outlined, size: 18)),
                ],
                selected: {selectedRole},
                onSelectionChanged: (v) => setSheetState(() => selectedRole = v.first),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  context.read<AdminCubit>().createInviteCode(selectedRole);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.vpn_key),
                label: const Text('Generate Code'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBarangaySheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final psgcCtrl = TextEditingController();
    bool isUrban = false;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                    borderRadius: BorderRadius.circular(2.5)
                  ),
                ),
              ),
              Text('Add Barangay', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Barangay Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: psgcCtrl,
                decoration: InputDecoration(
                  labelText: 'PSGC Code (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Urban Barangay'),
                value: isUrban,
                onChanged: (v) => setSheetState(() => isUrban = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    context.read<AdminCubit>().addBarangay(
                      nameCtrl.text.trim(),
                      psgcCtrl.text.trim().isNotEmpty ? psgcCtrl.text.trim() : null,
                      isUrban,
                    );
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Barangay'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    final cubit = context.read<AdminCubit>();
    String? selectedStatus;
    String? selectedType;

    final statuses = ['submitted', 'under_review', 'verified', 'rejected', 'resolved'];
    final types = ['fire', 'accident', 'crime', 'medical', 'natural_disaster', 'infrastructure'];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                    borderRadius: BorderRadius.circular(2.5)
                  ),
                ),
              ),
              Text('Export Incidents', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Download a CSV file of incidents with optional filters.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(value: null, child: Text('All')),
                  ...statuses.map((s) => DropdownMenuItem<String>(value: s, child: Text(s.toUpperCase()))),
                ],
                onChanged: (v) => setSheetState(() => selectedStatus = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Type (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(value: null, child: Text('All')),
                  ...types.map((t) => DropdownMenuItem<String>(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()))),
                ],
                onChanged: (v) => setSheetState(() => selectedType = v),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final csv = await cubit.exportIncidents(
                    status: selectedStatus,
                    type: selectedType,
                  );
                  if (csv != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Exported ${csv.split('\n').length - 1} incidents. CSV copied to clipboard.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    await Clipboard.setData(ClipboardData(text: csv));
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// ANALYTICS VIEW
// ---------------------------------------------------------

class _AnalyticsView extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final VoidCallback? onExport;

  const _AnalyticsView({required this.analytics, this.onExport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Total Users', value: analytics['totalUsers'].toString(), icon: Icons.people, color: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(title: 'Total Incidents', value: analytics['totalIncidents'].toString(), icon: Icons.report, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 24),
        if (onExport != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download),
              label: const Text('Export Incidents as CSV'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text('Incidents by Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildBreakdown(context, analytics['statusBreakdown'], analytics['totalIncidents']),
        const SizedBox(height: 32),
        Text('Incidents by Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildBreakdown(context, analytics['typeBreakdown'], analytics['totalIncidents'], isType: true),
        const SizedBox(height: 32),
        Text('Incidents by Barangay', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildBarangayBreakdown(context, analytics['barangayBreakdown'] ?? []),
      ],
    );
  }

  Widget _buildBreakdown(BuildContext context, List<dynamic> breakdown, int total, {bool isType = false}) {
    if (breakdown.isEmpty || total == 0) return const Text('No data available');
    final theme = Theme.of(context);
    
    return Column(
      children: breakdown.map((item) {
        final key = isType ? item['type'] : item['status'];
        final count = int.parse(item['count'].toString());
        final percentage = (count / total);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(key.toString().toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 12, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 12, 
                        decoration: BoxDecoration(
                          color: _getColor(key, theme.brightness == Brightness.dark), 
                          borderRadius: BorderRadius.circular(6)
                        )
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 40, child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColor(String key, bool isDark) {
    return IrmsStatusColors.resolve(key, isDark);
  }

  Widget _buildBarangayBreakdown(BuildContext context, List<dynamic> breakdown) {
    if (breakdown.isEmpty) return const Text('No data available');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = breakdown.where((b) => int.parse(b['count'].toString()) > 0).toList();

    if (filtered.isEmpty) return const Text('No incidents recorded yet');

    return Column(
      children: filtered.take(15).map((item) {
        final name = item['name'] ?? 'Unknown';
        final count = int.parse(item['count'].toString());
        final maxCount = filtered.fold<int>(0, (max, b) {
          final c = int.parse(b['count'].toString());
          return c > max ? c : max;
        });
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 10, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(5))),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: isDark ? IrmsColors.successDark : IrmsColors.success,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 30, child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------
// USERS VIEW (REDESIGNED FOR ADMIN)
// ---------------------------------------------------------

class _UsersView extends StatefulWidget {
  final List<dynamic> users;
  final List<dynamic> incidents;
  const _UsersView({required this.users, this.incidents = const []});

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _roleFilter = 'all'; // 'all', 'admin', 'dispatcher', 'reporter'
  final Set<String> _suspendedUsers = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get _filtered {
    return widget.users.where((u) {
      if (u == null) return false;
      final role = u['role']?.toString().toLowerCase() ?? 'reporter';
      if (_roleFilter != 'all' && role != _roleFilter) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final name = u['name']?.toString().toLowerCase() ?? '';
      final email = u['email']?.toString().toLowerCase() ?? '';
      final phone = u['phone']?.toString().toLowerCase() ?? '';
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  Map<String, int> get _roleCounts {
    int total = widget.users.length;
    int admin = 0;
    int dispatcher = 0;
    int reporter = 0;

    for (final u in widget.users) {
      if (u == null) continue;
      final r = u['role']?.toString().toLowerCase() ?? 'reporter';
      if (r == 'admin') admin++;
      else if (r == 'dispatcher') dispatcher++;
      else reporter++;
    }

    return {'total': total, 'admin': admin, 'dispatcher': dispatcher, 'reporter': reporter};
  }

  Map<String, List<dynamic>> get _grouped {
    final grouped = <String, List<dynamic>>{};
    for (final user in _filtered) {
      if (user == null) continue;
      final role = user['role']?.toString() ?? 'reporter';
      grouped.putIfAbsent(role, () => []).add(user);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final counts = _roleCounts;
    final grouped = _grouped;

    return Column(
      children: [
        // Role Statistics Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _UserStatCard(
                label: 'Total Users',
                count: counts['total'] ?? 0,
                icon: Icons.people_alt,
                color: theme.colorScheme.primary,
                isSelected: _roleFilter == 'all',
                onTap: () => setState(() => _roleFilter = 'all'),
              ),
              const SizedBox(width: 10),
              _UserStatCard(
                label: 'Admins',
                count: counts['admin'] ?? 0,
                icon: Icons.admin_panel_settings,
                color: isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
                isSelected: _roleFilter == 'admin',
                onTap: () => setState(() => _roleFilter = 'admin'),
              ),
              const SizedBox(width: 10),
              _UserStatCard(
                label: 'Dispatchers',
                count: counts['dispatcher'] ?? 0,
                icon: Icons.headset_mic,
                color: isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
                isSelected: _roleFilter == 'dispatcher',
                onTap: () => setState(() => _roleFilter = 'dispatcher'),
              ),
              const SizedBox(width: 10),
              _UserStatCard(
                label: 'Reporters',
                count: counts['reporter'] ?? 0,
                icon: Icons.person,
                color: isDark ? IrmsColors.primaryDark : IrmsColors.primary,
                isSelected: _roleFilter == 'reporter',
                onTap: () => setState(() => _roleFilter = 'reporter'),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
        ),

        // Empty State or List
        if (_filtered.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search_outlined, size: 56, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      _query.isNotEmpty ? 'No users match "$_query"' : 'No users found for this role filter',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                for (final role in ['admin', 'dispatcher', 'reporter'])
                  if (grouped.containsKey(role))
                    _RoleGroup(
                      role: role,
                      users: grouped[role]!,
                      incidents: widget.incidents,
                      query: _query,
                      suspendedUserIds: _suspendedUsers,
                      onToggleSuspend: (userId) {
                        setState(() {
                          if (_suspendedUsers.contains(userId)) {
                            _suspendedUsers.remove(userId);
                          } else {
                            _suspendedUsers.add(userId);
                          }
                        });
                      },
                      onRoleChange: (userId, newRole) {
                        context.read<AdminCubit>().updateUserRole(userId, newRole);
                      },
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UserStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isSelected ? color : theme.colorScheme.onSurface),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleGroup extends StatefulWidget {
  final String role;
  final List<dynamic> users;
  final List<dynamic> incidents;
  final String query;
  final Set<String> suspendedUserIds;
  final void Function(String userId) onToggleSuspend;
  final void Function(String userId, String newRole) onRoleChange;

  const _RoleGroup({
    required this.role,
    required this.users,
    required this.incidents,
    required this.query,
    required this.suspendedUserIds,
    required this.onToggleSuspend,
    required this.onRoleChange,
  });

  @override
  State<_RoleGroup> createState() => _RoleGroupState();
}

class _RoleGroupState extends State<_RoleGroup> {
  bool _expanded = true;

  String get _roleLabel => switch (widget.role) {
        'admin' => 'Admins',
        'dispatcher' => 'Dispatchers',
        'reporter' => 'Reporters',
        _ => widget.role,
      };

  IconData get _roleIcon => switch (widget.role) {
        'admin' => Icons.admin_panel_settings_outlined,
        'dispatcher' => Icons.headset_mic_outlined,
        'reporter' => Icons.person_outline,
        _ => Icons.person,
      };

  Color _roleColor(bool isDark) => switch (widget.role) {
        'admin' => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
        'dispatcher' => isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
        'reporter' => isDark ? IrmsColors.primaryDark : IrmsColors.primary,
        _ => isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _roleColor(isDark);

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_roleIcon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  _roleLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.users.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, color: color, size: 22),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(
            children: widget.users.map((user) => _UserCard(
              user: user,
              incidents: widget.incidents,
              isSuspended: widget.suspendedUserIds.contains(user['id']?.toString()),
              onToggleSuspend: () => widget.onToggleSuspend(user['id']?.toString() ?? ''),
              onRoleChange: widget.onRoleChange,
            )).toList(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<dynamic> incidents;
  final bool isSuspended;
  final VoidCallback onToggleSuspend;
  final void Function(String userId, String newRole) onRoleChange;

  const _UserCard({
    required this.user,
    required this.incidents,
    required this.isSuspended,
    required this.onToggleSuspend,
    required this.onRoleChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final userId = user['id']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'reporter';
    final roleColor = _roleColor(role, isDark);
    final email = user['email']?.toString() ?? 'No email registered';
    final phone = user['phone']?.toString();

    // User's incident history count
    final userIncidents = incidents.where((i) => i != null && i['reporter_id']?.toString() == userId).toList();
    final incidentCount = userIncidents.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSuspended ? theme.colorScheme.errorContainer.withValues(alpha: 0.1) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSuspended 
            ? theme.colorScheme.error.withValues(alpha: 0.4) 
            : theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with status indicator
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isSuspended
                            ? [Colors.grey, Colors.blueGrey]
                            : [roleColor.withValues(alpha: 0.6), roleColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (() {
                            final name = user['name']?.toString() ?? '';
                            return name.isNotEmpty ? name[0].toUpperCase() : '?';
                          })(),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isSuspended ? IrmsColors.success : IrmsColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['name'] ?? 'Unknown User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                decoration: isSuspended ? TextDecoration.lineThrough : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              role.toString().toUpperCase(),
                              style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '📞 $phone',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.colorScheme.primary),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  onPressed: () => _showUserAdminMenu(context, isDark, incidentCount, userIncidents),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            
            // User Meta & Quick Actions Row
            Row(
              children: [
                // Incident Count Badge
                GestureDetector(
                  onTap: () => _showUserAuditSheet(context, userIncidents),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '$incidentCount Reports',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Quick Call/SMS Button
                if (phone != null && phone.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.phone, size: 18),
                    tooltip: 'Call User',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Phone number $phone copied to clipboard')),
                      );
                    },
                  ),
                ],
                // Quick Email Copy Button
                IconButton(
                  icon: const Icon(Icons.email_outlined, size: 18),
                  tooltip: 'Email User',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: email));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email $email copied to clipboard')),
                    );
                  },
                ),
                // Change Role Quick Action
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                  tooltip: 'Change Role',
                  onPressed: () => _showRoleSheet(context, isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserAdminMenu(BuildContext context, bool isDark, int incidentCount, List<dynamic> userIncidents) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), 
                    borderRadius: BorderRadius.circular(2.5)
                  ),
                ),
              ),
              Text(
                'Admin Options: ${user['name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              
              // 1. Change Role
              ListTile(
                leading: const Icon(Icons.manage_accounts, color: Colors.blue),
                title: const Text('Change Privilege Role', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Current role: ${(user['role'] ?? 'reporter').toUpperCase()}'),
                onTap: () {
                  Navigator.pop(context);
                  _showRoleSheet(context, isDark);
                },
              ),
              
              // 2. Incident Audit History
              ListTile(
                leading: const Icon(Icons.history_edu, color: Colors.orange),
                title: const Text('User Incident Audit History', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('$incidentCount total incidents submitted'),
                onTap: () {
                  Navigator.pop(context);
                  _showUserAuditSheet(context, userIncidents);
                },
              ),

              // 3. Password Reset
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.purple),
                title: const Text('Reset Security Credentials', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Set new password directly for user account'),
                onTap: () {
                  Navigator.pop(context);
                  _showAdminResetPasswordDialog(context);
                },
              ),

              // 4. Suspend / Re-activate Account
              ListTile(
                leading: Icon(
                  isSuspended ? Icons.check_circle_outline : Icons.block,
                  color: isSuspended ? Colors.green : Colors.red,
                ),
                title: Text(
                  isSuspended ? 'Re-activate Account' : 'Suspend User Account',
                  style: TextStyle(fontWeight: FontWeight.w700, color: isSuspended ? Colors.green : Colors.red),
                ),
                subtitle: Text(isSuspended ? 'Restore app access for user' : 'Restrict user from submitting reports'),
                onTap: () {
                  Navigator.pop(context);
                  onToggleSuspend();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSuspended ? 'User ${user['name']} account re-activated.' : 'User ${user['name']} account suspended.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminResetPasswordDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    final userId = user['id']?.toString() ?? '';
    final userName = user['name']?.toString() ?? 'User';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.purple),
            const SizedBox(width: 10),
            Expanded(child: Text('Reset Password: $userName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter a new password for $userName (minimum 8 characters):', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = passCtrl.text;
              if (newPass.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters.')),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              try {
                await context.read<AdminCubit>().resetUserPassword(userId, newPass);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password successfully reset for $userName'),
                       backgroundColor: IrmsColors.success,
                    ),
                  );
                }
              } catch (err) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reset error: $err'),
                       backgroundColor: IrmsColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save New Password'),
          ),
        ],
      ),
    );
  }

  void _showUserAuditSheet(BuildContext context, List<dynamic> userIncidents) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), 
                  borderRadius: BorderRadius.circular(2.5)
                ),
              ),
            ),
            Text(
              'Incident History: ${user['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Total reports filed by this user (${userIncidents.length})',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (userIncidents.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('This user has not submitted any reports yet.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: userIncidents.length,
                  itemBuilder: (ctx, idx) {
                    final item = userIncidents[idx];
                    final title = item['title'] ?? 'Incident Report';
                    final type = item['type'] ?? 'general';
                    final status = item['status'] ?? 'submitted';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.report, color: Theme.of(context).colorScheme.primary, size: 20),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Type: ${type.toString().toUpperCase()}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: IrmsColors.infoBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: IrmsColors.info),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRoleSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), 
                  borderRadius: BorderRadius.circular(2.5)
                ),
              ),
              const Text('Change User Role', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Update privileges for ${user['name']}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 24),
              _RoleTile(
                label: 'Reporter', 
                description: 'Can only submit and view their own reports.',
                icon: Icons.person_outline, 
                color: isDark ? IrmsColors.primaryDark : IrmsColors.primary, 
                onTap: () { Navigator.pop(context); onRoleChange(user['id'], 'reporter'); }
              ),
              const SizedBox(height: 12),
              _RoleTile(
                label: 'Dispatcher', 
                description: 'Can view and manage all incoming reports.',
                icon: Icons.headset_mic_outlined, 
                color: isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light, 
                onTap: () { Navigator.pop(context); onRoleChange(user['id'], 'dispatcher'); }
              ),
              const SizedBox(height: 12),
              _RoleTile(
                label: 'Admin', 
                description: 'Full system access, can manage users.',
                icon: Icons.admin_panel_settings_outlined, 
                color: isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light, 
                onTap: () { Navigator.pop(context); onRoleChange(user['id'], 'admin'); }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _roleColor(String r, bool isDark) {
    return switch (r) {
      'admin' => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
      'dispatcher' => isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
      'reporter' => isDark ? IrmsColors.primaryDark : IrmsColors.primary,
      _ => isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText,
    };
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleTile({required this.label, required this.description, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// INVITE CODES VIEW
// ---------------------------------------------------------

class _InviteCodesView extends StatelessWidget {
  final List<dynamic> codes;
  const _InviteCodesView({required this.codes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unused = codes.where((c) => c['used_by'] == null).toList();
    final used = codes.where((c) => c['used_by'] != null).toList();

    if (codes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vpn_key_off, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No invite codes yet', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Tap "New Code" to generate one', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (unused.isNotEmpty) ...[
          Text('Available (${unused.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final code in unused)
            _CodeCard(code: code, isDark: isDark),
        ],
        if (used.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Used (${used.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 12),
          for (final code in used)
            _CodeCard(code: code, isDark: isDark, isUsed: true),
        ],
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  final Map<String, dynamic> code;
  final bool isDark;
  final bool isUsed;

  const _CodeCard({required this.code, required this.isDark, this.isUsed = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = code['role'] ?? 'dispatcher';
    final roleColor = role == 'admin'
        ? (isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light)
        : (isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light);
    final usedByName = code['used_by_name'];
    final usedAt = code['used_at'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                if (isUsed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: theme.colorScheme.error),
                        const SizedBox(width: 4),
                        Text(
                          'USED',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: IrmsColors.successBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: IrmsColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: IrmsColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (!isUsed)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code['code'] ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: ${code['code']}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                if (!isUsed)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                    onPressed: () => _confirmDelete(context),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              code['code'] ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: isUsed ? theme.colorScheme.onSurface.withValues(alpha: 0.4) : null,
              ),
            ),
            if (isUsed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    'Used by ${usedByName ?? code['used_by'] ?? 'unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (usedAt != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(usedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete code?'),
        content: Text('This will permanently delete ${code['code']}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              context.read<AdminCubit>().deleteInviteCode(code['id']).then((_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Invite code deleted successfully'), behavior: SnackBarBehavior.floating),
                );
              }).catchError((err) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete invite code: $err'), behavior: SnackBarBehavior.floating),
                );
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

// ---------------------------------------------------------
// INCIDENTS ADMIN VIEW
// ---------------------------------------------------------

class _IncidentsAdminView extends StatelessWidget {
  final List<dynamic> incidents;
  const _IncidentsAdminView({required this.incidents});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No incidents yet', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: incidents.length,
      itemBuilder: (ctx, i) => _IncidentAdminCard(incident: incidents[i], isDark: isDark),
    );
  }
}

class _IncidentAdminCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final bool isDark;
  const _IncidentAdminCard({required this.incident, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = incident['status'] ?? 'submitted';
    final statusColor = _statusColor(status, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident['type'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  if (incident['description'] != null)
                    Text(
                      incident['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toString().toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                      if (incident['barangay_name'] != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_outlined, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 2),
                        Text(
                          incident['barangay_name'],
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Broadcast Incident Alert',
                  icon: Icon(Icons.campaign_outlined, size: 20, color: theme.colorScheme.primary),
                  onPressed: () => _showIncidentBroadcast(context),
                ),
                IconButton(
                  tooltip: 'Send Push Notification',
                  icon: Icon(Icons.notifications_active_outlined, size: 20, color: Colors.orange.shade700),
                  onPressed: () => _showIncidentNotification(context),
                ),
                IconButton(
                  tooltip: 'Delete Incident',
                  icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status, bool isDark) {
    return IrmsStatusColors.resolve(status, isDark);
  }

  void _showIncidentBroadcast(BuildContext context) {
    final typeStr = (incident['type'] ?? 'Incident').toString().toUpperCase();
    final barangayStr = incident['barangay_name'] != null ? ' in ${incident['barangay_name']}' : '';
    final descStr = incident['description'] != null ? ': ${incident['description']}' : '';
    final defaultMsg = '🚨 EMERGENCY BROADCAST [$typeStr]$barangayStr$descStr';
    final ctrl = TextEditingController(text: defaultMsg);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bCtx).viewInsets.bottom,
          left: 24, right: 24, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2.5)),
              ),
            ),
            Row(
              children: [
                Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Broadcast Incident Alert', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Broadcast this emergency alert to all users and emergency dispatchers live across the region.', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLength: 500,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Broadcast Message',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  await context.read<AdminCubit>().sendBroadcast(ctrl.text.trim());
                  if (context.mounted) {
                    Navigator.pop(bCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📢 Emergency broadcast sent successfully!')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Broadcast Alert'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showIncidentNotification(BuildContext context) {
    final typeStr = (incident['type'] ?? 'Incident').toString().toUpperCase();
    final ctrl = TextEditingController(text: 'Dispatchers & Response Teams: Urgent action required for $typeStr report #${incident['id']}.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (nCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(nCtx).viewInsets.bottom,
          left: 24, right: 24, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2.5)),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Send Push Notification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dispatch an instant priority notification for this incident.', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLength: 300,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notification Content',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  await context.read<AdminCubit>().sendBroadcast('[NOTIFICATION] ${ctrl.text.trim()}');
                  if (context.mounted) {
                    Navigator.pop(nCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🔔 Notification dispatched to emergency responders!')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.notifications),
              label: const Text('Dispatch Notification'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete incident?'),
        content: const Text('This will permanently delete this incident and all its media.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              context.read<AdminCubit>().deleteIncident(incident['id'].toString()).then((_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Incident deleted successfully'), behavior: SnackBarBehavior.floating),
                );
              }).catchError((err) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete incident: $err'), behavior: SnackBarBehavior.floating),
                );
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

// ---------------------------------------------------------
// BARANGAYS VIEW
// ---------------------------------------------------------

class _BarangaysView extends StatelessWidget {
  final List<dynamic> barangays;
  const _BarangaysView({required this.barangays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (barangays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No barangays yet', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Tap "Add Barangay" to add one', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      );
    }

    final urban = barangays.where((b) => b['is_urban'] == true).toList();
    final rural = barangays.where((b) => b['is_urban'] != true).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text('Urban (${urban.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final b in urban)
          _BarangayCard(barangay: b, isDark: isDark),
        const SizedBox(height: 24),
        Text('Rural (${rural.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 12),
        for (final b in rural)
          _BarangayCard(barangay: b, isDark: isDark),
      ],
    );
  }
}

class _BarangayCard extends StatelessWidget {
  final Map<String, dynamic> barangay;
  final bool isDark;
  const _BarangayCard({required this.barangay, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = barangay['is_urban'] == true
        ? (isDark ? IrmsColors.primaryDark : IrmsColors.primary)
        : (isDark ? IrmsColors.successDark : IrmsColors.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.location_on_outlined, color: color, size: 20),
        ),
        title: Text(barangay['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: barangay['psgc_code'] != null
            ? Text('PSGC: ${barangay['psgc_code']}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))
            : null,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete barangay?'),
        content: Text('This will permanently delete "${barangay['name']}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              context.read<AdminCubit>().deleteBarangay(barangay['id']).then((_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Barangay deleted successfully'), behavior: SnackBarBehavior.floating),
                );
              }).catchError((err) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete barangay: $err'), behavior: SnackBarBehavior.floating),
                );
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

class _BroadcastSheetBody extends StatefulWidget {
  final TextEditingController ctrl;
  const _BroadcastSheetBody({required this.ctrl});

  @override
  State<_BroadcastSheetBody> createState() => _BroadcastSheetBodyState();
}

class _BroadcastSheetBodyState extends State<_BroadcastSheetBody> {
  bool _sending = false;
  bool _generating = false;
  String? _selectedTemplate;
  String _selectedCategory = 'emergency';
  String _targetRole = 'all';

  static const _templates = [
    {'key': 'general_emergency', 'label': 'General Emergency'},
    {'key': 'weather_advisory', 'label': 'Weather Advisory'},
    {'key': 'fire_alert', 'label': 'Fire Alert'},
    {'key': 'crime_safety', 'label': 'Crime / Safety'},
    {'key': 'medical_alert', 'label': 'Medical Alert'},
    {'key': 'traffic_update', 'label': 'Traffic Update'},
    {'key': 'earthquake_advisory', 'label': 'Earthquake Advisory'},
    {'key': 'flood_warning', 'label': 'Flood Warning'},
    {'key': 'tsunami_warning', 'label': 'Tsunami Warning'},
    {'key': 'incident_summary', 'label': 'Incident Summary'},
    {'key': 'safety_tip', 'label': 'Safety Tip'},
    {'key': 'system_maintenance', 'label': 'System Maintenance'},
  ];

  Future<void> _generate() async {
    if (_selectedTemplate == null) return;
    setState(() => _generating = true);
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.post('/admin/broadcast/generate', data: {
        'template': _selectedTemplate,
      });
      final message = resp.data['message'] as String;
      final category = resp.data['category'] as String;
      setState(() => _selectedCategory = category);
      widget.ctrl.text = message;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const Text('Send Global Broadcast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'This will immediately alert all active users across the platform.',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Quick Generate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedTemplate,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Template',
              hintText: 'Pick a template to auto-generate...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _templates.map((t) => DropdownMenuItem(
              value: t['key'] as String,
              child: Text(t['label'] as String, style: const TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: (v) => setState(() => _selectedTemplate = v),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_selectedTemplate == null || _generating) ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_generating ? 'Generating...' : 'Generate from Template'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: widget.ctrl,
            maxLength: 500,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter emergency alert or system message...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                    DropdownMenuItem(value: 'weather', child: Text('Weather')),
                    DropdownMenuItem(value: 'traffic', child: Text('Traffic')),
                    DropdownMenuItem(value: 'earthquake', child: Text('Earthquake')),
                    DropdownMenuItem(value: 'flood', child: Text('Flood')),
                    DropdownMenuItem(value: 'tsunami', child: Text('Tsunami')),
                    DropdownMenuItem(value: 'system', child: Text('System')),
                    DropdownMenuItem(value: 'safety', child: Text('Safety')),
                  ],
                  onChanged: (v) => setState(() => _selectedCategory = v ?? 'emergency'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _targetRole,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Recipients',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Everyone')),
                    DropdownMenuItem(value: 'reporters', child: Text('Reporters')),
                    DropdownMenuItem(value: 'dispatchers', child: Text('Dispatchers')),
                  ],
                  onChanged: (v) => setState(() => _targetRole = v ?? 'all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _sending
                ? null
                : () async {
                    final msg = widget.ctrl.text.trim();
                    if (msg.isEmpty) return;
                    setState(() => _sending = true);
                    try {
                      await context.read<AdminCubit>().sendBroadcast(
                        msg,
                        category: _selectedCategory,
                        targetRole: _targetRole,
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setState(() => _sending = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to send broadcast: $e'),
                            backgroundColor: theme.colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: Text(_sending ? 'Sending...' : 'Send Alert Now'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

void _showAddUnitSheet(BuildContext context) {
  final nameCtrl = TextEditingController();
  String unitType = 'fire';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (bottomCtx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2.5)),
              ),
            ),
            const Text('Add Dispatch Unit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Unit Name / Call Sign',
                hintText: 'e.g. Fire Engine 1, Ambulance Medic 2',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: unitType,
              decoration: InputDecoration(
                labelText: 'Unit Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'fire', child: Row(children: [Icon(Icons.local_fire_department, color: Colors.orange), SizedBox(width: 8), Text('FIRE')])),
                DropdownMenuItem(value: 'medical', child: Row(children: [Icon(Icons.medical_services, color: Colors.red), SizedBox(width: 8), Text('MEDICAL')])),
                DropdownMenuItem(value: 'police', child: Row(children: [Icon(Icons.local_police, color: Colors.blue), SizedBox(width: 8), Text('POLICE')])),
              ],
              onChanged: (v) => setSheetState(() => unitType = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                context.read<AdminCubit>().addUnit(name, unitType);
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Save Unit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

class _UnitsView extends StatelessWidget {
  final List<dynamic> units;

  const _UnitsView({required this.units});

  Color _typeColor(String? type, ColorScheme scheme, bool isDark) {
    return switch (type) {
      'fire'    => isDark ? IrmsStatusColors.fire.dark : IrmsStatusColors.fire.light,
      'medical' => isDark ? IrmsStatusColors.medical.dark : IrmsStatusColors.medical.light,
      'police'  => isDark ? IrmsColors.primaryDark : IrmsColors.primary,
      _         => scheme.primary,
    };
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'fire': return Icons.local_fire_department;
      case 'medical': return Icons.medical_services;
      case 'police': return Icons.local_police;
      default: return Icons.local_shipping;
    }
  }

  Color _statusColor(String? status, bool isDark) {
    if (status == null) return isDark ? IrmsColors.infoDark : IrmsColors.info;
    return IrmsStatusColors.resolve(status, isDark);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final availableCount = units.where((u) => u['status'] == 'available').length;
    final dispatchedCount = units.where((u) => u['status'] == 'dispatched').length;
    final maintenanceCount = units.where((u) => u['status'] == 'maintenance').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Available',
                value: '$availableCount',
                icon: Icons.check_circle_outline,
                color: isDark ? IrmsColors.successDark : IrmsColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Dispatched',
                value: '$dispatchedCount',
                icon: Icons.local_shipping_outlined,
                color: isDark ? IrmsStatusColors.dispatchedUnit.dark : IrmsStatusColors.dispatchedUnit.light,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Maintenance',
                value: '$maintenanceCount',
                icon: Icons.build_outlined,
                color: isDark ? IrmsColors.warningDark : IrmsColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Registered Units (${units.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (units.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
                  SizedBox(height: 12),
                  Text('No dispatch units set up yet.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
                ],
              ),
            ),
          )
        else
          ...units.map((u) {
            final typeColor = _typeColor(u['unit_type'], theme.colorScheme, isDark);
            final statusColor = _statusColor(u['status'], isDark);
            final unitId = u['id'].toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(u['unit_type']), color: typeColor, size: 24),
                ),
                title: Text(u['name'] ?? 'Unnamed Unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (u['unit_type'] ?? 'unit').toString().toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (u['status'] ?? 'unknown').toString().toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'delete') {
                      showDialog(
                        context: context,
                        builder: (dlgCtx) => AlertDialog(
                          title: const Text('Delete Unit'),
                          content: Text('Are you sure you want to delete "${u['name']}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(dlgCtx);
                                context.read<AdminCubit>().deleteUnit(unitId);
                              },
                              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      context.read<AdminCubit>().updateUnitStatus(unitId, val);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'available', child: Text('Set Available')),
                    const PopupMenuItem(value: 'maintenance', child: Text('Set Maintenance')),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: theme.colorScheme.error))),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
