import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mom_connect/services/auth_service.dart';

void main() {
  group('JWT Secure Implementation Tests', () {
    setUpAll(() async {
      // Load test environment
      await dotenv.load(fileName: '.env.test');
    });

    test('JWT Service initializes from environment variables', () async {
      final jwtService = JwtService.instance;
      await jwtService.initialize();
      
      // Should not throw - secrets loaded from env
      expect(() => jwtService.generateTokenPair(
        email: 'test@test.com',
        userId: 'user_123',
        isAdmin: false,
      ), returnsNormally);
    });

    test('Token generation creates valid token pair', () async {
      final jwtService = JwtService.instance;
      await jwtService.initialize();
      
      final tokens = jwtService.generateTokenPair(
        email: 'test@test.com',
        userId: 'user_123',
        isAdmin: true,
        additionalClaims: {'role': 'premium'},
      );
      
      expect(tokens.accessToken, isNotEmpty);
      expect(tokens.refreshToken, isNotEmpty);
      expect(tokens.accessTokenExpiry.isAfter(DateTime.now()), isTrue);
      expect(tokens.refreshTokenExpiry.isAfter(tokens.accessTokenExpiry), isTrue);
      expect(tokens.isAccessTokenExpired, isFalse);
    });

    test('Access token validation works correctly', () async {
      final jwtService = JwtService.instance;
      await jwtService.initialize();
      
      final tokens = jwtService.generateTokenPair(
        email: 'test@test.com',
        userId: 'user_123',
        isAdmin: false,
      );
      
      final result = jwtService.validateAccessToken(tokens.accessToken);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      
      final payload = result.jwt!.payload as Map<String, dynamic>;
      expect(payload['email'], equals('test@test.com'));
      expect(payload['type'], equals('access'));
    });

    test('Invalid token is rejected', () async {
      final jwtService = JwtService.instance;
      await jwtService.initialize();
      
      final result = jwtService.validateAccessToken('invalid.token.here');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('Refresh token validation works', () async {
      final jwtService = JwtService.instance;
      await jwtService.initialize();
      
      final tokens = jwtService.generateTokenPair(
        email: 'test@test.com',
        userId: 'user_123',
        isAdmin: false,
      );
      
      final result = jwtService.validateRefreshToken(tokens.refreshToken);
      expect(result.isValid, isTrue);
      
      final payload = result.jwt!.payload as Map<String, dynamic>;
      expect(payload['type'], equals('refresh'));
      expect(payload['jti'], isNotNull); // Token ID present
    });

    test('Token refresh generates new pair', () async {
      final jwtService = JwtService.instance;
      await jwtService.initialize();
      
      final originalTokens = jwtService.generateTokenPair(
        email: 'test@test.com',
        userId: 'user_123',
        isAdmin: false,
      );
      
      final newTokens = jwtService.refreshAccessToken(originalTokens.refreshToken);
      expect(newTokens, isNotNull);
      expect(newTokens!.accessToken, isNot(equals(originalTokens.accessToken)));
      expect(newTokens.refreshToken, isNot(equals(originalTokens.refreshToken)));
    });

    test('Expired refresh token cannot be used', () async {
      final jwtService = JwtService.instance;
      await jwtService.initialize();
      
      // Create an expired token by manipulating the creation
      final expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoicmVmcmVzaCIsImV4cCI6MTYwMDAwMDAwMH0.invalid';
      
      final result = jwtService.refreshAccessToken(expiredToken);
      expect(result, isNull);
    });

    test('Token pair expiry detection works', () async {
      final jwtService = JwtService.instance;
      await jwtService.initialize();
      
      final tokens = jwtService.generateTokenPair(
        email: 'test@test.com',
        userId: 'user_123',
        isAdmin: false,
      );
      
      expect(tokens.isAccessTokenExpired, isFalse);
      expect(tokens.isRefreshTokenExpired, isFalse);
      expect(tokens.needsRefresh, isFalse);
    });
  });
}
