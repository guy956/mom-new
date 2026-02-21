# UI/UX Widgets Usage Guide

## Importing

```dart
// Import specific widget files as needed
import 'package:mom_connect/core/widgets/loading_widgets.dart';
import 'package:mom_connect/core/widgets/empty_state_widgets.dart';
import 'package:mom_connect/core/widgets/dialog_widgets.dart';
import 'package:mom_connect/core/widgets/button_widgets.dart';

// Or import all at once via common_widgets
import 'package:mom_connect/core/widgets/common_widgets.dart';
```

## Loading Widgets

### ShimmerCard
Use for feed/post loading states:
```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const ShimmerCard(itemCount: 4);
}
```

### ShimmerList
Use for list loading states:
```dart
if (isLoading) {
  return const ShimmerList(itemCount: 5, hasAvatar: true);
}
```

### ShimmerGrid
Use for grid loading states:
```dart
if (isLoading) {
  return const ShimmerGrid(crossAxisCount: 2, itemCount: 4);
}
```

## Empty State Widgets

### EnhancedEmptyState
Basic usage:
```dart
EnhancedEmptyState(
  icon: Icons.inbox_outlined,
  title: 'אין פריטים',
  subtitle: 'התחלי ביצירת פריט חדש',
  buttonText: 'צרי חדש',
  onButtonPressed: () => _createNew(),
  iconColor: AppColors.primary,
)
```

### Factory Constructors
Use pre-built empty states:
```dart
// Search results
EnhancedEmptyState.search(
  query: _searchQuery,
  onClearSearch: () => _clearSearch(),
)

// Messages
EnhancedEmptyState.messages(
  onStartChat: () => _startChat(),
)

// Events
EnhancedEmptyState.events(
  onCreateEvent: () => _createEvent(),
)

// Posts
EnhancedEmptyState.posts(
  onCreatePost: () => _createPost(),
)

// Error state
EnhancedEmptyState.error(
  message: 'שגיאה בטעינת הנתונים',
  onRetry: () => _loadData(),
)

// No internet
EnhancedEmptyState.noInternet(
  onRetry: () => _loadData(),
)
```

## Dialogs

### Error Dialog
```dart
await context.showErrorDialog(
  title: 'שגיאה',
  message: 'לא ניתן לטעון את הנתונים',
  showRetry: true,
  onRetry: () => _loadData(),
);
```

### Success Dialog
```dart
await context.showSuccessDialog(
  title: 'הצלחה!',
  message: 'הפרטים נשמרו בהצלחה',
  actionText: 'אוקי',
);
```

### Confirmation Dialog
```dart
final confirmed = await context.showConfirmDialog(
  title: 'מחיקת פריט',
  message: 'האם את בטוחה שברצונך למחוק?',
  confirmText: 'מחקי',
  cancelText: 'ביטול',
  icon: Icons.delete_outline,
  isDestructive: true,
);

if (confirmed) {
  // Perform deletion
}
```

### Pre-built Confirmations
```dart
// Delete confirmation
final confirmed = await context.showDeleteConfirm(itemName: 'פוסט');

// Logout confirmation
final confirmed = await context.showLogoutConfirm();
```

## Snackbars

### Basic Usage
```dart
AppSnackbar.success(context, 'הפעולה הושלמה בהצלחה!');
AppSnackbar.error(context, 'אירעה שגיאה, נסי שוב');
AppSnackbar.warning(context, 'שימי לב לפרטים');
AppSnackbar.info(context, 'עדכון חדש זמין');
```

### With Action
```dart
AppSnackbar.success(
  context,
  'הפריט נמחק',
  actionLabel: 'ביטול',
  onAction: () => _undoDelete(),
);
```

## Buttons

### AppButton
Primary button:
```dart
AppButton(
  text: 'שמירה',
  onPressed: () => _save(),
)
```

Secondary button:
```dart
AppButton.secondary(
  text: 'ביטול',
  onPressed: () => Navigator.pop(context),
)
```

Text button:
```dart
AppButton.text(
  text: 'דלגי',
  onPressed: () => _skip(),
)
```

Danger button:
```dart
AppButton.danger(
  text: 'מחיקה',
  onPressed: () => _delete(),
)
```

With loading state:
```dart
AppButton(
  text: 'שמירה',
  onPressed: _isLoading ? null : () => _save(),
  isLoading: _isLoading,
)
```

With icon:
```dart
AppButton(
  text: 'הוספה',
  icon: Icons.add,
  onPressed: () => _add(),
)
```

### AppIconButton
```dart
AppIconButton(
  icon: Icons.favorite,
  onPressed: () => _toggleFavorite(),
  tooltip: 'הוספה למועדפים',
  semanticLabel: 'כפתור מועדפים',
)
```

With loading:
```dart
AppIconButton(
  icon: Icons.refresh,
  onPressed: _isRefreshing ? null : () => _refresh(),
  isLoading: _isRefreshing,
)
```

### AppFAB
```dart
AppFAB(
  onPressed: () => _createNew(),
  tooltip: 'צרי חדש',
)
```

Extended FAB:
```dart
AppFAB(
  isExtended: true,
  label: 'פוסט חדש',
  icon: Icons.add,
  onPressed: () => _createPost(),
)
```

## Pull-to-Refresh

### Basic Implementation
```dart
RefreshIndicator(
  onRefresh: () async {
    await _loadData();
    AppSnackbar.success(context, 'הרשימה עודכנה');
  },
  color: AppColors.primary,
  child: ListView(...),
)
```

### With StreamBuilder
```dart
RefreshIndicator(
  onRefresh: () async {
    setState(() {}); // Trigger stream rebuild
    await Future.delayed(const Duration(milliseconds: 500));
  },
  color: AppColors.primary,
  child: StreamBuilder(
    stream: _dataStream,
    builder: (context, snapshot) {
      // Build your UI
    },
  ),
)
```

## Best Practices

1. **Always use semantic labels** for accessibility:
   ```dart
   AppButton(
     text: 'שמירה',
     semanticLabel: 'כפתור שמירת פרופיל',
     onPressed: () => _save(),
   )
   ```

2. **Show loading states** for async operations:
   ```dart
   AppButton(
     text: 'שמירה',
     isLoading: _isSaving,
     onPressed: _isSaving ? null : () => _save(),
   )
   ```

3. **Use factory constructors** for common empty states instead of building from scratch.

4. **Always provide retry functionality** for error states.

5. **Use haptic feedback** consistently - all new buttons already include it.

6. **Follow RTL guidelines** - all widgets are already RTL-aware.

7. **Keep consistent spacing** - use the standard 16px padding.
