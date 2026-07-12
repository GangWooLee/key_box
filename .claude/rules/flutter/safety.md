---
paths:
  - "lib/**"
---

# 안전 · 보안 규칙 — 암호화 · 데이터 보호 · macOS Desktop

## 암호화 규칙 (AES-256-GCM + PBKDF2)

### 마스터 키 관리

```dart
// ❌ 금지: 마스터 키 평문 저장
SharedPreferences.setString('masterKey', base64Encode(key));

// ✅ 안전: 메모리에만 보유, 앱 잠금 시 삭제
class AuthNotifier extends StateNotifier<AuthState> {
  // masterKey는 AuthUnlocked 상태에만 존재
  // lock() 시 AuthLocked로 전환 → masterKey 접근 불가
}
```

### 복호화 값 로깅 금지

```dart
// ❌ 절대 금지
print('Decrypted: $plaintext');
debugPrint('Secret value: ${secret.value}');

// ✅ 안전: 컨텍스트만 로깅
debugPrint('[Crypto] Decrypt completed for secret #${secret.id}');
debugPrint('[Auth] User unlocked vault');
```

### Uint8List 메모리 정리

```dart
// 민감 데이터 사용 후 덮어쓰기
void clearSensitiveData(Uint8List data) {
  for (var i = 0; i < data.length; i++) {
    data[i] = 0;
  }
}
```

## 데이터베이스 보안 (Drift + SQLCipher)

### 파라미터화 쿼리만 허용

```dart
// ❌ 금지: 문자열 보간 SQL
customSelect('SELECT * FROM secrets WHERE name = "$name"');

// ✅ 안전: 파라미터화
customSelect(
  'SELECT * FROM secrets WHERE name = ?',
  variables: [Variable.withString(name)],
);

// ✅ 더 안전: Drift 타입 안전 쿼리
(select(secrets)..where((s) => s.name.equals(name))).get();
```

### SQLCipher 키 관리

```dart
// ❌ 금지: 하드코딩 키
NativeDatabase.createInBackground('db.sqlite', setup: (db) {
  db.execute("PRAGMA key = 'hardcoded-key'");
});

// ✅ 안전: 마스터 키에서 파생
NativeDatabase.createInBackground(file, setup: (db) {
  db.execute("PRAGMA key = '${hex.encode(derivedKey)}'");
});
```

## 클립보드 보안

```dart
// ❌ 금지: 클립보드에 무기한 보관
Clipboard.setData(ClipboardData(text: secretValue));

// ✅ 안전: 타임아웃 후 자동 삭제
Clipboard.setData(ClipboardData(text: secretValue));
Future.delayed(const Duration(seconds: 30), () {
  Clipboard.setData(const ClipboardData(text: ''));
});
```

## 자동 잠금

- 앱 비활성 시 타이머 기반 자동 잠금 (기본 5분)
- 앱 포커스 상실 시 잠금 고려
- 잠금 시 masterKey 메모리에서 제거

## 입력 검증

```dart
// 비밀번호 정책
static const minPasswordLength = 8;

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return '비밀번호를 입력하세요';
  if (value.length < minPasswordLength) return '최소 $minPasswordLength자 이상';
  return null;
}

// 시크릿 이름 검증
String? validateSecretName(String? value) {
  if (value == null || value.trim().isEmpty) return '이름을 입력하세요';
  if (value.length > 100) return '100자 이하로 입력하세요';
  return null;
}
```

## macOS 특화 보안

- Entitlements에서 필요한 권한만 선언
- 네트워크 접근 불필요 시 `com.apple.security.network.client` 제거
- 파일 접근은 앱 샌드박스 내로 제한
- keychain 접근 시 적절한 entitlement 필수

## 프로덕션 금지 명령

```bash
# ❌ 절대 금지
rm -rf ~/Library/Containers/com.example.keyBox/
git push --force origin main
git reset --hard
```

## 보안 체크리스트

- [ ] 마스터 키가 메모리에만 존재 (디스크 저장 금지)
- [ ] 복호화 값 로그 출력 없음
- [ ] SQLCipher 키가 하드코딩되지 않음
- [ ] 클립보드 자동 삭제 구현
- [ ] 자동 잠금 활성화
- [ ] Drift 쿼리가 파라미터화됨
- [ ] 민감 Uint8List 사용 후 0으로 덮어쓰기
