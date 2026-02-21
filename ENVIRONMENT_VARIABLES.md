# MOMIT Environment Variables Reference

## Cloudflare Pages Deployment Variables

### Required for Deployment

| Variable | Description | How to Obtain | Example |
|----------|-------------|---------------|---------|
| `CLOUDFLARE_API_TOKEN` | API token for Cloudflare API access | Cloudflare Dashboard → My Profile → API Tokens | `gUp2Z...` |
| `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account identifier | Cloudflare Dashboard → any domain → right sidebar | `c3da1f83...` |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `CLOUDFLARE_PAGES_PROJECT_NAME` | `momit` | Name of the Pages project |

---

## Application Environment Variables (`.env`)

### Admin Configuration

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `ADMIN_EMAILS` | ✅ Yes | Comma-separated admin email addresses | `admin@example.com,support@example.com` |

### JWT Security

| Variable | Required | Description | How to Generate |
|----------|----------|-------------|-----------------|
| `JWT_ACCESS_SECRET` | ✅ Yes | Secret key for access tokens | `openssl rand -base64 32` |
| `JWT_REFRESH_SECRET` | ✅ Yes | Secret key for refresh tokens | `openssl rand -base64 32` |

**Important:** Minimum 32 characters required. Generate with:
```bash
openssl rand -base64 32
```

### API Configuration

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `API_BASE_URL` | ✅ Yes | Base URL for API requests | `https://api.momit.app` |
| `GEMINI_API_KEY` | ⚠️ Conditional | Google Gemini API key for AI chat | `AIzaSyDENOB...` |

**Get Gemini API Key:** https://ai.google.dev/

### Feature Flags

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_ANALYTICS` | `true` | Enable analytics collection |
| `ENABLE_CRASHLYTICS` | `true` | Enable crash reporting |

### App Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_NAME` | `MOMIT` | Application name |
| `APP_VERSION` | `1.0.0` | Application version |

---

## GitHub Actions Secrets

Add these to **Settings → Secrets and variables → Actions**:

| Secret Name | Value |
|-------------|-------|
| `CLOUDFLARE_API_TOKEN` | Your API token from Cloudflare |
| `CLOUDFLARE_ACCOUNT_ID` | Your account ID |

---

## Complete `.env` Template

```bash
# ============================================
# CLOUDFLARE DEPLOYMENT
# ============================================
CLOUDFLARE_API_TOKEN=your_api_token_here
CLOUDFLARE_ACCOUNT_ID=your_account_id_here
CLOUDFLARE_PAGES_PROJECT_NAME=momit

# ============================================
# ADMIN CONFIGURATION
# ============================================
ADMIN_EMAILS=your-email@example.com

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

---

## Environment Variable Checklist

Before deployment, ensure:

- [ ] `.env` file created from `.env.example`
- [ ] `CLOUDFLARE_API_TOKEN` is valid (test with `wrangler whoami`)
- [ ] `CLOUDFLARE_ACCOUNT_ID` matches dashboard
- [ ] `ADMIN_EMAILS` contains valid email(s)
- [ ] `JWT_ACCESS_SECRET` is at least 32 characters
- [ ] `JWT_REFRESH_SECRET` is different from access secret
- [ ] `API_BASE_URL` is correct and accessible
- [ ] `GEMINI_API_KEY` is valid (if using AI features)
- [ ] `.env` is listed in `.gitignore`

---

## Testing Environment Variables

```bash
# Test Cloudflare authentication
wrangler whoami

# Verify API token
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"

# Test API endpoint
curl -I $API_BASE_URL/health
```

---

## Security Notes

⚠️ **CRITICAL:**
- Never commit `.env` files to version control
- Rotate API tokens regularly
- Use scoped tokens with minimal permissions
- Keep JWT secrets secure - treat them like passwords
- Use different secrets for production vs. development
