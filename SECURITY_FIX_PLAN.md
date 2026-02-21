# MOMIT Security Fix Plan

## Critical Issues Identified

### 1. API Vulnerabilities (HIGH PRIORITY)
**Status:** ⚠️ PENDING

Vulnerable packages:
- `tar` <= 7.5.6 - Arbitrary File Overwrite vulnerability
- `cookie` < 0.7.0 - Out of bounds characters
- `csurf` - Package deprecated and has transitive vulnerabilities

**Recommended Actions:**

#### Option A: Update Dependencies (Quick Fix)
```bash
cd /Users/joni/.openclaw/workspace/mom-project/api
npm update tar
cd .. && npm audit fix
```

#### Option B: Replace csurf with csrf-csrf (Recommended)
The `csurf` package is deprecated. Replace with `csrf-csrf`:

1. Install new package:
```bash
npm uninstall csurf
npm install csrf-csrf
```

2. Update server.js:
```javascript
// Replace this:
const csrf = require('csurf');
const csrfProtection = csrf({ cookie: true });

// With this:
const { doubleCsrf } = require('csrf-csrf');
const { csrfProtection, generateToken } = doubleCsrf({
  getSecret: () => process.env.CSRF_SECRET,
  cookieName: 'csrf-token',
  cookieOptions: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict'
  }
});
```

### 2. Test Failures (MEDIUM PRIORITY)
**Status:** ⚠️ 6 of 22 tests failing

**Failed Tests:**
1. X-XSS-Protection header - Helmet.js returns "0" instead of "1; mode=block"
2. CSRF blocking requests before validation - Expected behavior but tests need updating

**Fix:** Update test expectations to match actual security behavior:
- X-XSS-Protection: "0" is actually the modern recommendation (disables XSS auditor)
- CSRF returns 403 for missing/invalid tokens - this is correct behavior

### 3. SharedPreferences Usage (MEDIUM PRIORITY)
**Status:** ⚠️ Found in 5 files

Files using SharedPreferences:
- lib/features/album/screens/photo_album_screen.dart
- lib/main.dart
- lib/services/accessibility_service.dart
- lib/services/auth_service.dart
- lib/services/app_state.dart

**Migration Plan:**
Replace with `flutter_secure_storage`:

```dart
// Old:
final prefs = await SharedPreferences.getInstance();
await prefs.setString('key', value);

// New:
final storage = const FlutterSecureStorage();
await storage.write(key: 'key', value: value);
```

### 4. Code Quality Improvements

#### A. Remove debugPrint statements (13 files)
Replace with proper logging:
```dart
// Old:
debugPrint('[JwtService] Initialized');

// New:
import 'package:logging/logging.dart';
final _logger = Logger('JwtService');
_logger.info('Initialized');
```

#### B. Add const constructors where possible
Run: `flutter analyze --fix`

#### C. Fix deprecated API usage
- Update `express-slow-down` delayMs configuration
- Replace deprecated `xss-clean` with `helmet.contentSecurityPolicy`

## Implementation Priority

### Immediate (Now)
1. ✅ Document all issues
2. ⏳ Create fix branches for critical issues

### Today
1. Update security test expectations
2. Replace csurf with csrf-csrf
3. Fix npm audit issues

### This Week
1. Migrate SharedPreferences to flutter_secure_storage
2. Add proper logging framework
3. Set up CI/CD pipeline

## Testing After Fixes

```bash
# API tests
cd api
npm test

# Flutter tests (when Flutter available)
cd ..
flutter test

# Security audit
cd api
npm audit
```

## Monitoring Checklist

- [ ] No HIGH/CRITICAL vulnerabilities in npm audit
- [ ] All API tests passing
- [ ] Flutter tests passing
- [ ] Code coverage maintained at 80%+
- [ ] No deprecated dependencies
- [ ] Security headers validated

---
**Document Created:** 2026-02-17  
**Last Updated:** 2026-02-17  
**Status:** IN PROGRESS
