import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/socket_client.dart';
import '../core/notification_service.dart';
import '../features/announcements/widgets/announcement_detail_modal.dart';
import '../app/theme.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/pages/profile_page.dart';
import '../features/incidents/pages/submit_incident_page.dart';
import '../features/incidents/pages/my_reports_page.dart';
import '../features/incidents/pages/report_detail_page.dart';
import '../features/incidents/pages/call_responder_page.dart';
import '../features/incidents/pages/citizen_assistant_page.dart';
import '../features/incidents/pages/track_page.dart';
import '../features/dispatcher/pages/dispatcher_queue_page.dart';
import '../features/dispatcher/pages/dashboard_page.dart';
import '../features/dispatcher/pages/dispatcher_incident_detail_page.dart';
import '../features/dispatcher/cubit/dispatcher_incident_cubit.dart';
import '../features/dispatcher/repo/dispatcher_repo.dart';
import '../features/admin/pages/admin_page.dart';

import '../features/announcements/pages/announcements_page.dart';

final authNotifier = ValueNotifier<bool>(false);
final roleNotifier = ValueNotifier<String>('reporter');
final queueFilterNotifier = ValueNotifier<String?>(null);

const publicPaths = {'/', '/call', '/track', '/profile', '/announcements', '/chat'};

bool isDispatcher(String role) => role == 'dispatcher' || role == 'admin';

GoRouter createRouter(bool isAuthenticated) {
  authNotifier.value = isAuthenticated;
  final role = roleNotifier.value;
  return GoRouter(
    initialLocation: isDispatcher(role) ? '/dashboard' : '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authenticated = authNotifier.value;
      final currentRole = roleNotifier.value;
      final location = state.matchedLocation;
      final onAuth = location == '/login' || location == '/register';
      final isPublic = publicPaths.contains(location);

      if (!authenticated && !onAuth && !isPublic) return '/login';
      if (authenticated && onAuth) return isDispatcher(currentRole) ? '/dashboard' : '/';
      if (authenticated && isPublic && isDispatcher(currentRole) && location != '/queue' && location != '/profile' && location != '/call' && location != '/announcements') {
        return '/queue';
      }
      if (!authenticated && location == '/queue') return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/track', builder: (_, __) => const TrackPage()),
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const SubmitIncidentPage(),
          ),
          GoRoute(
            path: '/announcements',
            builder: (_, __) => const AnnouncementsPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const MyReportsPage(),
          ),
          GoRoute(
            path: '/call',
            builder: (_, __) => const CallResponderPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) => const CitizenAssistantPage(),
          ),
          GoRoute(
            path: '/queue',
            builder: (_, __) => const DispatcherQueuePage(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/reports/:id',
            builder: (context, state) =>
                ReportDetailPage(incidentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/queue/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final authState = context.read<AuthCubit>().state;
              final userId = authState is Authenticated ? (authState.user['id']?.toString() ?? '') : '';
              return BlocProvider(
                create: (ctx) => DispatcherIncidentCubit(
                  ctx.read<DispatcherRepo>(),
                  currentUserId: userId,
                  incidentId: id,
                ),
                child: DispatcherIncidentDetailPage(id: id),
              );
            },
          ),
        ],
      ),
    ],
  );
}

