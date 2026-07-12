# Flutter Widgets Standard — UI 상세 구현 패턴

Rules 파일의 원칙을 코드 예시와 함께 상세 설명합니다.

---

## 1. 3-Column 대시보드 레이아웃 패턴

```dart
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (200px 고정)
          const SizedBox(width: 200, child: Sidebar()),

          // Table View (유동적)
          Expanded(child: SecretListView()),

          // Detail Panel (340px 고정)
          const SizedBox(width: 340, child: SecretDetail()),
        ],
      ),
    );
  }
}
```

### Sidebar 패턴

```dart
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final selectedFolder = ref.watch(selectedFolderProvider);

    return Container(
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 앱 제목
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Key Box', style: AppTypography.heading),
          ),

          // 폴더 목록
          Expanded(
            child: ListView.builder(
              itemCount: folders.length,
              itemBuilder: (_, i) => FolderListItem(
                key: ValueKey(folders[i].id),
                folder: folders[i],
                isSelected: folders[i].id == selectedFolder,
                onTap: () => ref.read(selectedFolderProvider.notifier)
                    .state = folders[i].id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 2. 커스텀 테마 패턴

### AppTheme 정의

```dart
class AppTheme {
  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.foregroundLight,
    ),
    textTheme: AppTypography.textTheme,
    inputDecorationTheme: _inputTheme(),
    elevatedButtonTheme: _buttonTheme(),
  );

  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.foregroundDark,
    ),
    textTheme: AppTypography.textTheme,
    inputDecorationTheme: _inputTheme(),
    elevatedButtonTheme: _buttonTheme(),
  );
}
```

### ThemeProvider (Riverpod)

```dart
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);  // 기본: 다크

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
```

### 앱 진입점에서 테마 적용

```dart
class KeyBoxApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

---

## 3. AppColors & Typography

```dart
// lib/core/theme/colors.dart
abstract class AppColors {
  // Primary (Olive Moss Green)
  static const primary = Color(0xFF283618);
  static const primaryMuted = Color(0xFF3A5A1C);

  // Background (Warm Dark)
  static const baseBg = Color(0xFF0C1108);
  static const surfaceDark = Color(0xFF111A0B);
  static const cardDark = Color(0xFF1A2712);

  // Foreground
  static const foregroundDark = Color(0xFFE8EDE3);
  static const mutedFg = Color(0xFF9CAF88);
  static const secondaryText = Color(0xFF7A8C6A);

  // Borders
  static const border = Color.fromRGBO(180, 200, 160, 0.1);
}

// lib/core/theme/typography.dart
abstract class AppTypography {
  static const heading = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3,
  );
  static const body = TextStyle(fontSize: 14, height: 1.5);
  static const caption = TextStyle(fontSize: 12, height: 1.4);
}
```

---

## 4. Form 패턴

### 설정 화면 (비밀번호 입력)

```dart
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final error = await ref.read(authProvider.notifier).setup(
      password: _passwordController.text,
      confirmation: _confirmController.text,
    );

    if (mounted) {
      setState(() { _isLoading = false; _error = error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 chars',
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                validator: (v) => v == _passwordController.text ? null : 'Must match',
                decoration: const InputDecoration(labelText: 'Confirm'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create Vault'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 5. Dialog/Modal 패턴

```dart
// 확인 다이얼로그
Future<bool?> showDeleteConfirmation(BuildContext context, String itemName) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Secret'),
      content: Text('Are you sure you want to delete "$itemName"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
```

---

## 6. 키보드 단축키

```dart
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () => _createNew(ref),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () => _openSearch(ref),
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true): () => _lock(ref),
        const SingleActivator(LogicalKeyboardKey.comma, meta: true): () => _openSettings(ref),
      },
      child: Focus(
        autofocus: true,
        child: /* dashboard content */,
      ),
    );
  }
}
```

---

## 7. macOS 특화 패턴

### window_manager 초기화

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(900, 600),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: KeyBoxApp()));
}
```

### 타이틀 바 통합

```dart
// macOS 네이티브 타이틀 바 대체
class CustomTitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 38,
        color: AppColors.surfaceDark,
        child: const Row(
          children: [
            SizedBox(width: 78),  // 신호등 버튼 공간
            Text('Key Box', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. 접근성 패턴

```dart
// Semantics로 스크린 리더 지원
Semantics(
  label: 'Secret: $secretName',
  child: ListTile(
    title: Text(secretName),
    subtitle: Text(serviceName ?? ''),
    trailing: IconButton(
      icon: const Icon(LucideIcons.copy),
      tooltip: 'Copy to clipboard',  // 툴팁 = 접근성
      onPressed: _copyToClipboard,
    ),
  ),
)
```

---

## 9. 위젯 추출 가이드

### 추출 전 (80줄+ build 메서드)

```dart
// ❌ 너무 긴 build 메서드
Widget build(BuildContext context, WidgetRef ref) {
  return Column(children: [
    // ... 30줄 헤더
    // ... 40줄 리스트
    // ... 20줄 푸터
  ]);
}
```

### 추출 후

```dart
// ✅ 역할별 위젯 분리
Widget build(BuildContext context, WidgetRef ref) {
  return Column(children: [
    const _Header(),
    Expanded(child: _SecretList()),
    const _Footer(),
  ]);
}
```

### const 생성자 규칙

```dart
// ✅ 파라미터가 모두 compile-time 상수이면 const
class FolderListItem extends StatelessWidget {
  const FolderListItem({super.key, required this.folder, required this.isSelected});
  final Folder folder;
  final bool isSelected;
}

// 사용 시 const 전파
const FolderListItem(folder: folder, isSelected: true)  // 가능하면 const
```
