---
paths:
  - "lib/features/**/presentation/**"
  - "lib/features/**/domain/**"
---

# 위젯 & 상태 관리 — Widget 분리 · ConsumerWidget · 라이프사이클

## Widget 선택 결정 트리

```
상태가 필요한가?
├── 아니오 → StatelessWidget 또는 ConsumerWidget
│   └── Provider 구독 필요? → ConsumerWidget
└── 예 (로컬 상태: 텍스트 컨트롤러, 애니메이션, 포커스)
    └── ConsumerStatefulWidget
        └── dispose()에서 반드시 cleanup!
```

## ConsumerWidget 패턴

```dart
class SecretDetail extends ConsumerWidget {
  const SecretDetail({super.key, required this.secretId});
  final int secretId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secret = ref.watch(secretByIdProvider(secretId));
    return secret.when(
      data: (data) => _buildContent(data),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

## ConsumerStatefulWidget 패턴

```dart
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  late final TextEditingController _passwordController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _passwordController.dispose();  // 필수!
    _focusNode.dispose();           // 필수!
    super.dispose();
  }
}
```

## 위젯 분리 규칙

- **80줄 초과** → 별도 위젯으로 추출
- **반복 패턴 3회** → 재사용 위젯 생성
- **const 생성자** 가능하면 항상 사용 (리빌드 방지)
- **Key 사용**: `ValueKey` / `ObjectKey` (리스트에서 인덱스 단독 금지)

```dart
// ✅ ValueKey 사용
ListView.builder(
  itemBuilder: (_, i) => SecretListItem(
    key: ValueKey(secrets[i].id),
    secret: secrets[i],
  ),
)

// ❌ 인덱스 단독 사용 금지
ListView.builder(
  itemBuilder: (_, i) => SecretListItem(secret: secrets[i]),
)
```

## AsyncValue 패턴

```dart
// ✅ when으로 모든 상태 처리
asyncValue.when(
  data: (data) => DataWidget(data),
  loading: () => const LoadingIndicator(),
  error: (error, stack) => ErrorWidget(error.toString()),
);

// ✅ 조건부 로딩 표시
if (asyncValue.isLoading) return const Shimmer();
final data = asyncValue.valueOrNull;
if (data == null) return const EmptyState();
```

## dispose() 정리 필수 목록

| 리소스 | dispose 호출 |
|--------|-------------|
| `TextEditingController` | `.dispose()` |
| `FocusNode` | `.dispose()` |
| `AnimationController` | `.dispose()` |
| `ScrollController` | `.dispose()` |
| `StreamSubscription` | `.cancel()` |
| `Timer` | `.cancel()` |

## 폼 패턴

```dart
// GlobalKey<FormState> 사용
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(children: [
    TextFormField(
      validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
    ),
    ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          // 제출 처리
        }
      },
    ),
  ]),
)
```

## 키보드 단축키

```dart
// macOS 단축키 바인딩
CallbackShortcuts(
  bindings: {
    const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _createNew,
    const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _openSearch,
  },
  child: Focus(autofocus: true, child: /* ... */),
)
```

## 접근성

```dart
// 아이콘 버튼: Semantics 필수
Semantics(
  label: '새 시크릿 추가',
  child: IconButton(
    icon: const Icon(LucideIcons.plus),
    onPressed: _addSecret,
  ),
)

// 텍스트 대비: 최소 4.5:1 (일반), 3:1 (큰 텍스트)
// 터치 타겟: 최소 44x44
SizedBox(
  width: 44, height: 44,
  child: IconButton(/* ... */),
)
```

## 안티패턴

| 안티패턴 | 올바른 접근 |
|---------|-----------|
| `setState` 남발 | Riverpod Provider 사용 |
| build()에서 ref.read() | ref.watch() 사용 |
| 콜백에서 ref.watch() | ref.read() 사용 |
| dispose() 없이 Controller 사용 | 반드시 dispose() 호출 |
| 위젯 내 비즈니스 로직 | Domain 계층 (Notifier/Provider)로 분리 |
| 하드코딩 색상 | AppColors / Theme 사용 |
| `MediaQuery.of()` 남용 | LayoutBuilder 또는 Theme 활용 |
