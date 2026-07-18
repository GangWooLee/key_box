# key_box 완성도 스코어카드

> 측정일: 2026-07-16 · 브랜치: `feat/pr-a-recovery-net` (HEAD `f425aa1`) · 워킹트리 clean
> 원칙: 증거 없는 ✓ 금지. 모든 ✓는 이 날짜에 새로 실행한 명령의 출력 또는 file:line 근거를 가진다.

## 기준선 정의

- **기준선 A — 저자 개인 dogfood**: 저자가 자기 시크릿을 실제로 넣고 매일 쓸 수 있는 상태.
  at-rest 암호화 실증 · 부팅 매트릭스 안전 · 회전/백업/복구 왕복 · 릴리스 실행 가능 · 실사용 블로커 없음.
- **기준선 B — 배포**: 남에게 설치를 권할 수 있는 상태.
  A + 복구코드 · Developer ID 서명+공증 · 회전 원자성 · 광범위 위협모델 통과 · 설계 문서.

---

## 기준선 A 판정

| # | 항목 | 판정 | 증거 |
|---|---|---|---|
| A1 | 정적 분석 0건 | ✅ | `dart analyze` → "No issues found!" (2026-07-16 실행) |
| A2 | 단위/위젯 테스트 전건 green | ✅ | `flutter test` → **482건 All tests passed!**, exit 0 (2026-07-16 실행) |
| A3 | at-rest 암호화 (keyed open + 하드핀) | ✅ | `PRAGMA key` [database.dart:110](../lib/core/database/database.dart) + `cipherHardPinPragmas()` :111 · HKDF 도메인분리 [key_hierarchy_service.dart](../lib/core/encryption/key_hierarchy_service.dart) · AAD 롤백 방어 database.dart:64 · 실동작은 A8 integration 게이트 |
| A4 | 부팅 매트릭스 안전 (12셀) | ✅ | [auth_boot_matrix_test.dart](../test/features/auth/auth_boot_matrix_test.dart) — FirstRun/Locked/VaultError(sidecarMissing·vaultFileMissing·sidecarCorrupted·configMissing)/heal idempotent/reset, A2에 포함되어 green |
| A5 | 키 회전 + 회전 전 자동백업(Tier1) | ✅ | `3ebe1dc` + `FilePreRotationBackupStore` 프로덕션 배선 [auth_notifier.dart:106](../lib/features/auth/domain/auth_notifier.dart) · 실앱 왕복은 A8 |
| A6 | 백업/복구 왕복 | ✅ | restore 오케스트레이션+화면 (`docs/plans/PLAN_backup_restore_recovery_ui.md` 이행 커밋) · 실앱 왕복은 A8 |
| A7 | 릴리스 실행 크래시 없음 | ✅ | `c200edd` — hardened runtime + `disable-library-validation` ([Release.entitlements](../macos/Runner/Release.entitlements), F2 방어 유지 주석 포함) · 크래시 재현→수정→재실행 확인 완료(2026-07-15) |
| A8 | cipher 실동작 게이트 (integration) | ✅ | `cipher_positive` **3/3** (`read WITH correct key ok=true`) · `key_rotation_e2e` **2/2** · `restore_from_backup_e2e` **2/2** — 실 SQLCipher 왕복 green (2026-07-16 실행). flutter test는 cipher를 안 탐(Apple libsqlite3가 PRAGMA key 무시)이라 이 게이트가 유일한 암호화 실증 |
| A9 | macOS 디버그 빌드 성공 | ✅ | `flutter build macos --debug` → "Built build/macos/Build/Products/Debug/KeyBox.app", exit 0 (2026-07-16 실행) |
| A10 | dogfood 실사용 블로커 4종 수정 | ✅* | #2 폴더연결·카운트 `2317cd7` · #4 pre-fill `1f62f8a` · #1 토글아이콘 `c1dfb2a` · #3 간격 `1d54ff4` — 각각 테스트/골든 고정. **\*정직 각주(2026-07-17)**: #2는 소스에서 수정됐으나 dogfood 바이너리가 스테일이었음(실행 중 Release.app 빌드=Jul 14 23:48 < 수정 커밋=Jul 15 17:44) → 사용자가 실앱에서 버그 재보고. "소스 수정 ≠ 바이너리 재빌드" 갭 — Phase A에서 재빌드 규율(`scripts/dogfood.sh`)·실seam 회귀 테스트·비전 실증으로 봉합 |
| A11 | CI green (마이그레이션 후 첫) | ✅ | 푸시(`1d54ff4..f425aa1`) → GHA run 29480896148 **conclusion=success** (headSha f425aa1, 2026-07-16). **Flutter 전환 이후 첫 초록** — 그간 허위였던 "GHA 이중 안전망"이 이제 실재 |

