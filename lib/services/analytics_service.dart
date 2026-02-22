import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/constants/firestore_collections.dart';

/// Analytics data models
class AnalyticsMetrics {
  final int totalUsers;
  final int activeUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final double userGrowthRate;
  final Map<String, int> userGrowthByDay;
  final Map<String, int> userGrowthByWeek;
  final Map<String, int> userGrowthByMonth;
  final int activeUsersNow;
  final double avgSessionDuration;
  final int totalSessions;
  final Map<String, int> featureUsage;
  final Map<String, int> contentEngagement;
  final double engagementRate;
  final Map<String, double> revenueData;
  final DateTime timestamp;

  AnalyticsMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.userGrowthRate,
    required this.userGrowthByDay,
    required this.userGrowthByWeek,
    required this.userGrowthByMonth,
    required this.activeUsersNow,
    required this.avgSessionDuration,
    required this.totalSessions,
    required this.featureUsage,
    required this.contentEngagement,
    required this.engagementRate,
    required this.revenueData,
    required this.timestamp,
  });

  factory AnalyticsMetrics.empty() => AnalyticsMetrics(
    totalUsers: 0,
    activeUsers: 0,
    newUsersToday: 0,
    newUsersThisWeek: 0,
    newUsersThisMonth: 0,
    userGrowthRate: 0.0,
    userGrowthByDay: {},
    userGrowthByWeek: {},
    userGrowthByMonth: {},
    activeUsersNow: 0,
    avgSessionDuration: 0.0,
    totalSessions: 0,
    featureUsage: {},
    contentEngagement: {},
    engagementRate: 0.0,
    revenueData: {},
    timestamp: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'totalUsers': totalUsers,
    'activeUsers': activeUsers,
    'newUsersToday': newUsersToday,
    'newUsersThisWeek': newUsersThisWeek,
    'newUsersThisMonth': newUsersThisMonth,
    'userGrowthRate': userGrowthRate,
    'userGrowthByDay': userGrowthByDay,
    'userGrowthByWeek': userGrowthByWeek,
    'userGrowthByMonth': userGrowthByMonth,
    'activeUsersNow': activeUsersNow,
    'avgSessionDuration': avgSessionDuration,
    'totalSessions': totalSessions,
    'featureUsage': featureUsage,
    'contentEngagement': contentEngagement,
    'engagementRate': engagementRate,
    'revenueData': revenueData,
    'timestamp': timestamp.toIso8601String(),
  };
}

class UserAction {
  final String id;
  final String userId;
  final String action;
  final String? feature;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? sessionId;

  UserAction({
    required this.id,
    required this.userId,
    required this.action,
    this.feature,
    this.metadata,
    required this.timestamp,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'action': action,
    'feature': feature,
    'metadata': metadata,
    'timestamp': timestamp,
    'sessionId': sessionId,
  };

  factory UserAction.fromJson(Map<String, dynamic> json) => UserAction(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    action: json['action'] ?? '',
    feature: json['feature'],
    metadata: json['metadata'],
    timestamp: json['timestamp'] is DateTime 
      ? json['timestamp'] 
      : (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    sessionId: json['sessionId'],
  );
}

class TimeRange {
  final DateTime start;
  final DateTime end;
  final String label;

  TimeRange({required this.start, required this.end, required this.label});

  factory TimeRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return TimeRange(start: start, end: now, label: 'היום');
  }

  factory TimeRange.thisWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday % 7));
    return TimeRange(start: DateTime(start.year, start.month, start.day), end: now, label: 'השבוע');
  }

  factory TimeRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return TimeRange(start: start, end: now, label: 'החודש');
  }

  factory TimeRange.last7Days() {
    final now = DateTime.now();
    return TimeRange(start: now.subtract(const Duration(days: 7)), end: now, label: '7 ימים');
  }

  factory TimeRange.last30Days() {
    final now = DateTime.now();
    return TimeRange(start: now.subtract(const Duration(days: 30)), end: now, label: '30 יום');
  }

  factory TimeRange.last90Days() {
    final now = DateTime.now();
    return TimeRange(start: now.subtract(const Duration(days: 90)), end: now, label: '90 יום');
  }

  factory TimeRange.thisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    return TimeRange(start: start, end: now, label: 'השנה');
  }

  factory TimeRange.custom(DateTime start, DateTime end) {
    return TimeRange(
      start: start,
      end: end,
      label: '${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM').format(end)}',
    );
  }

  static List<TimeRange> get presets => [
    TimeRange.today(),
    TimeRange.thisWeek(),
    TimeRange.thisMonth(),
    TimeRange.last7Days(),
    TimeRange.last30Days(),
    TimeRange.last90Days(),
    TimeRange.thisYear(),
  ];
}

