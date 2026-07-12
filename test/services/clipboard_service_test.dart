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
  });
}
