import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MOMIT Accessibility Service - WCAG 2.2 AA compliant
/// Manages user accessibility preferences for inclusive design
class AccessibilityService extends ChangeNotifier {
  static const String _prefFontScale = 'a11y_font_scale';
  static const String _prefHighContrast = 'a11y_high_contrast';
  static const String _prefReduceMotion = 'a11y_reduce_motion';
  static const String _prefLargeTouch = 'a11y_large_touch';
  static const String _prefScreenReader = 'a11y_screen_reader';
  static const String _prefBoldText = 'a11y_bold_text';
  static const String _prefColorBlindMode = 'a11y_color_blind';

  double _fontScale = 1.0;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _largeTouch = false;
  bool _screenReaderOptimized = false;
  bool _boldText = false;
  String _colorBlindMode = 'none'; // none, protanopia, deuteranopia, tritanopia

  double get fontScale => _fontScale;
  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;
  bool get largeTouch => _largeTouch;
  bool get screenReaderOptimized => _screenReaderOptimized;
  bool get boldText => _boldText;
  String get colorBlindMode => _colorBlindMode;

  /// Minimum touch target size (WCAG 2.2 AA = 24px, AAA = 44px)
  double get minTouchTarget => _largeTouch ? 56.0 : 44.0;

  /// Font weight adjustment
  FontWeight get normalWeight => _boldText ? FontWeight.w500 : FontWeight.w400;
  FontWeight get mediumWeight => _boldText ? FontWeight.w600 : FontWeight.w500;
  FontWeight get boldWeight => _boldText ? FontWeight.w800 : FontWeight.w700;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontScale = prefs.getDouble(_prefFontScale) ?? 1.0;
      _highContrast = prefs.getBool(_prefHighContrast) ?? false;
      _reduceMotion = prefs.getBool(_prefReduceMotion) ?? false;
      _largeTouch = prefs.getBool(_prefLargeTouch) ?? false;
      _screenReaderOptimized = prefs.getBool(_prefScreenReader) ?? false;
      _boldText = prefs.getBool(_prefBoldText) ?? false;
      _colorBlindMode = prefs.getString(_prefColorBlindMode) ?? 'none';
      notifyListeners();
    } catch (e) {
      debugPrint('[A11y] Init error: $e');
    }
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.8, 2.0);
    await _save(_prefFontScale, _fontScale);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    await _saveBool(_prefHighContrast, value);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    await _saveBool(_prefReduceMotion, value);
    notifyListeners();
  }

  Future<void> setLargeTouch(bool value) async {
    _largeTouch = value;
    await _saveBool(_prefLargeTouch, value);
    notifyListeners();
  }

  Future<void> setScreenReaderOptimized(bool value) async {
    _screenReaderOptimized = value;
    await _saveBool(_prefScreenReader, value);
    notifyListeners();
  }

  Future<void> setBoldText(bool value) async {
    _boldText = value;
    await _saveBool(_prefBoldText, value);
    notifyListeners();
  }

  Future<void> setColorBlindMode(String mode) async {
    _colorBlindMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefColorBlindMode, mode);
    notifyListeners();
  }

  Future<void> resetAll() async {
    _fontScale = 1.0;
    _highContrast = false;
    _reduceMotion = false;
    _largeTouch = false;
    _screenReaderOptimized = false;
    _boldText = false;
    _colorBlindMode = 'none';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefFontScale);
    await prefs.remove(_prefHighContrast);
    await prefs.remove(_prefReduceMotion);
    await prefs.remove(_prefLargeTouch);
    await prefs.remove(_prefScreenReader);
    await prefs.remove(_prefBoldText);
    await prefs.remove(_prefColorBlindMode);
    notifyListeners();
  }

  Future<void> _save(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
