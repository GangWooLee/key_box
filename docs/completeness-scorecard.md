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

## Tier 2 (미착수 — 다음 세션)
- **Phase 4 레포 정리(#3)**: stale 브랜치 12+(Rails dependabot 등)·`claude/musing-snyder-9206b6`+워크트리 삭제(삭제 전 병합/고유커밋 확인)·docs/ 지층 재편(`_archive` 분리, 이 3개 분석 문서 정식화)·main 통합 전략(69커밋). 원격삭제·main 통합은 사용자 지시.
- **Phase 5 설계 문서(#4)**: docs/ARCHITECTURE·SECURITY·PRD·CONTRACTS + 용어집. 비-AI톤. SECURITY는 [security-threat-model.md](security-threat-model.md), 아키텍처는 이 스코어카드가 입력.

## B-장부 (A-필수 아님, 차기)
- 코드: `secrets_providers:262` 폴더링크 트랜잭션 밖(orphan)·미테스트 356/140·죽은코드 watchRecent(39)·sheet_modal 계층(386)·folder_dialogs 죽은캐시(194)
- 보안(방어심층/B): 포커스상실·화면잠금 auto-lock(네이티브)·lock/종료 시 클립보드 소거·마이그레이션 평문잔여·화면캡처. gap-accepted: ad-hoc→Developer ID 공증(B2)·T11 복구코드·회전 Tier2 원자성.
