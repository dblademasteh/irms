import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/auth_cubit.dart';
import '../../../l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (ctx, state) {
          if (state is Authenticated) ctx.go('/');
          if (state is Unauthenticated && state.error != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.error ?? loc.errorRegistrationFailed),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (ctx, state) {
          return isWide
              ? _buildWideLayout(context, theme, loc, state)
              : _buildNarrowLayout(context, theme, loc, state);
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, ThemeData theme, AppLocalizations loc, AuthState state) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  theme.colorScheme.secondary,
                  theme.colorScheme.secondary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CirclePatternPainter(color: Colors.white.withValues(alpha: 0.05))),
                ),
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(context),
                      const Spacer(),
                      _buildFeatureCard(
                        icon: Icons.speed,
                        title: 'Quick Reporting',
                        subtitle: 'Submit incidents in under 30 seconds',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        icon: Icons.location_on,
                        title: 'GPS Auto-Location',
                        subtitle: 'Your coordinates sent automatically',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        icon: Icons.notifications_active,
                        title: 'Real-time Alerts',
                        subtitle: 'Instant notifications for your reports',
                        theme: theme,
                      ),
                      const Spacer(),
                      Text(
                        'Join thousands of responders across the region',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildForm(context, theme, loc, state),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, ThemeData theme, AppLocalizations loc, AuthState state) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                _buildBackButton(context),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 14, color: theme.colorScheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'New Account',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildForm(context, theme, loc, state),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      onPressed: () => context.go('/profile'),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, ThemeData theme, AppLocalizations loc, AuthState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.of(context).size.width <= 700) ...[
          Text(
            'Create Account',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join the incident response network',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
        ],
        _buildSectionHeader(theme, 'Personal Information', Icons.person_outline),
        const SizedBox(height: 12),
        _buildField(
          controller: _nameCtrl,
          label: loc.fieldFullName,
          icon: Icons.person_outline,
          validator: (v) => v != null && v.isNotEmpty ? null : loc.validationRequired,
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _phoneCtrl,
          label: loc.fieldPhoneNumber,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) => v != null && v.isNotEmpty ? null : loc.validationRequired,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(theme, 'Contact & Location', Icons.location_on_outlined),
        const SizedBox(height: 12),
        _buildField(
          controller: _emailCtrl,
          label: loc.fieldEmail,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return loc.validationRequired;
            if (!val.contains('@') || !val.contains('.')) return loc.validationInvalidEmail;
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _addressCtrl,
          label: loc.fieldAddressOptional,
          icon: Icons.location_on_outlined,
          keyboardType: TextInputType.streetAddress,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(theme, 'Security', Icons.lock_outlined),
        const SizedBox(height: 12),
        _buildField(
          controller: _passCtrl,
          label: loc.fieldPassword,
          icon: Icons.lock_outline,
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          validator: (v) => v != null && v.length >= 8 ? null : loc.validationMin8Chars,
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _inviteCtrl,
          label: loc.fieldInviteCodeOptional,
          icon: Icons.vpn_key_outlined,
          hint: loc.hintInviteCode,
        ),
        const SizedBox(height: 32),
        if (state is AuthLoading)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          )
        else ...[
          FilledButton(
            onPressed: _submit,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 20),
                const SizedBox(width: 8),
                Text(loc.btnCreateAccount),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/login'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, size: 18),
                const SizedBox(width: 8),
                Text(loc.btnSignIn),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'By creating an account, you agree to our terms of service and privacy policy.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    String? hint,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
            password: _passCtrl.text,
            inviteCode: _inviteCtrl.text.trim().isEmpty ? null : _inviteCtrl.text.trim(),
          );
    }
  }
}

class _CirclePatternPainter extends CustomPainter {
  final Color color;
  _CirclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const radius = 120.0;
    for (double x = -radius; x < size.width + radius; x += radius * 2) {
      for (double y = -radius; y < size.height + radius; y += radius * 2) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
