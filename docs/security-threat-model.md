# key_box 위협모델 — 공격자 관점 (Phase 2, 2026-07-16)

> 멀티에이전트 워크플로(3 위협모델 × 6 카테고리, 36 에이전트) 열거 → 3-렌즈 방어-격차 판정.
> 원칙: 2차 password 등 마찰 방어 미채택 — 무마찰 방어만. 각 경로는 실 file:line 근거.

**판정 분포**: defended 8 · gap-accepted 13 · gap-real 10 · out-of-model 2 · 총 33

## [HIGH] at-rest · gap-real **[A-필수]**
- **공격**: .kbx 백업 파일의 평문 메타데이터 노출 — 크래킹 없이 시크릿 인벤토리+notes 즉시 획득
- **경로**: .kbx 파일 1개만 획득(사용자가 Downloads/iCloud Drive/이메일 첨부/Time Machine 등 어디든 저장 가능) → JSON을 텍스트 에디터로 열면 records[]의 name·secretType·serviceName·environment·notes(최대 2000자)·tags가 전부 base64도 아닌 평문. 값(value)만 암호화됨. notes에 사용자가 시크릿 원문·복구코드·URL을 붙여넣었으면 그대로 읽힘. 어떤 서비스의 어떤 환경 크리덴셜이 존재하는지 완전한 지도를 무비용으로 확보.
- **현재 방어**: value 필드만 AES-256-GCM 암호화(vault_backup_service.dart:218-228 _recordToJson). DB 파일 본체는 전체 암호화되어 이 누출이 없음 — .kbx만의 격차.
- **격차**: 메타데이터 전부 평문. .kbx는 접근제어 없이 사용자가 고른 위치(클라우드 동기화 폴더 포함 가능)에 상주. 무마찰 완화: 아카이브 전체를 password 파생 키로 봉투암호화(메타데이터까지)하거나, name/serviceName/notes/tags/environment도 MEK-GCM으로 암호화해 값과 동급 보호. 현재는 값만 지키고 나머지는 그대로 노출.
- **무마찰 수정**: 아카이브의 records[] 전체를 MEK-GCM으로 봉투암호화한다. 헤더(format/version/kdf/cipher/salt/wrappedMek)는 키 파생을 위해 평문 유지하되, name·secretType·serviceName·environment·notes·tags를 값(value)과 동급으로 암호화한다. 두 가지 구현 중 하나: ①레코드별로 {name,secretType,serviceName,environment,notes,tags,value}를 한 JSON blob으로 묶어 MEK-GCM 단일 암호문으로 저장(현재 _recordToJson 대체), 또는 ②records 배열 전체를 직렬화해 MEK-GCM으로 암호화한 뒤 encryptedRecords+iv+authTag로 저장. import 경로는 이미 password→KEK unwrap→MEK를 수행(describeImport, vault_backup_service.dart:200-206)하므로, 복원 시 그 MEK로 메타데이터를 복호화하면 된다. 복원에 필요한 마스터 password는 이미 유일한 키 입력이므로 사용자 추가 행동 0 — 완전 무마찰. 2차 password·추가 프롬프트 불필요.
- **근거**: `lib/core/backup/vault_backup_service.dart:114-153, 218-228`  · 위협모델 TM3-diskimage

## [INFO] at-rest · defended **[A-필수]**
- **공격**: [방어 검증] DB 파일 전체암호화 + 하드핀 + wrappedMek 내부 은닉 — DB 아티팩트 기밀성 충분
- **경로**: 공격자가 key_box.db만 확보 시: plaintext_header_size=0라 'SQLite format 3' 매직조차 없어 파일이 랜덤과 구별 불가 → 키박스 DB인지도 확증 곤란. wrappedMek·salt·스키마·메타데이터 전부 암호화 DB 내부라 keyed open 전에는 어떤 것도 추출 불가. .kbx와 달리 무크래킹 노출 표면이 0.
- **현재 방어**: database.dart:110-113 PRAGMA key 최초문+하드핀; cipher_params.dart:16-23(page_size 4096, HMAC_SHA512, use_hmac ON, plaintext_header_size 0); wrappedMek/salt는 vault_configs 내부(vault_configs.dart:10-12). PRAGMA rekey 시 WAL 체크포인트로 구키 페이지 잔존 차단(auth_notifier.dart:646-648).
- **격차**: 없음 — 방어 충분(DB 파일 자체는 강함). 잔여 위험은 .kbx·평문 마이그레이션 잔해·비번강도에 집중(위 항목들).
- **무마찰 수정**: 불필요 — DB 파일 자체의 기밀성 방어는 충분. (선택적 무마찰 개선: 마이그레이션/회전 잔해가 정말 없는지는 별도 항목에서 다루므로 이 경로에서 추가 조치 없음.)
- **근거**: `lib/core/database/cipher_params.dart:16-23; lib/core/database/database.dart:101-116`  · 위협모델 TM3-diskimage

## [INFO] at-rest · defended **[A-필수]**
- **공격**: [방어 검증] 키체인·생체·평문 키 영속화 부재 — 마스터키는 password 전용, 디스크에 키 재료 없음
- **경로**: 공격자가 앱 컨테이너 전체(SharedPreferences plist 포함)를 확보해도 키 재료 없음: keychain/flutter_secure_storage/local_auth 미사용(grep 확인), Touch ID는 비활성 placeholder(setup_screen.dart:346-369 '_touchIdAffordance ... disabled'). prefs엔 auto_lock_minutes·reveal_by_default·last_backup_at·창 크기·테마만(settings_preferences.dart, last_backup_store.dart, window_state_service.dart) — 시크릿·키 없음. 마스터키는 오직 비번 파생.
- **현재 방어**: MEK는 AuthUnlocked 상태 메모리에만 존재, 디스크 저장 없음(safety.md 규율). '비밀번호를 기억' 기능·생체 봉인 없음 → at-rest 키 유출 경로 자체가 없음.
- **격차**: 없음 — 방어 충분. (트레이드오프: 생체 편의 부재는 UX 비용이나 at-rest 보안엔 순이득.) 잔여 at-rest 위험은 전부 password 강도+.kbx+평문 잔해로 환원됨.
- **무마찰 수정**: 불필요
- **근거**: `lib/features/auth/presentation/screens/setup_screen.dart:346-369; lib/features/settings/domain/settings_preferences.dart:1-61`  · 위협모델 TM3-diskimage

## [HIGH] in-memory · gap-real
- **공격**: 앱이 포커스를 잃거나 숨겨져도(Cmd-Tab·최소화·디스플레이 슬립·스크린세이버) 잠기지 않아 재전면화 시 즉시 열람 가능
- **경로**: 사용자가 Cmd-Tab으로 전환하거나 창을 최소화/숨김 후 자리 비움 → 공격자가 앱을 다시 전면화(Dock 클릭/Cmd-Tab) → AuthUnlocked 상태 그대로 유지 → 열람. 유휴 타이머는 계속 카운트다운하지만 15분 내 재접근이면 잠기지 않음. 디스플레이 슬립/스크린세이버로 넘어가도 앱은 lock() 하지 않음.
- **현재 방어**: 유휴 타이머만. DashboardScreen에는 WidgetsBindingObserver/lifecycle/blur 핸들러가 전무 (dashboard_screen.dart:35-71).
- **격차**: onWindowBlur/onWindowMinimize/onWindowHide/AppLifecycleState.hidden|paused에 lock() 배선이 전혀 없음. _WindowListenerWrapper는 move/resize만 처리(main.dart:70-82). '포커스 상실 시 즉시 자동 잠금'이라는 무마찰 방어가 미구현 — 도난·자리비움 시나리오의 핵심 구멍.
- **무마찰 수정**: DashboardScreen(AuthUnlocked일 때만 mount되는 ConsumerStatefulWidget)을 WindowListener로도 만들어 initState에서 windowManager.addListener(this), dispose에서 removeListener 후: (1) onWindowMinimize/onWindowHide 오버라이드 → ref.read(authProvider.notifier).lock(). '앱을 치운다'는 명시 제스처라 무마찰. (2) 가장 강한 away-신호인 macOS 화면잠금/디스플레이 슬립/스크린세이버는 window_manager가 안 주므로, DistributedNotificationCenter의 com.apple.screenIsLocked·com.apple.screensaver.didstart를 관찰하는 작은 네이티브 채널(Swift ~15줄 + MethodChannel)로 lock() 호출 — 이미 자리를 뜬 뒤에만 트리거되어 일상 재인증 마찰 0. 단, 평범한 blur(Cmd-Tab)에는 lock 걸지 말 것: 600k PBKDF2 재유도 ~2.8s라 매 앱전환마다 재인증은 dogfood UX 파괴(앱간 복붙 흐름은 idle 타이머가 이미 커버).
- **근거**: `lib/main.dart:70-82, lib/features/secrets/presentation/screens/dashboard_screen.dart:35-71`  · 위협모델 TM1-physical

