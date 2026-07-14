# PLAN — 백업 / 복원 복구망 UI (feat/pr-a-recovery-net)

> 상태: 설계 확정, Phase 1 착수. 정본 스펙 = `docs/design/DESIGN.md` §restore-from-backup·§settings·§vault-error.

## 문제 정의

이 브랜치(pr-a-recovery-net = 복구망)의 백엔드는 완성됐다 — `VaultBackupService`가
`exportArchive`(salt·wrappedMek·records·mek → 검증된 아카이브 문자열),
`importArchive`(아카이브·비번·destinationMek → 재암호화 레코드), `verifyIntegrity`를
제공하고 integration_test cipher 게이트로 실동작 검증됨. **그러나 이를 트리거할 UI가
전무하다.** 사용자는 백업을 만들 수도, 복원할 수도 없다 — 시크릿 매니저에서 데이터
손실 방어선이 코드로만 존재하고 손에 닿지 않는 상태. DESIGN.md는 이를 "out-trust
유일 복구 경로"로 부른다.

부수 효과: 보안 상태 가시화 3/3(마지막 백업 시각)이 백업 UI 부재로 blocked. 키 회전
(changePassword, B5)도 UI가 없어 사용자가 비번을 바꿀 수 없다.

## 설계 원칙

- **네이티브 경계 격리**: 파일 선택/저장(NSOpenPanel/NSSavePanel)은 flutter test로
  검증 불가(cipher-integration-test 교훈과 동종 — 네이티브는 실앱에서만). 따라서 파일
  read/write를 **주입 가능한 함수 경계**로 분리한다. 순수 오케스트레이션(아카이브 조립·
  파싱·재암호화·DB 삽입)은 flutter test로, 파일 픽업 자체는 얇은 어댑터(integration_test
  또는 수동 QA).
- **파일 선택 의존성**: 진짜 복구(디스크 고장)를 위해 백업은 기계 밖으로 옮길 수 있어야
  한다 → 사용자 선택 위치 필요 → `file_selector`(Flutter 팀 유지, file_picker보다 경량).
  macOS 엔타이틀먼트에 `com.apple.security.files.user-selected.read-write` 추가.
- **복원 = 새 볼트 생성 + import + 열기**: importArchive가 레코드를 destinationMek로
  재암호화하므로, 복원은 (1) 입력 비번으로 새 볼트 생성(fresh salt/mek/wrappedMek)
  (2) importArchive(archive, 입력비번, newMek)로 아카이브 언랩+재암호화 (3) 레코드 삽입
  (4) 열기. 입력 비번이 아카이브 언랩 + 새 볼트 비번 양쪽 역할.
- **실패 구분**: DESIGN.md 요구 — 손상(무결성 실패) vs 오답(언랩 실패)을 클레이 톤으로
  구분 표시. importArchive는 둘 다 null 반환 → 구분하려면 얇은 결과 타입(예: sealed
  RestoreResult { corrupt | wrongPassword | success }) 필요. 언랩 성공했으나 레코드
  무결성 실패 = 손상 / 언랩 자체 실패 = 오답.

## Phase 1 — 복구 오케스트레이션 + 마지막 백업 시각 (순수/테스터블, 이번 착수)

**목표**: 파일 픽업·화면 없이, export/restore의 순수 로직을 TDD로 확정. 왕복 라운드트립
(export → restore → 모든 시크릿 보존) 테스트가 크라운 주얼 — 복구망이 실제로 작동함을
증명.

- `VaultRecoveryService`(또는 auth/secrets 도메인 확장):
  - `buildArchive({vaultId, mek})` → String? : vaultConfig(salt·wrappedMek) + 전체 시크릿
    → VaultBackupRecord 리스트 → exportArchive. 파일 저장은 분리(호출자가 주입 fn).
  - `restoreInto({archive, password})` → RestoreResult : 새 볼트 생성 + importArchive +
    레코드 삽입 + 상태 전이. 파일 읽기는 분리.
- ~~`lastBackupAtProvider`~~ → **Phase 3로 이관**(2026-07-14): 마지막 백업 시각 store는
  실제 export 트리거(Phase 3)가 유일 setter, 디테일 패널(Phase 4)이 유일 reader —
  소비자 없는 Phase 1 코드는 미니멀리즘 사다리 위반(①필요한가). export 배선과 함께 신설.
- **테스트**(in-memory DB + 실 crypto — cipher 무관 순수 부분): export→restore 왕복 보존,
  손상 아카이브 거부, 오답 거부, recordCount 불일치 거부, 빈 볼트 export, 마지막 백업
  시각 기록/복원.

## Phase 2 — restore-from-backup 화면 (Slab 3-step) + 파일 선택 + 진입점

DESIGN.md §restore: Slab 유지, 3스텝 — ①`.kbx` 파일 선택 ②마스터 비번 ③무결성 검사
(conic ring, verifyIntegrity 결과) → 성공=벤치 진입 스윕 / 실패=클레이 사유(손상·오답
구분). vault-error 화면 "복원" 링크에서 진입 + routing(RouteNames.restore 신설).
file_selector 의존성 + 엔타이틀먼트. golden(3스텝 각). 위젯 테스트(파일 읽기 주입 mock).

## Phase 3 — settings 화면 (Bench/Terminal)

DESIGN.md §settings: 3-Column, 좌측 섹션 목록 + 우측 폼. 항목: 자동잠금 시간·테마
(라이트/다크/시스템 — themeModeProvider 기존)·reveal 기본값·**비번 변경(→키 회전
changePassword 기존, UI 부재!)**·export/백업 트리거. RoutePaths.settings 배선(현재 미배선).
export 성공 → 마지막 백업 시각 갱신 → Phase 4 신호 활성.

## Phase 4 — 보안 상태 가시화 2/3·3/3

- 3/3 마지막 백업 시각: 디테일 패널 하단(클립보드 카운트다운 옆) mono muted
  `backed up 2h ago` / `never backed up`. lastBackupAtProvider watch.
- 2/3 자동잠금 잔여: AutoLockService에 lockDeadline 노출 + 활동 리셋 지터 처리(coarse
  틱). `auto-lock ~Nm`.

## 검증 게이트 (전 Phase 공통)

`dart analyze` 0 · `flutter test --exclude-tags golden` 전건 · 골든 비전 검수 ·
`flutter build macos --debug` · 파일/cipher 네이티브 경계는 integration_test 또는 수동 QA로
별도 확인(flutter test는 cipher 무시 — 교훈). 화면 단위 순수 톤 커밋.

## 리스크 장부

- **cipher 네이티브 테스트 공백**: 복원의 keyed DB open·실제 삽입은 flutter test에서
  cipher를 안 탐 → 왕복 보존은 순수 crypto 레벨로 증명하고, 실 DB 왕복은 integration_test.
- **엔타이틀먼트 변경**: 보안 민감 — user-selected.read-write만 추가(최소 권한), 네트워크
  등 확대 금지.
- **복원 중 자동잠금/기존 볼트**: 복원은 새 볼트로 진입하므로 기존 볼트 파일 처리 정책
  (덮어쓰기 vs 별도)은 Phase 2에서 확정.
