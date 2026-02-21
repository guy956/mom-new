# MOMIT Security Implementation

This document outlines all security fixes implemented in the MOMIT application.

## Security Fixes Applied

### 1. ✅ Replaced Math.random() with crypto.randomBytes

**Location:** `api/server.js`

All random generation for security purposes now uses Node.js `crypto` module:
- `generateSecureRandomBytes()` - For cryptographic keys
- `generateSecureRandomString()` - For tokens and IDs
- `generateSecureRandomNumber()` - For secure random numbers
- `generateSecureOTP()` - For one-time passwords

**Note:** The `intro_splash_screen.dart` uses `Random.secure()` for visual effects (particles), which is the secure equivalent in Dart.

### 2. ✅ Rate Limiting on Auth Endpoints

**Location:** `api/server.js`

Implemented using `express-rate-limit`:
- **General API:** 100 requests per 15 minutes per IP
- **Auth Endpoints:** 5 attempts per 15 minutes per IP
- **Speed Limiter:** Adds 500ms delay after 10 rapid requests

Protected endpoints:
- `/api/auth/login`
- `/api/auth/register`
- `/api/auth/forgot-password`
- `/api/auth/reset-password`
- `/api/auth/refresh-token`

### 3. ✅ Secure JWT Secrets (No Hardcoded)

**Location:** `api/.env.example` and `api/server.js`

JWT secrets are loaded from environment variables:
```bash
JWT_ACCESS_SECRET=your_super_secret_access_key_min_64_chars_long_here
JWT_REFRESH_SECRET=your_super_secret_refresh_key_min_64_chars_long_here
```

Features:
- Strong secrets (64+ character minimum recommended)
- Separate secrets for access and refresh tokens
- Short expiry times (15 min access, 7 days refresh)
- Secure token storage in memory only

### 4. ✅ Secure Cookies (httpOnly, secure, SameSite)

**Location:** `api/server.js`

All cookies use secure settings:
```javascript
{
  httpOnly: true,        // Prevents XSS via document.cookie
  secure: true,          // HTTPS only in production
  sameSite: 'strict',    // CSRF protection
  maxAge: ...,           // Appropriate expiry
  path: '/',
  domain: process.env.COOKIE_DOMAIN
}
```

### 5. ✅ Helmet.js Security Headers

**Location:** `api/server.js`, `serve.py`, `web/_headers`

Implemented security headers:
- `X-Frame-Options: SAMEORIGIN` - Clickjacking protection
- `X-Content-Type-Options: nosniff` - MIME sniffing protection
- `X-XSS-Protection: 1; mode=block` - XSS filter
- `Strict-Transport-Security` - HSTS (1 year, includeSubDomains, preload)
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Content-Security-Policy` - Comprehensive CSP
- `Permissions-Policy` - Feature access control
- `Cross-Origin-*` policies - Isolation protections

### 6. ✅ Fixed CORS Configuration

**Location:** `api/server.js`, `serve.py`

Secure CORS configuration:
- No wildcard (`*`) origins in production
- Specific allowed origins only:
  - `https://momit.app`
  - `https://www.momit.app`
  - `https://admin.momit.app`
- Credentials allowed for authenticated requests
- Preflight caching (24 hours)
- Proper handling of OPTIONS requests

## Additional Security Features

### CSRF Protection
- CSRF tokens required for state-changing operations
- Secure cookie-based CSRF tokens
- Token regeneration on authentication

### Input Sanitization
- XSS prevention with `xss-clean`
- NoSQL injection prevention with `mongo-sanitize`
- Parameter pollution prevention with `hpp`
- Request size limiting (10kb)

### Password Security
- Bcrypt hashing with 12 salt rounds
- Minimum password requirements (8 chars, complexity)
- No plaintext password storage

### TLS/SSL Security
- TLS 1.2+ only
- Secure cipher suites
- Certificate pinning ready (native platforms)

## Environment Setup

1. Copy `api/.env.example` to `api/.env`:
   ```bash
   cd api
   cp .env.example .env
   ```

2. Generate secure JWT secrets:
   ```bash
   node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
   ```

3. Update environment variables with your secure values

4. Install dependencies:
   ```bash
   npm install
   ```

5. Start the secure server:
   ```bash
   npm start
   ```

## Security Checklist

- [x] No Math.random() for security operations
- [x] Rate limiting on all auth endpoints
- [x] JWT secrets in environment variables
- [x] Secure cookie settings (httpOnly, secure, SameSite)
- [x] Helmet.js security headers
- [x] Strict CORS configuration
- [x] CSRF protection
- [x] XSS prevention
- [x] Input sanitization
- [x] Password hashing
- [x] TLS 1.2+ enforcement
- [x] Security headers on static hosting

## Testing Security

Run the test suite:
```bash
cd api
npm test
```

Manual security checks:
1. Verify rate limiting: Try logging in 6+ times quickly
2. Verify CORS: Attempt request from unauthorized origin
3. Verify cookies: Check DevTools Application tab
4. Verify headers: Use `curl -I https://api.momit.app/api/health`

## Reporting Security Issues

If you discover a security vulnerability, please email security@momit.app
DO NOT create a public GitHub issue for security problems.
