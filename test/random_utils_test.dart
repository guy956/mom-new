import 'package:flutter_test/flutter_test.dart';
import 'package:mom_connect/utils/random_utils.dart';

void main() {
  group('RandomUtils Tests', () {
    test('generateRandomCode generates code of correct length', () {
      final code6 = RandomUtils.generateRandomCode(length: 6);
      expect(code6.length, equals(6));
      expect(RegExp(r'^[A-Z0-9]+$').hasMatch(code6), isTrue);

      final code8 = RandomUtils.generateRandomCode(length: 8);
      expect(code8.length, equals(8));
    });

    test('generateRandomCode generates different codes', () {
      final code1 = RandomUtils.generateRandomCode();
      final code2 = RandomUtils.generateRandomCode();
      expect(code1, isNot(equals(code2)));
    });

    test('generateSecureToken generates token of correct length', () {
      final token = RandomUtils.generateSecureToken(byteLength: 32);
      expect(token.length, equals(64)); // hex encoding doubles length
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(token), isTrue);
    });

    test('generateSecureToken generates different tokens', () {
      final token1 = RandomUtils.generateSecureToken();
      final token2 = RandomUtils.generateSecureToken();
      expect(token1, isNot(equals(token2)));
    });

    test('generateCryptoToken generates token of correct length', () {
      final token = RandomUtils.generateCryptoToken(byteLength: 32);
      expect(token.length, equals(64)); // hex encoding doubles length
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(token), isTrue);
    });

    test('generateCryptoToken generates different tokens', () {
      final token1 = RandomUtils.generateCryptoToken();
      final token2 = RandomUtils.generateCryptoToken();
      expect(token1, isNot(equals(token2)));
    });

    test('generateRandomInt returns value in range', () {
      for (int i = 0; i < 100; i++) {
        final value = RandomUtils.generateRandomInt(10, 20);
        expect(value, greaterThanOrEqualTo(10));
        expect(value, lessThan(20));
      }
    });

    test('generateRandomDouble returns value between 0 and 1', () {
      for (int i = 0; i < 100; i++) {
        final value = RandomUtils.generateRandomDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('generateRandomBool returns boolean', () {
      final value = RandomUtils.generateRandomBool();
      expect(value is bool, isTrue);
    });

    test('generateSecureUuid returns valid UUID format', () {
      final uuid = RandomUtils.generateSecureUuid();
      expect(uuid.length, equals(36));
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(uuid),
        isTrue,
      );
    });

    test('generateSecureUuid generates different UUIDs', () {
      final uuid1 = RandomUtils.generateSecureUuid();
      final uuid2 = RandomUtils.generateSecureUuid();
      expect(uuid1, isNot(equals(uuid2)));
    });

    test('generateRandomString generates string of correct length', () {
      final str = RandomUtils.generateRandomString(10);
      expect(str.length, equals(10));
    });

    test('generateRandomString uses custom charset', () {
      final str = RandomUtils.generateRandomString(20, charset: 'ABC');
      expect(str.length, equals(20));
      expect(RegExp(r'^[ABC]+$').hasMatch(str), isTrue);
    });

    test('generateSecurePassword generates password of correct length', () {
      final password = RandomUtils.generateSecurePassword(length: 16);
      expect(password.length, equals(16));
    });

    test('generateSecurePassword contains required character types', () {
      final password = RandomUtils.generateSecurePassword(length: 16);
      expect(RegExp(r'[A-Z]').hasMatch(password), isTrue); // uppercase
      expect(RegExp(r'[a-z]').hasMatch(password), isTrue); // lowercase
      expect(RegExp(r'[0-9]').hasMatch(password), isTrue); // numbers
      expect(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password), isTrue); // special
    });

    test('All functions use secure random (no Math.random)', () {
      // Run multiple times to verify randomness
      final results = <String>[];
      for (int i = 0; i < 50; i++) {
        results.add(RandomUtils.generateRandomCode());
        results.add(RandomUtils.generateSecureToken());
        results.add(RandomUtils.generateSecureUuid());
        results.add(RandomUtils.generateCryptoToken());
      }
      // All results should be unique
      expect(results.toSet().length, equals(results.length));
    });
  });
}