## [HIGH] exfil-channel · gap-real
- **공격**: 복사된 시크릿이 클립보드에 남아 물리 접근 공격자가 붙여넣기로 획득; 잠금도 앱 종료도 클립보드를 비우지 않음
- **경로**: 사용자가 시크릿을 복사(30초 소거 타이머 시작) → 자리 비움/vault lock/앱 종료 → 공격자가 아무 텍스트 필드에서 Cmd-V → 마지막 복사 평문 획득. lock()은 MEK만 zero-out하고 클립보드는 손대지 않으므로 '잠긴' 화면에서도 붙여넣기 가능. 30초 내 앱을 종료하면 dispose()가 타이머만 취소하고 클립보드를 비우지 않아 평문이 무기한 잔류.
- **현재 방어**: ClipboardService 30초 자동 소거(clipboardClearSeconds=30) + 복사 이벤트 링 시각화 (clipboard_service.dart:24-51).
- **격차**: (a) 30초 창 자체가 물리 접근에 노출. (b) lock()/auto-lock이 클립보드를 소거하지 않음 — 잠금≠클립보드 정리(auth_notifier.dart:941-957). (c) dispose()가 클립보드를 비우지 않아 30초 내 종료 시 평문 무기한 잔류(clipboard_service.dart:53-56). 무마찰 개선: lock 시 클립보드가 이 앱이 쓴 값이면 소거, 종료 시 소거.
- **무마찰 수정**: Add `ClipboardService.clearIfOwned()` — clear the pasteboard only if it still holds this app's last-written value (guard against wiping the user's unrelated clipboard; track it via the value written at clipboard_service.dart:36-46 or the pasteboard changeCount / ConcealedType marker). Wire it to two triggers, both zero user action: (1) a listener on `authProvider` (mirroring autoLockProvider's `ref.listen`) that calls `ref.read(clipboardServiceProvider).clearIfOwned()` on the transition to AuthLocked — covers manual lock and auto-lock (auto_lock_service `_onTimeout`→lock()); (2) a native `applicationWillTerminate` handler on the existing `keybox/secure_clipboard` MethodChannel (macOS AppDelegate) that clears the NSPasteboard synchronously before quit — the robust place for the app-close case, since Dart `dispose()` (clipboard_service.dart:53-56) may not run on hard quit and, even when it does, only cancels the timer. The ownership guard keeps it frictionless: the user never loses unrelated clipboard content. Do NOT shorten the 30s window as the primary fix — that trades usability; the copy feature inherently exposes the value on the shared OS pasteboard for the paste window, which is accepted.
- **근거**: `lib/services/clipboard_service.dart:24-56, lib/features/auth/domain/auth_notifier.dart:941-957`  · 위협모델 TM1-physical

## [HIGH] at-rest · gap-real
- **공격**: .kbx 오프라인 비번 무차별 → 성공 시 실제 비밀번호까지 복구되어 전체(DB 포함) 침해
- **경로**: .kbx 획득 후 salt·wrappedMek를 파싱(평문). 추측마다: PBKDF2-600k(guess,salt)→PDK→HKDF KEK→MEK=unwrap(wrappedMek,KEK). GCM 인증태그가 결정적 오라클 — 통과하면 그 guess가 실제 비밀번호임을 확정. MEK로 모든 record value 복호화. 게다가 복구된 비밀번호 문자열로 현재 sidecar salt를 써 dbKey를 재파생해 SQLCipher DB까지 열 수 있음(비번 미변경 시). 즉 가장 저렴한 오라클이면서 성공 시 비번 자체를 넘겨줌.
- **현재 방어**: PBKDF2-HMAC-SHA256 600k(key_derivation_service.dart:35-40, crypto_constants.dart:4) + AES-256-GCM 봉투. 아카이브 헤더 KDF 파라미터가 CryptoConstants와 다르면(반복수 다운그레이드) 거부(vault_backup_service.dart:254-260). setup 시 최소 12자(crypto_constants.dart:34).
- **격차**: 작업계수가 600k PBKDF2-HMAC-SHA256 '하나'뿐 — 메모리-하드 아님(GPU/ASIC 친화적). Argon2id/scrypt 아님. 12자는 setup에서만 강제되고 unlock 재검증 없음(약한 인간선택 12자 사전공격 가능). 무마찰 레버(사용자 행동 불요): KDF를 Argon2id로 교체 또는 반복수 상향 — 봉투 재작성만으로 적용 가능, UX 불변.
- **무마찰 수정**: PBKDF2-HMAC-SHA256를 memory-hard KDF로 교체 — pointycastle이 이미 의존성이고 이 파일들이 직접 import 중이라 `Argon2BytesGenerator`(Argon2id)를 신규 의존성 없이 쓸 수 있다(key_derivation_service.dart:3). 대안으로 반복수 상향(예 600k→1.2M)도 가능하나 SHA-256 ASIC 친화성 자체는 못 없애므로 Argon2id 교체가 정공법. 적용은 완전 무마찰: KDF 파라미터가 이미 sidecar와 백업 봉투 양쪽에 버전으로 기록돼 있으므로(vault_backup_service.dart:138-143의 kdf 블록, 그리고 sidecar) 다음 unlock 시 조용히 마이그레이션 — 기존 반복수로 PDK 파생하여 언락 성공 → 새 KDF로 재파생 → `PRAGMA rekey`로 SQLCipher DB 재키 → deriveKek로 MEK 재래핑 → sidecar/백업 봉투의 KDF 레코드 갱신. 사용자 추가 행동 0, UX 불변. (2차 password 같은 마찰 방어 아님 — KDF 강도 교체 한 건.)
- **근거**: `lib/core/backup/vault_backup_service.dart:196-216; lib/core/encryption/key_derivation_service.dart:35-40`  · 위협모델 TM3-diskimage

## [HIGH] at-rest · gap-real
- **공격**: 중단·실패한 평문→암호화 마이그레이션이 평문 DB를 디스크에 잔존시킴
- **경로**: 마이그레이션 케이스: (a) 스왑 후 최종검증 실패 시 코드가 의도적으로 평문 소스를 main으로 롤백(vault_migrator.dart:562-564) → 볼트가 '암호화됐다'는 기대와 달리 main이 평문 SQLite로 상주. (b) 스왑 직후~최종검증 사이 크래시면 recoverInterrupted는 main+.pre-encryption 공존 케이스를 '의도적으로 건드리지 않음'(vault_migrator.dart:136-155) → 평문 .pre-encryption(볼트 전체 사본)이 남음. 이 시점 디스크/Time Machine 캡처 시 공격자는 PRAGMA key 없이 평문 DB를 바로 읽어 전 시크릿 획득 — 무크래킹.
- **현재 방어**: 성공 경로에서는 _finalVerifyAndCleanup이 .pre-encryption과 강제백업 .kbx를 삭제(vault_migrator.dart:550-557). recoverInterrupted가 main 부재+.pre-encryption 케이스는 롤백, .migrating 잔해는 삭제(143-155). 원자적 rename 스왑(224-225).
- **격차**: 실패/크래시 창에서 평문 사본이 표준 캡처 위치(app support dir)에 남는 창이 존재. 검증 실패 롤백은 데이터 보존을 위해 평문을 main으로 되돌려 암호화 목표를 무효화. 무마찰 완화: 검증 실패 시 평문 롤백 대신 잠금상태로 실패 표시(데이터는 .kbx 백업으로 복구)하고 평문 잔해를 즉시 파기, 부팅 시 main+.pre 공존을 keyed-open으로 판정해 평문 잔해를 조기 삭제.
- **무마찰 수정**: 무마찰(추가 사용자 행동 0) 부팅 청소로 docstring이 이미 약속한 "boot flow" 처리를 실제 구현하면 된다. 언락 경로에서 main의 keyed open이 성공한 직후(현재 auth_notifier.dart ~485-513이 이미 main을 keyed로 열고 config/first secret을 읽음 = 암호화 main이 신뢰 가능함을 증명) `key_box.db.pre-encryption`이 존재하면 즉시 삭제한다. 사용자는 평소 비번만 입력 — 2차 password/추가 단계 없음. 역케이스도 무마찰로 함께 처리 가능: keyed open이 실패하고 `.pre-encryption`이 존재하면 main 삭제 후 pre→main 롤백해 다음 언락에서 isPlaintextDb(main)==true로 마이그레이션이 재실행되게 한다. 대안으로 언락 시 dbKey 파생 직후(auth_notifier.dart:468 부근) `.pre-encryption` 존재 시 _finalVerifyPasses와 동일한 keyed-verify를 돌려 성공이면 삭제, 실패면 롤백하는 헬퍼를 VaultMigrator에 추가하면 케이스(b) 창이 다음 부팅에 반드시 닫힌다.
- **근거**: `lib/core/vault/vault_migrator.dart:136-155, 543-566; lib/core/database/vault_paths.dart:26-34`  · 위협모델 TM3-diskimage

## [MEDIUM] at-rest · gap-real
- **공격**: .kbx 백업의 평문 metadata(notes 포함) 파일 직접 읽기로 유출
- **경로**: 멀웨어가 발견 가능한 .kbx를 읽는다 — 고정 경로의 사전회전 스냅샷 key_box.vault.prerotate.kbx(모든 비밀번호 변경 중 존재), 마이그레이션 백업 key_box.backup-<epoch>.kbx(레거시 마이그레이션 중 존재), 또는 사용자 지정 export. JSON을 파싱하면 name·secretType·serviceName·environment·notes·tags가 전부 평문 — 값(encryptedValue)만 암호화돼 있다. notes/serviceName에는 URL·사용자명·힌트 등 민감 문맥이 흔히 담긴다.
- **현재 방어**: 아카이브의 시크릿 값은 AES-256-GCM 암호화(vault_backup_service.dart:225-227). 사전회전/마이그레이션 백업은 성공 후 삭제(auth_notifier changePassword ⑥ 이후, vault_migrator _finalVerifyAndCleanup).
- **격차**: 모든 metadata + notes가 평문 JSON으로 저장됨(vault_backup_service.dart:218-228). 사전회전 백업은 회전 지속 동안 고정 app-support 경로에 놓여 같은 사용자가 읽을 수 있다. 사용자 지정 .kbx도 동일하게 metadata 평문.
- **무마찰 수정**: 암호화 봉투(encrypted envelope): records[]를 JSON 직렬화 후 그 blob 전체를 AES-256-GCM으로 MEK 하 1회 암호화(fresh IV + AAD=formatVersion), base64(iv|ct|tag)를 records 자리에 저장. 헤더(salt·wrappedMek·kdf)만 평문 유지(MEK unwrap 선행에 필요). import는 현행 순서 그대로 MEK unwrap→records blob 복호→파싱, 왕복 대칭 보존. MEK는 세 생산자(사전회전 auth_notifier.dart:626, 마이그레이션 vault_migrator.dart:360, 사용자 export backup_export.dart:28) 모두 export 시점 보유하고 전부 exportArchive 단일 경유이므로 한 곳 수정으로 세 .kbx 표면 동시 폐쇄. 사용자 추가 행동·2차 password 없음. 선택적으로 recordCount도 봉투 안으로 이동해 시크릿 개수 노출까지 제거.
- **근거**: `lib/core/backup/vault_backup_service.dart:218-228; lib/core/vault/vault_paths.dart:42 (prerotate.kbx 고정 경로)`  · 위협모델 TM2-malware

## [MEDIUM] exfil-channel · gap-real
- **공격**: 창이 화면 캡처 가능 — reveal된 값 스크린/AX 스크래핑
- **경로**: 사용자가 시크릿을 reveal하면(secret_detail.dart:389가 decryptedValue를 Text로 렌더) Screen-Recording TCC를 가진 멀웨어가 CGWindowListCreateImage/screencapture로 창을 캡처하거나, Accessibility TCC로 AX 텍스트 트리를 읽어 화면상 평문을 복원한다.
- **현재 방어**: 기본 마스킹(reveal은 명시적, off-by-default — settings_preferences.dart:38, 고정 점 개수로 길이도 은닉). TCC가 화면 녹화·접근성을 게이트. 시크릿 전환 시 재마스킹(secret_detail.dart:50,70).
- **격차**: NSWindow가 sharingType=.none을 설정하지 않아 앱이 화면 캡처에 포함된다(MainFlutterWindow에 설정 없음). 값 뷰를 non-capturable로 표시하지도 않는다. 방어가 OS TCC 프롬프트에 귀착되는데 멀웨어가 이미 권한을 보유했거나 사회공학으로 얻을 수 있다.
- **무마찰 수정**: 완전 무마찰(2차 password 없음). 두 벡터를 각각 닫는다. (1) 이미지 캡처: MainFlutterWindow.awakeFromNib에 `self.sharingType = .none` 한 줄 추가 — 창을 CGWindowListCreateImage/screencapture/화면녹화 스트림에서 완전 제외한다(1Password 등 표준 시크릿 매니저가 하는 것). 사용자 행동 0. 유일한 부작용은 정상 화면공유(Zoom 등)에서 앱 창이 검게 보이는 것 — 이를 피하려면 기존 clipboard 메서드 채널을 미러링해, 값이 reveal된 동안에만 `.none`으로 토글하고 평소엔 `.readOnly` 유지(여전히 무마찰). (2) AX 트리: secret_detail.dart:388의 revealed `Text`를 `ExcludeSemantics`(또는 `Semantics(excludeSemantics: true)`)로 감싸 복호값이 semantics/AX 트리에 절대 실리지 않게 한다 — VoiceOver가 값을 읽어주지 못하는 트레이드오프뿐(마스킹 대상 시크릿엔 수용 가능, 사용자 행동 0). sharingType 단독은 이미지 캡처만 닫고 AX 벡터는 못 닫으므로 둘 다 필요.
- **근거**: `macos/Runner/MainFlutterWindow.swift:4-51 (sharingType 미설정); lib/features/secrets/presentation/widgets/secret_detail.dart:389`  · 위협모델 TM2-malware

## [MEDIUM] at-rest · gap-real
- **공격**: 마이그레이션 강제백업·pre-rotation .kbx가 크래시 시 support dir(표준 캡처 위치)에 잔존
- **경로**: 마이그레이션 중 강제 자동백업 .kbx(key_box.backup-<epoch>.kbx)는 성공 시 삭제되나(vault_migrator.dart:555-556), 백업 기록 후~정리 전 크래시면 support dir에 잔존. pre-rotation .kbx(key_box.vault.prerotate.kbx)는 회전 커밋 시 삭제되나(pre_rotation_backup_store.dart:36-40) 회전 중 크래시면 잔존. 둘 다 사용자 선택이 아닌 '앱 표준 디렉토리'에 놓여 전체 캡처에 반드시 포함 → 위의 .kbx 평문메타/무차별 공격 대상이 됨(무마찰로 항상 캡처됨).
- **현재 방어**: 성공 경로에서 원자적 tmp+rename 후 삭제(vault_migrator.dart:378-383, pre_rotation_backup_store.dart:29-34). 정상 종료 시 잔해 없음.
- **격차**: 크래시 창에서 support dir에 브루트포스 가능+평문메타 .kbx가 남음. 무마찰 완화: 부팅 시 support dir의 고아 .kbx(backup-*/prerotate)를 정리하는 스윕 추가(현재 recoverInterrupted는 DB 잔해만 처리, .kbx는 대상 아님, vault_migrator.dart:147-154).
- **무마찰 수정**: Add a boot-time orphan-.kbx sweep (zero user friction — pure housekeeping) alongside the existing recoverInterrupted call at auth_notifier.dart:179. Two rules: (1) Unconditionally delete any key_box.backup-*.kbx in supportDir at boot — migration is one-shot and self-cleaning, so these are never a live recovery net and must never outlive their migration. (2) Delete key_box.vault.prerotate.kbx ONLY AFTER the boot state machine has resolved that no interrupted rotation is pending — because prerotate.kbx doubles as the case-B recovery net the user restores with the OLD password (auth_notifier.dart:719-729). Gate the prerotate sweep behind 'staged sidecar absent / rotation resolved' so a genuine crashed-rotation snapshot is preserved for its resume path and only a truly-orphaned one is removed. Also harden the success path: the best-effort prerotate delete at auth_notifier.dart:657-660 swallows failures — the boot sweep is the backstop that guarantees eventual removal. Per project rule, mutation-test the new gate: inject a leftover backup-*.kbx + an orphan prerotate.kbx, boot, assert both gone; negative test — a pending-rotation prerotate.kbx is NOT swept.
- **근거**: `lib/core/vault/vault_migrator.dart:357-384; lib/core/backup/pre_rotation_backup_store.dart:20-40`  · 위협모델 TM3-diskimage

## [LOW] at-rest · gap-real
- **공격**: macOS 상태 복원(Saved Application State)·window server 스냅샷이 잠금 해제 화면 이미지를 디스크에 잔류시켜 도난 시 유출 가능
- **경로**: applicationSupportsSecureRestorableState=true라 macOS가 ~/Library/Saved Application State/<bundle>.savedState/에 창 복원 데이터를 기록하고, content protection 부재로 App Nap/Exposé용 window 스냅샷 비트맵이 캐시됨 → 공격자가 도난 Mac에서 해당 디렉토리 및 window server 캐시를 읽어 reveal된 시크릿이 담긴 화면 이미지를 획득.
- **현재 방어**: 없음 — 상태 복원 활성, content protection 미설정.
- **격차**: 상태 복원 비활성화(restorable=false / NSQuitAlwaysKeepsWindows=false)나 sharingType=.none이 없어 잠금 화면 스냅샷이 디스크에 남을 여지. 단 Flutter 뷰가 실제로 스냅샷에 캡처되는지는 미검증이라 추정적(honest caveat) — 확인 필요. 무마찰 방어: 상태 복원 비활성 + content protection.
- **무마찰 수정**: macos/Runner/MainFlutterWindow.swift의 awakeFromNib()에서 contentViewController 설정 직후 무마찰 2줄 추가 — (1) self.isRestorable = false : NSWindow 기본값 isRestorable=true를 끄면 macOS가 종료/은닉 시 ~/Library/Saved Application State/<bundle>.savedState/에 남기는 '즉시복원용 렌더 이미지'(reveal된 시크릿이 담길 수 있는 유일한 durable 디스크 잔류물)를 아예 생성하지 않는다. (2) 라이브 캡처 경로(Mission Control/Exposé 스냅샷·스크린 레코딩·화면 공유)까지 닫으려면 self.sharingType = .none 추가(1Password류 시크릿 매니저 표준 하드닝, 사용자 추가 행동 0 — 다만 사용자가 앱을 스크린샷 못 찍게 되는 제품 결정 포함). AppDelegate.swift:10-12의 applicationSupportsSecureRestorableState는 true로 유지하라 — 이건 복원 활성 스위치가 아니라 복원 디코딩에 NSSecureCoding을 쓰는 별개의 보안 강화이며, false로 뒤집으면 코딩 보안만 낮아지고 deprecation 경고가 난다. 최소 at-rest 방어는 isRestorable=false 단독으로 충분.
- **근거**: `macos/Runner/AppDelegate.swift:10-12`  · 위협모델 TM1-physical

## [LOW] at-rest · gap-real
- **공격**: 아카이브 내 record가 empty-AAD라 파일 간 레코드 치환에 무저항(값 자체는 GCM 보호)
- **경로**: 동일 MEK를 공유하는 두 .kbx(예: 회전 전후) 사이에서, 한 아카이브의 record 암호문 블록을 다른 아카이브로 옮겨도 empty-AAD라 GCM이 통과함(vault_backup_service.dart:299-315은 복호 시 AAD 미사용). DB는 secretAad(id:version) 바인딩으로 치환 방어(secret_encryption_service.dart:26-30)되나 아카이브는 그 바인딩이 없음. import 시 사용자가 조작된 아카이브를 복원하면 특정 시크릿을 옛/타 레코드 값으로 바꿔치기 가능.
- **현재 방어**: 값은 여전히 MEK-GCM 인증 — 임의 위조·복호는 불가(비번/ MEK 없이는 무의미). AAD 미적용은 '아카이브는 행 identity가 없다(복원 시 id 바뀜)'는 설계 의도(vault_backup_service.dart:56-65).
- **격차**: 순수 at-rest 복호 위협모델에서의 직접 피해는 낮음(치환은 '복원'이라는 사용자 행위+MEK 필요). 무마찰 완화: 아카이브에 파일 단위 무결성 태그(전체 records에 대한 MAC)를 추가해 파일 간 블록 이식을 차단.
- **무마찰 수정**: 파일 단위 무결성 태그(전체 records에 대한 MAC)를 아카이브 헤더에 추가. 무마찰(사용자 추가 행동 0): export 시점에 이미 손에 있는 MEK에서 HKDF 도메인분리 서브키(예: label `keybox/archive-mac/v1`, 레코드 암호화용 MEK 사용과 분리)를 파생해, 모든 record의 정규 직렬화(각 record의 encryptedValue||iv||authTag||plaintext 메타데이터를 순서대로 + recordCount)에 대해 HMAC-SHA256(또는 AES-GCM 태그)를 계산하고 base64로 헤더에 저장한다. import에서는 sourceMek unwrap 성공(vault_backup_service.dart:203-205) 직후, _reencryptRecords(:206) 이전에 파싱된 records 위에서 MAC을 재계산해 불일치 시 ArchiveImportCorrupt로 거부한다. 이렇게 하면 모든 record 블록이 한 파일에 묶여, 다른 same-MEK 아카이브에서 이식한 블록은 전체 파일 MAC을 깨뜨린다. 대안(동등 효과): export마다 랜덤 archive-nonce를 헤더에 넣고 각 record의 AAD에 nonce(+index)를 엮으면(secret_encryption_service.encrypt의 aad 인자 사용) 타 아카이브 블록이 GCM에서 실패 — 역시 무마찰. 전자(파일 MAC)가 지목된 공격(블록 이식)에 가장 직접적이고 깔끔하다.
- **근거**: `lib/core/backup/vault_backup_service.dart:56-65, 299-320; lib/core/encryption/secret_encryption_service.dart:21-30`  · 위협모델 TM3-diskimage

## [CRITICAL] entitlements · gap-accepted
- **공격**: task_for_pid 기반 프로세스 메모리 덤프로 MEK/PDK/dbKey/평문 직접 추출 (ad-hoc 서명이 get-task-allow 자동 부여)
- **경로**: 같은 사용자 권한(비-루트) 멀웨어가 실행 중인 key_box pid에 task_for_pid()를 호출한다. ad-hoc 서명은 com.apple.security.get-task-allow를 자동 부여하고 hardened runtime은 get-task-allow 타깃에 대해 attach를 막지 않으므로 task 포트 획득이 성공한다(또는 lldb/frida attach). vm_read로 힙을 스캔해 (a) AuthUnlocked.masterEncryptionKey에 세션 내내 상주하는 32B MEK, (b) unlock 순간 잠깐 사는 PDK/KEK 버퍼, (c) database.dart가 만든 dbKey hex String, (d) reveal/copy로 만들어진 평문 Dart String을 뽑아낸다. MEK만 얻으면 모든 레코드 값을 오프라인 복호화, dbKey만 얻으면 DB 파일을 통째로 연다.
- **현재 방어**: hardened runtime(Release.entitlements 주석이 명시) + lock() 시 MEK zero-out(auth_notifier.dart:952) + unlock/setup/changePassword의 finally에서 PDK·KEK·salt·wrappedMek zero-out. 디스크 저장은 절대 없음.
- **격차**: ad-hoc 서명(TeamIdentifier 미설정)이 get-task-allow를 자동 부여 → 같은 사용자 프로세스의 task_for_pid/attach가 성공한다. F2(메모리 추출) 방어는 Developer ID 서명(get-task-allow 부재) 시에만 완성된다. 잠금 전까지 MEK는 세션 전체(최대 auto-lock 15분, 활동 중이면 무기한) 평문으로 상주한다.
- **무마찰 수정**: 완전 무마찰. (1) 릴리스 빌드를 Developer ID 인증서 + notarization으로 서명(하드런타임 유지, get-task-allow 부재 유지) — ad-hoc 번들의 재서명+재실행 변조 벡터를 봉쇄하고 서명을 앵커링한다. 사용자 추가 행동 0. (2) dogfood는 반드시 릴리스(하드런타임) .app로만 — `flutter run`(DebugProfile.entitlements: 하드런타임 없음 + get-task-allow 주입 → 프로세스 통째로 덤프 가능)로는 dogfood 금지. (3) 심층방어(선택, 저마찰): auto-lock 시간 단축 + 창 포커스 상실 시 lock → MEK 상주 창을 좁힘(제거는 불가, 복호화에 키가 메모리에 있어야 하므로).
- **근거**: `macos/Runner/Release.entitlements:1-22 (hardened runtime이 get-task-allow를 거부하지 못함, ad-hoc); lib/features/auth/domain/auth_state.dart (AuthUnlocked.masterEncryptionKey 세션 상주)`  · 위협모델 TM2-malware

## [HIGH] in-memory · gap-accepted
- **공격**: 잠금 해제 상태로 자리를 비운 Mac에서 공격자가 UI로 모든 시크릿을 직접 열람 (auto-lock 기본 15분 무방비 창)
- **경로**: 사용자가 vault를 unlock한 뒤 화면 잠금 없이 자리를 비움 → 물리 접근 공격자가 기본 15분(autoLockMinutes=15) 유휴 타임아웃이 끝나기 전에 접근 → 시크릿 행 클릭 → reveal(눈 아이콘) 또는 복사 버튼으로 평문 획득. revealByDefault가 켜져 있으면(settings_preferences.dart:38) 행 선택만으로 자동 복호화·표시되어 클릭 한 번에 평문 노출.
- **현재 방어**: AutoLockService 유휴 타이머만. 기본 15분, 활동(pointer/key) 시 리셋 (auto_lock_service.dart:62-71).
- **격차**: 기본 15분은 물리 접근에 사실상 무방비. 최소 선택지도 1분(autoLockOptions=[1,5,15,30]). 활동 기반 타이머만 존재하고 '즉시 잠금' 이벤트 트리거가 없어, 공격자가 창 안에 도달하면 전면 열람.
- **무마찰 수정**: 무마찰 강화 = macOS 화면잠금/스크린세이버 시작 알림에 vault lock을 훅킹. 새 MethodChannel(clipboard_service.dart:19의 'keybox/secure_clipboard' 채널 패턴 그대로 재사용)로 네이티브 측 distributed notification `com.apple.screenIsLocked`(또는 NSWorkspace `screensDidSleepNotification`/`sessionDidResignActiveNotification`)를 구독 → Dart에서 수신 시 `ref.read(authProvider.notifier).lock()`(auth_notifier.dart:941, MEK zero-out) 호출. 배선 위치는 기존 `_WindowListenerWrapper`(main.dart:56)에 리스너 추가. 이는 사용자가 이미 자리를 뜨고 OS 화면이 잠긴 순간에만 발화하므로 능동 사용 중 추가 행동/재입력이 전혀 없다(무마찰) — 15분 유휴 창을 '화면 잠금 시점'으로 축소한다. 주의: window-blur/Cmd-Tab 기반 잠금은 매 컨텍스트 전환마다 재-unlock(비번 재입력)을 강제하므로 마찰 방어라 제외. 기본 15분→5분 하향은 순수 튜닝이나 능동 사용자 재-unlock 빈도를 높이는 트레이드오프라 부차적.
- **근거**: `lib/core/constants/app_constants.dart:23, lib/services/auto_lock_service.dart:62-71, lib/features/settings/domain/settings_preferences.dart:14`  · 위협모델 TM1-physical

## [HIGH] exfil-channel · gap-accepted
- **공격**: 창에 캡처 방지가 없어 스크린샷·화면 녹화·화면 공유·Mission Control 썸네일로 표시된 시크릿을 획득
- **경로**: 시크릿이 reveal된(또는 sheet_modal 편집 중) 상태에서 공격자가 screencapture CLI 실행, 또는 진행 중인 화면공유 세션(Zoom/원격 데스크톱/화면 녹화 malware)이 창을 캡처 → 평문 이미지 유출. Cmd-Tab·Mission Control 라이브 썸네일, 스크린세이버 전환 프레임에도 노출.
- **현재 방어**: 없음 (grep 결과 content protection/sharingType 미설정).
- **격차**: NSWindow.sharingType=.none(또는 content protection) 미설정 → window server 캡처·썸네일·화면공유에 창 콘텐츠가 그대로 노출. reveal/편집 화면에 한해 캡처를 차단하는 무마찰 방어 미구현.
- **무마찰 수정**: 무마찰(사용자 행동 0) — 2가지 옵션. [권장·최안전] Blanket: MainFlutterWindow.swift:5 awakeFromNib()에서 `self.sharingType = .none` 1줄 무조건 설정 → window server 캡처/녹화/Mission Control·Cmd-Tab 썸네일에서 창 원천 제외, 타이밍 레이스 없음(1Password/Bitwarden 표준 동작). [지목 정밀 매칭·차선] Scoped 토글: 기존 keybox/secure_clipboard 메서드 채널 패턴(MainFlutterWindow.swift:17-47) 재사용해 새 채널 keybox/capture_protection 등록, reveal/편집 sheet open 시 sharingType=.none, conceal/close 시 .readOnly 복원 → 비민감 UI 스크린샷 보존하며 "reveal/편집 화면에 한해" 차단. 단 스코프드는 reveal 탭 순간 이미 합성된 프레임·잔존 라이브 썸네일에 레이스 창이 남음 → blanket이 더 견고.
- **근거**: `macos/Runner/MainFlutterWindow.swift:4-51`  · 위협모델 TM1-physical

## [HIGH] code-integrity · gap-accepted
- **공격**: 실행 중(잠금 해제) 프로세스에 디버거를 attach해 MEK를 메모리에서 직접 읽음 — ad-hoc 서명이 get-task-allow를 자동 부여
- **경로**: ad-hoc 서명 빌드는 TeamIdentifier 부재로 get-task-allow가 자동 부여됨 → 물리 접근 공격자가 SIP 우회 없이 `lldb -p <pid>` 또는 task_for_pid로 attach → AuthUnlocked.masterEncryptionKey(Uint8List) 및 reveal된 평문을 힙에서 덤프. 잠금 해제 상태의 실행 중 앱이면 즉시 성립.
- **현재 방어**: Release.entitlements에 debug/JIT 권한 없음, hardened runtime 의도. lock() 시 MEK zero-out.
- **격차**: 현재 서명이 ad-hoc → get-task-allow 자동 = 디버거 attach 허용. F2(MEK 추출) 방어는 Developer ID 코드서명(+notarization)으로 get-task-allow가 제거될 때만 완성. disable-library-validation(Release.entitlements:15-16)은 dylib 로드만 완화한다고 주석하지만, 서명 부재 자체가 attach 차단을 무력화. 무마찰 방어: Developer ID 서명 + hardened runtime 배포.
- **무마찰 수정**: 배포(ship) 시점에 Developer ID Application 서명 + notarization + staple 적용(hardened runtime는 이미 project.pbxproj:729 ENABLE_HARDENED_RUNTIME=YES). 이는 100% 무마찰 — 사용자가 추가로 하는 행동이 전혀 없고, 빌드/서명/공증 파이프라인에서만 처리됨. Developer ID + notarization이 코드서명에 외부 신뢰 앵커를 부여하면 (a) 실행 중 pristine 프로세스의 task_for_pid가 커널에서 확정 차단되고 (b) 공격자가 get-task-allow를 넣어 재서명한 변종이 Gatekeeper/AMFI에서 거부되어, 재서명-후-다음-unlock 대기 우회로가 막힘. 부수적으로 Release.entitlements:13-14 주석("F2 defense stays intact")은 ad-hoc 구성에서 과신이므로 "Developer ID 서명 전까지는 미완성"으로 정정 필요.
- **근거**: `macos/Runner/Release.entitlements:5-21`  · 위협모델 TM1-physical

## [HIGH] at-rest · gap-accepted
- **공격**: 잠금 해제 상태에서 슬립/스왑된 Mac을 도난 → 디스크의 swapfile/sleepimage에서 MEK·평문 잔류를 오프라인 복원
- **경로**: vault unlock 상태로 Mac이 슬립하거나 메모리 압박으로 MEK 페이지가 스왑됨 → 공격자가 전원 꺼진 Mac 탈취 → FileVault 미사용 시 /private/var/vm/swapfile*·sleepimage를 오프라인 마운트/카빙 → MEK Uint8List·복호화된 평문 String 바이트를 스캔 추출. DB는 SQLCipher로 막혀 있으나 스왑된 키가 있으면 DB까지 복호화 가능.
- **현재 방어**: DB는 SQLCipher at-rest 암호화, sidecar는 salt만 보관. lock() 시 MEK zero-out (auth_notifier.dart:983-988).
- **격차**: MEK·평문이 mlock/wired 되지 않아 스왑·하이버네이션 이미지로 평문 유출 가능. 앱은 FileVault 활성 여부를 확인/경고하지 않음. lock의 zero-out은 이미 스왑에 기록된 페이지를 되돌리지 못함. 무마찰 방어: 키 버퍼 mlock(page pinning) + FileVault 미활성 시 경고 배너.
- **무마찰 수정**: 무마찰 개선 = FileVault 안내 배너(온보딩/설정에 정보성 배너: "완전한 at-rest 보호를 위해 macOS FileVault를 켜세요 — 미활성 시 슬립 중 디스크로 페이징된 메모리는 이 앱이 암호화하지 못합니다"). 2차 password·추가 인증 없음(무마찰 정의 충족)이며, 잔여 sleepimage/FileVault-off 벡터를 실제로 닫는 올바른 플랫폼 컨트롤로 유도. 샌드박스에서 FileVault 상태 런타임 감지는 fdesetup/diskutil 셸 의존이라 곤란하니 감지 조건부가 아닌 무조건 보안 안내 문구로. (부수적 저비용 방어심층화: secret_encryption_service.dart:79-111 decrypt()의 중간 `output` Uint8List를 반환 전 try/finally로 zero-fill — 평문 Uint8List 사본의 힙 잔류 창을 줄임. 단 반환 String은 여전히 남으므로 벡터를 닫지는 못함.) 전면 mlock/off-heap FFI 리팩터는 권고 안 함: Dart String 미커버 + 압축 GC로 힙 Uint8List mlock 불신뢰 + macOS 기본 암호화 스왑과 중복 = 고비용 저효익, A 필수 아님.
- **근거**: `lib/features/auth/domain/auth_notifier.dart:983-988, lib/core/encryption/master_key_service.dart:1-40`  · 위협모델 TM1-physical

## [HIGH] in-memory · gap-accepted
- **공격**: zero-out 불가능한 불변 Dart String에 상주하는 dbKey hex와 평문값 — 메모리 덤프 수확량 확대·지속
- **경로**: 경로1(task_for_pid, race 위와 동일) 성립 후, 공격자는 Uint8List 키가 아니라 String을 노린다. database.dart:101에서 dbKey가 소문자 hex String으로 렌더링되어 연결 수명 내내(그리고 GC 전까지) 산다 — 이 hex를 캡처하면 앱이 잠기거나 종료된 뒤에도 `PRAGMA key="x'<hex>'"`로 key_box.db를 직접 열 수 있다(MEK와 독립된 2차 전체-DB 침해 키). changePassword/회전 재개의 rekey 문(auth_notifier.dart:648,754)도 dbKeyNew를 hex String으로 렌더링한다. 또한 reveal/copy/search/복원이 만든 모든 복호화 평문·감사 metadata가 불변 String이라 zero 불가 — 스왑으로도 샐 수 있다.
- **현재 방어**: Uint8List 키 소재(MEK/PDK/KEK/salt/wrappedMek)는 모든 경로 finally에서 _zeroOut으로 0 덮어쓰기. lock() 시 MEK 즉시 zero. macOS 스왑은 기본 암호화(현대 버전)라 스왑 유출은 부분 완화.
- **격차**: String 타입 키 소재(dbKey hex)와 모든 평문값은 Dart String 불변성 때문에 영원히 zero-out 불가(코드 내 TODO(PR-B/F5)로 이미 인지). dbKey hex는 MEK와 별개로 DB 전체를 여는 독립 키이며 연결 수명 내내 상주 → 덤프 시 수확량과 지속시간을 넓힌다.
- **무마찰 수정**: 무마찰 개선 방향(선택, A에 불필요): String 불변성 때문에 in-place zero는 불가능하므로 hex String을 아예 만들지 않는 것이 유일한 실질 제거책 — SQLCipher를 `PRAGMA key/rekey` 텍스트 보간이 아니라 raw-bytes C API(sqlite3_key_v2/sqlite3_rekey_v2)로 Uint8List를 직접 키잉하면 hex String(및 보간된 PRAGMA SQL String)이 존재할 필요가 없어져 zero 가능한 Uint8List 사본만 남는다. 단 SQLCipher raw-key(x'...')는 통상 PRAGMA 텍스트로만 표현되므로 SQLCipher 전용 FFI 없이는 막혀 있을 수 있음(feasibility 미확정). 잔여 수명은 이미 lock()→_releaseDb()로 setup 클로저+hexKey가 MEK zero와 동시에 GC-eligible이 되어 세션 범위로 한정됨. 따라서 이는 F5 계열로 이연된 defense-in-depth 항목이지 A 차단 요소가 아님.
- **근거**: `lib/core/database/database.dart:97-101; lib/features/auth/domain/auth_notifier.dart:648,754 (rekey hex String)`  · 위협모델 TM2-malware

## [HIGH] exfil-channel · gap-accepted
- **공격**: 클립보드 평문을 같은 사용자 프로세스가 폴링해 30초 창에서 탈취 (ConcealedType은 권고일 뿐)
- **경로**: 멀웨어가 NSPasteboard.general.changeCount를 루프로 폴링한다(어떤 TCC/권한도 불필요). 값이 바뀌면 stringForType(.string)을 읽어 복사된 시크릿 전체 평문을 최대 30초간 확보한다. MainFlutterWindow.swift:44가 값을 .string 타입으로 평문 기록하기 때문에 마커와 무관하게 그대로 읽힌다. org.nspasteboard.ConcealedType은 협조적인 클립보드 매니저(Paste/Maccy)만 존중하는 권고 메타데이터라 멀웨어는 무시한다.
- **현재 방어**: 복사 30초 후 자동 소거(clipboard_service.dart:28-32) + ConcealedType 태깅(MainFlutterWindow.swift:38-45)으로 클립보드 매니저의 영속/동기화 억제 + 조용한 카운트다운 링 가시화.
- **격차**: 값이 일반 페이스트보드에 .string 평문으로 실제 기록되므로(MainFlutterWindow.swift:44) 임의 프로세스가 폴링으로 즉시 읽는다. 30초 창은 넉넉하고, 클립보드 읽기를 앱에 바인딩할 방법이 없다. 무마찰 방어의 한계 지점.
- **무마찰 수정**: 근본적 무마찰 차단은 불가능(macOS 클립보드는 앱에 바인딩 불가한 공유 OS 리소스 — copy-paste의 본질). 평문 `.string` 기록(MainFlutterWindow.swift:44)은 붙여넣기 대상이 임의 앱이므로 제거 불가. 다만 노출 창을 줄이는 무마찰 개선은 가능: (1) auto_lock_service의 lock() 및 창 blur/포커스 상실 시점에 clipboard_service._clearClipboard()도 함께 호출해 창을 30초→실사용시간으로 단축(사용자 추가행동 0). (2) clipboardClearSeconds를 15초 등으로 단축. 두 조치 모두 폴링 캡처 자체를 막지는 못하고(1Hz 폴러면 창 내 캡처됨) 창만 좁힌다. 실질적 잔여위험 제거는 이 경로가 아니라 상위 노출(ad-hoc 서명 get-task-allow → 메모리 덤프, B2 격차)을 닫는 것(Developer ID 서명)으로만 의미 있음. 클립보드 방어 자체는 현재 ConcealedType+auto-clear가 무마찰 best-practice 상한이라 추가 필수 조치는 불필요.
- **근거**: `macos/Runner/MainFlutterWindow.swift:43-46; lib/services/clipboard_service.dart:24-32`  · 위협모델 TM2-malware

## [HIGH] code-integrity · gap-accepted
- **공격**: disable-library-validation로 인한 악성 dylib 인-프로세스 로드 (사용자 쓰기가능 설치 위치일 때)
- **경로**: key_box가 사용자 쓰기가능 위치(~/Applications·~/Downloads·Desktop — admin 불필요)에 설치돼 있으면, 멀웨어가 .app 번들의 Frameworks 안 dylib(예: SQLCipher.framework 교체 또는 플러그인 투입)를 ad-hoc/타 팀 서명으로 덮어쓴다. 다음 실행 때 disable-library-validation이 팀-ID 미co-sign dylib의 로드를 허용 → 공격자 코드가 프로세스 내부에서 실행되어 task_for_pid 없이도 MEK/평문에 직접 접근한다.
- **현재 방어**: app-sandbox + hardened runtime. DYLD_INSERT_LIBRARIES 환경변수 주입은 차단됨(com.apple.security.cs.allow-dyld-environment-variables 미부여). Release.entitlements 주석이 disable-library-validation을 'co-sign 완화 전용, debugger attach 재활성 아님'으로 스코프 명시.
- **격차**: disable-library-validation이 팀-ID co-sign 요구를 제거하므로 번들이 사용자 쓰기가능일 때 디스크상 framework/dylib 치환으로 공격자 코드가 로드된다. ad-hoc 서명이라 번들 전체를 검증할 팀 서명 무결성도 없어 변조 탐지도 안 된다. /Applications(admin 필요) 설치 시엔 완화됨 — 설치 위치 의존.
- **무마찰 수정**: 사용자 무마찰 수정 = B2 원격조치(Developer ID 서명 + notarization + hardened runtime)를 배포 시점에 적용. 그 시점에 Flutter/SQLCipher framework가 단일 Team ID로 재서명되므로 library validation이 성립 → disable-library-validation을 제거하면 Team-ID 미일치 dylib(공격자 ad-hoc)이 로드 단계에서 거부된다. 이는 순수 개발자/배포 노동이며 최종 사용자 행동을 요구하지 않는다(오히려 Gatekeeper 경고 제거로 마찰 감소). 단 baseline A(개인 dogfood, `open .app`)에는 불필요 — 배포 전제. 주의: 엔타이틀먼트만 지우는 것은 유효한 fix가 아니다 — ad-hoc 상태에서는 (1) 번들 프레임워크 로드가 launch에서 실패하고 (2) 번들 쓰기 가능한 공격자가 전체 번들을 ad-hoc 재서명하면 library validation을 그대로 통과하므로 방어가 안 된다.
- **근거**: `macos/Runner/Release.entitlements:15-16`  · 위협모델 TM2-malware

## [MEDIUM] exfil-channel · gap-accepted
- **공격**: ConcealedType 마킹은 조언에 불과하고 .string 타입에 평문이 상존 → 이를 무시하는 매니저·스크립트·Universal Clipboard가 평문 캡처/동기화
- **경로**: 시크릿 복사 → 네이티브 핸들러가 .string과 org.nspasteboard.ConcealedType 둘 다에 평문을 기록 → ConcealedType을 존중하지 않는 클립보드 매니저나 `pbpaste`/NSPasteboard.string을 직접 읽는 스크립트가 평문을 저장. iCloud Universal Clipboard가 켜져 있으면 인근 사용자 기기로도 30초 내 유출. 네이티브 채널 실패 시 폴백은 마킹 없이 순수 평문만 기록.
- **현재 방어**: org.nspasteboard.ConcealedType 태깅으로 Paste/Maccy 등 협조 매니저의 영구 저장·동기화 스킵 유도 (MainFlutterWindow.swift:38-46).
- **격차**: 마킹은 강제력 없는 관례일 뿐 .string에 평문이 상존 → 임의 프로세스가 읽음. PlatformException/MissingPluginException 폴백 경로(clipboard_service.dart:41-45)는 마킹조차 없이 평문. Universal Clipboard 유출 경로 미차단.
- **무마찰 수정**: 불필요 (방어 충분 for 기준선 A). 핵심 잔여(=.string에 평문 상존)를 없애는 무마찰 수정은 원리상 불가능하다 — 복사한 시크릿이 붙여넣기 가능하려면 반드시 읽기 가능한 pasteboard 타입(.string)에 평문이 있어야 하고, macOS NSPasteboard는 iOS의 UIPasteboardOptionLocalOnly/expiration 같은 공개 API가 없어 Universal Clipboard 배제도 공개 API로는 불가하다. 유일한 레버인 30초 자동소거는 이미 구현됨(clipboard_service.dart:28-31,48-51). 선택적 DiD 두 가지가 무마찰이나 A에는 불요이자 사실상 무의미: (1) Dart 폴백(clipboard_service.dart:41-45)에도 ConcealedType 마킹 적용 — 단 프로덕션 macOS에선 네이티브 핸들러가 awakeFromNib에서 무조건 등록(MainFlutterWindow.swift:11-47)되므로 이 폴백은 도달 불가 → 순전히 cosmetic. (2) org.nspasteboard.TransientType를 함께 선언해 더 많은 매니저의 협조를 유도 — 그래도 비협조 리더의 .string 읽기는 못 막음.
- **근거**: `macos/Runner/MainFlutterWindow.swift:38-46, lib/services/clipboard_service.dart:36-46`  · 위협모델 TM1-physical

## [MEDIUM] at-rest · gap-accepted
- **공격**: 평문 salt sidecar + 암호화 DB 동시 확보로 오프라인 비밀번호 무차별 대입
- **경로**: 멀웨어가 key_box.db(암호문)와 key_box.vault.json(평문 salt)을 복사한다. 오프라인에서 후보 비밀번호마다 PBKDF2-HMAC-SHA256(600k) → HKDF dbKey → SQLCipher 페이지 HMAC 검증을 돌린다. 일치하면 전부 복호화. 동일 디렉터리의 비인증 평문 salt가 정확한 KDF 입력을 그대로 넘겨준다.
- **현재 방어**: 600k PBKDF2 반복 + 12자 최소 비밀번호(crypto_constants.dart:34, T7로 8→12 상향). salt는 설계상 비밀이 아님. sidecar는 CryptoConstants와 다른 KDF 파라미터(반복수 다운그레이드 등)를 손상으로 취급.
- **격차**: 유일한 장벽이 비밀번호 엔트로피 × KDF 비용뿐. salt를 손에 쥔 자원 있는 오프라인 공격자에겐 사람이 외우는 12자 비밀번호도 사정권. Secure Enclave 등 하드웨어 바인딩이 없어 볼트가 머신에 묶여 있지 않다 — 파일만 있으면 어디서든 공격 가능.
- **무마찰 수정**: 두 가지 무마찰 강화(사용자 추가 행동 0):

1) KDF를 PBKDF2 → Argon2id(메모리-하드)로 이관. 이 공격의 핵심 조력자는 GPU/ASIC 병렬성이다 — PBKDF2-HMAC-SHA256은 순수 연산이라 GPU당 저비용 대량 시도가 가능(600k iters ~10^4 guess/s/GPU). Argon2id는 메모리 대역폭에 병목을 걸어 GPU/ASIC 이득을 무력화한다. OWASP 현행 권고도 Argon2id > scrypt > bcrypt > PBKDF2 순서(PBKDF2 600k은 '폴백' 티어). sidecar 스키마(sidecar_store.dart:121-127)가 이미 algorithm/iterations 필드를 검증하므로 KDF 버전드 마이그레이션이 구조적으로 용이. 사용자 체감 변화는 잠금해제 타이밍뿐.

