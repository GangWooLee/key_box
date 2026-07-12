import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('calls action after delay', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      var called = false;

      debouncer.call(() => called = true);
      expect(called, isFalse);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(called, isTrue);

      debouncer.dispose();
    });

    test('cancels previous call on rapid fire', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      var count = 0;

      debouncer.call(() => count++);
      debouncer.call(() => count++);
      debouncer.call(() => count++);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(count, 1); // only the last call fires

      debouncer.dispose();
    });

    test('dispose cancels pending call', () async {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 50));
      var called = false;

      debouncer.call(() => called = true);
      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(called, isFalse);
    });
  });
}
