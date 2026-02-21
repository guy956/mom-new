# MOMIT Analytics Dashboard

## Overview

The Analytics Dashboard provides real-time insights into user activity, engagement, and growth metrics for the MOMIT platform. It offers comprehensive data visualization and export capabilities for administrators.

## Features

### 1. Real-time Active Users
- **Live Counter**: Shows users active in the last 5 minutes
- **Live Indicator**: Green "לייב" badge indicates real-time updates
- Updates automatically via Firestore listeners

### 2. Key Metrics
- **Total Users**: Overall registered users with growth trend
- **New Users Today**: Daily sign-ups with weekly comparison
- **Posts Count**: Total posts on the platform
- **Events Count**: Total events created

### 3. User Growth Chart
- **Line Chart**: Visualizes user growth over time
- **Time Range Support**: Switch between daily, weekly, or monthly views
- **Hover Tooltips**: Detailed information on data points
- **Trend Analysis**: Shows growth patterns

### 4. Feature Usage Analytics
- **Bar Chart**: Most popular platform features
- **Supported Features**:
  - צ׳אט (Chat)
  - פוסטים (Posts)
  - אירועים (Events)
  - מסירות (Marketplace)
  - מומחים (Experts)
  - טיפים (Tips)
  - פרופיל (Profile)
  - חיפוש (Search)
  - התראות (Notifications)
  - משחק (Gamification)

### 5. User Distribution
- **Pie Chart**: Visual breakdown of user statuses
- **Categories**:
  - פעילות (Active)
  - ממתינות (Pending)
  - חסומות (Banned)

### 6. Content Engagement Metrics
- **Posts**: Created, likes, comments
- **Events**: Created, RSVPs
- **Marketplace**: Items listed, items sold

### 7. Revenue Tracking
- **Total Revenue**: Combined from all sources
- **Marketplace Revenue**: Sales commission
- **Events Revenue**: Ticket sales
- **Premium Revenue**: Subscription fees

### 8. Date Range Selector
Available presets:
- היום (Today)
- השבוע (This Week)
- החודש (This Month)
- 7 ימים (Last 7 Days)
- 30 יום (Last 30 Days)
- 90 יום (Last 90 Days)
- השנה (This Year)
- טווח מותאם (Custom Range)

### 9. Export Functionality
- **CSV Export**: Raw data for spreadsheet analysis
- **PDF Report**: Formatted summary report

### 10. Activity Feed
- Real-time user action log
- Shows last 10 activities
- Includes action type, feature, and timestamp

## Architecture

### Files Structure
```
lib/
├── services/
│   └── analytics_service.dart      # Core analytics service
├── features/admin/
│   ├── tabs/
│   │   └── admin_overview_tab.dart # Main dashboard UI
│   └── widgets/
│       └── analytics_widgets.dart  # Reusable analytics widgets
```

### AnalyticsService

The `AnalyticsService` class provides:

#### User Action Tracking
```dart
await analyticsService.trackAction(
  userId: 'user-id',
  action: AnalyticsService.actionView,
  feature: 'posts',
  metadata: {'postId': '123'},
);
```

#### Statistics Aggregation
- `getUserGrowth(TimeRange)`: User registration trends
- `getFeatureUsage(TimeRange)`: Feature popularity
- `getContentEngagement(TimeRange)`: Content metrics
- `getRevenueStats(TimeRange)`: Revenue data

#### Real-time Streams
- `metricsStream`: Core metrics updates
- `activeUsersNowStream`: Live active user count
- `newUsersTodayStream`: Today's registrations
- `getRecentActions()`: Recent activity feed

#### Export Functions
- `exportToCsv()`: Export data as CSV
- `generateReportData()`: Generate report summary

## Firestore Collections

### analytics
```
analytics/
├── metrics              # Current aggregated metrics
├── feature_usage/
│   └── daily/{date}    # Daily feature usage counters
└── daily/
    └── stats/{date}    # Daily aggregated statistics
```

### analytics_events
```
analytics_events/       # Individual user actions
  - userId
  - action
  - feature
  - timestamp
  - metadata
  - sessionId
```

## Usage Examples

### Track Page View
```dart
final analytics = context.read<AnalyticsService>();
await analytics.trackView(
  userId: currentUser.id,
  page: 'marketplace',
);
```

### Track Feature Usage
```dart
await analytics.trackFeatureUsage(
  userId: currentUser.id,
  feature: 'chat',
  action: AnalyticsService.actionCreate,
);
```

### Get Growth Data
```dart
final growth = await analytics.getUserGrowth(
  TimeRange.last30Days(),
  granularity: 'week',
);
// Returns: {'2024-01-01': 15, '2024-01-08': 23, ...}
```

## Widgets Reference

### AnalyticsWidgets.statCard
```dart
AnalyticsWidgets.statCard(
  title: 'משתמשים חדשים',
  value: '150',
  icon: Icons.person_add,
  color: Colors.blue,
  trend: 12.5,  // Percentage
)
```

### AnalyticsWidgets.userGrowthChart
```dart
AnalyticsWidgets.userGrowthChart(
  data: userGrowthMap,
  title: 'צמיחת משתמשים',
  subtitle: '30 יום אחרונים',
)
```

### AnalyticsWidgets.featureUsageChart
```dart
AnalyticsWidgets.featureUsageChart(
  data: featureUsageMap,
)
```

### AnalyticsWidgets.dateRangeSelector
```dart
AnalyticsWidgets.dateRangeSelector(
  currentRange: selectedRange,
  onRangeChanged: (range) => setState(() => selectedRange = range),
  onCustomRange: () => showDatePicker(...),
)
```

## Testing

Run the analytics tests:
```bash
flutter test test/services/analytics_service_test.dart
flutter test test/admin/admin_overview_tab_test.dart
```

## Cloud Functions Integration

For production, set up Cloud Functions to:

1. **Aggregate Daily Analytics**
```javascript
exports.aggregateDailyAnalytics = functions.pubsub
  .schedule('0 1 * * *')  // Daily at 1 AM
  .onRun(async (context) => {
    const analytics = new AnalyticsService();
    await analytics.aggregateDailyAnalytics(new Date());
  });
```

2. **Update Real-time Metrics**
```javascript
exports.updateRealtimeMetrics = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const analytics = new AnalyticsService();
    await analytics.updateRealtimeMetrics();
  });
```

## Performance Considerations

1. **Caching**: Analytics data is cached to reduce Firestore reads
2. **Pagination**: Large datasets are paginated
3. **Debouncing**: Rapid updates are debounced
4. **Offline Support**: Analytics service works offline with local caching

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Analytics - admin only
    match /analytics/{document=**} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
      allow write: if false; // Only via Cloud Functions
    }
    
    // Analytics events - system only
    match /analytics_events/{eventId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
      allow create: if request.auth != null;
    }
  }
}
```

## Future Enhancements

- [ ] Funnel analysis (user journey tracking)
- [ ] Cohort analysis (retention metrics)
- [ ] A/B testing integration
- [ ] Predictive analytics
- [ ] Custom event tracking
- [ ] Real-time notifications for anomalies
- [ ] Comparative analytics (period vs period)
- [ ] User segmentation
- [ ] Heat maps for UI interactions
