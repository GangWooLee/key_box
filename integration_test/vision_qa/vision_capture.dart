// VISION-QA shared capture helper — RepaintBoundary→PNG for macOS
// integration tests.
//
// Why not `binding.takeScreenshot()`: the integration_test plugin ships no
// macOS native handler for the `captureScreenshot` channel (ios/ and android/
// only) → MissingPluginException. RepaintBoundary→`toImage()` is pure Flutter
// rendering, platform-independent.
//
// Sandbox: the app runs sandboxed, so PNGs are written INSIDE the app
// container (getApplicationSupportDirectory()/vision_qa/<scenario>/) and each
// capture prints a stable `[VISION_QA]` marker line with the absolute path —
// the /vision-qa skill greps these markers from test output and reads the
// files from outside the sandbox.
//
// Vault hygiene: scenario tests MUST redirect VaultPaths to a throwaway temp
// dir (see capture_spike_test.dart) so captures can never contain real user
// secrets.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

/// Root key the scenario must mount via [visionCaptureRoot].
final visionCaptureKey = GlobalKey(debugLabel: 'vision_qa_capture_root');

/// Wrap the app under test so [captureVision] can find the boundary.
Widget visionCaptureRoot({required Widget child}) =>
    RepaintBoundary(key: visionCaptureKey, child: child);

/// Bounded pumping — NOT pumpAndSettle: UnlockSweep/route transitions may
/// animate indefinitely (project-confirmed timeout trap).
Future<void> pumpBounded(
  WidgetTester tester, {
  int frames = 10,
  Duration step = const Duration(milliseconds: 200),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// Pumps until [finder] matches or [timeout] elapses (then fails). Use for
/// slow async transitions (e.g. PBKDF2 setup derivation takes seconds).
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('pumpUntil timeout ($timeout): $finder never matched');
}

/// Captures the current frame to
/// `<appSupport>/vision_qa/<scenario>/<name>.png`, prints the `[VISION_QA]`
/// marker line, and sanity-checks the PNG is not a blank frame.
Future<File> captureVision(
  WidgetTester tester,
  String scenario,
  String name,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(visionCaptureKey),
  );
  final image = await boundary.toImage(
    pixelRatio: tester.view.devicePixelRatio,
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  expect(byteData, isNotNull, reason: 'PNG encode returned null');

  final outDir = Directory(
    '${(await getApplicationSupportDirectory()).path}/vision_qa/$scenario',
  )..createSync(recursive: true);
  final file = File('${outDir.path}/$name.png');
  file.writeAsBytesSync(byteData!.buffer.asUint8List());

  // Stable marker — the /vision-qa skill greps this to locate captures.
  // ignore: avoid_print
  print(
    '[VISION_QA] screenshot: ${file.path} (${file.lengthSync()} bytes, '
    '${image.width}x${image.height})',
  );

  expect(
    file.lengthSync(),
    greaterThan(10 * 1024),
    reason: 'PNG suspiciously small — likely a blank/unpainted frame',
  );
  return file;
}