**A 판정: 도달 확정 (A1–A11 전건 ✅, 증거 첨부).** 기준선 A(저자 개인 dogfood)는 코드/빌드/테스트/CI 관점에서 완전히 닫혔다.

---

## 기준선 B 격차 장부

| # | 격차 | 1줄 명세 | 근거 |
|---|---|---|---|
| B1 | T11 복구코드 | 비번 분실 시 최후 복구 수단 없음 — `lib/` 전체에 recovery code 구현 부재 | grep 0건 (2026-07-16) |
| B2 | Developer ID 서명 + 공증 | 현재 ad-hoc 서명 — `Signature=adhoc`, `TeamIdentifier=not set`. ad-hoc은 `get-task-allow` 자동 부여로 F2(디버거 MEK 추출) 방어가 릴리스에서만 완성 | `codesign -dv` (2026-07-16) |
| B3 | 회전 Tier2 원자성 | rewrap 커밋↔rekey 사이 크래시 창이 Tier1(사전백업)으로 완화됐을 뿐 원자적이지 않음 | 회전 프로토콜 설계 (auth_notifier changePassword ③-⑥) |
| B4 | 광범위 위협모델 통과 | CSO T1–T11 중 T11 미완 + 카테고리 전수(메모리·exfil·code integrity 등) 미열거 | 본 전략 Phase 2에서 수행 |
| B5 | 설계 문서 | ARCHITECTURE/SECURITY/PRD/CONTRACTS 정본 부재 — docs/는 과정 산출물 지층 상태 | 본 전략 Phase 5에서 수행 |
| B6 | 레포 가독성 | stale 브랜치 12+·docs 지층·main 69커밋 미통합 | 본 전략 Phase 4에서 수행 |

---

## 판정 요약

- **A: 도달 확정.** A1–A11 전건 ✅(2026-07-16 실측: analyze 0 · unit 495 green · macOS 빌드 · integration cipher/rotation/restore green · CI green).
- **B: 6개 격차 명세 완료.** B1(복구코드)·B2(공증)·B3(회전 원자성)은 차기 사이클 이월.

---

## ▲ Tier 1 완료 (2026-07-16) — GATE 통과

**Phase 0~3 완료. A-필수 8건 전부 수정·커밋·푸시·CI-green.**

| Phase | 결과 | 커밋 |
|---|---|---|
| 0 완성도 판정 | 기준선 A 도달 확정 | (본 스코어카드) |
| 1 코드리뷰(멀티에이전트, 12 confirmed) | 회전 race + provider 스테일 클래스 5건 | `878d15e`·`fed5da6`·`f40a882`·`bbaae6d`·`e237571` |
| 2 보안 위협모델(33경로) | A-필수=백업 메타 v3 봉투암호화 | `d9e5f1b` (+ [security-threat-model.md](security-threat-model.md)) |
| 3 테스트/CI | CI에 integration cipher 게이트 상주(GHA green 실증) + 공허테스트 교체 | `c8b72f1` |

**GATE 판정**: (1) 기준선 A 닫힘 확정 (2) 코드 안정(남은 발견 전부 B-장부) → **통과. Tier 2 진입 가능.**

