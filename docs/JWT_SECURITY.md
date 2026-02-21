# Secure JWT Implementation Guide

## Overview
The authentication service now uses a secure JWT (JSON Web Token) implementation with the following security features:

## Security Features

### 1. No Hardcoded Secrets
- JWT secrets are loaded from environment variables (`JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`)
- Secrets must be at least 32 characters long
- Different secrets for access and refresh tokens

### 2. Environment Variables
Create a `.env` file in the project root:
```bash
JWT_ACCESS_SECRET=your_super_secret_access_key_min_32_chars_here
JWT_REFRESH_SECRET=your_super_secret_refresh_key_min_32_chars_here_different_from_access
ADMIN_EMAILS=admin@momit.app
```

**Generate secure secrets:**
```bash
openssl rand -base64 32
```

### 3. JWT Expiry Validation
- Access tokens expire after **15 minutes**
- Refresh tokens expire after **7 days**
- Automatic token expiry checking on every validation
- Expired tokens are rejected immediately

### 4. Token Refresh Logic
- Refresh token rotation (new refresh token issued with each refresh)
- Access token can be refreshed using valid refresh token
- Invalid/expired refresh token triggers logout
- Token ID (`jti`) tracking for potential revocation

### 5. Secure Token Storage
- Uses `flutter_secure_storage` (encrypted platform keystore)
- **NOT** stored in localStorage or SharedPreferences
- Android: EncryptedSharedPreferences with AES-GCM
- iOS: Keychain with first-unlock accessibility
- Tokens are deleted on logout

## Architecture

### Token Types

**Access Token (Short-lived)**
- Contains: email, userId, isAdmin, type="access"
- Expires: 15 minutes
- Used for: API authentication

**Refresh Token (Long-lived)**
- Contains: email, userId, type="refresh", jti
- Expires: 7 days
- Used for: Obtaining new access tokens

### Key Classes

- `JwtService`: Token generation, validation, and refresh
- `SecureTokenStorage`: Encrypted token persistence
- `AuthService`: High-level authentication operations
- `TokenPair`: Container for access/refresh tokens

## Usage Examples

### Initialize
```dart
await AuthService.instance.initialize();
```

### Login
```dart
final result = await AuthService.instance.login(
  email: 'user@example.com',
  password: 'password123',
);
if (result.isSuccess) {
  // Tokens automatically stored securely
  print('Access token: ${result.tokens?.accessToken}');
}
```

### Check Authentication
```dart
final isAuth = await AuthService.instance.isAuthenticated();
```

### Get Valid Access Token (auto-refreshes if needed)
```dart
final token = await AuthService.instance.getValidAccessToken();
```

### Logout
```dart
await AuthService.instance.logout();
// All tokens cleared from secure storage
```

## Testing

Run JWT tests:
```bash
flutter test test/jwt_secure_test.dart
```

## Security Checklist

- [ ] `.env` file added to `.gitignore`
- [ ] Strong secrets generated (32+ chars)
- [ ] Different secrets for access and refresh tokens
- [ ] Admin emails loaded from environment
- [ ] No secrets committed to git
- [ ] Production using production secrets
- [ ] Token expiry appropriate for use case

## Migration from Old System

The old implementation used SharedPreferences for session storage. The new system:
1. Uses secure storage for tokens
2. Adds JWT token generation
3. Implements proper expiry handling
4. Adds refresh token rotation

Existing user data in SharedPreferences is not automatically migrated - users will need to log in again to get JWT tokens.