2) macOS Keychain/Secure Enclave의 기기 바인딩 비밀을 at-rest DB 파생에만 혼합(peppering). 반출된 db+sidecar만으로는 오프라인 크래킹 불가 — 공격자가 피해자 기기에서 SE 호출 코드를 실행해야만 dbKey 파생 가능해진다. 무마찰. 단서: Keychain ACL이 앱 코드서명(안정 Team ID)에 바인딩돼야 견고 → 현재 ad-hoc 서명(B2 격차)이므로 Developer ID 서명 작업과 함께 진행. 휴대용 .kbx 백업은 설계상 비밀번호-온리 유지(사용자가 의도적으로 export). 이 둘은 필수가 아니라 향후 하드닝 — 기준선 A(개인 dogfood)에는 불필요.
- **근거**: `lib/core/vault/sidecar_store.dart:176-186 (평문 salt); lib/core/constants/crypto_constants.dart:1-34`  · 위협모델 TM2-malware

## [MEDIUM] at-rest · gap-accepted
- **공격**: 볼트 전체 롤백 — 외부 단조(anti-rollback) 상태 부재
- **경로**: 멀웨어가 T1 시점에 (key_box.db, key_box.vault.json) 쌍을 스냅샷한다. 사용자가 자격증명을 폐기하거나 비밀번호를 변경하게 둔 뒤, T2에 두 파일을 T1 쌍으로 덮어쓴다. 다음 unlock에서 볼트가 조용히 T1 상태로 되돌아간다(폐기된 시크릿 부활, 비밀번호 변경 취소). 레코드별 AAD 버전 바인딩은 한 DB '안'의 치환/롤백만 막을 뿐 파일 전체 교체는 막지 못한다.
- **현재 방어**: AAD가 레코드마다 (secretId, recordVersion)을 바인딩(secret_encryption_service.dart:26-30) → 레코드 치환·값 롤백 차단. sidecar 원자적 쓰기(tmp→rename). 회전 저널로 크래시 창 수렴.
- **격차**: DB 밖 어디에도 단조 카운터가 없어 과거의 정합한 (DB, sidecar) 쌍이 모든 검사를 통과한다. 무마찰 완화(예: Keychain에 세대 번호 보관 — 사용자 마찰 없음)가 존재하지 않는다. 전체-파일 롤백은 미탐지.
- **무마찰 수정**: macOS Keychain 세대 카운터(무마찰). 샌드박스 앱은 자기 access group(bundle ID) Keychain 아이템을 사용자 상호작용 0으로 R/W → 프롬프트·동의창 없음. 설계: 단조 증가 generation을 DB(SQLCipher 보호, 예: vault_config.generation)와 Keychain 양쪽에 저장, 상태 변경 커밋마다 증가(시크릿 create/update/delete, changePassword ④ updateKeyMaterial + ⑥ promoteStaged). unlock 시 DB open 후 비교: db.generation < keychain.generation → 롤백 탐지 → 조용한 되돌림 대신 변조 경고 노출. 지목된 공격은 두 컨테이너 파일(key_box.db(+WAL/SHM), key_box.vault.json)만 스냅샷하는데 Keychain 아이템은 그 파일 집합 밖(시스템 관리 keychain-db)에 있어, 복원 후에도 더 높은 세대를 유지 → 명세된 공격을 탐지. Keychain 쓰기는 best-effort·읽히는 세대가 있을 때만 강제(Keychain 장애가 unlock을 벽돌로 만들지 않게). 정직 단서: 같은 UID 멀웨어가 Security API로 Keychain 자체를 조작할 여지는 남으나 파일 덮어쓰기보다 훨씬 높은 문턱이고, 명세된 2-파일 공격 범위 밖. pubspec에 Keychain 플러그인 신규 필요(현재 미포함).
- **근거**: `lib/core/encryption/secret_encryption_service.dart:26-30; lib/features/auth/domain/auth_notifier.dart:563-687 (changePassword)`  · 위협모델 TM2-malware