## ▲ Phase A — 스테일 빌드 사건 봉합 (2026-07-17)

**계기**: 사용자가 #2(폴더 배치·집계)를 실앱에서 재보고 → 조사 결과 소스는 올바르고(HEAD에 `2317cd7` 포함), **실행 중이던 Release.app이 수정 이전 빌드**(Jul 14 23:48 < Jul 15 17:44)였음. "소스 수정 ≠ 바이너리 재빌드" 갭.

| 항목 | 결과 | 증거 |
|---|---|---|
| A1 재빌드+비전 실증 | ✅ | `dogfood.sh release`로 c8b72f1 빌드·재기동 → computer-use로 실측: toss 선택→키 추가→**toss에 배치**(0→1), General 3 불변, detail 폴더 칩=toss, 삭제 시 1→0 즉각 (2026-07-17 스크린샷) |
| A2 실seam 회귀 가드 | ✅ | [dashboard_secret_flow_test.dart](../test/features/secrets/presentation/screens/dashboard_secret_flow_test.dart) — 실 DashboardScreen+실 DB에서 실제 폴더 행 탭→추가→배치·카운트 단언. GREEN + **뮤테이션 RED 실증**(create 분기 선택 무시 주입 시 실패). 기존 `sheet_modal_test:203`은 provider 하드코딩이라 이 seam을 원리적으로 못 봄 |
| A3 dogfood 규율 | ✅ | [scripts/dogfood.sh](../scripts/dogfood.sh)(빌드→kill→재기동, HEAD sha 출력) + CLAUDE.md Gotchas 명문화 |
| A4 비전 QA 계층 | ✅ | [docs/qa-vision-e2e.md](qa-vision-e2e.md) — 루프·체크리스트 6항(실측 통과)·미커버 목록 |
| DoD | ✅ | `dart analyze` 0 · `flutter test` **496 all green** (2026-07-17 실행) |

**판정**: #2는 소스·바이너리·눈 3계층 모두에서 닫힘. A10 각주의 갭은 규율(A3)로 재발 방지. 잔여: 사용자 볼트의 기존 3키가 General에 있음(스테일 빌드 시절 산물) — 원하면 detail 패널 "Add to folder"로 toss에 재배치 가능(데이터 손실 아님, 사용자 선택).

## ▲ Tier 2 완료 — 레포 총정리 + 설계 문서 (2026-07-17)

**Phase 4 레포 총정리**:
- 브랜치: 로컬 `main`·`spike/sqlite3-multiple-ciphers`·`claude/musing-snyder-9206b6`(+워크트리) 삭제(전부 HEAD 조상·고유커밋 0 실측 후). 원격 dependabot 12종 삭제(Rails 시대 무의미). 결과 = **feat + main 둘뿐**.
- main 통합: `895e7a6`(Rails, 3/1) → `72e4d59` **fast-forward** — main이 4개월 만에 현재를 가리킴. 로컬·원격 CI 둘 다 green(72e4d59, run 29564121828·29564019408).
- docs/ 지층 재편: 과정 산출물 ~30파일 → `docs/_archive/`(사유 README). 최상위 = 정본만. 분석 문서 3종 최초 커밋. `.pdca-snapshots`→gitignore, 빈 디렉토리 정리.
- README: Rails 템플릿 → KeyBox 정본(문제부터, entitlements 실측).

**Phase 5 설계 문서(비-AI톤, docs/ 정본 5종)**:
- [ARCHITECTURE.md](ARCHITECTURE.md)·[SECURITY.md](SECURITY.md)·[PRD.md](PRD.md)·[CONTRACTS.md](CONTRACTS.md)·[GLOSSARY.md](GLOSSARY.md). 사실 수집=opus 에이전트 2기 병렬, 문서화=메인 직접. 게이트: 마크다운 링크·상대경로 전수 실재 + 인용 코드 주장(계층위반 줄번호·빈 디렉토리·schemaVersion·redirect 매핑) 실코드 대조.
- '정직한 흠' 절로 계층위반 3곳·빈 스캐폴딩·레거시 표면·감사 페이지네이션을 문서에 명시(축소 없음).

