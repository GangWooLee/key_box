# 내부 계약 명세

> 이 앱에는 외부 API가 없다 — 여기서 "계약"은 모듈이 서로에게 하는 약속이다.
> 시그니처는 IDE가 보여주지만, **미묘한 계약**(반환 null의 의미, 맵에 없는 키,
> 트랜잭션 경계, 멱등성)은 코드 주석에 흩어져 있고 그것이 버그의 온상이었다.
> 이 문서는 그 약속들을 한곳에 명문화한다. 용어는 [GLOSSARY.md](GLOSSARY.md).

## 관례 두 가지를 먼저

읽기 전에 이 코드베이스의 두 가지 반환 관례를 알아야 한다.

- **인증·조작 계층은 "성공 = null"** — `AuthNotifier.setup/unlock/changePassword`는
  성공하면 `null`, 실패하면 사용자에게 보여줄 에러 문자열을 반환한다.
- **암호 계층은 "실패 = null, 절대 throw 안 함"** — `unwrap`·`decrypt`는 GCM
  인증 실패를 예외가 아니라 `null`로 알린다. 오답 비밀번호와 손상 데이터를
  구분해 주지 않는 것은 의도다(공격자에게 오라클을 덜 준다).

## 인증 상태 머신 — `AuthNotifier`

상태는 sealed class 6종: `AuthInitial → AuthFirstRun | AuthLocked |
AuthVaultError(reason) | AuthUnlocked(masterEncryptionKey, vaultId, isFirstSetup)`.

| 메서드 | 계약 |
|---|---|
| `initialize()` | 재진입 가드 — `AuthInitial`이 아니면 즉시 반환. 중단된 회전/마이그레이션 복구 후 부팅 매트릭스(sidecar × DB 파일 존재)로 FirstRun/Locked/VaultError 판정 |
| `setup({password, confirmation})` | 성공=null. 볼트+설정+기본 폴더('General')+감사를 한 트랜잭션으로. sidecar 쓰기는 커밋 뒤(실패해도 치명 아님) |
| `unlock({password})` | 성공=null. **keyed DB open 자체가 비밀번호 검사다** — SQLCipher가 틀린 키에 `file is not a database`를 내고, 이는 손상과 구분되지 않는다(설계). 오답 시 잘못된 키의 DB 인스턴스를 해제해 재시도를 오염시키지 않는다 |
| `changePassword({old, new, confirmation})` | 성공=null. 6단계 크래시 프로토콜(스테이징→rewrap→rekey+WAL 체크포인트→승격), 사전 백업망 확보 실패 시 시작 자체를 거부. **세션 MEK는 그대로 — 재잠금 없음** |
| `lock()` | **회전 중이면 잠그지 않고 예약만 한다** — `_rotating`이 참이면 `_lockRequestedWhileRotating`을 세우고 반환, 회전의 바깥 `finally`가 예약된 lock을 재생한다. rekey 도중 keyed 연결을 끊으면 볼트가 복구 불능(케이스 B)에 빠질 수 있기 때문. 평시엔 MEK zero-out → `AuthLocked` → 연결 해제 |
| `restoreFromBackup({archive, password})` | `RestoreOutcome` 반환. DB를 건드리기 전에 아카이브 검증을 끝낸다. 복원 시 각 시크릿을 새 행 id에 AAD 재바인딩 |
| `resetAndReinitialize()` | 파기 순서 고정: sidecar 먼저, DB 나중 — 중간 크래시가 "sidecar만 남은" 모호 상태를 만들지 않게 |

핵심 provider 계약 ([auth_notifier.dart](../lib/features/auth/domain/auth_notifier.dart)):
`databaseProvider`는 잠금 전에 읽으면 `StateError('databaseProvider read before
vault unlock')`를 **던진다** — null을 주지 않는다. 내부의 `watch`가 load-bearing이라
잠금 전 에러가 캐시되지 않는다.

## 시크릿 연산 — `SecretOperations`

