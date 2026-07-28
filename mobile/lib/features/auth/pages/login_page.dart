import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubit/auth_cubit.dart';
import '../../../core/app_toast.dart';
import '../../../core/storage.dart';
import '../../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _obscure = true;
  int _loginMode = 0; // 0=password, 1=otp, 2=pin
  bool _otpSent = false;
  bool _hasStoredEmail = false;

  @override
  void initState() {
    super.initState();
    _loadStoredEmail();
  }

  Future<void> _loadStoredEmail() async {
    final stored = await SecureStorage().getUser();
    if (stored != null && mounted) {
      final email = stored['email']?.toString();
      if (email != null && email.isNotEmpty) {
        setState(() {
          _emailCtrl.text = email;
          _hasStoredEmail = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
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
          if (state is AuthOtpSent) {
            setState(() { _otpSent = true; });
            AppToast.success(ctx, 'OTP sent to ${state.phone}');
          }
          if (state is Unauthenticated && state.error != null) {
            AppToast.error(ctx, state.error ?? loc.errorLoginFailed);
            // Clear PIN/OTP field on failed login so user can re-enter cleanly
            if (_loginMode == 2) _otpCtrl.clear();
          }
        },
        builder: (ctx, state) {
          if (state is Auth2FaRequired) {
            return isWide
                ? Row(
                    children: [
                      Expanded(flex: 5, child: Container(color: theme.colorScheme.primary)),
                      Expanded(flex: 4, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(48), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: _TwoFaChallengeWidget(state: state)))))
                    ],
                  )
                : SafeArea(
                    child: Column(
                      children: [
                        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), child: Row(children: [Container(decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: IconButton(icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary), onPressed: () => context.read<AuthCubit>().cancel2FaChallenge()),)])),
                        Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: _TwoFaChallengeWidget(state: state))))),
                      ],
                    ),
                  );
          }
          if (_otpSent) {
            final onBack = () { if (mounted) setState(() { _otpSent = false; _otpCtrl.clear(); }); };
            return isWide
                ? Row(
                    children: [
                      Expanded(flex: 5, child: Container(color: theme.colorScheme.primary)),
                      Expanded(flex: 4, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(48), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: _OtpVerifyWidget(phone: _phoneCtrl.text.trim(), onBack: onBack))))),
                    ],
                  )
                : SafeArea(
                    child: Column(
                      children: [
                        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), child: Row(children: [Container(decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: IconButton(icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary), onPressed: onBack))])),
                        Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: _OtpVerifyWidget(phone: _phoneCtrl.text.trim(), onBack: onBack))))),
                      ],
                    ),
                  );
          }
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _GridPainter(color: Colors.white.withValues(alpha: 0.05))),
                ),
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(context),
                      const Spacer(),
                      _buildStatusCard(
                        icon: Icons.verified_user,
                        title: 'AuthorizedResponder',
                        subtitle: 'Verified IRMS Personnel',
                        color: Colors.white,
                        bgColor: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusCard(
                        icon: Icons.security,
                        title: 'End-to-End Encrypted',
                        subtitle: 'Secure Communication Channel',
                        color: Colors.white70,
                        bgColor: Colors.white.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusCard(
                        icon: Icons.cell_tower,
                        title: 'Live Monitoring',
                        subtitle: 'Real-time Incident Tracking',
                        color: Colors.white70,
                        bgColor: Colors.white.withValues(alpha: 0.1),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'All Systems Operational',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
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
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBackButton(context),
                _buildOnlineIndicator(theme),
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

  Widget _buildOnlineIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Online',
            style: TextStyle(
              color: const Color(0xFF4ADE80),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
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
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
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
    return Form(
      key: _formKey,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.of(context).size.width <= 700) ...[
          Text(
            'Sign In',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Access your IRMS account',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _loginTab(theme, 0, Icons.lock_outline, 'Password'),
              _loginTab(theme, 1, Icons.sms_outlined, 'OTP'),
              _loginTab(theme, 2, Icons.pin_outlined, 'PIN'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_loginMode == 0) ...[
          _buildField(
            controller: _emailCtrl,
            label: loc.fieldEmail,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.visiblePassword,
            validator: (v) => v != null && v.contains('@') ? null : loc.validationInvalidEmail,
          ),
          const SizedBox(height: 16),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ] else if (_loginMode == 2) ...[
          if (!_hasStoredEmail) ...[
            _buildField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.visiblePassword,
              validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            obscureText: true,
            obscuringCharacter: '●',
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12),
            onChanged: (v) {
              // Auto-submit when all 4 digits are entered
              if (v.length == 4) _submit();
            },
            decoration: InputDecoration(
              hintText: '_ _ _ _',
              hintStyle: TextStyle(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                letterSpacing: 8,
                fontSize: 20,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              counterText: '',
              prefixIcon: const Icon(Icons.pin_outlined, size: 20),
            ),
          ),
        ] else ...[
          _buildField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.visiblePassword,
            validator: (v) => v != null && v.length >= 8 ? null : 'Enter a valid phone number',
          ),
        ],
        const SizedBox(height: 24),
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
                Icon(_loginMode == 1 ? Icons.sms_outlined : _loginMode == 2 ? Icons.pin_outlined : Icons.login, size: 20),
                const SizedBox(width: 8),
                Text(_loginMode == 1 ? 'Send One-Time Pin' : _loginMode == 2 ? 'Sign In with PIN' : loc.btnSignIn),
              ],
            ),
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loginBiometrics,
              icon: const Icon(Icons.fingerprint, size: 22),
              label: const Text('Sign in with Biometrics'),
            ),
          ],
        ],
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Text(
                "Don't have an account?",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    loc.btnCreateAccount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/announcements'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                'Continue as Guest',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _loginTab(ThemeData theme, int mode, IconData icon, String label) {
    final active = _loginMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _loginMode = mode;
            if (mode != 1) { _otpSent = false; }
            // Always clear _otpCtrl INSIDE setState so the PIN TextField
            // rebuilds with empty text — prevents stale 4-digit OTP content
            // from triggering an auto-submit on the PIN field.
            _otpCtrl.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
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
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const <String>[],
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
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

  Future<void> _loginBiometrics() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometrics_enabled') ?? true;
    if (!enabled) {
      if (mounted) {
        AppToast.warning(context, 'Biometric unlock is disabled in Profile Settings');
      }
      return;
    }

    final auth = LocalAuthentication();
    try {
      final canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuthenticate) {
        if (mounted) {
          AppToast.warning(context, 'Biometric hardware not available on this device');
        }
        return;
      }
      final didAuth = await auth.authenticate(
        localizedReason: 'Authenticate with Fingerprint/FaceID to log into IRMS',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuth && mounted) {
        context.read<AuthCubit>().loginWithBiometrics();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Biometric error: $e');
      }
    }
  }


  Future<void> _submit() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) return;
    if (_loginMode == 1) {
      context.read<AuthCubit>().sendOtp(phone: _phoneCtrl.text.trim());
    } else if (_loginMode == 2) {
      final pin = _otpCtrl.text.trim();
      if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
        AppToast.warning(context, 'PIN must be 4 digits');
        return;
      }
      final email = _emailCtrl.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        AppToast.warning(context, 'Please enter your email');
        return;
      }
      if (!mounted) return;
      context.read<AuthCubit>().loginWithPin(email: email, pin: pin);
    } else {
      context.read<AuthCubit>().login(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    final codeCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    int step = 1;
    bool loading = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  step == 1 ? Icons.lock_reset : Icons.mark_email_unread_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                step == 1 ? 'Reset Password' : 'Verify Code',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                step == 1
                    ? 'Enter your registered email address to receive a 6-digit password reset code.'
                    : 'We sent a verification code to ${emailCtrl.text}. Enter the code and your new password below.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (step == 1) ...[
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false, enableSuggestions: false,
                  autofillHints: const <String>[],
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false, enableSuggestions: false,
                  autofillHints: const <String>[],
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: '6-digit Verification Code',
                    prefixIcon: const Icon(Icons.password_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  autocorrect: false, enableSuggestions: false,
                  autofillHints: const <String>[],
                  decoration: InputDecoration(
                    labelText: 'New Password (min 8 chars)',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(dialogCtx),
              child: Text(loc.btnCancel),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        AppToast.warning(context, 'Please enter a valid email address.');
                        return;
                      }

                      if (step == 1) {
                        setDialogState(() => loading = true);
                        try {
                          await context.read<AuthCubit>().sendForgotPasswordOtp(email: email);
                          setDialogState(() {
                            loading = false;
                            step = 2;
                          });
                          if (context.mounted) {
                            AppToast.success(context, 'Verification code sent to your email.');
                          }
                        } catch (err) {
                          setDialogState(() => loading = false);
                          if (context.mounted) {
                            AppToast.error(context, err.toString().replaceAll('Exception: ', ''));
                          }
                        }
                      } else {
                        final code = codeCtrl.text.trim();
                        final pass = newPassCtrl.text;
                        if (code.length != 6) {
                          AppToast.warning(context, 'Please enter the 6-digit verification code.');
                          return;
                        }
                        if (pass.length < 8) {
                          AppToast.warning(context, 'Password must be at least 8 characters.');
                          return;
                        }

                        setDialogState(() => loading = true);
                        try {
                          await context.read<AuthCubit>().resetPassword(
                                email: email,
                                code: code,
                                newPassword: pass,
                              );
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            AppToast.success(context, loc.snackbarPasswordChanged);
                          }
                        } catch (err) {
                          setDialogState(() => loading = false);
                          if (context.mounted) {
                            AppToast.error(context, err.toString().replaceAll('Exception: ', ''));
                          }
                        }
                      }
                    },
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(step == 1 ? 'Send Code' : 'Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoFaChallengeWidget extends StatefulWidget {
  final Auth2FaRequired state;
  const _TwoFaChallengeWidget({required this.state});

  @override
  State<_TwoFaChallengeWidget> createState() => _TwoFaChallengeWidgetState();
}

class _TwoFaChallengeWidgetState extends State<_TwoFaChallengeWidget> {
  String _code = '';
  String? _error;
  bool _verifying = false;

  void _verify() {
    if (_code.length != 6) return;
    setState(() { _verifying = true; _error = null; });
    context.read<AuthCubit>().verify2FaChallenge(
          challengeToken: widget.state.challengeToken,
          code: _code,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_user_outlined, size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text('Two-Factor Authentication', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Enter the 6-digit code from your\nGoogle Authenticator app',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          onChanged: (v) => setState(() { _code = v.replaceAll(RegExp(r'\D'), ''); }),
          keyboardType: TextInputType.number,
          autocorrect: false, enableSuggestions: false,
          autofillHints: const <String>[],
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(color: theme.colorScheme.outline.withValues(alpha: 0.3), letterSpacing: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            counterText: '',
          ),
          onSubmitted: (_) => _verify(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (_code.length == 6 && !_verifying) ? _verify : null,
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          child: _verifying
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_open, size: 20), SizedBox(width: 8), Text('Verify & Sign In')]),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.read<AuthCubit>().cancel2FaChallenge(),
          child: Text('Cancel and go back', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
        ),
      ],
    );
  }
}

