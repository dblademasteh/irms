import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/socket_client.dart';
import '../../../core/dio_client.dart';
import '../../../core/map_launcher.dart';
import '../cubit/incident_cubit.dart';
import '../widgets/incident_chat_sheet.dart';

class ReportDetailPage extends StatefulWidget {
  final String incidentId;
  const ReportDetailPage({super.key, required this.incidentId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    context.read<IncidentCubit>().loadDetail(widget.incidentId);
    try { context.read<SocketClient>().trackIncident(widget.incidentId); } catch (_) {}
  }

  @override
  void dispose() {
    try { context.read<SocketClient>().untrackIncident(widget.incidentId); } catch (_) {}
    super.dispose();
  }

  static const _typeIcons = {
    'fire': Icons.local_fire_department,
    'accident': Icons.car_crash,
    'crime': Icons.local_police,
    'medical': Icons.medical_services,
    'natural_disaster': Icons.storm,
    'infrastructure': Icons.construction,
  };

  static final _typeColors = {
    'fire': IrmsStatusColors.fire.light,
    'accident': IrmsStatusColors.pending.light,
    'crime': IrmsColors.primary,
    'medical': IrmsStatusColors.medical.light,
    'natural_disaster': IrmsColors.info,
    'infrastructure': IrmsColors.mutedText,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<IncidentCubit, IncidentState>(
      builder: (ctx, state) {
        final inc = state is IncidentDetailLoaded ? state.incident : <String, dynamic>{};

        return Scaffold(
          appBar: IrmsAppBar(
            title: 'Report Detail',
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Live Responder Chat & AI Assistant',
                onPressed: () => showIncidentChatSheet(context, incidentId: widget.incidentId, role: 'citizen', incident: inc.isNotEmpty ? inc : null),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showIncidentChatSheet(context, incidentId: widget.incidentId, role: 'citizen', incident: inc.isNotEmpty ? inc : null),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Live Chat & Assistant'),
          ),
          body: Builder(
            builder: (ctx) {
              if (state is IncidentError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text('Failed to load report', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.read<IncidentCubit>().loadDetail(widget.incidentId),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is! IncidentDetailLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final status = inc['status'] ?? 'submitted';
              final type = inc['type'] ?? 'fire';
              final severity = inc['severity'] ?? 'medium';
              final statusColor = _statusColor(status, theme.brightness == Brightness.dark);
              final typeColor = _typeColors[type] ?? theme.colorScheme.primary;
              final typeIcon = _typeIcons[type] ?? Icons.report;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(status: status, statusColor: statusColor),
                    const SizedBox(height: 16),
                    _buildTypeSeverityBadges(type: type, typeColor: typeColor, typeIcon: typeIcon, severity: severity, isDark: theme.brightness == Brightness.dark),
                    const SizedBox(height: 16),
                    _buildTimelineTracker(status: status, createdAt: inc['created_at'], theme: theme),
                    const SizedBox(height: 16),
                    _buildMetaCard(incident: inc, theme: theme),
                    if (status == 'verified' || status == 'resolved') ...[
                      const SizedBox(height: 14),
                      _buildResponderDispatchCard(type: type, theme: theme),
                    ],
                    if (inc['description'] != null && inc['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildDescriptionCard(description: inc['description'], theme: theme),
                    ],
                    if (inc['media'] != null && (inc['media'] as List).isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildPhotoCard(mediaUrls: List<String>.from(inc['media']), context: context, theme: theme),
                    ],
                    if (inc['dispatcher_note'] != null && inc['dispatcher_note'].toString().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildDispatcherNoteCard(note: inc['dispatcher_note'], theme: theme),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader({required String status, required Color statusColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(status), color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INCIDENT STATUS',
                style: TextStyle(
                  color: statusColor.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSeverityBadges({
    required String type,
    required Color typeColor,
    required IconData typeIcon,
    required String severity,
    required bool isDark,
  }) {
    final sevColor = _severityColor(severity, isDark);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: typeColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  type.toString().replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: sevColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sevColor.withValues(alpha: 0.25)),
          ),
          child: Text(
            severity.toUpperCase(),
            style: TextStyle(color: sevColor, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaCard({required Map<String, dynamic> incident, required ThemeData theme}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (incident['created_at'] != null)
              _MetaRow(icon: Icons.schedule, label: 'Created', value: (incident['created_at'] as String).substring(0, 16).replaceAll('T', ' ')),
            if (incident['address'] != null && incident['address'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _MetaRow(icon: Icons.location_on, label: 'Address', value: incident['address']),
            ],
            if (incident['latitude'] != null && incident['longitude'] != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => openMapDirections(
                  (incident['latitude'] as num).toDouble(),
                  (incident['longitude'] as num).toDouble(),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetaRow(
                          icon: Icons.map,
                          label: 'Coordinates (Tap for Directions)',
                          value: '${(incident['latitude'] as num).toDouble().toStringAsFixed(5)}, ${(incident['longitude'] as num).toDouble().toStringAsFixed(5)}',
                        ),
                      ),
                      Icon(Icons.open_in_new, size: 18, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            (incident['latitude'] as num).toDouble(),
                            (incident['longitude'] as num).toDouble(),
                          ),
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.irms_mobile',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  (incident['latitude'] as num).toDouble(),
                                  (incident['longitude'] as num).toDouble(),
                                ),
                                width: 38,
                                height: 38,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Column(
                          children: [
                            _MapControlButton(
                              icon: Icons.my_location,
                              tooltip: 'Recenter',
                              onTap: () => _mapController.move(
                                LatLng(
                                  (incident['latitude'] as num).toDouble(),
                                  (incident['longitude'] as num).toDouble(),
                                ),
                                _mapController.camera.zoom,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _MapControlButton(
                              icon: Icons.navigation,
                              tooltip: 'True North',
                              onTap: () => _mapController.rotate(0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard({required String description, required ThemeData theme}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DESCRIPTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            Text(description, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.9), height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({required List<String> mediaUrls, required BuildContext context, required ThemeData theme}) {
    final baseUrl = context.read<DioClient>().dio.options.baseUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Photos (${mediaUrls.length})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mediaUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, idx) {
                final rawUrl = mediaUrls[idx];
                final fullUrl = DioClient.resolveMediaUrl(baseUrl, rawUrl);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    fullUrl,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 140,
                      height: 140,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
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

  Widget _buildDispatcherNoteCard({required String note, required ThemeData theme}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'DISPATCHER NOTE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 8),
            Text(
              note,
              style: TextStyle(
                fontSize: 14,
                color: theme.brightness == Brightness.dark ? Colors.amber.shade200 : Colors.amber.shade900,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildTimelineTracker({required String status, String? createdAt, required ThemeData theme}) {
    final steps = [
      ('Submitted', status != 'draft'),
      ('Reviewing', status == 'under_review' || status == 'verified' || status == 'resolved'),
      ('Verified', status == 'verified' || status == 'resolved'),
      ('Resolved', status == 'resolved'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'INCIDENT TIMELINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((step) {
              final isDone = step.$2;
              final isRejected = status == 'rejected' && step.$1 == 'Verified';
              final activeColor = isRejected ? theme.colorScheme.error : theme.colorScheme.primary;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? activeColor : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isDone ? Icons.check : Icons.circle,
                          size: isDone ? 16 : 8,
                          color: isDone ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
                        color: isDone ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderDispatchCard({required String type, required ThemeData theme}) {
    final deptName = type == 'fire' ? 'Bureau of Fire Protection'
        : type == 'accident' ? 'Traffic Emergency Unit'
        : type == 'crime' ? 'Police Station Command'
        : type == 'medical' ? 'Red Cross Emergency Medical'
        : 'Disaster Response Team';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'DISPATCHED RESPONDER UNIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            deptName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Units assigned and en route to GPS coordinates. ETA ~ 8 mins.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _statusColor(String status, bool isDark) {
  return switch (status) {
    'submitted' => isDark ? IrmsStatusColors.submitted.dark : IrmsStatusColors.submitted.light,
    'under_review' => isDark ? IrmsStatusColors.underReview.dark : IrmsStatusColors.underReview.light,
    'verified' => isDark ? IrmsStatusColors.verified.dark : IrmsStatusColors.verified.light,
    'rejected' => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
    'resolved' => isDark ? IrmsStatusColors.resolved.dark : IrmsStatusColors.resolved.light,
    _ => isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText,
  };
}

IconData _statusIcon(String status) {
  return switch (status) {
    'submitted' => Icons.hourglass_top,
    'under_review' => Icons.search,
    'verified' => Icons.verified,
    'rejected' => Icons.cancel,
    'resolved' => Icons.check_circle,
    _ => Icons.help_outline,
  };
}

Color _severityColor(String severity, bool isDark) {
  return switch (severity) {
    'low'      => isDark ? IrmsStatusColors.verified.dark : IrmsStatusColors.verified.light,
    'medium'   => isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
    'high'     => isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
    'critical' => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
    _          => isDark ? IrmsColors.warningDark : IrmsColors.warning,
  };
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
