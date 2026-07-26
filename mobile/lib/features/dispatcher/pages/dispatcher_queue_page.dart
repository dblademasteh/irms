import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/dispatcher_cubit.dart';
import '../../../core/app_toast.dart';
import '../../../core/socket_client.dart';
import '../../../core/dio_client.dart';
import '../../../app/theme.dart';
import '../../../app/router.dart';
import 'dart:ui';

class DispatcherQueuePage extends StatefulWidget {
  const DispatcherQueuePage({super.key});

  @override
  State<DispatcherQueuePage> createState() => _DispatcherQueuePageState();
}

class _DispatcherQueuePageState extends State<DispatcherQueuePage> {
  String? _statusFilter;
  String? _typeFilter;
  String? _barangayFilter;
  String _searchQuery = '';
  SocketClient? _socket;
  List<Map<String, dynamic>> _barangays = [];
  final _searchCtrl = TextEditingController();
  bool _showAdvancedFilters = false;
  final Set<String> _selectedIds = {};

  static const _statuses = ['submitted', 'under_review', 'verified', 'rejected', 'resolved'];

  @override
  void initState() {
    super.initState();
    context.read<DispatcherCubit>().loadQueue();
    _socket = context.read<SocketClient>();
    _socket!.joinQueue();
    _socket!.onQueueNewIncident(_handleSocketUpdate);
    _socket!.onQueueUpdate(_handleSocketUpdate);
    _loadBarangays();
    queueFilterNotifier.addListener(_onQueueFilterChanged);
  }

  void _onQueueFilterChanged() {
    if (!mounted) return;
    final newFilter = queueFilterNotifier.value;
    if (_statusFilter != newFilter) {
      setState(() => _statusFilter = newFilter);
      _applyFilters();
    }
  }

