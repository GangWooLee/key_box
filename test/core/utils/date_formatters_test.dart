import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/utils/date_formatters.dart';

void main() {
  group('DateFormatters', () {
    test('full formats a date', () {
      final date = DateTime(2026, 3, 1, 14, 30);
      final result = DateFormatters.full(date);
      expect(result, isNotEmpty);
      expect(result, contains('2026'));
    });

    test('timeAgo returns just now for recent dates', () {
      final now = DateTime.now();
      final result = DateFormatters.timeAgo(now);
      expect(result.toLowerCase(), contains('just now'));
    });

    test('timeAgo returns minutes ago', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      final result = DateFormatters.timeAgo(past);
      expect(result, '5m ago');
    });

    test('timeAgo returns hours ago', () {
      final past = DateTime.now().subtract(const Duration(hours: 3));
      final result = DateFormatters.timeAgo(past);
      expect(result, '3h ago');
    });

    test('timeAgo returns days ago', () {
      final past = DateTime.now().subtract(const Duration(days: 7));
      final result = DateFormatters.timeAgo(past);
      expect(result, '7d ago');
    });
  });
}