## [MEDIUM] at-rest · gap-accepted
- **공격**: DB 파일+sidecar 오프라인 무차별(잘 보호된 형제 — 메타데이터는 지켜지나 값 크래킹 오라클 존재)
- **경로**: 전체 캡처로 key_box.db + key_box.vault.json(sidecar) 동시 확보. sidecar에서 salt 파싱(평문 JSON). 추측마다 PBKDF2-600k→HKDF dbKey→SQLCipher keyed open 시도, 페이지1 HMAC 검증이 오라클(성공=비번 확정). 이후 DB 내부 vault_configs에서 wrappedMek/records 복호화.
- **현재 방어**: 전체 파일 암호화(plaintext_header_size=0)로 파일이 랜덤과 구별 불가 — 크래킹 성공 전엔 스키마·메타데이터·wrappedMek 전부 불투명(cipher_params.dart:22, database.dart:110-113). wrappedMek이 암호화 DB 내부라 .kbx와 달리 무크래킹 노출 없음(vault_configs.dart:11).
- **격차**: 오라클 비용은 여전히 PBKDF2-600k 단일(위 항목과 동일 근본원인). sidecar salt는 표준 위치(DB 옆)라 전체 캡처 시 항상 동반 — salt 분리 이점(아래 항목)이 전체 캡처에선 무효. 무마찰 레버: 동일하게 KDF 하드닝.
- **무마찰 수정**: 무마찰 레버 = 비밀번호→PDK 단계를 메모리-하드 KDF(Argon2id 우선, 대안 scrypt)로 교체. 사용자는 같은 비밀번호를 그대로 입력 → 마찰 0. PBKDF2-600k가 못 막는 GPU/ASIC 병렬 무차별을 메모리 비용으로 차단한다. 반드시 별건이 아니라 형제 KDF-하드닝 항목과 하나로 묶어서 처리(동일 근본원인). 마이그레이션 배관은 이미 존재: sidecar가 kdf.algorithm/iterations/saltLength/keyLength를 기록·검증하고 불일치를 corruption 처리(sidecar_store.dart:121-127, 176-186)하므로, KDF 봉투 버전을 올려 다음 unlock 시 기존 vault를 재파생하면 됨(백업 .kbx 봉투도 동반 갱신). 주의: PBKDF2 iteration만 올리는 것은 fix가 아니다(수확 체감·여전히 GPU 병렬). 이 경로 고유의 구조 방어(full-file 암호화+wrappedMEK가 암호화 DB 내부)는 이미 완결이라 추가 조치 불요.
- **근거**: `lib/core/database/database.dart:90-116; lib/core/vault/sidecar_store.dart:85-119`  · 위협모델 TM3-diskimage

