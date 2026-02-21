# Feature Flag System

A comprehensive feature flag/toggle system for the MOMIT Flutter application that allows enabling/disabling features remotely without code changes.

## Overview

The feature flag system provides:
- **Remote Configuration**: Toggle features from Firebase Firestore
- **Local Caching**: Fast startup with cached flags
- **Real-time Updates**: Automatic sync when flags change
- **Rollout Percentage**: Gradual feature rollouts to specific user percentages
- **Backward Compatibility**: Works alongside the legacy feature flag system

## Files Created

### 1. Model (`lib/models/feature_flag_model.dart`)
- `FeatureFlag` class with properties: id, name, description, enabled, rolloutPercentage
- `FeatureFlagIds` class with predefined flag IDs
- Serialization methods for Firestore and local cache
- User-based rollout logic

### 2. Service (`lib/services/feature_flag_service.dart`)
- `FeatureFlagService` singleton for managing feature flags
- Methods:
  - `initialize()`: Initialize and load cached flags
  - `fetchFlags()`: Fetch flags from Firestore
  - `enableRealtimeUpdates()`: Enable real-time sync
  - `isEnabled(String flagId)`: Check if feature is enabled
  - `isEnabledForUser(String flagId, String userId)`: Check with rollout
  - `toggleFlag(String flagId)`: Toggle a flag (admin)
  - `updateMultipleFlags(Map<String, bool>)`: Batch update (admin)
  - `resetToDefaults()`: Reset to defaults (admin)
  - `seedInitialFlags()`: Create initial flags in Firestore

### 3. Widgets (`lib/widgets/feature_flag_widgets.dart`)
- `FeatureFlagGuard`: Conditionally renders children based on flag
- `FeatureFlagForUser`: Shows different widgets based on user rollout
- `AnimatedFeatureFlagGuard`: Animated show/hide based on flag
- `ExperimentalFeatureBadge`: Badge for beta features
- `FeatureFlagExtension`: BuildContext extension methods

### 4. Updated Admin Tab (`lib/features/admin/tabs/admin_feature_toggles_tab.dart`)
- New UI for managing feature flags
- Toggle switches for each flag
- Actions: Seed initial, Reset to defaults, Refresh

## Predefined Feature Flags

| Flag ID | Feature | Default |
|---------|---------|---------|
| `enable_ai_chat` | AI Chat (MomBot) | ✅ Enabled |
| `enable_marketplace` | Marketplace | ✅ Enabled |
| `enable_events` | Events | ✅ Enabled |
| `enable_gamification` | Gamification | ✅ Enabled |
| `enable_whatsapp` | WhatsApp Integration | ✅ Enabled |
| `enable_experts` | Experts | ✅ Enabled |
| `enable_sos` | SOS Button | ✅ Enabled |
| `enable_daily_tips` | Daily Tips | ✅ Enabled |
| `enable_mood_tracker` | Mood Tracker | ✅ Enabled |
| `enable_album` | Photo Album | ✅ Enabled |
| `enable_tracking` | Development Tracking | ✅ Enabled |
| `enable_chat` | Chat | ✅ Enabled |

## Usage

### Check if a feature is enabled (Global)

```dart
// Using the service directly
final featureService = context.read<FeatureFlagService>();
if (featureService.isEnabled(FeatureFlagIds.enableAiChat)) {
  // Show AI Chat feature
}

// Using the convenience getter
if (featureService.isAiChatEnabled) {
  // Show AI Chat feature
}
```

### Check with user rollout percentage

```dart
final featureService = context.read<FeatureFlagService>();
final userId = context.read<AppState>().currentUser?.id ?? '';

if (featureService.isEnabledForUser(FeatureFlagIds.enableAiChat, userId)) {
  // Show feature to this specific user
}
```

### Using the widget wrapper

```dart
FeatureFlagGuard(
  featureId: FeatureFlagIds.enableAiChat,
  child: AIChatButton(),
  fallback: SizedBox.shrink(),
)
```

