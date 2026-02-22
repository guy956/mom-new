import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/constants/text_config.dart';
import 'package:mom_connect/core/widgets/common_widgets.dart';
import 'package:mom_connect/features/auth/screens/login_screen.dart';
import 'package:mom_connect/features/auth/screens/intro_splash_screen.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  int _currentStep = 0;

  // Israeli cities list for autocomplete
  static const List<String> _israeliCities = [
    'ירושלים', 'תל אביב', 'חיפה', 'ראשון לציון', 'פתח תקווה',
    'אשדוד', 'נתניה', 'באר שבע', 'חולון', 'בני ברק',
    'רמת גן', 'אשקלון', 'רחובות', 'בת ים', 'הרצליה',
    'כפר סבא', 'חדרה', 'מודיעין', 'רעננה', 'לוד',
    'נצרת', 'רמלה', 'גבעתיים', 'הוד השרון', 'עכו',
    'נהריה', 'קרית אתא', 'קרית גת', 'אילת', 'טבריה',
    'רמת השרון', 'יהוד', 'נס ציונה', 'קרית מוצקין', 'כרמיאל',
    'אור יהודה', 'ביתר עילית', 'צפת', 'עפולה', 'מעלה אדומים',
    'אריאל', 'גבעת שמואל', 'טירת כרמל', 'יבנה', 'קרית ביאליק',
    'קרית ים', 'דימונה', 'קרית שמונה', 'מגדל העמק', 'שדרות',
    'עראבה', 'סח\'נין', 'טמרה', 'אום אל פחם', 'רהט',
    'מעלות', 'יקנעם', 'זכרון יעקב', 'פרדס חנה', 'אור עקיבא',
    'קצרין', 'שוהם', 'כפר יונה', 'גן יבנה', 'גדרה',
  ];

  List<String> _filteredCities = [];
  bool _showCitySuggestions = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _filterCities(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCities = [];
        _showCitySuggestions = false;
      });
      return;
    }
    setState(() {
      _filteredCities = _israeliCities
          .where((city) => city.contains(query))
          .take(5)
          .toList();
      _showCitySuggestions = _filteredCities.isNotEmpty;
    });
  }

  void _handleRegister() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש לאשר את תנאי השימוש ומדיניות הפרטיות', style: TextStyle(fontFamily: 'Heebo')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show confirmation dialog before registration
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('אישור הרשמה', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('את עומדת להירשם עם הפרטים הבאים:', style: TextStyle(fontFamily: 'Heebo')),
            const SizedBox(height: 12),
            Text('שם: ${_nameController.text.trim()}', style: const TextStyle(fontFamily: 'Heebo')),
            Text('אימייל: ${_emailController.text.trim()}', style: const TextStyle(fontFamily: 'Heebo')),
            Text('טלפון: ${_phoneController.text.trim()}', style: const TextStyle(fontFamily: 'Heebo')),
            Text('עיר: ${_cityController.text.trim()}', style: const TextStyle(fontFamily: 'Heebo')),
            const SizedBox(height: 12),
            const Text(
              'בלחיצה על "אישור" את מסכימה לתנאי השימוש ולמדיניות הפרטיות.',
              style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('אישור', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(result.errorMessage ?? 'שגיאה בהרשמה', style: const TextStyle(fontFamily: 'Heebo'))),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Registration success - auto login and go to main screen
    if (mounted) {
      // Auto login after successful registration
      final loginResult = await AuthService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final loginUserData = loginResult.userData;
      if (loginResult.isSuccess && loginUserData != null) {
        // Update AppState with user data
        final userModel = AuthService.instance.userModelFromData(loginUserData);
        context.read<AppState>().setUser(userModel);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('ההרשמה הושלמה בהצלחה! ברוכה הבאה לMOMIT', style: TextStyle(fontFamily: 'Heebo'))),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => IntroSplashScreen(userName: userModel.fullName),
            ),
            (route) => false,
          );
        }
      } else {
        // If auto-login fails, go to login screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('ההרשמה הושלמה! אנא התחברי', style: TextStyle(fontFamily: 'Heebo')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildProgressIndicator(),
                    const SizedBox(height: 30),
                    _buildCurrentStep(),
                    const SizedBox(height: 30),
                    _buildNavigationButtons(),
                    const SizedBox(height: 30),
                    if (_currentStep == 0) _buildLoginLink(),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('נרשמת...', style: TextStyle(fontFamily: 'Heebo', fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.pop(context);
                }
              },
              tooltip: 'חזרה',
              icon: const Icon(Icons.arrow_forward),
            ),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(gradient: AppColors.momGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Text(TextConfig.appName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Heebo', color: AppColors.primary)),
              ],
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 24),
        Text(_getStepTitle(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Heebo')),
        const SizedBox(height: 8),
        Text(_getStepSubtitle(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontFamily: 'Heebo', color: AppColors.textSecondary)),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'בואי נתחיל!';
      case 1: return 'סיסמה ועיר';
      case 2: return 'כמעט סיימנו!';
      default: return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0: return 'הזיני את הפרטים הבסיסיים שלך';
      case 1: return 'בחרי סיסמה חזקה ועיר מגורים';
      case 2: return 'אישור תנאי שימוש ומדיניות פרטיות';
      default: return '';
    }
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(hintText: 'שם מלא *', prefixIcon: Icon(Icons.person_outlined)),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return TextConfig.errorRequiredField;
            if (v.trim().length < 2) return 'שם מלא חייב להכיל לפחות 2 תווים';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: 'אימייל *', prefixIcon: Icon(Icons.email_outlined)),
          validator: (v) {
            if (v == null || v.isEmpty) return TextConfig.errorRequiredField;
            if (!v.contains('@') || !v.contains('.')) return TextConfig.errorInvalidEmail;
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: '050-0000000 *',
            prefixIcon: const Icon(Icons.phone_outlined),
            prefix: Container(
              padding: const EdgeInsets.only(left: 8),
              child: const Text('+972 ', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w600)),
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d-]'))],
          validator: (v) {
            if (v == null || v.isEmpty) return 'מספר טלפון הוא שדה חובה';
            final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
            if (!cleaned.startsWith('05') && !cleaned.startsWith('5')) {
              return 'מספר טלפון חייב להתחיל ב-05';
            }
            final phoneRegex = RegExp(r'^0?(5[0-9])\d{7}$');
            if (!phoneRegex.hasMatch(cleaned)) {
              return 'מספר טלפון ישראלי חייב להכיל 10 ספרות (05X-XXXXXXX)';
            }
            return null;
          },
        ),

      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: 'סיסמה *',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              tooltip: 'הסתר/הצג סיסמה',
            ),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.isEmpty) return TextConfig.errorRequiredField;
            if (v.length < 8) return 'הסיסמה חייבת להכיל לפחות 8 תווים';
            if (!v.contains(RegExp(r'[a-zA-Z]'))) return 'הסיסמה חייבת לכלול לפחות אות אחת';
            if (!v.contains(RegExp(r'[0-9]'))) return 'הסיסמה חייבת לכלול לפחות מספר אחד';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: 'אימות סיסמה *',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              tooltip: 'הסתר/הצג סיסמה',
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return TextConfig.errorRequiredField;
            if (v != _passwordController.text) return TextConfig.errorPasswordMismatch;
            return null;
          },
        ),
        const SizedBox(height: 16),
        // City with autocomplete
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _cityController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'עיר מגורים * (הקלידי לחיפוש)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: (value) => _filterCities(value),
              onTap: () {
                if (_cityController.text.isNotEmpty) {
                  _filterCities(_cityController.text);
                }
              },
              validator: (v) => (v == null || v.isEmpty) ? TextConfig.errorRequiredField : null,
            ),
            if (_showCitySuggestions)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                child: Column(
                  children: _filteredCities.map((city) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_city, size: 20, color: AppColors.primary),
                      title: Text(city, style: const TextStyle(fontFamily: 'Heebo')),
                      onTap: () {
                        _cityController.text = city;
                        setState(() => _showCitySuggestions = false);
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPasswordRequirements(),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('דרישות סיסמה:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Heebo')),
          const SizedBox(height: 8),
          _buildReq('לפחות 8 תווים', password.length >= 8),
          _buildReq('אות אחת לפחות', password.contains(RegExp(r'[a-zA-Z]'))),
          _buildReq('מספר אחד לפחות', password.contains(RegExp(r'[0-9]'))),
        ],
      ),
    );
  }

  Widget _buildReq(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.circle_outlined, size: 18, color: met ? AppColors.success : AppColors.textHint),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontFamily: 'Heebo', color: met ? AppColors.success : AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 60, color: AppColors.success),
              const SizedBox(height: 16),
              const Text('הפרטים שלך:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Heebo')),
              const SizedBox(height: 16),
              _buildSummaryRow('שם:', _nameController.text),
              _buildSummaryRow('אימייל:', _emailController.text),
              _buildSummaryRow('טלפון:', _phoneController.text),
              _buildSummaryRow('עיר:', _cityController.text),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Checkbox(value: _agreeToTerms, onChanged: (v) => setState(() => _agreeToTerms = v ?? false), activeColor: AppColors.primary),
              Expanded(
                child: Wrap(
                  children: [
                    const Text('קראתי ואני מסכימה ל', style: TextStyle(fontFamily: 'Heebo')),
                    GestureDetector(
                      onTap: _showTermsDialog,
                      child: const Text('תנאי השימוש', style: TextStyle(fontFamily: 'Heebo', color: AppColors.primary, decoration: TextDecoration.underline)),
                    ),
                    const Text(' ול', style: TextStyle(fontFamily: 'Heebo')),
                    GestureDetector(
                      onTap: _showPrivacyDialog,
                      child: const Text('מדיניות הפרטיות', style: TextStyle(fontFamily: 'Heebo', color: AppColors.primary, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 20, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(child: Text('הפרטים שלך מאובטחים ומוגנים בהתאם לחוק הגנת הפרטיות, התשמ"א-1981', style: TextStyle(fontFamily: 'Heebo', fontSize: 12, color: AppColors.info))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Heebo', color: AppColors.textSecondary)),
          Text(value.isEmpty ? '-' : value, style: const TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(child: SecondaryButton(text: TextConfig.back, onPressed: () => setState(() => _currentStep--))),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: _currentStep > 0 ? 2 : 1,
          child: PrimaryButton(
            text: _currentStep < 2 ? TextConfig.next : 'השלמת הרשמה',
            isLoading: _isLoading,
            icon: _currentStep < 2 ? Icons.arrow_back : Icons.check_circle_outline,
            onPressed: () {
              if (_currentStep < 2) {
                if (_validateCurrentStep()) setState(() => _currentStep++);
              } else {
                _handleRegister();
              }
            },
          ),
        ),
      ],
    );
  }

  bool _validateCurrentStep() {
    // Use the form's built-in validation to show inline error messages
    // on each TextFormField, then also do a manual check as a fallback.
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return false;

    switch (_currentStep) {
      case 0:
        // The form validator already checks name, email, phone inline.
        // This is a safety net in case form state is out of sync.
        if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('נא למלא את כל השדות', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error));
          return false;
        }
        return true;
      case 1:
        if (_passwordController.text.length < 8) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(TextConfig.errorInvalidPassword, style: const TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error));
          return false;
        }
        if (!_passwordController.text.contains(RegExp(r'[a-zA-Z]')) || !_passwordController.text.contains(RegExp(r'[0-9]'))) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('הסיסמה חייבת לכלול אות ומספר', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error));
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(TextConfig.errorPasswordMismatch, style: const TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error));
          return false;
        }
        if (_cityController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('נא להזין עיר מגורים', style: TextStyle(fontFamily: 'Heebo')), backgroundColor: AppColors.error));
          return false;
        }
        return true;
      default: return true;
    }
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(TextConfig.alreadyMember, style: const TextStyle(fontSize: 14, fontFamily: 'Heebo', color: AppColors.textSecondary)),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: Text(TextConfig.login, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Heebo')),
        ),
      ],
    );
  }

  void _showTermsDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('תנאי שימוש', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: const SingleChildScrollView(child: Text(
          'תנאי שימוש - אפליקציית "MOMIT" (MOM Connect)\n'
          'עדכון אחרון: פברואר 2025\n\n'
          '1. כללי\n'
          '1.1 אפליקציית "MOMIT" (להלן: "האפליקציה") מופעלת ומנוהלת על ידי MOMIT טכנולוגיות בע"מ (להלן: "החברה").\n'
          '1.2 השימוש באפליקציה מהווה הסכמה מלאה ומפורשת לתנאי שימוש אלה.\n'
          '1.3 האפליקציה מיועדת לאמהות, נשים בהריון ובני משפחה בישראל.\n'
          '1.4 החברה שומרת לעצמה את הזכות לעדכן תנאים אלה מעת לעת.\n\n'
          '2. הרשמה ופרטי משתמש\n'
          '2.1 ההרשמה לאפליקציה מחייבת מסירת פרטים אישיים אמיתיים ומדויקים.\n'
          '2.2 כל משתמשת אחראית לשמור על סיסמתה ופרטי הכניסה שלה בסודיות מלאה.\n'
          '2.3 חל איסור מוחלט ליצור יותר מחשבון אחד לכל אדם.\n'
          '2.4 החברה רשאית לדרוש אימות זהות נוסף בכל עת.\n\n'
          '3. שימוש מותר\n'
          '3.1 האפליקציה מיועדת לשימוש אישי בלבד ולא למטרות מסחריות.\n'
          '3.2 על המשתמשות לנהוג בכבוד הדדי, בסובלנות ובאחריות.\n'
          '3.3 חל איסור מוחלט על:\n'
          '   - פרסום תוכן פוגעני, מאיים, מטריד, גזעני או מיני.\n'
          '   - פרסום מידע כוזב, מטעה או שקרי.\n'
          '   - התחזות לאדם אחר.\n'
          '   - הפצת ספאם, פרסום מסחרי לא מאושר, או שיווק.\n'
          '   - איסוף פרטים אישיים של משתמשות אחרות ללא הסכמתן.\n'
          '   - העלאת תוכן המפר זכויות יוצרים או קניין רוחני.\n'
          '   - כל פעילות הנוגדת את חוקי מדינת ישראל.\n\n'
          '4. תוכן רפואי\n'
          '4.1 המידע באפליקציה הוא לצורכי מידע כללי בלבד ואינו מהווה ייעוץ רפואי מקצועי.\n'
          '4.2 בכל מקרה של חשש רפואי, יש לפנות לרופא או לשירותי חירום.\n'
          '4.3 החברה אינה אחראית לנזק שנגרם כתוצאה מהסתמכות על מידע באפליקציה.\n\n'
          '5. קניין רוחני\n'
          '5.1 כל הזכויות באפליקציה, לרבות עיצוב, קוד, תוכן ולוגו, שייכות לחברה.\n'
          '5.2 תוכן שמפורסם על ידי המשתמשות נשאר בבעלותן, אך הן מעניקות לחברה רישיון שימוש לצורך תפעול האפליקציה.\n\n'
          '6. הגבלת אחריות\n'
          '6.1 האפליקציה מסופקת "כמות שהיא" (AS IS) ללא אחריות מכל סוג.\n'
          '6.2 החברה לא תהיה אחראית לנזקים ישירים או עקיפים הנובעים מהשימוש באפליקציה.\n'
          '6.3 החברה אינה אחראית לתוכן המפורסם על ידי המשתמשות.\n\n'
          '7. הסרת תוכן וחסימת חשבונות\n'
          '7.1 החברה רשאית להסיר כל תוכן המפר את תנאי השימוש, ללא התראה מוקדמת.\n'
          '7.2 החברה רשאית לחסום או להשעות חשבון משתמשת שמפרה את התנאים.\n'
          '7.3 משתמשת שחשבונה נחסם רשאית לערער באמצעות פנייה לשירות הלקוחות.\n\n'
          '8. שימוש בנתונים למטרות דיוור והודעות\n'
          '8.1 בהרשמה לאפליקציה, המשתמשת מסכימה לקבל הודעות מהמערכת, לרבות:\n'
          '   - התראות על פעילות בחשבון (תגובות, הודעות, אירועים).\n'
          '   - עדכונים על תכונות חדשות באפליקציה.\n'
          '   - תוכן שיווקי ופרסומי מטעם החברה ושותפיה.\n'
          '   - סקרים ומשובים לשיפור השירות.\n'
          '8.2 ההודעות ישלחו באמצעות הודעות push, אימייל, SMS או WhatsApp, בהתאם לפרטים שנמסרו.\n'
          '8.3 ניתן לבטל הסכמה לקבלת דיוור שיווקי בכל עת דרך הגדרות האפליקציה.\n'
          '8.4 הודעות מערכת חיוניות (אבטחה, עדכוני תנאים) ימשיכו להישלח גם לאחר ביטול.\n\n'
          '9. דין חל וסמכות שיפוט\n'
          '9.1 תנאי שימוש אלה כפופים לדיני מדינת ישראל.\n'
          '9.2 סמכות השיפוט הבלעדית תהיה לבתי המשפט במחוז תל אביב.\n\n'
          '10. יצירת קשר\n'
          'לכל שאלה או פנייה בנושא תנאי השימוש:\n'
          'אימייל: legal@momit.co.il\n',
          style: TextStyle(fontFamily: 'Heebo', height: 1.6, fontSize: 13),
        )),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)))],
    ));
  }

  void _showPrivacyDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('מדיניות פרטיות', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: const SingleChildScrollView(child: Text(
          'מדיניות פרטיות - אפליקציית "MOMIT" (MOM Connect)\n'
          'עדכון אחרון: פברואר 2025\n\n'
          'מדיניות פרטיות זו מנוסחת בהתאם לחוק הגנת הפרטיות, התשמ"א-1981, ותקנות הגנת הפרטיות (אבטחת מידע), התשע"ז-2017.\n\n'
          '1. המידע שאנו אוספים\n'
          '1.1 מידע שנמסר על ידך:\n'
          '   - פרטי זיהוי: שם מלא, כתובת אימייל, מספר טלפון.\n'
          '   - מידע דמוגרפי: עיר מגורים, גיל ילדים.\n'
          '   - תוכן שנוצר: פוסטים, תמונות, הודעות, תגובות.\n'
          '   - נתוני מעקב: מדידות, יומני שינה/האכלה (אופציונלי).\n'
          '1.2 מידע שנאסף אוטומטית:\n'
          '   - נתוני שימוש: דפים שנצפו, פעולות שבוצעו.\n'
          '   - נתוני מכשיר: סוג מכשיר, מערכת הפעלה.\n'
          '   - מידע מיקום: עיר (לא מיקום מדויק), לצורך שירותי SOS וקהילה מקומית.\n\n'
          '2. מטרות השימוש במידע\n'
          '2.1 אנו משתמשים במידע למטרות הבאות:\n'
          '   - תפעול האפליקציה ומתן השירותים.\n'
          '   - התאמה אישית של חוויית המשתמש.\n'
          '   - שליחת התראות, עדכונים ודיוור (בהתאם להסכמתך).\n'
          '   - שיפור השירות וניתוח מגמות שימוש.\n'
          '   - אבטחת מידע ומניעת הונאות.\n'
          '   - עמידה בדרישות חוק.\n'
          '2.2 המידע ישמש גם לצורך:\n'
          '   - שליחת הודעות מערכת ותפעוליות.\n'
          '   - דיוור ישיר ושיווקי (בכפוף להסכמה).\n'
          '   - סקרים ומחקרי שוק (נתונים אנונימיים בלבד).\n\n'
          '3. שיתוף מידע עם צדדים שלישיים\n'
          '3.1 איננו מוכרים את המידע האישי שלך לצדדים שלישיים.\n'
          '3.2 אנו עשויים לשתף מידע עם:\n'
          '   - ספקי שירות טכניים (אחסון, ניתוח נתונים) - בכפוף להסכמי סודיות.\n'
          '   - רשויות חוק - כנדרש על פי דין.\n'
          '3.3 במקרה של מיזוג או רכישה, המידע עשוי להיות מועבר בכפוף להודעה מוקדמת.\n\n'
          '4. אבטחת מידע\n'
          '4.1 אנו מיישמים אמצעי אבטחה מתקדמים לשמירה על המידע שלך, בהתאם לתקנות אבטחת מידע.\n'
          '4.2 הנתונים מוצפנים הן בהעברה והן באחסון.\n'
          '4.3 הגישה למידע מוגבלת לעובדים מורשים בלבד.\n'
          '4.4 אנו מבצעים בדיקות אבטחה תקופתיות.\n\n'
          '5. זכויותייך\n'
          'בהתאם לחוק הגנת הפרטיות, יש לך זכות:\n'
          '5.1 לעיין במידע האישי שנאסף עלייך.\n'
          '5.2 לבקש תיקון מידע שגוי.\n'
          '5.3 לבקש מחיקת המידע שלך (בכפוף למגבלות חוקיות).\n'
          '5.4 לבטל הסכמה לדיוור שיווקי בכל עת.\n'
          '5.5 להגביל את השימוש במידע שלך.\n'
          '5.6 לבקש העברת המידע שלך (Portability).\n\n'
          '6. שמירת מידע\n'
          '6.1 המידע נשמר כל עוד החשבון פעיל.\n'
          '6.2 לאחר מחיקת חשבון, המידע יימחק תוך 30 יום, למעט מידע שנדרש לשמרו על פי דין.\n'
          '6.3 גיבויים מוצפנים נשמרים למשך 90 יום.\n\n'
          '7. פרטיות ילדים\n'
          '7.1 נתוני ילדים (תמונות, מדידות, מעקב) מוגנים בהגנה מוגברת.\n'
          '7.2 אלבומים פרטיים נגישים לאם בלבד.\n'
          '7.3 איננו משתפים נתוני ילדים עם צדדים שלישיים בשום מקרה.\n\n'
          '8. Cookies ומעקב\n'
          '8.1 האפליקציה משתמשת בעוגיות לצורך תפעול ושיפור השירות.\n'
          '8.2 ניתן לשלוט בהעדפות העוגיות דרך הגדרות המכשיר.\n\n'
          '9. עדכונים למדיניות\n'
          '9.1 אנו עשויים לעדכן מדיניות זו מעת לעת.\n'
          '9.2 שינויים מהותיים יפורסמו באפליקציה ובאימייל.\n\n'
          '10. יצירת קשר - ממונה הגנת פרטיות\n'
          'לכל שאלה או בקשה בנושא פרטיות:\n'
          'אימייל: privacy@momit.co.il\n'
          'כתובת: רח\' הרצל 1, תל אביב\n\n'
          '11. רשם מאגרי מידע\n'
          'מאגר המידע של האפליקציה רשום ברשם מאגרי מידע בהתאם לחוק.\n',
          style: TextStyle(fontFamily: 'Heebo', height: 1.6, fontSize: 13),
        )),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('סגור', style: TextStyle(fontFamily: 'Heebo', fontWeight: FontWeight.bold)))],
    ));
  }
}
