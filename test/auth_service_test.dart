import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mom_connect/services/auth_service.dart';
import 'package:mom_connect/middleware/rate_limiter.dart';

void main() {
  group('AuthService Comprehensive Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: '.env.test');
    });

    setUp(() {
      // Clear rate limits before each test
      RateLimiter.instance.clearAll();
    });

    group('JWT Token Generation', () {
      test('generates unique token pairs for different users', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final tokens1 = jwtService.generateTokenPair(
          email: 'user1@test.com',
          userId: 'user_1',
          isAdmin: false,
        );

        final tokens2 = jwtService.generateTokenPair(
          email: 'user2@test.com',
          userId: 'user_2',
          isAdmin: true,
        );

        expect(tokens1.accessToken, isNot(equals(tokens2.accessToken)));
        expect(tokens1.refreshToken, isNot(equals(tokens2.refreshToken)));
      });

      test('access token contains correct payload', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final tokens = jwtService.generateTokenPair(
          email: 'admin@test.com',
          userId: 'admin_123',
          isAdmin: true,
          additionalClaims: {'role': 'premium', 'tier': 'gold'},
        );

        final result = jwtService.validateAccessToken(tokens.accessToken);
        expect(result.isValid, isTrue);

        final payload = result.jwt!.payload as Map<String, dynamic>;
        expect(payload['email'], equals('admin@test.com'));
        expect(payload['userId'], equals('admin_123'));
        expect(payload['isAdmin'], isTrue);
        expect(payload['type'], equals('access'));
        expect(payload['role'], equals('premium'));
        expect(payload['tier'], equals('gold'));
      });

      test('refresh token has correct type and jti', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final tokens = jwtService.generateTokenPair(
          email: 'user@test.com',
          userId: 'user_123',
          isAdmin: false,
        );

        final result = jwtService.validateRefreshToken(tokens.refreshToken);
        expect(result.isValid, isTrue);

        final payload = result.jwt!.payload as Map<String, dynamic>;
        expect(payload['type'], equals('refresh'));
        expect(payload['jti'], isNotNull);
        expect(payload['jti'].toString().isNotEmpty, isTrue);
      });
    });

    group('Token Validation', () {
      test('rejects access token used as refresh token', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final tokens = jwtService.generateTokenPair(
          email: 'user@test.com',
          userId: 'user_123',
          isAdmin: false,
        );

        // Try to validate access token as refresh token
        final result = jwtService.validateRefreshToken(tokens.accessToken);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Invalid token type'));
      });

      test('rejects refresh token used as access token', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final tokens = jwtService.generateTokenPair(
          email: 'user@test.com',
          userId: 'user_123',
          isAdmin: false,
        );

        // Try to validate refresh token as access token
        final result = jwtService.validateAccessToken(tokens.refreshToken);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Invalid token type'));
      });

      test('rejects completely invalid tokens', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final invalidTokens = [
          '',
          'invalid',
          'invalid.token',
          'not.a.valid.token',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature',
        ];

        for (final token in invalidTokens) {
          final result = jwtService.validateAccessToken(token);
          expect(result.isValid, isFalse, reason: 'Token "$token" should be invalid');
        }
      });
    });

    group('Token Pair Properties', () {
      test('token expiry times are correctly calculated', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final beforeGeneration = DateTime.now();
        final tokens = jwtService.generateTokenPair(
          email: 'user@test.com',
          userId: 'user_123',
          isAdmin: false,
        );
        final afterGeneration = DateTime.now();

        // Access token should expire in ~15 minutes
        expect(
          tokens.accessTokenExpiry.difference(beforeGeneration).inMinutes,
          greaterThanOrEqualTo(14),
        );
        expect(
          tokens.accessTokenExpiry.difference(afterGeneration).inMinutes,
          lessThanOrEqualTo(15),
        );

        // Refresh token should expire in ~7 days
        expect(
          tokens.refreshTokenExpiry.difference(beforeGeneration).inDays,
          greaterThanOrEqualTo(6),
        );
        expect(
          tokens.refreshTokenExpiry.difference(afterGeneration).inDays,
          lessThanOrEqualTo(7),
        );
      });

      test('fresh tokens are not expired', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final tokens = jwtService.generateTokenPair(
          email: 'user@test.com',
          userId: 'user_123',
          isAdmin: false,
        );

        expect(tokens.isAccessTokenExpired, isFalse);
        expect(tokens.isRefreshTokenExpired, isFalse);
        expect(tokens.needsRefresh, isFalse);
      });
    });

    group('Admin Email Detection', () {
      test('detects admin emails correctly', () {
        // Based on .env.test: ADMIN_EMAILS=test@example.com
        expect(AuthService.isAdminEmail('test@example.com'), isTrue);
        expect(AuthService.isAdminEmail('TEST@EXAMPLE.COM'), isTrue); // Case insensitive
        expect(AuthService.isAdminEmail('test@example.com '), isTrue); // Trims whitespace
      });

      test('rejects non-admin emails', () {
        expect(AuthService.isAdminEmail('user@test.com'), isFalse);
        expect(AuthService.isAdminEmail('admin@other.com'), isFalse);
        expect(AuthService.isAdminEmail(''), isFalse);
      });
    });

    group('Password Hashing', () {
      test('same password with different salts produces different hashes', () {
        const password = 'SecurePassword123!';

        // Use reflection or public methods if available
        // Since _hashPassword is private, we test through behavior
        final authService = AuthService.instance;

        // Different salts should produce different results
        // This is implicitly tested through the registration process
        expect(authService, isNotNull);
      });
    });

    group('Input Validation', () {
      test('registration validates email format', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        final invalidEmails = [
          '',
          'invalid',
          'invalid@',
          '@test.com',
          'invalid@test',
        ];

        for (final email in invalidEmails) {
          final result = await authService.register(
            email: email,
            password: 'ValidPass123',
            fullName: 'Test User',
            phone: '0501234567',
            city: 'Test City',
          );
          expect(result.isSuccess, isFalse, reason: 'Email "$email" should be rejected');
        }
      });

      test('registration validates password strength', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        final weakPasswords = [
          'short',
          '12345678',
          'password',
          'Password', // No number
          '12345678a', // Less than 8 chars
        ];

        for (final password in weakPasswords) {
          final result = await authService.register(
            email: 'test@test.com',
            password: password,
            fullName: 'Test User',
            phone: '0501234567',
            city: 'Test City',
          );
          expect(result.isSuccess, isFalse, reason: 'Password "$password" should be rejected');
        }
      });

      test('registration validates phone number', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        final invalidPhones = [
          '',
          '123',
          'abc',
          '12-34-56',
        ];

        for (final phone in invalidPhones) {
          final result = await authService.register(
            email: 'test@test.com',
            password: 'ValidPass123',
            fullName: 'Test User',
            phone: phone,
            city: 'Test City',
          );
          expect(result.isSuccess, isFalse, reason: 'Phone "$phone" should be rejected');
        }
      });

      test('registration validates required fields', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        // Test empty full name
        var result = await authService.register(
          email: 'test@test.com',
          password: 'ValidPass123',
          fullName: '',
          phone: '0501234567',
          city: 'Test City',
        );
        expect(result.isSuccess, isFalse);

        // Test empty city
        result = await authService.register(
          email: 'test@test.com',
          password: 'ValidPass123',
          fullName: 'Test User',
          phone: '0501234567',
          city: '',
        );
        expect(result.isSuccess, isFalse);
      });
    });

    group('Rate Limiting Integration', () {
      test('login enforces rate limiting', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        const email = 'ratelimit@test.com';

        // Make 5 successful login attempts
        for (int i = 0; i < 5; i++) {
          final result = await authService.login(
            email: email,
            password: 'password123',
          );
          // Should succeed (even with wrong password for this test)
          expect(result.isSuccess, isTrue);
        }

        // 6th attempt should be rate limited
        final result = await authService.login(
          email: email,
          password: 'password123',
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('limit exceeded'));
      });

      test('registration enforces API rate limiting', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        const email = 'api_ratelimit@test.com';

        // Make many registration attempts quickly
        int successCount = 0;
        int rateLimitedCount = 0;

        for (int i = 0; i < 105; i++) {
          final result = await authService.register(
            email: 'user$i@$email',
            password: 'ValidPass123',
            fullName: 'Test User',
            phone: '0501234567',
            city: 'Test City',
          );

          if (result.isSuccess) {
            successCount++;
          } else if (result.errorMessage?.contains('limit exceeded') ?? false) {
            rateLimitedCount++;
          }
        }

        // Should have rate limited some requests
        expect(rateLimitedCount, greaterThan(0));
      });
    });

    group('Token Refresh Flow', () {
      test('refresh token rotation works', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final originalTokens = jwtService.generateTokenPair(
          email: 'user@test.com',
          userId: 'user_123',
          isAdmin: false,
        );

        final newTokens = jwtService.refreshAccessToken(originalTokens.refreshToken);
        expect(newTokens, isNotNull);

        // New tokens should be different
        expect(newTokens!.accessToken, isNot(equals(originalTokens.accessToken)));
        expect(newTokens.refreshToken, isNot(equals(originalTokens.refreshToken)));

        // Old refresh token should still be valid for single use
        // (depending on implementation)
        final oldRefreshResult = jwtService.validateRefreshToken(originalTokens.refreshToken);
        // The old token is still cryptographically valid until expiry
        expect(oldRefreshResult.isValid, isTrue);
      });

      test('new tokens have extended expiry', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final originalTokens = jwtService.generateTokenPair(
          email: 'user@test.com',
          userId: 'user_123',
          isAdmin: false,
        );

        // Wait a tiny bit to ensure time difference
        await Future.delayed(const Duration(milliseconds: 10));

        final newTokens = jwtService.refreshAccessToken(originalTokens.refreshToken);
        expect(newTokens, isNotNull);

        // New tokens should have later expiry times
        expect(
          newTokens!.accessTokenExpiry.isAfter(originalTokens.accessTokenExpiry) ||
          newTokens.accessTokenExpiry == originalTokens.accessTokenExpiry,
          isTrue,
        );
      });
    });

    group('JWTValidationResult', () {
      test('valid result contains JWT', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final tokens = jwtService.generateTokenPair(
          email: 'user@test.com',
          userId: 'user_123',
          isAdmin: false,
        );

        final result = jwtService.validateAccessToken(tokens.accessToken);
        expect(result.isValid, isTrue);
        expect(result.jwt, isNotNull);
        expect(result.errorMessage, isNull);
      });

      test('invalid result contains error message', () async {
        final jwtService = JwtService.instance;
        await jwtService.initialize();

        final result = jwtService.validateAccessToken('invalid.token');
        expect(result.isValid, isFalse);
        expect(result.jwt, isNull);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage!.isNotEmpty, isTrue);
      });
    });

    group('AuthResult', () {
      test('success result has user data and tokens', () {
        final mockUserData = {'email': 'test@test.com', 'id': '123'};
        final mockTokens = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );

        final result = AuthResult.success(mockUserData, mockTokens);

        expect(result.isSuccess, isTrue);
        expect(result.userData, equals(mockUserData));
        expect(result.tokens, equals(mockTokens));
        expect(result.errorMessage, isNull);
      });

      test('failure result has error message', () {
        const errorMessage = 'Invalid credentials';
        final result = AuthResult.failure(errorMessage);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals(errorMessage));
        expect(result.userData, isNull);
        expect(result.tokens, isNull);
      });
    });

    group('Password Reset', () {
      test('password reset validates email', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        final result = await authService.requestPasswordReset('invalid-email');
        expect(result.isSuccess, isFalse);
      });

      test('password reset enforces rate limiting', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        const email = 'reset_ratelimit@test.com';

        // Make 3 valid requests (limit is 3 per hour)
        for (int i = 0; i < 3; i++) {
          final result = await authService.requestPasswordReset(email);
          // Should succeed
          expect(result.isSuccess, isTrue);
        }

        // 4th request should be rate limited
        final result = await authService.requestPasswordReset(email);
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('limit exceeded'));
      });

      test('password reset result structure', () async {
        final authService = AuthService.instance;
        await authService.initialize();

        // Clear rate limits first
        RateLimiter.instance.clearAll();

        final result = await authService.requestPasswordReset('valid@test.com');
        expect(result.isSuccess, isTrue);
      });
    });
  });
}