## [LOW] in-memory · gap-accepted
- **공격**: 코어 덤프 / 크래시 리포트에 키 바이트 잔존
- **경로**: 멀웨어가 unlock 상태에서 key_box 크래시를 유발하거나 대기한다. ad-hoc의 get-task-allow가 코어 생성을 허용하고 ReportCrash가 ~/Library/Logs/DiagnosticReports(같은 사용자 읽기 가능)에 리포트를 쓴다 → 스레드/레지스터/스택 조각에 MEK/PDK/dbKey 바이트가 포함될 수 있다.
- **현재 방어**: hardened runtime은 get-task-allow 없는 프로세스의 풍부한 크래시 산출물을 억제. lock() 시 MEK zero로 창 축소.
- **격차**: get-task-allow(ad-hoc)가 코어/크래시 산출물 풍부화를 재활성. 크래시 리포트는 같은 사용자 읽기 가능. 부분 데이터·크래시 필요 → 낮음. Developer ID 서명이 근본 완화.
- **무마찰 수정**: Developer ID 서명 + notarization으로 배포 (build/distribution 게이트, 사용자 마찰 0). 이것이 get-task-allow를 제거하고 hardened runtime이 register/stack 조각을 담은 풍부한 크래시 산출물을 억제하게 만드는 근본 완화 — 동시에 B2/F2(live task_for_pid 메모리 읽기) 격차도 함께 닫는다. 앱 코드 측 완화는 실효 없음: macOS 기본 RLIMIT_CORE=0으로 full core 파일은 이미 미생성(setrlimit 호출은 no-op), ReportCrash 진단 리포트는 hardened-runtime-without-get-task-allow로만 억제 가능하고, SIGSEGV 핸들러는 손상된 프로세스에서 타 스레드 레지스터를 신뢰성 있게 0으로 만들 수 없음.
- **근거**: `macos/Runner/Release.entitlements:1-22`  · 위협모델 TM2-malware

