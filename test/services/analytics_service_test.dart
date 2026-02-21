import 'package:flutter_test/flutter_test.dart';
import 'package:mom_connect/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    tearDown(() {
      analyticsService.dispose();
    });

    test('should create AnalyticsMetrics empty instance', () {
      final metrics = AnalyticsMetrics.empty();
      
      expect(metrics.totalUsers, 0);
      expect(metrics.activeUsers, 0);
      expect(metrics.userGrowthRate, 0.0);
      expect(metrics.userGrowthByDay, isEmpty);
    });

    test('should create TimeRange presets correctly', () {
      final today = TimeRange.today();
      expect(today.label, 'היום');
      
      final thisWeek = TimeRange.thisWeek();
      expect(thisWeek.label, 'השבוע');
      
      final last7Days = TimeRange.last7Days();
      expect(last7Days.label, '7 ימים');
      
      final last30Days = TimeRange.last30Days();
      expect(last30Days.label, '30 יום');
    });

    test('should create custom TimeRange', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      final range = TimeRange.custom(start, end);
      
      expect(range.start, start);
      expect(range.end, end);
      expect(range.label, contains('01/01'));
      expect(range.label, contains('31/01'));
    });

    test('should have all feature names in Hebrew', () {
      expect(AnalyticsService.featureNames['chat'], 'צ׳אט');
      expect(AnalyticsService.featureNames['posts'], 'פוסטים');
      expect(AnalyticsService.featureNames['events'], 'אירועים');
      expect(AnalyticsService.featureNames['marketplace'], 'מסירות');
      expect(AnalyticsService.featureNames['experts'], 'מומחים');
    });

    test('should have action type constants', () {
      expect(AnalyticsService.actionView, 'view');
      expect(AnalyticsService.actionClick, 'click');
      expect(AnalyticsService.actionCreate, 'create');
      expect(AnalyticsService.actionLike, 'like');
      expect(AnalyticsService.actionPurchase, 'purchase');
    });

    test('should create UserAction from JSON', () {
      final json = {
        'id': 'test-id',
        'userId': 'user-123',
        'action': 'view',
        'feature': 'posts',
        'timestamp': DateTime(2024, 1, 15),
        'sessionId': 'session-456',
      };
      
      final action = UserAction.fromJson(json);
      
      expect(action.id, 'test-id');
      expect(action.userId, 'user-123');
      expect(action.action, 'view');
      expect(action.feature, 'posts');
      expect(action.sessionId, 'session-456');
    });
  });

  group('TimeRange presets', () {
    test('presets list should contain all standard ranges', () {
      final presets = TimeRange.presets;
      
      expect(presets.length, 7);
      expect(presets.map((r) => r.label), contains('היום'));
      expect(presets.map((r) => r.label), contains('השבוע'));
      expect(presets.map((r) => r.label), contains('החודש'));
      expect(presets.map((r) => r.label), contains('7 ימים'));
      expect(presets.map((r) => r.label), contains('30 יום'));
      expect(presets.map((r) => r.label), contains('90 יום'));
      expect(presets.map((r) => r.label), contains('השנה'));
    });
  });
}
