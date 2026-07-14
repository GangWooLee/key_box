import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/services/clipboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureChannel = MethodChannel('keybox/secure_clipboard');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('ClipboardService', () {
    late ClipboardService service;

    setUp(() {
      service = ClipboardService();
    });

    tearDown(() {
      service.dispose();
      messenger.setMockMethodCallHandler(secureChannel, null);
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

    test('writes through the concealed pasteboard channel', () async {
      // 보안 CSO F6: the secret must go out via the native ConcealedType
      // bridge, not the plain system clipboard — so clipboard managers skip it.
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(secureChannel, (call) async {
        calls.add(call);
        return null;
      });

      await service.copyWithAutoClear('top-secret');

      expect(calls, hasLength(1));
      expect(calls.single.method, 'copyConcealed');
      expect((calls.single.arguments as Map)['value'], 'top-secret');
    });

    test(
      'falls back to the plain clipboard when the channel is absent',
      () async {
        // No mock handler on the secure channel → MissingPluginException →
        // graceful fallback. onCopy must still fire (the countdown still runs).
        var copies = 0;
        final s = ClipboardService(onCopy: () => copies++);
        addTearDown(s.dispose);

        await s.copyWithAutoClear('secret'); // must not throw
        expect(copies, 1);
      },
    );
  });
}