### Using with animation

```dart
AnimatedFeatureFlagGuard(
  featureId: FeatureFlagIds.enableAiChat,
  duration: Duration(milliseconds: 300),
  child: NewFeatureWidget(),
)
```

### BuildContext extension

```dart
// In any widget build method
if (context.isFeatureEnabled(FeatureFlagIds.enableAiChat, useNewSystem: true)) {
  // Show feature
}
```

## Admin Usage

### In the Admin Dashboard

1. Navigate to **Feature Toggles** tab
2. Use the new **Feature Flag System** card to manage flags
3. Toggle switches to enable/disable features
4. Use action buttons:
   - **יצירת דגלים ראשוניים**: Create initial flags in Firestore
   - **איפוס לברירת מחדל**: Reset all flags to defaults
   - **רענון**: Refresh flags from Firestore

### Programmatic Admin Operations

```dart
final service = FeatureFlagService.instance;

// Toggle a feature
await service.toggleFlag(FeatureFlagIds.enableAiChat);

// Update multiple flags
await service.updateMultipleFlags({
  FeatureFlagIds.enableAiChat: true,
  FeatureFlagIds.enableMarketplace: false,
});

// Reset to defaults
await service.resetToDefaults();

// Seed initial data
await service.seedInitialFlags();
```

## Firestore Structure

```
feature_flags (collection)
  ├── enable_ai_chat (document)
  │     ├── name: "צ'אט AI"
  │     ├── description: "מאפשר גישה לעוזרת AI חכמה"
  │     ├── enabled: true
  │     ├── rolloutPercentage: 100
  │     ├── updatedAt: Timestamp
  │     └── updatedBy: "admin@example.com"
  ├── enable_marketplace (document)
  │     └── ...
  └── ...
```

## Migration from Legacy System

The new system works alongside the legacy AppState feature flags:

```dart
// Legacy way (still works)
final appState = context.read<AppState>();
if (appState.isFeatureEnabled('aiChat')) {
  // Show feature
}

// New way
final service = context.read<FeatureFlagService>();
if (service.isEnabled(FeatureFlagIds.enableAiChat)) {
  // Show feature
}

// Combined check (recommended during transition)
bool isEnabled(String feature) {
  final appState = context.read<AppState>();
  final service = context.read<FeatureFlagService>();
  final flagId = _mapLegacyFeatureToFlagId(feature);
  return appState.isFeatureEnabled(feature) || 
         (flagId != null && service.isEnabled(flagId));
}
```

## Best Practices

1. **Use the service in initState** for one-time checks
2. **Use Consumer/StreamBuilder** for reactive UI updates
3. **Cache results** when checking multiple times
4. **Provide fallbacks** for disabled features
5. **Log feature usage** for analytics
6. **Test with rollout percentages** before full release

## Testing

```dart
// Test with feature flag service
void main() {
  testWidgets('Feature flag guards work', (tester) async {
    final service = FeatureFlagService();
    await service.initialize();
    
    // Mock flag state
    service.flags[FeatureFlagIds.enableAiChat] = 
      FeatureFlagIds.defaults[FeatureFlagIds.enableAiChat]!.copyWith(
        enabled: true,
      );
    
    await tester.pumpWidget(
      Provider<FeatureFlagService>.value(
        value: service,
        child: MyApp(),
      ),
    );
    
    // Test UI based on flag
    expect(find.text('AI Chat'), findsOneWidget);
  });
}
```

## Troubleshooting

### Feature not showing
1. Check Firestore for the flag document
2. Verify `enabled: true`
3. Check rollout percentage
4. Clear app cache and restart

### Real-time updates not working
1. Ensure `enableRealtimeUpdates()` was called
2. Check Firestore security rules
3. Verify network connection

### Cache issues
```dart
// Clear cache
await FeatureFlagService.instance.clearCache();
```