**전체 마무리 판정**: 5대 작업(리뷰·보안·정리·문서·완성도) + Phase A(스테일 빌드 봉합) 완료. 처음 읽는 사람이 README→설계 정본으로 자립 이해 가능. 커밋 전부 CI-green·푸시.

---

## ▲ 외부자 시선 3단계 평가 (2026-07-18) — 실측

> "지금까지 판정은 만든 사람 시선"이라는 한계를 깨는 후속 평가. 1·2 실측이 3의 입력.

### 1단계 — 유지보수성 실측 (`flutter test --coverage`, 2026-07-18)

**커버리지 vs CLAUDE.md 타깃** (lcov 파싱, `*.g.dart` 제외):

| 영역 | 타깃 | 실측 | 판정 |
|---|---|---|---|
| core/encryption | 100% | **100.0%** (117/117) | ✅ 충족 |
| auth/domain | 100% | 94.7% (321/339) | ⚠️ 격차 5.3%p — backup_file_picker 20%(네이티브 패널)·auth_notifier 미커버 14줄은 전부 에러상태 전이(configMissing/mekUnwrapFailed)+debugPrint |
| core/database | 80% | DAO만 88.6% / tables 포함 74.1% | ✅ DAO 충족(테이블 정의는 실행라인 0=구조상 정상) |
| features/*/domain | 80% | **88.2%** (194/220) | ✅ 충족 |
| features/*/presentation | 60% | 68.4% (1842/2694) | ✅ 충족(단 folder_dialogs 0%·audit_log 1%·onboarding 1.5%=미테스트 화면) |
| services | 70% | **85.7%** (54/63) | ✅ 충족 |
| **lib 전체** | — | **73.8%** (3301/4473) | — |

- **정직 각주**: cipher 의존 라인의 "커버"는 라인 실행일 뿐 암호화 실증이 아님(macOS flutter test는 PRAGMA key 무시 — integration_test가 실증 계층). encryption 100%는 순수 로직(HKDF·wrap·AAD) 커버지 SQLCipher 왕복 아님.
- **판정**: 6개 영역 중 encryption·domain·database(DAO)·presentation·services 충족, auth/domain만 5.3%p 미달(미커버=에러전이+네이티브패널, 실사용 경로는 커버). 타깃 대비 양호하나 100% 두 영역 중 auth는 미달로 명기.

**구조 부채 (정량)**:
- 200줄 초과 파일 20개 / 73개(27%). 최대 auth_notifier 989·secret_detail 843·sheet_modal 756. CLAUDE.md 클래스 200줄 기준 초과 다수 — 단 대부분 위젯 build 트리(분해 가능하나 결함 아님).
- **confirmed 죽은 심볼 7건**(적대검증 후, 직접 재확인): `watchRecent`·`SecretDao.watchByFolderId`·`FolderDao.decrementSecretsCount`·`VaultDao.getAll`·`DateFormatters.timeOnly`·**enum 통파일 `SecretType`·`Environment`**(어디서도 import 안 됨 — grep 0). 프로덕션-죽음/테스트-생존 9건 별도(unlinkFromFolder는 removeFromFolder로 대체돼 테스트만 참조).
- **의존성 노후**(`pub outdated`): 직접 12개 중 다수 메이저 뒤처짐 — drift 2.28→2.34, riverpod 2.6→3.3, go_router 14→17, pointycastle 3.9→4.0. **단 drift/riverpod은 riverpod_generator 3.0 충돌로 의도적 핀**(memory 기록) — "노후"가 아니라 "잠금". sqlcipher_flutter_libs 0.6→0.7+eol(EOL 표시 주의).

### 2단계 — UX 실측 (실앱 비전, 볼트 대피 후, 2026-07-18)

> 볼트 원본 shasum 대조 일치로 무손상 원복 확인(대피→테스트→복원). 판정 기준: 태스크가 끝나는가.

