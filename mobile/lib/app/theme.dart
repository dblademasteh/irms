import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class _TextScale {
  const _TextScale();

  double get displayLarge  => 32;
  double get displayMedium => 28;
  double get displaySmall  => 24;
  double get headlineLarge  => 24;
  double get headlineMedium => 20;
  double get headlineSmall  => 18;
  double get titleLarge     => 20;
  double get titleMedium    => 16;
  double get titleSmall     => 14;
  double get bodyLarge      => 16;
  double get bodyMedium     => 14;
  double get bodySmall      => 12;
  double get labelLarge     => 14;
  double get labelMedium    => 12;
  double get labelSmall     => 11;L
}

class IrmsColors {
  IrmsColors._();

  // Brand & UI
  static const primary       = Color(0xFF059669);
  static const primaryDark   = Color(0xFF10B981);
  static const primaryLight  = Color(0xFF34D399);
  static const accent        = Color(0xFF2563EB);
  static const accentDark    = Color(0xFF3B82F6);

  // Status
  static const success       = Color(0xFF16A34A);
  static const successDark   = Color(0xFF4ADE80);
  static const successBg     = Color(0xFFDCFCE7);
  static const successBgDark = Color(0xFF14532D);

  static const warning       = Color(0xFFD97706);
  static const warningDark   = Color(0xFFFBBF24);
  static const warningBg     = Color(0xFFFEF3C7);
  static const warningBgDark = Color(0xFF78350F);

  static const error         = Color(0xFFDC2626);
  static const errorDark     = Color(0xFFF87171);
  static const errorBg       = Color(0xFFFEE2E2);
  static const errorBgDark   = Color(0xFF7F1D1D);

  static const info          = Color(0xFF2563EB);
  static const infoDark      = Color(0xFF60A5FA);
  static const infoBg        = Color(0xFFDBEAFE);
  static const infoBgDark    = Color(0xFF1E3A8A);

  static const rejected      = Color(0xFFDC2626);
  static const rejectedDark  = Color(0xFFF87171);

  static const pending       = Color(0xFFD97706);
  static const pendingDark   = Color(0xFFFBBF24);

  static const critical      = Color(0xFFDC2626);
  static const criticalDark  = Color(0xFFF87171);

  // Neutrals
  static const surface       = Color(0xFFFFFFFF);
  static const surfaceDark   = Color(0xFF111827);
  static const bg           = Color(0xFFF8FAFC);
  static const bgDark       = Color(0xFF0B0F19);
  static const fg           = Color(0xFF0F172A);
  static const border       = Color(0xFFE2E8F0);
  static const borderDark   = Color(0xFF1F2937);
  static const mutedText    = Color(0xFF64748B);
  static const mutedTextDark = Color(0xFF94A3B8);
}

class _StatusColors {
  final Color light;
  final Color dark;
  final Color lightBg;
  final Color darkBg;

  const _StatusColors({
    required this.light,
    required this.dark,
    required this.lightBg,
    required this.darkBg,
  });
}

class IrmsStatusColors {
  const IrmsStatusColors._();

