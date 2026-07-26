import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../core/app_toast.dart';
import '../../../core/locale_cubit.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';
import '../../../core/theme_cubit.dart';
import '../../../core/dio_client.dart';
import '../repo/auth_repo.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConsentOnMount());
  }

  void _checkConsentOnMount() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConsentGate(context);
      });
    }
  }

  void _showConsentGate(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ConsentGateSheet(theme: theme, onAccept: () => Navigator.pop(ctx)),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _startEditing(Map<String, dynamic> user) {
    _nameCtrl.text = user['name'] ?? '';
    _phoneCtrl.text = user['phone'] ?? '';
    _addressCtrl.text = user['address'] ?? '';
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    setState(() => _editing = false);
  }

  void _saveChanges() {
    context.read<AuthCubit>().updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileAppBarTitle),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                if (_editing) {
                  return Row(
                    children: [
                      IconButton(icon: const Icon(Icons.close), onPressed: _cancelEditing),
                      IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges),
                    ],
                  );
                }
                return Row(
                  children: [
                    _NotificationBell(),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return _buildAuthenticatedProfile(context, state.user, theme);
          }
          return _buildUnauthenticatedProfile(context, theme);
        },
      ),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final role = user['role']?.toString().toLowerCase() ?? 'reporter';
    final roleColor = _roleColor(role, theme);
    final roleIcon = _roleIcon(role);
    final nameStr = user['name']?.toString() ?? 'User';
    final initial = nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'U';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
              child: Column(
                children: [
                  _buildProfileHeader(user, role, roleColor, roleIcon, initial, theme),
                  const SizedBox(height: 24),
                  _buildSection(
                    theme,
                    title: 'Account',
                    items: [
                      _SectionItem(
                        icon: Icons.person_outlined,
                        title: 'Personal Info',
                        subtitle: 'Name, email, phone, address',
                        onTap: () => _showAccountDetailsSheet(context, user, theme),
                      ),
                      _SectionItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Alerts, sounds, badges',
                        onTap: () => _showNotificationSettingsSheet(context),
                      ),
_SectionItem(
                        icon: Icons.vpn_key_outlined,
                        title: 'Invites & Codes',
                        subtitle: 'Invite people to join',
                        onTap: () => _showInviteLinkSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    theme,
                    title: 'Preferences',
                    items: [
                      _SectionItem(
                        icon: Icons.dark_mode_outlined,
                        title: 'Theme',
                        subtitle: _getThemeLabel(context),
                        onTap: () => _showThemeSelector(context),
                      ),
                      _SectionItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: _getLanguageLabel(context),
                        onTap: () => _toggleLanguage(context),
                      ),
                      _SectionItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location Services',
                        subtitle: 'GPS, proximity alerts',
                        onTap: () => _showLocationSettingsSheet(context),
                      ),
                      _SectionItem(
                        icon: Icons.speed_outlined,
                        title: 'Units of Measure',
                        subtitle: 'Distance, temperature',
                        onTap: () => _showUnitsSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    theme,
                    title: 'Security',
                    items: [
_SectionItem(
                        icon: Icons.lock_outlined,
                        title: 'Change Password',
                        onTap: () => _showChangePasswordSheet(context),
                      ),
                      _SectionItem(
                        icon: Icons.verified_user_outlined,
                        title: 'Two-Factor Authentication',
                        subtitle: 'Google Authenticator',
                        onTap: () => _showTwoFactorSheet(context),
                      ),
                      if (!kIsWeb)
                        _SectionItem(
                          icon: Icons.fingerprint,
                          title: 'Biometric Unlock',
                          subtitle: 'Face ID, fingerprint',
                          trailing: _BiometricToggle(),
                        ),
                      _SectionItem(
                        icon: Icons.pin_outlined,
                        title: '4-Digit PIN',
                        subtitle: 'Quick login with PIN',
                        onTap: () => _showPinSetupSheet(context),
                      ),
_SectionItem(
                        icon: Icons.devices_outlined,
                        title: 'Active Sessions',
                        subtitle: 'Manage logged-in devices',
                        onTap: () => _showActiveSessionsSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
_buildSection(
                    theme,
                    title: 'About',
                    items: [
                      _SectionItem(
                        icon: Icons.info_outlined,
                        title: 'App Info',
                        subtitle: 'Version 1.0.0',
                        onTap: () => _showAboutSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context, theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    Map<String, dynamic> user,
    String role,
    Color roleColor,
    IconData roleIcon,
    String initial,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [roleColor, roleColor.withValues(alpha: 0.65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: Text(
              initial,
              style: theme.textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_editing)
          SizedBox(
            width: 200,
            child: TextField(
              controller: _nameCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else
          Text(user['name'] ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          user['email'] ?? '',
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: roleColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleIcon, size: 14, color: roleColor),
              const SizedBox(width: 6),
              Text(
                role[0].toUpperCase() + role.substring(1),
                style: TextStyle(color: roleColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, {required String title, required List<_SectionItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary, letterSpacing: 0.5)),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) Divider(height: 1, indent: 56, color: theme.colorScheme.outline.withValues(alpha: 0.06)),
                Material(color: Colors.transparent, child: item.buildTile(theme)),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _getLanguageLabel(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state;
    return locale.languageCode == 'fil' ? 'Filipino' : 'English';
  }

  void _toggleLanguage(BuildContext context) {
    final locale = context.read<LocaleCubit>().state;
    context.read<LocaleCubit>().setLocale(locale.languageCode == 'fil' ? const Locale('en') : const Locale('fil'));
  }

  String _getThemeLabel(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    return switch (mode) {
      ThemeMode.system => 'System Default',
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
    };
  }

  void _showThemeSelector(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Select Theme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System Default'),
              onTap: () { context.read<ThemeCubit>().setThemeMode(ThemeMode.system); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () { context.read<ThemeCubit>().setThemeMode(ThemeMode.light); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () { context.read<ThemeCubit>().setThemeMode(ThemeMode.dark); Navigator.pop(ctx); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

void _showAccountDetailsSheet(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final loc = AppLocalizations.of(context)!;
    final role = user['role']?.toString() ?? 'reporter';
    final nameCtrl = TextEditingController(text: user['name'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final addressCtrl = TextEditingController(text: user['address'] ?? '');
    bool isEditing = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Personal Information', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    if (!isEditing)
                      TextButton.icon(
                        onPressed: () => setSheetState(() => isEditing = true),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      )
                    else
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              nameCtrl.text = user['name'] ?? '';
                              phoneCtrl.text = user['phone'] ?? '';
                              addressCtrl.text = user['address'] ?? '';
                              setSheetState(() => isEditing = false);
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setSheetState(() => isSaving = true);
                                    try {
                                      context.read<AuthCubit>().updateProfile(
                                        name: nameCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                        address: addressCtrl.text.trim(),
                                      );
                                      if (ctx.mounted) {
                                        setSheetState(() { isEditing = false; isSaving = false; });
                                        Navigator.pop(ctx);
                                        AppToast.success(context, 'Profile updated');
                                      }
                                    } catch (e) {
                                      setSheetState(() => isSaving = false);
                                    }
                                  },
                            child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _EditableInfoCard(
                  nameCtrl: nameCtrl,
                  phoneCtrl: phoneCtrl,
                  addressCtrl: addressCtrl,
                  userId: user['id'] ?? '',
                  email: user['email'] ?? '',
                  role: role,
                  isEditing: isEditing,
                  loc: loc,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _NotificationSettingsSheet(theme: theme),
    );
  }

void _showLocationSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _LocationSettingsSheet(theme: theme),
    );
  }

void _showUnitsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (ctx) => _UnitsSheet(theme: theme),
    );
  }

  void _showActiveSessionsSheet(BuildContext context) {
    final dio = context.read<DioClient>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ActiveSessionsSheet(theme: Theme.of(context), dio: dio),
    );
  }

  void _showTwoFactorSheet(BuildContext context) {
    final dio = context.read<DioClient>();
    final authCubit = context.read<AuthCubit>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _TwoFactorSetupSheet(theme: Theme.of(context), dio: dio, authCubit: authCubit),
    );
  }

  void _showPinSetupSheet(BuildContext context) {
    final dio = context.read<DioClient>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PinSetupSheet(theme: Theme.of(context), dio: dio),
    );
  }

  void _showAboutSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AppInfoSheet(
              theme: theme,
              onHelpSupportTap: () {
                Navigator.pop(ctx);
                _showHelpSupportSheet(context);
              },
              onPrivacyPolicyTap: () {
                Navigator.pop(ctx);
                _showPrivacyPolicySheet(context);
              },
              onTermsOfServiceTap: () {
                Navigator.pop(ctx);
                _showTermsOfServiceSheet(context);
              },
            ),
    );
  }

  void _showInviteLinkSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _InviteLinkSheet(theme: theme),
    );
  }

  void _showHelpSupportSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _HelpSupportSheet(theme: theme),
    );
  }

  void _showPrivacyPolicySheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PrivacyPolicySheet(theme: theme),
    );
  }

  void _showTermsOfServiceSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _TermsOfServiceSheet(theme: theme),
    );
  }
}