## [HIGH] at-rest · out-of-model
- **공격**: 마이그레이션 이전 시대의 평문 DB가 Time Machine/과거 백업 스냅샷에 영구 잔존
- **경로**: 앱 초기 버전/마이그레이션 전 볼트는 평문 SQLite(isPlaintextDb 헤더 'SQLite format 3', vault_migrator.dart:105). 사용자가 이후 SQLCipher로 마이그레이션해도 Time Machine·과거 디스크 이미지·클라우드 백업에는 마이그레이션 이전 '평문 DB 스냅샷'이 남아 있음. 공격자가 그 히스토리 스냅샷만 확보하면 비밀번호·크래킹 없이 전 시크릿을 평문으로 읽음.
- **현재 방어**: 현재 라이브 볼트는 SQLCipher 전체암호화(database.dart:101-113) + plaintext_header_size=0로 파일이 랜덤과 구별 불가(cipher_params.dart:22). 마이그레이션 성공 시 로컬 평문 잔해는 삭제.
- **격차**: 앱은 외부 백업 시스템(Time Machine·클라우드)의 과거 스냅샷을 파기할 수 없음 — 근본적 잔여. 무마찰 완전 해결책 없음(정직 보고). 부분 완화: 애초에 첫 부팅부터 암호화 상태로 생성해 '평문 시대'를 없애면 신규 사용자에겐 이 잔재가 생기지 않음(기존 평문 볼트 이력자에겐 소급 불가).
- **무마찰 수정**: 불필요 — 전향적(forward) 방어는 이미 코드에 구현됨. setup()(auth_notifier.dart:249-327)이 dbKey로 keyed open(database.dart:90-117 PRAGMA key)하므로 신규 볼트는 birth부터 SQLCipher 암호화 → 평문 SQLite 파일이 디스크에 존재한 적이 없어 Time Machine에 평문 스냅샷이 애초에 생기지 않는다. 잔여(pre-flip 평문 시대 볼트의 과거 백업 스냅샷)에 대한 무마찰 in-app 기술 수정은 존재하지 않는다: 샌드박스 앱은 OS 소유 APFS TM 스냅샷/iCloud/외장·네트워크 백업 대상에 도달·삭제할 수 없다(tmutil deletelocalsnapshots는 권한 부재+외장 미포함으로 부분적이며 사실상 차단). 마이그레이션 성공 시 tmutil best-effort 호출은 장식일 뿐 실질 방어가 아니다. 유일한 정직 조치는 방어가 아닌 고지(pre-flip 볼트 사용자에게 기존 백업에 평문 잔재 가능 안내)뿐이며, 이는 방어가 아니라 소급 불가 사실의 공개다.
- **근거**: `lib/core/vault/vault_migrator.dart:105-125`  · 위협모델 TM3-diskimage

