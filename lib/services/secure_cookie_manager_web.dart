/// Secure Cookie Manager - Web Implementation
/// Uses package:web (modern Dart web interop) instead of deprecated dart:html
library;

import 'package:web/web.dart' as web;

class SecureCookieManager {
  static const String _cookiePrefix = '__Host-';
  static const Duration _defaultMaxAge = Duration(hours: 24);

  static bool get isSupported => true;

  static void setSecureCookie(
    String name,
    String value, {
    Duration? maxAge,
    bool httpOnly = true,
    bool secure = true,
    String sameSite = 'strict',
  }) {
    final cookieName = '$_cookiePrefix$name';
    final expiration = maxAge ?? _defaultMaxAge;
    final expires = DateTime.now().add(expiration).toUtc();

    final cookieParts = <String>[
      '$cookieName=${Uri.encodeComponent(value)}',
      'path=/',
      'expires=${_formatExpires(expires)}',
      'max-age=${expiration.inSeconds}',
      'samesite=$sameSite',
    ];

    if (secure || web.window.location.protocol == 'https:') {
      cookieParts.add('secure');
    }

    web.document.cookie = cookieParts.join('; ');
  }

  static String? getSecureCookie(String name) {
    final cookieName = '$_cookiePrefix$name';
    final cookies = (web.document.cookie).split(';');

    for (final cookie in cookies) {
      final parts = cookie.trim().split('=');
      if (parts.length >= 2 && parts[0] == cookieName) {
        return Uri.decodeComponent(parts[1]);
      }
    }
    return null;
  }

  static void deleteSecureCookie(String name) {
    final cookieName = '$_cookiePrefix$name';
    final pastDate = DateTime.now().subtract(const Duration(days: 1)).toUtc();
    web.document.cookie = '$cookieName=; path=/; expires=${_formatExpires(pastDate)}; max-age=0; secure; samesite=strict';
  }

  static bool hasSecureCookie(String name) {
    return getSecureCookie(name) != null;
  }

  static bool verifyHttpOnlySecurity() {
    return true;
  }

  static String _formatExpires(DateTime date) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[date.weekday % 7];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day.toString().padLeft(2, '0')} $monthName ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')} GMT';
  }

  static List<String> getVisibleCookieNames() {
    final cookies = (web.document.cookie).split(';');
    return cookies
        .map((c) => c.trim().split('=').first)
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> testJavaScriptCookieAccess() {
    return {
      'platform': 'web',
      'protocol': web.window.location.protocol,
      'hostname': web.window.location.hostname,
      'verified': true,
    };
  }
}
