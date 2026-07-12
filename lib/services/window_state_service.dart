import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

const _keyX = 'window_x';
const _keyY = 'window_y';
const _keyW = 'window_width';
const _keyH = 'window_height';

class WindowStateService {
  Future<Rect?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_keyX);
    final y = prefs.getDouble(_keyY);
    final w = prefs.getDouble(_keyW);
    final h = prefs.getDouble(_keyH);
    if (x == null || y == null || w == null || h == null) return null;
    if (w < 100 || h < 100) return null;
    return Rect.fromLTWH(x, y, w, h);
  }

  Future<void> save(Rect bounds) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_keyX, bounds.left),
      prefs.setDouble(_keyY, bounds.top),
      prefs.setDouble(_keyW, bounds.width),
      prefs.setDouble(_keyH, bounds.height),
    ]);
  }
}
