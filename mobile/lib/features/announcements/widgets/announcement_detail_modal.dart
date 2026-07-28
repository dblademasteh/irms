import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme.dart';
import '../../../core/app_toast.dart';

Color broadcastCategoryColor(String category, ColorScheme scheme) {
  return switch (category.toLowerCase()) {
    'emergency' => scheme.error,
    'system' => scheme.secondary,
    'safety' => IrmsColors.success,
    'weather' => Colors.lightBlue,
    'traffic' => Colors.orange,
    'earthquake' => Colors.brown,
    'flood' => Colors.blue,
    'tsunami' => Colors.cyan,
    'national' => Colors.blueGrey,
    _ => scheme.primary,
  };
}

IconData broadcastCategoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'emergency' => Icons.warning_amber_rounded,
    'system' => Icons.settings_outlined,
    'safety' => Icons.health_and_safety_outlined,
    'weather' => Icons.thunderstorm_outlined,
    'traffic' => Icons.traffic_outlined,
    'earthquake' => Icons.vibration,
    'flood' => Icons.water_outlined,
    'tsunami' => Icons.waves,
    'national' => Icons.public,
    _ => Icons.campaign_outlined,
  };
}

void showAnnouncementDetailModal(BuildContext context, Map<String, dynamic> announcement) {
  final theme = Theme.of(context);

  final category = (announcement['category'] ?? 'emergency').toString();
  final title = (announcement['title'] ?? 'Broadcast Alert').toString();
  final message = (announcement['message'] ?? '').toString();
  final author = (announcement['author'] ?? announcement['authorName'] ?? 'Command Center').toString();
  final timestamp = (announcement['timestamp'] ?? '').toString();
  final targetRole = (announcement['targetRole'] ?? announcement['target_role'] ?? 'all').toString();

  final catColor = broadcastCategoryColor(category, theme.colorScheme);
  final catIcon = broadcastCategoryIcon(category);
  final isEmergency = category.toLowerCase() == 'emergency';

  String formattedDate = '';
  if (timestamp.isNotEmpty) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      formattedDate = DateFormat('MMM d, y • h:mm a').format(dt);
    } catch (_) {
      formattedDate = timestamp;
    }
  }

  final plainText = '$title\n\n$message';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (_) => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(catIcon, color: catColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    color: catColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              if (targetRole != 'all')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    targetRole.toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                if (isEmergency) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emergency_share, color: theme.colorScheme.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is an emergency broadcast. Follow official instructions immediately.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.65,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Issued by $author',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: plainText));
                          AppToast.info(context, 'Copied to clipboard');
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Share.share(plainText, subject: title),
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
