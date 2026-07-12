import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/services/window_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WindowStateService', () {
    late WindowStateService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = WindowStateService();
    });

    test('restore returns null when no saved state', () async {
      final rect = await service.restore();
      expect(rect, isNull);
    });

    test('save and restore round-trips', () async {
      const bounds = Rect.fromLTWH(100, 200, 1200, 800);
      await service.save(bounds);

      final restored = await service.restore();
      expect(restored, isNotNull);
      expect(restored!.left, 100.0);
      expect(restored.top, 200.0);
      expect(restored.width, 1200.0);
      expect(restored.height, 800.0);
    });

    test('restore returns null for invalid dimensions', () async {
      SharedPreferences.setMockInitialValues({
        'window_x': 0.0,
        'window_y': 0.0,
        'window_width': 50.0, // too small
        'window_height': 50.0,
      });

      final restored = await service.restore();
      expect(restored, isNull);
    });
  });
}
