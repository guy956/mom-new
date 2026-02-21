import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Utility class for handling Firestore errors consistently
class FirestoreErrorHandler {
  FirestoreErrorHandler._();

  /// Handles Firestore errors and returns a user-friendly error message
  static String handleError(dynamic error, {String? operation}) {
    final String prefix = operation != null ? '$operation: ' : '';
    
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          debugPrint('${prefix}Permission denied: ${error.message}');
          return 'אין הרשאה לבצע פעולה זו';
        case 'not-found':
          debugPrint('${prefix}Document not found: ${error.message}');
          return 'המידע המבוקש לא נמצא';
        case 'already-exists':
          debugPrint('${prefix}Document already exists: ${error.message}');
          return 'הפריט כבר קיים';
        case 'failed-precondition':
          debugPrint('${prefix}Failed precondition: ${error.message}');
          return 'תנאי מוקדם נכשל - ייתכן שחסר אינדקס';
        case 'unavailable':
          debugPrint('${prefix}Service unavailable: ${error.message}');
          return 'השירות לא זמין כרגע, נסה שוב מאוחר יותר';
        case 'deadline-exceeded':
          debugPrint('${prefix}Deadline exceeded: ${error.message}');
          return 'הפעולה נמשכה יותר מדי זמן, נסה שוב';
        case 'cancelled':
          debugPrint('${prefix}Operation cancelled: ${error.message}');
          return 'הפעולה בוטלה';
        case 'data-loss':
          debugPrint('${prefix}Data loss: ${error.message}');
          return 'אירעה שגיאה בשמירת הנתונים';
        case 'unauthenticated':
          debugPrint('${prefix}Unauthenticated: ${error.message}');
          return 'נדרשת התחברות מחדש';
        case 'resource-exhausted':
          debugPrint('${prefix}Resource exhausted: ${error.message}');
          return 'חריגה ממכסת השימוש, נסה שוב מאוחר יותר';
        default:
          debugPrint('${prefix}Firestore error (${error.code}): ${error.message}');
          return 'שגיאה בגישה לנתונים';
      }
    }
    
    debugPrint('${prefix}Unexpected error: $error');
    return 'אירעה שגיאה בלתי צפויה';
  }

  /// Wraps a Firestore operation with error handling
  static Future<T?> handleAsync<T>({
    required Future<T> Function() operation,
    required String operationName,
    void Function(String errorMessage)? onError,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final errorMessage = handleError(e, operation: operationName);
      if (onError != null) {
        onError(errorMessage);
      }
      return null;
    }
  }

  /// Wraps a Firestore stream with error handling
  static Stream<T> handleStream<T>({
    required Stream<T> stream,
    required String operationName,
  }) {
    return stream.handleError((error) {
      final errorMessage = handleError(error, operation: operationName);
      debugPrint('Stream error in $operationName: $errorMessage');
    });
  }
}

/// Mixin for adding error handling to Firestore services
mixin FirestoreErrorHandlerMixin {
  /// Wraps an async operation with standardized error handling
  Future<T?> withErrorHandling<T>({
    required Future<T> Function() operation,
    required String operationName,
    void Function(String errorMessage)? onError,
  }) async {
    return FirestoreErrorHandler.handleAsync(
      operation: operation,
      operationName: operationName,
      onError: onError,
    );
  }

  /// Safely executes a Firestore write operation with retry logic
  Future<bool> safeWrite({
    required Future<void> Function() operation,
    required String operationName,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        await operation();
        return true;
      } catch (e) {
        attempts++;
        final errorMessage = FirestoreErrorHandler.handleError(e, operation: operationName);
        debugPrint('Attempt $attempts/$maxRetries failed: $errorMessage');
        
        if (attempts >= maxRetries) {
          debugPrint('Max retries exceeded for $operationName');
          return false;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 100 * attempts));
      }
    }
    
    return false;
  }
}
