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
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _cancelEditing,
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _saveChanges,
                      ),
                    ],
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _startEditing(state.user),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 800 : 450),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildAvatarCard(user, role, roleColor, roleIcon, initial, theme),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                               _buildDetailsSection(context, user, theme),
                              const SizedBox(height: 32),
                              _buildLogoutButton(context, theme),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAvatarCard(user, role, roleColor, roleIcon, initial, theme),
                        const SizedBox(height: 28),
                        _buildDetailsSection(context, user, theme),
                        const SizedBox(height: 32),
                        _buildLogoutButton(context, theme),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarCard(
    Map<String, dynamic> user,
    String role,
    Color roleColor,
    IconData roleIcon,
    String initial,
    ThemeData theme,
  ) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 44),
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: roleColor.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_editing) ...[
                TextField(
                  controller: _nameCtrl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Your name',
                  ),
                ),
              ] else ...[
                Text(
                  user['name'] ?? 'User',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                user['email'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roleColor.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 14, color: roleColor),
                    const SizedBox(width: 6),
                    Text(
                      role[0].toUpperCase() + role.substring(1),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [roleColor, roleColor.withValues(alpha: 0.65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: roleColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.badge_outlined, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                loc.profileAccountDetails,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFieldRow(
            icon: Icons.fingerprint,
            label: loc.profileAccountId,
            value: user['id'] ?? loc.fallbackUnknown,
            theme: theme,
            readOnly: true,
          ),
          const Divider(height: 28),
          _buildFieldRow(
            icon: Icons.badge_outlined,
            label: loc.profileFullName,
            value: user['name'] ?? loc.fallbackUnknown,
            theme: theme,
            editingKey: 'name',
            ctrl: _nameCtrl,
          ),
          const Divider(height: 28),
          _buildFieldRow(
            icon: Icons.email_outlined,
            label: loc.profileEmailAddress,
            value: user['email'] ?? loc.fallbackNoEmail,
            theme: theme,
            readOnly: true,
          ),
          const Divider(height: 28),
          _buildFieldRow(
            icon: Icons.phone_outlined,
            label: loc.profilePhoneNumber,
            value: user['phone'] ?? loc.fallbackNotProvided,
            theme: theme,
            editingKey: 'phone',
            ctrl: _phoneCtrl,
          ),
          const Divider(height: 28),
          _buildFieldRow(
            icon: Icons.location_on_outlined,
            label: loc.profileAddress,
            value: user['address'] ?? loc.fallbackNotProvided,
            theme: theme,
            editingKey: 'address',
            ctrl: _addressCtrl,
          ),
          const Divider(height: 28),
          _buildLanguageRow(theme),
          const Divider(height: 28),
          _buildThemeRow(theme),
          if (!kIsWeb) ...[
            const Divider(height: 28),
            _buildBiometricRow(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildBiometricRow(ThemeData theme) {
    if (kIsWeb) return const SizedBox.shrink();
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final prefs = snapshot.data!;
        bool isEnabled = prefs.getBool('biometrics_enabled') ?? true;

        return StatefulBuilder(
          builder: (context, setTileState) {
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fingerprint, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biometric Quick Unlock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Use Face ID / Fingerprint to log in', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (v) async {
                    await prefs.setBool('biometrics_enabled', v);
                    setTileState(() {
                      isEnabled = v;
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(v ? 'Biometric quick unlock enabled' : 'Biometric quick unlock disabled'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildThemeRow(ThemeData theme) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && theme.brightness == Brightness.dark);
        final label = mode == ThemeMode.system
            ? 'System Default'
            : (mode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode');

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Visual Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ),
            PopupMenuButton<ThemeMode>(
              initialValue: mode,
              onSelected: (newMode) => context.read<ThemeCubit>().setThemeMode(newMode),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      Icon(Icons.brightness_auto, size: 18),
                      SizedBox(width: 10),
                      Text('System Default'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      Icon(Icons.light_mode, size: 18),
                      SizedBox(width: 10),
                      Text('Light Mode'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      Icon(Icons.dark_mode, size: 18),
                      SizedBox(width: 10),
                      Text('Dark Mode'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary, size: 18),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageRow(ThemeData theme) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final isFil = locale.languageCode == 'fil';
        return GestureDetector(
          onTap: () {
            context.read<LocaleCubit>().setLocale(
              isFil ? const Locale('en') : const Locale('fil'),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.language_outlined, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Language',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFil ? 'Filipino' : 'English',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.swap_horiz, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFil ? 'FIL' : 'EN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    bool readOnly = false,
    String? editingKey,
    TextEditingController? ctrl,
  }) {
    final isEditing = _editing && !readOnly;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isEditing ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isEditing ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 2),
              if (isEditing && ctrl != null)
                TextField(
                  controller: ctrl,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
        if (isEditing)
          Icon(Icons.edit, size: 14, color: theme.colorScheme.primary),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showChangePasswordDialog(context),
          icon: const Icon(Icons.lock_reset),
          label: Text(loc.btnChangePassword),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            context.read<AuthCubit>().logout();
            context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: Text(loc.btnSignOut),
          style: FilledButton.styleFrom(
            backgroundColor: IrmsColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
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
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.fieldCurrentPassword,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? loc.validationRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.fieldNewPassword,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.length < 8 ? loc.validationMin8Chars : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.fieldConfirmPassword,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v != newCtrl.text) return loc.validationPasswordMismatch;
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.of(ctx).pop(),
                child: Text(loc.btnCancel),
              ),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() {
                            loading = true;
                            error = null;
                          });
                          try {
                            await context.read<AuthCubit>().changePassword(
                                  currentPassword: currentCtrl.text,
                                  newPassword: newCtrl.text,
                                );
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.snackbarPasswordChanged)),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              loading = false;
                              error = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        }
                      },
                child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(loc.btnDone),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_circle,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                loc.profileAnonymousMode,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                loc.profileAnonymousDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.go('/login'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(loc.btnLoginToAccount),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/register'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
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
}