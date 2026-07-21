---
paths:
  - "test/**"
---

# 테스팅 — flutter_test · mocktail · Drift in-memory

## 테스트 파일 구조

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:key_box/core/encryption/key_derivation_service.dart';

void main() {
  group('KeyDerivationService', () {
    late KeyDerivationService service;

    setUp(() {
      service = KeyDerivationService();
    });

    // ===== 정상 동작 =====
    test('derives key from password and salt', () async {
      final key = await service.deriveKey('password', salt);
      expect(key.length, equals(32));
    });

    // ===== 엣지 케이스 =====
    test('throws on empty password', () {
      expect(() => service.deriveKey('', salt), throwsArgumentError);
    });
  });
}
```

## 테스트 유형

| 유형 | 위치 | 도구 | 용도 |
|------|------|------|------|
| Unit | `test/core/`, `test/features/*/domain/` | `flutter_test` | 로직, 서비스, 프로바이더 |
| Widget | `test/features/*/presentation/` | `flutter_test` + `ProviderScope` | UI 컴포넌트 |
| Integration | `test/integration/` | `flutter_test` | E2E 시나리오 |

## Riverpod 테스트 패턴

```dart
// ProviderContainer로 프로바이더 독립 테스트
final container = ProviderContainer(overrides: [
  databaseProvider.overrideWithValue(testDatabase),
  encryptionServiceProvider.overrideWithValue(mockEncryption),
]);

addTearDown(container.dispose);

final notifier = container.read(authNotifierProvider.notifier);
await notifier.setup('password');
expect(container.read(authNotifierProvider), isA<AuthUnlocked>());
```

## Drift In-Memory DB 패턴

```dart
// 테스트용 인메모리 DB
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

setUp(() {
  database = createTestDatabase();
});

tearDown(() async {
  await database.close();
});
```

## mocktail 패턴

```dart
import 'package:mocktail/mocktail.dart';

class MockEncryptionService extends Mock implements SecretEncryptionService {}

setUp(() {
  mockEncryption = MockEncryptionService();
  when(() => mockEncryption.encrypt(any(), any()))
      .thenAnswer((_) async => Uint8List(32));
});
```

## Widget 테스트 패턴

```dart
testWidgets('shows unlock screen when locked', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => TestAuthNotifier(AuthLocked()),
        ),
      ],
      child: const MaterialApp(home: UnlockScreen()),
    ),
  );

  expect(find.text('비밀번호를 입력하세요'), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'password');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
});
```

## drift 스트림 × 위젯 테스트 — drain 필수 (3회 반복으로 승격, 2026-07-21)

위젯이 실 drift 스트림(StreamProvider → `watch*()`)을 watch하는 테스트는
**테스트 본문 끝에 반드시 `drainDriftTimers(tester)`** (공용 헬퍼,
`test/helpers/widget_test_helpers.dart`) 호출:

```dart
await drainDriftTimers(tester); // 트리 언마운트 + fake 시계 1s 전진
```

- 이유: 트리 해체 시 drift가 0-duration 정리 타이머(`markAsClosed`)를
  예약하는데, fake-async 시계가 멈춰 있으면 발화 불가 → ① `'!timersPending'`
  단언 실패("A Timer is still pending…") ② tearDown `db.close()` **행**
  (테스트당 ~10분 타임아웃).
- **증상이 '실패'가 아니라 '행/타임아웃'이면 이 클래스부터 의심**하라.
- 위젯에 drift StreamProvider watch를 새로 추가하면 그 위젯의 **기존 테스트
  전건**에 drain이 필요해진다 (2026-07-21 sheet_modal 10건 회귀 사례 —
  `docs/solutions/test-failures/` 참조).

## 금지 패턴

```dart
// ❌ sleep 사용 금지
await Future.delayed(Duration(seconds: 2));
expect(find.text('결과'), findsOneWidget);

// ✅ pumpAndSettle 또는 pump 사용
await tester.pumpAndSettle();
expect(find.text('결과'), findsOneWidget);

// ❌ 하드코딩 경로 → ✅ 테스트 헬퍼 사용
// ❌ 테스트 간 공유 상태 → ✅ setUp/tearDown으로 격리
```

## pumpAndSettle 주의사항

```dart
// pumpAndSettle은 모든 애니메이션이 끝날 때까지 대기
// 무한 애니메이션(CircularProgressIndicator)이 있으면 타임아웃!

// ✅ 타임아웃 지정
await tester.pumpAndSettle(const Duration(seconds: 5));

// ✅ 또는 pump로 특정 시간만 진행
await tester.pump(const Duration(milliseconds: 500));
```

## 커버리지 목표

| 영역 | 최소 커버리지 |
|------|-------------|
| Encryption (core/encryption/) | 100% |
| Auth (features/auth/domain/) | 100% |
| Database (core/database/) | 80% |
| Providers (features/*/domain/) | 80% |
| Widgets (features/*/presentation/) | 60% |
| Services (services/) | 70% |

## 테스트 실행

```bash
flutter test                              # 전체
flutter test test/core/                   # 특정 디렉토리
flutter test test/core/encryption/key_derivation_service_test.dart  # 특정 파일
flutter test --coverage                   # 커버리지 리포트
dart analyze                              # 정적 분석 (테스트 파일 포함)
```

## 테스트 헬퍼

`test/helpers/` 디렉토리에 공용 헬퍼 배치:
- `test_helpers.dart` — DB 생성, 공용 mock
- `widget_test_helpers.dart` — ProviderScope 래퍼, 테마 적용

## CI 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| `pumpAndSettle` 타임아웃 | 무한 애니메이션 | `pump()` + 특정 시간 |
| `MissingPluginException` | 네이티브 플러그인 미등록 | `TestWidgetsFlutterBinding.ensureInitialized()` |
| Drift 테스트 실패 | DB 미정리 | `tearDown`에서 `database.close()` |
| Provider 상태 누수 | Container 미정리 | `addTearDown(container.dispose)` |