| 태스크 | 완주 | 발견(심각도) |
|---|---|---|
| 1. 첫 5분(셋업→첫 키) | ✅ | 12자 검증 즉시 표시(좋음)·온보딩 3화면이 ⌘K/⌘N/⌘C를 가르침(좋음). **[사소] "forgotten passwords cannot be recovered"만 있고 복구코드 부재 재확인** |
| 2. 핵심 루프(찾기→reveal→copy→붙여넣기) | ✅ | reveal/copy 작동, 클립보드 실측 일치(`dummy-value-for-ux-eval`). **[짜증] 커맨드 팔레트 입력에 자동 포커스 안 됨 — 한 번 더 클릭해야 타이핑(자동화 영향 가능성 보수적 감안)**. **[관찰] ⌘K 단축키가 팔레트를 안 열었음(자동 synthetic modifier 한계 의심 — 수동 확인 권장)** |
| 3. 백업 유도 실효성 | ⚠️ | Export는 Settings>Backup에 명확. **[짜증] "never backed up" 배너가 클릭 불가 수동 라벨 — 백업 행동으로 유도 안 함**. 배너→export 연결 부재 |
| 4. 저빈도 발견성 | ⚠️ | 비번변경(Settings>Security, 명료)·백업(Settings>Backup) 발견 가능. **[사용포기급 후보] 복원(Restore)이 Settings에 없음 — vault-error/unlock 경로에서만 도달. 정상 세션에서 "다른 기기 백업 복원"을 찾을 수 없음** |
| 부수 | — | **[관찰] 온보딩 Continue 시점 macOS "메모리 부족" 강제종료 다이얼로그 발생** — 단 KeyBox 자체는 87MB(결백), 머신 전역 압박(ChatGPT 12GB 등). KeyBox 누수 아님. **감사 로그 정확**(reveal/create/setup 기록 확인) |

> **2단계 자기 정정(정직)**: 위 (a)팔레트 자동포커스·(b)⌘K 미개방은 3단계 적대검증에서 **코드 반증됨** — `command_palette.dart:84`에 `autofocus: true`, `dashboard_screen.dart:210-214`에 ⌘K 바인딩 실재. 실앱 관찰은 **자동화 synthetic-modifier 한계/스테일 의심 아티팩트**로 판단, **실결함 아님**으로 격하한다("증거 없는 결함 주장 금지"의 대칭 적용). 재빌드 후 수동 재확인이 최종 확답이나, 소스 근거상 정상.

### 3단계 — 컨셉 적합성 + 종합 (멀티에이전트 12에이전트, 적대검증, 2026-07-18)

**방법**: 경쟁 4(1P·Bitwarden·Keychain·pass, 웹 리서치) + PRD갭 1 + 악마의변호인 3 → 각 논거 3렌즈 적대검증(사실성·유스케이스 적합·수용 트레이드오프 위장). 애매하면 refuted. 최종 등급은 메인(Advisor) 직접 산정.

**악마의 변호인 판정 결과**: 3개 보고의 **논거 전부(6+6+6) 검증에서, confirmed로 살아남은 하드 결함은 단 1건** — 나머지는 배포(기준선 B)·수용 트레이드오프·유스케이스 부정합을 결함으로 포장한 것으로 코드/문서로 반증.

