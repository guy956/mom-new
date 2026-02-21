import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mom_connect/main.dart';
import 'package:mom_connect/services/app_state.dart';
import 'package:mom_connect/services/accessibility_service.dart';
import 'package:mom_connect/core/constants/app_colors.dart';
import 'package:mom_connect/core/constants/app_strings.dart';
import 'package:mom_connect/core/widgets/common_widgets.dart';
import 'package:mom_connect/models/user_model.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('App loads correctly with providers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppState()),
            ChangeNotifierProvider(create: (_) => AccessibilityService()),
          ],
          child: const MomitApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the app loads with MOMIT text
      expect(find.text('MOMIT'), findsWidgets);
    });

    testWidgets('App has RTL directionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppState()),
            ChangeNotifierProvider(create: (_) => AccessibilityService()),
          ],
          child: const MomitApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Hebrew locale is set (RTL)
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale?.languageCode, 'he');
    });
  });

  group('AppColors Tests', () {
    test('Primary color is correct', () {
      expect(AppColors.primary, const Color(0xFFD4A1AC));
    });

    test('Background color is warm ivory', () {
      expect(AppColors.background, const Color(0xFFFCFAF9));
    });

    test('Text primary has high contrast', () {
      expect(AppColors.textPrimary, const Color(0xFF140F11));
    });

    test('Dark theme colors are defined', () {
      expect(AppColors.darkBackground, isNotNull);
      expect(AppColors.darkSurface, isNotNull);
      expect(AppColors.darkTextPrimary, isNotNull);
    });

    test('Gradients are defined', () {
      expect(AppColors.primaryGradient.colors.length, 2);
      expect(AppColors.momGradient.colors.length, 2);
      expect(AppColors.splashGradient.colors.length, 3);
    });
  });

  group('AppStrings Tests', () {
    test('App name is MOMIT', () {
      expect(AppStrings.appName, 'MOMIT');
    });

    test('All Hebrew strings are non-empty', () {
      expect(AppStrings.slogan.isNotEmpty, true);
      expect(AppStrings.welcomeTitle.isNotEmpty, true);
      expect(AppStrings.loginTitle.isNotEmpty, true);
      expect(AppStrings.registerTitle.isNotEmpty, true);
    });

    test('Error messages are defined', () {
      expect(AppStrings.errorGeneral.isNotEmpty, true);
      expect(AppStrings.errorNetwork.isNotEmpty, true);
      expect(AppStrings.errorInvalidEmail.isNotEmpty, true);
      expect(AppStrings.errorInvalidPassword.isNotEmpty, true);
    });
  });

  group('UserModel Tests', () {
    test('Demo user is created correctly', () {
      final user = UserModel.demo();
      expect(user.email, 'demo@example.com');
      expect(user.fullName, 'שרה כהן');
      expect(user.city, 'תל אביב');
      expect(user.children.length, 2);
      expect(user.isVerified, true);
    });

    test('UserModel serialization roundtrip', () {
      final user = UserModel.demo();
      final json = user.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, user.id);
      expect(restored.email, user.email);
      expect(restored.fullName, user.fullName);
      expect(restored.city, user.city);
      expect(restored.children.length, user.children.length);
    });

    test('UserModel copyWith works', () {
      final user = UserModel.demo();
      final updated = user.copyWith(fullName: 'רחל לוי', city: 'ירושלים');

      expect(updated.fullName, 'רחל לוי');
      expect(updated.city, 'ירושלים');
      expect(updated.email, user.email); // unchanged
    });

    test('ChildModel age calculation works', () {
      final child = ChildModel(
        id: 'test',
        name: 'תינוק',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        gender: Gender.male,
      );
      expect(child.ageInMonths, greaterThanOrEqualTo(1));
      expect(child.formattedAge.isNotEmpty, true);
    });

    test('ChildModel serialization roundtrip', () {
      final child = ChildModel.demo();
      final json = child.toJson();
      final restored = ChildModel.fromJson(json);

      expect(restored.id, child.id);
      expect(restored.name, child.name);
      expect(restored.gender, child.gender);
    });

    test('Gender extension works', () {
      expect(Gender.male.displayName, 'זכר');
      expect(Gender.female.displayName, 'נקבה');
      expect(Gender.unknown.displayName, 'לא צוין');
      expect(Gender.male.emoji, '👦');
      expect(Gender.female.emoji, '👧');
    });

    test('PrivacySettings defaults are sensible', () {
      final privacy = PrivacySettings();
      expect(privacy.profileVisibility, 'public');
      expect(privacy.childrenVisibility, 'private');
      expect(privacy.allowMessages, true);
    });

    test('UserStats defaults to zero', () {
      final stats = UserStats();
      expect(stats.postsCount, 0);
      expect(stats.rating, 0.0);
      expect(stats.followersCount, 0);
    });
  });

  group('Common Widgets Tests', () {
    testWidgets('PrimaryButton renders correctly', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'התחברי',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('התחברי'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, true);
    });

    testWidgets('PrimaryButton shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'טוען',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('טוען'), findsNothing);
    });

    testWidgets('SecondaryButton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              text: 'ביטול',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('ביטול'), findsOneWidget);
    });

    testWidgets('EmptyState shows all elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'אין פוסטים',
              subtitle: 'התחילי לשתף',
              buttonText: 'צרי פוסט',
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('אין פוסטים'), findsOneWidget);
      expect(find.text('התחילי לשתף'), findsOneWidget);
      expect(find.text('צרי פוסט'), findsOneWidget);
    });

    testWidgets('ProfileAvatar shows initials when no image', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(name: 'שרה כהן'),
          ),
        ),
      );

      expect(find.text('שכ'), findsOneWidget);
    });

    testWidgets('NotificationBadge shows count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 5,
              child: const Icon(Icons.notifications),
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('NotificationBadge shows 99+ for large counts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 150,
              child: const Icon(Icons.notifications),
            ),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('CategoryChip renders selected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'שאלות',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('שאלות'), findsOneWidget);
    });

    testWidgets('LoadingIndicator shows message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'טוען...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('טוען...'), findsOneWidget);
    });

    testWidgets('StatCard renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              value: '42',
              label: 'פוסטים',
              icon: Icons.article,
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text('פוסטים'), findsOneWidget);
    });

    testWidgets('ColorTag renders filled and outlined', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ColorTag(text: 'חדש', color: Colors.green, filled: true),
                ColorTag(text: 'מקוון', color: Colors.blue, filled: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('חדש'), findsOneWidget);
      expect(find.text('מקוון'), findsOneWidget);
    });
  });

  group('AppState Tests', () {
    test('Initial state is correct', () {
      final state = AppState();
      expect(state.isLoggedIn, false);
      expect(state.currentUser, null);
      expect(state.themeMode, ThemeMode.light);
      expect(state.notificationCount, 0);
      expect(state.messageCount, 0);
    });

    test('Theme toggle works', () {
      final state = AppState();
      expect(state.themeMode, ThemeMode.light);

      state.toggleTheme();
      expect(state.themeMode, ThemeMode.dark);

      state.toggleTheme();
      expect(state.themeMode, ThemeMode.light);
    });

    test('Login creates user', () {
      final state = AppState();
      state.loginUser('test@test.com', 'שרה');

      expect(state.isLoggedIn, true);
      expect(state.currentUser?.email, 'test@test.com');
      expect(state.currentUser?.fullName, 'שרה');
    });

    test('Logout clears state', () {
      final state = AppState();
      state.loginUser('test@test.com', 'שרה');
      state.setNotificationCount(5);
      state.setMessageCount(3);

      state.logout();

      expect(state.isLoggedIn, false);
      expect(state.notificationCount, 0);
      expect(state.messageCount, 0);
    });

    test('Notification count updates', () {
      final state = AppState();
      state.setNotificationCount(10);
      expect(state.notificationCount, 10);

      state.decrementNotificationCount();
      expect(state.notificationCount, 9);
    });

    test('Update user profile', () {
      final state = AppState();
      state.loginUser('test@test.com', 'שרה');

      state.updateUserProfile(fullName: 'שרה כהן', city: 'חיפה');

      expect(state.currentUser?.fullName, 'שרה כהן');
      expect(state.currentUser?.city, 'חיפה');
    });
  });

  group('AccessibilityService Tests', () {
    test('Default values are sensible', () {
      final service = AccessibilityService();
      expect(service.fontScale, 1.0);
      expect(service.highContrast, false);
      expect(service.reduceMotion, false);
      expect(service.largeTouch, false);
      expect(service.boldText, false);
      expect(service.colorBlindMode, 'none');
    });

    test('Min touch target returns correct size', () {
      final service = AccessibilityService();
      expect(service.minTouchTarget, 44.0);
    });

    test('Font weight adjustments work', () {
      final service = AccessibilityService();
      expect(service.normalWeight, FontWeight.w400);
      expect(service.boldWeight, FontWeight.w700);
    });
  });
}
