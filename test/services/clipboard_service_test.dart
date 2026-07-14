import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/services/clipboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClipboardService', () {
    late ClipboardService service;

    setUp(() {
      service = ClipboardService();
    });

    tearDown(() {
      service.dispose();
    });

    test('can be created and disposed', () {
      expect(service, isA<ClipboardService>());
      service.dispose();
    });

    test('dispose can be called multiple times safely', () {
      service.dispose();
      service.dispose();
    });

    test('copyWithAutoClear completes without error', () async {
      // In test environment, Clipboard.setData may not persist,
      // but the method should complete without throwing.
      await service.copyWithAutoClear('test-secret');
    });

    test(
      'copyWithAutoClear fires onCopy so the UI can start the countdown',
      () async {
        var copies = 0;
        final s = ClipboardService(onCopy: () => copies++);
        addTearDown(s.dispose);

        await s.copyWithAutoClear('secret');
        expect(copies, 1);

        // A second copy re-arms the countdown (fires again).
        await s.copyWithAutoClear('another');
        expect(copies, 2);
      },
    );
  });
}