[secrets_providers.dart:217](../lib/features/secrets/domain/secrets_providers.dart) —
전 메서드가 `Result<T>`(Success/Failure) 또는 nullable을 반환한다.

**`create(...)` — 이 코드베이스에서 가장 계약이 두꺼운 메서드.**
암호문은 자기 행 id에 AAD로 묶여야 하는데 id는 insert가 끝나야 나온다. 그래서
한 트랜잭션 안에서: ① 빈 값 자리표시자 insert로 id 예약 → ② 그 id·버전으로
암호화 → ③ 암호문 update. 값 없는 자리표시자는 트랜잭션 밖으로 절대 새지 않는다.
**단, 폴더 링크(`link(folderId, secret.id)`)는 트랜잭션 커밋 *뒤*에 실행된다** —
커밋과 링크 사이에 프로세스가 죽으면 시크릿은 존재하지만 어느 폴더에도 안 보이는
고아가 된다(카운트에도 빠짐). 알려진 창이며 B-장부 항목이다.

| 메서드 | 계약 |
|---|---|
| `update(id, {value, ...})` | **값이 바뀔 때만 회전한다**: `value != null`일 때만 `recordVersion+1`로 재암호화. null이면 암호문·버전 불변(편집 UI가 "원본과 같으면 null 전달"로 이를 보장) |
| `delete(secret)` | 순서 고정: unlink 전부 → 행 삭제. 카운트는 파생이라 감소 연산 없음 |
| `reveal(secret)` | **평문을 돌려주기 전에** 부작용을 남긴다: access_count 증가 + 감사 `secret.read`. 복호 실패 시에도 접근 기록은 남는다 |
| `decrypt(secret)` | 부작용 없음. reveal과의 차이가 곧 감사 정책이다 |
| `linkToFolder` / `unlinkFromFolder` | link는 멱등(insertOrIgnore — 중복 링크 무해), unlink는 삭제 행 수 반환 |

## 데이터 계층 — DAO별 미묘 계약

전 DAO가 Drift 파라미터화 쿼리만 쓴다(문자열 보간 SQL 없음 — safety 규율).

**FolderSecretsDao** ([folder_secrets_dao.dart](../lib/core/database/daos/folder_secrets_dao.dart))
— M:N 조인 테이블, **폴더 소속과 카운트의 유일한 진실원천**.

- `link(folderId, secretId)` — `insertOrIgnore`: 이미 있으면 조용히 무시. 멱등.
- `watchCountsByFolder(): Stream<Map<int,int>>` — **링크가 0인 폴더는 맵에
  없다.** 호출자는 반드시 `counts[id] ?? 0`. (이 스트림이 예전의
  `folders.secretsCount` 캐시 컬럼을 대체했다 — 캐시는 쓰기 경로가 갈라져
  드리프트했고, 파생은 원리적으로 드리프트할 수 없다.)
- `watchSecretsByFolderId` — innerJoin, `updatedAt DESC` 정렬 보장.

**SecretDao** ([secret_dao.dart](../lib/core/database/daos/secret_dao.dart))

- `updateSecret(...)` — null 인자는 `Value.absent()`(부분 갱신). `updatedAt`은
  항상 갱신. **`recordVersion`은 명시로 넘길 때만 쓰인다** — 값 회전 경로가
  버전 관리 책임을 진다.
- `deleteSecret(id)` — **folder_secrets를 건드리지 않는다.** 호출자(SecretOperations)가
  unlink를 선행할 책임.
- `search(vaultId, query)` — name·service·tags·notes LIKE, 상한 50건.
- `watchByFolderId` — 레거시 1:N `folderId` 컬럼 기준. **UI 폴더 뷰는 이걸 쓰지
  않는다**(M:N 조인이 진실원천) — 잔존 표면임을 주의.

**FolderDao** ([folder_dao.dart](../lib/core/database/daos/folder_dao.dart))

