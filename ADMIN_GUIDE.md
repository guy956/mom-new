# MOMIT Admin Dashboard Guide

Complete guide for using the MOMIT Admin Dashboard (God-Mode).

---

## 📑 Table of Contents

1. [Getting Started](#getting-started)
2. [Admin Tabs Overview](#admin-tabs-overview)
3. [Detailed Tab Guides](#detailed-tab-guides)
4. [User Management](#user-management)
5. [Content Management](#content-management)
6. [Security & Audit](#security--audit)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Accessing the Admin Dashboard

1. **Login with Admin Account**
   - Use an email address configured as admin in Firebase
   - Or have a user role assigned in the `user_roles` collection

2. **Navigate to Admin Dashboard**
   - From the main app: Profile → "Admin Dashboard" button
   - Direct URL: `/admin` route

3. **Verify Access**
   - The dashboard will load with accessible tabs based on your role
   - Unauthorized users will see an access denied message

### User Roles

The system has 4 role levels:

| Role | Description | Access Level |
|------|-------------|--------------|
| **Super Admin** | Full system access | All tabs and actions |
| **Admin** | Standard admin access | Most tabs, limited role assignment |
| **Moderator** | Content moderation | Content, reports, users (view only) |
| **Viewer** | Read-only access | View-only on most tabs |

### Setting Up an Admin User

#### Method 1: Admin Email List
```javascript
// In AuthService - predefined admin emails
static bool isAdminEmail(String email) {
  const adminEmails = [
    'admin@momit.app',
    'support@momit.app',
    // Add more admin emails here
  ];
  return adminEmails.contains(email.toLowerCase());
}
```

#### Method 2: Assign Role in Firestore
```javascript
// In Firebase Console → Firestore
db.collection('user_roles').doc('USER_ID').set({
  userId: 'USER_ID',
  role: 'admin',  // super_admin | admin | moderator | viewer
  assignedBy: 'admin_user_id',
  assignedAt: Timestamp.now(),
  expiresAt: null  // Optional: set expiration date
});
```

#### Method 3: Via Admin Dashboard
1. Go to "משתמשות" (Users) tab
2. Find the user
3. Click the role badge
4. Select new role
5. Confirm

---

## Admin Tabs Overview

The admin dashboard includes 17 tabs, each with specific functionality:

### Tab List by Category

#### 📊 Analytics & Overview
- **סקירה (Overview)** - Dashboard with key metrics and charts

#### 👥 User Management
- **משתמשות (Users)** - User list, approval, and management
- **מומחים (Experts)** - Expert directory management

#### 📦 Content Management
- **תוכן (Tips)** - Daily tips and content management
- **ניהול תוכן (Content Manager)** - Dynamic content management
- **דינמי (Dynamic)** - Dynamic sections configuration

#### 🎪 Community Features
- **אירועים (Events)** - Event creation and management
- **מסירות (Marketplace)** - Marketplace moderation

#### ⚙️ Configuration
- **הגדרות (Settings)** - App configuration
- **תכונות (Features)** - Feature toggles
- **עיצוב (Design)** - Colors and UI customization
- **ניווט (Navigation)** - Navigation structure editor

#### 🔧 System
- **מדיה (Media)** - Media library and uploads
- **תקשורת (Communication)** - Push notifications
- **טפסים (Forms)** - Dynamic form builder
- **דיווחים (Reports)** - User reports and moderation
- **אבטחה (Security)** - Audit logs and security monitoring

---

## Detailed Tab Guides

### 1. סקירה (Overview)

**Permission Required:** `viewAnalytics`

The Overview tab provides a high-level view of the app's health and activity.

#### Features:

**Key Metrics Cards**
- Total Users - Overall registered users count
- Active Today - Users active in last 24 hours
- Active This Week - Users active in last 7 days
- Pending Reports - Unresolved user reports

**Charts:**
- **User Registration Trend** - Line chart showing new registrations over 30 days
- **Most Active Sections** - Bar chart of feature usage
- **User Retention** - Retention rates (Day 1, 7, 30)

**Recent Activity:**
- Latest user registrations
- Recent posts
- Recent reports

**System Health:**
- Error counts by severity
- Performance metrics
- API status

#### Usage:
1. Monitor daily active users for engagement trends
2. Check pending reports for moderation needs
3. Review error logs for system issues

---

### 2. משתמשות (Users)

**Permission Required:** `viewUsers`

Manage all users in the system.

#### Features:

**User List:**
- Table view with sortable columns
- Search by name or email
- Filter by status (active, pending, banned)
- Export to CSV

**User Actions:**
- **View Profile** - See full user details
- **Edit User** - Modify user information
- **Change Role** - Assign admin/moderator roles
- **Ban/Unban** - Disable/enable user account
- **Delete** - Permanently remove user (super admin only)

**Bulk Actions:**
- Approve multiple pending users
- Export selected users
- Send mass notifications

#### User Statuses:
| Status | Description | Action Needed |
|--------|-------------|---------------|
| **Active** | Normal user | None |
| **Pending** | Awaiting approval | Approve or reject |
| **Banned** | Disabled account | Review for unban |
| **Verified** | Email verified | None |

#### User Profile View:
- Basic info (name, email, phone)
- Children information
- Activity stats (posts, comments, likes)
- Privacy settings
- Recent activity log

---

### 3. מומחים (Experts)

**Permission Required:** `viewExperts`

Manage the expert directory.

#### Features:

**Expert List:**
- Filter by category
- Sort by rating, consultations
- Search by name or specialty

**Expert Categories:**
- רופאת ילדים (Pediatrician)
- יועצת שינה (Sleep Consultant)
- יועצת הנקה (Lactation Consultant)
- דיאטנית (Dietitian)
- פסיכולוגית (Psychologist)
- מטפלת רגשית (Emotional Therapist)
- פיזיותרפיסטית (Physiotherapist)

**Expert Actions:**
- **Add Expert** - Create new expert profile
- **Edit Expert** - Update information
- **Verify** - Mark as verified expert
- **Remove** - Delete from directory

**Expert Profile Fields:**
- Name and photo
- Category and specialties
- Bio and credentials
- Rating and reviews
- Contact information
- Availability schedule

---

### 4. אירועים (Events)

**Permission Required:** `manageEvents`

Create and manage community events.

#### Features:

**Event List:**
- Calendar view and list view
- Filter by type, date, status
- Search by title or location

**Event Types:**
| Type | Icon | Description |
|------|------|-------------|
| מפגש משחק | 🧸 | Play meetups |
| סדנה | 🎨 | Workshops |
| וובינר | 💻 | Online webinars |
| ערב נשים | 🍷 | Women's evenings |
| קבוצת תמיכה | 💕 | Support groups |
| חוג | 📚 | Classes |

**Creating an Event:**
1. Click "+ אירוע חדש"
2. Fill event details:
   - Title and description
   - Date and time
   - Location (physical or online)
   - Maximum participants
   - Price (if applicable)
3. Upload event image
4. Set target age group
5. Add tags
6. Save

**Event Actions:**
- **Edit** - Modify event details
- **Duplicate** - Copy event as template
- **Cancel** - Cancel event and notify participants
- **Delete** - Remove event

**Participant Management:**
- View attendee list
- Export participant details
- Send message to all attendees

---

### 5. מסירות (Marketplace)

**Permission Required:** `viewMarketplace`

Moderate marketplace listings.

#### Features:

**Listings View:**
- Grid and list views
- Filter by category, status, price
- Sort by date, price, views

**Product Categories:**
- ציוד לתינוק (Baby equipment)
- עגלות (Strollers)
- ריהוט (Furniture)
- ביגוד (Clothing)
- צעצועים (Toys)
- ספרים (Books)

**Listing Actions:**
- **View Details** - See full listing
- **Edit** - Modify listing
- **Approve** - Approve pending listing
- **Reject** - Reject with reason
- **Remove** - Delete listing
- **Feature** - Pin to top

**Moderation Tools:**
- Auto-approve trusted sellers
- Flag suspicious listings
- View reported items
- Block problematic sellers

---

### 6. תוכן (Tips)

**Permission Required:** `viewContent`

Manage daily tips and content.

#### Features:

**Tips List:**
- Search by title or content
- Filter by category, age range
- Sort by date, popularity

**Tip Categories:**
- שינה (Sleep)
- האכלה (Feeding)
- התפתחות (Development)
- בריאות (Health)
- כושר (Fitness)
- רווחה נפשית (Mental health)

**Creating a Tip:**
1. Click "+ טיפ חדש"
2. Enter title and content
3. Select category
4. Set age range
5. Add media (optional)
6. Set active/inactive
7. Save

**Tip Actions:**
- **Edit** - Modify content
- **Toggle Active** - Enable/disable
- **Preview** - See how it appears
- **Delete** - Remove tip
- **Duplicate** - Copy as new

**Bulk Import:**
- Upload CSV file with multiple tips
- JSON import for advanced users

---

### 7. דיווחים (Reports)

**Permission Required:** `viewReports`

Handle user reports and moderation.

#### Features:

**Reports List:**
- Filter by status (pending, resolved, dismissed)
- Filter by type (post, user, message)
- Sort by date, severity

**Report Types:**
| Type | Description |
|------|-------------|
| **Spam** | Unwanted promotional content |
| **Harassment** | Bullying or harassment |
| **Inappropriate** | Content violates guidelines |
| **Fake Profile** | Suspicious or fake account |
| **Other** | Other concerns |

**Handling Reports:**
1. Review reported content
2. Choose action:
   - **Dismiss** - No action needed
   - **Warn User** - Send warning
   - **Remove Content** - Delete post/message
   - **Ban User** - Disable account
3. Add admin note
4. Mark as resolved

**Report Details:**
- Reporter information
- Reported content preview
- Report reason
- Previous reports (if any)
- User history

---

### 8. הגדרות (Settings)

**Permission Required:** `viewConfig`

Configure app-wide settings.

#### Features:

**App Information:**
- App name
- Slogan/tagline
- Contact email
- Support phone

**Registration Settings:**
- Require approval for new users
- Email verification required
- Minimum age requirement

**Content Settings:**
- Auto-moderation level
- Profanity filter
- Image moderation

**Notification Defaults:**
- Default notification preferences
- Email notification settings
- Push notification defaults

---

### 9. תכונות (Features)

**Permission Required:** `manageFeatures`

Enable or disable app features dynamically.

#### Feature Toggles:

| Feature | Description | Default |
|---------|-------------|---------|
| **צ'אט** | Chat between users | ✅ On |
| **אירועים** | Events feature | ✅ On |
| **מסירות** | Marketplace | ✅ On |
| **מומחים** | Expert directory | ✅ On |
| **טיפים** | Daily tips | ✅ On |
| **מד מצב רוח** | Mood tracking | ✅ On |
| **SOS** | Emergency button | ✅ On |
| **גיימיפיקציה** | Points and badges | ✅ On |
| **צ'אט AI** | AI assistant | ✅ On |
| **WhatsApp** | WhatsApp integration | ✅ On |
| **אלבום** | Photo albums | ✅ On |
| **מעקב** | Baby tracking | ✅ On |

#### Moderation Settings:
- Require user approval
- Auto content filter
- Profanity filter
- Require event approval

**Usage:**
1. Toggle switches to enable/disable features
2. Changes apply immediately
3. Users will see/hide features automatically

---

### 10. עיצוב (Design)

**Permission Required:** `manageUIDesign`

Customize app colors and UI.

#### Color Configuration:

**App Colors:**
- **Primary** - Main brand color
- **Secondary** - Supporting color
- **Accent** - Highlight/emphasis color

**Color Presets:**
8 predefined color palettes available:
- Pink/Rose (default)
- Purple
- Blue
- Green
- Orange
- Custom

**Category Management:**
- Expert categories
- Tip categories
- Marketplace categories

**Menu Order:**
- Drag and drop to reorder navigation
- Changes reflect immediately in app

**Live Preview:**
- See color changes in real-time
- Preview before saving

---

### 11. ניווט (Navigation)

**Permission Required:** `editConfig`

Edit app navigation structure.

#### Features:

**Navigation Items:**
- Reorder tabs with drag and drop
- Show/hide navigation items
- Set default tab

**Navigation Items List:**
1. בית (Home)
2. צ'אט (Chat)
3. קהילה (Community)
4. אירועים (Events)
5. מומחים (Experts)
6. פרופיל (Profile)

**Actions:**
- Drag handle to reorder
- Toggle to show/hide
- Save to apply changes

---

### 12. דינמי (Dynamic Sections)

**Permission Required:** `editConfig`

Manage dynamic content sections.

#### Features:

**Section List:**
- View all dynamic sections
- Toggle active/inactive
- Reorder sections

**Creating a Section:**
1. Click "+ סקשן חדש"
2. Enter:
   - Key (unique identifier)
   - Name (display name)
   - Type (hero, features, tips, etc.)
   - Order (position)
3. Configure settings
4. Save

**Section Types:**
- **Hero** - Main banner/header
- **Features** - Feature highlights
- **Tips** - Tips carousel
- **Community** - Community stats
- **CTA** - Call to action

**Section Settings:**
- Background image
- Text alignment
- Show overlay
- Custom styling

---

### 13. ניהול תוכן (Content Manager)

**Permission Required:** `viewContent`

Advanced content management for dynamic sections.

#### Features:

**Content Items:**
- Create content for any section
- Schedule publish dates
- Draft mode

**Content Types:**
- Text
- Image
- Video
- Link

**Content Fields:**
- Title
- Subtitle
- Body text
- Media URL
- Link URL
- Link text

**Scheduling:**
- Start date (when to publish)
- End date (when to unpublish)
- Timezone support

---

### 14. מדיה (Media)

**Permission Required:** `viewMedia`

Central media library.

#### Features:

**Media Grid:**
- View all uploaded media
- Filter by type (image, video)
- Sort by date, size
- Search by name

**Upload Media:**
- Drag and drop upload
- Multiple file upload
- Progress indicator
- Auto-compression for images

**Media Actions:**
- **Preview** - Full size view
- **Copy URL** - Copy direct link
- **Delete** - Remove from library
- **Replace** - Upload replacement

**Usage in Content:**
- Select media when creating content
- Automatic optimization
- CDN delivery

---

### 15. תקשורת (Communication)

**Permission Required:** `manageCommunication`

Send push notifications to users.

#### Features:

**Send Notification:**
1. Choose target audience:
   - All users
   - Specific users
   - By filter (location, interests)
2. Compose message:
   - Title
   - Body
   - Image (optional)
   - Action URL
3. Schedule (optional)
4. Preview
5. Send

**Notification History:**
- View sent notifications
- See delivery stats
- Track open rates
- Cancel scheduled notifications

**Templates:**
- Save notification templates
- Reuse for common messages

---

### 16. טפסים (Forms)

**Permission Required:** `manageForms`

Build dynamic forms.

#### Features:

**Registration Form:**
- Add/remove fields
- Mark fields as required
- Field validation rules

**SOS Form:**
- Customize emergency form
- Add custom fields
- Configure auto-response

**Form Fields:**
- Text input
- Number input
- Email
- Phone
- Select dropdown
- Checkbox
- Radio buttons
- Date picker

---

### 17. אבטחה (Security)

**Permission Required:** `viewAuditLog`

Monitor security and audit logs.

#### Features:

**Activity Log:**
- View all admin actions
- Filter by user, action type, date
- Export logs

**Audit Entries:**
| Field | Description |
|-------|-------------|
| Timestamp | When action occurred |
| User | Who performed the action |
| Action | What was done |
| Type | Category of action |
| Details | Additional information |

**Security Alerts:**
- Failed login attempts
- Unusual activity
- Permission changes

**Log Retention:**
- Automatic cleanup of old logs
- Configurable retention period

---

## User Management

### User Lifecycle

```
Registration → Approval (if required) → Active → Optional: Ban/Delete
```

### Approval Workflow

1. **New User Registers**
   - If `requireUserApproval` is enabled, user gets "pending" status

2. **Admin Review**
   - Go to Users tab
   - Filter by "pending" status
   - Review user information

3. **Approve or Reject**
   - Click checkmark to approve
   - Click X to reject (with reason)
   - User gets email notification

### Banning Users

**When to Ban:**
- Multiple violations of community guidelines
- Spam or harassment
- Fake profile
- At user request

**Ban Process:**
1. Go to user profile
2. Click "Ban User"
3. Select reason:
   - Spam
   - Harassment
   - Inappropriate content
   - Fake account
   - Other
4. Set duration (temporary or permanent)
5. Confirm

**Unban Process:**
1. Find banned user
2. Click "Unban"
3. Confirm

---

## Content Management

### Content Approval Workflow

For content types with approval enabled:

1. **User Submits Content**
   - Content gets "pending" status
   - Not visible to other users

2. **Admin Review**
   - Review in relevant tab (Tips, Events, etc.)
   - Check content quality and guidelines

3. **Approve/Reject**
   - Approve: Content becomes visible
   - Reject: Send feedback to user

### Content Guidelines

**Approved Content:**
- Original and helpful
- Appropriate for target audience
- No personal information
- No promotional spam

**Rejected Content:**
- Duplicate or low quality
- Violates community guidelines
- Contains misinformation
- Promotional without value

---

## Security & Audit

### Best Practices

1. **Regular Review**
   - Check audit logs weekly
   - Review failed login attempts
   - Monitor for unusual activity

2. **Role Management**
   - Only give necessary permissions
   - Review roles quarterly
   - Remove access for departed team members

3. **Password Security**
   - Use strong passwords
   - Enable 2FA if available
   - Don't share accounts

### Audit Log Analysis

**Red Flags to Watch:**
- Multiple failed login attempts
- Unusual access times
- Permission changes outside normal workflow
- Bulk deletions

**Monthly Review Checklist:**
- [ ] Review all permission changes
- [ ] Check for unauthorized access attempts
- [ ] Verify content deletions
- [ ] Review user bans

---

## Best Practices

### General Guidelines

1. **Always Test Changes**
   - Test in development first
   - Use staging environment
   - Verify on mobile and web

2. **Document Changes**
   - Add notes in audit log
   - Document configuration changes
   - Keep change log

3. **Coordinate with Team**
   - Communicate major changes
   - Avoid conflicting edits
   - Use activity log to stay informed

4. **Monitor Impact**
   - Watch analytics after changes
   - Monitor error logs
   - Check user feedback

### Content Management

1. **Scheduling**
   - Schedule content in advance
   - Consider time zones
   - Plan around holidays/events

2. **Quality Control**
   - Proofread before publishing
   - Check all links work
   - Verify images load correctly

3. **Accessibility**
   - Add alt text to images
   - Use clear language
   - Consider color contrast

### User Communication

1. **Push Notifications**
   - Don't over-send
   - Personalize when possible
   - Use clear, concise language

2. **User Support**
   - Respond to reports promptly
   - Be professional and empathetic
   - Follow up on resolved issues

---

## Troubleshooting

### Common Issues

#### Changes Not Appearing

**Problem:** Made changes in admin but not showing in app

**Solutions:**
1. Check if section is active (`isActive: true`)
2. Check if content is published (`isPublished: true`)
3. Verify publish dates are in valid range
4. Refresh app to clear cache
5. Check Firestore rules allow read access

#### Admin Tab Not Showing

**Problem:** Can't see admin dashboard button

**Solutions:**
1. Verify `isAdmin: true` in user document
2. Check `user_roles` collection for role assignment
3. Logout and login again
4. Check email is in admin email list

#### Can't Save Changes

**Problem:** Getting error when saving

**Solutions:**
1. Check internet connection
2. Verify admin permissions
3. Check browser console for errors
4. Ensure all required fields are filled
5. Check Firestore security rules

#### User Can't Access Feature

**Problem:** User reports feature is missing

**Solutions:**
1. Check feature flag is enabled
2. Verify user meets requirements (age, verification)
3. Check if feature is location-restricted
4. Ask user to update app

### Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Permission denied" | Insufficient role | Contact super admin |
| "Network error" | Connection issue | Check internet |
| "Invalid data" | Form validation | Check all fields |
| "Not found" | Document deleted | Refresh page |

### Getting Help

**Internal Issues:**
- Check activity log for recent changes
- Review error logs in Security tab
- Ask team members in communication channel

**Technical Support:**
- Email: support@momit.app
- Include: error message, screenshots, steps to reproduce

---

## Quick Reference

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+S | Save current form |
| Ctrl+R | Refresh data |
| Escape | Close modal/dialog |

### Color Codes

| Role | Color | Code |
|------|-------|------|
| Super Admin | Purple | #8E44AD |
| Admin | Red | #E74C3C |
| Moderator | Blue | #3498DB |
| Viewer | Gray | #95A5A6 |

### Status Indicators

| Status | Icon | Color |
|--------|------|-------|
| Active | ✓ | Green |
| Pending | ⏳ | Yellow |
| Banned | 🚫 | Red |
| Inactive | ○ | Gray |

---

*Last updated: February 2026*