- **[CONFIRMED · 사용포기급] 복원(Restore) 발견성** — restore 진입점이 **오직 `vault_error_screen.dart:62` 한 곳**(grep 실측, 여러 검증자 독립 확인). Settings·unlock·first-run 어디에도 없음 → **신규 Mac은 볼트 부재로 first-run(setup) 진입 → 백업 복원 경로 자체가 없음**. "타기기 백업 복원"이 정상 온보딩에서 불가능. PRD 요구 #5(백업/복구 왕복)의 경험상 미완 — 배치/라우팅 한 곳(Settings에 Restore 추가)으로 닫히는 유계 갭이나 실측 유효.
- **[CONFIRMED · 사소] "never backed up" 배너 비인터랙티브**(`vault_status_strip.dart:33` Text) — 백업 자체는 Settings>Backup에서 발견 가능하므로 경미. 악마가 그린 "완화책 붕괴"는 과장.
- **[CONFIRMED · 사소] SecretType·Environment 죽은 enum + taxonomy 이원화** — 기능 동작, 드리프트 리스크.
- **[REFUTED] 복구코드 부재**(무백도어 ZK 설계의 수용된 대가, API키 재발급 가능, `pass`도 동일) · **ad-hoc 서명**(배포=B 관심사) · **회전 비원자성**("벽돌화" 거짓 — 저널+사전백업+case A/B/C 재개, 실패 시 vault-error=복원 진입점) · **자작 크립토**(pointycastle+SQLCipher 조합, 프리미티브 자작 아님) · **핀=패치 봉쇄**(핀은 코드젠 dev-dep에만; sqlcipher/pointycastle 런타임은 독립 bump 가능) · **Keychain으로 충분**(분리 마스터비번+auto-lock+무네트워크 entitlement = 측정 가능 confidentiality 이득, 폴더·검색·감사·이식형 백업 = Keychain 미제공 UX).

**경쟁 벤치마크 결론** (유스케이스 한정 "개발자 개인 로컬 온리 API키 관리"):

| 대안 | 로컬온리 순수성 | 이 유스케이스 결론 |
|---|---|---|
| **1Password** | ✗ v8이 계정+클라우드 동기화 강제(standalone 폐지) | 로컬온리 하드요건이면 후보 자체 아님. 단 "로컬온리=수단"이면 `op run`·`op://`·SSH agent 개발툴링이 KeyBox 수동 복사 루프를 압도 |
| **Bitwarden** | △ 오프라인=읽기전용 캐시, 진짜 로컬온리는 셀프호스트(Docker) | 무료·오픈소스지만 로컬온리엔 서버 구축 필요 |
| **Keychain/Passwords.app** | ✓ 로컬 | 로그인 시 자동해제(분리 비번 없음)·임의 개발시크릿 정리/검색/백업 UX 빈약 |
| **pass/gopass** | ✓ 로컬·파일 | GPG CLI, GUI 없음·비개발자 마찰 |

**→ KeyBox의 진짜 해자**: "완전 로컬온리 + 제로 네트워크(entitlement) + 제로 계정 + GUI + 폴더/검색/감사/이식형 암호화 백업"을 **동시에** 주는 대안이 없다. 단 해자의 폭은 좁다 — "로컬온리가 협상 불가 하드요건"일 때만 결정적이고, 취향 수준이면 1Password의 개발 워크플로 주입이 우세.

---

## ◆ 종합 스코어카드 — 5차원 등급 (Advisor 직접 판정, 2026-07-18)

> 등급은 "잘 만들었다"의 보상이 아니라 실측의 요약. 나쁜 수치는 나쁜 등급으로.

| 차원 | 등급 | 근거 (1차 증거) |
|---|---|---|
| **설계** | **A−** | 키 계층(PBKDF2 600k→HKDF 도메인분리→MEK wrap)·AAD 치환/롤백 방어·cipher 하드핀·크래시 안전 회전 프로토콜(case A/B/C)·entitlement 무네트워크. 위협모델 33경로. 감점: 복구코드·회전 원자성이 설계급 수용 갭(B 이월). [SECURITY.md·ARCHITECTURE.md] |
| **구현** | **B+** | test 499 green + cipher integration_test 실증 + CI green. 실앱 버그 4종 수정·removeFromFolder 추가. 감점: 죽은 심볼 7(enum 2 통파일 포함)·200줄 초과 20/73·계층위반 3곳. [1단계 실측] |
| **유지보수** | **B** | 문서 정본 5종+위협모델+스코어카드(탁월). 커버리지 영역 타깃 대부분 충족. 감점: auth/domain 94.7%<100%·의존성 메이저 핀(riverpod_generator 3.0 충돌 = 실 업그레이드 블로커)·구조 부채. [1단계 실측] |
| **UX** | **B−** | 첫 5분·핵심 루프(찾기→reveal→copy→붙여넣기, 클립보드 실측 일치) 완주. 감점: **복원 발견성 사용포기급 confirmed**(신규 Mac 이관 차단)·백업 배너 비인터랙티브. 시크릿매니저의 가장 안전임계 플로(백업/복구)에 실 구멍. [2·3단계] |
| **컨셉** | **B** | "완전 로컬온리 개인 API키 관리"에 경쟁 대안이 못 채우는 진짜 니치. 감점: 해자가 "로컬온리=하드요건"에 전적 의존(취향이면 1P 우세)·개발 워크플로 주입(CLI/env) 부재로 폭 좁음. [3단계 벤치마크] |

