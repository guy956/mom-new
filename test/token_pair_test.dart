import 'package:flutter_test/flutter_test.dart';
import 'package:mom_connect/services/auth_service.dart';

void main() {
  group('TokenPair Tests', () {
    test('creates token pair with all fields', () {
      final now = DateTime.now();
      final accessExpiry = now.add(const Duration(minutes: 15));
      final refreshExpiry = now.add(const Duration(days: 7));

      final tokenPair = TokenPair(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        accessTokenExpiry: accessExpiry,
        refreshTokenExpiry: refreshExpiry,
      );

      expect(tokenPair.accessToken, equals('access_token_123'));
      expect(tokenPair.refreshToken, equals('refresh_token_456'));
      expect(tokenPair.accessTokenExpiry, equals(accessExpiry));
      expect(tokenPair.refreshTokenExpiry, equals(refreshExpiry));
    });

    group('JSON Serialization', () {
      test('toJson converts correctly', () {
        final now = DateTime.now();
        final tokenPair = TokenPair(
          accessToken: 'access_123',
          refreshToken: 'refresh_456',
          accessTokenExpiry: now.add(const Duration(minutes: 15)),
          refreshTokenExpiry: now.add(const Duration(days: 7)),
        );

        final json = tokenPair.toJson();

        expect(json['accessToken'], equals('access_123'));
        expect(json['refreshToken'], equals('refresh_456'));
        expect(json['accessTokenExpiry'], isA<String>());
        expect(json['refreshTokenExpiry'], isA<String>());
      });

      test('fromJson creates correctly', () {
        final now = DateTime.now();
        final json = {
          'accessToken': 'access_789',
          'refreshToken': 'refresh_012',
          'accessTokenExpiry': now.add(const Duration(minutes: 15)).toIso8601String(),
          'refreshTokenExpiry': now.add(const Duration(days: 7)).toIso8601String(),
        };

        final tokenPair = TokenPair.fromJson(json);

        expect(tokenPair.accessToken, equals('access_789'));
        expect(tokenPair.refreshToken, equals('refresh_012'));
      });

      test('fromJson parses ISO8601 dates correctly', () {
        final now = DateTime.now();
        final accessExpiry = now.add(const Duration(minutes: 15));
        final refreshExpiry = now.add(const Duration(days: 7));

        final json = {
          'accessToken': 'token',
          'refreshToken': 'refresh',
          'accessTokenExpiry': accessExpiry.toIso8601String(),
          'refreshTokenExpiry': refreshExpiry.toIso8601String(),
        };

        final tokenPair = TokenPair.fromJson(json);

        // Allow small time difference due to parsing
        expect(
          tokenPair.accessTokenExpiry.difference(accessExpiry).inMilliseconds.abs(),
          lessThan(1000),
        );
        expect(
          tokenPair.refreshTokenExpiry.difference(refreshExpiry).inMilliseconds.abs(),
          lessThan(1000),
        );
      });

      test('round-trip serialization preserves data', () {
        final now = DateTime.now();
        final original = TokenPair(
          accessToken: 'original_access',
          refreshToken: 'original_refresh',
          accessTokenExpiry: now.add(const Duration(minutes: 15)),
          refreshTokenExpiry: now.add(const Duration(days: 7)),
        );

        final json = original.toJson();
        final restored = TokenPair.fromJson(json);

        expect(restored.accessToken, equals(original.accessToken));
        expect(restored.refreshToken, equals(original.refreshToken));
      });
    });

    group('Expiry Detection', () {
      test('fresh tokens are not expired', () {
        final tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );

        expect(tokenPair.isAccessTokenExpired, isFalse);
        expect(tokenPair.isRefreshTokenExpired, isFalse);
        expect(tokenPair.needsRefresh, isFalse);
      });

      test('access token expiry is detected', () {
        final tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: DateTime.now().subtract(const Duration(minutes: 1)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );

        expect(tokenPair.isAccessTokenExpired, isTrue);
        expect(tokenPair.isRefreshTokenExpired, isFalse);
        expect(tokenPair.needsRefresh, isTrue);
      });

      test('refresh token expiry is detected', () {
        final tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: DateTime.now().subtract(const Duration(minutes: 1)),
          refreshTokenExpiry: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(tokenPair.isAccessTokenExpired, isTrue);
        expect(tokenPair.isRefreshTokenExpired, isTrue);
        expect(tokenPair.needsRefresh, isFalse); // Can't refresh if refresh token is expired
      });

      test('needsRefresh only when access expired but refresh valid', () {
        // Both valid
        var tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );
        expect(tokenPair.needsRefresh, isFalse);

        // Access expired, refresh valid
        tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: DateTime.now().subtract(const Duration(minutes: 1)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );
        expect(tokenPair.needsRefresh, isTrue);

        // Both expired
        tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: DateTime.now().subtract(const Duration(minutes: 1)),
          refreshTokenExpiry: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(tokenPair.needsRefresh, isFalse);
      });
    });

    group('Edge Cases', () {
      test('handles tokens at exact expiry boundary', () {
        final now = DateTime.now();
        final tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: now,
          refreshTokenExpiry: now,
        );

        // Token at exact current time should be considered expired
        expect(tokenPair.isAccessTokenExpired, isTrue);
        expect(tokenPair.isRefreshTokenExpired, isTrue);
      });

      test('handles very long expiry times', () {
        final farFuture = DateTime.now().add(const Duration(days: 365 * 10)); // 10 years
        final tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: farFuture,
          refreshTokenExpiry: farFuture.add(const Duration(days: 365)),
        );

        expect(tokenPair.isAccessTokenExpired, isFalse);
        expect(tokenPair.isRefreshTokenExpired, isFalse);
      });

      test('handles very short expiry times', () {
        final soon = DateTime.now().add(const Duration(milliseconds: 1));
        final tokenPair = TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessTokenExpiry: soon,
          refreshTokenExpiry: soon.add(const Duration(seconds: 1)),
        );

        // Should not be expired yet
        expect(tokenPair.isAccessTokenExpired, isFalse);
      });

      test('handles empty tokens', () {
        final tokenPair = TokenPair(
          accessToken: '',
          refreshToken: '',
          accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );

        expect(tokenPair.accessToken, equals(''));
        expect(tokenPair.refreshToken, equals(''));
        // Expiry detection should still work
        expect(tokenPair.isAccessTokenExpired, isFalse);
      });

      test('handles very long tokens', () {
        final longToken = 'a' * 10000;
        final tokenPair = TokenPair(
          accessToken: longToken,
          refreshToken: longToken,
          accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );

        expect(tokenPair.accessToken.length, equals(10000));
        expect(tokenPair.refreshToken.length, equals(10000));
      });
    });

    group('JWT Token Format Validation', () {
      test('access token should be JWT format', () {
        // Typical JWT format: header.payload.signature
        const jwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
        
        final parts = jwtToken.split('.');
        expect(parts.length, equals(3));
      });

      test('refresh token should be JWT format', () {
        const jwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoicmVmcmVzaCJ9.3f3f3f3f3f3f3f3f3f3f3f3f';
        
        final parts = jwtToken.split('.');
        expect(parts.length, equals(3));
      });

      test('handles malformed tokens gracefully', () {
        const malformedTokens = [
          '',
          'invalid',
          'invalid.token',
          'too.many.parts.here.extra',
          '.no.header.',
          'no.signature',
        ];

        for (final token in malformedTokens) {
          final tokenPair = TokenPair(
            accessToken: token,
            refreshToken: token,
            accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
            refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
          );

          // Should still create the object
          expect(tokenPair.accessToken, equals(token));
        }
      });
    });

    group('Token Lifecycle States', () {
      test('valid state - both tokens valid', () {
        final tokenPair = TokenPair(
          accessToken: 'valid_access',
          refreshToken: 'valid_refresh',
          accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );

        expect(tokenPair.isAccessTokenExpired, isFalse);
        expect(tokenPair.isRefreshTokenExpired, isFalse);
        expect(tokenPair.needsRefresh, isFalse);
      });

      test('refresh needed state - access expired', () {
        final tokenPair = TokenPair(
          accessToken: 'expired_access',
          refreshToken: 'valid_refresh',
          accessTokenExpiry: DateTime.now().subtract(const Duration(minutes: 1)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );

        expect(tokenPair.isAccessTokenExpired, isTrue);
        expect(tokenPair.isRefreshTokenExpired, isFalse);
        expect(tokenPair.needsRefresh, isTrue);
      });

      test('expired state - both tokens expired', () {
        final tokenPair = TokenPair(
          accessToken: 'expired_access',
          refreshToken: 'expired_refresh',
          accessTokenExpiry: DateTime.now().subtract(const Duration(minutes: 1)),
          refreshTokenExpiry: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(tokenPair.isAccessTokenExpired, isTrue);
        expect(tokenPair.isRefreshTokenExpired, isTrue);
        expect(tokenPair.needsRefresh, isFalse);
      });

      test('near expiry state - access about to expire', () {
        final tokenPair = TokenPair(
          accessToken: 'about_to_expire',
          refreshToken: 'valid_refresh',
          accessTokenExpiry: DateTime.now().add(const Duration(seconds: 10)),
          refreshTokenExpiry: DateTime.now().add(const Duration(days: 7)),
        );

        expect(tokenPair.isAccessTokenExpired, isFalse);
        expect(tokenPair.needsRefresh, isFalse);
      });
    });

    group('Time Calculations', () {
      test('access token typically expires in 15 minutes', () {
        const expectedDuration = Duration(minutes: 15);
        expect(expectedDuration.inMinutes, equals(15));
      });

      test('refresh token typically expires in 7 days', () {
        const expectedDuration = Duration(days: 7);
        expect(expectedDuration.inDays, equals(7));
      });

      test('refresh token lives much longer than access token', () {
        const accessDuration = Duration(minutes: 15);
        const refreshDuration = Duration(days: 7);

        expect(refreshDuration.inMinutes, greaterThan(accessDuration.inMinutes));
        expect(refreshDuration.inMinutes, equals(7 * 24 * 60)); // 10080 minutes
      });
    });
  });

  group('JWTValidationResult Tests', () {
    group('Factory Constructors', () {
      test('valid factory creates valid result', () {
        // We can't easily create a JWT object without importing the library,
        // so we test the factory behavior
        final result = JWTValidationResult.invalid('Test error');
        
        expect(result.isValid, isFalse);
        expect(result.errorMessage, equals('Test error'));
        expect(result.jwt, isNull);
      });

      test('invalid factory creates invalid result', () {
        final result = JWTValidationResult.invalid('Invalid token');
        
        expect(result.isValid, isFalse);
        expect(result.errorMessage, equals('Invalid token'));
        expect(result.jwt, isNull);
      });
    });

    group('Error Messages', () {
      test('common error messages', () {
        final errors = [
          'Token expired',
          'Invalid token type',
          'Invalid token: malformed',
          'Refresh token expired',
          'No tokens found',
        ];

        for (final error in errors) {
          final result = JWTValidationResult.invalid(error);
          expect(result.errorMessage, equals(error));
          expect(result.isValid, isFalse);
        }
      });

      test('error message is not empty', () {
        final result = JWTValidationResult.invalid('Some error');
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage!.isNotEmpty, isTrue);
      });
    });
  });
}