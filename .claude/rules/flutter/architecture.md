---
paths:
  - "lib/core/**"
  - "lib/features/**"
  - "lib/services/**"
---

# Flutter 아키텍처 원칙 — 계층 분리 · Riverpod · 설계 패턴

## Feature-First 디렉토리 구조

```
lib/
├── core/                    # 공유 인프라 (전 feature 공통)
│   ├── constants/           # 앱 상수, 암호화 상수, 타입 정의
│   ├── database/            # Drift 테이블, DAO, database.dart
│   ├── encryption/          # 암호화 서비스 (AES-GCM, PBKDF2, 마스터키)
│   ├── router/              # GoRouter 설정, 라우트 이름
│   ├── theme/               # AppTheme, colors, typography, ThemeProvider
│   └── utils/               # Result, Debouncer, DateFormatters
├── features/                # 기능 모듈 (독립적)
│   ├── auth/
│   │   ├── domain/          # AuthNotifier, AuthState (비즈니스 로직)
│   │   └── presentation/    # screens/, widgets/ (UI)
│   ├── secrets/
│   │   ├── domain/          # SecretsProviders (Riverpod)
│   │   └── presentation/    # DashboardScreen, Sidebar, SecretDetail
│   └── audit/
│       └── presentation/    # AuditLogScreen
├── services/                # 앱 수준 서비스 (WindowState, AutoLock, Clipboard)
└── main.dart                # 앱 진입점
```

## 계층 분리 (Presentation → Domain → Data)

```
Presentation (screens, widgets)
     ↓ ref.watch / ref.read
Domain (providers, notifiers, states)
     ↓
Data (database, encryption, services)
```

의존성은 항상 안쪽(Data)을 향한다. Data 계층은 Presentation을 모른다.

| 계층 | 책임 | 금지 |
|------|------|------|
| **Presentation** | UI 렌더링, 사용자 입력, 내비게이션 | 직접 DB 접근, 비즈니스 로직 |
| **Domain** | 비즈니스 상태 관리, 프로바이더 정의 | UI 위젯, BuildContext 의존 |
| **Data** | DB 쿼리, 암호화, 외부 서비스 | UI 또는 Domain 역참조 |

## Riverpod 패턴

### Provider 사용 가이드

| Provider 유형 | 용도 | 예시 |
|--------------|------|------|
| `Provider` | 의존성 주입, 계산된 값 | `databaseProvider`, `encryptionServiceProvider` |
| `StateNotifierProvider` | 복잡한 상태 머신 | `authNotifierProvider` (AuthState 관리) |
| `FutureProvider` | 비동기 1회 로드 | `secretsListProvider` |
| `StreamProvider` | 실시간 데이터 관찰 | `watchSecrets()` |

### ref 사용 규칙

```dart
// build() 내부: watch (반응형 구독)
final state = ref.watch(authNotifierProvider);

// 콜백/이벤트 핸들러: read (1회 읽기)
onPressed: () => ref.read(authNotifierProvider.notifier).unlock(password)

// 절대 금지: build() 내부에서 ref.read()
// 절대 금지: 콜백에서 ref.watch()
```

## Sealed Class 상태 패턴

```dart
// 상태 정의 — 모든 가능한 상태를 열거
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthFirstRun extends AuthState {}
class AuthLocked extends AuthState {}
class AuthUnlocked extends AuthState { final Uint8List masterKey; }

// switch로 모든 상태 처리 (컴파일 타임 완전성 체크)
switch (state) {
  case AuthInitial(): return LoadingScreen();
  case AuthFirstRun(): return SetupScreen();
  case AuthLocked(): return UnlockScreen();
  case AuthUnlocked(): return DashboardScreen();
}
```

## Result 패턴

`core/utils/result.dart` 활용. 예외 대신 명시적 성공/실패.

```dart
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> { final T value; }
class Failure<T> extends Result<T> { final String message; }

// 사용
final result = await encryptionService.encrypt(data);
switch (result) {
  case Success(value: final encrypted): // 성공 처리
  case Failure(message: final msg): // 에러 표시
}
```

## 설계 패턴 선택 가이드

| 신호 | 패턴 |
|------|------|
| 복잡한 상태 전이 (3+ 상태) | StateNotifier + Sealed Class |
| 단순 on/off 상태 | StateProvider |
| DB CRUD 조합 | DAO 메서드 + FutureProvider |
| 위젯 80줄+ | 별도 위젯으로 추출 |
| 3+ 프로바이더 조합 | 중간 Provider로 합성 |
| 비동기 초기화 | FutureProvider + AsyncValue |

## SOLID 원칙 (Flutter 적용)

### S — 단일 책임
- 1 위젯 = 1 UI 관심사
- 1 Notifier = 1 상태 도메인
- DAO는 테이블별 분리

### O — 개방/폐쇄
- 새 SecretType 추가 시 기존 코드 수정 최소화 (enum + switch)
- Theme 확장: `AppTheme.light()` / `AppTheme.dark()` 패턴

### D — 의존성 역전
- Riverpod Provider를 통한 의존성 주입
- 테스트에서 `overrides:` 로 교체 가능

## 네이밍 규칙

```dart
// 파일: snake_case.dart
auth_notifier.dart, secret_dao.dart

// 클래스: PascalCase
class AuthNotifier extends StateNotifier<AuthState> {}

// 변수/함수: camelCase
final masterKey = await deriveMasterKey(password);

// 상수: camelCase 또는 SCREAMING_SNAKE_CASE
const maxPasswordAttempts = 10;
const kDatabaseFileName = 'key_box.db';

// Provider: camelCase + Provider 접미사
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// Private: _ 접두사
void _handleSubmit() {}
```

## 복잡도 제한

| 항목 | 최대값 | 초과 시 조치 |
|------|-------|------------|
| 위젯 build() | 80줄 | 위젯 추출 |
| 클래스 길이 | 200줄 | 분리 |
| 조건문 깊이 | 3단계 | Early return |
| 생성자 파라미터 | 5개 | 객체로 묶기 |