class _OtpVerifyWidget extends StatefulWidget {
  final String phone;
  final VoidCallback onBack;
  const _OtpVerifyWidget({required this.phone, required this.onBack});

  @override
  State<_OtpVerifyWidget> createState() => _OtpVerifyWidgetState();
}

class _OtpVerifyWidgetState extends State<_OtpVerifyWidget> {
  String _code = '';
  bool _verifying = false;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _resendSeconds <= 0) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    setState(() => _verifying = true);
    context.read<AuthCubit>().verifyOtp(phone: widget.phone, code: _code);
  }

  Future<void> _resend() async {
    setState(() => _resendSeconds = 60);
    _startResendTimer();
    context.read<AuthCubit>().sendOtp(phone: widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.sms_outlined, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('One-Time Pin', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                    const SizedBox(height: 2),
                    Text('Sent to ${widget.phone}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Enter the 6-digit code', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Check your phone for the verification code', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 24),
        TextField(
          onChanged: (v) => setState(() => _code = v.replaceAll(RegExp(r'\D'), '')),
          keyboardType: TextInputType.number,
          autocorrect: false, enableSuggestions: false,
          autofillHints: const <String>[],
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 12),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(color: theme.colorScheme.outline.withValues(alpha: 0.3), letterSpacing: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (_code.length == 6 && !_verifying) ? _verify : null,
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
            child: _verifying
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.login, size: 20), SizedBox(width: 8), Text('Verify & Sign In')]),
          ),
        ),
        const SizedBox(height: 16),
        if (_resendSeconds > 0)
          Text('Resend code in ${_resendSeconds}s', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)))
        else
          TextButton(
            onPressed: _resend,
            child: const Text('Resend Code', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.onBack,
          child: Text('Use password instead', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}