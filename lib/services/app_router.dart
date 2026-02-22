import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/features/auth/screens/welcome_screen.dart';
import 'package:mom_connect/features/auth/screens/login_screen.dart';
import 'package:mom_connect/features/auth/screens/register_screen.dart';
import 'package:mom_connect/features/home/screens/main_screen.dart';
import 'package:mom_connect/features/chat/screens/chat_screen.dart';
import 'package:mom_connect/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:mom_connect/features/admin/screens/admin_dashboard_screen.dart';
import 'package:mom_connect/services/app_state.dart';

// Global navigator key for navigation without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// MOMIT Central Navigation System
/// 
/// Handles all app routing with smooth animations and error handling.
/// All routes are defined as constants for type-safe navigation.
class AppRouter {
  // ════════════════════════════════════════════════════════════════
  //  ROUTE CONSTANTS
  // ════════════════════════════════════════════════════════════════
  
  // Auth routes
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Main routes
  static const String home = '/home';
  static const String feed = '/feed';
  static const String tracking = '/tracking';
  static const String events = '/events';
  static const String chat = '/chat';
  static const String aiChat = '/ai-chat';
  static const String profile = '/profile';
  static const String marketplace = '/marketplace';
  static const String groups = '/groups';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  
  // Feature routes
  static const String experts = '/experts';
  static const String tips = '/tips';
  static const String sos = '/sos';
  static const String album = '/album';
  static const String gamification = '/gamification';
  static const String whatsapp = '/whatsapp';
  static const String mood = '/mood';
  
  // Admin routes
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminConfig = '/admin/config';
  static const String adminContent = '/admin/content';
  static const String adminAudit = '/admin/audit';

  // ════════════════════════════════════════════════════════════════
  //  ROUTE GENERATION
  // ════════════════════════════════════════════════════════════════

  /// Generate routes with error handling and animations
  static Route<dynamic> generateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        // Auth routes
        case welcome:
          return _buildPageRoute(const WelcomeScreen(), settings);
        case login:
          return _buildPageRoute(const LoginScreen(), settings);
        case register:
          return _buildPageRoute(const RegisterScreen(), settings);
        
        // Main routes
        case home:
          return _buildPageRoute(const MainScreen(), settings);
        case chat:
          return _buildPageRoute(const ChatScreen(), settings);
        case aiChat:
          return _buildPageRoute(const AiChatScreen(), settings);
        case admin:
          return _buildPageRoute(
            Builder(builder: (context) {
              final appState = Provider.of<AppState>(context, listen: false);
              if (!appState.isLoggedIn || !appState.isAdmin) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed(home);
                });
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return const AdminDashboardScreen();
            }),
            settings,
          );
        
        default:
          // Log unknown routes for debugging
          debugPrint('[AppRouter] Unknown route: ${settings.name}');
          return _buildErrorRoute('העמוד לא נמצא', settings);
      }
    } catch (e, stackTrace) {
      debugPrint('[AppRouter] Error generating route: $e');
      debugPrint('[AppRouter] Stack trace: $stackTrace');
      return _buildErrorRoute('שגיאה בטעינת העמוד', settings);
    }
  }
  
  /// Build an error route for unknown routes or errors
  static Route<dynamic> _buildErrorRoute(String message, RouteSettings settings) {
    return _buildPageRoute(
      Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => navigatorKey.currentState?.pushReplacementNamed(home),
                child: const Text('חזרה לדף הבית'),
              ),
            ],
          ),
        ),
      ),
      settings,
    );
  }
  
  static PageRouteBuilder _buildPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  // ════════════════════════════════════════════════════════════════
  //  NAVIGATION HELPERS
  // ════════════════════════════════════════════════════════════════

  /// Navigate to a route with animation
  /// 
  /// [context] - BuildContext for navigation
  /// [routeName] - Target route constant
  /// [arguments] - Optional arguments to pass
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }
  
  /// Navigate without context (using global key)
  /// 
  /// [routeName] - Target route constant
  /// [arguments] - Optional arguments to pass
  static Future<T?> navigateToWithoutContext<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed<T>(routeName, arguments: arguments) ?? Future.value(null);
  }
  
  /// Navigate and replace current screen
  /// 
  /// Use this for login -> home transitions where back button
  /// should not return to login
  static Future<T?> navigateAndReplace<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, dynamic>(context, routeName, arguments: arguments);
  }
  
  /// Navigate and replace without context
  static Future<T?> navigateAndReplaceWithoutContext<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushReplacementNamed<T, dynamic>(routeName, arguments: arguments) ?? Future.value(null);
  }
  
  /// Navigate and clear all previous screens
  /// 
  /// Use this for splash -> home or logout -> login transitions
  static Future<T?> navigateAndClearAll<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil<T>(context, routeName, (route) => false, arguments: arguments);
  }
  
  /// Navigate and clear without context
  static Future<T?> navigateAndClearAllWithoutContext<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil<T>(routeName, (route) => false, arguments: arguments) ?? Future.value(null);
  }
  
  /// Go back to previous screen
  /// 
  /// Returns true if navigation was successful
  static bool goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return true;
    }
    return false;
  }
  
  /// Go back without context
  static bool goBackWithoutContext() {
    final navigator = navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return true;
    }
    return false;
  }
  
  /// Pop until a specific route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }
  
  /// Pop until without context
  static void popUntilWithoutContext(String routeName) {
    navigatorKey.currentState?.popUntil(ModalRoute.withName(routeName));
  }
  
  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}
