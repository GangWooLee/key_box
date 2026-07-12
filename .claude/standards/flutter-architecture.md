# Flutter Architecture Standard — 상세 구현 패턴

Rules 파일의 원칙을 코드 예시와 함께 상세 설명합니다.

---

## 1. Riverpod Provider 패턴

### Provider (의존성 주입)

```dart
// core 의존성 — 앱 전역에서 1개 인스턴스
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());  // 반드시 정리!
  return db;
});

// 서비스 의존성 — 다른 provider 참조
final encryptionServiceProvider = Provider<SecretEncryptionService>((ref) {
  return SecretEncryptionService();
});
```

### StateNotifierProvider (상태 머신)

```dart
// Provider 정의
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(databaseProvider));
});

// StateNotifier 구현
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._db) : super(const AuthInitial());
  final AppDatabase _db;

  Future<void> initialize() async {
    final hasConfig = await _db.vaultConfigDao.exists();
    state = hasConfig ? const AuthLocked() : const AuthFirstRun();
  }

  Future<String?> unlock(String password) async {
    // ... 검증 로직
    state = AuthUnlocked(masterEncryptionKey: mek, vaultId: vaultId);
    return null;  // null = 성공, String = 에러 메시지
  }

  void lock() {
    state = const AuthLocked();
  }
}
```

### FutureProvider (비동기 1회 로드)

```dart
final secretsListProvider = FutureProvider.family<List<Secret>, int>(
  (ref, folderId) async {
    final db = ref.read(databaseProvider);
    return db.secretDao.getByFolderId(folderId);
  },
);
```

### StreamProvider (실시간 관찰)

```dart
final watchSecretsProvider = StreamProvider.family<List<Secret>, int>(
  (ref, folderId) {
    final db = ref.read(databaseProvider);
    return db.secretDao.watchByFolderId(folderId);
  },
);
```

### Provider 합성 패턴

```dart
// 여러 provider를 합성하는 중간 provider
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth is! AuthUnlocked) throw StateError('Not unlocked');

  final db = ref.read(databaseProvider);
  final folders = await db.folderDao.getByVaultId(auth.vaultId);
  final totalSecrets = await db.secretDao.countByVaultId(auth.vaultId);

  return DashboardData(folders: folders, totalSecrets: totalSecrets);
});
```

---

## 2. Sealed Class 상태 머신 패턴

### 상태 정의 (프로젝트 실제 코드)

```dart
/// Authentication state machine.
/// Flow: AuthInitial → AuthFirstRun/AuthLocked → AuthUnlocked → AuthLocked
sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthFirstRun extends AuthState {
  const AuthFirstRun();
}

final class AuthLocked extends AuthState {
  const AuthLocked();
}

final class AuthUnlocked extends AuthState {
  const AuthUnlocked({
    required this.masterEncryptionKey,
    required this.vaultId,
    this.isFirstSetup = false,
  });
  final Uint8List masterEncryptionKey;
  final int vaultId;
  final bool isFirstSetup;
}
```

### 상태 소비 (UI에서)

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authProvider);

  return switch (authState) {
    AuthInitial() => const LoadingScreen(),
    AuthFirstRun() => const SetupScreen(),
    AuthLocked() => const UnlockScreen(),
    AuthUnlocked() => const DashboardScreen(),
  };
}
```

---

## 3. Result 패턴 (프로젝트 실제 코드)

```dart
sealed class Result<T> {
  const Result();
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, {this.errors = const []});
  final String message;
  final List<String> errors;
}

