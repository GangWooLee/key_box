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

    test('both themes use the IBM Plex Sans UI family', () {
      // V9: single IBM Plex family (Inter/JetBrains removed).
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.textTheme.bodyMedium?.fontFamily, contains('IBM Plex Sans'));
      expect(dark.textTheme.bodyMedium?.fontFamily, contains('IBM Plex Sans'));
    });

    test('ElevatedButton minimum hit target is 32x32 (desktop pointer)', () {
      // V9 DESIGN.md: 32×32 is the macOS desktop-pointer target (44 is the
      // touch rule and does not apply to this cursor-driven app).
      final theme = AppTheme.dark();
      final buttonStyle = theme.elevatedButtonTheme.style;
      final minSize = buttonStyle?.minimumSize?.resolve({});
      expect(minSize, isNotNull);
      expect(minSize!.width, greaterThanOrEqualTo(32));
      expect(minSize.height, greaterThanOrEqualTo(32));
    });
  });
}