  static const verified  = _StatusColors(
    light: Color(0xFF16A34A), dark: Color(0xFF4ADE80),
    lightBg: Color(0xFFDCFCE7), darkBg: Color(0xFF14532D),
  );
  static const resolved = _StatusColors(
    light: Color(0xFF16A34A), dark: Color(0xFF4ADE80),
    lightBg: Color(0xFFDCFCE7), darkBg: Color(0xFF14532D),
  );
  static const rejected = _StatusColors(
    light: Color(0xFFDC2626), dark: Color(0xFFF87171),
    lightBg: Color(0xFFFEE2E2), darkBg: Color(0xFF7F1D1D),
  );
  static const pending  = _StatusColors(
    light: Color(0xFFD97706), dark: Color(0xFFFBBF24),
    lightBg: Color(0xFFFEF3C7), darkBg: Color(0xFF78350F),
  );
  static const underReview = _StatusColors(
    light: Color(0xFF2563EB), dark: Color(0xFF60A5FA),
    lightBg: Color(0xFFDBEAFE), darkBg: Color(0xFF1E3A8A),
  );
  static const submitted = _StatusColors(
    light: Color(0xFF64748B), dark: Color(0xFF94A3B8),
    lightBg: Color(0xFFF1F5F9), darkBg: Color(0xFF1E293B),
  );
  static const criticalStatus = _StatusColors(
    light: Color(0xFFDC2626), dark: Color(0xFFF87171),
    lightBg: Color(0xFFFEE2E2), darkBg: Color(0xFF7F1D1D),
  );
  static const fire      = _StatusColors(
    light: Color(0xFFDC2626), dark: Color(0xFFF87171),
    lightBg: Color(0xFFFEE2E2), darkBg: Color(0xFF7F1D1D),
  );
  static const medical   = _StatusColors(
    light: Color(0xFFDC2626), dark: Color(0xFFF87171),
    lightBg: Color(0xFFFEE2E2), darkBg: Color(0xFF7F1D1D),
  );
  static const defaultType = _StatusColors(
    light: Color(0xFF2563EB), dark: Color(0xFF60A5FA),
    lightBg: Color(0xFFDBEAFE), darkBg: Color(0xFF1E3A8A),
  );
  static const availableUnit = _StatusColors(
    light: Color(0xFF16A34A), dark: Color(0xFF4ADE80),
    lightBg: Color(0xFFDCFCE7), darkBg: Color(0xFF14532D),
  );
  static const dispatchedUnit = _StatusColors(
    light: Color(0xFF7C3AED), dark: Color(0xFFA78BFA),
    lightBg: Color(0xFFEDE9FE), darkBg: Color(0xFF3B0764),
  );
  static const maintenanceUnit = _StatusColors(
    light: Color(0xFFD97706), dark: Color(0xFFFBBF24),
    lightBg: Color(0xFFFEF3C7), darkBg: Color(0xFF78350F),
  );

  static Color resolve(String key, bool isDark) {
    return switch (key.toLowerCase()) {
      'verified' || 'resolved' => isDark ? verified.dark : verified.light,
      'rejected'                => isDark ? rejected.dark : rejected.light,
      'pending' || 'submitted'  => isDark ? pending.dark : pending.light,
      'under_review'            => isDark ? underReview.dark : underReview.light,
      'fire' || 'medical'       => isDark ? fire.dark : fire.light,
      'critical'                => isDark ? criticalStatus.dark : criticalStatus.light,
      'available'               => isDark ? availableUnit.dark : availableUnit.light,
      'dispatched'              => isDark ? dispatchedUnit.dark : dispatchedUnit.light,
      'maintenance'            => isDark ? maintenanceUnit.dark : maintenanceUnit.light,
      _                         => isDark ? defaultType.dark : defaultType.light,
    };
  }

  static Color resolveBg(String key, bool isDark) {
    return switch (key.toLowerCase()) {
      'verified' || 'resolved' => isDark ? verified.darkBg : verified.lightBg,
      'rejected'               => isDark ? rejected.darkBg : rejected.lightBg,
      'pending' || 'submitted'  => isDark ? pending.darkBg : pending.lightBg,
      'under_review'           => isDark ? underReview.darkBg : underReview.lightBg,
      'fire' || 'medical'      => isDark ? fire.darkBg : fire.lightBg,
      'critical'               => isDark ? criticalStatus.darkBg : criticalStatus.lightBg,
      _                        => isDark ? defaultType.darkBg : defaultType.lightBg,
    };
  }
}

class IrmsTheme {
  IrmsTheme._();

  static const _textScale = _TextScale();

