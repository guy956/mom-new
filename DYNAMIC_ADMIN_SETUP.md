# Firestore Setup for Dynamic Admin Dashboard

## Collections Structure

### 1. `app_config` (Singleton Document)
```json
{
  "appName": "MOMIT",
  "slogan": "כי רק אמא מבינה אמא",
  "navigationOrder": ["home", "chat", "events", "profile"],
  "featureVisibility": {
    "chat": true,
    "events": true,
    "marketplace": true,
    "experts": true,
    "tips": true
  },
  "themeSettings": {},
  "updatedAt": "timestamp"
}
```

### 2. `dynamic_sections` (Collection)
```json
{
  "key": "hero",
  "name": "כותרת ראשית",
  "description": "אזור הכותרת הראשית בדף הבית",
  "type": "hero",
  "order": 0,
  "isActive": true,
  "settings": {
    "backgroundImage": "",
    "textAlign": "center",
    "showOverlay": true
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 3. `content_management` (Collection)
```json
{
  "sectionId": "section_id_here",
  "title": "כותרת התוכן",
  "subtitle": "כותרת משנה",
  "body": "תוכן מלא...",
  "type": "text",
  "mediaUrl": "https://...",
  "linkUrl": "https://...",
  "linkText": "למידע נוסף",
  "order": 0,
  "isPublished": true,
  "metadata": {},
  "startDate": "timestamp",
  "endDate": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Required Firestore Indexes

Create these composite indexes in Firebase Console:

### Collection: `dynamic_sections`
```
Fields:
1. isActive (Ascending)
2. order (Ascending)

Query scope: Collection
```

### Collection: `content_management`
```
Fields:
1. sectionId (Ascending)
2. isPublished (Ascending)
3. order (Ascending)

Query scope: Collection
```

```
Fields:
1. updatedAt (Descending)

Query scope: Collection
```

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // App Config - Public read, Admin write
    match /app_config/{doc} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Dynamic Sections - Public read active only, Admin full access
    match /dynamic_sections/{section} {
      allow read: if resource.data.isActive == true || isAdmin();
      allow create, update, delete: if isAdmin();
    }

    // Content Management - Public read published only, Admin full access
    match /content_management/{content} {
      allow read: if resource.data.isPublished == true || isAdmin();
      allow create, update, delete: if isAdmin();
    }

    // Other collections (existing)
    match /users/{user} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == user;
    }
  }
}
```

## Setup Instructions

1. **Create Collections**: The app will auto-create collections on first run via `seedDefaultSections()`

2. **Create Indexes**: Go to Firebase Console → Firestore Database → Indexes and create the composite indexes listed above

3. **Update Security Rules**: Copy the security rules above to Firebase Console → Firestore Database → Rules

4. **Admin User**: Ensure your user document has `isAdmin: true` field

## Default Sections Created

The system will automatically create these default sections:

1. **hero** - כותרת ראשית (Hero section)
2. **features** - תכונות עיקריות (Features grid)
3. **tips** - טיפים יומיים (Daily tips)
4. **community** - קהילה (Community section)
5. **cta** - קריאה לפעולה (Call to action buttons)

## Testing

1. Open Admin Dashboard
2. Go to "דינמי" tab
3. You should see the default sections
4. Try:
   - Reordering sections via drag & drop
   - Toggling section visibility
   - Editing section settings
   - Creating new sections
   - Adding content to sections
   - Reordering content items
