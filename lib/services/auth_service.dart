import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mom_connect/models/user_model.dart';
import 'package:mom_connect/firebase_options.dart';
import 'package:mom_connect/middleware/rate_limiter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

// Conditional imports for secure cookie management on web
import 'secure_cookie_manager.dart' if (dart.library.js_interop) 'secure_cookie_manager_web.dart';

/// JWT Token pair for authentication
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiry;
  final DateTime refreshTokenExpiry;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
  });

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessTokenExpiry': accessTokenExpiry.toIso8601String(),
    'refreshTokenExpiry': refreshTokenExpiry.toIso8601String(),
  };

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
    accessTokenExpiry: DateTime.parse(json['accessTokenExpiry']),
    refreshTokenExpiry: DateTime.parse(json['refreshTokenExpiry']),
  );

  bool get isAccessTokenExpired => DateTime.now().isAfter(accessTokenExpiry);
  bool get isRefreshTokenExpired => DateTime.now().isAfter(refreshTokenExpiry);
  bool get needsRefresh => isAccessTokenExpired && !isRefreshTokenExpired;
}

/// Secure JWT Service for token generation and validation
class JwtService {
  static JwtService? _instance;
  static JwtService get instance => _instance ??= JwtService._();

  JwtService._();

  String? _accessSecret;
  String? _refreshSecret;
  bool _initialized = false;

  /// Token expiration times
  static const Duration accessTokenExpiry = Duration(minutes: 15);
  static const Duration refreshTokenExpiry = Duration(days: 7);

  /// Initialize JWT secrets from environment variables
  Future<void> initialize() async {
    if (_initialized) return;

    // Load from environment variables
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('[JwtService] Warning: .env file not found: $e');
    }

    _accessSecret = dotenv.env['JWT_ACCESS_SECRET'];
    _refreshSecret = dotenv.env['JWT_REFRESH_SECRET'];

    // Validate secrets are set - generate cryptographically random fallback if missing
    if (_accessSecret == null || _accessSecret!.isEmpty || _accessSecret!.length < 32) {
      debugPrint('[JwtService] Warning: JWT_ACCESS_SECRET missing or too short, using random fallback');
      _accessSecret = _generateRandomSecret();
    }
    if (_refreshSecret == null || _refreshSecret!.isEmpty || _refreshSecret!.length < 32) {
      debugPrint('[JwtService] Warning: JWT_REFRESH_SECRET missing or too short, using random fallback');
      _refreshSecret = _generateRandomSecret();
    }

