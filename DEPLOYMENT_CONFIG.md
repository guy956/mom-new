# Cloudflare Pages Deployment Configuration for MOMIT

**Project:** MOMIT (momit.pages.dev)  
**Platform:** Cloudflare Pages  
**Framework:** Flutter Web  
**Last Updated:** 2026-02-17

---

## ✅ Pre-Deployment Verification Checklist

### 1. Security Headers Configuration (`web/_headers`)

**Status:** ✅ Verified and Complete

The `_headers` file is properly configured with comprehensive security headers:

| Header | Value | Purpose |
|--------|-------|---------|
| X-Frame-Options | DENY | Prevents clickjacking attacks |
| X-Content-Type-Options | nosniff | Prevents MIME-type sniffing |
| X-XSS-Protection | 1; mode=block | XSS protection (legacy browsers) |
| Referrer-Policy | strict-origin-when-cross-origin | Controls referrer information |
| Permissions-Policy | camera=(self), microphone=(self)... | Restricts browser feature access |
| Cross-Origin-Embedder-Policy | credentialless | Controls cross-origin embedding |
| Cross-Origin-Opener-Policy | same-origin-allow-popups | Isolates browsing context |
| Cross-Origin-Resource-Policy | cross-origin | Controls resource sharing |
| Strict-Transport-Security | max-age=31536000; includeSubDomains; preload | Enforces HTTPS |

**Cache Configuration:**
- Static assets (`/assets/*`, `/icons/*`): 1 year with immutable flag
- Service worker: No cache (must-revalidate)
- HTML entry point (`index.html`): No cache
- Main app files (`main.dart.js`): 1 hour cache
- Legal pages (`/privacy`, `/terms`): 1 day cache

### 2. SPA Routing Configuration (`web/_redirects`)

**Status:** ✅ Verified and Complete

The `_redirects` file handles:

| Rule | From | To | Status |
|------|------|-----|--------|
| HTTPS enforcement | `http://*` | `https://:splat` | 301 |
| Canonical URLs | `/privacy` | `/privacy.html` | 301 |
| Canonical URLs | `/terms` | `/terms.html` | 301 |
| SEO redirects | `/about`, `/contact`, `/help` | `/` | 301 |
| SPA fallback | `/*` | `/index.html` | 200 |

**Important:** The SPA fallback (`/* /index.html 200`) ensures client-side routing works correctly for a Flutter Web application.

### 3. Firebase Configuration (`firebase.json`)

**Status:** ✅ Verified and Complete

The Firebase hosting configuration mirrors the Cloudflare Pages headers and routing:

**Hosting Settings:**
```json
{
  "hosting": {
    "public": "build/web",
    "trailingSlash": false,
    "rewrites": [...],
    "headers": [...]
  }
}
```

**Key Features:**
- Public directory: `build/web`
- SPA rewrite: `/**` → `/index.html`
- Static file rewrites for `/privacy`, `/terms`, `/robots.txt`, `/sitemap.xml`
- Security headers matching Cloudflare Pages configuration
- Cache control headers for optimal performance

**Firestore & Storage:**
- Firestore rules: `firestore.rules`
- Firestore indexes: `firestore.indexes.json`
- Storage rules: `storage.rules`

---

## 🔧 Required Environment Variables

### Cloudflare Pages Deployment Variables

| Variable | Required | Description | Source |
|----------|----------|-------------|--------|
| `CLOUDFLARE_API_TOKEN` | ✅ Yes | API token for Cloudflare access | Cloudflare Dashboard → Profile → API Tokens |
| `CLOUDFLARE_ACCOUNT_ID` | ✅ Yes | Cloudflare account identifier | Cloudflare Dashboard → Right sidebar |
| `CLOUDFLARE_PAGES_PROJECT_NAME` | ⚠️ Optional | Project name (default: `momit`) | Created during project setup |

### Application Environment Variables (`.env`)

**⚠️ CRITICAL: Never commit this file to version control!**

```bash
# ============================================
# ADMIN CONFIGURATION
# ============================================
# Comma-separated list of admin emails
ADMIN_EMAILS=ola.cos85@gmail.com

# ============================================
# JWT SECURITY
# ============================================
# Generate with: openssl rand -base64 32
JWT_ACCESS_SECRET=your_access_secret_here
JWT_REFRESH_SECRET=your_refresh_secret_here

# ============================================
# API CONFIGURATION
# ============================================
API_BASE_URL=https://api.momit.app

# Google Gemini API Key for AI Chat
GEMINI_API_KEY=your_gemini_api_key_here

# ============================================
# FEATURE FLAGS
# ============================================
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true

# ============================================
# APP CONFIGURATION
# ============================================
APP_NAME=MOMIT
APP_VERSION=1.0.0
```

### Flutter/Firebase Configuration

Firebase configuration is loaded from `lib/firebase_options.dart` - no environment variables needed for web.

---

## 📋 Deployment Steps

### Prerequisites

1. **Flutter SDK** installed (version 3.24.0 or later)
2. **Node.js** and **npm** installed
3. **Wrangler CLI** installed: `npm install -g wrangler`
4. **Cloudflare account** with Pages project created

