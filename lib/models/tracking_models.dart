import 'package:flutter/material.dart';

/// ===== סוגי רשומות מעקב =====
enum TrackingType {
  growth,     // מדידה - משקל/גובה/היקף ראש
  sleep,      // שינה
  feeding,    // האכלה
  diaper,     // חיתול
  milestone,  // אבן דרך
  health,     // בריאות
  other,      // אחר
}

enum FeedingSubType {
  breastfeeding,  // הנקה
  bottle,         // בקבוק
  solid,          // מוצק
  water,          // מים
  snack,          // חטיף
}

enum SleepSubType {
  nightSleep,   // שינת לילה
  nap,          // תנומה
}

enum DiaperSubType {
  wet,    // רטוב
  dirty,  // מלוכלך
  both,   // שניהם
  dry,    // יבש
}

enum MilestoneCategory {
  grossMotor,   // מוטורי גס
  fineMotor,    // מוטורי עדין
  language,     // שפה
  social,       // חברתי
  cognitive,    // קוגניטיבי
}

enum MilestoneStatus {
  achieved,     // הושג
  inProgress,   // בתהליך
  expected,     // צפוי
}

/// ===== מודל ילד =====
class ChildProfile {
  final String id;
  String name;
  DateTime birthDate;
  String gender; // 'male' / 'female'
  String? photoUrl;

  ChildProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.photoUrl,
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  }

  String get ageDisplay {
    final months = ageInMonths;
    if (months < 1) {
      final days = DateTime.now().difference(birthDate).inDays;
      return '$days ימים';
    } else if (months < 12) {
      return months == 1 ? 'חודש' : '$months חודשים';
    } else {
      final years = months ~/ 12;
      final rem = months % 12;
      final yearsStr = years == 1 ? 'שנה' : (years == 2 ? 'שנתיים' : '$years שנים');
      if (rem == 0) return yearsStr;
      final monthsStr = rem == 1 ? 'חודש' : '$rem חודשים';
      return '$yearsStr ו-$monthsStr';
    }
  }

  bool get isBoy => gender == 'male';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthDate': birthDate.toIso8601String(),
    'gender': gender,
    'photoUrl': photoUrl,
  };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    birthDate: DateTime.tryParse(json['birthDate'] ?? '') ?? DateTime.now(),
    gender: json['gender'] ?? 'unknown',
    photoUrl: json['photoUrl'],
  );
}

/// ===== רשומת מעקב בסיסית =====
class TrackingRecord {
  final String id;
  final String childId;
  final TrackingType type;
  DateTime dateTime;
  String? notes;
  Map<String, dynamic> data; // flexible data per type

  TrackingRecord({
    required this.id,
    required this.childId,
    required this.type,
    required this.dateTime,
    this.notes,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  // ===== Growth helpers =====
  double? get weight => data['weight'] as double?;
  set weight(double? v) => data['weight'] = v;
  double? get height => data['height'] as double?;
  set height(double? v) => data['height'] = v;
  double? get headCircumference => data['headCircumference'] as double?;
  set headCircumference(double? v) => data['headCircumference'] = v;

  // ===== Sleep helpers =====
  SleepSubType? get sleepType {
    final s = data['sleepType'] as String?;
    if (s == null) return null;
    return SleepSubType.values.firstWhere((e) => e.name == s, orElse: () => SleepSubType.nap);
  }
  set sleepType(SleepSubType? v) => data['sleepType'] = v?.name;
  DateTime? get sleepEnd {
    final s = data['sleepEnd'] as String?;
    return s != null ? DateTime.tryParse(s) : null;
  }
  set sleepEnd(DateTime? v) => data['sleepEnd'] = v?.toIso8601String();
  double get sleepDurationHours {
    final end = sleepEnd;
    if (end == null) return 0;
    double hours = end.difference(dateTime).inMinutes / 60.0;
    // Handle overnight sleep (e.g., 22:00 to 06:00)
    if (hours < 0) hours += 24;
    return hours;
  }

  // ===== Feeding helpers =====
  FeedingSubType? get feedingType {
    final s = data['feedingType'] as String?;
    if (s == null) return null;
    return FeedingSubType.values.firstWhere((e) => e.name == s, orElse: () => FeedingSubType.bottle);
  }
  set feedingType(FeedingSubType? v) => data['feedingType'] = v?.name;
  double? get amountMl => data['amountMl'] as double?;
  set amountMl(double? v) => data['amountMl'] = v;
  int? get durationMinutes => data['durationMinutes'] as int?;
  set durationMinutes(int? v) => data['durationMinutes'] = v;
  String? get foodDetails => data['foodDetails'] as String?;
  set foodDetails(String? v) => data['foodDetails'] = v;
  String? get breastSide => data['breastSide'] as String?;
  set breastSide(String? v) => data['breastSide'] = v;

  // ===== Diaper helpers =====
  DiaperSubType? get diaperType {
    final s = data['diaperType'] as String?;
    if (s == null) return null;
    return DiaperSubType.values.firstWhere((e) => e.name == s, orElse: () => DiaperSubType.wet);
  }
  set diaperType(DiaperSubType? v) => data['diaperType'] = v?.name;

  // ===== Milestone helpers =====
  MilestoneCategory? get milestoneCategory {
    final s = data['milestoneCategory'] as String?;
    if (s == null) return null;
    return MilestoneCategory.values.firstWhere((e) => e.name == s, orElse: () => MilestoneCategory.grossMotor);
  }
  set milestoneCategory(MilestoneCategory? v) => data['milestoneCategory'] = v?.name;
  MilestoneStatus? get milestoneStatus {
    final s = data['milestoneStatus'] as String?;
    if (s == null) return null;
    return MilestoneStatus.values.firstWhere((e) => e.name == s, orElse: () => MilestoneStatus.expected);
  }
  set milestoneStatus(MilestoneStatus? v) => data['milestoneStatus'] = v?.name;
  String? get milestoneName => data['milestoneName'] as String?;
  set milestoneName(String? v) => data['milestoneName'] = v;

  // ===== Health helpers =====
  String? get healthType => data['healthType'] as String?;
  set healthType(String? v) => data['healthType'] = v;
  String? get healthDetails => data['healthDetails'] as String?;
  set healthDetails(String? v) => data['healthDetails'] = v;
  double? get temperature => data['temperature'] as double?;
  set temperature(double? v) => data['temperature'] = v;

  // ===== Other =====
  String? get customType => data['customType'] as String?;
  set customType(String? v) => data['customType'] = v;

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'type': type.name,
    'dateTime': dateTime.toIso8601String(),
    'notes': notes,
    'data': data,
  };

  factory TrackingRecord.fromJson(Map<String, dynamic> json) => TrackingRecord(
    id: json['id'] ?? '',
    childId: json['childId'] ?? '',
    type: TrackingType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TrackingType.other,
    ),
    dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
    notes: json['notes'],
    data: Map<String, dynamic>.from(json['data'] ?? {}),
  );