// 사용 패턴
Future<Result<Secret>> createSecret(...) async {
  try {
    final secret = await _dao.create(...);
    return Success(secret);
  } catch (e) {
    return Failure('Failed to create secret: $e');
  }
}
```

---

## 4. Drift DAO 패턴

### 테이블 정의

```dart
// lib/core/database/tables/secrets.dart
class Secrets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vaultId => integer().references(Vaults, #id)();
  IntColumn get folderId => integer().references(Folders, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BlobColumn get encryptedValue => blob()();
  BlobColumn get encryptedValueIv => blob()();
  BlobColumn get encryptedValueAuthTag => blob()();
  TextColumn get secretType => text().withDefault(const Constant('api_key'))();
  TextColumn get serviceName => text().nullable()();
  TextColumn get environment => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

### DAO 구현

```dart
@DriftAccessor(tables: [Secrets])
class SecretDao extends DatabaseAccessor<AppDatabase> with _$SecretDaoMixin {
  SecretDao(super.db);

  // Create
  Future<Secret> create({required int vaultId, required String name, ...}) {
    return into(secrets).insertReturning(SecretsCompanion.insert(...));
  }

  // Read (단일)
  Future<Secret?> getById(int id) {
    return (select(secrets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Read (목록 + 정렬)
  Future<List<Secret>> getByFolderId(int folderId) {
    return (select(secrets)
          ..where((t) => t.folderId.equals(folderId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  // Watch (실시간 스트림)
  Stream<List<Secret>> watchByFolderId(int folderId) {
    return (select(secrets)
          ..where((t) => t.folderId.equals(folderId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  // Update
  Future<bool> updateById(int id, SecretsCompanion companion) {
    return (update(secrets)..where((t) => t.id.equals(id)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  // Delete
  Future<int> deleteById(int id) {
    return (delete(secrets)..where((t) => t.id.equals(id))).go();
  }

  // Search
  Future<List<Secret>> search(int vaultId, String query) {
    return (select(secrets)
          ..where((t) =>
              t.vaultId.equals(vaultId) &
              (t.name.like('%$query%') | t.serviceName.like('%$query%')))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }
}
```

### 코드 생성

```bash
# Drift 코드 생성 (테이블/DAO 변경 후 필수)
dart run build_runner build --delete-conflicting-outputs
```

### 트랜잭션

```dart
await _db.transaction(() async {
  final vault = await _db.vaultDao.create(name: 'Personal');
  await _db.vaultConfigDao.create(vaultId: vault.id, salt: salt, ...);
  await _db.folderDao.create(vaultId: vault.id, name: 'Default');
});
```

---

## 5. GoRouter 리다이렉트/가드 패턴

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = auth is AuthUnlocked;
      final isAuthRoute = state.matchedLocation == '/setup'
          || state.matchedLocation == '/unlock';

      if (!isAuth && !isAuthRoute) {
        return auth is AuthFirstRun ? '/setup' : '/unlock';
      }
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupScreen()),
      GoRoute(path: '/unlock', builder: (_, __) => const UnlockScreen()),
    ],
  );
});
```

---

## 6. 암호화 서비스 패턴

### 키 파생 (PBKDF2)

```dart
class KeyDerivationService {
  Uint8List generateSalt() => SecureRandom.generate(CryptoConstants.saltLength);

  Uint8List deriveKey({required String password, required Uint8List salt}) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, CryptoConstants.pbkdf2Iterations, CryptoConstants.keyLength));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }
}
```

### 암호화/복호화 (AES-256-GCM)

```dart
class SecretEncryptionService {
  ({Uint8List ciphertext, Uint8List iv, Uint8List authTag}) encrypt({
    required Uint8List plaintext,
    required Uint8List key,
  }) {
    final iv = SecureRandom.generate(CryptoConstants.ivLength);
    final gcm = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    // ... encrypt and split ciphertext + authTag
  }
}
```

---

## 7. 프로젝트 상수

```dart
// lib/core/constants/crypto_constants.dart
abstract class CryptoConstants {
  static const int keyLength = 32;          // AES-256
  static const int saltLength = 32;
  static const int ivLength = 12;           // GCM standard
  static const int pbkdf2Iterations = 600000;
  static const int minPasswordLength = 8;
}

// lib/core/constants/app_constants.dart
abstract class AppConstants {
  static const String appName = 'Key Box';
  static const Duration autoLockTimeout = Duration(minutes: 5);
  static const Duration clipboardClearTimeout = Duration(seconds: 30);
}
```

---

## 8. 안티패턴 → 올바른 패턴

| 안티패턴 | 올바른 접근 |
|---------|-----------|
| Widget에서 직접 DB 접근 | Provider를 통해 간접 접근 |
| `ref.read` in `build()` | `ref.watch` 사용 |
| God Widget (300줄+) | 위젯 추출 + Provider 분리 |
| 트랜잭션 없이 다중 insert | `_db.transaction()` 사용 |
| 하드코딩 암호화 상수 | `CryptoConstants` 사용 |
| 문자열 보간 SQL | Drift 타입 안전 쿼리 |
| `*.g.dart` 수동 편집 | `build_runner` 재실행 |