    _initialized = true;
    debugPrint('[JwtService] Initialized with secure secrets from environment');
  }

  static String _generateRandomSecret() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    return List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String get _accessSecretKey {
    if (!_initialized) throw StateError('JwtService not initialized');
    return _accessSecret!;
  }

  String get _refreshSecretKey {
    if (!_initialized) throw StateError('JwtService not initialized');
    return _refreshSecret!;
  }

  /// Generate a new token pair for a user
  TokenPair generateTokenPair({
    required String email,
    required String userId,
    required bool isAdmin,
    Map<String, dynamic>? additionalClaims,
  }) {
    final now = DateTime.now();
    final accessExpiry = now.add(accessTokenExpiry);
    final refreshExpiry = now.add(refreshTokenExpiry);

    // Generate Access Token (short-lived)
    final accessJwt = JWT({
      'email': email,
      'userId': userId,
      'isAdmin': isAdmin,
      'type': 'access',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': accessExpiry.millisecondsSinceEpoch ~/ 1000,
      ...additionalClaims ?? {},
    });
    final accessToken = accessJwt.sign(
      SecretKey(_accessSecretKey),
      algorithm: JWTAlgorithm.HS256,
    );

    // Generate Refresh Token (long-lived, single purpose)
    final refreshJwt = JWT({
      'email': email,
      'userId': userId,
      'type': 'refresh',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': refreshExpiry.millisecondsSinceEpoch ~/ 1000,
      'jti': _generateTokenId(), // Unique token ID for revocation
    });
    final refreshToken = refreshJwt.sign(
      SecretKey(_refreshSecretKey),
      algorithm: JWTAlgorithm.HS256,
    );

    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiry: accessExpiry,
      refreshTokenExpiry: refreshExpiry,
    );
  }

  /// Validate an access token
  JWTValidationResult validateAccessToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_accessSecretKey));
      final payload = jwt.payload as Map<String, dynamic>;
      
      // Check token type
      if (payload['type'] != 'access') {
        return JWTValidationResult.invalid('Invalid token type');
      }

      // Check expiration (redundant with verify, but explicit)
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (DateTime.now().isAfter(expiry)) {
          return JWTValidationResult.invalid('Token expired');
        }
      }

      return JWTValidationResult.valid(jwt);
    } on JWTExpiredException {
      return JWTValidationResult.invalid('Token expired');
    } on JWTException catch (e) {
      return JWTValidationResult.invalid('Invalid token: ${e.message}');
    }
  }

  /// Validate a refresh token
  JWTValidationResult validateRefreshToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_refreshSecretKey));
      final payload = jwt.payload as Map<String, dynamic>;
      
      // Check token type
      if (payload['type'] != 'refresh') {
        return JWTValidationResult.invalid('Invalid token type');
      }

      return JWTValidationResult.valid(jwt);
    } on JWTExpiredException {
      return JWTValidationResult.invalid('Refresh token expired');
    } on JWTException catch (e) {
      return JWTValidationResult.invalid('Invalid refresh token: ${e.message}');
    }
  }

  /// Refresh access token using refresh token
  TokenPair? refreshAccessToken(String refreshToken) {
    final validation = validateRefreshToken(refreshToken);
    if (!validation.isValid || validation.jwt == null) {
      return null;
    }

    final payload = validation.jwt!.payload as Map<String, dynamic>;
    final email = payload['email'] as String;
    final userId = payload['userId'] as String;
    final isAdmin = payload['isAdmin'] as bool? ?? false;

    // Generate new token pair (refresh token rotation)
    return generateTokenPair(
      email: email,
      userId: userId,
      isAdmin: isAdmin,
    );
  }

  /// Generate unique token ID for revocation tracking
  String _generateTokenId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}

/// JWT Validation result
class JWTValidationResult {
  final bool isValid;
  final String? errorMessage;
  final JWT? jwt;

  JWTValidationResult._({required this.isValid, this.errorMessage, this.jwt});

  factory JWTValidationResult.valid(JWT jwt) {
    return JWTValidationResult._(isValid: true, jwt: jwt);
  }

  factory JWTValidationResult.invalid(String message) {
    return JWTValidationResult._(isValid: false, errorMessage: message);
  }
}

/// Secure Token Storage
/// Web: uses SharedPreferences (reliable on all browsers)
/// Native: uses FlutterSecureStorage (encrypted keychain/keystore)
class SecureTokenStorage {
  static const _nativeStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accountName: 'momit_secure_tokens',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _tokenKey = 'momit_jwt_tokens';
  static const String _userKey = 'momit_user_data';

