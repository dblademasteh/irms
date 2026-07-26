import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/incidents/cubit/incident_cubit.dart';

class IdleTimeoutManager extends StatefulWidget {
  final Widget child;
  const IdleTimeoutManager({super.key, required this.child});

  @override
  State<IdleTimeoutManager> createState() => _IdleTimeoutManagerState();
}

class _IdleTimeoutManagerState extends State<IdleTimeoutManager>
    with WidgetsBindingObserver {
  // Timers
  Timer? _foregroundTimer;
  Timer? _backgroundTimer;
  Timer? _gracePeriodTimer;

  // Settings (configurable via SharedPreferences)
  int _foregroundTimeoutMinutes = 30;
  int _backgroundTimeoutMinutes = 15;
  int _gracePeriodSeconds = 60;

  // State
  bool _showingWarning = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foregroundTimer?.cancel();
    _backgroundTimer?.cancel();
    _gracePeriodTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _foregroundTimeoutMinutes = prefs.getInt('idle_foreground_minutes') ?? 30;
      _backgroundTimeoutMinutes = prefs.getInt('idle_background_minutes') ?? 15;
      _gracePeriodSeconds = prefs.getInt('idle_grace_seconds') ?? 60;
    });
    _resetForegroundTimer();
  }

  // ─── Foreground idle timer ──────────────────────────────────────────────

  void _resetForegroundTimer() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer(
      Duration(minutes: _foregroundTimeoutMinutes),
      _onForegroundTimeout,
    );
  }

  void _onUserInteraction() {
    if (!_showingWarning) {
      _resetForegroundTimer();
    }
  }

  void _onForegroundTimeout() {
    if (_isActiveIncidentFlow()) {
      // User is mid-submission or has unsaved data — reset and skip
      _resetForegroundTimer();
      return;
    }
    _showGraceWarning('You\'ve been idle for $_foregroundTimeoutMinutes minutes.');
  }

  // ─── Background timer ──────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _foregroundTimer?.cancel();
      _backgroundedAt = DateTime.now();
      _backgroundTimer?.cancel();
      _backgroundTimer = Timer(
        Duration(minutes: _backgroundTimeoutMinutes),
        _onBackgroundTimeout,
      );
    } else if (state == AppLifecycleState.resumed) {
      _backgroundTimer?.cancel();
      if (_backgroundedAt != null) {
        final awayMinutes = DateTime.now().difference(_backgroundedAt!).inMinutes;
        _backgroundedAt = null;
        if (awayMinutes >= _backgroundTimeoutMinutes && !_showingWarning) {
          // Already exceeded background timeout — force logout
          _performLogout();
          return;
        } else if (awayMinutes >= _backgroundTimeoutMinutes - 2 && !_showingWarning) {
          // Close to timeout — show warning with remaining time
          final remaining = _backgroundTimeoutMinutes - awayMinutes;
          _showGraceWarning('You were away for $awayMinutes minutes. Logging out in ${remaining.clamp(0, _backgroundTimeoutMinutes)} min.');
        }
      }
      _resetForegroundTimer();
    }
  }

  void _onBackgroundTimeout() {
    _performLogout();
  }

  // ─── Active incident flow check ────────────────────────────────────────

  bool _isActiveIncidentFlow() {
    if (!mounted) return false;
    try {
      final incidentCubit = context.read<IncidentCubit>();
      final state = incidentCubit.state;
      // Don't timeout during active submission
      if (state is IncidentSubmitting) return true;
      // Don't timeout on submission success (user might be copying tracking code)
      if (state is IncidentSubmitted) return true;
    } catch (_) {}
    return false;
  }

  // ─── Grace warning dialog ──────────────────────────────────────────────

  void _showGraceWarning(String message) {
    if (_showingWarning || !mounted) return;
    _showingWarning = true;
    _foregroundTimer?.cancel();
    _backgroundTimer?.cancel();

    int remaining = _gracePeriodSeconds;
    _gracePeriodTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Start grace countdown
          _gracePeriodTimer?.cancel();
          _gracePeriodTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!ctx.mounted) {
              timer.cancel();
              return;
            }
            remaining--;
            if (remaining <= 0) {
              timer.cancel();
              Navigator.of(ctx).pop();
              _performLogout();
            } else {
              setDialogState(() {});
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_off, color: Theme.of(context).colorScheme.error, size: 32),
            ),
            title: const Text('Session Timeout', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 16),
                Text(
                  'Logging out in $remaining s',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: remaining <= 10 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: remaining / _gracePeriodSeconds,
                    backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                    color: remaining <= 10 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _gracePeriodTimer?.cancel();
                  Navigator.of(ctx).pop();
                  _showingWarning = false;
                  _resetForegroundTimer();
                },
                child: const Text('Stay Logged In', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      _gracePeriodTimer?.cancel();
      _showingWarning = false;
    });
  }

  // ─── Logout ─────────────────────────────────────────────────────────────

  void _performLogout() {
    _gracePeriodTimer?.cancel();
    _foregroundTimer?.cancel();
    _backgroundTimer?.cancel();
    _showingWarning = false;

    if (!mounted) return;

    try {
      context.read<AuthCubit>().logout();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onUserInteraction,
        child: widget.child,
      ),
    );
  }
}