## [MEDIUM] in-memory · out-of-model
- **공격**: 잠금 해제 상태에서 물리 메모리를 추출(콜드부트/Thunderbolt DMA/코어 덤프)해 MEK와 reveal된 평문을 복원; 평문은 Dart String이라 zero-out 불가
- **경로**: unlock된 프로세스가 살아있는 채로 공격자가 (a) 콜드부트로 RAM 잔류 스캔, (b) Thunderbolt/PCIe DMA(비-VT-d 환경), (c) 크래시/코어 덤프 유도 → AuthUnlocked.masterEncryptionKey와 함께, 한 번이라도 reveal/편집한 시크릿의 평문 String(secret_detail의 _decryptedValue, sheet_modal의 _originalValue·TextEditingController 버퍼)을 힙에서 추출.
- **현재 방어**: lock() 시 MEK zero-out. MEK는 AuthUnlocked에만 존재. sheet_modal은 종료 시 컨트롤러 clear + 참조 드롭 시도.
- **격차**: 잠금 해제 상태에서는 근본 방어가 없고(부분적으로 불가피), reveal된 평문이 Dart String으로 보관되어 zero-out이 원천 불가능(sheet_modal.dart:161-164 주석이 명시적으로 인정, secret_detail.dart:31). 메모리 pinning(mlock) 부재로 힙 덤프·DMA에 그대로 노출. 무마찰 완화: 평문 노출 최소화(reveal 자동 재마스킹/타임아웃) + 키 페이지 pinning.
- **무마찰 수정**: 주 방어(무마찰·in-model): reveal 자동 재마스킹 타임아웃. 현재 secret_detail.dart는 reveal 후 _decryptedValue(String)를 secret 전환(46-53)·편집 bump(64-74)·명시 Hide(237-241) 때만 null로 만들 뿐 시간 기반 재마스킹이 없어, 한 번 reveal하면 평문 String이 잠금해제 세션 내내 힙에 잔존한다. 클립보드는 이미 30초 자동소거(app_constants.dart:20 clipboardClearSeconds)가 있으나 reveal에는 대응물이 없다. 그 패턴을 그대로 이식하라: (1) app_constants.dart에 revealAutoMaskSeconds(예: 30) 추가, (2) _SecretDetailState에 Timer? _revealTimer 추가, (3) _toggleReveal의 reveal 분기(244-250)에서 타이머 시작→만료 시 setState로 _isRevealed=false·_decryptedValue=null(참조 드롭), Hide/secret 전환/편집 시 취소·리셋, (4) dispose()에서 _revealTimer.cancel()(widgets-and-state 규율: Timer→cancel 필수). 사용자는 아무 추가 행동도 안 하며 더 오래 필요하면 다시 Reveal만 누르면 되므로 완전 무마찰이고, 온스크린 shoulder-surf 노출과 힙 평문 창을 동시에 줄인다. 이것이 실질적 in-model 이득(walk-away/어깨너머)이다. MEK 쪽은 auto-lock 15분→lock()→_zeroOut(auth_notifier.dart:952)로 이미 유계이므로 추가 불요. mlock/page-pinning은 스왑 파일 유출만 막을 뿐 콜드부트·DMA·코어덤프는 못 막으므로 지목된 공격에 대한 답이 아니다(한계 효용, 선택). 지목된 물리 RAM 포렌식 자체는 Dart String zero-out 원천 불가 + 잠금해제·구동 중 물리접근 전제(화면 읽기가 더 쉬움)로 근본 방어 불가—개인 dogfood 위협모델 밖.
- **근거**: `lib/features/secrets/presentation/widgets/secret_detail.dart:31, lib/features/secrets/presentation/widgets/sheet_modal.dart:161-164`  · 위협모델 TM1-physical

## [MEDIUM] at-rest · defended
- **공격**: raw-key 모드가 SQLCipher 내부 256k KDF를 무효화 — 계층 KDF는 착시, 총 작업계수는 PBKDF2 600k 단일
- **경로**: DB/.kbx 어느 쪽이든 추측당 비용은 PBKDF2-600k 한 번뿐. DB는 raw-key 모드(x'<hex64>')로 32바이트 키를 페이지 키로 직접 사용 → SQLCipher의 kdf_iter=256000이 우회됨(cipher_params.dart:10-11 주석이 명시: 'unused in raw-key mode'). 따라서 '앱 PBKDF2 600k + SQLCipher 256k = 856k' 같은 심층방어가 실현되지 않고, 공격자 추측 비용은 600k에 고정.
- **현재 방어**: raw-key 모드 선택은 의도적(이미 PBKDF2+HKDF를 앱이 수행). 하드핀으로 온디스크 포맷 동결(cipher_params.dart:16-23). SHA512 HMAC 페이지 무결성.
- **격차**: 심층 KDF 스태킹이 없어 총 오프라인 작업계수가 단일 PBKDF2-600k. 무마찰 레버: 앱 측 KDF를 메모리-하드(Argon2id)로 올리거나 반복수 상향 — SQLCipher 내부 KDF는 raw-key라 손댈 수 없으므로 강화는 앱 KDF에서만 가능. (다운그레이드 취약점은 아님, 방어계수 관측치.)
- **무마찰 수정**: 불필요. 방어가 이미 충분(600k PBKDF2 = OWASP-2023 권장 하한)하고, raw-key 모드로 SQLCipher 내부 256k를 우회하는 것은 앱이 자체 KDF를 수행할 때의 정석·권장 설계다(무의미한 이중 KDF 회피). 856k 스태킹은 애초에 보장된 속성이 아니었다. 향후 강화가 필요할 경우(비-dogfood 릴리스, Riverpod 3 안정판 이후)의 유일한 레버는 앱 측 KDF뿐이다 — SQLCipher 내부 KDF는 raw-key라 손댈 수 없으므로 Argon2id(메모리-하드)로 교체하거나 PBKDF2 반복수 상향. 둘 다 무마찰(사용자 추가 행동 없음)이나 잠금 해제 지연 비용이 있다(현재 순수 Dart PBKDF2 600k = ~2.8s/derive로 이미 auth 도메인 테스트 타임아웃 플레이크 유발, MEMORY 기록). dogfood 기준선에는 불필요.
- **근거**: `lib/core/database/cipher_params.dart:8-23; lib/core/database/database.dart:101-113`  · 위협모델 TM3-diskimage