class _ActiveSessionsSheet extends StatefulWidget {
  final ThemeData theme;
  final DioClient dio;
  const _ActiveSessionsSheet({required this.theme, required this.dio});

  @override
  State<_ActiveSessionsSheet> createState() => _ActiveSessionsSheetState();
}

class _ActiveSessionsSheetState extends State<_ActiveSessionsSheet> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final repo = AuthRepo(widget.dio);
      final sessions = await repo.getSessions();
      if (mounted) setState(() { _sessions = sessions; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    try {
      final repo = AuthRepo(widget.dio);
      await repo.revokeSession(sessionId);
      if (mounted) {
        setState(() { _sessions.removeWhere((s) => s['id'] == sessionId); });
        AppToast.success(context, 'Session revoked');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Failed: $e');
    }
  }

  String _formatUserAgent(String? ua) {
    if (ua == null || ua.isEmpty) return 'Unknown device';
    if (ua.toLowerCase().contains('android')) return 'Android Device';
    if (ua.toLowerCase().contains('iphone') || ua.toLowerCase().contains('ipad')) return 'iOS Device';
    if (ua.toLowerCase().contains('chrome')) return 'Chrome Browser';
    if (ua.toLowerCase().contains('firefox')) return 'Firefox Browser';
    return ua.length > 40 ? '${ua.substring(0, 40)}...' : ua;
  }

  @override
  Widget build(BuildContext context) {
    final currentCount = _sessions.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Active Sessions', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Manage your logged-in devices', style: TextStyle(color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.theme.colorScheme.primary,
                    widget.theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Sessions', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        _loading
                            ? const Text('--', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))
                            : Text('$currentCount', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                        const SizedBox(width: 6),
                        Text(_loading ? '...' : 'Live', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_error!, style: TextStyle(color: widget.theme.colorScheme.error))))
            else if (_sessions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No active sessions')))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final session = _sessions[i];
                    final isCurrent = session['current'] == true;
                    final sessionId = session['id'] as String;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? widget.theme.colorScheme.primary.withValues(alpha: 0.1)
                            : widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? widget.theme.colorScheme.primary.withValues(alpha: 0.3)
                              : widget.theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? widget.theme.colorScheme.primary.withValues(alpha: 0.2)
                                  : widget.theme.colorScheme.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isCurrent ? Icons.smartphone : Icons.computer,
                              color: isCurrent ? widget.theme.colorScheme.primary : widget.theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _formatUserAgent(session['userAgent'] as String?),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Current', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (session['ip'] != null)
                                  Text('IP: ${session['ip']}', style: TextStyle(fontSize: 12, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                if (session['createdAt'] != null)
                                  Text('Since: ${session['createdAt']}', style: TextStyle(fontSize: 11, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                              ],
                            ),
                          ),
                          if (!isCurrent)
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: widget.theme.colorScheme.error.withValues(alpha: 0.7), size: 22),
                              onPressed: () => _revokeSession(sessionId),
                              tooltip: 'Revoke session',
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _sessions.isEmpty ? null : () async {
                  final repo = AuthRepo(widget.dio);
                  for (final s in _sessions) {
                    if (s['current'] != true) {
                      try { await repo.revokeSession(s['id'] as String); } catch (_) {}
                    }
                  }
                  if (mounted) {
                    setState(() => _sessions = _sessions.where((s) => s['current'] == true).toList());
                    AppToast.success(context, 'Other sessions revoked');
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Logout Other Devices'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PinSetupSheet extends StatefulWidget {
  final ThemeData theme;
  final DioClient dio;
  const _PinSetupSheet({required this.theme, required this.dio});

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  String _pin = '';
  String _confirm = '';
  bool _loading = false;
  bool _pinEnabled = false;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final repo = AuthRepo(widget.dio);
      final enabled = await repo.getPinStatus();
      if (mounted) setState(() { _pinEnabled = enabled; _checkingStatus = false; });
    } catch (_) {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  Future<void> _setup() async {
    if (_pin.length != 4 || _confirm.length != 4) return;
    if (_pin != _confirm) return;
    setState(() => _loading = true);
    try {
      final repo = AuthRepo(widget.dio);
      await repo.setupPin(_pin);
      if (mounted) {
        setState(() => _pinEnabled = true);
        AppToast.success(context, 'PIN set successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _loading = true);
    try {
      final repo = AuthRepo(widget.dio);
      await repo.removePin();
      if (mounted) {
        setState(() { _pinEnabled = false; _pin = ''; _confirm = ''; });
        AppToast.success(context, 'PIN removed');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: _checkingStatus
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: widget.theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.pin_outlined, color: widget.theme.colorScheme.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text('4-Digit PIN', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pinEnabled ? 'Your PIN is active. You can log in with your email and PIN.' : 'Set a 4-digit PIN for quick login without your password.',
                          style: TextStyle(color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 24),
                        if (_pinEnabled) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 12),
                                Text('PIN is active', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _loading ? null : _remove,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: widget.theme.colorScheme.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text('Remove PIN', style: TextStyle(color: widget.theme.colorScheme.error, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            onChanged: (v) => setState(() => _pin = v.replaceAll(RegExp(r'\D'), '')),
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            obscureText: true,
                            obscuringCharacter: '●',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12),
                            decoration: InputDecoration(
                              labelText: 'Enter 4-digit PIN',
                              hintText: '●●●●',
                              hintStyle: TextStyle(color: widget.theme.colorScheme.outline.withValues(alpha: 0.3), letterSpacing: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (v) => setState(() => _confirm = v.replaceAll(RegExp(r'\D'), '')),
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            obscureText: true,
                            obscuringCharacter: '●',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12),
                            decoration: InputDecoration(
                              labelText: 'Confirm PIN',
                              hintText: '●●●●',
                              hintStyle: TextStyle(color: widget.theme.colorScheme.outline.withValues(alpha: 0.3), letterSpacing: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              counterText: '',
                              errorText: _pin.isNotEmpty && _confirm.isNotEmpty && _pin != _confirm ? 'PINs do not match' : null,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: (_pin.length == 4 && _confirm.length == 4 && _pin == _confirm && !_loading) ? _setup : null,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Set PIN', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _AppInfoSheet extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback? onHelpSupportTap;
  final VoidCallback? onPrivacyPolicyTap;
  final VoidCallback? onTermsOfServiceTap;
  const _AppInfoSheet({required this.theme, this.onHelpSupportTap, this.onPrivacyPolicyTap, this.onTermsOfServiceTap});

  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset('solana_logo.png', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('IRMS', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      Text('Incident Reporting & Management System', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    _InfoRow(icon: Icons.tag, label: 'Version', value: '1.0.0', theme: theme),
                    _InfoRow(icon: Icons.code, label: 'Build', value: '2026.07', theme: theme),
                    _InfoRow(icon: Icons.flutter_dash, label: 'Framework', value: 'Flutter', theme: theme),
                    const Divider(height: 32),
                    _LinkRow(icon: Icons.help_outline, label: 'Help & Support', onTap: () => onHelpSupportTap?.call(), theme: theme),
                    _LinkRow(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => onPrivacyPolicyTap?.call(), theme: theme),
                    _LinkRow(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () => onTermsOfServiceTap?.call(), theme: theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InviteLinkSheet extends StatefulWidget {
  final ThemeData theme;
  const _InviteLinkSheet({required this.theme});

  @override
  State<_InviteLinkSheet> createState() => _InviteLinkSheetState();
}

class _InviteLinkSheetState extends State<_InviteLinkSheet> {
  bool _loading = false;
  String? _currentCode;
  String? _currentShareUrl;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final repo = AuthRepo(context.read<DioClient>());
    final codes = await repo.getMyInviteCodes();
    setState(() => _history = codes);
  }

  Future<void> _generateCode() async {
    setState(() => _loading = true);
    try {
      final repo = AuthRepo(context.read<DioClient>());
      final result = await repo.createInviteCode();
      setState(() {
        _currentCode = result['code'] as String;
        _currentShareUrl = result['shareUrl'] as String;
      });
      await repo.saveInviteCode({'code': _currentCode, 'shareUrl': _currentShareUrl, 'createdAt': DateTime.now().toIso8601String()});
      await _loadHistory();
    } catch (e) {
      if (mounted) AppToast.error(context, 'Failed to generate code: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyCode() {
    if (_currentCode == null) return;
    Clipboard.setData(ClipboardData(text: _currentCode!));
    AppToast.info(context, 'Code copied: ${_currentCode!}');
  }

  void _shareLink() {
    if (_currentCode == null) return;
    final text = 'Join IRMS! Use invite code: $_currentCode';
    Share.share(text, subject: 'IRMS Invite Code');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.vpn_key_outlined, color: widget.theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text('Invite & Codes', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Generate invite codes to share with others', style: TextStyle(color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _generateCode,
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add),
                    label: Text(_loading ? 'Generating…' : 'Generate Invite Code'),
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
                ),
                if (_currentCode != null) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: widget.theme.colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Invite Code', style: TextStyle(fontWeight: FontWeight.w600, color: widget.theme.colorScheme.primary)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(_currentCode!, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: widget.theme.colorScheme.onSurface)),
                              ),
                              IconButton(
                                onPressed: _copyCode,
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy code',
                              ),
                              IconButton(
                                onPressed: _shareLink,
                                icon: const Icon(Icons.share),
                                tooltip: 'Share link',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_currentShareUrl ?? '', style: TextStyle(fontSize: 12, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.4)), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Expanded(
                  child: _history.isEmpty
                      ? Center(child: Text('No codes generated yet', style: TextStyle(color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.4))))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _history.length,
                          itemBuilder: (ctx, i) {
                            final item = _history[i];
                            final createdAt = DateTime.tryParse(item['createdAt'] ?? '');
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.vpn_key_outlined, size: 18, color: widget.theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                                        if (createdAt != null) Text(_formatDate(createdAt), style: TextStyle(fontSize: 12, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final code = item['code'] as String?;
                                      if (code != null) {
                                        Share.share('Join IRMS! Use invite code: $code', subject: 'IRMS Invite Code');
                                      }
                                    },
                                    icon: const Icon(Icons.share, size: 18),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TwoFactorSetupSheet extends StatefulWidget {
  final ThemeData theme;
  final DioClient dio;
  final AuthCubit authCubit;
  const _TwoFactorSetupSheet({required this.theme, required this.dio, required this.authCubit});

  @override
  State<_TwoFactorSetupSheet> createState() => _TwoFactorSetupSheetState();
}

class _TwoFactorSetupSheetState extends State<_TwoFactorSetupSheet> {
  String? _secret;
  String? _otpUri;
  bool _loading = false;
  bool _verifying = false;
  String _code = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _loading = true);
    try {
      final repo = AuthRepo(widget.dio);
      final result = await repo.setup2Fa();
      setState(() {
        _secret = result['secret'] as String;
        _otpUri = result['uri'] as String;
      });
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to setup 2FA: $e');
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    setState(() { _verifying = true; _error = null; });
    try {
      final repo = AuthRepo(widget.dio);
      await repo.verify2FaSetup(_code);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Invalid code. Try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _disable() async {
    try {
      final repo = AuthRepo(widget.dio);
      await repo.disable2Fa();
      if (mounted) {
        AppToast.success(context, '2FA has been disabled');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Column(
                          children: [
                            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.verified_user_outlined, color: widget.theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Text('Two-Factor Authentication', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Scan the QR code with Google Authenticator', style: TextStyle(color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(24),
                          children: [
                            if (_otpUri != null)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                  child: QrImageView(data: _otpUri!, version: QrVersions.auto, size: 200),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Manual Key', style: TextStyle(fontWeight: FontWeight.w600, color: widget.theme.colorScheme.primary)),
                                  const SizedBox(height: 8),
                                  Text(_secret ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 2)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Open Google Authenticator → Add account → Scan barcode or enter key manually', style: TextStyle(fontSize: 12, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                            const SizedBox(height: 24),
                            TextField(
                              onChanged: (v) => setState(() { _code = v.replaceAll(RegExp(r'\D'), ''); }),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
                              decoration: InputDecoration(
                                hintText: '000000',
                                hintStyle: TextStyle(color: widget.theme.colorScheme.outline.withValues(alpha: 0.3), letterSpacing: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                counterText: '',
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(_error!, style: TextStyle(color: widget.theme.colorScheme.error, fontSize: 13)),
                            ],
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: (_code.length == 6 && !_verifying) ? _verify : null,
                              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                              child: _verifying
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Verify & Enable'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _disable,
                              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                              child: const Text('Disable 2FA'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  const _InfoRow({super.key, required this.icon, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;
  const _LinkRow({super.key, required this.icon, required this.label, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: theme.colorScheme.primary),
      title: Text(label),
      trailing: Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
      onTap: onTap,
    );
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  final ThemeData theme;
  const _NotificationSettingsSheet({required this.theme});

  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _badgeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notif_push') ?? true;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
      _badgeEnabled = prefs.getBool('notif_badge') ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Notification Settings', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            _SettingToggleTile(title: 'Push Notifications', subtitle: 'Receive alerts on your device', value: _pushEnabled, onChanged: (v) => setState(() { _pushEnabled = v; _save('notif_push', v); })),
            _SettingToggleTile(title: 'Sound', subtitle: 'Play sound for new alerts', value: _soundEnabled, onChanged: (v) => setState(() { _soundEnabled = v; _save('notif_sound', v); })),
            _SettingToggleTile(title: 'Vibration', subtitle: 'Vibrate for emergency alerts', value: _vibrationEnabled, onChanged: (v) => setState(() { _vibrationEnabled = v; _save('notif_vibration', v); })),
            _SettingToggleTile(title: 'Badge Count', subtitle: 'Show unread notification count', value: _badgeEnabled, onChanged: (v) => setState(() { _badgeEnabled = v; _save('notif_badge', v); })),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    final loc = AppLocalizations.of(context)!;
    return FilledButton.icon(
      onPressed: () {
        context.read<AuthCubit>().logout();
        context.go('/login');
      },
      icon: const Icon(Icons.logout),
      label: Text(loc.btnSignOut),
      style: FilledButton.styleFrom(
        backgroundColor: IrmsColors.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ChangePasswordSheet(theme: Theme.of(context)),
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context, ThemeData theme) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                child: Center(child: Icon(Icons.account_circle, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.25))),
              ),
              const SizedBox(height: 32),
              Text(loc.profileAnonymousMode, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(loc.profileAnonymousDescription, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55), height: 1.5)),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.go('/login'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(loc.btnLoginToAccount),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/register'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(loc.btnCreateAccount),
              ),
            ],
          ),
        ),
      ),
);
  }

Color _roleColor(String role, ThemeData theme) {
  final statusKey = switch (role) {
    'admin' => 'admin',
    'dispatcher' => 'dispatcher',
    'reporter' => 'reporter',
    _ => 'reporter',
  };
  final isDark = theme.brightness == Brightness.dark;
  return IrmsStatusColors.resolve(statusKey, isDark);
}

IconData _roleIcon(String role) {
  return switch (role) {
    'admin' => Icons.admin_panel_settings,
    'dispatcher' => Icons.verified_user,
    'reporter' => Icons.person,
    _ => Icons.person,
  };
}

class _SectionItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SectionItem({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap});

  Widget buildTile(ThemeData theme) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))) : null,
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)) : null),
      onTap: onTap,
    );
  }
}


class _BiometricToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final prefs = snapshot.data!;
        bool isEnabled = prefs.getBool('biometrics_enabled') ?? true;
        return Switch(
          value: isEnabled,
          onChanged: (v) async {
            await prefs.setBool('biometrics_enabled', v);
            if (context.mounted) {
              AppToast.info(context, v ? 'Biometric unlock enabled' : 'Biometric unlock disabled');
            }
          },
);
      },
    );
  }
}

class _NotificationBell extends StatefulWidget {
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/notifications', queryParameters: {'unreadOnly': true});
      final list = resp.data['notifications'] as List? ?? [];
      if (mounted) setState(() => _unreadCount = list.length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.go('/announcements'),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  final ThemeData theme;
  const _InfoCard({required this.items, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (index > 0) Divider(height: 1, indent: 56, color: theme.colorScheme.outline.withValues(alpha: 0.06)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: theme.colorScheme.primary),
                ),
                title: Text(item.label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                subtitle: Text(item.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                trailing: item.copyable ? IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () {}) : null,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  const _InfoItem({required this.icon, required this.label, required this.value, this.copyable = false});
}

class _SettingToggle extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingToggle({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  State<_SettingToggle> createState() => _SettingToggleState();
}

class _SettingToggleState extends State<_SettingToggle> {
  late bool _value;
  @override
  void initState() { super.initState(); _value = widget.value; }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(widget.subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      trailing: Switch(value: _value, onChanged: (v) { setState(() => _value = v); widget.onChanged(v); }),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String title;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const _RadioOption({required this.title, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        ),
        Row(
          children: options.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isSelected = index == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => onChanged(index),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _DetailTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EditableInfoCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final String userId;
  final String email;
  final String role;
  final bool isEditing;
  final AppLocalizations loc;
  final ThemeData theme;

  const _EditableInfoCard({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.userId,
    required this.email,
    required this.role,
    required this.isEditing,
    required this.loc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildReadOnlyTile(Icons.badge, 'User ID', userId),
          const Divider(height: 1, indent: 56),
          _buildNameTile(),
          const Divider(height: 1, indent: 56),
          _buildReadOnlyTile(Icons.email, loc.profileEmailAddress, email),
          const Divider(height: 1, indent: 56),
          _buildPhoneTile(),
          const Divider(height: 1, indent: 56),
          _buildAddressTile(),
          const Divider(height: 1, indent: 56),
          _buildRoleTile(),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildNameTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(loc.profileFullName, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
      subtitle: isEditing
          ? TextField(controller: nameCtrl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), decoration: const InputDecoration(isDense: true, border: InputBorder.none))
          : Text(nameCtrl.text.isEmpty ? loc.fallbackUnknown : nameCtrl.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPhoneTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.phone, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(loc.profilePhoneNumber, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
      subtitle: isEditing
          ? TextField(controller: phoneCtrl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: loc.fallbackNotProvided))
          : Text(phoneCtrl.text.isEmpty ? loc.fallbackNotProvided : phoneCtrl.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAddressTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.location_on, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(loc.profileAddress, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
      subtitle: isEditing
          ? TextField(controller: addressCtrl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: loc.fallbackNotProvided))
          : Text(addressCtrl.text.isEmpty ? loc.fallbackNotProvided : addressCtrl.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildRoleTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.shield, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text('Role', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
      subtitle: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Text(role[0].toUpperCase() + role.substring(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
      ),
    );
  }
}

class _LocationSettingsSheet extends StatefulWidget {
  final ThemeData theme;
  const _LocationSettingsSheet({required this.theme});

  @override
  State<_LocationSettingsSheet> createState() => _LocationSettingsSheetState();
}

class _LocationSettingsSheetState extends State<_LocationSettingsSheet> {
  bool _gpsEnabled = true;
  bool _nearbyAlerts = true;
  bool _autoReport = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gpsEnabled = prefs.getBool('setting_gps') ?? true;
      _nearbyAlerts = prefs.getBool('setting_nearby_alerts') ?? true;
      _autoReport = prefs.getBool('setting_auto_report_location') ?? false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Location Services', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            _SettingToggleTile(
              title: 'GPS Location',
              subtitle: 'Share your location when reporting',
              value: _gpsEnabled,
              onChanged: (v) => setState(() { _gpsEnabled = v; _save('setting_gps', v); }),
            ),
            _SettingToggleTile(
              title: 'Nearby Alerts',
              subtitle: 'Get notified of incidents near you',
              value: _nearbyAlerts,
              onChanged: (v) => setState(() { _nearbyAlerts = v; _save('setting_nearby_alerts', v); }),
            ),
            _SettingToggleTile(
              title: 'Auto-Report Location',
              subtitle: 'Automatically include location in reports',
              value: _autoReport,
              onChanged: (v) => setState(() { _autoReport = v; _save('setting_auto_report_location', v); }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _UnitsSheet extends StatefulWidget {
  final ThemeData theme;
  const _UnitsSheet({required this.theme});

  @override
  State<_UnitsSheet> createState() => _UnitsSheetState();
}

class _UnitsSheetState extends State<_UnitsSheet> {
  int _distance = 0; // 0 = km, 1 = miles
  int _temperature = 0; // 0 = celsius, 1 = fahrenheit
  int _speed = 0; // 0 = km/h, 1 = mph

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _distance = prefs.getInt('setting_distance_unit') ?? 0;
      _temperature = prefs.getInt('setting_temp_unit') ?? 0;
      _speed = prefs.getInt('setting_speed_unit') ?? 0;
    });
  }

  Future<void> _save(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Units of Measure', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            _RadioOptionTile(
              title: 'Distance',
              options: const ['Kilometers', 'Miles'],
              selected: _distance,
              onChanged: (i) => setState(() { _distance = i; _save('setting_distance_unit', i); }),
            ),
            _RadioOptionTile(
              title: 'Temperature',
              options: const ['Celsius', 'Fahrenheit'],
              selected: _temperature,
              onChanged: (i) => setState(() { _temperature = i; _save('setting_temp_unit', i); }),
            ),
            _RadioOptionTile(
              title: 'Speed',
              options: const ['km/h', 'mph'],
              selected: _speed,
              onChanged: (i) => setState(() { _speed = i; _save('setting_speed_unit', i); }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SettingToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingToggleTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _RadioOptionTile extends StatelessWidget {
  final String title;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const _RadioOptionTile({required this.title, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        ),
        Wrap(
          spacing: 8,
          children: options.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isSelected = index == selected;
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(index),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface))),
        ],
      ),
);
  }
}

class _HelpSupportSheet extends StatefulWidget {
  final ThemeData theme;
  const _HelpSupportSheet({required this.theme});

  @override
  State<_HelpSupportSheet> createState() => _HelpSupportSheetState();
}

class _HelpSupportSheetState extends State<_HelpSupportSheet> {
  int? _expandedIndex;

  final List<_FaqItem> _faqs = [
    _FaqItem(
      q: 'How do I report an incident?',
      a: 'Tap the + button on the home screen, fill in the incident type, location, and description, then submit. You can also attach photos.',
    ),
    _FaqItem(
      q: 'How do I add emergency contacts?',
      a: 'Go to Profile > Contacts. From there you can add, edit, or remove emergency contacts who will be notified during incidents.',
    ),
    _FaqItem(
      q: 'Can I report anonymously?',
      a: 'Yes, toggle the "Report Anonymously" option when creating an incident. Your identity will not be shared.',
    ),
    _FaqItem(
      q: 'How does location tracking work?',
      a: 'Location is used to pinpoint incident reports and dispatch responders. You can enable/disable this in Profile > Location.',
    ),
    _FaqItem(
      q: 'What alert categories can I subscribe to?',
      a: 'You can subscribe to Weather, Traffic, Earthquake, Flood, Tsunami, and Fire alerts. Manage them in Profile > Notifications.',
    ),
  ];

@override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: widget.theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.support_agent, color: widget.theme.colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text('Help & Support', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Row(
                      children: [
                        _SupportCard(
                          icon: Icons.email_outlined,
                          label: 'Contact',
                          sub: 'Email us',
                          color: Colors.blue,
                          onTap: () => _launchEmail(),
                        ),
                        const SizedBox(width: 12),
                        _SupportCard(
                          icon: Icons.bug_report_outlined,
                          label: 'Bug',
                          sub: 'Report issue',
                          color: Colors.orange,
                          onTap: () => _launchBugReport(),
                        ),
                        const SizedBox(width: 12),
                        _SupportCard(
                          icon: Icons.menu_book_outlined,
                          label: 'Guide',
                          sub: 'How-to',
                          color: Colors.teal,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Frequently Asked Questions', style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text('${_faqs.length} questions', style: TextStyle(fontSize: 12, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_faqs.length, (index) {
                      final faq = _faqs[index];
                      final isExpanded = _expandedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isExpanded
                                  ? widget.theme.colorScheme.primary.withValues(alpha: 0.3)
                                  : widget.theme.colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                          size: 18,
                                          color: widget.theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            faq.q,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isExpanded) ...[
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 28),
                                        child: Text(
                                          faq.a,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchEmail() {
    AppToast.info(context, 'Opening email client...');
  }

  void _launchBugReport() {
    AppToast.info(context, 'Opening bug report form...');
  }
}

class _FaqItem {
  final String q;
  final String a;
  _FaqItem({required this.q, required this.a});
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _SupportCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                Text(sub, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyPolicySheet extends StatefulWidget {
  final ThemeData theme;
  const _PrivacyPolicySheet({required this.theme});

  @override
  State<_PrivacyPolicySheet> createState() => _PrivacyPolicySheetState();
}

class _PrivacyPolicySheetState extends State<_PrivacyPolicySheet> {
  bool _consentGiven = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.privacy_tip, color: theme.colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Privacy Policy', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                                Text('Data Privacy Act compliance', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text('v1.0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    _PolicySection(
                      theme: theme,
                      icon: Icons.storage,
                      title: '1. Information We Collect',
                      content: 'We collect personal information that you voluntarily provide when registering an account, including your name, email address, phone number, and location data. We also collect device information such as device type, operating system, and unique device identifiers. Usage data including incident reports, alert preferences, and interaction logs are captured to improve service quality.',
                    ),
                    _PolicySection(
                      theme: theme,
                      icon: Icons.widgets,
                      title: '2. How We Use Your Information',
                      content: 'Your information is used to provide and maintain the IRMS incident reporting service, notify you of relevant safety alerts in your area, dispatch emergency responders to reported incidents, and improve our platform functionality and user experience. We may aggregate anonymized data for statistical analysis to enhance public safety systems.',
                    ),
                    _PolicySection(
                      theme: theme,
                      icon: Icons.share,
                      title: '3. Data Sharing & Disclosure',
                      content: 'Personal information may be shared with authorized government agencies, law enforcement, and emergency response units when necessary to respond to reported incidents. We do not sell your personal data to third parties. Data may be disclosed when required by law, court order, or to protect the safety of individuals.',
                    ),
                    _PolicySection(
                      theme: theme,
                      icon: Icons.shield,
                      title: '4. Data Security',
                      content: 'We implement appropriate technical and organizational security measures including encryption of data in transit and at rest, access controls and authentication requirements, regular security audits and vulnerability assessments, and secure storage with redundant backups. No system is completely secure, and we cannot guarantee absolute security.',
                    ),
                    _PolicySection(
                      theme: theme,
                      icon: Icons.person,
                      title: '5. Your Rights',
                      content: 'You have the right to access your personal data and receive a copy, request correction of inaccurate information, request deletion of your data subject to legal retention requirements, withdraw consent at any time (where processing is consent-based), and lodge a complaint with a data protection authority if you believe your rights have been violated.',
                    ),
                    _PolicySection(
                      theme: theme,
                      icon: Icons.timer,
                      title: '6. Data Retention',
                      content: 'Account data is retained while your account is active. Incident reports and associated data are retained for a minimum period as required by applicable laws and regulations. You may request account deletion, after which your data will be removed within 30 days, except where legal retention obligations apply.',
                    ),
                    _PolicySection(
                      theme: theme,
                      icon: Icons.policy,
                      title: '7. Cookies & Tracking',
                      content: 'We use essential cookies to maintain session state and authentication. Analytics cookies help us understand app usage patterns to improve functionality. You can manage cookie preferences in your device settings. Disabling cookies may affect some app features.',
                    ),
                    _PolicySection(
                      theme: theme,
                      icon: Icons.contact_mail,
                      title: '8. Contact & Data Officer',
                      content: 'For privacy concerns, contact our Data Protection Officer at privacy@irms.local. For incident reports or urgent safety matters, use the in-app emergency reporting feature or contact local authorities directly.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Consent Agreement', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'By using IRMS, you acknowledge that you have read, understood, and agree to the collection, use, and processing of your personal information as described in this Privacy Policy. You consent to the sharing of your information with authorized responders and agencies for the purpose of incident response and public safety.',
                            style: TextStyle(fontSize: 13, height: 1.6, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => setState(() => _consentGiven = !_consentGiven),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: _consentGiven ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                                foregroundColor: _consentGiven ? Colors.white : theme.colorScheme.onSurface,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_consentGiven ? Icons.check_circle : Icons.circle_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(_consentGiven ? 'Consent Given' : 'Give Consent'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PolicySection extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String content;
  const _PolicySection({required this.theme, required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
Text(content, style: TextStyle(fontSize: 12.5, height: 1.6, color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final ThemeData theme;
  const _ChangePasswordSheet({required this.theme});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int _getStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    int score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)) score++;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pwd)) score++;
    return score.clamp(0, 5);
  }

  Color _strengthColor(int s) {
    if (s <= 1) return Colors.red;
    if (s <= 2) return Colors.orange;
    if (s <= 3) return Colors.amber;
    return Colors.green;
  }

  String _strengthLabel(int s) {
    if (s == 0) return '';
    if (s <= 1) return 'Weak';
    if (s <= 2) return 'Fair';
    if (s <= 3) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final strength = _getStrength(_newCtrl.text);

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text('Change Password', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PasswordField(
                            controller: _currentCtrl,
                            label: 'Current Password',
                            show: _showCurrent,
                            onToggle: () => setState(() => _showCurrent = !_showCurrent),
                            validator: (v) => v == null || v.isEmpty ? 'Current password is required' : null,
                          ),
                          const SizedBox(height: 20),
                          _PasswordField(
                            controller: _newCtrl,
                            label: 'New Password',
                            show: _showNew,
                            onToggle: () => setState(() => _showNew = !_showNew),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'New password is required';
                              if (v.length < 8) return 'Minimum 8 characters required';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_newCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: strength / 5,
                                      minHeight: 6,
                                      backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
                                      color: _strengthColor(strength),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_strengthLabel(strength), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _strengthColor(strength))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                _reqChip('8+ chars', _newCtrl.text.length >= 8, theme),
                                _reqChip('Upper+Lower', RegExp(r'[A-Z]').hasMatch(_newCtrl.text) && RegExp(r'[a-z]').hasMatch(_newCtrl.text), theme),
                                _reqChip('Number', RegExp(r'[0-9]').hasMatch(_newCtrl.text), theme),
                                _reqChip('Special', RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_newCtrl.text), theme),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          _PasswordField(
                            controller: _confirmCtrl,
                            label: 'Confirm New Password',
                            show: _showConfirm,
                            onToggle: () => setState(() => _showConfirm = !_showConfirm),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm your password';
                              if (v != _newCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13))),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_reset, size: 18),
                                        SizedBox(width: 8),
                                        Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reqChip(String label, bool met, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: met ? Colors.green.withValues(alpha: 0.1) : theme.colorScheme.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: met ? Colors.green.withValues(alpha: 0.3) : theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(met ? Icons.check : Icons.close, size: 10, color: met ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: met ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthCubit>().changePassword(currentPassword: _currentCtrl.text, newPassword: _newCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Password updated successfully');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final void Function(String)? onChanged;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: !show,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility, size: 20),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}

class _ConsentGateSheet extends StatefulWidget {
  final ThemeData theme;
  final VoidCallback onAccept;
  const _ConsentGateSheet({required this.theme, required this.onAccept});

  @override
  State<_ConsentGateSheet> createState() => _ConsentGateSheetState();
}

class _ConsentGateSheetState extends State<_ConsentGateSheet> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: widget.theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.privacy_tip, color: widget.theme.colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Privacy Policy', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                                Text('Data Privacy Act compliance', style: TextStyle(fontSize: 12, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  children: [
                    _PolicySection(
                      theme: widget.theme,
                      icon: Icons.storage,
                      title: '1. Information We Collect',
                      content: 'We collect personal information that you voluntarily provide, including your name, email address, phone number, and location data. Device information such as device type, operating system, and unique identifiers are also collected.',
                    ),
                    _PolicySection(
                      theme: widget.theme,
                      icon: Icons.widgets,
                      title: '2. How We Use Your Information',
                      content: 'Your information is used to provide and maintain the IRMS incident reporting service, notify you of relevant safety alerts, dispatch emergency responders, and improve our platform functionality.',
                    ),
                    _PolicySection(
                      theme: widget.theme,
                      icon: Icons.share,
                      title: '3. Data Sharing',
                      content: 'Personal information may be shared with authorized government agencies, law enforcement, and emergency response units when necessary to respond to reported incidents. We do not sell your personal data.',
                    ),
                    _PolicySection(
                      theme: widget.theme,
                      icon: Icons.shield,
                      title: '4. Data Security',
                      content: 'We implement encryption of data in transit and at rest, access controls, and secure storage with redundant backups. No system is completely secure, and we cannot guarantee absolute security.',
                    ),
                    _PolicySection(
                      theme: widget.theme,
                      icon: Icons.person,
                      title: '5. Your Rights',
                      content: 'You have the right to access, correct, and request deletion of your personal data. You may withdraw consent at any time and lodge a complaint with a data protection authority.',
                    ),
                    _PolicySection(
                      theme: widget.theme,
                      icon: Icons.timer,
                      title: '6. Data Retention',
                      content: 'Account data is retained while your account is active. You may request account deletion, after which your data will be removed within 30 days, except where legal retention obligations apply.',
                    ),
                    _PolicySection(
                      theme: widget.theme,
                      icon: Icons.contact_mail,
                      title: '7. Contact',
                      content: 'For privacy concerns, contact our Data Protection Officer at privacy@irms.local.',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: widget.theme.colorScheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: widget.theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Consent Agreement', style: TextStyle(fontWeight: FontWeight.w800, color: widget.theme.colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'By using IRMS, you acknowledge that you have read, understood, and agree to the collection, use, and processing of your personal information as described above. You consent to the sharing of your information with authorized responders and agencies for incident response and public safety.',
                            style: TextStyle(fontSize: 13, height: 1.6, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => setState(() => _accepted = !_accepted),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: _accepted ? widget.theme.colorScheme.primary : widget.theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: _accepted ? Colors.white : widget.theme.colorScheme.onSurface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_accepted ? Icons.check_circle : Icons.circle_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(_accepted ? 'I Accept & Continue' : 'Accept to Continue'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _accepted ? widget.onAccept : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Continue to Profile'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TermsOfServiceSheet extends StatelessWidget {
  final ThemeData theme;
  const _TermsOfServiceSheet({required this.theme});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.gavel, color: theme.colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Terms of Service', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                                Text('Effective date: July 2026', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    _TosSection(theme: theme, number: '1', title: 'Acceptance of Terms', content: 'By accessing or using the IRMS mobile application and services, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any part of these terms, you must not use the service.'),
                    _TosSection(theme: theme, number: '2', title: 'Description of Service', content: 'IRMS provides an incident reporting and management system for reporting safety incidents, receiving emergency alerts, and coordinating with dispatch services. The service is provided as-is and may be updated, modified, or discontinued at any time without prior notice.'),
                    _TosSection(theme: theme, number: '3', title: 'User Eligibility', content: 'You must be at least 18 years of age to create an account. Minors may use the service under the supervision of a parent or legal guardian who accepts these terms on their behalf. You are responsible for ensuring your use of the service complies with local laws in your jurisdiction.'),
                    _TosSection(theme: theme, number: '4', title: 'Account Responsibilities', content: 'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify IRMS immediately of any unauthorized use. You must provide accurate and complete information during registration and keep your profile updated.'),
                    _TosSection(theme: theme, number: '5', title: 'Incident Reporting Guidelines', content: 'When reporting incidents, you must provide accurate and truthful information. False, misleading, or malicious reports are strictly prohibited and may result in account termination. You may not use the reporting system for non-emergency purposes or spam. Repeated abuse of the incident reporting feature may lead to suspension or permanent ban from the platform.'),
                    _TosSection(theme: theme, number: '6', title: 'Prohibited Activities', content: 'You agree not to: (a) use the service for any illegal purpose; (b) submit false emergency reports or hoax alerts; (c) attempt to gain unauthorized access to any part of the system; (d) interfere with or disrupt the service or servers; (e) collect user information without consent; (f) transmit any malware or harmful code; (g) impersonate any person or entity.'),
                    _TosSection(theme: theme, number: '7', title: 'Emergency Services', content: 'IRMS is not a substitute for contacting local emergency services (police, fire, medical) directly. In a life-threatening emergency, always call your local emergency number immediately. While we endeavor to route reports to appropriate responders, we do not guarantee response times or that a response will be dispatched.'),
                    _TosSection(theme: theme, number: '8', title: 'Disclaimer of Warranties', content: 'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND. IRMS DOES NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED, SECURE, OR ERROR-FREE. WE MAKE NO WARRANTIES ABOUT THE ACCURACY, RELIABILITY, OR COMPLETENESS OF ANY INFORMATION PROVIDED THROUGH THE SERVICE.'),
                    _TosSection(theme: theme, number: '9', title: 'Limitation of Liability', content: 'TO THE MAXIMUM EXTENT PERMITTED BY LAW, IRMS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF OR INABILITY TO USE THE SERVICE. IN NO EVENT SHALL OUR TOTAL LIABILITY EXCEED THE AMOUNT YOU PAID US IN THE PAST TWELVE MONTHS, IF ANY.'),
                    _TosSection(theme: theme, number: '10', title: 'Termination', content: 'We may terminate or suspend your account immediately, without prior notice, for any reason including breach of these Terms. Upon termination, your right to use the service will cease immediately. Provisions that by their nature should survive termination shall survive, including ownership, warranties, indemnification, and limitations of liability.'),
                    _TosSection(theme: theme, number: '11', title: 'Changes to Terms', content: 'We reserve the right to modify these terms at any time. Changes will be effective upon posting to the application. Your continued use after changes constitutes acceptance of the modified terms. We encourage you to review these terms periodically.'),
                    _TosSection(theme: theme, number: '12', title: 'Governing Law', content: 'These Terms shall be governed by and construed in accordance with applicable laws. Any disputes arising from these terms or your use of the service shall be resolved through binding arbitration or in the courts of competent jurisdiction.'),
                    _TosSection(theme: theme, number: '13', title: 'Contact', content: 'For questions about these Terms, contact us at legal@irms.local. For emergency situations, use the in-app emergency reporting feature or contact local authorities directly.'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TosSection extends StatelessWidget {
  final ThemeData theme;
  final String number;
  final String title;
  final String content;
  const _TosSection({required this.theme, required this.number, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 12.5, height: 1.6, color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}
