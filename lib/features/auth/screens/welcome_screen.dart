import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/constants/color_config.dart';
import 'package:mom_connect/core/constants/text_config.dart';
import 'package:mom_connect/features/auth/screens/login_screen.dart';
import 'package:mom_connect/features/auth/screens/register_screen.dart';
import 'package:mom_connect/features/home/screens/main_screen.dart';
import 'package:mom_connect/features/auth/screens/intro_splash_screen.dart';
import 'package:mom_connect/features/admin/screens/admin_dashboard_screen.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Check for saved session (auto-login)
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    try {
      // Timeout safety: never hang more than 4 seconds
      await Future.any([
        _doSessionCheck(),
        Future.delayed(const Duration(seconds: 4)),
      ]);
    } catch (e) {
      debugPrint('[WelcomeScreen] Session check error: $e');
    }

    // Always show welcome screen if we're still here
    if (mounted && _isCheckingSession) {
      setState(() => _isCheckingSession = false);
      _animationController.forward();
    }
  }

  Future<void> _doSessionCheck() async {
    // AuthService already initialized in main.dart Phase 2 (idempotent - safe if called again)
    final savedSession = await AuthService.instance.getSavedSession();

    if (!mounted) return;

    if (savedSession != null) {
      final isAdmin = savedSession['isAdmin'] == true;
      if (isAdmin) {
        context.read<AppState>().loginAsAdmin(savedSession['email'] ?? '');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
        return;
      } else {
        final userModel = AuthService.instance.userModelFromData(savedSession);
        context.read<AppState>().setUser(userModel);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
        return;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    
    final result = await AuthService.instance.signInWithGoogle();

    if (!mounted) return;

    if (result.isSuccess && result.userData != null) {
      final userData = result.userData!;
      final isAdmin = userData['isAdmin'] == true;

      if (isAdmin) {
        context.read<AppState>().loginAsAdmin(userData['email'] ?? '');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      } else {
        final userModel = AuthService.instance.userModelFromData(userData);
        context.read<AppState>().setUser(userModel);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u05d1\u05e8\u05d5\u05db\u05d4 \u05d4\u05d1\u05d0\u05d4, ${userData['fullName']}!', style: const TextStyle(fontFamily: 'Heebo')),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => IntroSplashScreen(userName: userData['fullName'] ?? '')),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(result.errorMessage ?? '\u05d4\u05ea\u05d7\u05d1\u05e8\u05d5\u05ea \u05e2\u05dd Google \u05d6\u05de\u05d9\u05e0\u05d4 \u05e8\u05e7 \u05d1\u05d0\u05e4\u05dc\u05d9\u05e7\u05e6\u05d9\u05d4', style: const TextStyle(fontFamily: 'Heebo'))),
            ],
          ),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: ColorConfig.primary),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorConfig.primarySoft,
              ColorConfig.background,
              ColorConfig.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: _buildHeroSection(),
              ),
              Expanded(
                flex: 2,
                child: _buildActionSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Name
                  Text(
                    TextConfig.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Slogan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      TextConfig.slogan,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    TextConfig.welcomeDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Features Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureChipIcon(Icons.people_outline_rounded, 'קהילה'),
                    const SizedBox(width: 12),
                    _buildFeatureChipIcon(Icons.chat_bubble_outline_rounded, 'שיחות'),
                    const SizedBox(width: 12),
                    _buildFeatureChipIcon(Icons.event_outlined, 'אירועים'),
                  ],
                ),
                const SizedBox(height: 32),

                // Join Button
                Semantics(
                  button: true,
                  label: 'הרשמה חינם לאפליקציה',
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            TextConfig.joinFree,
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Google Sign In Button - More prominent
                Semantics(
                  button: true,
                  label: 'הרשמה באמצעות חשבון Google',
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google colored G logo
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Center(
                              child: ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF4285F4), Color(0xFFDB4437), Color(0xFFF4B400), Color(0xFF0F9D58)],
                                  stops: [0.0, 0.33, 0.66, 1.0],
                                ).createShader(bounds),
                                child: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '\u05d4\u05e8\u05e9\u05de\u05d4 \u05d1\u05d0\u05de\u05e6\u05e2\u05d5\u05ea Google',
                            style: TextStyle(
                              fontFamily: 'Heebo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Login Button
                Semantics(
                  button: true,
                  label: 'כניסה לחשבון קיים',
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '\u05d9\u05e9 \u05dc\u05d9 \u05db\u05d1\u05e8 \u05d7\u05e9\u05d1\u05d5\u05df',
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // App stats - real count from Firestore
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FutureBuilder<int>(
                    future: AuthService.instance.getRegisteredUsersCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count < 10) return const SizedBox.shrink();
                      return Text(
                        '\u05db\u05d1\u05e8 $count+ \u05d0\u05de\u05d4\u05d5\u05ea \u05d1\u05e7\u05d4\u05d9\u05dc\u05d4',
                        style: TextStyle(
                          fontFamily: 'Heebo',
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureChipIcon(IconData icon, String label) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Heebo',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
