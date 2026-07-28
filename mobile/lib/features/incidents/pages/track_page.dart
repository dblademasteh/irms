import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../../../core/app_toast.dart';
import '../cubit/incident_cubit.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});
  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: IrmsAppBar(title: 'Track Report'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter your tracking code', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'The code you received after submitting a report',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _codeCtrl,
                autocorrect: false, enableSuggestions: false,
                autofillHints: const <String>[],
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'TRACKING CODE',
                  hintText: 'XXXX-XXXX',
                  prefixIcon: const Icon(Icons.search),
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                ),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4, fontFamily: 'monospace'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Enter tracking code',
              ),
              const SizedBox(height: 20),
              BlocConsumer<IncidentCubit, IncidentState>(
                listener: (ctx, state) {
                  if (state is IncidentError) {
                    AppToast.error(ctx, state.message);
                  }
                },
                builder: (ctx, state) {
                  if (state is IncidentSubmitting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                  }
                  if (state is IncidentTracked) {
                    return _buildResult(state.incident);
                  }
                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _track,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Track'),
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

  Widget _buildResult(Map<String, dynamic> incident) {
    final theme = Theme.of(context);
    final status = incident['status'] ?? 'unknown';
    final severity = incident['severity'] ?? 'medium';
    final statusColor = _statusColor(status);
    final severityColor = _severityColor(severity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      severity.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                incident['title'] ?? '',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (incident['type'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  incident['type'].toString().replaceAll('_', ' '),
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ],
          ),
        ),
        if (incident['description'] != null && incident['description'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESCRIPTION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident['description'],
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (incident['address'] != null && incident['address'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      incident['address'],
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: () {
              _codeCtrl.clear();
              context.read<IncidentCubit>().reset();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Track Another'),
          ),
        ),
      ],
    );
  }

  void _track() {
    if (_formKey.currentState!.validate()) {
      context.read<IncidentCubit>().trackByCode(_codeCtrl.text.trim().toUpperCase());
    }
  }

  Color _statusColor(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (status) {
      'submitted' => isDark ? IrmsStatusColors.submitted.dark : IrmsStatusColors.submitted.light,
      'under_review' => isDark ? IrmsStatusColors.underReview.dark : IrmsStatusColors.underReview.light,
      'verified' => isDark ? IrmsStatusColors.verified.dark : IrmsStatusColors.verified.light,
      'rejected' => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
      'resolved' => isDark ? IrmsStatusColors.resolved.dark : IrmsStatusColors.resolved.light,
      _ => isDark ? IrmsColors.mutedTextDark : IrmsColors.mutedText,
    };
  }

  Color _severityColor(String severity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (severity) {
      'low'      => isDark ? IrmsStatusColors.verified.dark : IrmsStatusColors.verified.light,
      'medium'   => isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
      'high'     => isDark ? IrmsStatusColors.pending.dark : IrmsStatusColors.pending.light,
      'critical' => isDark ? IrmsStatusColors.rejected.dark : IrmsStatusColors.rejected.light,
      _          => isDark ? IrmsColors.warningDark : IrmsColors.warning,
    };
  }
}
