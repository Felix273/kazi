import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// Consistent spacing values used throughout Kazi.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double section = 48;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets card = EdgeInsets.all(md);
}

/// Consistent corner radii used throughout Kazi.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

/// Shared animation durations.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
}

/// Kazi's single source of truth for branding and Material 3 styling.
abstract final class AppTheme {
  // Primary brand palette.
  static const Color primaryGreen = Color(0xFF12664F);
  static const Color primaryGreenDark = Color(0xFF084C3B);
  static const Color primaryGreenLight = Color(0xFFD9F3E8);

  static const Color accentGold = Color(0xFFF2B84B);
  static const Color accentGoldLight = Color(0xFFFFF1CF);

  static const Color teal = Color(0xFF167C80);
  static const Color blue = Color(0xFF3467D6);

  // Semantic palette.
  static const Color success = Color(0xFF16835B);
  static const Color warning = Color(0xFFB86A00);
  static const Color error = Color(0xFFBA1A1A);
  static const Color info = Color(0xFF2864C7);

  // Light surfaces.
  static const Color backgroundLight = Color(0xFFF6F8F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFEEF2F0);
  static const Color ink = Color(0xFF17201D);
  static const Color inkMuted = Color(0xFF5D6965);
  static const Color outlineLight = Color(0xFFD8E0DC);

  // Dark surfaces.
  static const Color backgroundDark = Color(0xFF0C1411);
  static const Color surfaceDark = Color(0xFF121D19);
  static const Color surfaceMutedDark = Color(0xFF1C2924);
  static const Color outlineDark = Color(0xFF384A43);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static List<BoxShadow> softShadow(Brightness brightness) {
    return [
      BoxShadow(
        color: brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.28)
            : const Color(0xFF18251F).withValues(alpha: 0.07),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFF78D8B5) : primaryGreen,
          onPrimary: isDark ? const Color(0xFF00382A) : Colors.white,
          primaryContainer: isDark
              ? const Color(0xFF07513D)
              : primaryGreenLight,
          onPrimaryContainer: isDark
              ? const Color(0xFFA0F4D0)
              : primaryGreenDark,
          secondary: isDark ? const Color(0xFFFFD17A) : accentGold,
          onSecondary: const Color(0xFF3E2D00),
          secondaryContainer: isDark
              ? const Color(0xFF5B4300)
              : accentGoldLight,
          onSecondaryContainer: isDark
              ? const Color(0xFFFFE2A8)
              : const Color(0xFF4B3600),
          tertiary: isDark ? const Color(0xFF72D4D6) : teal,
          onTertiary: isDark ? const Color(0xFF003738) : Colors.white,
          tertiaryContainer: isDark
              ? const Color(0xFF004F51)
              : const Color(0xFFD0F0F1),
          onTertiaryContainer: isDark
              ? const Color(0xFF90F1F3)
              : const Color(0xFF003738),
          error: isDark ? const Color(0xFFFFB4AB) : error,
          onError: isDark ? const Color(0xFF690005) : Colors.white,
          errorContainer: isDark
              ? const Color(0xFF93000A)
              : const Color(0xFFFFDAD6),
          onErrorContainer: isDark
              ? const Color(0xFFFFDAD6)
              : const Color(0xFF410002),
          surface: isDark ? surfaceDark : surfaceLight,
          onSurface: isDark ? const Color(0xFFE1E9E5) : ink,
          outline: isDark ? const Color(0xFF85948E) : const Color(0xFF71807A),
          outlineVariant: isDark ? outlineDark : outlineLight,
          shadow: Colors.black,
          scrim: Colors.black,
        );

    final textTheme = GoogleFonts.manropeTextTheme(_textTheme(scheme));
    final fieldFill = isDark ? surfaceMutedDark : surfaceLight;
    final cardBorder = scheme.outlineVariant.withValues(
      alpha: isDark ? 0.65 : 0.85,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: GoogleFonts.manrope().fontFamily,
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      canvasColor: isDark ? backgroundDark : backgroundLight,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 17,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: inkMuted),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: _inputBorder(cardBorder),
        enabledBorder: _inputBorder(cardBorder),
        focusedBorder: _inputBorder(scheme.primary, width: 1.6),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.6),
        disabledBorder: _inputBorder(
          scheme.outlineVariant.withValues(alpha: 0.55),
        ),
        errorMaxLines: 2,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: scheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: cardBorder),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 24 : 23,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surfaceMutedDark : surfaceMutedLight,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.onSurface.withValues(alpha: 0.08),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        showCheckmark: false,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        minTileHeight: 56,
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 8,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFFE1E9E5)
            : const Color(0xFF24312C),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? const Color(0xFF17201D) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: isDark ? primaryGreenDark : const Color(0xFFA8E9CF),
        elevation: 4,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFE1E9E5) : const Color(0xFF24312C),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: isDark ? const Color(0xFF17201D) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.22),
        selectionHandleColor: scheme.primary,
      ),

      dividerColor: scheme.outlineVariant,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: 48,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
      ),
      displayMedium: const TextStyle(
        fontSize: 40,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      displaySmall: const TextStyle(
        fontSize: 34,
        height: 1.16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineLarge: const TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      headlineMedium: const TextStyle(
        fontSize: 26,
        height: 1.24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
      headlineSmall: const TextStyle(
        fontSize: 23,
        height: 1.28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        height: 1.32,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: const TextStyle(
        fontSize: 16.5,
        height: 1.38,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: const TextStyle(
        fontSize: 14.5,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.52,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14.5,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: const TextStyle(
        fontSize: 12.5,
        height: 1.46,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
      labelMedium: const TextStyle(
        fontSize: 12.5,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
      labelSmall: const TextStyle(
        fontSize: 11.5,
        height: 1.25,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
