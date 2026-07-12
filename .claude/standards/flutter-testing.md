# Flutter Testing Standard — 상세 테스트 패턴

Rules 파일의 원칙을 코드 예시와 함께 상세 설명합니다.

---

## 1. Unit 테스트 패턴

### 암호화 서비스 테스트

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';

void main() {
  group('KeyDerivationService', () {
    late KeyDerivationService service;

    setUp(() {
      service = KeyDerivationService();
    });

    test('generates salt of correct length', () {
      final salt = service.generateSalt();
      expect(salt.length, equals(32));
    });

    test('derives 32-byte key from password and salt', () {
      final salt = service.generateSalt();
      final key = service.deriveKey(password: 'testPassword123', salt: salt);
      expect(key.length, equals(32));
    });

    test('same input produces same key (deterministic)', () {
      final salt = service.generateSalt();
      final key1 = service.deriveKey(password: 'password', salt: salt);
      final key2 = service.deriveKey(password: 'password', salt: salt);
      expect(key1, equals(key2));
    });

    test('different salts produce different keys', () {
      final salt1 = service.generateSalt();
      final salt2 = service.generateSalt();
      final key1 = service.deriveKey(password: 'password', salt: salt1);
      final key2 = service.deriveKey(password: 'password', salt: salt2);
      expect(key1, isNot(equals(key2)));
    });
  });
}
```

### Result 타입 테스트

```dart
void main() {
  group('Result', () {
    test('Success holds data', () {
      const result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, equals(42));
    });

    test('Failure holds message', () {
      const result = Failure<int>('Something went wrong');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.message, equals('Something went wrong'));
    });
  });
}
```

---

## 2. Drift Database 테스트 패턴

### In-Memory DB 설정

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SecretDao', () {
    late int vaultId;
    late int folderId;

    setUp(() async {
      // 테스트용 vault와 folder 생성
      final vault = await db.vaultDao.create(name: 'Test Vault');
      vaultId = vault.id;
      final folder = await db.folderDao.create(
        vaultId: vaultId, name: 'Default',
      );
      folderId = folder.id;
    });

    test('creates and retrieves a secret', () async {
      final secret = await db.secretDao.create(
        vaultId: vaultId,
        folderId: folderId,
        name: 'API Key',
        encryptedValue: Uint8List(32),
        encryptedValueIv: Uint8List(12),
        encryptedValueAuthTag: Uint8List(16),
      );

      expect(secret.id, isNonZero);
      expect(secret.name, equals('API Key'));

      final retrieved = await db.secretDao.getById(secret.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('API Key'));
    });

    test('search filters by name', () async {
      await db.secretDao.create(
        vaultId: vaultId, folderId: folderId, name: 'GitHub Token', ...
      );
      await db.secretDao.create(
        vaultId: vaultId, folderId: folderId, name: 'AWS Key', ...
      );

      final results = await db.secretDao.search(vaultId, 'GitHub');
      expect(results, hasLength(1));
      expect(results.first.name, equals('GitHub Token'));
    });
  });
}
```

---

## 3. Riverpod Provider 테스트 패턴

### ProviderContainer 사용

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthNotifier', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
      ]);
      addTearDown(container.dispose);
    });

    tearDown(() async {
      await db.close();
    });

    test('initializes to FirstRun when no config exists', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.initialize();
      expect(container.read(authProvider), isA<AuthFirstRun>());
    });

    test('setup creates vault and transitions to Unlocked', () async {
      final notifier = container.read(authProvider.notifier);
      await notifier.initialize();

      final error = await notifier.setup(
        password: 'TestPassword123',
        confirmation: 'TestPassword123',
      );

      expect(error, isNull);  // null = 성공
      expect(container.read(authProvider), isA<AuthUnlocked>());
    });

    test('lock transitions to Locked', () async {
      // setup first...
      final notifier = container.read(authProvider.notifier);
      await notifier.initialize();
      await notifier.setup(password: 'TestPassword123', confirmation: 'TestPassword123');

      notifier.lock();
      expect(container.read(authProvider), isA<AuthLocked>());
    });
  });
}
```

---

## 4. Widget 테스트 패턴

### 기본 위젯 테스트

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SetupScreen shows password fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SetupScreen()),
      ),
    );

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Create Vault'), findsOneWidget);
  });

  testWidgets('SetupScreen validates empty password', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SetupScreen()),
      ),
    );

    await tester.tap(find.text('Create Vault'));
    await tester.pumpAndSettle();

    expect(find.text('Min 8 chars'), findsOneWidget);
  });
}
```

### Provider Override 위젯 테스트

```dart
testWidgets('DashboardScreen shows secrets when unlocked', (tester) async {
  final mockDb = AppDatabase(NativeDatabase.memory());
  // ... seed test data

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        authProvider.overrideWith((ref) => TestAuthNotifier(
          AuthUnlocked(masterEncryptionKey: testKey, vaultId: 1),
        )),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('API Key'), findsOneWidget);
});
```

---

## 5. mocktail 패턴

### Mock 정의

```dart
import 'package:mocktail/mocktail.dart';

class MockEncryptionService extends Mock implements SecretEncryptionService {}
class MockDatabase extends Mock implements AppDatabase {}

// Fake 등록 (setUpAll에서)
setUpAll(() {
  registerFallbackValue(Uint8List(0));
});
```

### Mock 사용

```dart
setUp(() {
  mockEncryption = MockEncryptionService();

  when(() => mockEncryption.encrypt(
    plaintext: any(named: 'plaintext'),
    key: any(named: 'key'),
  )).thenReturn((
    ciphertext: Uint8List(48),
    iv: Uint8List(12),
    authTag: Uint8List(16),
  ));
});
```

---

## 6. 테스트 헬퍼

### test/helpers/test_helpers.dart

```dart
import 'package:drift/native.dart';
import 'package:key_box/core/database/database.dart';

AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

Uint8List createTestKey([int length = 32]) {
  return Uint8List(length);
}
```

### test/helpers/widget_test_helpers.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget wrapWithProviders(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}
```

---

## 7. CI 명령

```bash
# 전체 테스트
flutter test

# 특정 디렉토리
flutter test test/core/encryption/

# 특정 파일
flutter test test/core/encryption/key_derivation_service_test.dart

# 커버리지
flutter test --coverage
# 리포트 생성
genhtml coverage/lcov.info -o coverage/html

# 정적 분석
dart analyze

# 코드 품질 자동 수정
dart fix --apply

# Drift 코드 재생성 (테이블 변경 후)
dart run build_runner build --delete-conflicting-outputs
```

---

## 8. 테스트 체크리스트

### 새 기능 추가 시

- [ ] Unit: 비즈니스 로직 / 서비스 테스트
- [ ] Unit: Provider/Notifier 상태 전이 테스트
- [ ] Widget: 화면 렌더링 + 인터랙션 테스트
- [ ] Edge: 빈 상태, 에러 상태, 경계값
- [ ] `flutter test` 전체 통과
- [ ] `dart analyze` 경고 0건

### 버그 수정 시

- [ ] 재현 테스트 먼저 작성 (RED)
- [ ] 수정 후 통과 확인 (GREEN)
- [ ] 회귀 테스트 유지

### PR 전 체크

```bash
flutter test && dart analyze && echo "Ready for PR"
```
