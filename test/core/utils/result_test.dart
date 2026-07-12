import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Success has correct properties', () {
      const result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 42);
    });

    test('Failure has correct properties', () {
      const result = Failure<int>('something went wrong');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.message, 'something went wrong');
    });

    test('Failure can carry error list', () {
      const result = Failure<int>('error', errors: ['a', 'b']);
      expect(result.errors, ['a', 'b']);
    });

    test('Success<void> works', () {
      const result = Success<void>(null);
      expect(result.isSuccess, isTrue);
    });

    test('toString works for both types', () {
      expect(const Success(1).toString(), 'Success(1)');
      expect(const Failure<int>('err').toString(), contains('Failure'));
    });
  });
}
