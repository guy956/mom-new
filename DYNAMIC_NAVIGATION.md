# Dynamic Bottom Navigation

The bottom navigation is now fully dynamic and controlled via Firestore.

## Firestore Structure

### Collection: `app_config`

Document ID: `main`

```json
{
  "appName": "MOMIT",
  "slogan": "כי רק אמא מבינה אמא",
  "navigationItems": [
    {
      "key": "feed",
      "label": "Home",
      "labelHe": "בית",
      "iconName": "home_outlined",
      "activeIconName": "home_rounded",
      "route": "/feed",
      "isVisible": true
    },
    {
      "key": "tracking",
      "label": "Tracking",
      "labelHe": "מעקב",
      "iconName": "child_care_outlined",
      "activeIconName": "child_care",
      "route": "/tracking",
      "isVisible": true
    },
    {
      "key": "events",
      "label": "Events",
      "labelHe": "אירועים",
      "iconName": "event_outlined",
      "activeIconName": "event_rounded",
      "route": "/events",
      "isVisible": true
    },
    {
      "key": "chat",
      "label": "Chat",
      "labelHe": "צ'אט",
      "iconName": "chat_bubble_outline",
      "activeIconName": "chat_bubble_rounded",
      "route": "/chat",
      "isVisible": true
    },
    {
      "key": "profile",
      "label": "Profile",
      "labelHe": "פרופיל",
      "iconName": "person_outline_rounded",
      "activeIconName": "person_rounded",
      "route": "/profile",
      "isVisible": true
    }
  ],
  "navigationOrder": ["feed", "tracking", "events", "chat", "profile"],
  "featureVisibility": {
    "chat": true,
    "events": true,
    "marketplace": true,
    "experts": true,
    "tips": true
  },
  "themeSettings": {}
}
```

## Available Screen Keys

The following screen keys are available for navigation:

- `feed` - Feed/Home screen
- `tracking` - Baby tracking screen
- `events` - Events screen
- `chat` - Chat screen
- `profile` - Profile screen
- `home` - Alias for feed

## Available Icons

### Navigation Icons
- `home_outlined` / `home_rounded`
- `child_care_outlined` / `child_care` / `child_care_rounded`
- `event_outlined` / `event_rounded`
- `chat_bubble_outline` / `chat_bubble_rounded`
- `person_outline_rounded` / `person_rounded`
- `chat_outlined` / `chat_rounded`
- `feed_outlined` / `feed_rounded`
- `forum_outlined` / `forum_rounded`
- `groups_outlined` / `groups_rounded`
- `store_outlined` / `store_rounded`
- `shopping_bag_outlined` / `shopping_bag_rounded`
- `settings_outlined` / `settings_rounded`
- `notifications_outlined` / `notifications_rounded`
- `search_outlined` / `search_rounded`

## Admin Operations

### Using DynamicConfigService

```dart
// Get singleton instance
final configService = DynamicConfigService.instance;

// Update navigation items
await configService.updateNavigationItems([
  NavigationItem(
    id: 'nav_0',
    key: 'feed',
    label: 'Home',
    labelHe: 'בית',
    iconName: 'home_outlined',
    activeIconName: 'home_rounded',
    route: '/feed',
    order: 0,
    isVisible: true,
  ),
  // ... more items
]);

// Toggle visibility
await configService.toggleNavigationItemVisibility('chat', false);

// Reorder items
await configService.reorderNavigationItems(['profile', 'chat', 'events', 'tracking', 'feed']);

// Update label
await configService.updateNavigationItemLabel('chat', 'Messages', labelHe: 'הודעות');
```

## How It Works

1. The app listens to the `app_config` document in Firestore via `DynamicConfigService.instance.appConfigStream`
2. When config changes, the bottom navigation automatically updates
3. If no config exists, default items are used
4. Only visible items (`isVisible: true`) are shown
5. Items are sorted by their `order` field
6. The drawer also uses the same navigation items

## Fallback Behavior

If Firestore is unavailable or no config exists, the app uses the default navigation items defined in `NavigationItemDefaults.defaultItems`.
