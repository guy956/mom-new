# MOMIT Dynamic Configuration Guide

Complete guide for dynamically configuring the MOMIT app through the admin dashboard without code changes or redeployment.

---

## 📑 Table of Contents

1. [Overview](#overview)
2. [Changing App Colors](#changing-app-colors)
3. [Modifying Navigation](#modifying-navigation)
4. [Managing Features](#managing-features)
5. [Dynamic Sections](#dynamic-sections)
6. [Content Management](#content-management)
7. [Text Overrides](#text-overrides)
8. [Configuration Reference](#configuration-reference)

---

## Overview

MOMIT supports dynamic configuration through Firebase Firestore. This allows administrators to:

- ✅ Change app colors instantly
- ✅ Reorder navigation items
- ✅ Enable/disable features
- ✅ Add dynamic content sections
- ✅ Modify text without code changes
- ✅ Schedule content publication

All changes are applied in real-time to all connected clients.

### How It Works

```
Admin Dashboard → Firestore → Real-time Sync → All Clients
```

1. Admin makes change in dashboard
2. Change saved to Firestore `admin_config` collection
3. Firestore broadcasts update to all connected clients
4. App updates automatically without refresh

### Configuration Collections

| Collection | Purpose | Real-time |
|------------|---------|-----------|
| `admin_config/app_config` | General app settings | ✅ Yes |
| `admin_config/ui_config` | Colors and UI | ✅ Yes |
| `admin_config/feature_flags` | Feature toggles | ✅ Yes |
| `admin_config/text_overrides` | Custom text | ✅ Yes |
| `dynamic_sections` | Dynamic sections | ✅ Yes |
| `content_management` | Managed content | ✅ Yes |

---

## Changing App Colors

### Via Admin Dashboard (Recommended)

1. Go to **עיצוב (Design)** tab
2. Find the **צבעי אפליקציה (App Colors)** section
3. Click on the color you want to change
4. Select from preset colors or enter custom HEX code
5. Click **שמור (Save)**

### Color Configuration

**Primary Color** (`primaryColor`)
- Used for: Buttons, active states, highlights
- Default: `#D4A1AC` (Dusty Rose)
- Recommended: Brand color

**Secondary Color** (`secondaryColor`)
- Used for: Backgrounds, secondary elements
- Default: `#EDD3D8` (Light Pink)
- Recommended: Lighter variant of primary

**Accent Color** (`accentColor`)
- Used for: Special highlights, CTAs
- Default: `#DBC8B0` (Beige)
- Recommended: Complementary color

### Available Color Presets

```javascript
const colorPresets = [
  '#D4A1AC',  // Dusty Rose (default)
  '#EDD3D8',  // Light Pink
  '#DBC8B0',  // Beige
  '#B5C8B9',  // Sage Green
  '#D1C2D3',  // Lavender
  '#7986CB',  // Periwinkle
  '#FF8A65',  // Coral
  '#81C784',  // Light Green
];
```

### Custom Colors

To set a custom color:

1. Click the color input field
2. Enter HEX code (e.g., `#FF5733`)
3. Preview updates automatically
4. Save changes

### Color Application Areas

```
Primary Color:
├── AppBar background
├── Primary buttons
├── Active navigation items
├── Links
└── Selected states

Secondary Color:
├── Card backgrounds
├── Secondary buttons
├── Hover states
└── Subtle highlights

Accent Color:
├── Call-to-action buttons
├── Special badges
├── Important highlights
└── Success states
```

### Firestore Direct Update

If needed, update directly in Firestore:

```javascript
// Using Firebase Console or Admin SDK
db.collection('admin_config').doc('ui_config').update({
  primaryColor: '#D4A1AC',
  secondaryColor: '#EDD3D8',
  accentColor: '#DBC8B0',
  updatedAt: Timestamp.now()
});
```

---

## Modifying Navigation

### Navigation Structure

The app navigation is defined in the `menuOrder` field and consists of these items:

```javascript
const defaultNavigation = [
  'בית',      // Home
  'צ\'אט',    // Chat
  'קהילה',   // Community
  'אירועים', // Events
  'מומחים',  // Experts
  'פרופיל',  // Profile
];
```

### Reordering Navigation

**Via Admin Dashboard:**

1. Go to **ניווט (Navigation)** tab
2. See list of navigation items
3. Drag items using the handle (⋮⋮) to reorder
4. Changes save automatically

**Via Firestore:**

```javascript
db.collection('admin_config').doc('ui_config').update({
  menuOrder: ['בית', 'אירועים', 'צ\'אט', 'קהילה', 'מומחים', 'פרופיל'],
  updatedAt: Timestamp.now()
});
```

### Hiding Navigation Items

To hide a navigation item:

1. Go to **תכונות (Features)** tab
2. Toggle off the corresponding feature
3. Navigation item hides automatically

### Custom Navigation Items

For advanced customization, you can add custom navigation items:

```javascript
// In Firestore - requires app support
db.collection('admin_config').doc('ui_config').update({
  customNavItems: [
    {
      id: 'custom_page',
      label: 'עמוד מותאם',
      icon: 'star',
      route: '/custom'
    }
  ]
});
```

---

## Managing Features

### Feature Flags

Feature flags allow enabling/disabling features without redeployment.

### Available Features

| Feature Key | Description | Default |
|-------------|-------------|---------|
| `chat` | Chat between users | true |
| `events` | Events feature | true |
| `marketplace` | Marketplace | true |
| `experts` | Expert directory | true |
| `tips` | Daily tips | true |
| `mood` | Mood tracking | true |
| `sos` | Emergency button | true |
| `gamification` | Points and badges | true |
| `aiChat` | AI assistant | true |
| `whatsapp` | WhatsApp integration | true |
| `album` | Photo albums | true |
| `tracking` | Baby tracking | true |

### Enabling/Disabling Features

**Via Admin Dashboard:**

1. Go to **תכונות (Features)** tab
2. Find the feature you want to toggle
3. Click the switch to enable/disable
4. Changes apply immediately

**Quick Actions:**
- **הפעל הכל (Enable All)** - Turn on all features
- **כבה הכל (Disable All)** - Turn off all features (use with caution!)

**Via Firestore:**

```javascript
// Disable chat feature
db.collection('admin_config').doc('feature_flags').update({
  chat: false,
  updatedAt: Timestamp.now()
});

// Enable chat feature
db.collection('admin_config').doc('feature_flags').update({
  chat: true,
  updatedAt: Timestamp.now()
});
```

### Moderation Settings

Additional feature-related settings:

| Setting | Description | Default |
|---------|-------------|---------|
| `requireUserApproval` | New users need approval | false |
| `autoContentFilter` | Automatic content filtering | true |
| `profanityFilter` | Filter inappropriate language | true |
| `requireEventApproval` | Events need admin approval | false |

### Feature Visibility Logic

```dart
// Example implementation
if (featureFlags['chat'] == true) {
  showChatTab();
} else {
  hideChatTab();
}
```

---

## Dynamic Sections

### What Are Dynamic Sections?

Dynamic sections are content areas on the home screen that can be:
- Created
- Modified
- Reordered
- Enabled/disabled
- Scheduled

All without code changes.

### Default Sections

| Section Key | Name | Type | Description |
|-------------|------|------|-------------|
| `hero` | כותרת ראשית | hero | Main banner |
| `features` | תכונות עיקריות | features | Feature highlights |
| `tips` | טיפים | tips | Tips carousel |
| `community` | קהילה | community | Community stats |
| `cta` | קריאה לפעולה | cta | Call to action |

### Creating a Section

**Via Admin Dashboard:**

1. Go to **דינמי (Dynamic)** tab
2. Click **+ סקשן חדש**
3. Fill section details:
   - **Key** - Unique identifier (lowercase, no spaces)
   - **Name** - Display name in Hebrew
   - **Description** - Internal description
   - **Type** - Section type
   - **Order** - Position in list
4. Configure settings
5. Toggle **Active** to show/hide
6. Click **שמור**

**Via Firestore:**

```javascript
db.collection('dynamic_sections').add({
  key: 'custom_section',
  name: 'סקשן מותאם',
  description: 'תיאור של הסקשן',
  type: 'custom',
  order: 5,
  isActive: true,
  settings: {
    backgroundImage: 'https://...',
    textAlign: 'center',
    showOverlay: true,
    customClass: 'my-section'
  },
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now()
});
```

### Section Types

| Type | Purpose | Settings |
|------|---------|----------|
| `hero` | Main banner | backgroundImage, textAlign, showOverlay |
| `features` | Feature grid | columns, iconStyle, cardStyle |
| `tips` | Tips carousel | autoPlay, interval, showDots |
| `community` | Stats display | statTypes, layout |
| `cta` | Call to action | buttonStyle, link, target |
| `custom` | Custom content | html, css, js |

### Reordering Sections

**Via Admin Dashboard:**

1. Go to **דינמי (Dynamic)** tab
2. Drag sections using the handle (⋮⋮)
3. Order saves automatically
4. Refresh app to see changes

**Via Firestore:**

```javascript
// Update order for multiple sections
const batch = db.batch();

batch.update(db.collection('dynamic_sections').doc('hero_id'), {
  order: 0
});

batch.update(db.collection('dynamic_sections').doc('tips_id'), {
  order: 1
});

await batch.commit();
```

### Section Settings Reference

**Hero Section:**
```javascript
{
  backgroundImage: 'https://example.com/hero.jpg',
  textAlign: 'center', // left | center | right
  showOverlay: true,   // boolean
  overlayOpacity: 0.5, // 0-1
  minHeight: '400px',  // CSS value
  textColor: '#FFFFFF' // HEX color
}
```

**Features Section:**
```javascript
{
  columns: 3,           // 2 | 3 | 4
  iconStyle: 'filled',  // filled | outlined | rounded
  cardStyle: 'elevated',// elevated | outlined | flat
  showIcons: true,      // boolean
  animation: 'fade'     // none | fade | slide
}
```

**Tips Section:**
```javascript
{
  autoPlay: true,       // boolean
  interval: 5000,       // milliseconds
  showDots: true,       // boolean
  showArrows: true,     // boolean
  transition: 'slide'   // slide | fade | none
}
```

---

## Content Management

### Content Items

Content items are pieces of content assigned to dynamic sections.

### Creating Content

**Via Admin Dashboard:**

1. Go to **ניהול תוכן (Content Manager)** tab
2. Select the section for the content
3. Click **+ תוכן חדש**
4. Fill content details:
   - **Title** - Main title
   - **Subtitle** - Secondary title
   - **Body** - Main content (supports basic HTML)
   - **Type** - Content type
   - **Media URL** - Image or video URL
   - **Link URL** - Click-through link
   - **Link Text** - Button text
5. Set schedule (optional)
6. Toggle **Published** status
7. Click **שמור**

**Via Firestore:**

```javascript
db.collection('content_management').add({
  sectionId: 'section_id_here',
  title: 'כותרת התוכן',
  subtitle: 'כותרת משנה',
  body: 'תוכן מלא...',
  type: 'text', // text | image | video | link
  mediaUrl: 'https://example.com/image.jpg',
  linkUrl: 'https://example.com/page',
  linkText: 'למידע נוסף',
  order: 0,
  isPublished: true,
  metadata: {
    author: 'Admin Name',
    tags: ['tag1', 'tag2']
  },
  startDate: Timestamp.fromDate(new Date('2026-02-20')),
  endDate: Timestamp.fromDate(new Date('2026-03-20')),
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now()
});
```

### Content Types

| Type | Description | Fields Required |
|------|-------------|-----------------|
| `text` | Text content | title, body |
| `image` | Image content | mediaUrl |
| `video` | Video content | mediaUrl |
| `link` | Link card | linkUrl, linkText |
| `mixed` | Mixed media | title, body, mediaUrl |

### Scheduling Content

Content can be scheduled to appear and disappear automatically:

```javascript
{
  // Content visible from Feb 20, 2026
  startDate: Timestamp.fromDate(new Date('2026-02-20T00:00:00')),
  
  // Content hidden after March 20, 2026
  endDate: Timestamp.fromDate(new Date('2026-03-20T23:59:59')),
  
  // Must also be published
  isPublished: true
}
```

**Scheduling Tips:**
- Set `startDate` for future publication
- Set `endDate` for automatic removal
- Use for time-sensitive content (holidays, events)
- Schedule in user's timezone (default: Israel time)

### Draft Mode

To keep content as draft:

```javascript
{
  isPublished: false,
  // No startDate needed
}
```

Draft content is visible only to admins.

### Content Ordering

Content items within a section are ordered by the `order` field:

```javascript
// Lower number = appears first
{ order: 0 }  // First
{ order: 1 }  // Second
{ order: 2 }  // Third
```

---

## Text Overrides

### What Are Text Overrides?

Text overrides allow changing any text in the app without code changes or redeployment.

### Supported Text Areas

- App strings
- Button labels
- Form labels
- Error messages
- Success messages
- Navigation labels

### Creating Text Overrides

**Via Admin Dashboard:**

1. Go to **הגדרות (Settings)** tab
2. Find **Text Overrides** section
3. Click **+ הוספת טקסט**
4. Enter:
   - **Key** - The text key to override
   - **Value** - The new text
5. Click **שמור**

**Via Firestore:**

```javascript
db.collection('admin_config').doc('text_overrides').set({
  welcome_message: 'ברוכה הבאה לאפליקציית MOMIT!',
  home_title: 'הקהילה שלי',
  button_submit: 'שליחה',
  // Section-based overrides
  auth: {
    login_title: 'התחברי לחשבונך',
    register_title: 'הרשמי עכשיו'
  },
  updatedAt: Timestamp.now()
}, { merge: true });
```

### Common Text Keys

| Key | Default | Description |
|-----|---------|-------------|
| `app_name` | MOMIT | App name |
| `welcome_message` | ברוכה הבאה | Welcome message |
| `home_title` | בית | Home screen title |
| `chat_title` | צ'אט | Chat screen title |
| `button_submit` | שלח | Submit button |
| `button_cancel` | ביטול | Cancel button |
| `error_generic` | שגיאה | Generic error |
| `success_saved` | נשמר | Success message |

### Section-Based Overrides

Organize overrides by section:

```javascript
{
  auth: {
    login_title: 'התחברי',
    register_title: 'הרשמי',
    forgot_password: 'שכחת סיסמה?'
  },
  feed: {
    empty_message: 'אין פוסטים עדיין',
    create_post: 'צרי פוסט חדש'
  },
  profile: {
    edit_profile: 'עריכת פרופיל',
    my_children: 'הילדים שלי'
  }
}
```

---

## Configuration Reference

### Complete Configuration Structure

```javascript
// admin_config/app_config
db.collection('admin_config').doc('app_config').set({
  appName: 'MOMIT',
  slogan: 'כי רק אמא מבינה אמא',
  contactEmail: 'support@momit.app',
  supportPhone: '03-1234567',
  version: '1.0.0',
  updatedAt: Timestamp.now()
});

// admin_config/ui_config
db.collection('admin_config').doc('ui_config').set({
  primaryColor: '#D4A1AC',
  secondaryColor: '#EDD3D8',
  accentColor: '#DBC8B0',
  menuOrder: ['בית', 'צ\'אט', 'קהילה', 'אירועים', 'מומחים', 'פרופיל'],
  expertCategories: ['רופאת ילדים', 'יועצת שינה', 'יועצת הנקה'],
  tipCategories: ['שינה', 'האכלה', 'התפתחות', 'בריאות'],
  marketplaceCategories: ['ציוד לתינוק', 'עגלות', 'ריהוט', 'בגדים'],
  updatedAt: Timestamp.now()
});

// admin_config/feature_flags
db.collection('admin_config').doc('feature_flags').set({
  chat: true,
  events: true,
  marketplace: true,
  experts: true,
  tips: true,
  mood: true,
  sos: true,
  gamification: true,
  aiChat: true,
  whatsapp: true,
  album: true,
  tracking: true,
  requireUserApproval: false,
  autoContentFilter: true,
  profanityFilter: true,
  requireEventApproval: false,
  updatedAt: Timestamp.now()
});

// admin_config/announcement
db.collection('admin_config').doc('announcement').set({
  enabled: true,
  title: 'עדכון חדש!',
  message: 'גרסה חדשה זמינה עם תכונות מדהימות',
  type: 'info', // info | warning | success
  actionText: 'קראי עוד',
  actionUrl: '/update',
  dismissible: true,
  showOnce: false,
  startDate: Timestamp.now(),
  endDate: Timestamp.fromDate(new Date('2026-12-31')),
  updatedAt: Timestamp.now()
});

// admin_config/text_overrides
db.collection('admin_config').doc('text_overrides').set({
  welcome_message: 'ברוכה הבאה לאפליקציית MOMIT!',
  // ... other overrides
  updatedAt: Timestamp.now()
});
```

### Default Values

If configuration documents don't exist, the app uses these defaults:

```dart
const defaultAppConfig = {
  'appName': 'MOMIT',
  'slogan': 'כי רק אמא מבינה אמא',
  'contactEmail': 'support@momit.app',
};

const defaultUIConfig = {
  'primaryColor': '#D4A1AC',
  'secondaryColor': '#EDD3D8',
  'accentColor': '#DBC8B0',
  'menuOrder': ['בית', 'צ\'אט', 'קהילה', 'אירועים', 'מומחים', 'פרופיל'],
};

const defaultFeatureFlags = {
  'chat': true,
  'events': true,
  'marketplace': true,
  'experts': true,
  'tips': true,
  'mood': true,
  'sos': true,
  'gamification': true,
  'aiChat': true,
  'whatsapp': true,
  'album': true,
  'tracking': true,
};

const defaultModerationSettings = {
  'requireUserApproval': false,
  'autoContentFilter': true,
  'profanityFilter': true,
  'requireEventApproval': false,
};
```

### Configuration Caching

The app caches configuration for 5 minutes to reduce Firestore reads. To force refresh:

1. Pull-to-refresh on relevant screen
2. Logout and login again
3. Clear app data (mobile)

### Configuration Migration

When adding new configuration fields:

1. Add to default values
2. Update admin dashboard UI
3. Document in this guide
4. Test with existing configs

---

## Best Practices

### Colors
- Use consistent color palette
- Ensure WCAG 2.2 AA contrast ratios
- Test on light and dark modes
- Consider colorblind users

### Navigation
- Keep most-used items first
- Don't hide critical features
- Maintain logical grouping
- Test on small screens

### Features
- Communicate changes to users
- Provide fallback for disabled features
- Monitor usage analytics
- Don't disable during peak hours

### Content
- Plan content calendar
- Use scheduling for time-sensitive content
- Preview before publishing
- Keep backups of important content

### Testing
- Test changes in staging first
- Verify on multiple devices
- Check accessibility
- Monitor error logs after changes

---

*Last updated: February 2026*
