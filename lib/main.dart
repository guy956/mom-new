import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mom_connect/firebase_options.dart';
import 'package:mom_connect/core/theme/app_theme.dart';
import 'package:mom_connect/features/auth/screens/welcome_screen.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/app_config_provider.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/services/firestore_service.dart';
import 'package:mom_connect/services/feature_flag_service.dart';
import 'package:mom_connect/services/tracking_service.dart';
import 'package:mom_connect/services/accessibility_service.dart';
import 'package:mom_connect/services/dynamic_config_service.dart';

void main() async {
  // Catch ALL errors including async ones
  runZonedGuarded(() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show visible errors in release mode (instead of blank)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[MOMIT] Widget Error: ${details.exception}');
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'MOMIT Error: ${details.exception}',
            style: const TextStyle(color: Colors.red, fontSize: 14, fontFamily: 'Heebo'),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[MOMIT] Flutter Error: ${details.exception}');
    debugPrint('[MOMIT] Stack: ${details.stack}');
  };

  // ════════════════════════════════════════════════════════════════
  //  PHASE 1: Initialize Firebase FIRST (required by many services)
  // ════════════════════════════════════════════════════════════════

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('[MOMIT] ✓ Firebase initialized');
  } catch (e) {
    debugPrint('[MOMIT] ⚠ Firebase init warning: $e');
    debugPrint('[MOMIT] ℹ Running in offline mode with cached data');
  }

  // ════════════════════════════════════════════════════════════════
  //  PHASE 2: Initialize core services
  // ════════════════════════════════════════════════════════════════

  // Initialize AuthService with SharedPreferences (CRITICAL - must succeed)
  try {
    await AuthService.instance.initialize();
    debugPrint('[MOMIT] ✓ AuthService initialized');
  } catch (e) {
    debugPrint('[MOMIT] ⚠ AuthService init warning: $e');
    try {
      await AuthService.instance.initialize();
    } catch (e2) {
      debugPrint('[MOMIT] ⚠ AuthService second attempt: $e2');
    }
  }

  // Initialize Accessibility Service
  final a11yService = AccessibilityService();
  try {
    await a11yService.initialize();
    debugPrint('[MOMIT] ✓ AccessibilityService initialized');
  } catch (e) {
    debugPrint('[MOMIT] ⚠ AccessibilityService init warning: $e');
  }

  // Initialize AppState (restores user session, theme, counts)
  final appState = AppState();
  try {
    await appState.initialize();
    debugPrint('[MOMIT] ✓ AppState initialized');
  } catch (e) {
    debugPrint('[MOMIT] ⚠ AppState init warning: $e');
  }

  // Initialize AppConfigProvider (loads cached config for fast startup)
  final appConfigProvider = AppConfigProvider();
  try {
    await appConfigProvider.initialize();
    debugPrint('[MOMIT] ✓ AppConfigProvider initialized');
  } catch (e) {
    debugPrint('[MOMIT] ⚠ AppConfigProvider init warning: $e');
  }

  // Initialize Hive for tracking data
  try {
    await Hive.initFlutter();
    debugPrint('[MOMIT] ✓ Hive initialized');
  } catch (e) {
    debugPrint('[MOMIT] ⚠ Hive init warning: $e');
  }

  // ════════════════════════════════════════════════════════════════
  //  PHASE 3: Initialize Firestore services and connect real-time sync
  // ════════════════════════════════════════════════════════════════

  FirestoreService? firestoreService;
  FeatureFlagService? featureFlagService;

  if (firebaseReady) {
    try {
      // Initialize FirestoreService (seed runs after admin login, not at startup)
      firestoreService = FirestoreService();
      debugPrint('[MOMIT] ✓ FirestoreService initialized');

      // Initialize FeatureFlagService
      featureFlagService = FeatureFlagService();
      await featureFlagService.initialize();
      // Enable real-time updates for feature flags
      featureFlagService.enableRealtimeUpdates();
      debugPrint('[MOMIT] ✓ FeatureFlagService initialized');

      // Connect AppState to Firestore (legacy connection for backwards compatibility)
      appState.connectToFirestore(firestoreService);
      debugPrint('[MOMIT] ✓ AppState connected to Firestore');

      // Connect AppConfigProvider to Firestore (real-time sync)
      appConfigProvider.connectToFirestore();
      debugPrint('[MOMIT] ✓ AppConfigProvider connected to Firestore real-time streams');

    } catch (e) {
      debugPrint('[MOMIT] ⚠ Firestore init warning: $e');
      debugPrint('[MOMIT] ℹ Running in offline mode with cached data');
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  PHASE 4: Run app with all providers
  // ════════════════════════════════════════════════════════════════

  runApp(
    MultiProvider(
      providers: [
        // Core state providers
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: appConfigProvider),
        
        // Service providers
        if (firestoreService != null)
          ChangeNotifierProvider.value(value: firestoreService)
        else
          ChangeNotifierProvider(create: (_) => FirestoreService()),
        
        if (featureFlagService != null)
          ChangeNotifierProvider.value(value: featureFlagService)
        else
          ChangeNotifierProvider(create: (_) => FeatureFlagService()),
        
        ChangeNotifierProvider(create: (_) => DynamicConfigService.instance),
        ChangeNotifierProvider(create: (_) => TrackingService()),
        ChangeNotifierProvider.value(value: a11yService),
      ],
      child: const MomitApp(),
    ),
  );
  }, (error, stack) {
    debugPrint('[MOMIT] Uncaught zone error: $error');
    debugPrint('[MOMIT] Stack: $stack');
  });
}

