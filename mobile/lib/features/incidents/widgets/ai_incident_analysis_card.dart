import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../../../core/dio_client.dart';

class AiIncidentAnalysisCard extends StatefulWidget {
  final String incidentId;

  const AiIncidentAnalysisCard({super.key, required this.incidentId});

  @override
  State<AiIncidentAnalysisCard> createState() => _AiIncidentAnalysisCardState();
}

class _AiIncidentAnalysisCardState extends State<AiIncidentAnalysisCard> {
  bool _loading = false;
  Map<String, dynamic>? _analysis;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.post('/incidents/${widget.incidentId}/analyze');
      if (mounted) {
        setState(() {
          _analysis = resp.data['analysis'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to analyze report';
          _loading = false;
        });
      }
    }
  }

  Color _severityColor(String? sev) {
    switch (sev) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? IrmsColors.bgDark : IrmsColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('AI Situational Analysis', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              IconButton(
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 20),
                onPressed: _loading ? null : _fetchAnalysis,
                tooltip: 'Re-analyze Report',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(_error!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            )
          else if (_analysis != null) ...[
            Text(_analysis!['summary'] ?? '', style: TextStyle(fontSize: 14, height: 1.4, color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityColor(_analysis!['recommendedSeverity']).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SUGGESTED SEVERITY: ${(_analysis!['recommendedSeverity'] ?? 'medium').toString().toUpperCase()}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _severityColor(_analysis!['recommendedSeverity'])),
                  ),
                ),
                if (_analysis!['recommendedUnits'] != null)
                  ...(_analysis!['recommendedUnits'] as List).map((u) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'UNIT: ${u.toString().toUpperCase()}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  )),
              ],
            ),
            if (_analysis!['keyRisks'] != null && (_analysis!['keyRisks'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Key Risks & Hazards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ...(_analysis!['keyRisks'] as List).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
            ],
            if (_analysis!['emergencyAdvice'] != null && (_analysis!['emergencyAdvice'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Emergency Safety & First-Aid Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ...(_analysis!['emergencyAdvice'] as List).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(a.toString(), style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }
}