- `getByVaultId` — `position ASC` 정렬. **`folders.first` = 최저 position =
  'General'** — 새 시크릿의 폴더 폴백이 general로 가는 메커니즘이 이 정렬이다.
- `deleteFolder(id)` — 자식 폴더도 링크도 cascade하지 않는다. 호출자 책임.
- `getDescendantIds(id)` — 재귀 CTE, 자기 자신은 제외.
- `increment/decrementSecretsCount` — **레거시 캐시 컬럼 조작.** 라이브 카운트
  경로에서 제거됐고 복원(restore) 경로만 아직 쓴다. 신규 코드에서 호출 금지.

**VaultConfigDao** — `updateKeyMaterial({salt, encryptedMasterKey})`: salt와
wrappedMek은 **한 단위로만** 바뀐다(회전 커밋 ④). 따로 바꾸는 API가 없는 것이
계약이다.

**AuditEventDao** — `getPage(vaultId, {page, limit})`: `createdAt DESC`.
호출자(auditEventsProvider)는 `limit=(page+1)*50, offset 0`의 **누적 창** 방식으로
쓴다 — 진짜 페이지네이션이 아님을 알고 읽어야 한다.

## 암호화 서비스 — 크기와 실패 규약

[crypto_constants.dart](../lib/core/constants/crypto_constants.dart)가 전 상수의
정본: PBKDF2 600,000회 · salt 32B · 키 32B · IV 12B · GCM 태그 16B ·
wrappedMek 60B(=12+16+32) · HKDF 라벨 `keybox/v1/dbkey`·`keybox/v1/kek` ·
AAD 접두 `keybox/v1/secret` · 최소 비밀번호 12자.

| 서비스 | 계약 |
|---|---|
| `KeyDerivationService.deriveKey({password, salt})` | PBKDF2-HMAC-SHA256 → 32B PDK. 생성자의 `iterations` 주입은 **테스트 전용**(600k ≈ 3초/회라 테스트가 타임아웃 남) — 프로덕션에서 낮추면 안 된다 |
| `KeyHierarchyService.deriveDbKey/deriveKek(pdk)` | HKDF-SHA256, salt는 빈 값(RFC 5869), 분리는 info 라벨로만. `pdk.length != 32`면 `ArgumentError` **throw** (이 계층의 유일한 throw) |
| `MasterKeyService.wrap(...)` | 60B `[IV 12][태그 16][암호문 32]` 레이아웃. AAD 없음(MEK 랩은 레코드에 안 묶임). 호출마다 새 IV |
| `MasterKeyService.unwrap(...)` | 길이≠60 또는 GCM 실패 → **null. 절대 throw 안 함** |
| `SecretEncryptionService.decrypt(...)` | AAD 불일치 포함 모든 인증 실패 → null |
| `secretAad({secretId, recordVersion})` | `keybox/v1/secret:<id>:<version>` UTF-8 — 치환(id)·롤백(version) 방어의 실체 |

**zero-out 책임은 호출자에 있다**: PDK·KEK·salt·wrappedMek은 AuthNotifier의
`finally`에서 지운다. 예외 하나 — **dbKey는 의도적으로 안 지운다**: keyed 연결의
setup 콜백이 연결 수명 동안 `PRAGMA key`를 재실행하는 데 필요하다. 회전의
`dbKeyNew`는 rekey 문자열 생성 후 지운다.

## 백업 — `VaultBackupService`

쓰기는 항상 **v3**, 읽기는 v3·v2·v1(v1은 레거시 PDK 직접 랩 — 가져오기 전용).

