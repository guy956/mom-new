/// Rate Limiter Middleware for MOMIT App
/// Implements in-memory rate limiting for authentication endpoints
/// 
/// Limits:
/// - Login attempts: 5 per minute
/// - API calls: 100 per minute
/// - Password reset: 3 per hour

import 'dart:collection';

/// Rate limit configuration
class RateLimitConfig {
  final int maxRequests;
  final Duration window;
  final String name;

  const RateLimitConfig({
    required this.maxRequests,
    required this.window,
    required this.name,
  });

  /// Default login limit: 5 attempts per minute
  static const login = RateLimitConfig(
    maxRequests: 5,
    window: Duration(minutes: 1),
    name: 'login',
  );

  /// Default API limit: 100 calls per minute
  static const api = RateLimitConfig(
    maxRequests: 100,
    window: Duration(minutes: 1),
    name: 'api',
  );

  /// Default password reset limit: 3 attempts per hour
  static const passwordReset = RateLimitConfig(
    maxRequests: 3,
    window: Duration(hours: 1),
    name: 'password_reset',
  );
}

/// Represents a rate limit bucket for a specific client
class _RateLimitBucket {
  final String identifier;
  final Queue<DateTime> _timestamps = Queue<DateTime>();
  final RateLimitConfig config;

  _RateLimitBucket(this.identifier, this.config);

  /// Check if a request is allowed and record it if so
  RateLimitResult allowRequest() {
    final now = DateTime.now();
    final windowStart = now.subtract(config.window);

    // Remove timestamps outside the window
    while (_timestamps.isNotEmpty && _timestamps.first.isBefore(windowStart)) {
      _timestamps.removeFirst();
    }

    // Check if limit exceeded
    if (_timestamps.length >= config.maxRequests) {
      final oldest = _timestamps.first;
      final resetTime = oldest.add(config.window);
      final remainingSeconds = resetTime.difference(now).inSeconds;

      return RateLimitResult(
        allowed: false,
        limit: config.maxRequests,
        remaining: 0,
        resetInSeconds: remainingSeconds,
        errorMessage:
            '${config.name} limit exceeded. Try again in ${_formatDuration(Duration(seconds: remainingSeconds))}',
      );
    }

    // Record the request
    _timestamps.add(now);

    return RateLimitResult(
      allowed: true,
      limit: config.maxRequests,
      remaining: config.maxRequests - _timestamps.length,
      resetInSeconds: config.window.inSeconds,
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
    return '${duration.inSeconds} seconds';
  }
}

/// Result of a rate limit check
class RateLimitResult {
  final bool allowed;
  final int limit;
  final int remaining;
  final int resetInSeconds;
  final String? errorMessage;

  const RateLimitResult({
    required this.allowed,
    required this.limit,
    required this.remaining,
    required this.resetInSeconds,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'RateLimitResult(allowed: $allowed, remaining: $remaining, limit: $limit)';
  }
}

/// Central rate limiter managing buckets for different clients
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  static RateLimiter get instance => _instance;

  RateLimiter._internal();

  // Storage for buckets: Map<configName, Map<identifier, bucket>>
  final Map<String, Map<String, _RateLimitBucket>> _buckets = {};

  /// Check if a request is allowed for the given identifier and config
  RateLimitResult checkLimit(String identifier, RateLimitConfig config) {
    final bucketsForConfig = _buckets.putIfAbsent(
      config.name,
      () => <String, _RateLimitBucket>{},
    );

    final bucket = bucketsForConfig.putIfAbsent(
      identifier,
      () => _RateLimitBucket(identifier, config),
    );

    return bucket.allowRequest();
  }

  /// Convenience method for login attempts
  RateLimitResult checkLoginLimit(String identifier) {
    return checkLimit(identifier, RateLimitConfig.login);
  }

  /// Convenience method for API calls
  RateLimitResult checkApiLimit(String identifier) {
    return checkLimit(identifier, RateLimitConfig.api);
  }

  /// Convenience method for password reset attempts
  RateLimitResult checkPasswordResetLimit(String identifier) {
    return checkLimit(identifier, RateLimitConfig.passwordReset);
  }

  /// Clear all rate limit data (useful for testing or admin actions)
  void clearAll() {
    _buckets.clear();
  }

  /// Clear rate limit for a specific identifier
  void clearForIdentifier(String identifier) {
    for (final bucketsForConfig in _buckets.values) {
      bucketsForConfig.remove(identifier);
    }
  }

  /// Get current statistics for debugging
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};
    for (final entry in _buckets.entries) {
      stats[entry.key] = entry.value.length;
    }
    return stats;
  }
}

/// Exception thrown when rate limit is exceeded
class RateLimitExceededException implements Exception {
  final String message;
  final RateLimitResult result;

  const RateLimitExceededException(this.message, this.result);

  @override
  String toString() => 'RateLimitExceededException: $message';
}

/// Utility mixin for easy integration with services
/// Usage: `class MyService with RateLimitMixin { ... }`
mixin RateLimitMixin {
  RateLimiter get _rateLimiter => RateLimiter.instance;

  /// Rate limit a login attempt
  /// Returns null if allowed, or error message if blocked
  String? rateLimitLogin(String identifier) {
    final result = _rateLimiter.checkLoginLimit(identifier);
    if (!result.allowed) {
      return result.errorMessage;
    }
    return null;
  }

  /// Rate limit an API call
  /// Returns null if allowed, or error message if blocked
  String? rateLimitApiCall(String identifier) {
    final result = _rateLimiter.checkApiLimit(identifier);
    if (!result.allowed) {
      return result.errorMessage;
    }
    return null;
  }

  /// Rate limit a password reset attempt
  /// Returns null if allowed, or error message if blocked
  String? rateLimitPasswordReset(String identifier) {
    final result = _rateLimiter.checkPasswordResetLimit(identifier);
    if (!result.allowed) {
      return result.errorMessage;
    }
    return null;
  }

  /// Check rate limit and throw exception if exceeded
  void enforceRateLimit(String identifier, RateLimitConfig config) {
    final result = _rateLimiter.checkLimit(identifier, config);
    if (!result.allowed) {
      throw RateLimitExceededException(
        result.errorMessage ?? 'Rate limit exceeded',
        result,
      );
    }
  }
}
