import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mom_connect/models/tracking_models.dart';
import 'package:mom_connect/models/user_model.dart';

/// שירות מעקב - ניהול CRUD מלא עם שמירה ב-Hive
class TrackingService extends ChangeNotifier {
  static const String _childrenBoxName = 'tracking_children';
  static const String _recordsBoxName = 'tracking_records';

  List<ChildProfile> _children = [];
  List<TrackingRecord> _records = [];
  bool _isInitialized = false;

  List<ChildProfile> get children => _children;
  List<TrackingRecord> get records => _records;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.openBox<String>(_childrenBoxName);
    await Hive.openBox<String>(_recordsBoxName);
    _loadFromHive();
    if (_children.isEmpty) {
      _seedDemoData();
      _saveAllToHive();
    }
    _isInitialized = true;
    notifyListeners();
  }

  void _loadFromHive() {
    final childrenBox = Hive.box<String>(_childrenBoxName);
    final recordsBox = Hive.box<String>(_recordsBoxName);

    _children = childrenBox.values.map((json) {
      return ChildProfile.fromJson(jsonDecode(json));
    }).toList();

    _records = recordsBox.values.map((json) {
      return TrackingRecord.fromJson(jsonDecode(json));
    }).toList();

    // Sort records newest first
    _records.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  void _saveAllToHive() {
    final childrenBox = Hive.box<String>(_childrenBoxName);
    final recordsBox = Hive.box<String>(_recordsBoxName);

    childrenBox.clear();
    for (final child in _children) {
      childrenBox.put(child.id, jsonEncode(child.toJson()));
    }

    recordsBox.clear();
    for (final record in _records) {
      recordsBox.put(record.id, jsonEncode(record.toJson()));
    }
  }

  // ===== Sync helpers =====
  /// Convert ChildProfile (tracking) to ChildModel (profile)
  ChildModel childProfileToModel(ChildProfile cp) {
    return ChildModel(
      id: cp.id,
      name: cp.name,
      birthDate: cp.birthDate,
      gender: cp.gender == 'male' ? Gender.male : (cp.gender == 'female' ? Gender.female : Gender.unknown),
    );
  }

  /// Convert ChildModel (profile) to ChildProfile (tracking)
  ChildProfile childModelToProfile(ChildModel cm) {
    return ChildProfile(
      id: cm.id,
      name: cm.name,
      birthDate: cm.birthDate,
      gender: cm.gender == Gender.male ? 'male' : 'female',
    );
  }

  /// Sync children from Profile (AppState) into TrackingService - merges new ones
  void syncFromProfile(List<ChildModel> profileChildren) {
    bool changed = false;
    for (final cm in profileChildren) {
      final exists = _children.any((c) => c.id == cm.id);
      if (!exists) {
        final cp = childModelToProfile(cm);
        _children.add(cp);
        Hive.box<String>(_childrenBoxName).put(cp.id, jsonEncode(cp.toJson()));
        changed = true;
      } else {
        // Update existing child data (name, birthdate, gender)
        final idx = _children.indexWhere((c) => c.id == cm.id);
        if (idx != -1) {
          final existing = _children[idx];
          final newGender = cm.gender == Gender.male ? 'male' : 'female';
          if (existing.name != cm.name || existing.birthDate != cm.birthDate || existing.gender != newGender) {
            _children[idx] = ChildProfile(
              id: cm.id,
              name: cm.name,
              birthDate: cm.birthDate,
              gender: newGender,
              photoUrl: existing.photoUrl,
            );
            Hive.box<String>(_childrenBoxName).put(cm.id, jsonEncode(_children[idx].toJson()));
            changed = true;
          }
        }
      }
    }
    if (changed) notifyListeners();
  }

  /// Get list of ChildModels for profile sync
  List<ChildModel> getChildModelsForProfile() {
    return _children.map((cp) => childProfileToModel(cp)).toList();
  }

  // ===== Children CRUD =====
  void addChild(ChildProfile child) {
    _children.add(child);
    Hive.box<String>(_childrenBoxName).put(child.id, jsonEncode(child.toJson()));
    notifyListeners();
  }

  void updateChild(ChildProfile child) {
    final idx = _children.indexWhere((c) => c.id == child.id);
    if (idx != -1) {
      _children[idx] = child;
      Hive.box<String>(_childrenBoxName).put(child.id, jsonEncode(child.toJson()));
      notifyListeners();
    }
  }

  void deleteChild(String childId) {
    _children.removeWhere((c) => c.id == childId);
    _records.removeWhere((r) => r.childId == childId);
    Hive.box<String>(_childrenBoxName).delete(childId);
    // remove all records for this child
    final recordsBox = Hive.box<String>(_recordsBoxName);
    final keysToRemove = <String>[];
    for (final key in recordsBox.keys) {
      final json = jsonDecode(recordsBox.get(key)!);
      if (json['childId'] == childId) keysToRemove.add(key as String);
    }
    for (final key in keysToRemove) {
      recordsBox.delete(key);
    }
    notifyListeners();
  }

  // ===== Records CRUD =====
  void addRecord(TrackingRecord record) {
    _records.insert(0, record);
    Hive.box<String>(_recordsBoxName).put(record.id, jsonEncode(record.toJson()));
    notifyListeners();
  }

  void updateRecord(TrackingRecord record) {
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      _records[idx] = record;
      Hive.box<String>(_recordsBoxName).put(record.id, jsonEncode(record.toJson()));
      _records.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      notifyListeners();
    }
  }

  void deleteRecord(String recordId) {
    _records.removeWhere((r) => r.id == recordId);
    Hive.box<String>(_recordsBoxName).delete(recordId);
    notifyListeners();
  }

  // ===== Query helpers =====
  List<TrackingRecord> getRecordsForChild(String childId, {TrackingType? type}) {
    return _records.where((r) {
      if (r.childId != childId) return false;
      if (type != null && r.type != type) return false;
      return true;
    }).toList();
  }

  List<TrackingRecord> getTodayRecords(String childId, {TrackingType? type}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getRecordsForChild(childId, type: type).where((r) {
      return r.dateTime.isAfter(today);
    }).toList();
  }

  List<TrackingRecord> getWeekRecords(String childId, {TrackingType? type}) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return getRecordsForChild(childId, type: type).where((r) {
      return r.dateTime.isAfter(weekAgo);
    }).toList();
  }

  // ===== Computed stats =====
  double getTodaySleepHours(String childId) {
    final sleepRecords = getTodayRecords(childId, type: TrackingType.sleep);
    double total = 0;
    for (final r in sleepRecords) {
      total += r.sleepDurationHours;
    }
    return total;
  }

  int getTodayFeedingCount(String childId) {
    return getTodayRecords(childId, type: TrackingType.feeding).length;
  }

  int getTodayDiaperCount(String childId) {
    return getTodayRecords(childId, type: TrackingType.diaper).length;
  }

  TrackingRecord? getLatestGrowth(String childId) {
    final growthRecords = getRecordsForChild(childId, type: TrackingType.growth);
    return growthRecords.isNotEmpty ? growthRecords.first : null;
  }

  // ===== Demo data seed =====
  void _seedDemoData() {
    final now = DateTime.now();

    // Add demo children
    final noahId = 'child_noah';
    final eitanId = 'child_eitan';

    _children = [
      ChildProfile(
        id: noahId,
        name: 'נועה',
        birthDate: DateTime(2022, 3, 10),
        gender: 'female',
      ),
      ChildProfile(
        id: eitanId,
        name: 'איתן',
        birthDate: DateTime(2024, 1, 5),
        gender: 'male',
      ),
    ];

    _records = [];

    // --- Growth records for Noa ---
    final growthData = [
      {'m': 0, 'w': 3.5, 'h': 50.0, 'hc': 35.0},
      {'m': 1, 'w': 4.3, 'h': 54.0, 'hc': 37.0},
      {'m': 3, 'w': 5.8, 'h': 60.0, 'hc': 40.0},
      {'m': 6, 'w': 7.8, 'h': 66.0, 'hc': 43.0},
      {'m': 9, 'w': 9.2, 'h': 70.0, 'hc': 44.5},
      {'m': 12, 'w': 10.3, 'h': 74.0, 'hc': 45.5},
      {'m': 15, 'w': 11.1, 'h': 78.0, 'hc': 46.0},
      {'m': 18, 'w': 11.8, 'h': 81.0, 'hc': 46.5},
      {'m': 22, 'w': 12.2, 'h': 84.0, 'hc': 47.0},
    ];
    for (final g in growthData) {
      final months = g['m'] as int;
      _records.add(TrackingRecord(
        id: 'growth_noah_$months',
        childId: noahId,
        type: TrackingType.growth,
        dateTime: DateTime(2022, 3 + months, 10),
        data: {
          'weight': g['w'],
          'height': g['h'],
          'headCircumference': g['hc'],
        },
        notes: months == 22 ? 'בדיקת שגרה אצל רופא' : null,
      ));
    }

    // --- Sleep records (today + recent) ---
    _records.add(TrackingRecord(
      id: 'sleep_noah_1',
      childId: noahId,
      type: TrackingType.sleep,
      dateTime: DateTime(now.year, now.month, now.day, 20, 30),
      data: {
        'sleepType': 'nightSleep',
        'sleepEnd': DateTime(now.year, now.month, now.day + 1, 7, 0).toIso8601String(),
      },
      notes: 'נרדמה מהר',
    ));
    _records.add(TrackingRecord(
      id: 'sleep_noah_2',
      childId: noahId,
      type: TrackingType.sleep,
      dateTime: DateTime(now.year, now.month, now.day, 10, 0),
      data: {
        'sleepType': 'nap',
        'sleepEnd': DateTime(now.year, now.month, now.day, 11, 30).toIso8601String(),
      },
    ));
    _records.add(TrackingRecord(
      id: 'sleep_noah_3',
      childId: noahId,
      type: TrackingType.sleep,
      dateTime: DateTime(now.year, now.month, now.day, 15, 0),
      data: {
        'sleepType': 'nap',
        'sleepEnd': DateTime(now.year, now.month, now.day, 15, 30).toIso8601String(),
      },
    ));

    // past days sleep data
    for (int i = 1; i <= 6; i++) {
      final d = now.subtract(Duration(days: i));
      final nightH = 9.0 + (i % 3);
      final napH = 1.0 + (i % 2) * 0.5;
      _records.add(TrackingRecord(
        id: 'sleep_noah_night_$i',
        childId: noahId,
        type: TrackingType.sleep,
        dateTime: DateTime(d.year, d.month, d.day, 20, 0),
        data: {
          'sleepType': 'nightSleep',
          'sleepEnd': DateTime(d.year, d.month, d.day, 20 + nightH.toInt(), ((nightH % 1) * 60).toInt()).toIso8601String(),
        },
      ));
      _records.add(TrackingRecord(
        id: 'sleep_noah_nap_$i',
        childId: noahId,
        type: TrackingType.sleep,
        dateTime: DateTime(d.year, d.month, d.day, 13, 0),
        data: {
          'sleepType': 'nap',
          'sleepEnd': DateTime(d.year, d.month, d.day, 13 + napH.toInt(), ((napH % 1) * 60).toInt()).toIso8601String(),
        },
      ));
    }

    // --- Feeding records today ---
    _records.addAll([
      TrackingRecord(
        id: 'feed_noah_1',
        childId: noahId,
        type: TrackingType.feeding,
        dateTime: DateTime(now.year, now.month, now.day, 7, 30),
        data: {'feedingType': 'breastfeeding', 'durationMinutes': 20, 'breastSide': 'שמאל + ימין'},
      ),
      TrackingRecord(
        id: 'feed_noah_2',
        childId: noahId,
        type: TrackingType.feeding,
        dateTime: DateTime(now.year, now.month, now.day, 9, 0),
        data: {'feedingType': 'solid', 'foodDetails': 'דייסה + פירות'},
        notes: 'אכלה טוב',
      ),
      TrackingRecord(
        id: 'feed_noah_3',
        childId: noahId,
        type: TrackingType.feeding,
        dateTime: DateTime(now.year, now.month, now.day, 12, 0),
        data: {'feedingType': 'bottle', 'amountMl': 120.0},
      ),
      TrackingRecord(
        id: 'feed_noah_4',
        childId: noahId,
        type: TrackingType.feeding,
        dateTime: DateTime(now.year, now.month, now.day, 13, 0),
        data: {'feedingType': 'solid', 'foodDetails': 'ירקות + עוף'},
      ),
      TrackingRecord(
        id: 'feed_noah_5',
        childId: noahId,
        type: TrackingType.feeding,
        dateTime: DateTime(now.year, now.month, now.day, 15, 30),
        data: {'feedingType': 'water', 'amountMl': 50.0},
      ),
    ]);

    // --- Diaper records today ---
    for (int i = 0; i < 6; i++) {
      _records.add(TrackingRecord(
        id: 'diaper_noah_$i',
        childId: noahId,
        type: TrackingType.diaper,
        dateTime: DateTime(now.year, now.month, now.day, 6 + i * 3, 0),
        data: {'diaperType': i % 3 == 0 ? 'both' : (i % 2 == 0 ? 'wet' : 'dirty')},
      ));
    }

    // --- Milestones ---
    _records.addAll([
      TrackingRecord(
        id: 'mile_noah_1',
        childId: noahId,
        type: TrackingType.milestone,
        dateTime: now.subtract(const Duration(days: 14)),
        data: {'milestoneName': 'הליכה עצמאית', 'milestoneCategory': 'grossMotor', 'milestoneStatus': 'achieved'},
        notes: 'התחילה ללכת בלי עזרה!',
      ),
      TrackingRecord(
        id: 'mile_noah_2',
        childId: noahId,
        type: TrackingType.milestone,
        dateTime: now.subtract(const Duration(days: 30)),
        data: {'milestoneName': 'אומרת "אמא"', 'milestoneCategory': 'language', 'milestoneStatus': 'achieved'},
      ),
      TrackingRecord(
        id: 'mile_noah_3',
        childId: noahId,
        type: TrackingType.milestone,
        dateTime: now.subtract(const Duration(days: 3)),
        data: {'milestoneName': 'אוכלת עם כפית', 'milestoneCategory': 'fineMotor', 'milestoneStatus': 'inProgress'},
      ),
      TrackingRecord(
        id: 'mile_noah_4',
        childId: noahId,
        type: TrackingType.milestone,
        dateTime: now,
        data: {'milestoneName': 'משחקת עם ילדים', 'milestoneCategory': 'social', 'milestoneStatus': 'expected'},
      ),
    ]);

    // --- Health records ---
    _records.addAll([
      TrackingRecord(
        id: 'health_noah_1',
        childId: noahId,
        type: TrackingType.health,
        dateTime: now.subtract(const Duration(days: 7)),
        data: {'healthType': 'doctor_visit', 'healthDetails': 'בדיקת שגרה - הכל תקין'},
      ),
      TrackingRecord(
        id: 'health_noah_2',
        childId: noahId,
        type: TrackingType.health,
        dateTime: now.subtract(const Duration(days: 21)),
        data: {'healthType': 'fever', 'temperature': 38.5, 'healthDetails': 'טופלה בפרצטמול'},
      ),
      TrackingRecord(
        id: 'health_noah_3',
        childId: noahId,
        type: TrackingType.health,
        dateTime: now.subtract(const Duration(days: 60)),
        data: {'healthType': 'vaccine', 'healthDetails': 'חיסון משושה - 18 חודשים'},
      ),
      TrackingRecord(
        id: 'health_noah_4',
        childId: noahId,
        type: TrackingType.health,
        dateTime: now.subtract(const Duration(days: 90)),
        data: {'healthType': 'allergy', 'healthDetails': 'תגובה קלה לחלב - עברה'},
      ),
    ]);

    // Sort all records
    _records.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }
}
