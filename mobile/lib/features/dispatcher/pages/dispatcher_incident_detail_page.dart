import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../../../core/map_launcher.dart';
import '../../../core/dio_client.dart';
import 'package:intl/intl.dart';
import '../cubit/dispatcher_incident_cubit.dart';
import '../../incidents/widgets/ai_incident_analysis_card.dart';
import '../../incidents/widgets/incident_chat_sheet.dart';

class DispatcherIncidentDetailPage extends StatefulWidget {
  final String id;
  const DispatcherIncidentDetailPage({super.key, required this.id});

  @override
  State<DispatcherIncidentDetailPage> createState() => _DispatcherIncidentDetailPageState();
}

class _DispatcherIncidentDetailPageState extends State<DispatcherIncidentDetailPage> {
  List<Map<String, dynamic>> _actionLog = [];

  @override
  void initState() {
    super.initState();
    context.read<DispatcherIncidentCubit>().loadIncident();
    _loadActionLog();
  }

  Future<void> _loadActionLog() async {
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/incidents/${widget.id}/action-log');
      setState(() {
        _actionLog = List<Map<String, dynamic>>.from(resp.data['logs'] ?? []);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: IrmsAppBar(
        title: 'Incident Details',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Live Incident Chat & AI Assistant',
            onPressed: () {
              final state = context.read<DispatcherIncidentCubit>().state;
              final userId = state is DispatcherIncidentLoaded ? state.currentUserId : null;
              showIncidentChatSheet(context, incidentId: widget.id, currentUserId: userId, role: 'dispatcher');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DispatcherIncidentCubit>().loadIncident(),
          ),
        ],
      ),
      body: BlocBuilder<DispatcherIncidentCubit, DispatcherIncidentState>(
        builder: (ctx, state) {
          if (state is DispatcherIncidentLoading && state is! DispatcherIncidentLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DispatcherIncidentError) {
            return _buildError(theme, state.message);
          }

          if (state is DispatcherIncidentLoaded) {
            final inc = state.incident;
            final isDark = theme.brightness == Brightness.dark;
            final claimedByOther = inc['dispatcher_id'] != null && inc['dispatcher_id'] != state.currentUserId;
            final claimedByMe = inc['dispatcher_id'] == state.currentUserId;

            return Column(
              children: [
                if (claimedByOther)
                  Container(
                    width: double.infinity,
                    color: theme.colorScheme.errorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: theme.colorScheme.onErrorContainer, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LOCKED - Being handled by another dispatcher.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: _getSeverityColor(inc['severity'], isDark).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(_getIncidentIcon(inc['type']), color: _getSeverityColor(inc['severity'], isDark), size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inc['title'] ?? 'No Title',
                                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.2),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _Badge(text: (inc['type'] ?? 'Unknown').toString().toUpperCase(), color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    _Badge(text: (inc['status'] ?? 'Unknown').toString().toUpperCase(), color: _getStatusColor(inc['status'], isDark)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Details Card
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(icon: Icons.calendar_today, label: 'Reported', value: _formatDate(inc['created_at'])),
                            const Divider(height: 24),
                            _DetailRow(icon: Icons.warning_amber_rounded, label: 'Severity', value: (inc['severity'] ?? 'Medium').toString().toUpperCase(), color: _getSeverityColor(inc['severity'], isDark)),
                            const Divider(height: 24),
                            if (inc['barangay_name'] != null)
                              _DetailRow(icon: Icons.location_city_outlined, label: 'Barangay', value: inc['barangay_name']),
                            if (inc['barangay_name'] != null) const Divider(height: 24),
                            if (inc['latitude'] != null && inc['longitude'] != null)
                              InkWell(
                                onTap: () => openMapDirections(
                                  (inc['latitude'] as num).toDouble(),
                                  (inc['longitude'] as num).toDouble(),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _DetailRow(
                                          icon: Icons.directions_outlined,
                                          label: 'Location (Tap for Directions)',
                                          value: inc['address'] ?? 'Coordinates: ${inc['latitude']}, ${inc['longitude']}',
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Icon(Icons.open_in_new, size: 18, color: theme.colorScheme.primary),
                                    ],
                                  ),
                                ),
                              )
                            else
                              _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: inc['address'] ?? 'No location provided'),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Icons.person_outline,
                              label: 'Reporter',
                              value: inc['reporter_name'] ?? (inc['is_anonymous'] == true ? 'Anonymous' : 'Unknown'),
                            ),
                            if (inc['reporter_phone'] != null) ...[
                              const Divider(height: 24),
                              _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: inc['reporter_phone']),
                            ],
                            const Divider(height: 24),
                            InkWell(
                              onTap: () => _showAssignDispatcherSheet(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _DetailRow(
                                        icon: Icons.headset_mic_outlined,
                                        label: 'Assigned Dispatcher',
                                        value: inc['dispatcher_name'] ?? 'Tap to assign responder',
                                        color: inc['dispatcher_name'] == null ? theme.colorScheme.primary : null,
                                      ),
                                    ),
                                    Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                                  ],
                                ),
                              ),
                            ),
                            if (inc['tracking_code'] != null) ...[
                              const Divider(height: 24),
                              _DetailRow(icon: Icons.qr_code, label: 'Tracking Code', value: inc['tracking_code']),
                            ],
                            if (context.read<DispatcherIncidentCubit>().units.isNotEmpty) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Icon(Icons.local_shipping_outlined, size: 18, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text('Dispatched Units', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: theme.colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...context.read<DispatcherIncidentCubit>().units.map((u) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _unitTypeColor(u['unit_type'], theme.colorScheme).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(_unitTypeIcon(u['unit_type']), size: 18, color: _unitTypeColor(u['unit_type'], theme.colorScheme)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u['unit_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                          Text(u['unit_type']?.toString().toUpperCase() ?? '', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    _UnitStatusChip(status: u['status'] ?? 'dispatched'),
                                    if (claimedByMe || inc['status'] == 'under_review' || inc['status'] == 'verified') ...[
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                        onSelected: (val) async {
                                          final cubit = context.read<DispatcherIncidentCubit>();
                                          if (val == 'remove') {
                                            await cubit.removeUnit(u['unit_id']);
                                          } else {
                                            final dio = context.read<DioClient>();
                                            await dio.dio.patch('/incidents/${widget.id}/units/${u['unit_id']}/status', data: {'status': val});
                                            await cubit.loadIncident();
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'en_route', child: Text('En Route')),
                                          const PopupMenuItem(value: 'on_scene', child: Text('On Scene')),
                                          const PopupMenuItem(value: 'returned', child: Text('Returned')),
                                          const PopupMenuDivider(),
                                          PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: theme.colorScheme.error))),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              )),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Photos Gallery Section
                      if (inc['media'] != null && (inc['media'] as List).isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Photos (${(inc['media'] as List).length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: (inc['media'] as List).length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (ctx, idx) {
                              final item = (inc['media'] as List)[idx];
                              final rawUrl = item is Map ? (item['url'] ?? '').toString() : item.toString();
                              final baseUrl = context.read<DioClient>().dio.options.baseUrl;
                              final fullUrl = DioClient.resolveMediaUrl(baseUrl, rawUrl);
                              final allUrls = (inc['media'] as List).map((m) {
                                final r = m is Map ? (m['url'] ?? '').toString() : m.toString();
                                return DioClient.resolveMediaUrl(baseUrl, r);
                              }).toList();

                              return GestureDetector(
                                onTap: () => _showPhotoLightbox(context, allUrls, idx),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        fullUrl,
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 140,
                                          height: 140,
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 6,
                                      bottom: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      Text('Description', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(
                        inc['description'] ?? 'No description provided.',
                        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // AI SITUATIONAL ANALYSIS CARD
                      AiIncidentAnalysisCard(incidentId: widget.id),
                      const SizedBox(height: 32),

                      // ACTION LOG TIMELINE
                      if (_actionLog.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.history, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Activity Timeline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ActionLogTimeline(logs: _actionLog),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),

                // ACTION BAR
                if (!claimedByOther && inc['status'] != 'resolved' && inc['status'] != 'rejected' && inc['status'] != 'declined')
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4))],
                    ),
                    child: SafeArea(
                      top: false,
                      child: claimedByMe || inc['status'] == 'under_review' || inc['status'] == 'verified'
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showDispatchUnitSheet(context),
                                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                                      label: const Text('Dispatch Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        foregroundColor: theme.colorScheme.primary,
                                        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showRejectSheet(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        foregroundColor: theme.colorScheme.error,
                                        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                                      ),
                                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: inc['status'] == 'verified'
                                        ? () => _showResolveSheet(context)
                                        : () => _showVerifySheet(context, inc['severity'] ?? 'medium'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: inc['status'] == 'verified' ? (isDark ? IrmsColors.successDark : IrmsColors.success) : (isDark ? IrmsColors.successDark : IrmsColors.success),
                                      ),
                                      child: Text(
                                        inc['status'] == 'verified' ? 'Mark as Resolved' : 'Verify & Assign',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () => context.read<DispatcherIncidentCubit>().claimIncident(),
                                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                  child: const Text('Claim Incident'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _showDeclineSheet(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    foregroundColor: isDark ? IrmsColors.warningDark : IrmsColors.warning,
                                    side: BorderSide(color: (isDark ? IrmsColors.warningDark : IrmsColors.warning).withValues(alpha: 0.5)),
                                  ),
                                  child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                    ),
                  )
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showVerifySheet(BuildContext context, String currentSeverity) {
    String sev = currentSeverity;
    final ctrl = TextEditingController();
    final cubit = context.read<DispatcherIncidentCubit>();
    final assignedUnitIds = cubit.units.map((u) => u['unit_id'] as String).toSet();
    final selectedUnits = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomCtx) => FutureBuilder<List<dynamic>>(
        future: () async {
          final dio = context.read<DioClient>();
          final resp = await dio.dio.get('/dispatch-units');
          return List<dynamic>.from(resp.data['units'] ?? []);
        }(),
        builder: (ctx, snapshot) {
          final allUnits = snapshot.data ?? [];
          final availableUnits = allUnits.where((u) => !assignedUnitIds.contains(u['id']) && u['status'] == 'available').toList();

          return StatefulBuilder(
            builder: (ctx, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 24, right: 24, top: 16,
                ),
                child: SingleChildScrollView(
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
                      const Text('Verify & Assign Incident', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      const Text('Confirm Severity', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: sev,
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('LOW')),
                          DropdownMenuItem(value: 'medium', child: Text('MEDIUM')),
                          DropdownMenuItem(value: 'high', child: Text('HIGH')),
                          DropdownMenuItem(value: 'critical', child: Text('CRITICAL')),
                        ],
                        onChanged: (v) => setState(() => sev = v!),
                      ),
                      const SizedBox(height: 16),
                      const Text('Assign Response Units (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                      else if (availableUnits.isEmpty)
                        Text('No available units right now.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13))
                      else
                        ...availableUnits.map((u) {
                          final uid = u['id'] as String;
                          final isSelected = selectedUnits.contains(uid);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text((u['unit_type'] ?? '').toString().toUpperCase(), style: const TextStyle(fontSize: 11)),
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selectedUnits.add(uid);
                                } else {
                                  selectedUnits.remove(uid);
                                }
                              });
                            },
                          );
                        }),
                      const SizedBox(height: 16),
                      const Text('Dispatcher Notes (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ctrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g., Firetruck dispatched to location',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () async {
                          final incidentCubit = context.read<DispatcherIncidentCubit>();
                          await incidentCubit.verifyIncident(sev, ctrl.text.trim());
                          if (selectedUnits.isNotEmpty) {
                            await incidentCubit.dispatchUnits(selectedUnits.toList());
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: IrmsColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          selectedUnits.isEmpty ? 'Confirm & Verify' : 'Confirm, Verify & Dispatch (${selectedUnits.length} Unit${selectedUnits.length > 1 ? 's' : ''})',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showResolveSheet(BuildContext context) {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomCtx).viewInsets.bottom,
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
            const Text('Resolve Incident', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Mark this incident as resolved after emergency response is complete.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Resolution notes (e.g., Fire extinguished, scene cleared)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                context.read<DispatcherIncidentCubit>().resolveIncident(ctrl.text.trim());
                Navigator.pop(bottomCtx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: IrmsColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirm & Mark Resolved', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showRejectSheet(BuildContext context) {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomCtx).viewInsets.bottom,
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
            const Text('Reject Incident', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('This will close the incident.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (e.g., Prank call, duplicate)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                context.read<DispatcherIncidentCubit>().rejectIncident(ctrl.text.trim());
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Reject Incident', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showDeclineSheet(BuildContext context) {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomCtx).viewInsets.bottom,
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
            const Text('Decline Incident', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'This will mark the incident as declined. It will remain visible but will not proceed to verification.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for declining (e.g., Outside jurisdiction, insufficient info)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                context.read<DispatcherIncidentCubit>().declineIncident(ctrl.text.trim());
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? IrmsColors.warningDark : IrmsColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Decline Incident', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAssignDispatcherSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomCtx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: () async {
            final dio = context.read<DioClient>();
            final resp = await dio.dio.get('/admin/users');
            final users = List<Map<String, dynamic>>.from(resp.data['users'] ?? []);
            return users.where((u) => u['role'] == 'dispatcher' || u['role'] == 'admin').toList();
          }(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final dispatchers = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Assign Dispatcher / Responder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (dispatchers.isEmpty)
                    const Text('No dispatchers found.')
                  else
                    ...dispatchers.map((d) => ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(d['name'] ?? 'Unknown'),
                          subtitle: Text(d['email'] ?? d['role']),
                          onTap: () async {
                            final dio = context.read<DioClient>();
                            await dio.dio.patch('/incidents/${widget.id}/assign', data: {
                              'dispatcher_id': d['id'],
                            });
                            if (ctx.mounted) {
                              Navigator.pop(bottomCtx);
                              context.read<DispatcherIncidentCubit>().loadIncident();
                            }
                          },
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDispatchUnitSheet(BuildContext context) {
    final cubit = context.read<DispatcherIncidentCubit>();
    final assignedUnitIds = cubit.units.map((u) => u['unit_id'] as String).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomCtx) {
        return FutureBuilder<List<dynamic>>(
          future: () async {
            final dio = context.read<DioClient>();
            final resp = await dio.dio.get('/dispatch-units');
            return List<dynamic>.from(resp.data['units'] ?? []);
          }(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final allUnits = snapshot.data ?? [];
            final availableUnits = allUnits.where((u) => !assignedUnitIds.contains(u['id'])).toList();
            final selectedUnits = <String>{};

            return StatefulBuilder(
              builder: (ctx, setSheetState) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        const Text('Dispatch Unit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Select units to dispatch to this incident.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                    const SizedBox(height: 20),
                    if (availableUnits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text('No available units', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14)),
                          ],
                        ),
                      )
                    else
                      ...availableUnits.map((u) {
                        final isSelected = selectedUnits.contains(u['id']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setSheetState(() {
                                if (isSelected) {
                                  selectedUnits.remove(u['id']);
                                } else {
                                  selectedUnits.add(u['id']);
                                }
                              }),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _unitTypeColor(u['unit_type'], Theme.of(context).colorScheme).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(_unitTypeIcon(u['unit_type']), size: 20, color: _unitTypeColor(u['unit_type'], Theme.of(context).colorScheme)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                          Text(u['unit_type']?.toString().toUpperCase() ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    if (selectedUnits.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          await cubit.dispatchUnits(selectedUnits.toList());
                          if (bottomCtx.mounted) Navigator.pop(bottomCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${selectedUnits.length} unit(s) dispatched'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: Text('Dispatch ${selectedUnits.length} Unit(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Error', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<DispatcherIncidentCubit>().loadIncident(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showPhotoLightbox(BuildContext context, List<String> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final url = photos[index];
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.white54),
                          SizedBox(height: 12),
                          Text('Unable to load photo', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dt) {
    if (dt == null) return 'Unknown';
    try {
      final date = DateTime.parse(dt).toLocal();
      return DateFormat('MMM d, y h:mm a').format(date);
    } catch (_) {
      return dt;
    }
  }

  Color _getSeverityColor(String? severity, bool isDark) {
    return switch (severity) {
      'critical' => isDark ? IrmsColors.errorDark : IrmsColors.error,
      'high' => isDark ? IrmsColors.warningDark : IrmsColors.warning,
      'medium' => isDark ? IrmsColors.warningDark : IrmsColors.warning,
      'low' => isDark ? IrmsColors.successDark : IrmsColors.success,
      _ => isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText,
    };
  }

  Color _getStatusColor(String? status, bool isDark) {
    return IrmsStatusColors.resolve(status ?? '', isDark);
  }

  IconData _getIncidentIcon(String? type) {
    switch (type) {
      case 'fire': return Icons.local_fire_department;
      case 'accident': return Icons.car_crash;
      case 'crime': return Icons.local_police;
      case 'medical': return Icons.medical_services;
      case 'natural_disaster': return Icons.storm;
      case 'infrastructure': return Icons.construction;
      default: return Icons.report_problem;
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _DetailRow({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color ?? theme.colorScheme.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionLogTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  const _ActionLogTimeline({required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: List.generate(logs.length, (i) {
        final log = logs[i];
        final isLast = i == logs.length - 1;
        final action = log['action'] ?? '';
        final color = _actionColor(action, isDark);
        final icon = _actionIcon(action);
        final date = _formatDate(log['created_at']);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _actionLabel(action),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
                    ),
                    if (log['actor_name'] != null)
                      Text(
                        'by ${log['actor_name']}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    if (log['notes'] != null && log['notes'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          log['notes'],
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                        ),
                      ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _actionLabel(String action) {
    return switch (action) {
      'created' => 'Incident Reported',
      'verified' => 'Incident Verified',
      'rejected' => 'Incident Rejected',
      'resolved' => 'Incident Resolved',
      'claimed' => 'Incident Claimed',
      'dispatched' => 'Unit Dispatched',
      'declined' => 'Incident Declined',
      _ => action.toUpperCase(),
    };
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'created' => Icons.add_circle_outline,
      'verified' => Icons.check_circle_outline,
      'rejected' => Icons.cancel_outlined,
      'resolved' => Icons.task_alt,
      'claimed' => Icons.person_outline,
      'dispatched' => Icons.local_shipping_outlined,
      'declined' => Icons.block_outlined,
      _ => Icons.circle,
    };
  }

  Color _actionColor(String action, bool isDark) {
    return switch (action) {
      'created'   => isDark ? IrmsColors.primaryDark : IrmsColors.primary,
      'verified'  => isDark ? IrmsStatusColors.verified.dark : IrmsStatusColors.verified.light,
      'rejected'  => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
      'resolved'  => isDark ? IrmsStatusColors.resolved.dark : IrmsStatusColors.resolved.light,
      'claimed'   => isDark ? IrmsStatusColors.underReview.dark : IrmsStatusColors.underReview.light,
      'dispatched' => isDark ? IrmsStatusColors.dispatchedUnit.dark : IrmsStatusColors.dispatchedUnit.light,
      'declined'  => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
      _           => isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText,
    };
  }

  String _formatDate(String? dt) {
    if (dt == null) return '';
    try {
      final date = DateTime.parse(dt).toLocal();
      return DateFormat('MMM d, y h:mm a').format(date);
    } catch (_) {
      return dt;
    }
  }
}

Color _unitTypeColor(String? type, ColorScheme scheme) {
  final isDark = scheme.brightness == Brightness.dark;
  return switch (type) {
    'fire'    => isDark ? IrmsStatusColors.fire.dark : IrmsStatusColors.fire.light,
    'medical' => isDark ? IrmsStatusColors.medical.dark : IrmsStatusColors.medical.light,
    'police'  => isDark ? IrmsColors.primaryDark : IrmsColors.primary,
    _         => scheme.primary,
  };
}

IconData _unitTypeIcon(String? type) {
  return switch (type) {
    'fire' => Icons.local_fire_department,
    'medical' => Icons.medical_services,
    'police' => Icons.local_police,
    _ => Icons.local_shipping_outlined,
  };
}

class _UnitStatusChip extends StatelessWidget {
  final String status;
  const _UnitStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (label, color) = switch (status) {
      'dispatched' => ('Dispatched', isDark ? IrmsStatusColors.dispatchedUnit.dark : IrmsStatusColors.dispatchedUnit.light),
      'en_route' => ('En Route', isDark ? IrmsColors.warningDark : IrmsColors.warning),
      'on_scene' => ('On Scene', isDark ? IrmsColors.successDark : IrmsColors.success),
      'returned' => ('Returned', isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText),
      _ => (status, isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