| 메서드 | 계약 |
|---|---|
| `exportArchive(...)` | **내보내기 전에 전 레코드를 MEK로 복호 검증** — 하나라도 실패하면 null 반환, 손상 백업은 애초에 만들어지지 않는다. v3는 레코드 메타데이터(이름·메모 등)를 MEK-GCM 암호화 |
| `describeImport(...)` | 실패 분류가 sealed class로 명시적: `Corrupt`(파싱 불가·미지 버전·**KDF 파라미터가 상수와 다름 = 다운그레이드 방어**·레코드 GCM 실패) vs `WrongPassword`(정상 구조인데 MEK unwrap 실패) vs `Success`. 성공 시 전 레코드를 **새 IV로** 목적지 MEK에 재암호화해 반환 |
| `importArchive(...)` | 얇은 래퍼 — Corrupt와 WrongPassword를 null 하나로 뭉갠다. 구분이 필요하면 describeImport를 쓸 것 |

아카이브 레코드는 **의도적으로 AAD 없음** — 아카이브에는 행 identity가 없고
(복원 시 id가 바뀐다), AAD는 복원 insert 시점에 새 id로 재바인딩된다.

## Provider 계약 — 가드·수명·무효화

**auth 가드 패턴**: 스트림 provider는 `authProvider`를 watch하고 잠금이면
`Stream.empty()`를 돌려준다. 이 watch는 데이터 가드이자 **재바인딩 장치**다 —
lock→unlock 시 새 keyed 연결로 스트림을 다시 물리게 한다(없으면 닫힌 연결의
죽은 스트림을 계속 서빙한다 — Phase 1 리뷰가 잡은 실결함 클래스).

| provider | 유형 | 가드 | 비고 |
|---|---|---|---|
| foldersProvider / rootFoldersProvider / folderChildrenProvider / secretsProvider / folderSecretsProvider / folderSecretCountsProvider | Stream | ✅ | 전부 Drift watch — 쓰기에 자동 반응, 수동 무효화 불요 |
| searchResultsProvider | Future | ✅ | 빈 질의 단락 |
| auditEventsProvider | Future.autoDispose | ✅ | **autoDispose가 load-bearing** — 없으면 첫 페이지가 영구 캐시되어 재진입 시 새 이벤트가 안 보인다 |
| secretDetailProvider | Future.autoDispose.family | ❌ | 가드 없이 databaseProvider 직독 — detail 패널이 AuthUnlocked에서만 렌더되므로 안전, 위반 시 StateError로 시끄럽게 죽는다(무음 오염 아님) |
| folderIdsBySecretProvider | Future.autoDispose.family | ❌ | 위와 동일 패턴 |
| filteredSecretsProvider | 파생 | (간접) | **폴더 선택이 카테고리보다 우선** — 폴더 선택 시 카테고리 필터 무시 |

**무효화 지도** — 일회성(Future) provider는 스스로 갱신되지 않으므로, 쓰기를
한 UI가 무효화 책임을 진다. 현재 계약된 지점은 정확히 셋뿐이다:

1. 편집 저장 후 → `invalidate(secretDetailProvider(id))` — 안 하면 detail
   패널이 **수정 전 값을 계속 복호·표시**한다 (sheet_modal `_save`).
2. 폴더 링크 후 → `invalidate(folderIdsBySecretProvider(id))` (secret_detail).
3. 폴더 언링크 후 → 동일 (secret_detail).

새 쓰기 경로를 추가하면 이 지도에 등재하는 것까지가 계약이다.

## 앱 서비스

**ClipboardService** — `copyWithAutoClear(value)`: 네이티브 채널로
ConcealedType 마킹과 함께 쓰고 30초 타이머를 장전한다(재복사 시 타이머 리셋).
채널 실패(테스트·비macOS) 시 평문 폴백으로라도 **복사는 절대 실패하지 않는다**.

**AutoLockService** — `recordActivity()`는 **타이머가 이미 돌 때만** 리셋한다
(잠금 상태의 활동은 무시). 유휴 시간 설정 변경은 다음 활동부터 적용. 만료 시
`lock()`을 fire-and-forget으로 호출 — 그리고 그 lock이 회전 중이면 위의 defer
계약대로 예약된다. `dispose()`는 타이머만 취소한다(컨테이너 teardown 중 다른
provider를 읽으면 throw하므로).
