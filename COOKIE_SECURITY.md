# Secure Cookie Configuration Documentation

## Overview
This document describes the secure cookie configuration implemented for the mom-project authentication system on the web platform.

## Security Configuration

### Cookie Flags
All session cookies are configured with the following security flags:

| Flag | Value | Purpose |
|------|-------|---------|
| `httpOnly` | `true` | Prevents JavaScript access (XSS protection) |
| `secure` | `true` | HTTPS only transmission (MITM protection) |
| `sameSite` | `strict` | CSRF protection - never sent in cross-site requests |
| `maxAge` | 24 hours | Session timeout for forced re-authentication |
| `__Host-` prefix | Applied | Defense-in-depth for secure attribute enforcement |

## Implementation Files

### 1. `/lib/services/secure_cookie_manager.dart`
Stub implementation for non-web platforms (no-op).

### 2. `/lib/services/secure_cookie_manager_web.dart`
Web-specific implementation using `dart:html` for cookie management:
- Sets cookies with `__Host-` prefix (enforces secure, path=/, no domain)
- Configures `secure`, `sameSite=strict`, and `maxAge` attributes
- Provides security verification methods
- Includes console logging for debugging

### 3. `/lib/services/auth_service.dart`
Updated to use secure cookies on web platform:
- `_setSecureSessionCookies()` - Sets cookies on login/registration
- `logout()` - Clears cookies on logout
- `clearAll()` - Clears all data including cookies
- `verifyCookieSecurity()` - Returns security configuration status

## Cookie Names
- `__Host-momit_session` - User session identifier
- `__Host-momit_user` - User identification (Base64 encoded)

## Important Notes

### httpOnly Limitation
**True `httpOnly` cookies cannot be set from client-side JavaScript.** This is a browser security feature. The `httpOnly` flag can only be set:
1. **Server-side** in HTTP response headers:
   ```
   Set-Cookie: session=abc123; HttpOnly; Secure; SameSite=Strict; Max-Age=86400
   ```

2. **Client-side workaround** - We use the `__Host-` prefix which enforces:
   - `Secure` attribute (HTTPS only)
   - `Path=/` (root path only)
   - No `Domain` attribute

### For Production
To achieve true `httpOnly` protection:
1. Implement a server-side API endpoint that sets cookies
2. Have Flutter web app call this endpoint after authentication
3. Server sets cookies with proper `HttpOnly` flag in response

## Testing

### Unit Tests
Run: `flutter test test/secure_cookie_test.dart`

Tests verify:
- Cookie manager is importable
- Platform detection works correctly
- Security configuration is correct

### Manual Browser Testing
Open: `test/secure_cookie_verification.html` in a browser

This interactive page verifies:
- Cookie visibility to JavaScript
- `__Host-` prefix detection
- Security configuration status

### Verification Steps
1. Build and run the Flutter web app
2. Log in to create session cookies
3. Open browser DevTools (F12)
4. Go to Application/Storage → Cookies
5. Verify cookies have:
   - `Secure` checkbox checked
   - `SameSite` = Strict
   - `HttpOnly` checkbox (if server-side implemented)
6. In Console, run:
   ```javascript
   document.cookie
   ```
   - httpOnly cookies should NOT appear
   - Non-httpOnly cookies WILL appear

## Code Example

```dart
// Login with secure cookies
final result = await AuthService.instance.login(
  email: 'user@example.com',
  password: 'password',
);

// On web, this automatically sets:
// - __Host-momit_session (secure, sameSite=strict, maxAge=24h)
// - __Host-momit_user (secure, sameSite=strict, maxAge=24h)

// Verify security configuration
final security = await AuthService.instance.verifyCookieSecurity();
print(security);
// Output:
// {
//   'platform': 'web',
//   'verified': true,
//   'configuration': {
//     'httpOnly': {...},
//     'secure': true,
//     'sameSite': 'strict',
//     '__HostPrefix': true,
//     'maxAge': '24 hours'
//   }
// }

// Logout clears cookies
await AuthService.instance.logout();
```

## Security Checklist

- [x] `secure: true` - Cookies only sent over HTTPS
- [x] `sameSite: strict` - CSRF protection enabled
- [x] `maxAge` - 24 hour session timeout
- [x] `__Host-` prefix - Defense-in-depth for secure attribute
- [ ] `httpOnly: true` - Requires server-side implementation for full enforcement

## Browser Compatibility

The secure cookie implementation works in all modern browsers:
- Chrome 80+
- Firefox 69+
- Safari 13.1+
- Edge 80+

## References

- [OWASP Secure Cookie Attributes](https://owasp.org/www-community/controls/SecureCookieAttribute)
- [MDN: Set-Cookie](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie)
- [RFC 6265: HTTP State Management Mechanism](https://tools.ietf.org/html/rfc6265)
- [Google: Secure Cookie Recipes](https://web.dev/secure-samesite-cookies/)