  Future<void> _loadBarangays() async {
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/barangays');
      setState(() {
        _barangays = List<Map<String, dynamic>>.from(resp.data['barangays'] ?? resp.data);
      });
    } catch (_) {}
  }

  void _handleSocketUpdate(dynamic data) {
    if (mounted) {
      _applyFilters();
    }
  }

  void _applyFilters() {
    final cubit = context.read<DispatcherCubit>();
    if (_searchQuery.isNotEmpty || _typeFilter != null || _barangayFilter != null) {
      cubit.searchIncidents(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter,
        type: _typeFilter,
        barangayId: _barangayFilter,
      );
    } else {
      cubit.loadQueue(status: _statusFilter);
    }
  }

  @override
  void dispose() {
    _socket?.offQueueNewIncident(_handleSocketUpdate);
    _socket?.offQueueUpdate(_handleSocketUpdate);
    _searchCtrl.dispose();
    queueFilterNotifier.removeListener(_onQueueFilterChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: IrmsAppBar(
        title: _selectedIds.isNotEmpty ? '${_selectedIds.length} Selected' : 'Incident Queue',
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            TextButton(
              onPressed: () async {
                final dio = context.read<DioClient>();
                await dio.dio.post('/incidents/bulk-status', data: {
                  'ids': _selectedIds.toList(),
                  'status': 'verified',
                });
                setState(() => _selectedIds.clear());
                _applyFilters();
              },
              child: const Text('Verify All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                final dio = context.read<DioClient>();
                await dio.dio.post('/incidents/bulk-status', data: {
                  'ids': _selectedIds.toList(),
                  'status': 'resolved',
                });
                setState(() => _selectedIds.clear());
                _applyFilters();
              },
              child: Text('Resolve All', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? IrmsColors.successDark : IrmsColors.success)),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedIds.clear()),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _applyFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search by title, tracking code...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : IconButton(
                        icon: Icon(
                          _showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list,
                          size: 20,
                          color: (_typeFilter != null || _barangayFilter != null)
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        onPressed: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),

          // Advanced filters
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _typeFilter,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Types')),
                        DropdownMenuItem(value: 'fire', child: Text('Fire')),
                        DropdownMenuItem(value: 'accident', child: Text('Accident')),
                        DropdownMenuItem(value: 'crime', child: Text('Crime')),
                        DropdownMenuItem(value: 'medical', child: Text('Medical')),
                        DropdownMenuItem(value: 'natural_disaster', child: Text('Disaster')),
                        DropdownMenuItem(value: 'infrastructure', child: Text('Infra')),
                      ],
                      onChanged: (v) {
                        setState(() => _typeFilter = v);
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _barangayFilter,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Barangay',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Barangays')),
                        ..._barangays.map((b) => DropdownMenuItem(
                          value: b['id'] as String,
                          child: Text(b['name'] as String),
                        )),
                      ],
                      onChanged: (v) {
                        setState(() => _barangayFilter = v);
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _showAdvancedFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),

          // Active filter indicator
          if (_typeFilter != null || _barangayFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_typeFilter != null ? _typeFilter!.replaceAll('_', ' ').toUpperCase() : ''}'
                      '${_typeFilter != null && _barangayFilter != null ? ' + ' : ''}'
                      '${_barangayFilter != null ? _barangays.firstWhere((b) => b['id'] == _barangayFilter, orElse: () => {'name': ''})['name'] : ''}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _typeFilter = null;
                        _barangayFilter = null;
                      });
                      _applyFilters();
                    },
                    child: Text('Clear', style: TextStyle(fontSize: 12, color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          _buildFilterChips(theme),
          Expanded(
            child: BlocBuilder<DispatcherCubit, DispatcherState>(
              builder: (ctx, state) {
                if (state is DispatcherLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is DispatcherError && state.incidents?.isEmpty == true) {
                  return _buildError(theme, state.message);
                }
                final incidents = _currentIncidents(state);
                if (incidents.isEmpty) {
                  return _buildEmpty(theme);
                }
                return RefreshIndicator(
                  onRefresh: () async => _applyFilters(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    itemCount: incidents.length,
                    itemBuilder: (ctx, i) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: GestureDetector(
                          onTap: () => context.push('/queue/${incidents[i]['id']}'),
                          child: _IncidentCard(
                            incident: incidents[i],
                            isUpdating: state is IncidentUpdating && state.updatingId == incidents[i]['id'],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _currentIncidents(DispatcherState state) {
    if (state is QueueLoaded) return state.incidents;
    if (state is IncidentUpdating) return state.incidents;
    if (state is DispatcherError) return state.incidents ?? [];
    return [];
  }

  Widget _buildFilterChips(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip(theme, null, 'All', isActive: _statusFilter == null),
          const SizedBox(width: 8),
          ..._statuses.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _filterChip(
              theme,
              s,
              s.replaceAll('_', ' ').toUpperCase(),
              isActive: _statusFilter == s,
            ),
          )),
        ],
      ),
    );
  }

  Widget _filterChip(ThemeData theme, String? value, String label, {required bool isActive}) {
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        final newFilter = isActive ? null : value;
        setState(() => _statusFilter = newFilter);
        queueFilterNotifier.value = newFilter;
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary
              : (isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.1) : (isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText)),
          borderRadius: BorderRadius.circular(24),
          border: isActive ? null : Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
          boxShadow: isActive ? [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
            child: Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Queue is empty',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! Great job.', 
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5), 
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.error.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 16),
            Text('Failed to load queue', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<DispatcherCubit>().loadQueue(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyDialog(BuildContext ctx, Map<String, dynamic> incident) {
    String? severity = incident['severity'];
    final noteCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Verify Incident', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: severity,
              decoration: InputDecoration(
                labelText: 'Override severity (optional)', 
                prefixIcon: const Icon(Icons.speed),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (v) => severity = v,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Dispatcher note (optional)',
                hintText: 'Add context or instructions...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(ctx);
              Navigator.pop(ctx);
              ctx.read<DispatcherCubit>().verifyIncident(
                incident['id'],
                severity: severity,
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              ).then((_) {
                AppToast.successOn(messenger, 'Incident verified successfully');
              }).catchError((err) {
                AppToast.errorOn(messenger, 'Failed to verify incident: $err');
              });
            },
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext ctx, Map<String, dynamic> incident) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reject Incident', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Why is this being rejected?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error, 
              foregroundColor: Theme.of(ctx).colorScheme.onError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              final messenger = ScaffoldMessenger.of(ctx);
              Navigator.pop(ctx);
              ctx.read<DispatcherCubit>().rejectIncident(
                incident['id'],
                reasonCtrl.text.trim(),
              ).then((_) {
                AppToast.successOn(messenger, 'Incident rejected');
              }).catchError((err) {
                AppToast.errorOn(messenger, 'Failed to reject incident: $err');
              });
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final bool isUpdating;

  const _IncidentCard({
    required this.incident,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final status = incident['status'] ?? 'submitted';
    final severity = incident['severity'] ?? 'medium';
    final type = incident['type'] ?? '';

    final severityColor = _severityColor(severity, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Ambient glowing gradient based on severity
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [severityColor.withValues(alpha: isDark ? 0.15 : 0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      _Badge(label: severity.toUpperCase(), color: severityColor, icon: Icons.shield_outlined),
                      const SizedBox(width: 8),
                      _Badge(label: status.replaceAll('_', ' ').toUpperCase(), color: _statusColor(status, isDark)),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgo(incident['created_at']),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                            incident['title'] ?? '',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
                          ),
                      if (incident['description'] != null && incident['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            incident['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (type.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.category_outlined, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                  const SizedBox(width: 4),
                                  Text(
                                    type.toString().replaceAll('_', ' '),
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                           if (incident['barangay_name'] != null) ...[
                            if (type.isNotEmpty) const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_city_outlined, size: 12, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    incident['barangay_name'],
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (incident['media'] != null && (incident['media'] as List).isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_camera, size: 12, color: theme.colorScheme.tertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(incident['media'] as List).length} Photo${(incident['media'] as List).length > 1 ? 's' : ''}',
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.tertiary, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (incident['address'] != null && incident['address'].toString().isNotEmpty) ...[
                            if (type.isNotEmpty) const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.location_on_rounded, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      incident['address'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUpdating)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                    child: Row(
                      children: [
                        if (incident['dispatcher_id'] != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.error),
                                const SizedBox(width: 6),
                                Text(
                                  'Claimed',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.error),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        Text(
                          'View Details →',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 28),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2.5)),
              ),
              const Text('Update Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              _StatusTile(label: 'Under Review', icon: Icons.hourglass_empty, color: isDark ? IrmsStatusColors.underReview.dark : IrmsStatusColors.underReview.light, onTap: () { Navigator.pop(context); }),
              const SizedBox(height: 12),
              _StatusTile(label: 'Resolved', icon: Icons.check_circle, color: isDark ? IrmsStatusColors.resolved.dark : IrmsStatusColors.resolved.light, onTap: () { Navigator.pop(context); }),
              const SizedBox(height: 12),
              _StatusTile(label: 'Rejected', icon: Icons.cancel, color: isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light, onTap: () { Navigator.pop(context); }),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(String s, bool isDark) {
    return switch (s) {
      'critical' => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
      'high'     => isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
      'medium'   => isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
      'low'      => isDark ? IrmsStatusColors.verified.dark : IrmsStatusColors.verified.light,
      _          => isDark ? IrmsColors.warningDark : IrmsColors.warning,
    };
  }

  Color _statusColor(String s, bool isDark) {
    return switch (s) {
      'submitted'    => isDark ? IrmsStatusColors.submitted.dark : IrmsStatusColors.submitted.light,
      'under_review' => isDark ? IrmsStatusColors.underReview.dark : IrmsStatusColors.underReview.light,
      'verified'     => isDark ? IrmsStatusColors.verified.dark : IrmsStatusColors.verified.light,
      'rejected'     => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
      'resolved'     => isDark ? IrmsStatusColors.resolved.dark : IrmsStatusColors.resolved.light,
      'declined'     => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
      _              => isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText,
    };
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatusTile({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const Spacer(),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
