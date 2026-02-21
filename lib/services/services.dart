/// MOMIT Services Library
/// 
/// This library exports all services for the MOMIT application.
/// Each service is a singleton that can be accessed via `.instance` or `.()`.
/// 
/// ## Usage
/// ```dart
/// import 'package:mom_connect/services/services.dart';
/// 
/// // Access services
/// final authService = AuthService.instance;
/// final firestoreService = FirestoreService();
/// ```

// ════════════════════════════════════════════════════════════════
//  CORE SERVICES
// ════════════════════════════════════════════════════════════════

export 'accessibility_service.dart';
export 'app_config_provider.dart';
export 'app_router.dart';
export 'app_state.dart';

// ════════════════════════════════════════════════════════════════
//  AUTHENTICATION & SECURITY
// ════════════════════════════════════════════════════════════════

export 'auth_service.dart';
export 'secure_api_client.dart';
export 'secure_cookie_manager.dart';
// secure_cookie_manager_web.dart is conditionally exported via auth_service.dart

// ════════════════════════════════════════════════════════════════
//  FIREBASE & DATA
// ════════════════════════════════════════════════════════════════

export 'firestore_service.dart';
export 'dynamic_config_service.dart';
export 'branding_config_service.dart';

// ════════════════════════════════════════════════════════════════
//  ADMIN & AUDIT
// ════════════════════════════════════════════════════════════════

export 'audit_log_service.dart';
export 'rbac_service.dart';

// ════════════════════════════════════════════════════════════════
//  USER FEATURES
// ════════════════════════════════════════════════════════════════

export 'tracking_service.dart';

// ════════════════════════════════════════════════════════════════
//  SERVICE INITIALIZATION HELPER
// ════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'app_config_provider.dart';
import 'app_state.dart';
import 'branding_config_service.dart';
import 'firestore_service.dart';
import 'secure_api_client.dart';

/// Helper class to initialize all services in the correct order
/// 
/// Call [Services.initialize()] at app startup before runApp()
class Services {
  static bool _initialized = false;
  
  /// Initialize all services
  /// 
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[Services] Already initialized');
      return;
    }
    
    debugPrint('[Services] Initializing all services...');
    
    // 1. Initialize AuthService (handles JWT, secure storage)
    await AuthService.instance.initialize();
    debugPrint('[Services] ✓ AuthService initialized');
    
    // 2. Initialize SecureApiClient
    await SecureApiClient.instance.initialize();
    debugPrint('[Services] ✓ SecureApiClient initialized');
    
    // 3. Initialize BrandingConfigService
    await BrandingConfigService.instance.initialize();
    debugPrint('[Services] ✓ BrandingConfigService initialized');
    
    // 4. Initialize AppState (local persistence)
    // Note: AppState requires a Provider context, so we create a temporary instance
    final appState = AppState();
    await appState.initialize();
    debugPrint('[Services] ✓ AppState initialized');
    
    // 5. Initialize AppConfigProvider (local persistence)
    await AppConfigProvider().initialize();
    debugPrint('[Services] ✓ AppConfigProvider initialized');
    
    _initialized = true;
    debugPrint('[Services] All services initialized successfully');
  }
  
  /// Connect to Firestore for real-time sync
  /// 
  /// Call this after Firebase.initializeApp() is complete
  static void connectFirestore(FirestoreService firestoreService) {
    // Connect AppState to Firestore
    final appState = AppState();
    appState.connectToFirestore(firestoreService);
    debugPrint('[Services] ✓ AppState connected to Firestore');
    
    // Connect AppConfigProvider to Firestore
    AppConfigProvider().connectToFirestore();
    debugPrint('[Services] ✓ AppConfigProvider connected to Firestore');
    
    // BrandingConfigService connects automatically in initialize()
    debugPrint('[Services] ✓ BrandingConfigService connected to Firestore');
  }
  
  /// Check if services are initialized
  static bool get isInitialized => _initialized;
  
  /// Dispose all services
  /// 
  /// Call this on app shutdown or logout
  static void dispose() {
    debugPrint('[Services] Disposing all services...');
    
    SecureApiClient.instance.dispose();
    BrandingConfigService.instance.dispose();
    // AuthService doesn't need disposal
    // AppState disposal is handled by Provider
    // AppConfigProvider disposal is handled by Provider
    
    _initialized = false;
    debugPrint('[Services] All services disposed');
  }
}