**Advisor 종합 판정**: KeyBox는 **기준선 A(저자 개인 dogfood)를 실증으로 닫은, 설계가 특히 견고한 1인 제품**이다. 12에이전트 적대검증이 찾아낸 "쓰지 말아야 할 이유"는 **단 하나의 실 결함(복원 발견성)으로 수축**했고 — 나머지는 전부 (a)스스로 선언한 기준선 B 미완이거나 (b)논증을 거쳐 수용한 설계 트레이드오프였다. 가장 시급한 단일 개선은 **Settings에 Restore/Import 진입점 추가**(백업/복구 왕복 약속을 정상 세션에서 성립시킴). 컨셉은 방어 가능하나 해자가 좁아, 배포(B)로 가려면 복구코드·Developer ID 공증이 관문이다.

## B-장부 (A-필수 아님 — 통합·갱신)

- ~~**UX(신규 최우선)**: 복원 진입점을 first-run에 추가~~ → **2026-07-18 닫힘**: setup(AuthFirstRun)에 "Restore from backup" 진입점 + restore 화면 Cancel 탈출로 + 라우터 `authRedirect`가 FirstRun/VaultError에서 /restore 허용(mirror 복제 제거·뮤테이션 RED 실증). 신규-Mac 왕복(setup→restore→cancel) 실앱 비전 확인. 잔여: "never backed up" 배너 onTap→Backup 연결(사소)·AuthLocked(비번분실+백업) 복원은 reset-first 흐름 필요(별도 B).
- **코드 위생**: 죽은 심볼 7 제거(`SecretType`·`Environment` enum 통파일·`watchRecent`·`SecretDao.watchByFolderId`·`FolderDao.decrementSecretsCount`·`VaultDao.getAll`·`DateFormatters.timeOnly`)·taxonomy 이원화(SecretCategory vs 죽은 enum) 정리·200줄 초과 위젯 분해·계층위반 3곳(folder_dialogs·sheet_modal·onboarding→domain)·빈 스캐폴딩 features/folders·search·vault·`secrets_providers` 폴더링크 트랜잭션 밖(orphan 창).
- **보안(방어심층/B)**: 포커스상실·화면잠금 auto-lock(네이티브)·lock/종료 시 클립보드 소거·마이그레이션 평문잔여·화면캡처(sharingType). gap-accepted: ad-hoc→Developer ID+공증(B2)·복구코드(B1)·회전 Tier2 원자성(B3)·Argon2id 이관.
- **의존성**: riverpod 3/drift 2.32+ 승급(riverpod_generator 3 안정판에 묶어서)·sqlcipher_flutter_libs 0.7 EOL 검토.

> **커버리지 수치 정직 각주**: 본 스코어카드 실측(73.8%, `*.g.dart` 제외·영역 매핑)과 3단계 검증자가 본 lcov(54.9% 총, core 37.6%)의 차이는 (a) `*.g.dart`/집계 범위, (b) cipher 의존 코어가 integration_test로만 검증돼 flutter-test lcov에 안 잡히는 분리 아티팩트 때문. 영역별 타깃 대조(encryption 100%·presentation≥60%)는 양쪽 해석에서 유지.
