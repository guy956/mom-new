import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Secure random number generator utilities
/// Uses Random.secure() and crypto library for cryptographically secure random generation
/// 
/// SECURITY NOTE: This file replaces all Math.random() usage with secure alternatives
/// to prevent predictability attacks on tokens, codes, and session identifiers.
class RandomUtils {
  static final Random _secureRandom = Random.secure();

  /// Generates a random code of specified length using alphanumeric characters
  /// Uses secure random for cryptographic safety
  /// 
  /// SECURITY: Previously used Math.random() - now uses Random.secure()
  static String generateRandomCode({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Generates a cryptographically secure token of specified byte length
  /// Returns hex encoded string suitable for session tokens, CSRF tokens, etc.
  /// 
  /// SECURITY: Uses Random.secure() for true cryptographic randomness
  static String generateSecureToken({int byteLength = 32}) {
    final random = Random.secure();
    final bytes = Uint8List(byteLength);
    for (int i = 0; i < byteLength; i++) {
      bytes[i] = random.nextInt(256);
    }
    // Convert to hex string for URL-safe token
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generates a cryptographically secure token using crypto library
  /// Provides additional entropy by incorporating timestamp hash
  /// 
  /// SECURITY: Uses crypto.sha256 for enhanced token generation
  static String generateCryptoToken({int byteLength = 32}) {
    final random = Random.secure();
    final bytes = Uint8List(byteLength);
    for (int i = 0; i < byteLength; i++) {
      bytes[i] = random.nextInt(256);
    }
    
    // Add additional entropy with timestamp
    final timestampBytes = utf8.encode(DateTime.now().millisecondsSinceEpoch.toString());
    final combined = Uint8List.fromList([...bytes, ...timestampBytes]);
    final hash = sha256.convert(combined);
    
    return hash.toString().substring(0, byteLength * 2);
  }

  /// Generates a random integer between min (inclusive) and max (exclusive)
  static int generateRandomInt(int min, int max) {
    final random = Random.secure();
    return min + random.nextInt(max - min);
  }

  /// Generates a random double between 0.0 and 1.0
  static double generateRandomDouble() {
    return Random.secure().nextDouble();
  }

  /// Generates a random boolean
  static bool generateRandomBool() {
    return Random.secure().nextBool();
  }

  /// Generates a secure random UUID v4 string
  static String generateSecureUuid() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    
    for (int i = 0; i < 16; i++) {
      bytes[i] = random.nextInt(256);
    }
    
    // Set version (4) and variant bits for UUID v4
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // Variant 10
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Generates a random string of specified length from given character set
  static String generateRandomString(int length, {String? charset}) {
    final chars = charset ?? 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generates a secure random password with mixed characters
  static String generateSecurePassword({int length = 16}) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    final allChars = uppercase + lowercase + numbers + special;
    final random = Random.secure();
    
    // Ensure at least one of each type
    final password = StringBuffer();
    password.write(uppercase[random.nextInt(uppercase.length)]);
    password.write(lowercase[random.nextInt(lowercase.length)]);
    password.write(numbers[random.nextInt(numbers.length)]);
    password.write(special[random.nextInt(special.length)]);
    
    // Fill remaining with random chars
    for (int i = 4; i < length; i++) {
      password.write(allChars[random.nextInt(allChars.length)]);
    }
    
    // Shuffle the password
    final passwordList = password.toString().split('')..shuffle(random);
    return passwordList.join();
  }
}