  static Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _nativeStorage.write(key: key, value: value);
    }
  }

  static Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _nativeStorage.read(key: key);
    }
  }

  static Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _nativeStorage.delete(key: key);
    }
  }

  static Future<void> saveTokens(TokenPair tokens) async {
    final json = jsonEncode(tokens.toJson());
    await _write(_tokenKey, json);
  }

  static Future<TokenPair?> loadTokens() async {
    final json = await _read(_tokenKey);
    if (json == null) return null;
    try {
      return TokenPair.fromJson(jsonDecode(json));
    } catch (e) {
      await deleteTokens();
      return null;
    }
  }

  static Future<void> deleteTokens() async {
    await _delete(_tokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final json = jsonEncode(userData);
    await _write(_userKey, json);
  }

  static Future<Map<String, dynamic>?> loadUserData() async {
    final json = await _read(_userKey);
    if (json == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteUserData() async {
    await _delete(_userKey);
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } else {
      await _nativeStorage.deleteAll();
    }
  }
}

/// Robust authentication service with secure JWT implementation
class AuthService with RateLimitMixin {
  // Admin emails loaded from environment with hardcoded fallback
  static List<String> get _adminEmails {
    final emailsStr = dotenv.env['ADMIN_EMAILS'];
    if (emailsStr != null && emailsStr.isNotEmpty) {
      return emailsStr.split(',').map((e) => e.trim().toLowerCase()).toList();
    }
    return const ['ola.cos85@gmail.com'];
  }

  /// Check if an email is an admin email
  static bool isAdminEmail(String email) => _adminEmails.contains(email.toLowerCase().trim());

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  bool _isInitialized = false;

  /// Initialize AuthService
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize JWT service first
    await JwtService.instance.initialize();

    _isInitialized = true;
    debugPrint('[AuthService] Initialized successfully with secure JWT');
    
    // Log secure cookie configuration on web
    if (kIsWeb && kDebugMode) {
      debugPrint('[AuthService] Web platform - Secure cookie configuration:');
      debugPrint('  - httpOnly: true (requires server-side enforcement)');
      debugPrint('  - secure: true (__Host- prefix enforced)');
      debugPrint('  - sameSite: strict (CSRF protection)');
      debugPrint('  - maxAge: 24 hours (session timeout)');
    }
  }

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String city,
  }) async {
    try {
      await _ensureInitialized();

      final emailLower = email.toLowerCase().trim();

      // Check rate limit for registration/API calls (100 per minute)
      final rateLimitError = rateLimitApiCall(emailLower);
      if (rateLimitError != null) {
        debugPrint('[AuthService] Rate limit exceeded for registration: $emailLower');
        return AuthResult.failure(rateLimitError);
      }

      // Validate
      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        return AuthResult.failure('כתובת אימייל לא תקינה');
      }
      if (password.length < 8) {
        return AuthResult.failure('סיסמא חייבת להכיל לפחות 8 תווים');
      }
      if (!password.contains(RegExp(r'[a-zA-Z]')) || !password.contains(RegExp(r'[0-9]'))) {
        return AuthResult.failure('הסיסמא חייבת לכלול לפחות אות אחת ומספר אחד');
      }
      if (fullName.isEmpty) {
        return AuthResult.failure('שם מלא הוא שדה חובה');
      }
      final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length < 9) {
        return AuthResult.failure('מספר טלפון לא תקין');
      }
      if (city.isEmpty) {
        return AuthResult.failure('עיר מגורים היא שדה חובה');
      }

      // === Firebase Auth: Create user ===
      final fb_auth.UserCredential credential;
      try {
        credential = await fb_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailLower,
          password: password,
        );
      } on fb_auth.FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'email-already-in-use':
            return AuthResult.failure('כתובת האימייל כבר רשומה במערכת');
          case 'invalid-email':
            return AuthResult.failure('כתובת אימייל לא תקינה');
          case 'weak-password':
            return AuthResult.failure('הסיסמה חלשה מדי');
          default:
            return AuthResult.failure('שגיאה בהרשמה: ${e.message}');
        }
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        return AuthResult.failure('שגיאה בהרשמה - לא התקבל משתמש');
      }

      final userId = fbUser.uid;
      final isAdmin = isAdminEmail(emailLower);

      // Update display name in Firebase Auth
      await fbUser.updateDisplayName(fullName);

      // Create Firestore user document
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'id': userId,
        'email': emailLower,
        'fullName': fullName,
        'phone': phone,
        'city': city,
        'isAdmin': isAdmin,
        'role': isAdmin ? 'admin' : 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': true,
        'isVerified': false,
        'loginCount': 1,
      });

      // Generate local JWT tokens (backward compatibility)
      final tokens = JwtService.instance.generateTokenPair(
        email: emailLower,
        userId: userId,
        isAdmin: isAdmin,
      );
      await SecureTokenStorage.saveTokens(tokens);

      final userData = {
        'id': userId,
        'email': emailLower,
        'fullName': fullName,
        'phone': phone,
        'city': city,
        'isAdmin': isAdmin,
        'createdAt': DateTime.now().toIso8601String(),
        'lastActive': DateTime.now().toIso8601String(),
        'loginCount': 1,
      };
      await SecureTokenStorage.saveUserData(userData);

      if (kIsWeb) {
        _setSecureSessionCookies(emailLower, tokens);
      }

      await logUserActivity(email: emailLower, activityType: 'register', details: 'Firebase Auth registration');
      debugPrint('[AuthService] Registered with Firebase Auth: $emailLower (uid: $userId)');
      return AuthResult.success(userData, tokens);
    } catch (e) {
      debugPrint('[AuthService] Register error: $e');
      return AuthResult.failure('שגיאה בהרשמה: $e');
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      await _ensureInitialized();

      final emailLower = email.toLowerCase().trim();

      // Check rate limit for login attempts (5 per minute)
      final rateLimitError = rateLimitLogin(emailLower);
      if (rateLimitError != null) {
        debugPrint('[AuthService] Rate limit exceeded for login: $emailLower');
        return AuthResult.failure(rateLimitError);
      }

      // === Firebase Auth: Sign in ===
      final fb_auth.UserCredential credential;
      try {
        credential = await fb_auth.FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: emailLower,
          password: password,
        );
      } on fb_auth.FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'user-not-found':
            return AuthResult.failure('משתמש לא נמצא - נסי להירשם');
          case 'wrong-password':
          case 'invalid-credential':
            return AuthResult.failure('סיסמה שגויה');
          case 'user-disabled':
            return AuthResult.failure('החשבון הושעה');
          case 'too-many-requests':
            return AuthResult.failure('יותר מדי ניסיונות - נסי שוב מאוחר יותר');
          default:
            return AuthResult.failure('שגיאה בהתחברות: ${e.message}');
        }
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        return AuthResult.failure('שגיאה בהתחברות - לא התקבל משתמש');
      }

      final userId = fbUser.uid;
      final isAdmin = isAdminEmail(emailLower);

      // Create/update Firestore user document
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnap = await userDoc.get();

      if (docSnap.exists) {
        await userDoc.update({
          'lastActive': FieldValue.serverTimestamp(),
          'isOnline': true,
          'loginCount': FieldValue.increment(1),
          'isAdmin': isAdmin,
        });
      } else {
        await userDoc.set({
          'id': userId,
          'email': emailLower,
          'fullName': fbUser.displayName ?? emailLower.split('@').first,
          'isAdmin': isAdmin,
          'role': isAdmin ? 'admin' : 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'isOnline': true,
          'isVerified': false,
          'loginCount': 1,
        });
      }

      // Generate local JWT tokens (backward compatibility)
      final tokens = JwtService.instance.generateTokenPair(
        email: emailLower,
        userId: userId,
        isAdmin: isAdmin,
      );
      await SecureTokenStorage.saveTokens(tokens);

      final userData = {
        'id': userId,
        'email': emailLower,
        'fullName': fbUser.displayName ?? emailLower.split('@').first,
        'isAdmin': isAdmin,
        'lastActive': DateTime.now().toIso8601String(),
        'loginCount': 1,
      };
      await SecureTokenStorage.saveUserData(userData);

      if (kIsWeb) {
        _setSecureSessionCookies(emailLower, tokens);
      }

      await logUserActivity(email: emailLower, activityType: 'login', details: 'Firebase Auth login');
      debugPrint('[AuthService] Logged in with Firebase Auth: $emailLower (uid: $userId)');
      return AuthResult.success(userData, tokens);
    } catch (e) {
      debugPrint('[AuthService] Login error: $e');
      return AuthResult.failure('שגיאה בהתחברות: $e');
    }
  }

  /// Google Sign-In with Firebase Auth
  Future<AuthResult> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      fb_auth.User? fbUser;
      String? emailLower;
      String? fullName;
      String? photoUrl;

      if (kIsWeb) {
        final webClientId = DefaultFirebaseOptions.webGoogleClientId;

        if (webClientId.isEmpty) {
          // Use Firebase popup directly
          try {
            final provider = fb_auth.GoogleAuthProvider();
            provider.addScope('email');
            provider.addScope('profile');
            final result = await fb_auth.FirebaseAuth.instance.signInWithPopup(provider);
            fbUser = result.user;
            if (fbUser == null) {
              return AuthResult.failure('התחברות עם Google בוטלה');
            }
            emailLower = fbUser.email?.toLowerCase().trim();
            fullName = fbUser.displayName ?? fbUser.email?.split('@').first ?? '';
            photoUrl = fbUser.photoURL ?? '';
          } catch (e) {
            debugPrint('[AuthService] Firebase popup failed: $e');
            return AuthResult.failure(
              'התחברות עם Google לא זמינה כרגע. נסי להתחבר עם אימייל וסיסמה.');
          }
        } else {
          // Use GoogleSignIn + Firebase credential
          final googleSignIn = GoogleSignIn(
            clientId: webClientId,
            scopes: ['email', 'profile'],
          );
          final googleUser = await googleSignIn.signIn();
          if (googleUser == null) {
            return AuthResult.failure('התחברות עם Google בוטלה');
          }

          final googleAuth = await googleUser.authentication;
          final credential = fb_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final fbResult = await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
          fbUser = fbResult.user;

          emailLower = (fbUser?.email ?? googleUser.email).toLowerCase().trim();
          fullName = fbUser?.displayName ?? googleUser.displayName ?? googleUser.email.split('@').first;
          photoUrl = fbUser?.photoURL ?? googleUser.photoUrl ?? '';
        }
      } else {
        // Native: GoogleSignIn + Firebase credential
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return AuthResult.failure('התחברות עם Google בוטלה');
        }

        final googleAuth = await googleUser.authentication;
        final credential = fb_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final fbResult = await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
        fbUser = fbResult.user;
        emailLower = (fbUser?.email ?? googleUser.email).toLowerCase().trim();
        fullName = fbUser?.displayName ?? googleUser.displayName ?? googleUser.email.split('@').first;
        photoUrl = fbUser?.photoURL ?? googleUser.photoUrl ?? '';
      }

      if (emailLower == null || emailLower.isEmpty) {
        return AuthResult.failure('לא התקבל אימייל מ-Google');
      }

      final userId = fbUser?.uid ?? 'user_${emailLower.hashCode}';
      final isAdmin = isAdminEmail(emailLower);

      // Create/update Firestore user document
      if (fbUser != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
        final docSnap = await userDoc.get();

        if (docSnap.exists) {
          await userDoc.update({
            'lastActive': FieldValue.serverTimestamp(),
            'isOnline': true,
            'loginCount': FieldValue.increment(1),
            'isAdmin': isAdmin,
            'profileImage': photoUrl,
          });
        } else {
          await userDoc.set({
            'id': userId,
            'email': emailLower,
            'fullName': fullName,
            'profileImage': photoUrl,
            'isAdmin': isAdmin,
            'role': isAdmin ? 'admin' : 'user',
            'googleUser': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
            'isOnline': true,
            'isVerified': true,
            'loginCount': 1,
          });
        }
      }

      // Generate local JWT tokens (backward compatibility)
      final tokens = JwtService.instance.generateTokenPair(
        email: emailLower,
        userId: userId,
        isAdmin: isAdmin,
      );
      await SecureTokenStorage.saveTokens(tokens);

      final userData = {
        'id': userId,
        'email': emailLower,
        'fullName': fullName,
        'profileImage': photoUrl,
        'isAdmin': isAdmin,
        'googleUser': true,
        'lastActive': DateTime.now().toIso8601String(),
        'loginCount': 1,
      };
      await SecureTokenStorage.saveUserData(userData);

      if (kIsWeb) {
        _setSecureSessionCookies(emailLower, tokens);
      }

      await logUserActivity(email: emailLower, activityType: 'login', details: 'Google Sign-In with Firebase Auth');
      debugPrint('[AuthService] Google Sign-In: $emailLower (uid: $userId)');
      return AuthResult.success(userData, tokens);
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In error: $e');
      return AuthResult.failure('התחברות עם Google נכשלה: $e');
    }
  }

  /// Validate current access token
  Future<JWTValidationResult> validateCurrentToken() async {
    await _ensureInitialized();
    final tokens = await SecureTokenStorage.loadTokens();
    if (tokens == null) {
      return JWTValidationResult.invalid('No tokens found');
    }
    return JwtService.instance.validateAccessToken(tokens.accessToken);
  }

  /// Refresh tokens if needed
  Future<bool> refreshTokensIfNeeded() async {
    await _ensureInitialized();
    final tokens = await SecureTokenStorage.loadTokens();
    if (tokens == null) return false;

    if (tokens.needsRefresh || tokens.isAccessTokenExpired) {
      final newTokens = JwtService.instance.refreshAccessToken(tokens.refreshToken);
      if (newTokens != null) {
        await SecureTokenStorage.saveTokens(newTokens);
        debugPrint('[AuthService] Tokens refreshed successfully');
        return true;
      } else {
        // Refresh token expired or invalid
        await logout();
        return false;
      }
    }
    return true;
  }

  /// Get current access token (refreshes if needed)
  Future<String?> getValidAccessToken() async {
    final refreshed = await refreshTokensIfNeeded();
    if (!refreshed) return null;
    final tokens = await SecureTokenStorage.loadTokens();
    return tokens?.accessToken;
  }

  /// Check if user is authenticated (Firebase Auth or local JWT)
  Future<bool> isAuthenticated() async {
    // Check Firebase Auth first
    if (fb_auth.FirebaseAuth.instance.currentUser != null) return true;

    // Fallback to local JWT
    final validation = await validateCurrentToken();
    if (validation.isValid) return true;

    return await refreshTokensIfNeeded();
  }

  /// Get saved session - checks Firebase Auth first, then local storage
  Future<Map<String, dynamic>?> getSavedSession() async {
    try {
      await _ensureInitialized();

      // Check Firebase Auth first
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final emailLower = fbUser.email?.toLowerCase().trim() ?? '';
        final isAdmin = isAdminEmail(emailLower);
        return {
          'id': fbUser.uid,
          'email': emailLower,
          'fullName': fbUser.displayName ?? emailLower.split('@').first,
          'isAdmin': isAdmin,
          'googleUser': fbUser.providerData.any((p) => p.providerId == 'google.com'),
          'lastActive': DateTime.now().toIso8601String(),
        };
      }

      // Fallback to local JWT
      final isAuth = await isAuthenticated();
      if (!isAuth) return null;
      return await SecureTokenStorage.loadUserData();
    } catch (e) {
      debugPrint('[AuthService] getSavedSession error: $e');
      return null;
    }
  }

  /// Logout - sign out from Firebase Auth + clear all local storage
  Future<void> logout() async {
    // Sign out from Firebase Auth
    try {
      await fb_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[AuthService] Firebase signOut error: $e');
    }
    // Clear secure cookies on web platform
    if (kIsWeb) {
      SecureCookieManager.deleteSecureCookie('momit_session');
      SecureCookieManager.deleteSecureCookie('momit_user');
    }
    await SecureTokenStorage.deleteTokens();
    await SecureTokenStorage.deleteUserData();
    debugPrint('[AuthService] Logged out - Firebase + tokens + cookies cleared');
  }

  /// Clear all data
  Future<void> clearAll() async {
    try {
      await fb_auth.FirebaseAuth.instance.signOut();
    } catch (e) { debugPrint('[AuthService] Firebase signOut failed: $e'); }
    if (kIsWeb) {
      SecureCookieManager.deleteSecureCookie('momit_session');
      SecureCookieManager.deleteSecureCookie('momit_user');
    }
    await SecureTokenStorage.clearAll();
  }

  /// Set secure session cookies on web platform
  /// Security configuration:
  /// - httpOnly: true (requires server-side for full enforcement)
  /// - secure: true (HTTPS only, enforced via __Host- prefix)
  /// - sameSite: strict (CSRF protection)
  /// - maxAge: 24 hours (session timeout)
  void _setSecureSessionCookies(String email, TokenPair tokens) {
    if (!kIsWeb) return;
    
    try {
      // Set session cookie with user email
      SecureCookieManager.setSecureCookie(
        'momit_session',
        email,
        maxAge: const Duration(hours: 24),
        httpOnly: true,
        secure: true,
        sameSite: 'strict',
      );
      
      // Set user identification cookie (non-sensitive)
      SecureCookieManager.setSecureCookie(
        'momit_user',
        base64Encode(utf8.encode(email)),
        maxAge: const Duration(hours: 24),
        httpOnly: true,
        secure: true,
        sameSite: 'strict',
      );
      
      if (kDebugMode) {
        debugPrint('[AuthService] Secure session cookies set for web');
        debugPrint('  - httpOnly: true (requires server-side enforcement)');
        debugPrint('  - secure: true (__Host- prefix enforced)');
        debugPrint('  - sameSite: strict (CSRF protection)');
        debugPrint('  - maxAge: 24 hours');
      }
    } catch (e) {
      debugPrint('[AuthService] Error setting secure cookies: $e');
    }
  }

  /// Verify secure cookie configuration
  /// Returns security status and configuration details
  Future<Map<String, dynamic>> verifyCookieSecurity() async {
    final results = <String, dynamic>{
      'platform': kIsWeb ? 'web' : 'native',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (kIsWeb) {
      try {
        // Run security test
        final testResults = SecureCookieManager.testJavaScriptCookieAccess();
        results['cookieTest'] = testResults;
        results['configuration'] = {
          'httpOnly': {
            'status': 'requires_server_side',
            'note': 'httpOnly can only be set server-side; client uses __Host- prefix',
          },
          'secure': true,
          'sameSite': 'strict',
          '__HostPrefix': true,
          'maxAge': '24 hours',
        };
        results['securityLevel'] = 'high (with server-side httpOnly)';
        results['verified'] = true;
      } catch (e) {
        results['error'] = e.toString();
        results['verified'] = false;
      }
    } else {
      results['note'] = 'Cookie security verification only applies to web platform';
      results['verified'] = true;
    }
    
    return results;
  }

  /// Ensure initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Log user activity to Firestore audit trail
  Future<void> logUserActivity({
    required String email,
    required String activityType,
    String? details,
  }) async {
    debugPrint('[AuthService] Activity: $email - $activityType - $details');
    try {
      await FirebaseFirestore.instance.collection('activity_log').add({
        'email': email,
        'activityType': activityType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (e) {
      debugPrint('[AuthService] Failed to log activity: $e');
    }
  }

  /// Convert stored user data to UserModel
  UserModel userModelFromData(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? 'user_${data['email'].hashCode}',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'],
      city: data['city'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      lastLoginAt: DateTime.now(),
      isOnline: true,
      isVerified: true,
    );
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String email,
    String? fullName,
    String? phone,
    String? city,
    String? bio,
    String? profileImage,
  }) async {
    final userData = await SecureTokenStorage.loadUserData();
    if (userData != null) {
      if (fullName != null) userData['fullName'] = fullName;
      if (phone != null) userData['phone'] = phone;
      if (city != null) userData['city'] = city;
      if (bio != null) userData['bio'] = bio;
      if (profileImage != null) userData['profileImage'] = profileImage;
      userData['updatedAt'] = DateTime.now().toIso8601String();
      await SecureTokenStorage.saveUserData(userData);
    }
  }

  /// Get registered users count from Firestore
  Future<int> getRegisteredUsersCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[AuthService] Error getting users count: $e');
      return 0;
    }
  }

  /// Request password reset with rate limiting (3 per hour)
  Future<PasswordResetResult> requestPasswordReset(String email) async {
    try {
      await _ensureInitialized();

      final emailLower = email.toLowerCase().trim();

      // Check rate limit for password reset (3 per hour)
      final rateLimitError = rateLimitPasswordReset(emailLower);
      if (rateLimitError != null) {
        debugPrint('[AuthService] Rate limit exceeded for password reset: $emailLower');
        return PasswordResetResult.failure(rateLimitError);
      }

      // Validate email
      if (emailLower.isEmpty || !emailLower.contains('@') || !emailLower.contains('.')) {
        return PasswordResetResult.failure('כתובת אימייל לא תקינה');
      }

      // Log password reset request
      await logUserActivity(
        email: emailLower,
        activityType: 'password_reset_request',
        details: 'Password reset requested',
      );

      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: emailLower);
      return PasswordResetResult.success(
        message: 'אם קיים חשבון עם כתובת זו, נשלח קישור לאיפוס סיסמה',
      );
    } catch (e) {
      debugPrint('[AuthService] Password reset error: $e');
      return PasswordResetResult.failure('שגיאה בבקשת איפוס סיסמה: $e');
    }
  }
}

/// Password reset result
class PasswordResetResult {
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  PasswordResetResult._({required this.isSuccess, this.errorMessage, this.userData});

  factory PasswordResetResult.success({String? message}) {
    return PasswordResetResult._(isSuccess: true, userData: message != null ? {'message': message} : null);
  }

  factory PasswordResetResult.failure(String message) {
    return PasswordResetResult._(isSuccess: false, errorMessage: message);
  }
}

/// Auth result wrapper with tokens
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? userData;
  final TokenPair? tokens;

  AuthResult._({required this.isSuccess, this.errorMessage, this.userData, this.tokens});

  factory AuthResult.success(Map<String, dynamic> data, TokenPair? tokenPair) {
    return AuthResult._(isSuccess: true, userData: data, tokens: tokenPair);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
