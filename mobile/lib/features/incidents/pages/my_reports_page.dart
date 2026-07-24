import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/incident_cubit.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});
  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  @override
  void initState() {
    super.initState();
    context.read<IncidentCubit>().loadMyReports();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: IrmsAppBar(
        title: loc.myReportsTitle,
      ),
      body: BlocBuilder<IncidentCubit, IncidentState>(
        builder: (ctx, state) {
          if (state is IncidentError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(loc.errorFailedToLoadReports, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.read<IncidentCubit>().loadMyReports(),
                      icon: const Icon(Icons.refresh),
                      label: Text(loc.btnRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is IncidentsLoaded) {
            if (state.incidents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      loc.emptyNoReports,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.emptyNoReportsSubtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<IncidentCubit>().loadMyReports(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.incidents.length,
                itemBuilder: (ctx, i) => _ReportCard(
                  incident: state.incidents[i],
                  onTap: () => context.go('/reports/${state.incidents[i]['id']}'),
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onTap;

  const _ReportCard({required this.incident, required this.onTap});

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

  static final _statusConfig = {
    'submitted': (IrmsStatusColors.submitted.light, 'SUBMITTED'),
    'under_review': (IrmsStatusColors.underReview.light, 'REVIEWING'),
    'verified': (IrmsStatusColors.verified.light, 'VERIFIED'),
    'rejected': (IrmsStatusColors.rejected.light, 'REJECTED'),
    'resolved': (IrmsStatusColors.resolved.light, 'RESOLVED'),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _typeColors[incident['type']] ?? theme.colorScheme.primary;
    final icon = _typeIcons[incident['type']] ?? Icons.report;
    final status = incident['status'] ?? 'submitted';
    final cfg = _statusConfig[status] ?? (theme.colorScheme.primary, status.toUpperCase());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(icon, color: typeColor, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident['title'] ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (incident['type'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: typeColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          incident['created_at']?.substring(0, 10) ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cfg.$1.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cfg.$1.withValues(alpha: 0.3)),
                ),
                child: Text(
                  cfg.$2,
                  style: TextStyle(
                    color: cfg.$1,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