  TrackingRecord copyWith({
    String? id,
    String? childId,
    TrackingType? type,
    DateTime? dateTime,
    String? notes,
    Map<String, dynamic>? data,
  }) {
    return TrackingRecord(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      data: data ?? Map<String, dynamic>.from(this.data),
    );
  }
}

/// ===== Helper maps for display =====
class TrackingHelpers {
  static String typeLabel(TrackingType type) {
    switch (type) {
      case TrackingType.growth: return 'מדידה';
      case TrackingType.sleep: return 'שינה';
      case TrackingType.feeding: return 'האכלה';
      case TrackingType.diaper: return 'חיתול';
      case TrackingType.milestone: return 'אבן דרך';
      case TrackingType.health: return 'בריאות';
      case TrackingType.other: return 'אחר';
    }
  }

  static String typeEmoji(TrackingType type) {
    switch (type) {
      case TrackingType.growth: return '📏';
      case TrackingType.sleep: return '😴';
      case TrackingType.feeding: return '🍼';
      case TrackingType.diaper: return '👶';
      case TrackingType.milestone: return '🎯';
      case TrackingType.health: return '💊';
      case TrackingType.other: return '✍️';
    }
  }

  static Color typeColor(TrackingType type) {
    switch (type) {
      case TrackingType.growth: return const Color(0xFFB5C8B9);
      case TrackingType.sleep: return const Color(0xFFD1C2D3);
      case TrackingType.feeding: return const Color(0xFFEDD3D8);
      case TrackingType.diaper: return const Color(0xFFDBC8B0);
      case TrackingType.milestone: return const Color(0xFFB5C8B9);
      case TrackingType.health: return const Color(0xFFD4A3A3);
      case TrackingType.other: return const Color(0xFFD1C2D3);
    }
  }

  static String feedingTypeLabel(FeedingSubType type) {
    switch (type) {
      case FeedingSubType.breastfeeding: return 'הנקה';
      case FeedingSubType.bottle: return 'בקבוק';
      case FeedingSubType.solid: return 'מוצק';
      case FeedingSubType.water: return 'מים';
      case FeedingSubType.snack: return 'חטיף';
    }
  }

  static String feedingTypeEmoji(FeedingSubType type) {
    switch (type) {
      case FeedingSubType.breastfeeding: return '🤱';
      case FeedingSubType.bottle: return '🍼';
      case FeedingSubType.solid: return '🥗';
      case FeedingSubType.water: return '💧';
      case FeedingSubType.snack: return '🍪';
    }
  }

  static String sleepTypeLabel(SleepSubType type) {
    switch (type) {
      case SleepSubType.nightSleep: return 'שינת לילה';
      case SleepSubType.nap: return 'תנומה';
    }
  }

  static String diaperTypeLabel(DiaperSubType type) {
    switch (type) {
      case DiaperSubType.wet: return 'רטוב';
      case DiaperSubType.dirty: return 'מלוכלך';
      case DiaperSubType.both: return 'שניהם';
      case DiaperSubType.dry: return 'יבש';
    }
  }

  static String milestoneCategoryLabel(MilestoneCategory cat) {
    switch (cat) {
      case MilestoneCategory.grossMotor: return 'מוטורי גס';
      case MilestoneCategory.fineMotor: return 'מוטורי עדין';
      case MilestoneCategory.language: return 'שפה';
      case MilestoneCategory.social: return 'חברתי';
      case MilestoneCategory.cognitive: return 'קוגניטיבי';
    }
  }

  static String milestoneStatusLabel(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.achieved: return 'הושג ✅';
      case MilestoneStatus.inProgress: return 'בתהליך 🔄';
      case MilestoneStatus.expected: return 'צפוי ⏳';
    }
  }

  static String healthTypeLabel(String? type) {
    switch (type) {
      case 'doctor_visit': return 'ביקור רופא';
      case 'fever': return 'חום';
      case 'allergy': return 'אלרגיה';
      case 'vaccine': return 'חיסון';
      case 'medication': return 'תרופה';
      case 'injury': return 'פציעה';
      default: return type ?? 'אחר';
    }
  }

  static IconData healthTypeIcon(String? type) {
    switch (type) {
      case 'doctor_visit': return Icons.medical_services;
      case 'fever': return Icons.thermostat;
      case 'allergy': return Icons.warning;
      case 'vaccine': return Icons.vaccines;
      case 'medication': return Icons.medication;
      case 'injury': return Icons.healing;
      default: return Icons.health_and_safety;
    }
  }
}
