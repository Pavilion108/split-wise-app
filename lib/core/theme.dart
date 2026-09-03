import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const seed = Color(0xFF1565C0);
  static const received = Color(0xFF2E7D32);
  static const owed = Color(0xFFC62828);
  static const surface = Color(0xFFF8F9FC);
  static const cardBorder = Color(0xFFE8ECF1);

  // Dark mode
  static const darkSurface = Color(0xFF0F1118);
  static const darkCard = Color(0xFF1A1D2B);
  static const darkCardBorder = Color(0xFF2A2E3D);

  // Dark mode accent colors (brighter for contrast)
  static const darkReceived = Color(0xFF4CAF50);
  static const darkOwed = Color(0xFFEF5350);
  static const darkTextPrimary = Color(0xFFE8EAF0);
  static const darkTextSecondary = Color(0xFF9EA3B0);
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.light,
    surface: Colors.white,
  );
  return _buildTheme(scheme, Brightness.light);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
  );
  return _buildTheme(scheme, Brightness.dark);
}

ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
  final cardColor = isDark ? AppColors.darkCard : Colors.white;
  final borderColor =
      isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
  final inputFill = isDark ? const Color(0xFF141722) : Colors.white;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: surfaceColor,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: cardColor,
      elevation: 0,
      shadowColor: isDark ? Colors.black26 : Colors.black12,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(
        color: isDark ? AppColors.darkTextPrimary : scheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      filled: true,
      fillColor: inputFill,
      labelStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : null,
      ),
      hintStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.6) : null,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 0.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      titleTextStyle: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : scheme.onSurface,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      elevation: 2,
      shadowColor: isDark ? Colors.black26 : Colors.black12,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }
        return TextStyle(
          color: isDark ? AppColors.darkTextSecondary : scheme.outline,
          fontSize: 12,
        );
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF2A2E3D) : scheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : scheme.onInverseSurface,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.surface,
      side: BorderSide(color: borderColor),
      labelStyle: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : null,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: borderColor,
      thickness: 0.5,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : scheme.onSurface,
        fontSize: 14,
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: isDark ? AppColors.darkTextPrimary : null,
      iconColor: isDark ? AppColors.darkTextSecondary : null,
    ),
  );
}