/// Comprehensive Analytics Service for MOMIT
/// Handles tracking, aggregation, and real-time analytics updates
class AnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Streams
  StreamSubscription? _metricsSubscription;
  StreamSubscription? _activeUsersSubscription;
  
  // Current metrics
  AnalyticsMetrics _currentMetrics = AnalyticsMetrics.empty();
  int _activeUsersNow = 0;
  
  // Cache
  final Map<String, dynamic> _cache = {};
  DateTime? _lastCacheUpdate;
  
  // Getters
  AnalyticsMetrics get currentMetrics => _currentMetrics;
  int get activeUsersNow => _activeUsersNow;
  
  // Feature names mapping
  static const Map<String, String> featureNames = {
    'chat': 'צ׳אט',
    'posts': 'פוסטים',
    'events': 'אירועים',
    'marketplace': 'מסירות',
    'experts': 'מומחים',
    'tips': 'טיפים',
    'profile': 'פרופיל',
    'search': 'חיפוש',
    'notifications': 'התראות',
    'gamification': 'משחק',
  };

  // Action types
  static const String actionView = 'view';
  static const String actionClick = 'click';
  static const String actionCreate = 'create';
  static const String actionLike = 'like';
  static const String actionComment = 'comment';
  static const String actionShare = 'share';
  static const String actionPurchase = 'purchase';
  static const String actionLogin = 'login';
  static const String actionRegister = 'register';

  AnalyticsService() {
    _initRealTimeListeners();
  }

  void _initRealTimeListeners() {
    // Listen to analytics metrics document
    _metricsSubscription = _db
      .collection(FirestoreCollections.analytics)
      .doc('metrics')
      .snapshots()
      .listen(_onMetricsUpdate);
    
    // Listen to active users
    _activeUsersSubscription = _db
      .collection(FirestoreCollections.users)
      .where('lastActive', isGreaterThan: Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 5))
      ))
      .snapshots()
      .listen(_onActiveUsersUpdate);
  }

  void _onMetricsUpdate(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      _currentMetrics = _parseMetrics(snapshot.data()!);
      notifyListeners();
    }
  }

  void _onActiveUsersUpdate(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _activeUsersNow = snapshot.docs.length;
    notifyListeners();
  }

  AnalyticsMetrics _parseMetrics(Map<String, dynamic> data) {
    return AnalyticsMetrics(
      totalUsers: data['totalUsers'] ?? 0,
      activeUsers: data['activeUsers'] ?? 0,
      newUsersToday: data['newUsersToday'] ?? 0,
      newUsersThisWeek: data['newUsersThisWeek'] ?? 0,
      newUsersThisMonth: data['newUsersThisMonth'] ?? 0,
      userGrowthRate: (data['userGrowthRate'] ?? 0.0).toDouble(),
      userGrowthByDay: (data['userGrowthByDay'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      userGrowthByWeek: (data['userGrowthByWeek'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      userGrowthByMonth: (data['userGrowthByMonth'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      activeUsersNow: _activeUsersNow,
      avgSessionDuration: (data['avgSessionDuration'] ?? 0.0).toDouble(),
      totalSessions: data['totalSessions'] ?? 0,
      featureUsage: (data['featureUsage'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      contentEngagement: (data['contentEngagement'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      engagementRate: (data['engagementRate'] ?? 0.0).toDouble(),
      revenueData: Map<String, double>.from(
        (data['revenueData'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble()))
      ),
      timestamp: data['timestamp'] is Timestamp 
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // USER ACTION TRACKING
  // ════════════════════════════════════════════════════════════════

  /// Track a user action/event
  Future<void> trackAction({
    required String userId,
    required String action,
    String? feature,
    Map<String, dynamic>? metadata,
    String? sessionId,
  }) async {
    try {
      final actionData = {
        'userId': userId,
        'action': action,
        'feature': feature,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': sessionId ?? _generateSessionId(),
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'hour': DateTime.now().hour,
      };

      // Add to user actions subcollection
      await _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection('actions')
        .add(actionData);

      // Add to global analytics events
      await _db.collection('analytics_events').add(actionData);

      // Update feature usage counter
      if (feature != null) {
        await _incrementFeatureUsage(feature);
      }

    } catch (e) {
      debugPrint('Error tracking action: $e');
    }
  }

  /// Track page/view
  Future<void> trackView({
    required String userId,
    required String page,
    Map<String, dynamic>? metadata,
  }) async {
    await trackAction(
      userId: userId,
      action: actionView,
      feature: page,
      metadata: metadata,
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsage({
    required String userId,
    required String feature,
    String? action,
  }) async {
    await trackAction(
      userId: userId,
      action: action ?? actionClick,
      feature: feature,
    );
  }

  Future<void> _incrementFeatureUsage(String feature) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    await _db
      .collection(FirestoreCollections.analytics)
      .doc('feature_usage')
      .collection('daily')
      .doc(today)
      .set({
        feature: FieldValue.increment(1),
        'date': today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
  }

  // ════════════════════════════════════════════════════════════════
  // STATISTICS AGGREGATION
  // ════════════════════════════════════════════════════════════════

  /// Get user growth data for a date range
  Future<Map<String, int>> getUserGrowth(TimeRange range, {String granularity = 'day'}) async {
    final result = <String, int>{};
    
    try {
      final snapshot = await _db
        .collection(FirestoreCollections.users)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;

        String key;
        switch (granularity) {
          case 'week':
            final weekStart = createdAt.subtract(Duration(days: createdAt.weekday % 7));
            key = DateFormat('yyyy-MM-dd').format(weekStart);
            break;
          case 'month':
            key = DateFormat('yyyy-MM').format(createdAt);
            break;
          case 'day':
          default:
            key = DateFormat('yyyy-MM-dd').format(createdAt);
        }

        result[key] = (result[key] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('Error getting user growth: $e');
    }

    return result;
  }

  /// Get feature usage statistics
  Future<Map<String, int>> getFeatureUsage(TimeRange range) async {
    final result = <String, int>{};
    
    try {
      final snapshot = await _db
        .collection(FirestoreCollections.analytics)
        .doc('feature_usage')
        .collection('daily')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: 
          DateFormat('yyyy-MM-dd').format(range.start))
        .where(FieldPath.documentId, isLessThanOrEqualTo: 
          DateFormat('yyyy-MM-dd').format(range.end))
        .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        for (final entry in data.entries) {
          if (entry.key != 'date' && entry.key != 'updatedAt') {
            result[entry.key] = (result[entry.key] ?? 0) + (entry.value as num).toInt();
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting feature usage: $e');
    }

    // Ensure all features are represented
    for (final feature in featureNames.keys) {
      result.putIfAbsent(feature, () => 0);
    }

    return result;
  }

  /// Get content engagement stats
  Future<Map<String, dynamic>> getContentEngagement(TimeRange range) async {
    final result = {
      'posts': {'created': 0, 'likes': 0, 'comments': 0},
      'events': {'created': 0, 'rsvps': 0},
      'marketplace': {'created': 0, 'sold': 0},
      'tips': {'views': 0, 'saves': 0},
    };

    try {
      // Posts stats
      final postsSnapshot = await _db
        .collection(FirestoreCollections.posts)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .get();
      
      result['posts']!['created'] = postsSnapshot.docs.length;
      
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        result['posts']!['likes'] = (result['posts']!['likes'] as int) + 
          ((data['likesCount'] ?? 0) as num).toInt();
        result['posts']!['comments'] = (result['posts']!['comments'] as int) + 
          ((data['commentsCount'] ?? 0) as num).toInt();
      }

      // Events stats
      final eventsSnapshot = await _db
        .collection(FirestoreCollections.events)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .get();
      
      result['events']!['created'] = eventsSnapshot.docs.length;

      // Marketplace stats
      final marketplaceSnapshot = await _db
        .collection(FirestoreCollections.marketplace)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .get();
      
      result['marketplace']!['created'] = marketplaceSnapshot.docs.length;
      result['marketplace']!['sold'] = marketplaceSnapshot.docs
        .where((d) => d.data()['status'] == 'sold').length;

    } catch (e) {
      debugPrint('Error getting content engagement: $e');
    }

    return result;
  }

  /// Get revenue statistics (if applicable)
  Future<Map<String, double>> getRevenueStats(TimeRange range) async {
    final result = <String, double>{
      'total': 0.0,
      'marketplace': 0.0,
      'events': 0.0,
      'premium': 0.0,
    };

    try {
      // This is a placeholder - implement based on your actual revenue tracking
      // Could be from a 'transactions' or 'orders' collection
      final snapshot = await _db
        .collection('transactions')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .where('status', isEqualTo: 'completed')
        .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final type = data['type'] ?? 'other';
        
        result['total'] = (result['total'] ?? 0.0) + amount;

        if (result.containsKey(type)) {
          result[type] = (result[type] ?? 0.0) + amount;
        }
      }
    } catch (e) {
      debugPrint('Error getting revenue stats: $e');
    }

    return result;
  }

  // ════════════════════════════════════════════════════════════════
  // REAL-TIME STREAMS
  // ════════════════════════════════════════════════════════════════

  /// Stream of analytics metrics
  Stream<AnalyticsMetrics> get metricsStream => _db
    .collection(FirestoreCollections.analytics)
    .doc('metrics')
    .snapshots()
    .map((snap) => snap.exists && snap.data() != null 
      ? _parseMetrics(snap.data()!) 
      : AnalyticsMetrics.empty());

  /// Stream of active users count (updated every minute)
  Stream<int> get activeUsersNowStream => _db
    .collection(FirestoreCollections.users)
    .where('lastActive', isGreaterThan: Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 5))
    ))
    .snapshots()
    .map((snap) => snap.docs.length);

  /// Stream of today's new users
  Stream<int> get newUsersTodayStream {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _db
      .collection(FirestoreCollections.users)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .snapshots()
      .map((snap) => snap.docs.length);
  }

  /// Stream of recent user actions
  Stream<List<UserAction>> getRecentActions({int limit = 50}) {
    return _db
      .collection('analytics_events')
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs
        .map((d) => UserAction.fromJson({'id': d.id, ...d.data()}))
        .toList());
  }

  // ════════════════════════════════════════════════════════════════
  // EXPORT FUNCTIONALITY
  // ════════════════════════════════════════════════════════════════

  /// Sanitize a value for CSV to prevent formula injection
  String _csvSafe(dynamic value) {
    final s = (value ?? '').toString();
    if (s.isEmpty) return '';
    // Prefix cells starting with formula characters to prevent CSV injection
    if (s.startsWith('=') || s.startsWith('+') || s.startsWith('-') || s.startsWith('@') || s.startsWith('\t') || s.startsWith('\r')) {
      return "'$s";
    }
    return s;
  }

  /// Export data to CSV format
  Future<String> exportToCsv({
    required String dataType,
    required TimeRange range,
  }) async {
    final buffer = StringBuffer();
    
    switch (dataType) {
      case 'users':
        buffer.writeln('ID,Email,Full Name,Status,Created At,Last Active');
        
        final snapshot = await _db
          .collection(FirestoreCollections.users)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .get();
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          buffer.writeln(
            '${_csvSafe(doc.id)},'
            '"${_csvSafe(data['email'])}",'
            '"${_csvSafe(data['fullName'])}",'
            '${_csvSafe(data['status'] ?? 'active')},'
            '${_formatDate(data['createdAt'])},'
            '${_formatDate(data['lastActive'])}'
          );
        }
        break;

      case 'activity':
        buffer.writeln('User ID,Action,Feature,Timestamp,Metadata');

        final snapshot = await _db
          .collection('analytics_events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .orderBy('timestamp', descending: true)
          .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          buffer.writeln(
            '${_csvSafe(data['userId'])},'
            '${_csvSafe(data['action'])},'
            '${_csvSafe(data['feature'])},'
            '${_formatDate(data['timestamp'])},'
            '"${_csvSafe(jsonEncode(data['metadata'] ?? {}))}"'
          );
        }
        break;

      case 'analytics':
        buffer.writeln('Date,New Users,Active Users,Feature Usage,Engagement Rate');
        
        final userGrowth = await getUserGrowth(range);
        
        for (final entry in userGrowth.entries.toList()..sort()) {
          buffer.writeln('${entry.key},${entry.value},,,,');
        }
        break;

      default:
        throw ArgumentError('Unknown data type: $dataType');
    }

    return buffer.toString();
  }

  /// Generate summary report data for PDF export
  Future<Map<String, dynamic>> generateReportData(TimeRange range) async {
    final userGrowth = await getUserGrowth(range);
    final featureUsage = await getFeatureUsage(range);
    final engagement = await getContentEngagement(range);
    final revenue = await getRevenueStats(range);

    final totalNewUsers = userGrowth.values.fold(0, (a, b) => a + b);
    
    return {
      'range': {
        'start': range.start.toIso8601String(),
        'end': range.end.toIso8601String(),
        'label': range.label,
      },
      'summary': {
        'totalNewUsers': totalNewUsers,
        'totalActiveUsers': _currentMetrics.activeUsers,
        'avgDailyGrowth': userGrowth.isEmpty ? 0 : totalNewUsers / userGrowth.length,
        'totalRevenue': revenue['total'],
        'engagementRate': _currentMetrics.engagementRate,
      },
      'userGrowth': userGrowth,
      'featureUsage': featureUsage,
      'contentEngagement': engagement,
      'revenue': revenue,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  // ════════════════════════════════════════════════════════════════
  // AGGREGATION JOBS (for background/cloud functions)
  // ════════════════════════════════════════════════════════════════

  /// Aggregate daily analytics (should be called by cloud function)
  Future<void> aggregateDailyAnalytics(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // Count new users
      final newUsersSnapshot = await _db
        .collection(FirestoreCollections.users)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .count()
        .get();

      // Count active users (logged in that day)
      final activeUsersSnapshot = await _db
        .collection(FirestoreCollections.users)
        .where('lastLogin', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('lastLogin', isLessThan: Timestamp.fromDate(endOfDay))
        .count()
        .get();

      // Store aggregated data
      await _db
        .collection(FirestoreCollections.analytics)
        .doc('daily')
        .collection('stats')
        .doc(dateStr)
        .set({
          'date': dateStr,
          'newUsers': newUsersSnapshot.count,
          'activeUsers': activeUsersSnapshot.count,
          'aggregatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('Error aggregating daily analytics: $e');
    }
  }

  /// Update real-time metrics document
  Future<void> updateRealtimeMetrics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month, 1);

      // Get counts
      final totalUsers = await _getCount(FirestoreCollections.users);
      final newUsersToday = await _getCountSince(FirestoreCollections.users, today);
      final newUsersThisWeek = await _getCountSince(FirestoreCollections.users, weekAgo);
      final newUsersThisMonth = await _getCountSince(FirestoreCollections.users, monthAgo);

      // Calculate growth rate
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final newUsersLastMonth = await _getCountRange(
        FirestoreCollections.users, 
        lastMonth, 
        monthAgo
      );
      
      final growthRate = newUsersLastMonth > 0 
        ? ((newUsersThisMonth - newUsersLastMonth) / newUsersLastMonth) * 100 
        : 0.0;

      await _db.collection(FirestoreCollections.analytics).doc('metrics').set({
        'totalUsers': totalUsers,
        'newUsersToday': newUsersToday,
        'newUsersThisWeek': newUsersThisWeek,
        'newUsersThisMonth': newUsersThisMonth,
        'userGrowthRate': growthRate,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('Error updating realtime metrics: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════

  Future<int> _getCount(String collection) async {
    final snapshot = await _db.collection(collection).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getCountSince(String collection, DateTime since) async {
    final snapshot = await _db
      .collection(collection)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .count()
      .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getCountRange(String collection, DateTime start, DateTime end) async {
    final snapshot = await _db
      .collection(collection)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('createdAt', isLessThan: Timestamp.fromDate(end))
      .count()
      .get();
    return snapshot.count ?? 0;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString()}';
  }

  @override
  void dispose() {
    _metricsSubscription?.cancel();
    _activeUsersSubscription?.cancel();
    super.dispose();
  }
}
