---
description: "TDD 워크플로우를 시작합니다. RED → GREEN → REFACTOR 사이클로 테스트 주도 개발을 진행합니다."
---

# TDD 워크플로우 (Test-Driven Development)

엄격한 **RED → GREEN → REFACTOR** 사이클을 따라 구현합니다.

## 프로세스

### 1단계: 인터페이스 설계
- Drift 테이블 스키마, DAO 인터페이스, Provider 인터페이스를 먼저 정의
- 필요한 테이블/컬럼 파악
- sealed class로 상태 모델링 설계

### 2단계: 테스트 먼저 작성 (RED)
- 구현 전에 실패하는 테스트를 작성
- `flutter test` 로 실패 확인
- flutter_test + mocktail + ProviderContainer 패턴 사용

### 3단계: 최소 구현 (GREEN)
- 테스트를 통과하는 **최소한의** 코드만 작성
- 과잉 설계 금지

### 4단계: 리팩토링 (REFACTOR)
- 테스트가 통과하는 상태에서 코드 개선
- 중복 제거, 네이밍 개선

### 5단계: 커버리지 확인
- 암호화 (Encryption/KeyDerivation): **100%** 커버리지
- 인증 (Auth): **100%** 커버리지
- Provider/Notifier: **80%** 이상
- Widget: **60%** 이상

## 테스트 유형

| 유형 | 도구 | 위치 |
|------|------|------|
| 단위 테스트 (core/domain) | flutter_test + mocktail | `test/core/`, `test/features/*/domain/` |
| Provider 테스트 | ProviderContainer | `test/features/*/domain/` |
| Widget 테스트 | flutter_test + ProviderScope | `test/features/*/presentation/` |
| 통합 테스트 | flutter_test + in-memory Drift | `test/integration/` |

## TDD 예시

### RED: 실패하는 테스트 작성

```dart
// test/features/secrets/domain/secrets_providers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockSecretDao extends Mock implements SecretDao {}

void main() {
  group('SecretsNotifier', () {
    late ProviderContainer container;
    late MockSecretDao mockDao;

    setUp(() {
      mockDao = MockSecretDao();
      container = ProviderContainer(overrides: [
        secretDaoProvider.overrideWithValue(mockDao),
      ]);
    });

    tearDown(() => container.dispose());

    test('loadSecrets returns list from DAO', () async {
      when(() => mockDao.getAllSecrets())
          .thenAnswer((_) async => [testSecret]);

      final notifier = container.read(secretsProvider.notifier);
      await notifier.loadSecrets();

      final state = container.read(secretsProvider);
      expect(state, isA<SecretsLoaded>());
    });
  });
}
```

### GREEN: 최소 구현

```dart
// lib/features/secrets/domain/secrets_providers.dart
class SecretsNotifier extends StateNotifier<SecretsState> {
  final SecretDao _dao;
  SecretsNotifier(this._dao) : super(const SecretsInitial());

  Future<void> loadSecrets() async {
    final secrets = await _dao.getAllSecrets();
    state = SecretsLoaded(secrets);
  }
}
```

### REFACTOR: 개선

```dart
// 에러 핸들링 추가, sealed class 활용
Future<void> loadSecrets() async {
  state = const SecretsLoading();
  try {
    final secrets = await _dao.getAllSecrets();
    state = SecretsLoaded(secrets);
  } catch (e) {
    state = SecretsError(e.toString());
  }
}
```

## TDD 적용 대상
- 새 기능 / Drift 테이블 / Provider / Widget
- 버그 수정 (실패 테스트 먼저 → 수정)
- 리팩토링
- 핵심 비즈니스 로직 (암호화, 인증)

## 체크리스트
- ✅ 테스트를 먼저 작성했는가
- ✅ `flutter test`로 실패를 확인했는가
- ✅ 최소한의 변경만 했는가
- ❌ 구현 후 테스트 작성 금지
- ❌ 테스트 실행 생략 금지
- ❌ 과도한 모킹 금지 (in-memory Drift DB 우선)

## Drift 코드 생성 주의
테이블 스키마 변경 후 반드시 코드 생성 재실행:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 관련 워크플로우
- `/verify` — 구현 후 종합 검증
- `/code-review` — 코드 리뷰
