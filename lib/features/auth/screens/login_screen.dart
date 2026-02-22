import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/constants/text_config.dart';
import 'package:mom_connect/features/auth/screens/register_screen.dart';
import 'package:mom_connect/features/auth/screens/intro_splash_screen.dart';
import 'package:mom_connect/features/admin/screens/admin_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/core/widgets/dialog_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
          tooltip: 'חזרה',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 12),
                _buildRememberAndForgot(),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 32),
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD1C2D3), Color(0xFFEDD3D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD1C2D3).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
          ),
        ]),
        const SizedBox(height: 24),
        Text('\u05d1\u05e8\u05d5\u05db\u05d4 \u05d4\u05e9\u05d1\u05d4!', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('\u05e9\u05de\u05d7\u05d5\u05ea \u05dc\u05e8\u05d0\u05d5\u05ea \u05d0\u05d5\u05ea\u05da \u05e9\u05d5\u05d1 \u05d1MOMIT', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('\u05d0\u05d9\u05de\u05d9\u05d9\u05dc', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontFamily: 'Heebo'),
          decoration: InputDecoration(
            hintText: '\u05d4\u05db\u05e0\u05d9\u05e1\u05d9 \u05d0\u05ea \u05d4\u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05e9\u05dc\u05da',
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textHint),
            filled: true, fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return TextConfig.errorRequiredField;
            if (!v.contains('@')) return TextConfig.errorInvalidEmail;
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('\u05e1\u05d9\u05e1\u05de\u05d4', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(fontFamily: 'Heebo'),
          decoration: InputDecoration(
            hintText: '\u05d4\u05db\u05e0\u05d9\u05e1\u05d9 \u05d0\u05ea \u05d4\u05e1\u05d9\u05e1\u05de\u05d4 \u05e9\u05dc\u05da',
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              tooltip: 'הסתר/הצג סיסמה',
            ),
            filled: true, fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return TextConfig.errorRequiredField;
            if (v.length < 6) return TextConfig.errorInvalidPassword;
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: _showForgotPasswordSheet, child: Text(TextConfig.forgotPassword, style: const TextStyle(fontFamily: 'Heebo', fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildLoginButton() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final sineValue = _shakeController.isAnimating
            ? sin(_shakeController.value * pi * 4) * 8
            : 0.0;
        return Transform.translate(
          offset: Offset(sineValue, 0),
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(TextConfig.login, style: const TextStyle(fontFamily: 'Heebo', fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('\u05e2\u05d3\u05d9\u05d9\u05df \u05d0\u05d9\u05df \u05dc\u05da \u05d7\u05e9\u05d1\u05d5\u05df? ', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
            child: const Text('\u05d4\u05e6\u05d8\u05e8\u05e4\u05d9 \u05e2\u05db\u05e9\u05d9\u05d5', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// REAL login handler - with proper error handling and navigation
  void _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Ensure AuthService is initialized
      await AuthService.instance.initialize();

      final result = await AuthService.instance.login(email: email, password: password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!result.isSuccess) {
        _shakeController.forward(from: 0);
        HapticFeedback.heavyImpact();
        if (!mounted) return;
        AppSnackbar.error(
          context,
          result.errorMessage ?? 'שגיאה בכניסה',
        );
        return;
      }

      // Success!
      final userData = result.userData;
      if (userData == null) {
        AppSnackbar.error(context, 'שגיאה בקבלת נתוני משתמש');
        return;
      }
      final isAdmin = userData['isAdmin'] == true;

      if (!mounted) return;

      if (isAdmin) {
        // Admin login
        context.read<AppState>().loginAsAdmin(email);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      } else {
        // Regular user login
        final userModel = AuthService.instance.userModelFromData(userData);
        context.read<AppState>().setUser(userModel);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => IntroSplashScreen(userName: userModel.fullName)),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, 'שגיאה לא צפויה: $e');
    }
  }

  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController();
    final forgotFormKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: forgotFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    const Text('\u05e9\u05db\u05d7\u05ea \u05e1\u05d9\u05e1\u05de\u05d4?', style: TextStyle(fontFamily: 'Heebo', fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('\u05d4\u05db\u05e0\u05d9\u05e1\u05d9 \u05d0\u05ea \u05d4\u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05e9\u05dc\u05da \u05d5\u05e0\u05e9\u05dc\u05d7 \u05dc\u05da \u05e7\u05d9\u05e9\u05d5\u05e8 \u05dc\u05d0\u05d9\u05e4\u05d5\u05e1', style: TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(hintText: '\u05d4\u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05e9\u05dc\u05da', prefixIcon: const Icon(Icons.email_outlined), filled: true, fillColor: AppColors.surfaceVariant, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'נא להזין כתובת אימייל';
                        if (!v.contains('@') || !v.contains('.')) return 'כתובת אימייל לא תקינה';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                      onPressed: isSending ? null : () async {
                        if (!(forgotFormKey.currentState?.validate() ?? false)) return;

                        final email = emailCtrl.text.trim();
                        setSheetState(() => isSending = true);

                        // Call rate-limited password reset
                        final result = await AuthService.instance.requestPasswordReset(email);

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);

                        if (!context.mounted) return;

                        if (result.isSuccess) {
                          AppSnackbar.success(
                            context,
                            result.userData?['message'] as String? ?? 'קישור לאיפוס סיסמה נשלח',
                          );
                        } else {
                          AppSnackbar.error(
                            context,
                            result.errorMessage ?? 'שגיאה בשליחת הבקשה',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSending
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('\u05e9\u05dc\u05d9\u05d7\u05ea \u05e7\u05d9\u05e9\u05d5\u05e8', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, fontWeight: FontWeight.bold)),
                    )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
