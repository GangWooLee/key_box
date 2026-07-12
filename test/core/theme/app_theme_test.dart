import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme has light brightness', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme has dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('both themes use Inter font family', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.textTheme.bodyMedium?.fontFamily, contains('Inter'));
      expect(dark.textTheme.bodyMedium?.fontFamily, contains('Inter'));
    });

    test('ElevatedButton minimum size is 44x44 (accessibility)', () {
      final theme = AppTheme.dark();
      final buttonStyle = theme.elevatedButtonTheme.style;
      final minSize = buttonStyle?.minimumSize?.resolve({});
      expect(minSize, isNotNull);
      expect(minSize!.width, greaterThanOrEqualTo(44));
      expect(minSize.height, greaterThanOrEqualTo(44));
    });
  });
}
