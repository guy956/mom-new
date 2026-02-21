/// Secure Cookie Manager - Stub for non-web platforms
/// On native platforms, this falls back to secure storage
class SecureCookieManager {
  static bool get isSupported => false;
  
  static void setSecureCookie(
    String name,
    String value, {
    Duration? maxAge,
    bool httpOnly = true,
    bool secure = true,
    String sameSite = 'strict',
  }) {
    // No-op on non-web platforms
  }
  
  static String? getSecureCookie(String name) {
    // No-op on non-web platforms
    return null;
  }
  
  static void deleteSecureCookie(String name) {
    // No-op on non-web platforms
  }
  
  static bool hasSecureCookie(String name) {
    return false;
  }
  
  /// Verify that cookies are NOT accessible via JavaScript (httpOnly check)
  /// On non-web, always returns true as there's no document.cookie
  static bool verifyHttpOnlySecurity() {
    return true;
  }
  
  /// Get all visible cookies (for debugging - non-sensitive only)
  static List<String> getVisibleCookieNames() {
    return [];
  }
  
  /// Test that JavaScript CANNOT access httpOnly cookies
  /// On non-web, returns mock results
  static Map<String, dynamic> testJavaScriptCookieAccess() {
    return {
      'platform': 'native',
      'status': 'not_applicable',
      'note': 'Cookie security testing only available on web platform',
    };
  }
}
