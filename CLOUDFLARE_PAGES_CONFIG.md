# Cloudflare Pages Configuration for MOMIT

This document describes the configuration needed to deploy MOMIT to Cloudflare Pages.

## Quick Start

### Option 1: One-Click GitHub Actions Deployment (Recommended)

1. Push to `main` branch → Automatic deployment
2. Or go to GitHub → Actions → Deploy to Cloudflare Pages → Run workflow

### Option 2: Local Deployment

```bash
# Make script executable
chmod +x deploy.sh

# Deploy to production
./deploy.sh production

# Deploy preview/staging
./deploy.sh preview
```

---

## Environment Variables

### Required Secrets (GitHub Repository Settings)

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Description | How to Get |
|--------|-------------|------------|
| `CLOUDFLARE_API_TOKEN` | API token for Cloudflare access | Cloudflare Dashboard → My Profile → API Tokens |
| `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account ID | Cloudflare Dashboard → any domain → right sidebar |
| `CLOUDFLARE_PAGES_PROJECT_NAME` | Pages project name (default: `momit`) | Created during project setup |

### Optional Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FLUTTER_VERSION` | `3.24.0` | Flutter SDK version for CI |
| `NODE_VERSION` | `20` | Node.js version for Wrangler |

### Local Environment (for deploy.sh)

Create a `.env` file in project root:

```bash
# Cloudflare credentials (optional - will use wrangler login)
CLOUDFLARE_API_TOKEN=your_api_token_here
CLOUDFLARE_ACCOUNT_ID=your_account_id_here
CLOUDFLARE_PAGES_PROJECT_NAME=momit
```

---

## Cloudflare Pages Project Setup

### 1. Create Pages Project

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to **Pages**
3. Click **Create a project**
4. Choose **Upload assets** (we'll use Direct Upload, not Git integration)
5. Project name: `momit` (or your preferred name)
6. Click **Create project**

### 2. Get API Token

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token**
3. Use the **Custom token** template
4. Configure permissions:
   - **Zone:Read** (optional, for custom domains)
   - **Account:Read**
   - **Cloudflare Pages:Edit**
5. **Account Resources**: Include your account
6. **Zone Resources** (optional): Include your domain
7. Click **Continue to summary** → **Create token**
8. Copy the token immediately (shown only once)

### 3. Get Account ID

1. In Cloudflare Dashboard, open any domain
2. Look at the right sidebar
3. Copy **Account ID**

---

## Build Settings

### GitHub Actions Build Configuration

| Setting | Value |
|---------|-------|
| Build Command | `flutter build web --release --web-renderer html --no-tree-shake-icons` |
| Build Output Directory | `build/web` |
| Flutter Version | 3.24.0 (configurable) |
| Node Version | 20 |

### Flutter Build Options Explained

```bash
flutter build web \
  --release \              # Production build
  --web-renderer html \    # HTML renderer (better compatibility)
  --no-tree-shake-icons     # Keep all icons (prevents missing icons)
```

### Important Notes

1. **HTML Renderer**: Required for proper Firebase Auth on web
2. **Tree Shaking**: Disabled for icons to prevent runtime issues
3. **Build Output**: All files in `build/web/` are deployed

---

## Domain Configuration

### Custom Domain (Optional)

1. In Cloudflare Pages project → **Custom domains**
2. Click **Set up a custom domain**
3. Enter your domain (e.g., `momit.co.il`)
4. Follow DNS configuration instructions
5. Enable **Always Use HTTPS**

### Default Pages.dev URL

After first deployment, your app will be available at:
```
https://momit.pages.dev
```

---

## Deployment Workflows

### Automatic Deployment (GitHub Actions)

```yaml
Triggers:
  - Push to main branch
  - Manual trigger (workflow_dispatch)
  - Pull requests (creates preview deployments)
```

### Branch Strategy

| Branch | Deployment Type | URL Pattern |
|--------|----------------|-------------|
| `main` | Production | `https://momit.pages.dev` |
| `feature/*` | Preview | `https://[branch-name].momit.pages.dev` |
| PRs | Preview | GitHub comment with URL |

---

## Troubleshooting

### Common Issues

#### 1. Build Fails - Missing Flutter

```
Error: Flutter not found
```
**Solution**: GitHub Actions uses `subosito/flutter-action` to install Flutter automatically.

#### 2. Wrangler Authentication Failed

```
Error: Could not authenticate
```
**Solution**: 
- Verify `CLOUDFLARE_API_TOKEN` is set correctly
- Check token has `Cloudflare Pages:Edit` permission
- For local: Run `wrangler login`

#### 3. Project Not Found

```
Error: Could not find project
```
**Solution**: 
- Create project in Cloudflare Dashboard first
- Verify `CLOUDFLARE_PAGES_PROJECT_NAME` matches exactly

#### 4. Large Bundle Size

Flutter web builds are large by default. Consider:
- Using `--web-renderer canvaskit` (smaller but less compatible)
- Enabling compression on Cloudflare
- Using deferred loading for large components

---

## Security Best Practices

1. **API Tokens**: Use scoped tokens with minimal permissions
2. **Secrets**: Never commit `.env` files
3. **Preview Deployments**: Use for testing, protect production
4. **Custom Domains**: Enable Always Use HTTPS
5. **CORS**: Configure in `security.js` for API access

---

## Monitoring

### Cloudflare Analytics

- **Real-time metrics**: Requests, bandwidth, errors
- **Web Analytics**: Core Web Vitals, page load times
- **Security**: Threats blocked, bot traffic

### Build Logs

- GitHub Actions: Check **Actions** tab
- Local: Terminal output shows all build steps

---

## Support

- **Cloudflare Docs**: https://developers.cloudflare.com/pages/
- **Wrangler CLI**: https://developers.cloudflare.com/workers/wrangler/
- **Flutter Web**: https://docs.flutter.dev/platform-integration/web
