# MOMIT Deployment Guide

Complete deployment guide for the MOMIT (Mom Connect) social network application for mothers in Israel.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Overview](#project-overview)
3. [Environment Setup](#environment-setup)
4. [Firebase Configuration](#firebase-configuration)
5. [Building the Application](#building-the-application)
6. [Cloudflare Pages Deployment](#cloudflare-pages-deployment)
7. [Firestore Database Setup](#firestore-database-setup)
8. [Post-Deployment Verification](#post-deployment-verification)
9. [Environment Variables Reference](#environment-variables-reference)
10. [Troubleshooting](#troubleshooting)
11. [Security Checklist](#security-checklist)

---

## Prerequisites

Before starting deployment, ensure you have the following installed:

### Required Tools

| Tool | Version | Purpose | Download Link |
|------|---------|---------|---------------|
| Flutter SDK | ^3.7.0 | App framework | https://flutter.dev/docs/get-started/install |
| Dart | ^3.7.0 | Programming language | Included with Flutter |
| Node.js | 18+ | Backend scripts | https://nodejs.org/ |
| npm | 9+ | Package manager | Included with Node.js |
| Firebase CLI | Latest | Firebase deployment | `npm install -g firebase-tools` |
| Cloudflare Wrangler | Latest | Pages deployment | `npm install -g wrangler` |
| Git | Latest | Version control | https://git-scm.com/ |

### Verify Installation

```bash
# Check Flutter installation
flutter doctor

# Check Node.js version
node --version  # Should be v18.x.x or higher

# Check Firebase CLI
firebase --version

# Check Wrangler
wrangler --version
```

### Required Accounts

1. **Firebase Account** - https://console.firebase.google.com/
2. **Cloudflare Account** - https://dash.cloudflare.com/
3. **Google Cloud Console** - https://console.cloud.google.com/ (for OAuth)

---

## Project Overview

MOMIT is a Flutter-based social network application with the following architecture:

```
Project Structure:
├── new uplode/          # Main Flutter application
│   ├── lib/             # Dart source code
│   ├── web/             # Web-specific files (headers, manifest, HTML)
│   ├── pubspec.yaml     # Flutter dependencies
│   └── wrangler.toml    # Cloudflare Pages config
├── firestore/           # Firestore initialization & rules
│   ├── init-firestore.ts
│   ├── firestore.rules
│   └── firestore.indexes.json
└── web/                 # Additional web assets (if any)
```

### Technology Stack

- **Frontend:** Flutter (Web, iOS, Android)
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Authentication:** Firebase Auth with JWT
- **Database:** Cloud Firestore
- **Hosting:** Cloudflare Pages (Web)
- **Security:** Firebase Security Rules, Security Headers

---

## Environment Setup

### 1. Clone the Repository

```bash
# Clone the project
git clone <repository-url>
cd mom-project

# Verify project structure
ls -la
```

### 2. Install Flutter Dependencies

```bash
cd "new uplode"

# Get Flutter packages
flutter pub get

# Verify no issues
flutter doctor
```

### 3. Install Firestore Tools

```bash
cd ../firestore

# Install dependencies
npm install

# Build TypeScript
npm run build
```

---

## Firebase Configuration

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `momit-1` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Accept terms and create project

### Step 2: Enable Firebase Services

Navigate to each service and click "Get started":

1. **Authentication**
   - Go to Build → Authentication
   - Click "Get started"
   - Enable "Email/Password" provider
   - Enable "Google" provider (configure OAuth consent screen)

2. **Cloud Firestore**
   - Go to Build → Firestore Database
   - Click "Create database"
   - Choose "Start in production mode"
   - Select region: `europe-west1` (recommended for Israel/Europe)

3. **Firebase Storage** (for image uploads)
   - Go to Build → Storage
   - Click "Get started"
   - Choose "Start in production mode"

### Step 3: Register Web App

1. In Firebase Console, click the gear icon ⚙️ → Project settings
2. Go to "Your apps" section
3. Click "</>" (Web) icon to add web app
4. Register app:
   - **App nickname:** `momit-web`
   - **Hosting:** Uncheck "Firebase Hosting"
   - Click "Register app"
5. Copy the Firebase configuration values

### Step 4: Configure Firebase in Code

Update `lib/firebase_options.dart` with your Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  measurementId: 'YOUR_MEASUREMENT_ID',
);
```

### Step 5: Configure Authorized Domains

1. Go to Firebase Console → Authentication → Settings
2. Scroll to "Authorized domains"
3. Add your custom domain:
   - `momit.pages.dev` (Cloudflare Pages)
   - `localhost` (for development)
   - Any custom domain you plan to use

### Step 6: Download Platform Config Files

#### Android

1. Go to Project settings → Your apps → Android
2. Click "Download google-services.json"
3. Place file at: `android/app/google-services.json`

#### iOS

1. Go to Project settings → Your apps → iOS
2. Click "Download GoogleService-Info.plist`
3. Place file at: `ios/Runner/GoogleService-Info.plist`

---

## Building the Application

### Web Build

The web build is the primary deployment target for Cloudflare Pages.

```bash
cd "new uplode"

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for production
flutter build web --release --web-renderer html --base-href /

# Verify build output
ls -la build/web/
```

#### Build Output Structure

```
build/web/
├── assets/              # Static assets (images, fonts)
├── canvaskit/           # CanvasKit renderer (not used with html renderer)
├── icons/               # App icons
├── _headers             # Cloudflare security headers
├── _redirects           # URL redirects
├── favicon.png          # Favicon
├── favicon.svg          # SVG favicon
├── index.html           # Entry HTML file
├── manifest.json        # PWA manifest
├── privacy.html         # Privacy policy
├── terms.html           # Terms of service
├── security.js          # Security utilities
└── flutter_bootstrap.js # Flutter web bootstrap
```

### Mobile Builds (Optional)

#### Android APK

```bash
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS

```bash
flutter build ios --release

# Then archive and upload via Xcode
```

---

## Cloudflare Pages Deployment

### Step 1: Configure Wrangler

The project includes `wrangler.toml` for Cloudflare Pages:

```toml
name = "momit"
account_id = "c3da1f83e98070eb27dc17680e183bb3"
compatibility_date = "2026-02-14"
pages_build_output_dir = "build/web"
```

Update the `account_id` with your Cloudflare account ID:

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Copy your Account ID from the right sidebar
3. Update `wrangler.toml` or use environment variable

### Step 2: Deploy to Cloudflare Pages

```bash
cd "new uplode"

# Option 1: Using npx (no global install needed)
npx wrangler pages deploy build/web --project-name=momit

# Option 2: Using global wrangler
wrangler pages deploy build/web --project-name=momit

# Option 3: With custom branch (for staging)
npx wrangler pages deploy build/web --project-name=momit --branch=staging
```

### Step 3: Configure Custom Domain (Optional)

1. Go to Cloudflare Dashboard → Pages
2. Select your project
3. Go to "Custom domains" tab
4. Click "Set up a custom domain"
5. Enter your domain (e.g., `momit.app`)
6. Follow the DNS configuration steps

### Step 4: Environment Variables on Cloudflare

If your app needs runtime environment variables:

```bash
# Add environment variables
npx wrangler pages secret put JWT_ACCESS_SECRET
npx wrangler pages secret put JWT_REFRESH_SECRET
npx wrangler pages secret put ADMIN_EMAILS
```

---

## Firestore Database Setup

### Step 1: Set Up Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to IAM & Admin → Service Accounts
3. Click "Create service account"
4. Name: `firestore-admin`
5. Grant roles:
   - `Cloud Datastore User`
   - `Firebase Admin SDK Administrator Service Agent`
6. Create key (JSON) and download
7. Save as `firestore/serviceAccountKey.json`

⚠️ **IMPORTANT:** Never commit `serviceAccountKey.json` to git!

### Step 2: Set Environment Variable

```bash
export GOOGLE_APPLICATION_CREDENTIALS="./firestore/serviceAccountKey.json"
```

Or on Windows:
```cmd
set GOOGLE_APPLICATION_CREDENTIALS=./firestore/serviceAccountKey.json
```

### Step 3: Initialize Firestore Schema

```bash
cd firestore

# Build TypeScript
npm run build

# Run initialization script
npm run init
```

This creates:
- Default user roles (super_admin, admin, moderator, editor, user)
- App configuration documents
- Feature flags
- Dynamic sections
- Initial audit log structure

### Step 4: Deploy Security Rules

```bash
# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes
```

### Step 5: Create Admin User

1. Register a user through the app
2. In Firebase Console → Firestore Database
3. Find the user document in `users` collection
4. Add field: `isAdmin: true` (boolean)
5. Or set `role: 'super_admin'` for full permissions

---

## Post-Deployment Verification

### 1. Verify Web Deployment

```bash
# Test the deployed URL
curl -I https://momit.pages.dev

# Expected: HTTP 200 OK with security headers
```

### 2. Check Security Headers

```bash
curl -I https://momit.pages.dev | grep -E "X-|Content-Security|Strict-Transport"
```

Expected headers:
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `Strict-Transport-Security: max-age=31536000`
- `Content-Security-Policy: ...`

### 3. Test Firebase Authentication

1. Open the deployed app
2. Try registering a new user
3. Verify user appears in Firebase Console → Authentication
4. Check user document created in Firestore

### 4. Test Firestore Database

```bash
# Check if collections were created
firebase firestore:databases:list

# View documents (requires firebase-tools)
firebase firestore:documents:get /users --project your-project-id
```

### 5. Verify PWA Features

1. Open Chrome DevTools → Application tab
2. Check Manifest is loaded correctly
3. Check Service Worker is registered
4. Run Lighthouse audit for PWA compliance

### 6. Test Admin Dashboard

1. Login with admin user
2. Navigate to Profile → Admin Dashboard
3. Verify all admin features load:
   - Dynamic sections management
   - Content management
   - App configuration
   - User roles

---

## Environment Variables Reference

### Firebase Configuration (lib/firebase_options.dart)

```dart
// All Firebase configuration values are in lib/firebase_options.dart
// Do NOT hardcode API keys in documentation.
// Web, Android, and iOS configurations reference project: momit-1
// See lib/firebase_options.dart for actual apiKey, appId, and other values.
```

### API Environment Variables (.env)

Create `.env` file in API directory (if using custom backend):

```bash
# JWT Secrets - Generate with: openssl rand -base64 32
JWT_ACCESS_SECRET=your_super_secret_access_key_min_32_chars_here
JWT_REFRESH_SECRET=your_super_secret_refresh_key_min_32_chars_here_different_from_access

# Admin Configuration
ADMIN_EMAILS=admin@momit.app,support@momit.app

# Optional: Default admin password (change immediately after setup)
DEFAULT_ADMIN_PASSWORD=ChangeThisPassword123!

# Firebase (if using Admin SDK)
FIREBASE_PROJECT_ID=momit-1
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@momit-1.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# CORS Configuration
ALLOWED_ORIGINS=https://momit.pages.dev,https://momit.app

# Node Environment
NODE_ENV=production
```

### Generating Secure Secrets

```bash
# Generate JWT secrets
openssl rand -base64 32

# Generate longer secret (64 bytes)
openssl rand -base64 64

# Generate hex secret
openssl rand -hex 32
```

---

## Troubleshooting

### Build Issues

#### Error: `Target dart2js failed`

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release --web-renderer html
```

#### Error: `Firebase configuration not found`

1. Verify `google-services.json` is in `android/app/`
2. Verify `GoogleService-Info.plist` is in `ios/Runner/`
3. Check `lib/firebase_options.dart` has correct values

### Deployment Issues

#### Error: `Could not find account_id in wrangler.toml`

```bash
# Get your account ID from Cloudflare Dashboard
# Or run:
npx wrangler whoami

# Then update wrangler.toml or use:
export CLOUDFLARE_ACCOUNT_ID=your_account_id
```

#### Error: `No such file or directory: build/web`

```bash
# Ensure build completed successfully
flutter build web --release --web-renderer html

# Verify output exists
ls -la build/web/
```

#### Error: `Authentication error`

```bash
# Login to Cloudflare
npx wrangler login

# Or use API token
export CLOUDFLARE_API_TOKEN=your_token
```

### Firebase Issues

#### Error: `Permission denied` in Firestore

1. Check Firestore rules are deployed:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. Verify user has proper authentication
3. Check custom claims for admin permissions

#### Error: `Firebase App named '[DEFAULT]' already exists`

```bash
# Clear browser cache and localStorage
# Or check for multiple Firebase.initializeApp() calls
```

### Authentication Issues

#### Google Sign-In not working

1. Verify OAuth consent screen is configured in Google Cloud Console
2. Add authorized domains in Firebase Console → Authentication → Settings
3. Check `webGoogleClientId` in `firebase_options.dart`
4. Verify `google-signin-client_id` meta tag in `index.html`

#### Admin dashboard not visible

1. Check user document has `isAdmin: true` or `role: 'admin'`
2. Logout and login again (claims are set at login)
3. Verify Firestore rules allow admin operations

### Performance Issues

#### Slow initial load

1. Enable CDN caching in Cloudflare
2. Compress images in `assets/images/`
3. Use lazy loading for routes
4. Enable Flutter's deferred loading

#### Firestore read limits exceeded

1. Check for inefficient queries
2. Add proper indexes (see `firestore.indexes.json`)
3. Implement pagination
4. Use caching where appropriate

### Common Error Messages

| Error | Solution |
|-------|----------|
| `404 Not Found` after refresh | Add SPA redirect rule in `_redirects` |
| `CORS error` | Add domain to Firebase authorized domains |
| `MIME type error` | Verify `_headers` file has correct content types |
| `Service worker failed` | Clear browser cache, unregister old SW |
| `Firebase: Error (auth/unauthorized-domain)` | Add domain to Firebase Console authorized domains |

---

## Security Checklist

Before going live, verify:

### Firebase Security

- [ ] Firestore rules restrict access appropriately
- [ ] Authentication is enabled and configured
- [ ] API keys are restricted to specific domains
- [ ] Service account keys are not in version control
- [ ] Firebase Storage rules are configured

### Application Security

- [ ] JWT secrets are strong (min 32 chars, random)
- [ ] Admin passwords are changed from defaults
- [ ] HTTPS is enforced (HSTS headers)
- [ ] Security headers are configured (`_headers` file)
- [ ] Content Security Policy is set
- [ ] CORS is configured properly

### Cloudflare Configuration

- [ ] Custom domain has SSL/TLS enabled
- [ ] Always Use HTTPS is enabled
- [ ] Security Level is appropriate
- [ ] Browser Integrity Check is enabled
- [ ] Hotlink protection is considered

### General Best Practices

- [ ] Environment variables are not exposed in code
- [ ] No sensitive data in client-side code
- [ ] Error messages don't leak system information
- [ ] Rate limiting is implemented
- [ ] Input validation is in place
- [ ] Regular dependency updates scheduled

---

## Maintenance

### Updating Dependencies

```bash
cd "new uplode"

# Check for outdated packages
flutter pub outdated

# Update packages
flutter pub upgrade

# Test thoroughly before deploying
flutter build web --release --web-renderer html
```

### Monitoring

1. Set up Firebase Analytics
2. Configure Firebase Crashlytics (for mobile)
3. Monitor Cloudflare Analytics
4. Set up Firebase Performance Monitoring

### Backups

```bash
# Export Firestore data
firebase firestore:export ./backups/$(date +%Y%m%d)

# Schedule regular backups via Cloud Functions
```

---

## Support

For deployment issues:

1. Check this guide's Troubleshooting section
2. Review Flutter documentation: https://flutter.dev/docs
3. Check Firebase documentation: https://firebase.google.com/docs
4. Cloudflare Pages docs: https://developers.cloudflare.com/pages/

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-17  
**Project:** MOMIT - Social Network for Mothers in Israel
