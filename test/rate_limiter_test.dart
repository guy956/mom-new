import 'package:flutter_test/flutter_test.dart';
import 'package:mom_connect/middleware/rate_limiter.dart';

void main() {
  group('RateLimiter Tests', () {
    setUp(() {
      // Clear rate limiter before each test
      RateLimiter.instance.clearAll();
    });

    group('RateLimiter Singleton', () {
      test('is singleton', () {
        final instance1 = RateLimiter.instance;
        final instance2 = RateLimiter.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('RateLimitConfig', () {
      test('login config has correct values', () {
        const config = RateLimitConfig.login;

        expect(config.maxRequests, equals(5));
        expect(config.window, equals(const Duration(minutes: 1)));
        expect(config.name, equals('login'));
      });

      test('api config has correct values', () {
        const config = RateLimitConfig.api;

        expect(config.maxRequests, equals(100));
        expect(config.window, equals(const Duration(minutes: 1)));
        expect(config.name, equals('api'));
      });

      test('passwordReset config has correct values', () {
        const config = RateLimitConfig.passwordReset;

        expect(config.maxRequests, equals(3));
        expect(config.window, equals(const Duration(hours: 1)));
        expect(config.name, equals('password_reset'));
      });

      test('custom config can be created', () {
        const customConfig = RateLimitConfig(
          maxRequests: 10,
          window: Duration(seconds: 30),
          name: 'custom',
        );

        expect(customConfig.maxRequests, equals(10));
        expect(customConfig.window, equals(const Duration(seconds: 30)));
        expect(customConfig.name, equals('custom'));
      });
    });

    group('Rate Limit Checking', () {
      test('allows requests within limit', () {
        final limiter = RateLimiter.instance;
        const identifier = 'user_123';
        const config = RateLimitConfig.login;

        // First 5 requests should be allowed
        for (int i = 0; i < 5; i++) {
          final result = limiter.checkLimit(identifier, config);
          expect(result.allowed, isTrue, reason: 'Request ${i + 1} should be allowed');
          expect(result.remaining, equals(4 - i));
        }
      });

      test('blocks requests over limit', () {
        final limiter = RateLimiter.instance;
        const identifier = 'user_456';
        const config = RateLimitConfig(
          maxRequests: 3,
          window: Duration(minutes: 1),
          name: 'test',
        );

        // First 3 requests allowed
        for (int i = 0; i < 3; i++) {
          final result = limiter.checkLimit(identifier, config);
          expect(result.allowed, isTrue);
        }

        // 4th request blocked
        final blockedResult = limiter.checkLimit(identifier, config);
        expect(blockedResult.allowed, isFalse);
        expect(blockedResult.remaining, equals(0));
        expect(blockedResult.errorMessage, isNotNull);
        expect(blockedResult.errorMessage, contains('limit exceeded'));
      });

      test('different identifiers have separate buckets', () {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig(
          maxRequests: 3,
          window: Duration(minutes: 1),
          name: 'test',
        );

        // Exhaust limit for user_1
        for (int i = 0; i < 3; i++) {
          limiter.checkLimit('user_1', config);
        }

        // user_1 should be blocked
        final user1Result = limiter.checkLimit('user_1', config);
        expect(user1Result.allowed, isFalse);

        // user_2 should still be allowed
        final user2Result = limiter.checkLimit('user_2', config);
        expect(user2Result.allowed, isTrue);
      });

      test('different configs have separate buckets', () {
        final limiter = RateLimiter.instance;
        const identifier = 'user_789';

        // Exhaust login limit
        for (int i = 0; i < 5; i++) {
          limiter.checkLoginLimit(identifier);
        }

        // Login should be blocked
        final loginResult = limiter.checkLoginLimit(identifier);
        expect(loginResult.allowed, isFalse);

        // But API calls should still be allowed (different bucket)
        final apiResult = limiter.checkApiLimit(identifier);
        expect(apiResult.allowed, isTrue);
      });
    });

    group('Rate Limit Result', () {
      test('success result has correct properties', () {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig.login;

        final result = limiter.checkLimit('test_user', config);

        expect(result.allowed, isTrue);
        expect(result.limit, equals(5));
        expect(result.remaining, equals(4));
        expect(result.resetInSeconds, equals(60));
        expect(result.errorMessage, isNull);
      });

      test('blocked result has reset time', () {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig(
          maxRequests: 1,
          window: Duration(minutes: 1),
          name: 'test',
        );

        // First request
        limiter.checkLimit('blocked_user', config);

        // Second request blocked
        final result = limiter.checkLimit('blocked_user', config);

        expect(result.allowed, isFalse);
        expect(result.resetInSeconds, greaterThan(0));
        expect(result.resetInSeconds, lessThanOrEqualTo(60));
      });

      test('toString provides useful info', () {
        const result = RateLimitResult(
          allowed: true,
          limit: 5,
          remaining: 3,
          resetInSeconds: 60,
        );

        final str = result.toString();
        expect(str, contains('allowed: true'));
        expect(str, contains('remaining: 3'));
        expect(str, contains('limit: 5'));
      });
    });

    group('RateLimitMixin', () {
      test('mixin provides rate limiting methods', () {
        final service = TestServiceWithRateLimit();

        // Test that methods exist and work
        expect(service.rateLimitLogin('test'), isNull); // First call allowed

        // Exhaust login limit
        for (int i = 0; i < 4; i++) {
          service.rateLimitLogin('test');
        }

        // Next call should be rate limited
        final error = service.rateLimitLogin('test');
        expect(error, isNotNull);
        expect(error, contains('limit exceeded'));
      });

      test('rateLimitApiCall works', () {
        final service = TestServiceWithRateLimit();

        // API limit is 100, so many calls should work
        for (int i = 0; i < 100; i++) {
          final error = service.rateLimitApiCall('api_user');
          expect(error, isNull, reason: 'Call $i should not be rate limited');
        }

        // 101st call should be rate limited
        final error = service.rateLimitApiCall('api_user');
        expect(error, isNotNull);
        expect(error, contains('limit exceeded'));
      });

      test('rateLimitPasswordReset works', () {
        final service = TestServiceWithRateLimit();

        // First 3 calls allowed
        for (int i = 0; i < 3; i++) {
          expect(service.rateLimitPasswordReset('reset_user'), isNull);
        }

        // 4th call blocked
        final error = service.rateLimitPasswordReset('reset_user');
        expect(error, isNotNull);
        expect(error, contains('limit exceeded'));
      });

      test('enforceRateLimit throws exception when exceeded', () {
        final service = TestServiceWithRateLimit();
        const config = RateLimitConfig(
          maxRequests: 1,
          window: Duration(minutes: 1),
          name: 'test',
        );

        // First call should not throw
        service.enforceRateLimit('enforce_user', config);

        // Second call should throw
        expect(
          () => service.enforceRateLimit('enforce_user', config),
          throwsA(isA<RateLimitExceededException>()),
        );
      });
    });

    group('RateLimitExceededException', () {
      test('exception contains message and result', () {
        const result = RateLimitResult(
          allowed: false,
          limit: 5,
          remaining: 0,
          resetInSeconds: 60,
          errorMessage: 'Rate limit exceeded',
        );

        final exception = RateLimitExceededException('Too many requests', result);

        expect(exception.message, equals('Too many requests'));
        expect(exception.result, equals(result));
        expect(exception.toString(), contains('Too many requests'));
      });
    });

    group('Clearing and Stats', () {
      test('clearAll removes all rate limits', () {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig.login;

        // Exhaust limit
        for (int i = 0; i < 5; i++) {
          limiter.checkLimit('clear_test', config);
        }

        // Should be blocked
        expect(limiter.checkLimit('clear_test', config).allowed, isFalse);

        // Clear all
        limiter.clearAll();

        // Should be allowed again
        expect(limiter.checkLimit('clear_test', config).allowed, isTrue);
      });

      test('clearForIdentifier removes specific identifier', () {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig.login;

        // Exhaust limit for user_1
        for (int i = 0; i < 5; i++) {
          limiter.checkLimit('user_1', config);
        }
        // Exhaust limit for user_2
        for (int i = 0; i < 5; i++) {
          limiter.checkLimit('user_2', config);
        }

        // Both blocked
        expect(limiter.checkLimit('user_1', config).allowed, isFalse);
        expect(limiter.checkLimit('user_2', config).allowed, isFalse);

        // Clear only user_1
        limiter.clearForIdentifier('user_1');

        // user_1 allowed, user_2 still blocked
        expect(limiter.checkLimit('user_1', config).allowed, isTrue);
        expect(limiter.checkLimit('user_2', config).allowed, isFalse);
      });

      test('getStats returns statistics', () {
        final limiter = RateLimiter.instance;

        // Initially empty
        var stats = limiter.getStats();
        expect(stats, isEmpty);

        // Add some traffic
        limiter.checkLoginLimit('user_1');
        limiter.checkLoginLimit('user_2');
        limiter.checkApiLimit('user_1');

        stats = limiter.getStats();
        expect(stats.containsKey('login'), isTrue);
        expect(stats.containsKey('api'), isTrue);
      });
    });

    group('Time Window Behavior', () {
      test('requests outside window are not counted', () async {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig(
          maxRequests: 2,
          window: Duration(milliseconds: 100),
          name: 'fast_test',
        );

        // Exhaust limit
        limiter.checkLimit('window_test', config);
        limiter.checkLimit('window_test', config);

        // Should be blocked
        expect(limiter.checkLimit('window_test', config).allowed, isFalse);

        // Wait for window to expire
        await Future.delayed(const Duration(milliseconds: 150));

        // Should be allowed again
        final result = limiter.checkLimit('window_test', config);
        expect(result.allowed, isTrue);
      });

      test('oldest request is removed first', () async {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig(
          maxRequests: 3,
          window: Duration(milliseconds: 200),
          name: 'fifo_test',
        );

        // Make 3 requests
        limiter.checkLimit('fifo_test', config);
        await Future.delayed(const Duration(milliseconds: 50));
        limiter.checkLimit('fifo_test', config);
        await Future.delayed(const Duration(milliseconds: 50));
        limiter.checkLimit('fifo_test', config);

        // Should be at limit
        expect(limiter.checkLimit('fifo_test', config).allowed, isFalse);

        // Wait for first request to expire
        await Future.delayed(const Duration(milliseconds: 150));

        // Should have 1 slot available
        final result = limiter.checkLimit('fifo_test', config);
        expect(result.allowed, isTrue);
        expect(result.remaining, equals(0));
      });
    });

    group('Convenience Methods', () {
      test('checkLoginLimit uses login config', () {
        final limiter = RateLimiter.instance;

        // Should allow 5 requests
        for (int i = 0; i < 5; i++) {
          final result = limiter.checkLoginLimit('login_test');
          expect(result.allowed, isTrue);
        }

        // 6th should be blocked
        final result = limiter.checkLoginLimit('login_test');
        expect(result.allowed, isFalse);
      });

      test('checkApiLimit uses api config', () {
        final limiter = RateLimiter.instance;

        // Should allow 100 requests
        for (int i = 0; i < 100; i++) {
          final result = limiter.checkApiLimit('api_test');
          expect(result.allowed, isTrue);
        }

        // 101st should be blocked
        final result = limiter.checkApiLimit('api_test');
        expect(result.allowed, isFalse);
      });

      test('checkPasswordResetLimit uses passwordReset config', () {
        final limiter = RateLimiter.instance;

        // Should allow 3 requests
        for (int i = 0; i < 3; i++) {
          final result = limiter.checkPasswordResetLimit('reset_test');
          expect(result.allowed, isTrue);
        }

        // 4th should be blocked
        final result = limiter.checkPasswordResetLimit('reset_test');
        expect(result.allowed, isFalse);
      });
    });

    group('Error Message Formatting', () {
      test('formats hours correctly', () async {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig(
          maxRequests: 1,
          window: Duration(hours: 1),
          name: 'hour_test',
        );

        limiter.checkLimit('hour_format', config);
        final result = limiter.checkLimit('hour_format', config);

        expect(result.errorMessage, contains('hour'));
      });

      test('formats minutes correctly', () {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig(
          maxRequests: 1,
          window: Duration(minutes: 5),
          name: 'minute_test',
        );

        limiter.checkLimit('minute_format', config);
        final result = limiter.checkLimit('minute_format', config);

        expect(result.errorMessage, contains('minute'));
      });

      test('formats seconds correctly', () async {
        final limiter = RateLimiter.instance;
        const config = RateLimitConfig(
          maxRequests: 1,
          window: Duration(seconds: 5),
          name: 'second_test',
        );

        limiter.checkLimit('second_format', config);
        // Wait a bit so reset time is less than a minute
        await Future.delayed(const Duration(seconds: 1));

        final result = limiter.checkLimit('second_format', config);
        expect(result.errorMessage, contains('second'));
      });
    });
  });
}

// Test class to verify mixin functionality
class TestServiceWithRateLimit with RateLimitMixin {
  // Empty class, just needs the mixin
}