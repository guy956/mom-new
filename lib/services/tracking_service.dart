import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mom_connect/models/tracking_models.dart';
import 'package:mom_connect/models/user_model.dart';
import 'package:mom_connect/services/firestore_service.dart';

/// שירות מעקב - ניהול CRUD מלא עם שמירה ב-Hive
class TrackingService extends ChangeNotifier {
  static const String _childrenBoxBaseName = 'tracking_children';
  static const String _recordsBoxBaseName = 'tracking_records';

  /// Resolved box names (prefixed with userId after init)
  String _childrenBoxName = 'tracking_children';
  String _recordsBoxName = 'tracking_records';

  /// The userId this service is scoped to
  String? _userId;
  FirestoreService? _firestoreService;

  List<ChildProfile> _children = [];
  List<TrackingRecord> _records = [];
  bool _isInitialized = false;

  List<ChildProfile> get children => _children;
  List<TrackingRecord> get records => _records;
  bool get isInitialized => _isInitialized;

  /// Initialize with a [userId] to scope Hive boxes per user.
  /// If [userId] is null or empty, falls back to global box names.
  Future<void> init({String? userId, FirestoreService? firestoreService}) async {
    // If re-initializing for a different user, close old boxes and reset
    if (_isInitialized && userId != _userId) {
      _children = [];
      _records = [];
      _isInitialized = false;
    }
    if (_isInitialized) return;

    _userId = userId;
    _firestoreService = firestoreService;
    if (userId != null && userId.isNotEmpty) {
      _childrenBoxName = '${userId}_$_childrenBoxBaseName';
      _recordsBoxName = '${userId}_$_recordsBoxBaseName';
    } else {
      _childrenBoxName = _childrenBoxBaseName;
      _recordsBoxName = _recordsBoxBaseName;
    }

    await Hive.openBox<String>(_childrenBoxName);
    await Hive.openBox<String>(_recordsBoxName);
    _loadFromHive();
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

  // ===== Firestore sync helper =====
  void _syncChildToFirestore(ChildProfile child) {
    if (_userId != null && _firestoreService != null) {
      _firestoreService!.saveTrackingChild(_userId!, child.toJson());
    }
  }

  void _syncRecordToFirestore(TrackingRecord record) {
    if (_userId != null && _firestoreService != null) {
      _firestoreService!.saveTrackingRecord(_userId!, record.toJson());
    }
  }

  // ===== Children CRUD =====
  void addChild(ChildProfile child) {
    _children.add(child);
    Hive.box<String>(_childrenBoxName).put(child.id, jsonEncode(child.toJson()));
    _syncChildToFirestore(child);
    notifyListeners();
  }

  void updateChild(ChildProfile child) {
    final idx = _children.indexWhere((c) => c.id == child.id);
    if (idx != -1) {
      _children[idx] = child;
      Hive.box<String>(_childrenBoxName).put(child.id, jsonEncode(child.toJson()));
      _syncChildToFirestore(child);
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
    if (_userId != null && _firestoreService != null) {
      _firestoreService!.deleteTrackingChild(_userId!, childId);
    }
    notifyListeners();
  }

  // ===== Records CRUD =====
  void addRecord(TrackingRecord record) {
    _records.insert(0, record);
    Hive.box<String>(_recordsBoxName).put(record.id, jsonEncode(record.toJson()));
    _syncRecordToFirestore(record);
    notifyListeners();
  }

  void updateRecord(TrackingRecord record) {
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      _records[idx] = record;
      Hive.box<String>(_recordsBoxName).put(record.id, jsonEncode(record.toJson()));
      _syncRecordToFirestore(record);
      _records.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      notifyListeners();
    }
  }

  void deleteRecord(String recordId) {
    _records.removeWhere((r) => r.id == recordId);
    Hive.box<String>(_recordsBoxName).delete(recordId);
    if (_userId != null && _firestoreService != null) {
      _firestoreService!.deleteTrackingRecord(_userId!, recordId);
    }
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

  // ===== Demo data seed (disabled - kept for reference) =====
  // void _seedDemoData() {
  //   // Demo data seeding has been removed from production.
  //   // New users now start with an empty tracking screen.
  //   // The demo data previously created fake children (נועה, איתן)
  //   // and sample records for growth, sleep, feeding, diapers,
  //   // milestones, and health. It was called on first launch when
  //   // _children.isEmpty. This is no longer needed since the app
  //   // syncs real children from the user's profile.
  // }
}
