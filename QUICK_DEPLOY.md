# MOMIT Quick Deployment Guide

This guide explains how to deploy MOMIT immediately using the pre-built `build-web.zip` file, without needing to fix source code issues first.

## Overview

- **Build file**: `build-web.zip` (11MB compressed, 32MB extracted)
- **Contents**: Complete Flutter web build with all assets
- **Deployment target**: Cloudflare Pages
- **Estimated deploy time**: 1-2 minutes

## Prerequisites

1. **Node.js and npm** installed
2. **wrangler CLI** installed:
   ```bash
   npm install -g wrangler
   ```
3. **Cloudflare account** with Pages access
4. **Authenticated wrangler**:
   ```bash
   wrangler login
   ```

## Quick Deploy (One Command)

```bash
cd /Users/joni/.openclaw/workspace/mom-project
./quick-deploy.sh
```

The script will:
1. ✓ Verify `build-web.zip` exists and is valid
2. ✓ Extract to `build/web/`
3. ✓ Verify all critical files are present
4. ✓ Check wrangler configuration
5. ✓ Prompt for deployment confirmation
6. ✓ Deploy to Cloudflare Pages

## Manual Deployment

If you prefer manual steps:

```bash
cd /Users/joni/.openclaw/workspace/mom-project

# 1. Clean and extract
rm -rf build/web
unzip build-web.zip

# 2. Verify files
ls build/web/index.html
ls build/web/main.dart.js
ls build/web/flutter.js

# 3. Deploy
wrangler pages deploy build/web --project-name=momit
```

## What's Included in the Build

### Core Files
- `index.html` - Main entry point
- `main.dart.js` (5.1MB) - Compiled Flutter application
- `flutter.js`, `flutter_bootstrap.js`, `flutter_service_worker.js` - Flutter runtime
- `security.js` - Security headers and scripts

### Configuration
- `_headers` - HTTP headers for Cloudflare
- `_redirects` - URL redirect rules
- `manifest.json` - PWA manifest

### Assets
- `assets/` - Flutter assets (images, fonts, etc.)
- `canvaskit/` - Canvas rendering engine
- `icons/` - App icons (192px, 512px, maskable)
- `privacy/`, `terms/` - Legal pages

### Total: 42 files, 32MB

## Post-Deployment

### Verify Deployment
```bash
# Check deployment status
wrangler pages deployment list --project-name=momit

# View live site
open https://momit.pages.dev
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `wrangler not found` | Run: `npm install -g wrangler` |
| `Not authenticated` | Run: `wrangler login` |
| `Project not found` | Check `wrangler.toml` or create project in Cloudflare Dashboard |
| `Build files missing` | Re-extract: `unzip -o build-web.zip` |

## Build Contents Verification

After extraction, verify these critical files:

```bash
cd build/web

# Check core files exist
[ -f index.html ] && echo "✓ index.html"
[ -f main.dart.js ] && echo "✓ main.dart.js"
[ -f flutter.js ] && echo "✓ flutter.js"
[ -f manifest.json ] && echo "✓ manifest.json"

# Check directories
[ -d assets ] && echo "✓ assets/"
[ -d icons ] && echo "✓ icons/"
[ -d canvaskit ] && echo "✓ canvaskit/"
```

## Updating the Build

If you need to update `build-web.zip`:

1. Fix source code issues
2. Build Flutter web:
   ```bash
   flutter build web --release
   ```
3. Create new zip:
   ```bash
   cd build
   zip -r ../build-web.zip web/
   ```

## Configuration Files

### wrangler.toml
```toml
name = "momit"
account_id = "c3da1f83e98070eb27dc17680e183bb3"
compatibility_date = "2026-02-14"
pages_build_output_dir = "build/web"
```

### Environment Variables
Copy `.env.example` to `.env` and configure:
- Firebase credentials
- API endpoints
- Feature flags

## Notes

- This deployment uses **pre-built files** - no compilation needed
- Source code fixes can be done **after** deployment
- The zip was created on: 2026-02-17
- Build ID: Check `.last_build_id` in build/web/

## Support

For issues with:
- **Deployment**: Check Cloudflare Pages dashboard
- **Build files**: Re-extract from build-web.zip
- **Application**: Check browser console for errors

## Deployment Status

Last verified: 2026-02-17
- ✓ Zip file valid
- ✓ All files extracted
- ✓ Wrangler configured
- ✓ Ready for deployment
