import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../../core/locale_cubit.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';
import '../../../core/theme_cubit.dart';
import '../../../core/dio_client.dart';

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
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _startEditing(state.user)),
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
                        onTap: () => context.go('/admin'),
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
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      if (!kIsWeb)
                        _SectionItem(
                          icon: Icons.fingerprint,
                          title: 'Biometric Unlock',
                          subtitle: 'Face ID, fingerprint',
                          trailing: _BiometricToggle(),
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
                      _SectionItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      _SectionItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {},
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
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _NotificationSettingsSheet(theme: theme),
    );
  }

void _showLocationSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _LocationSettingsSheet(theme: theme),
    );
  }

void _showUnitsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
builder: (ctx) => _UnitsSheet(theme: theme),
    );
  }

  void _showActiveSessionsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ActiveSessionsSheet(theme: theme),
    );
  }

  void _showAboutSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AppInfoSheet(theme: theme),
    );
  }
}

class _ActiveSessionsSheet extends StatefulWidget {
  final ThemeData theme;
  const _ActiveSessionsSheet({required this.theme});

  @override
  State<_ActiveSessionsSheet> createState() => _ActiveSessionsSheetState();
}

class _ActiveSessionsSheetState extends State<_ActiveSessionsSheet> {
  String _deviceName = 'Unknown Device';
  String _loginTime = 'Unknown';
  String _loginDate = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  Future<void> _loadSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    setState(() {
      _deviceName = prefs.getString('device_name') ?? _getDeviceType();
      _loginDate = '${now.day}/${now.month}/${now.year}';
      _loginTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  String _getDeviceType() {
    if (kIsWeb) return 'Web Browser';
    return 'Mobile Device';
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
            Text('Active Sessions', style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Manage your logged-in devices', style: TextStyle(color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: widget.theme.colorScheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.smartphone, color: widget.theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('This Device', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(_deviceName, style: TextStyle(fontSize: 12, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last active', style: TextStyle(fontSize: 11, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 2),
                          Text('Today, $_loginTime', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Login date', style: TextStyle(fontSize: 11, color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 2),
                          Text(_loginDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All sessions cleared')));
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Logout All Devices'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AppInfoSheet extends StatelessWidget {
  final ThemeData theme;
  const _AppInfoSheet({required this.theme});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.shield, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('IRMS', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            Text('Incident Reporting & Management System', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 24),
            _InfoRow(icon: Icons.tag, label: 'Version', value: '1.0.0', theme: theme),
            _InfoRow(icon: Icons.code, label: 'Build', value: '2026.07', theme: theme),
            _InfoRow(icon: Icons.flutter_dash, label: 'Framework', value: 'Flutter', theme: theme),
            const Divider(height: 32),
            _LinkRow(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}, theme: theme),
            _LinkRow(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}, theme: theme),
            _LinkRow(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}, theme: theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
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

  void _showChangePasswordDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(loc.dialogChangePasswordTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null) ...[
                    Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(controller: currentCtrl, obscureText: true, decoration: InputDecoration(labelText: loc.fieldCurrentPassword, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v == null || v.isEmpty ? loc.validationRequired : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: newCtrl, obscureText: true, decoration: InputDecoration(labelText: loc.fieldNewPassword, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v == null || v.length < 8 ? loc.validationMin8Chars : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: confirmCtrl, obscureText: true, decoration: InputDecoration(labelText: loc.fieldConfirmPassword, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v != newCtrl.text ? loc.validationPasswordMismatch : null),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.of(ctx).pop(), child: Text(loc.btnCancel)),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() { loading = true; error = null; });
                          try {
                            await context.read<AuthCubit>().changePassword(currentPassword: currentCtrl.text, newPassword: newCtrl.text);
                            if (ctx.mounted) { Navigator.of(ctx).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.snackbarPasswordChanged))); }
                          } catch (e) {
                            setDialogState(() { loading = false; error = e.toString().replaceAll('Exception: ', ''); });
                          }
                        }
                      },
                child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(loc.btnDone),
              ),
            ],
          );
        },
      ),
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v ? 'Biometric unlock enabled' : 'Biometric unlock disabled')));
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
