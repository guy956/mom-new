# MOMIT - API Keys & Configuration Guide

## Environment Variables (.env)

All API keys are stored securely in the `.env` file at the project root.
**NEVER commit API keys to source control.**

---

### Admin Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `ADMIN_EMAILS` | Comma-separated admin emails | `admin@example.com,admin2@example.com` |

---

### JWT Authentication

| Variable | Description | Min Length |
|----------|-------------|-----------|
| `JWT_ACCESS_SECRET` | Secret for access token signing | 32 chars |
| `JWT_REFRESH_SECRET` | Secret for refresh token signing | 32 chars |

**Important:** If these are not set, random secrets are generated at runtime. This means user sessions will NOT persist across app restarts.

---

### Gemini AI (MomBot)

| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | Google Gemini 2.0 Flash API key |

**Where it's used:** `lib/features/ai_chat/screens/ai_chat_screen.dart`

**How to get a new key:**
1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Create a new API key
3. Add it to `.env`

**Fallback:** If `.env` key is missing, the app tries to load from Firestore `admin_config/api_keys` document (field: `geminiApiKey`).

---

### Mailjet Email (Admin Notifications)

| Variable | Description |
|----------|-------------|
| `MAILJET_API_KEY` | Mailjet API key |
| `MAILJET_SECRET_KEY` | Mailjet secret key |

**Where it's used:** `lib/services/email_service.dart`

**How to get keys:**
1. Go to [Mailjet Dashboard](https://app.mailjet.com/account/apikeys)
2. Copy API Key and Secret Key
3. Add them to `.env`

**Email Configuration:**

| Variable | Description | Default |
|----------|-------------|---------|
| `EMAIL_FROM` | Sender email address | `noreply@momit.co.il` |
| `EMAIL_FROM_NAME` | Sender display name | `MOMIT System` |

---

### Firebase Configuration

Firebase keys are configured in `lib/firebase_options.dart` (not in `.env`).

| Platform | API Key | App ID |
|----------|---------|--------|
| Web | `AIzaSyCjI-LFvVTF2WPHRMiVVS4ClbnSixG1bR4` | `1:459220254220:web:...` |
| Android | Same as Web | `1:459220254220:android:...` |
| iOS | `AIzaSyAWumTmBmRzyqw1mBg3q63kzrsaED1S1ds` | `1:459220254220:ios:...` |

**Project ID:** `momit-1`
**Storage Bucket:** `momit-1.firebasestorage.app`

---

### Google Sign-In (Web)

| Variable | Location | Status |
|----------|----------|--------|
| `webGoogleClientId` | `firebase_options.dart` line 65 | Needs configuration |

**How to configure:**
1. Go to [Google Cloud Console](https://console.cloud.google.com) > Project `momit-1`
2. APIs & Credentials > OAuth 2.0 Client IDs
3. Create: OAuth client ID > Type: "Web application"
4. Add Authorized JavaScript origins:
   - `https://momit.pages.dev`
   - `https://momit-1.firebaseapp.com`
   - `http://localhost`
5. Add Authorized redirect URIs:
   - `https://momit-1.firebaseapp.com/__/auth/handler`
6. Copy Client ID to `firebase_options.dart` line 65

---

## Security Notes

1. **`.env` file is listed in `.gitignore`** - it should never be committed
2. **`.env` is bundled as a Flutter asset** (listed in `pubspec.yaml`) - it's loaded at runtime via `flutter_dotenv`
3. **Firebase API keys** are in source code but protected by Firebase Security Rules
4. **Firestore `admin_config` collection** requires authentication to read (updated from public access)
5. **JWT secrets** should be unique per environment (dev/staging/prod)
6. **Mailjet keys** are used server-side only for email sending

---

## Environment Setup

### Development
```bash
cp .env.example .env
# Edit .env with your development keys
```

### Production
Set environment variables in your hosting platform (Cloudflare Pages, etc.)

---

## Key Rotation

If you need to rotate keys:

1. **Gemini API Key:** Generate new key in Google AI Studio, update `.env`
2. **Mailjet Keys:** Generate new keys in Mailjet dashboard, update `.env`
3. **JWT Secrets:** Change in `.env` - WARNING: All existing sessions will be invalidated
4. **Firebase Keys:** These are project-bound and generally don't change
