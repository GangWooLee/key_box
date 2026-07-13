import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/core/database/database.dart';
import 'package:key_box/core/theme/app_theme.dart';

/// Golden test infrastructure for the V9 design work.
///
/// The default `flutter_test` binding renders every glyph with the Ahem
/// placeholder font, which makes typography-level design review impossible.
/// These helpers load the app's real bundled fonts (plus the Lucide icon
/// font) so golden PNGs capture what the app actually looks like.
///
/// Goldens are a LOCAL design-review tool: real-font rasterisation is
/// sensitive to the host OS version, so every golden test is tagged
/// `golden` and excluded from CI (see `dart_test.yaml` / `.github/ci.yml`).

// ─── Fixed viewports ───

/// Common golden viewports (logical pixels). Device pixel ratio is pinned to
/// 1.0 in [pumpGolden] so the emitted PNG dimensions equal these sizes.
abstract final class GoldenSizes {
  /// Full macOS desktop window for the 3-column dashboard.
  static const desktop = Size(1440, 900);

  /// Centered auth/onboarding cards (unlock, setup, vault error, onboarding).
  static const authCard = Size(480, 860);

  /// Centered create/edit secret sheet modal (+ scrim).
  static const modal = Size(760, 720);

  /// The 340px detail panel in isolation.
  static const detailPanel = Size(340, 720);
}

// ─── Real font loading ───

/// App font families (from `pubspec.yaml`) plus the Lucide icon font.
///
/// Lucide declares `fontPackage: 'lucide_icons'`, so its effective family is
/// prefixed `packages/lucide_icons/Lucide` — that prefixed name is what the
/// rendered `IconData` references, and therefore what [FontLoader] must use.
const Map<String, List<String>> _fontAssets = {
  'IBM Plex Sans': [
    'assets/fonts/IBMPlexSans-Regular.ttf',
    'assets/fonts/IBMPlexSans-Medium.ttf',
    'assets/fonts/IBMPlexSans-SemiBold.ttf',
  ],
  'IBM Plex Mono': [
    'assets/fonts/IBMPlexMono-Regular.ttf',
    'assets/fonts/IBMPlexMono-Medium.ttf',
    'assets/fonts/IBMPlexMono-SemiBold.ttf',
  ],
  'packages/lucide_icons/Lucide': ['packages/lucide_icons/assets/lucide.ttf'],
};

bool _fontsLoaded = false;

/// Loads the real bundled fonts into the test font system. Idempotent — safe
/// to call at the start of every golden test.
Future<void> loadTestFonts() async {
  if (_fontsLoaded) return;
  for (final entry in _fontAssets.entries) {
    final loader = FontLoader(entry.key);
    for (final asset in entry.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

// ─── Pump helper ───

/// Pumps [child] inside a themed [MaterialApp] at a fixed [size] with real
/// fonts loaded and a 1.0 device pixel ratio (so the golden PNG dimensions
/// equal [size]). Restores the surface size / DPR on teardown.
///
/// Does NOT settle animations — the caller decides how to advance frames
/// (screens with a `CircularProgressIndicator` must use `pump()` with a fixed
/// duration rather than `pumpAndSettle()`, which would time out).
Future<void> pumpGolden(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.dark,
}) async {
  await loadTestFonts();

  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: child,
      ),
    ),
  );
}

// ─── Deterministic test data ───

/// Convenience constructor for a [Folder] used in dashboard goldens.
/// Fixed timestamps keep the golden deterministic.
Folder makeTestFolder({
  int id = 1,
  int vaultId = 1,
  int? parentId,
  String name = 'Folder',
  String icon = 'folder',
  int position = 0,
  int secretsCount = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final fixed = DateTime.utc(2026, 1, 1);
  return Folder(
    id: id,
    vaultId: vaultId,
    parentId: parentId,
    name: name,
    icon: icon,
    position: position,
    secretsCount: secretsCount,
    createdAt: createdAt ?? fixed,
    updatedAt: updatedAt ?? fixed,
  );
}