class _ScaffoldWithNav extends StatefulWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  @override
  State<_ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends State<_ScaffoldWithNav> {
  late SocketClient _socket;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _socket = context.read<SocketClient>();
    _socket.connect();
    _socket.onSystemBroadcast(_onBroadcast);
    _socket.onConnect(() {
      if (mounted) setState(() => _isOnline = true);
    });
    _socket.onDisconnect(() {
      if (mounted) setState(() => _isOnline = false);
    });
  }

  @override
  void dispose() {
    _socket.offSystemBroadcast(_onBroadcast);
    super.dispose();
  }

  void _onBroadcast(dynamic data) {
    if (!mounted) return;
    final msg = data['message'] ?? '';
    final author = data['authorName'] ?? 'System';
    final targetRole = data['targetRole'] ?? 'all';
    final myRole = roleNotifier.value;
    final isDispatcherUser = isDispatcher(myRole);

    if (targetRole == 'dispatchers' && !isDispatcherUser) return;
    if (targetRole == 'reporters' && isDispatcherUser) return;

    NotificationService.notifyEmergencyBroadcast(author: author, message: msg);

    final announcementData = Map<String, dynamic>.from(data is Map ? data : {});
    if (!announcementData.containsKey('title')) announcementData['title'] = 'LIVE BROADCAST ALERT';

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        icon: Icon(Icons.campaign, color: Theme.of(context).colorScheme.error, size: 32),
        title: Text(
          'BROADCAST FROM ${author.toUpperCase()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.error,
            letterSpacing: 0.8,
          ),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            msg,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              showAnnouncementDetailModal(context, announcementData);
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).matchedLocation;
    final isAdmin = roleNotifier.value == 'admin';
    final dispatcher = isDispatcher(roleNotifier.value);
    
    if (dispatcher) {
      if (path == '/dashboard') return 0;
      if (path == '/queue') return 1;
      if (path == '/announcements') return 2;
      if (path == '/call') return 3;
      if (path == '/admin' && isAdmin) return 4;
      if (path == '/profile') return isAdmin ? 5 : 4;
      return 0;
    }

    if (path == '/announcements') return 1;
    if (path == '/chat') return 2;
    if (path == '/call') return 3;
    if (path == '/reports') return 4;
    if (path == '/profile') return authNotifier.value ? 5 : 4;
    return 0;
  }

  List<NavigationDestination> _destinations(BuildContext context) {
    final authenticated = authNotifier.value;
    final dispatcher = isDispatcher(roleNotifier.value);
    if (dispatcher) {
      return [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: Icon(Icons.queue_outlined),
          selectedIcon: Icon(Icons.queue),
          label: 'Queue',
        ),
        const NavigationDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign),
          label: 'Alerts',
        ),
        const NavigationDestination(
          icon: Icon(Icons.call_outlined),
          selectedIcon: Icon(Icons.call),
          label: 'Call',
        ),
        if (roleNotifier.value == 'admin')
          const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
    return [
      const NavigationDestination(
        icon: Icon(Icons.add_circle_outline),
        selectedIcon: Icon(Icons.add_circle),
        label: 'Report',
      ),
      const NavigationDestination(
        icon: Icon(Icons.campaign_outlined),
        selectedIcon: Icon(Icons.campaign),
        label: 'Alerts',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Live Chat',
      ),
      const NavigationDestination(
        icon: Icon(Icons.phone_outlined),
        selectedIcon: Icon(Icons.phone),
        label: 'Call',
      ),
      if (authenticated)
        const NavigationDestination(
          icon: Icon(Icons.list_alt),
          selectedIcon: Icon(Icons.list),
          label: 'My Reports',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  void _onTap(BuildContext context, int i) {
    final dispatcher = isDispatcher(roleNotifier.value);
    final isAdmin = roleNotifier.value == 'admin';
    if (dispatcher) {
      if (i == 0) context.go('/dashboard');
      if (i == 1) context.go('/queue');
      if (i == 2) context.go('/announcements');
      if (i == 3) context.go('/call');
      if (i == 4 && isAdmin) context.go('/admin');
      if (i == (isAdmin ? 5 : 4)) context.go('/profile');
      return;
    }
    final authenticated = authNotifier.value;
    if (i == 0) context.go('/');
    if (i == 1) context.go('/announcements');
    if (i == 2) context.go('/chat');
    if (i == 3) context.go('/call');
    final reportsIndex = authenticated ? 4 : -1;
    if (i == reportsIndex) context.go('/reports');
    final profileIndex = authenticated ? 5 : 4;
    if (i == profileIndex) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final dests = _destinations(context);
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width >= 1100;

    if (isWideScreen) {
      final selectedIndex = _currentIndex(context);
      final isAdmin = roleNotifier.value == 'admin';
      final dispatcher = isDispatcher(roleNotifier.value);
      final isDark = theme.brightness == Brightness.dark;
      final userName = context.read<AuthCubit>().state is Authenticated
          ? (context.read<AuthCubit>().state as Authenticated).user['name'] ?? 'User'
          : 'Guest';
      final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
      final role = roleNotifier.value;

      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.08),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      children: [
                        _SidebarItem(
                          icon: Icons.dashboard_outlined,
                          selectedIcon: Icons.dashboard,
                          label: 'Dashboard',
                          isSelected: selectedIndex == 0,
                          onTap: () => _onTap(context, 0),
                          theme: theme,
                        ),
                        const SizedBox(height: 4),
                        _SidebarItem(
                          icon: Icons.queue_outlined,
                          selectedIcon: Icons.queue,
                          label: 'Queue',
                          isSelected: selectedIndex == 1,
                          onTap: () => _onTap(context, 1),
                          theme: theme,
                          expanded: selectedIndex == 1,
                          subItems: [
                            _SubItem(label: 'All', filter: null, icon: Icons.inbox_outlined),
                            _SubItem(label: 'Submitted', filter: 'submitted', icon: Icons.send_outlined),
                            _SubItem(label: 'Under Review', filter: 'under_review', icon: Icons.hourglass_empty_outlined),
                            _SubItem(label: 'Verified', filter: 'verified', icon: Icons.verified_outlined),
                            _SubItem(label: 'Rejected', filter: 'rejected', icon: Icons.cancel_outlined),
                            _SubItem(label: 'Resolved', filter: 'resolved', icon: Icons.check_circle_outlined),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _SidebarItem(
                          icon: Icons.campaign_outlined,
                          selectedIcon: Icons.campaign,
                          label: 'Alerts',
                          isSelected: selectedIndex == 2,
                          onTap: () => _onTap(context, 2),
                          theme: theme,
                        ),
                        const SizedBox(height: 4),
                        _SidebarItem(
                          icon: Icons.call_outlined,
                          selectedIcon: Icons.call,
                          label: 'Call',
                          isSelected: selectedIndex == 3,
                          onTap: () => _onTap(context, 3),
                          theme: theme,
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 4),
                          _SidebarItem(
                            icon: Icons.admin_panel_settings_outlined,
                            selectedIcon: Icons.admin_panel_settings,
                            label: 'Admin',
                            isSelected: selectedIndex == 4,
                            onTap: () => _onTap(context, 4),
                            theme: theme,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    height: 1,
                  ),
                  const SizedBox(height: 6),
                  _SidebarItem(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
                    isSelected: dispatcher
                        ? (isAdmin ? selectedIndex == 5 : selectedIndex == 4)
                        : selectedIndex == (authNotifier.value ? 5 : 4),
                    onTap: () {
                      final idx = dispatcher
                          ? (isAdmin ? 5 : 4)
                          : (authNotifier.value ? 5 : 4);
                      _onTap(context, idx);
                    },
                    theme: theme,
                    showTopBorder: false,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (role == 'admin' ? IrmsColors.error : theme.colorScheme.primary).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: role == 'admin' ? IrmsColors.error : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: false,
      body: widget.child,
      bottomNavigationBar: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.18 : 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(dests.length, (i) {
                  final dest = dests[i];
                  final isSelected = _currentIndex(context) == i;
                  final iconWidget = isSelected ? dest.selectedIcon : dest.icon;
                  final iconData = (iconWidget as Icon).icon;

                  return GestureDetector(
                    onTap: () => _onTap(context, i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 16 : 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconData,
                            size: 24,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Text(
                              dest.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubItem {
  final String label;
  final String? filter;
  final IconData icon;
  const _SubItem({required this.label, this.filter, required this.icon});
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool expanded;
  final List<_SubItem> subItems;
  final bool showTopBorder;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    this.expanded = false,
    this.subItems = const [],
    this.showTopBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final hasSubItems = subItems.isNotEmpty && isSelected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasSubItems) ...[
          const SizedBox(height: 4),
          ...subItems.map((sub) {
            final isActive = queueFilterNotifier.value == sub.filter;
            return GestureDetector(
              onTap: () {
                queueFilterNotifier.value = sub.filter;
                if (!isSelected) onTap();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sub.icon,
                      size: 14,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub.label,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}