/// Main MOMIT Application Widget
/// 
/// Uses Consumer to listen to multiple providers and rebuild accordingly:
/// - AppState: theme, user session
/// - AppConfigProvider: dynamic configuration (colors, text, features)
/// - AccessibilityService: accessibility settings
class MomitApp extends StatelessWidget {
  const MomitApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to all configuration providers
    return Consumer3<AppState, AppConfigProvider, AccessibilityService>(
      builder: (context, appState, appConfig, a11y, child) {
        // Build theme with dynamic colors from AppConfigProvider
        ThemeData effectiveTheme = _buildThemeWithDynamicColors(
          AppTheme.lightTheme,
          appConfig,
          a11y,
        );
        
        ThemeData effectiveDarkTheme = _buildThemeWithDynamicColors(
          AppTheme.darkTheme,
          appConfig,
          a11y,
        );
        
        // Apply accessibility settings
        effectiveTheme = _applyAccessibilitySettings(effectiveTheme, a11y);
        
        return MaterialApp(
          // Dynamic app name from Firestore
          title: appConfig.appName,
          debugShowCheckedModeBanner: false,
          
          // Theme with dynamic colors
          theme: effectiveTheme,
          darkTheme: effectiveDarkTheme,
          themeMode: appState.themeMode,
          
          // Apply accessibility font scaling
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(a11y.fontScale),
                boldText: a11y.boldText || mediaQuery.boldText,
                disableAnimations: a11y.reduceMotion || mediaQuery.disableAnimations,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          
          // RTL Support for Hebrew
          locale: const Locale('he', 'IL'),
          supportedLocales: const [
            Locale('he', 'IL'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
          // Home Screen
          home: const WelcomeScreen(),
        );
      },
    );
  }

  /// Build theme with dynamic colors from Firestore config
  ThemeData _buildThemeWithDynamicColors(
    ThemeData baseTheme,
    AppConfigProvider config,
    AccessibilityService a11y,
  ) {
    // Parse colors from config
    final primaryColor = _parseColor(config.primaryColor, const Color(0xFFD4A1AC));
    final secondaryColor = _parseColor(config.secondaryColor, const Color(0xFFEDD3D8));
    final accentColor = _parseColor(config.accentColor, const Color(0xFFDBC8B0));
    
    // Create color scheme
    final colorScheme = baseTheme.colorScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
    );
    
    // Build updated theme
    var theme = baseTheme.copyWith(
      colorScheme: colorScheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: _parseColor(config.backgroundColor, baseTheme.scaffoldBackgroundColor),
    );
    
    // Apply high contrast if enabled
    if (a11y.highContrast) {
      theme = theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: const Color(0xFF8B1A4A),
          onSurface: const Color(0xFF000000),
          onSurfaceVariant: const Color(0xFF1A1A1A),
        ),
        textTheme: theme.textTheme.apply(
          bodyColor: const Color(0xFF000000),
          displayColor: const Color(0xFF000000),
        ),
      );
    }
    
    return theme;
  }

  /// Apply accessibility settings to theme
  ThemeData _applyAccessibilitySettings(ThemeData theme, AccessibilityService a11y) {
    if (a11y.boldText) {
      final baseTextTheme = theme.textTheme;
      return theme.copyWith(
        textTheme: baseTextTheme.copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900),
          displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900),
          displaySmall: baseTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: baseTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          bodySmall: baseTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }
    
    return theme;
  }

  /// Parse hex color string to Color
  Color _parseColor(String? value, Color fallback) {
    if (value == null || value.isEmpty) return fallback;
    
    String colorString = value;
    
    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
      
      if (colorString.length == 6) {
        final hex = int.tryParse(colorString, radix: 16);
        if (hex != null) {
          return Color(0xFF000000 + hex);
        }
      }
      
      if (colorString.length == 8) {
        final hex = int.tryParse(colorString, radix: 16);
        if (hex != null) {
          return Color(hex);
        }
      }
    }
    
    return fallback;
  }
}
