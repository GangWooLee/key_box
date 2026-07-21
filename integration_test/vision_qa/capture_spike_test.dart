// VISION-QA Phase 0 spike (kept as the capture pipeline's smoke test) —
// proves RepaintBoundary→PNG capture works in the REAL macOS app runtime.
// Capture mechanics live in vision_capture.dart (shared helper).
//
// Run ONLY on a real macOS device:
//   flutter test integration_test/vision_qa/capture_spike_test.dart -d macos
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_box/app.dart';
import 'package:key_box/core/database/vault_paths.dart';
import 'package:path_provider/path_provider.dart';

import 'vision_capture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpVault;
  late Future<Directory> Function() previousSupportDir;

  setUp(() async {
    // Vault hygiene: NEVER touch the real vault — captures must not be able
    // to contain real user secrets.
    final base = await getApplicationSupportDirectory();
    tmpVault = Directory(
      '${base.path}/vision_qa_spike_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    previousSupportDir = VaultPaths.supportDir;
    VaultPaths.supportDir = () async => tmpVault;
  });

  tearDown(() {
    VaultPaths.supportDir = previousSupportDir;
    if (tmpVault.existsSync()) tmpVault.deleteSync(recursive: true);
  });

  testWidgets('captures the real app UI to a PNG file', (tester) async {
    await tester.pumpWidget(
      visionCaptureRoot(child: const ProviderScope(child: KeyBoxApp())),
    );
    await pumpBounded(tester);

    final file = await captureVision(tester, 'spike', 'spike');
    expect(file.existsSync(), isTrue);
  });
}