### Step 1: Initial Setup (One-Time)

```bash
# 1. Clone/navigate to the project
cd mom-project

# 2. Install Flutter dependencies
flutter pub get

# 3. Create environment file
cp .env.example .env
# Edit .env with your actual values

# 4. Login to Cloudflare
wrangler login
```

### Step 2: Build Configuration

**Build Command:**
```bash
flutter build web \
  --release \
  --web-renderer html \
  --no-tree-shake-icons \
  --dart-define=ENV=production
```

**Build Output:** `build/web/`

**Important Build Options:**
- `--web-renderer html`: Required for Firebase Auth compatibility
- `--no-tree-shake-icons`: Prevents missing icons in production
- `--dart-define=ENV=production`: Sets production environment

### Step 3: Deploy Using Provided Scripts

**Option A: Using deploy.sh (Recommended for Local)**
```bash
# Make executable
chmod +x deploy.sh

# Deploy to production
./deploy.sh production

# Deploy to preview/staging
./deploy.sh preview
```

**Option B: Using deploy_cf_pages.py (Direct API)**
```bash
# Ensure dependencies are installed
pip install requests

# Run deployment script
python3 deploy_cf_pages.py
```

**Option C: Manual Wrangler Deploy**
```bash
# Build first
flutter build web --release --web-renderer html --no-tree-shake-icons

# Deploy with wrangler
npx wrangler pages deploy build/web --project-name=momit
```

### Step 4: Verify Deployment

1. **Check deployment URL:**
   - Production: `https://momit.pages.dev`
   - Preview: `https://[branch-name].momit.pages.dev`

2. **Verify headers:**
   ```bash
   curl -I https://momit.pages.dev
   ```

3. **Test SPA routing:**
   - Navigate to `https://momit.pages.dev/privacy`
   - Refresh the page - should work without 404

4. **Check security headers:**
   ```bash
   curl -I https://momit.pages.dev | grep -E "(X-Frame|X-Content|Referrer|Strict-Transport)"
   ```

---

## 🔒 Security Checklist

Before each deployment, verify:

- [ ] `.env` file is in `.gitignore`
- [ ] No secrets in code
- [ ] Firebase security rules reviewed
- [ ] Security headers present in response
- [ ] HTTPS enforced
- [ ] CSP (Content Security Policy) configured if needed

---

## 🚀 CI/CD Integration (GitHub Actions)

### Required Repository Secrets

Go to **GitHub Repository → Settings → Secrets and variables → Actions**:

| Secret Name | Value |
|-------------|-------|
| `CLOUDFLARE_API_TOKEN` | Your Cloudflare API token |
| `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account ID |

### Workflow Configuration

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release --web-renderer html --no-tree-shake-icons
      
      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: momit
          directory: build/web
```

---

## 📊 Post-Deployment Verification

### Automated Checks

Run the following after each deployment:

```bash
# Check site is accessible
curl -s -o /dev/null -w "%{http_code}" https://momit.pages.dev
# Expected: 200

# Verify security headers
curl -I https://momit.pages.dev 2>/dev/null | grep -E "^((HTTP|X-|Referrer|Strict-Transport|Permissions))"

# Test SPA routing
curl -s -o /dev/null -w "%{http_code}" https://momit.pages.dev/privacy
# Expected: 200 (not 404)

# Check main.js loads
curl -s -o /dev/null -w "%{http_code}" https://momit.pages.dev/main.dart.js
# Expected: 200
```

### Manual Testing Checklist

- [ ] Homepage loads correctly
- [ ] Navigation works (client-side routing)
- [ ] Direct URL access works (e.g., refresh on `/privacy`)
- [ ] Firebase Auth functions correctly
- [ ] Images and assets load properly
- [ ] Service worker registers
- [ ] Mobile responsiveness verified

---

## 🆘 Troubleshooting

### Common Issues

#### Build Fails
```
Error: Flutter not found
```
**Solution:** Install Flutter SDK and ensure it's in PATH

#### Wrangler Authentication Failed
```
Error: Could not authenticate
```
**Solution:** Run `wrangler login` or check `CLOUDFLARE_API_TOKEN`

#### 404 on Page Refresh
```
404 Not Found on /some-route
```
**Solution:** Verify `_redirects` file has `/* /index.html 200`

#### Missing Security Headers
**Solution:** Verify `_headers` file is in `web/` directory and copied to `build/web/`

#### Large Bundle Size
**Solution:** Consider code splitting or using `--web-renderer canvaskit` (smaller but less compatible)

---

## 📚 Additional Resources

- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Flutter Web Deployment](https://docs.flutter.dev/platform-integration/web)
- [Wrangler CLI Reference](https://developers.cloudflare.com/workers/wrangler/)
- [Cloudflare Pages Headers Format](https://developers.cloudflare.com/pages/configuration/headers/)
- [Cloudflare Pages Redirects Format](https://developers.cloudflare.com/pages/configuration/redirects/)

---

## 📝 Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-17 | 1.0 | Initial deployment configuration |

---

**Ready for deployment to:** `https://momit.pages.dev` ✅
