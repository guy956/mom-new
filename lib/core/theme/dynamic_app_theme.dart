import 'package:flutter/material.dart';
import 'package:mom_connect/providers/theme_provider.dart';

/// MOMIT Dynamic Theme - Uses ThemeProvider for real-time color updates
/// All colors are loaded from Firestore and update immediately when changed
class DynamicAppTheme {
  DynamicAppTheme._();

  // ===== Light Theme - Dynamic Colors =====
  static ThemeData lightTheme(ThemeProvider theme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: theme.lightColorScheme,

      scaffoldBackgroundColor: theme.background,

      // AppBar - Dynamic Colors
      appBarTheme: AppBarTheme(
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        iconTheme: IconThemeData(color: theme.textPrimary, size: 24),
      ),

      // Cards - Dynamic Colors
      cardTheme: CardThemeData(
        color: theme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.border.withValues(alpha: 0.5), width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Elevated Buttons - Dynamic Primary Color
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.textOnPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Heebo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Buttons - Dynamic Primary Color
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          side: BorderSide(color: theme.primary, width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Heebo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text Buttons - Dynamic Primary Color
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: theme.primary,
          textStyle: const TextStyle(
            fontFamily: 'Heebo',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // FAB - Dynamic Primary Color
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: theme.primary,
        foregroundColor: theme.textOnPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      ),

      // Input Fields - Dynamic Colors
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.border.withValues(alpha: 0.7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.primary, width: 2.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.error, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Heebo',
          color: theme.textHint,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Heebo',
          color: theme.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Chips - Dynamic Colors
      chipTheme: ChipThemeData(
        backgroundColor: theme.surfaceVariant,
        selectedColor: theme.primary,
        labelStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 13,
          color: theme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 13,
          color: theme.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        side: BorderSide(color: theme.border.withValues(alpha: 0.4)),
      ),

      // Bottom Navigation - Dynamic Primary Color
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: theme.surface,
        selectedItemColor: theme.primary,
        unselectedItemColor: theme.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Navigation Bar - Dynamic Colors
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: theme.surface,
        indicatorColor: theme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: 'Heebo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.primary,
            );
          }
          return TextStyle(
            fontFamily: 'Heebo',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.textHint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: theme.primary, size: 24);
          }
          return IconThemeData(color: theme.textHint, size: 24);
        }),
      ),

      // Tab Bar - Dynamic Primary Color
      tabBarTheme: TabBarThemeData(
        labelColor: theme.primary,
        unselectedLabelColor: theme.textHint,
        indicatorColor: theme.primary,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Heebo',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Dialogs - Dynamic Colors
      dialogTheme: DialogThemeData(
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          letterSpacing: -0.3,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 15,
          color: theme.textSecondary,
          height: 1.5,
        ),
      ),

      // Snackbar - Dynamic Colors
      snackBarTheme: SnackBarThemeData(
        backgroundColor: theme.textPrimary,
        contentTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // Divider - Dynamic Color
      dividerTheme: DividerThemeData(
        color: theme.divider,
        thickness: 0.8,
        space: 0.8,
      ),

      // Typography - Heebo with Dynamic Colors
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: theme.textPrimary,
          letterSpacing: -0.6,
          height: 1.12,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          letterSpacing: -0.5,
          height: 1.12,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          letterSpacing: -0.4,
          height: 1.15,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 23,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: theme.textPrimary,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: theme.textPrimary,
          letterSpacing: -0.2,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: theme.textPrimary,
          letterSpacing: -0.1,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.textPrimary,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: theme.textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: theme.textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.textSecondary,
          letterSpacing: 0.1,
        ),
      ),

      // Icon Theme - Dynamic Colors
      iconTheme: IconThemeData(
        color: theme.textSecondary,
        size: 22,
      ),

      // List Tile - Dynamic Colors
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        iconColor: theme.textSecondary,
        textColor: theme.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // Switch - Dynamic Primary Color
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return theme.primary;
          return theme.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return theme.primary.withValues(alpha: 0.3);
          }
          return theme.border;
        }),
      ),

      // Checkbox - Dynamic Primary Color
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return theme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: theme.border, width: 1.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),

      // Bottom Sheet - Dynamic Colors
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: theme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Progress Indicator - Dynamic Primary Color
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: theme.primary,
        linearTrackColor: theme.surfaceVariant,
      ),
    );
  }

  // ===== Dark Theme - Dynamic Colors =====
  static ThemeData darkTheme(ThemeProvider theme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: theme.darkColorScheme,

      scaffoldBackgroundColor: theme.darkBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: theme.darkSurface,
        foregroundColor: theme.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: theme.darkTextPrimary,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: theme.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryLight,
          foregroundColor: theme.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.darkSurface.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.primaryLight, width: 2),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: theme.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 16,
          color: theme.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Heebo',
          fontSize: 14,
          color: theme.darkTextSecondary,
        ),
      ),
    );
  }
}
