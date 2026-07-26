import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';

void showAnnouncementDetailModal(BuildContext context, Map<String, dynamic> announcement) {
  final theme = Theme.of(context);

  final category = (announcement['category'] ?? 'emergency').toString();
  final title = (announcement['title'] ?? 'BROADCAST ALERT').toString();
  final message = (announcement['message'] ?? '').toString();
  final author = (announcement['author'] ?? announcement['authorName'] ?? 'Command Center').toString();
  final timestamp = (announcement['timestamp'] ?? '').toString();
  final targetRole = (announcement['targetRole'] ?? announcement['target_role'] ?? 'all').toString();

  Color catColor;
  IconData catIcon;
  switch (category.toLowerCase()) {
    case 'emergency':
      catColor = theme.colorScheme.error;
      catIcon = Icons.warning_amber_rounded;
      break;
    case 'system':
      catColor = theme.colorScheme.secondary;
      catIcon = Icons.settings_outlined;
      break;
    case 'safety':
      catColor = IrmsColors.success;
      catIcon = Icons.health_and_safety_outlined;
      break;
    case 'weather':
      catColor = Colors.lightBlue;
      catIcon = Icons.thunderstorm_outlined;
      break;
    case 'traffic':
      catColor = Colors.orange;
      catIcon = Icons.traffic_outlined;
      break;
    case 'earthquake':
      catColor = Colors.brown;
      catIcon = Icons.vibration;
      break;
    case 'flood':
      catColor = Colors.blue;
      catIcon = Icons.water_outlined;
      break;
    case 'tsunami':
      catColor = Colors.cyan;
      catIcon = Icons.waves;
      break;
    default:
      catColor = theme.colorScheme.primary;
      catIcon = Icons.campaign_outlined;
  }

  String formattedDate = '';
  if (timestamp.isNotEmpty) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      formattedDate = DateFormat('EEEE, MMMM d, y • h:mm a').format(dt);
    } catch (_) {
      formattedDate = timestamp;
    }
  }

  showDialog(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Container with Category Theme Color
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: catColor.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(catIcon, color: catColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.outline.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Audience: ${targetRole.toUpperCase()}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close Modal',
                  ),
                ],
              ),
            ),

            // Scrollable Full Message Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.account_circle, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Text(
                          'Issued by: $author',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Modal Actions Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '$title\n\n$message'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert text copied to clipboard!'), duration: Duration(seconds: 2)),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Text'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: catColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
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
