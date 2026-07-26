import 'package:flutter/material.dart';

class AppToast {
  AppToast._();

  static void success(BuildContext context, String message, {String? title}) {
    _showWithMessenger(ScaffoldMessenger.of(context), message, title: title, icon: Icons.check_circle_rounded, color: Colors.green);
  }

  static void error(BuildContext context, String message, {String? title}) {
    _showWithMessenger(ScaffoldMessenger.of(context), message, title: title, icon: Icons.error_rounded, color: Colors.red);
  }

  static void info(BuildContext context, String message, {String? title}) {
    _showWithMessenger(ScaffoldMessenger.of(context), message, title: title, icon: Icons.info_rounded, color: Colors.blue);
  }

  static void warning(BuildContext context, String message, {String? title}) {
    _showWithMessenger(ScaffoldMessenger.of(context), message, title: title, icon: Icons.warning_rounded, color: Colors.amber);
  }

  static void successOn(ScaffoldMessengerState messenger, String message, {String? title}) {
    _showWithMessenger(messenger, message, title: title, icon: Icons.check_circle_rounded, color: Colors.green);
  }

  static void errorOn(ScaffoldMessengerState messenger, String message, {String? title}) {
    _showWithMessenger(messenger, message, title: title, icon: Icons.error_rounded, color: Colors.red);
  }

  static void _showWithMessenger(
    ScaffoldMessengerState messenger,
    String message, {
    String? title,
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = messenger.context.findAncestorWidgetOfExactType<MaterialApp>() != null
        ? Theme.of(messenger.context)
        : ThemeData.fallback();
    final isDark = theme.brightness == Brightness.dark;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: duration,
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
