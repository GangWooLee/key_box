# Feature Development Workflow

> Agent OS 스타일 워크플로우 - 새 기능 개발 시 따라야 할 단계별 프로세스

## 워크플로우 개요

```
┌─────────────────────────────────────────────────────────────────┐
│  1. 요구사항 분석  →  2. 설계  →  3. 구현  →  4. 테스트  →  5. 리뷰  │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: 요구사항 분석

### 1.1 기능 정의
```markdown
## 기능명: [기능 이름]

### 목적
- 이 기능이 해결하는 문제는 무엇인가?
- 사용자에게 어떤 가치를 제공하는가?

### 사용자 스토리
- As a [사용자 유형], I want to [행동], so that [목적]

### 수락 기준 (Acceptance Criteria)
- [ ] 기준 1
- [ ] 기준 2
- [ ] 기준 3

### 제약 조건
- 기술적 제약
- 비즈니스 제약
- 시간 제약
```

### 1.2 기존 코드베이스 분석
```bash
# 관련 파일 탐색
# 1. 라우터 확인
cat lib/core/router/app_router.dart

# 2. 관련 도메인 확인
ls lib/features/

# 3. 관련 DB 테이블 확인
ls lib/core/database/

# 4. 관련 Provider 확인
ls lib/features/*/domain/

# 5. 테스트 확인
ls test/features/ test/core/
```

### 1.3 영향 범위 파악
```markdown
### 영향받는 파일들
- DB 테이블: lib/core/database/database.dart
- DAO: lib/core/database/daos/xxx_dao.dart
- Provider: lib/features/xxx/domain/xxx_providers.dart
- 상태: lib/features/xxx/domain/xxx_state.dart
- 화면: lib/features/xxx/presentation/screens/xxx_screen.dart
- 위젯: lib/features/xxx/presentation/widgets/xxx_widget.dart
- 테스트: test/features/xxx/

### 의존성
- 이 기능이 의존하는 기존 기능
- 이 기능에 의존하게 될 기능

### 잠재적 사이드 이펙트
- 기존 기능에 미치는 영향
- 성능 영향 (Widget rebuild 범위)
- 보안 고려사항 (암호화, SQLCipher)
```

## Phase 2: 설계

### 2.1 데이터 모델 설계
```dart
// Drift 테이블 스키마
// lib/core/database/database.dart

/// secrets 테이블
///   - id: integer (PK, autoIncrement)
///   - folderId: integer (FK -> folders)
///   - name: text (NOT NULL)
///   - encryptedValue: blob (NOT NULL)
///   - category: text (NOT NULL, default: 'credential')
///   - createdAt, updatedAt: dateTime

class Secrets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get folderId => integer().nullable().references(Folders, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BlobColumn get encryptedValue => blob()();
  TextColumn get category => text().withDefault(const Constant('credential'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

### 2.2 상태 설계
```dart
// sealed class로 상태 모델링
// lib/features/xxx/domain/xxx_state.dart

sealed class XxxState {
  const XxxState();
}

class XxxInitial extends XxxState {
  const XxxInitial();
}

class XxxLoading extends XxxState {
  const XxxLoading();
}

class XxxLoaded extends XxxState {
  final List<XxxData> items;
  const XxxLoaded(this.items);
}

class XxxError extends XxxState {
  final String message;
  const XxxError(this.message);
}
```

### 2.3 UI 설계 (Widget 명세)
```markdown
### 컴포넌트 명세

#### XxxListWidget
- 위치: lib/features/xxx/presentation/widgets/xxx_list.dart
- Props:
  - items: List<XxxData>
  - onSelect: ValueChanged<XxxData>
- 디자인:
  - Material 3 Card + ListTile
  - lucide_icons 아이콘 사용
  - 앱 테마 준수 (AppTheme)

#### XxxFormWidget
- 위치: lib/features/xxx/presentation/widgets/xxx_form.dart
- 필드: name (TextFormField), value (TextFormField), category (DropdownButton)
- 버튼: 저장 (FilledButton), 취소 (OutlinedButton)
- Validation: FormKey + TextFormField validator
```

### 2.4 Provider 설계
```markdown
### XxxNotifier
- extends: StateNotifier<XxxState>
- 의존성: XxxDao, EncryptionService
- 메서드:
  - loadItems(): 전체 목록 로드
  - createItem(name, value): 새 항목 생성 (암호화)
  - updateItem(id, name, value): 항목 수정
  - deleteItem(id): 항목 삭제
```

## Phase 3: 구현

### 3.1 구현 순서 (권장)
```
1. Drift 테이블 정의 + 코드 생성
2. DAO 작성 (데이터 접근 계층)
3. sealed class 상태 정의
4. StateNotifier + Provider 작성
5. 화면 (Screen) 위젯 작성
6. 하위 위젯 (Widget) 작성
7. GoRouter 라우트 등록
8. 테스트 작성 + 리팩토링
```

### 3.2 TDD 방식 (권장)
```dart
// 1. 실패하는 테스트 작성
test('should create item with valid data', () async {
  final container = ProviderContainer(overrides: [
    xxxDaoProvider.overrideWithValue(mockDao),
  ]);

  when(() => mockDao.insertItem(any()))
      .thenAnswer((_) async => 1);

  final notifier = container.read(xxxProvider.notifier);
  await notifier.createItem('Test', 'Value');

  final state = container.read(xxxProvider);
  expect(state, isA<XxxLoaded>());
});

// 2. 테스트를 통과하는 최소 코드 작성
Future<void> createItem(String name, String value) async {
  final encrypted = _encryption.encrypt(value);
  await _dao.insertItem(XxxCompanion(
    name: Value(name),
    encryptedValue: Value(encrypted),
  ));
  await loadItems();
}

// 3. 리팩토링
```

### 3.3 체크리스트
```markdown
#### Database (Drift)
- [ ] 테이블 정의 (database.dart)
- [ ] 코드 생성 실행 (build_runner)
- [ ] DAO 작성 (CRUD 메서드)
- [ ] 인덱스 설정

#### Domain (Provider/State)
- [ ] sealed class 상태 정의
- [ ] StateNotifier 작성
- [ ] Provider 등록
- [ ] 에러 핸들링 (try/catch → Error state)

#### Presentation (Widget)
- [ ] Screen 위젯 (ConsumerWidget/ConsumerStatefulWidget)
- [ ] ref.watch로 상태 구독
- [ ] Material 3 테마 준수
- [ ] lucide_icons 아이콘 사용
- [ ] 로딩/에러/빈 상태 처리
- [ ] const 생성자 활용

#### Router
- [ ] GoRoute 등록 (route_names.dart)
- [ ] redirect 조건 확인

#### 암호화 (해당 시)
- [ ] EncryptionService 연동
- [ ] 암호화/복호화 테스트
```

## Phase 4: 테스트

### 4.1 테스트 작성 순서
```
1. 단위 테스트 (DAO, Encryption, 유틸리티)
2. Provider 테스트 (StateNotifier + ProviderContainer)
3. Widget 테스트 (ProviderScope + pumpWidget)
4. 통합 테스트 (in-memory Drift DB)
```

### 4.2 테스트 실행
```bash
# 전체 테스트
flutter test

# 관련 테스트만
flutter test test/features/xxx/
flutter test test/core/database/

# 커버리지 포함
flutter test --coverage

# Drift 코드 생성 (테이블 변경 시)
dart run build_runner build --delete-conflicting-outputs
```

### 4.3 수동 테스트 체크리스트
```markdown
#### 기능 테스트
- [ ] 정상 동작 (Happy Path)
- [ ] 에러 케이스 (잘못된 입력)
- [ ] Edge Case (빈 데이터, 최대 길이)
- [ ] 인증 없이 접근 시도 (GoRouter redirect)
- [ ] 마스터 비밀번호 잠금 후 재접근

#### macOS 데스크톱 테스트
- [ ] 윈도우 리사이즈 대응
- [ ] 키보드 단축키 동작
- [ ] 메뉴바 연동

#### 상태 관리 테스트
- [ ] Provider dispose 시 리소스 정리
- [ ] 상태 전환 (Loading → Loaded → Error)
- [ ] Hot restart 후 상태 복원
```

## Phase 5: 코드 리뷰

### 5.1 셀프 리뷰 체크리스트
```markdown
#### 코드 품질
- [ ] dart analyze 통과
- [ ] dart fix --dry-run 이슈 없음
- [ ] 명확한 변수/메서드 이름
- [ ] const 생성자 최대 활용
- [ ] 불필요한 rebuild 방지 (select 활용)

#### 보안
- [ ] 암호화 키 하드코딩 없음
- [ ] SQLCipher 연동 확인
- [ ] 민감 데이터 메모리 정리
- [ ] Entitlements 설정 확인 (macOS)

#### 성능
- [ ] 불필요한 Widget rebuild 없음
- [ ] const 위젯 활용
- [ ] Riverpod select로 세밀한 구독
- [ ] 대량 데이터 처리 시 페이지네이션

#### 테스트
- [ ] 핵심 기능 테스트 있음
- [ ] Edge Case 테스트 있음
- [ ] 모든 테스트 통과 (flutter test)
```

### 5.2 커밋 및 PR
```bash
# 브랜치 생성
git checkout -b feature/xxx-crud

# 커밋 (기능별로 분리)
git add lib/core/database/
git commit -m "feat: Xxx Drift 테이블 + DAO 추가"

git add lib/features/xxx/domain/
git commit -m "feat: Xxx Provider + 상태 관리 구현"

git add lib/features/xxx/presentation/
git commit -m "feat: Xxx 화면 + 위젯 구현"

# PR 생성
gh pr create --title "feat: Xxx 기능 구현" --body "..."
```

## 빠른 참조 명령어

```bash
# Drift 코드 생성
dart run build_runner build --delete-conflicting-outputs

# 정적 분석
dart analyze

# 자동 수정
dart fix --apply

# 테스트 실행
flutter test

# macOS 빌드
flutter build macos --debug

# 앱 실행
flutter run -d macos
```
