# MOMIT Firebase Setup Guide

**Project:** MOMIT - Social Network for Mothers in Israel  
**Firebase Project ID:** `momit-1`  
**Last Updated:** 2025-02-17

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Firebase Project Configuration](#firebase-project-configuration)
3. [Firebase Services Setup](#firebase-services-setup)
4. [Platform Configuration](#platform-configuration)
5. [Security Rules](#security-rules)
6. [Indexes](#indexes)
7. [Deployment](#deployment)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites

- Node.js 18+ installed
- Firebase CLI installed: `npm install -g firebase-tools`
- Firebase account with project `momit-1` created
- Flutter SDK 3.7+ installed

### Initial Setup

```bash
# 1. Login to Firebase
firebase login

# 2. Navigate to project directory
cd mom-project

# 3. Verify project association
firebase projects:list

# 4. Deploy Firebase configuration
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage:rules
```

---

## Firebase Project Configuration

### Project Details

| Property | Value |
|----------|-------|
| Project ID | `momit-1` |
| Project Number | `459220254220` |
| Storage Bucket | `momit-1.firebasestorage.app` |
| Region | `europe-west1` (recommended for Israel) |

### Configuration Files

| File | Purpose |
|------|---------|
| `.firebaserc` | Project association |
| `firebase.json` | Hosting, Firestore, Storage config |
| `firestore.rules` | Security rules for Firestore |
| `firestore.indexes.json` | Composite indexes |
| `storage.rules` | Security rules for Storage |

---

## Firebase Services Setup

### 1. Authentication

**Status:** ✅ Configured

**Enabled Providers:**
- Email/Password
- Google Sign-In

**Configuration Required:**

1. **Firebase Console** > Authentication > Sign-in method
2. Enable **Email/Password** provider
3. Enable **Google** provider
   - Add support email
   - Configure OAuth consent screen in Google Cloud Console

4. **Authorized Domains** (for web):
   - `localhost` (development)
   - `momit-1.firebaseapp.com`
   - `momit.pages.dev` (production)

**Web OAuth Client ID Setup:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project `momit-1`
3. APIs & Credentials > OAuth 2.0 Client IDs
4. Create credentials > OAuth client ID > Web application
5. Add authorized JavaScript origins:
   - `https://momit.pages.dev`
   - `https://momit-1.firebaseapp.com`
   - `http://localhost`
6. Add authorized redirect URIs:
   - `https://momit-1.firebaseapp.com/__/auth/handler`
7. Copy Client ID to `lib/firebase_options.dart` > `webGoogleClientId`

### 2. Firestore Database

**Status:** ✅ Configured

**Database Mode:** Native mode (not Datastore mode)

**Location:** `europe-west1` (Belgium) - closest to Israel

**Collections Structure:**

```
app_config/           # App-wide configuration
dynamic_sections/     # Dynamic UI sections
content_management/   # CMS content
feature_flags/        # Feature toggles
admin_config/         # Admin dashboard config
users/               # User profiles
experts/             # Expert profiles
events/              # Community events
marketplace/         # Marketplace items
tips/                # Parenting tips
posts/               # Community posts
reports/             # User reports
media_library/       # Admin media assets
activity_log/        # User activity tracking
error_logs/          # Error tracking
push_notifications/  # Notification queue
chats/               # Chat rooms
notifications/       # User notifications
admin_audit_log/     # Admin actions audit
```

### 3. Cloud Storage

**Status:** ✅ Configured

**Storage Buckets:**
- Default: `momit-1.firebasestorage.app`

**Folder Structure:**

```
/media_vault/        # Admin media assets (public read)
/tips/              # Tips images (public read)
/user_uploads/      # User content (owner write)
/posts/             # Post images (auth write)
/profile_pictures/  # User avatars (owner write)
/marketplace/       # Marketplace images (auth write)
/events/            # Event images (auth write)
/chat_attachments/  # Chat files (participant access)
```

**CORS Configuration:**
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

### 4. Firebase Hosting

**Status:** ✅ Configured

**Configuration:**
- Public directory: `build/web`
- SPA routing: Enabled
- Trailing slash: Disabled

**Security Headers:**
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Strict-Transport-Security: max-age=31536000
- Content-Security-Policy (comprehensive)

**Cache Control:**
- Assets: 1 year (immutable)
- index.html: 0 (must-revalidate)
- flutter_service_worker.js: 0

---

## Platform Configuration

### Web

**File:** `web/index.html`

- Preconnect to Firebase domains configured
- DNS prefetch enabled
- No inline Firebase scripts (uses FlutterFire)

**File:** `lib/firebase_options.dart`

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyCjI-LFvVTF2WPHRMiVVS4ClbnSixG1bR4',
  appId: '1:459220254220:web:1b2ae6f7c99fff14fff829',
  messagingSenderId: '459220254220',
  projectId: 'momit-1',
  authDomain: 'momit-1.firebaseapp.com',
  storageBucket: 'momit-1.firebasestorage.app',
  measurementId: 'G-MEASUREMENT_ID', // Update with actual ID
);
```

### Android

**File:** `android/app/google-services.json`

- Package name: `com.momconnect.social`
- App ID: `1:459220254220:android:1b2ae6f7c99fff14fff829`

**Configuration:**
- File already placed in `android/app/`
- Gradle plugin configured in `android/build.gradle`

### iOS

**Status:** ⚠️ Partially Configured

**File:** `lib/firebase_options.dart`

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyAWumTmBmRzyqw1mBg3q63kzrsaED1S1ds',
  appId: '1:459220254220:ios:70f057902858a848fff829',
  messagingSenderId: '459220254220',
  projectId: 'momit-1',
  storageBucket: 'momit-1.firebasestorage.app',
  iosClientId: '459220254220-gaaf7nh618bgjc2tbd0ds6r0urgru8ea.apps.googleusercontent.com',
  iosBundleId: 'MOMIT-1',
);
```

**Missing:** `ios/Runner/GoogleService-Info.plist`

**Action Required:**
1. Download from Firebase Console > Project Settings > iOS app
2. Place in `ios/Runner/GoogleService-Info.plist`

---

## Security Rules

### Firestore Rules

**File:** `firestore.rules`

**Key Features:**
- ✅ Authentication required for most operations
- ✅ Role-based access control (Admin/Moderator)
- ✅ User ownership validation
- ✅ Public read for published content
- ✅ Audit logging support

**Rules Summary:**

| Collection | Read | Write |
|------------|------|-------|
| app_config | Public | Admin only |
| users | Authenticated | Owner/Admin |
| posts | Public | Owner/Admin |
| tips | Public | Admin only |
| marketplace | Public | Owner/Admin |
| reports | Admin/Moderator | Authenticated create |
| admin_audit_log | Admin | Authenticated create |

### Storage Rules

**File:** `storage.rules`

**Key Features:**
- ✅ User-scoped file access
- ✅ Chat attachment restrictions
- ✅ Admin override capability

---

## Indexes

**File:** `firestore.indexes.json`

**Total Indexes:** 20 composite indexes configured

**Critical Indexes:**

| Collection | Fields | Purpose |
|------------|--------|---------|
| dynamic_sections | isActive + order | Display active sections |
| content_management | sectionId + isPublished + order | Filter published content |
| users | lastActive + createdAt | User analytics |
| admin_audit_log | actionType + timestamp | Audit filtering |

**Deploy Indexes:**
```bash
firebase deploy --only firestore:indexes
```

**Note:** Index creation can take several minutes. Monitor progress in Firebase Console.

---

## Deployment

### Deploy All Firebase Resources

```bash
# Deploy everything
firebase deploy

# Deploy specific services
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage:rules
firebase deploy --only hosting
```

### Flutter Build & Deploy

```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting (if using Firebase Hosting)
firebase deploy --only hosting

# Or deploy to Cloudflare Pages (current production)
# (See DEPLOYMENT_GUIDE.md for Cloudflare Pages setup)
```

---

## Troubleshooting

### Common Issues

#### 1. "Permission denied" errors

**Cause:** Firestore rules rejecting the operation

**Solution:**
- Check user is authenticated
- Verify user has required role
- Review rule conditions in Firebase Console > Firestore Database > Rules

#### 2. "Index not found" errors

**Cause:** Missing composite index for query

**Solution:**
- Check error message for index creation link
- Or add index to `firestore.indexes.json` and deploy
- Wait for index to build (can take several minutes)

#### 3. CORS errors on Storage

**Cause:** Missing CORS configuration

**Solution:**
```bash
# Create cors.json file
cat > cors.json << 'EOF'
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
EOF

# Apply CORS configuration
gsutil cors set cors.json gs://momit-1.firebasestorage.app
```

#### 4. Google Sign-In not working on web

**Cause:** Missing OAuth configuration

**Solution:**
- Verify `webGoogleClientId` in `firebase_options.dart`
- Add domain to Firebase Console > Authentication > Settings > Authorized domains
- Configure OAuth consent screen in Google Cloud Console

### Firebase CLI Commands

```bash
# Check Firebase status
firebase projects:list

# Switch project
firebase use momit-1

# View current configuration
firebase apps:list

# Get configuration for a platform
firebase apps:sdkconfig WEB

# Open Firebase Console
firebase open
```

### Validation Checklist

- [ ] Firebase project `momit-1` exists and accessible
- [ ] `.firebaserc` configured with default project
- [ ] `firebase.json` has correct hosting/firestore/storage config
- [ ] Firestore rules deployed and active
- [ ] Storage rules deployed and active
- [ ] Firestore indexes created (check Firebase Console)
- [ ] Android `google-services.json` in place
- [ ] iOS `GoogleService-Info.plist` in place (if building iOS)
- [ ] `firebase_options.dart` has correct API keys for all platforms
- [ ] Authentication providers enabled in Firebase Console
- [ ] Authorized domains configured for web

---

## Additional Resources

- [Firebase Console](https://console.firebase.google.com/project/momit-1)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Firebase Storage Documentation](https://firebase.google.com/docs/storage)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

---

## Contact

For Firebase configuration issues, contact:
- Firebase Console support
- Project maintainer via repository issues