  static TextTheme _textTheme(Brightness brightness) {
    final fg = brightness == Brightness.light ? IrmsColors.fg : Colors.white;
    return GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge:  TextStyle(color: fg, fontSize: _textScale.displayLarge,  fontWeight: FontWeight.w900),
        displayMedium: TextStyle(color: fg, fontSize: _textScale.displayMedium, fontWeight: FontWeight.w800),
        displaySmall:  TextStyle(color: fg, fontSize: _textScale.displaySmall,  fontWeight: FontWeight.w800),
        headlineLarge:  TextStyle(color: fg, fontSize: _textScale.headlineLarge,  fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: fg, fontSize: _textScale.headlineMedium, fontWeight: FontWeight.w700),
        headlineSmall:  TextStyle(color: fg, fontSize: _textScale.headlineSmall,  fontWeight: FontWeight.w700),
        titleLarge:     TextStyle(color: fg, fontSize: _textScale.titleLarge,     fontWeight: FontWeight.w600),
        titleMedium:    TextStyle(color: fg, fontSize: _textScale.titleMedium,    fontWeight: FontWeight.w600),
        titleSmall:     TextStyle(color: fg, fontSize: _textScale.titleSmall,     fontWeight: FontWeight.w600),
        bodyLarge:      TextStyle(color: fg, fontSize: _textScale.bodyLarge,      fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium:     TextStyle(color: fg, fontSize: _textScale.bodyMedium,     fontWeight: FontWeight.w400, height: 1.5),
        bodySmall:      TextStyle(color: fg.withValues(alpha: 0.6), fontSize: _textScale.bodySmall, fontWeight: FontWeight.w400),
        labelLarge:     TextStyle(color: fg, fontSize: _textScale.labelLarge,     fontWeight: FontWeight.w600),
        labelMedium:    TextStyle(color: fg, fontSize: _textScale.labelMedium,    fontWeight: FontWeight.w600),
        labelSmall:     TextStyle(color: fg, fontSize: _textScale.labelSmall,     fontWeight: FontWeight.w700),
      ),
    );
  }

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: IrmsColors.primary,
      onPrimary: Colors.white,
      secondary: IrmsColors.accent,
      onSecondary: Colors.white,
      surface: IrmsColors.surface,
      onSurface: IrmsColors.fg,
      error: IrmsColors.error,
      onError: Colors.white,
      outline: IrmsColors.border,
    ),
    scaffoldBackgroundColor: IrmsColors.bg,
    textTheme: _textTheme(Brightness.light),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: IrmsColors.surface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      shape: const Border(bottom: BorderSide(color: IrmsColors.border, width: 1)),
      foregroundColor: IrmsColors.fg,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: _textScale.titleMedium,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: IrmsColors.fg,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: IrmsColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: IrmsColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: IrmsColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: IrmsColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: IrmsColors.error)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: IrmsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: IrmsColors.border)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: IrmsColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: 'Outfit', fontSize: _textScale.bodyLarge, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: IrmsColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: IrmsColors.primary.withValues(alpha: 0.3),
        textStyle: TextStyle(fontFamily: 'Outfit', fontSize: _textScale.bodyLarge, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: BorderSide(color: IrmsColors.border.withValues(alpha: 0.8), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: 'Outfit', fontSize: _textScale.bodyLarge, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        foregroundColor: IrmsColors.fg,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: _textScale.bodyMedium),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: IrmsColors.surface,
      indicatorColor: IrmsColors.primary.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontFamily: 'Outfit', fontSize: _textScale.labelMedium, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: IrmsColors.fg,
      contentTextStyle: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: IrmsColors.primaryDark,
      onPrimary: Colors.white,
      secondary: IrmsColors.accentDark,
      onSecondary: Colors.white,
      surface: IrmsColors.surfaceDark,
      onSurface: Colors.white,
      error: IrmsColors.errorDark,
      onError: Colors.white,
      outline: IrmsColors.borderDark,
    ),
    scaffoldBackgroundColor: IrmsColors.bgDark,
    textTheme: _textTheme(Brightness.dark),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: IrmsColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      shape: const Border(bottom: BorderSide(color: IrmsColors.borderDark, width: 1)),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: _textScale.titleMedium,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: IrmsColors.surfaceDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: IrmsColors.borderDark)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: IrmsColors.borderDark)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: IrmsColors.primaryDark, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: IrmsColors.errorDark)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: IrmsColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: IrmsColors.borderDark)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: IrmsColors.primaryDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: 'Outfit', fontSize: _textScale.bodyLarge, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: IrmsColors.primaryDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: IrmsColors.primaryDark.withValues(alpha: 0.3),
        textStyle: TextStyle(fontFamily: 'Outfit', fontSize: _textScale.bodyLarge, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: BorderSide(color: IrmsColors.borderDark.withValues(alpha: 0.8), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: 'Outfit', fontSize: _textScale.bodyLarge, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: _textScale.bodyMedium),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: IrmsColors.surfaceDark,
      indicatorColor: IrmsColors.primaryDark.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontFamily: 'Outfit', fontSize: _textScale.labelMedium, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(fontFamily: 'Outfit', color: IrmsColors.fg, fontWeight: FontWeight.w600, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class IrmsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final Color? backgroundColor;

  const IrmsAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBack = false,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.12 : 0.06),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: theme.colorScheme.onSurface),
                  padding: const EdgeInsets.only(right: 4),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (leading != null) leading!,
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}