## [MEDIUM] at-rest · defended
- **공격**: 비밀번호 변경(회전) 후에도 과거 .kbx 백업이 옛 비번으로 여전히 크래킹·복호화 가능
- **경로**: 사용자가 (유출 의심 등으로) 비밀번호를 바꿔도, 회전은 sidecar salt를 새로 생성하고 DB만 rekey함(auth_notifier.dart:631-652). 과거에 내보낸 .kbx와 pre-rotation .kbx는 '옛 salt+옛 wrappedMek'을 그대로 담고 있어 옛 비밀번호로 여전히 오프라인 크래킹·복호화됨. 값이 회전되지 않은 시크릿은 옛 백업에서 현재값과 동일하게 복원됨(롤백형 노출).
- **현재 방어**: 회전 시 새 salt·새 KEK 래핑으로 라이브 DB는 즉시 옛 비번 무효화(auth_notifier.dart:555-652). AAD recordVersion 바인딩은 '같은 볼트 내' 회전값 롤백 방어(secrets.dart:21-24).
- **격차**: AAD 버전 바인딩은 개별 .kbx 파일 간에는 무력(각 아카이브는 empty-AAD로 자기완결적, vault_backup_service.dart:313-315). 회전이 과거 백업을 소급 무효화하지 못함 — 앱이 사용자 저장 위치의 옛 .kbx를 회수·파기할 수 없기 때문. 무마찰 완전해결 불가(정직). 부분 완화: 회전 시 pre-rotation .kbx(support dir 내, 위치 통제 가능분)를 확실히 파기.
- **무마찰 수정**: 불필요. 이 finding이 "부분 완화"로 제안한 '회전 시 pre-rotation .kbx 확실히 파기'는 이미 구현돼 있음 — auth_notifier.dart:656-660이 커밋 시점(promoteStaged, :652) 직후 _preRotationBackup.delete()를 호출하고, FilePreRotationBackupStore.delete()(pre_rotation_backup_store.dart:37-40)가 support dir 파일을 제거한다. best-effort(try/catch)는 의도된 트레이드오프(이미 커밋된 회전을 청소 실패로 실패시키지 않음 + 다음 회전 write가 같은 경로를 덮어씀)이며 gap-real이 아니다. 사용자 내보낸 .kbx(임의 위치·샌드박스 밖)에 대한 무마찰 수정은 존재하지 않음: 샌드박스 앱은 사용자가 복사해 둔 파일을 회수할 권한/도달성이 없고, 암호화 스냅샷의 안전성은 생성 시점에 동결되는 백업 본연의 성질이다. 게다가 vault 비번 회전은 시크릿 '값'을 바꾸지 않으므로, 완벽한 백업 무효화가 있어도 노출을 라이브 값 이하로 낮추지 못한다 — 유출 의심 시 실질 대응은 시크릿 값을 소스에서 회전(앱의 편집 기능)하는 것.
- **근거**: `lib/features/auth/domain/auth_notifier.dart:555-660; lib/core/backup/vault_backup_service.dart:313-315`  · 위협모델 TM3-diskimage

## [LOW] at-rest · defended
- **공격**: 단일 PDK가 모든 게이트를 열어 크래킹 비용이 곱해지지 않음(DB·아카이브 독립 salting 없음)
- **경로**: DB의 dbKey와 .kbx의 KEK는 같은 salt로 만든 동일 PDK에서 HKDF 도메인분리(key_hierarchy_service.dart:22-42). 추측 1회의 PBKDF2-600k 결과 PDK 하나로 dbKey·KEK 둘 다 파생 → DB 오라클과 .kbx 오라클이 같은 비용을 공유. 공격자는 가장 싼 오라클(.kbx)만 때려 전부를 얻음.
- **현재 방어**: HKDF info 라벨('keybox/v1/dbkey' vs '/kek')로 도메인 분리 — 서브키 상호 파생 불가(key_hierarchy_service.dart, crypto_constants.dart:20-21). 이는 서브키 격리로 올바름.
- **격차**: 도메인 분리는 맞지만 '추측당 비용 곱셈'은 없음(같은 PDK). 아카이브에 독립 salt/KDF를 주면 .kbx 오라클과 DB 오라클을 분리할 수 있으나, 어차피 단일 비밀번호이므로 이득은 제한적. 무마찰 레버는 여전히 KDF 하드닝 단일 지점. 근본 방어는 충분에 가까움 — 관측치.
- **무마찰 수정**: 불필요. 무마찰 레버(PBKDF2 600k + 최소 비번 12자, crypto_constants.dart:4,34)는 이미 적용돼 있고, 아카이브별 독립 salt는 무마찰이지만 단일-비번 모델에서 크래킹 비용을 곱하지 못한다(어느 오라클에서든 비번 복구 시 각 artifact의 salt로 전 키 재파생). 도메인 분리(HKDF info 라벨)는 이미 올바르게 구현됨. 추가 조치 없음.
- **근거**: `lib/core/encryption/key_hierarchy_service.dart:20-42; lib/core/constants/crypto_constants.dart:16-27`  · 위협모델 TM3-diskimage

## [LOW] at-rest · defended
- **공격**: sidecar 평문 JSON이 볼트 존재·KDF 파라미터·salt를 무크래킹 공개
- **경로**: key_box.vault.json을 열면 format·formatVersion·kdf{algorithm:PBKDF2-HMAC-SHA256, iterations:600000, saltLength, keyLength}·salt(base64) 전부 평문(sidecar_store.dart:176-186). 공격자는 키박스 설치 사실·정확한 KDF 설정·salt를 확보 → 오프라인 무차별 셋업을 즉시 구성. 복호화 자체엔 비번 필요하나 정찰 비용 0.
- **현재 방어**: salt는 암호학적으로 비밀이 아님(PBKDF2 salt는 유일성만 필요) — 노출이 곧 취약은 아님. 32바이트 랜덤 per-vault salt로 레인보우테이블/사전계산 무력화(key_derivation_service.dart:25-27, secure_random.dart). 파싱 시 KDF 파라미터가 상수와 다르면 손상 처리(다운그레이드 거부, sidecar_store.dart:92-127).
- **격차**: 존재/파라미터/salt 노출은 설계상 수용된 부분(salt 비밀 아님). 실질 격차 아님이나 at-rest 정찰 표면으로 열거. 무마찰 개선 여지 낮음 — 방어 대체로 충분.
- **무마찰 수정**: 불필요. 방어 충분. 무마찰 개선안(예: salt를 macOS Keychain으로 이전)조차 실질 격차를 닫지 못한다 — (a) PBKDF2 salt는 설계상 비밀이 아니라 유일성만 요구하고, (b) KDF 파라미터는 앱 바이너리에서 회수 가능한 컴파일타임 상수이며, (c) 파생은 sidecar 값이 아닌 하드핀 상수(CryptoConstants.pbkdf2Iterations)를 사용하므로 평문 노출/개조가 실제 work factor를 낮추지 못한다. 아키텍처 churn 대비 보안 이득 ~0.
- **근거**: `lib/core/vault/sidecar_store.dart:176-193`  · 위협모델 TM3-diskimage

## [INFO] race-toctou · defended
- **공격**: isPlaintextDb 프로브→open 사이 DB 스왑 (TM2에서 추출은 불가)
- **경로**: 멀웨어가 VaultMigrator.isPlaintextDb()와 키드 open(auth_notifier unlock:471) 사이에 key_box.db를 스왑해 평문 DB를 심어 레거시 마이그레이션 경로를 강제하려 시도한다.
- **현재 방어**: 마이그레이션은 어떤 비가역 작업 전에 사용자의 실제 PDK로 MEK 언랩을 요구한다(vault_migrator _unwrapConfigAndCheckpoint:323-326) → 공격자가 위조할 수 없는 config의 심은 DB는 wrongPassword로 중단, 평문 원본은 절대 수정되지 않음(_cleanupAbortedCopy, .pre-encryption 보존).
- **격차**: 없음 — 추출 불가(비밀번호 게이트 유지). 비동기 exists→open은 견고성/DoS 이음새일 뿐 기밀성 파괴는 아님. 방어 충분(참고용으로만 기록).
- **무마찰 수정**: 불필요 — 기밀성 방어 충분. (선택적 견고성 개선: isPlaintextDb의 exists→open을 단일 fd로 읽거나 프로브~keyed open 사이를 advisory lock/rename-into-place로 좁히면 이중 stat DoS 이음새가 사라지나, 무마찰이고 기밀성과 무관하므로 dogfood 필수 아님.)
- **근거**: `lib/core/vault/vault_migrator.dart:112-125; lib/features/auth/domain/auth_notifier.dart:471`  · 위협모델 TM2-malware

## [INFO] at-rest · defended
- **공격**: [방어 검증] salt 분리 — DB만 단독 캡처 시(sidecar 부재) 무차별 사실상 불가
- **경로**: sidecar 없이 key_box.db만 확보한 경우: salt는 오직 (a)평문 sidecar와 (b)암호화 DB 내부 vault_configs.masterKeySalt 두 곳뿐. DB를 열려면 dbKey가 필요하고 dbKey엔 salt가 필요한데 salt가 DB 안에 잠겨 있어 순환 → 공격자는 비번(엔트로피)+32바이트 랜덤 salt(256비트)를 동시 무차별해야 함 = 비현실적.
- **현재 방어**: salt를 DB 밖 sidecar에 두되 DB 내부에도 보관하는 이중 구조(sidecar_store.dart, vault_configs.dart:10). 부팅 시 salt 원천은 sidecar, 손상/부재 시 AuthVaultError(sidecar_store.dart:12-27).
- **격차**: sidecar가 DB와 같은 support dir에 상주해 '전체 디스크/Time Machine 캡처'에선 항상 동반 → 이 방어는 'DB만 따로 유출'된 좁은 경우에만 유효, .kbx는 자체 salt를 실어 무관. 실효 이득 제한적이나 부분 방어로 유효. 격차: 전체 캡처 시나리오에서 무력.
- **무마찰 수정**: 불필요. 방어가 충분하며, 지적된 '전체 캡처 시 무력'은 실제 보안 격차가 아니다. salt는 KDF salt로서 암호학적으로 공개(비밀 아님)가 전제인 값 — 그 목적은 레인보우테이블·교차 vault 사전계산 차단이지 비밀 엔트로피가 아니다. TM3-diskimage(Time Machine·전체 디스크)에서의 실제 at-rest 방어선은 PBKDF2-600k iters + 비번 엔트로피이며, 이것은 salt 노출 여부와 무관하게 온전하다. (선택적·무마찰 강화로 salt를 macOS Keychain으로 이전하면 전체 캡처에도 bonus가 확장되나, salt 비밀성이 보안 요구가 아니고 Keychain은 자체 트레이드오프가 있어 필수 아님 — 채택 불요.)
- **근거**: `lib/core/vault/sidecar_store.dart:32-59; lib/core/database/tables/vault_configs.dart:7-15`  · 위협모델 TM3-diskimage

