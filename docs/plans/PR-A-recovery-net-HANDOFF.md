# PR-A(복구망) 인계 — 다음 세션 START HERE

> 2026-07-12 세션 종료 시점. 브랜치 `feat/pr-a-recovery-net`.
> 이 문서는 포인터다. 상세는 아래 3개 진실원천을 읽어라.

## 진실원천 (읽는 순서)
1. **설계문서(정본)**: `~/.gstack/projects/GangWooLee-key_box/igangu-main-design-20260712-131424.md`
   — 문제정의 → 접근 → 구현 태스크 T0~T11 → eng-review 리포트 → CSO 잔여위협. 전부 여기.
2. **gstack 체크포인트**: `~/.gstack/projects/GangWooLee-key_box/checkpoints/20260712-181419-pr-a-recovery-net-t1b-next.md`
   (또는 `/context-restore`).
3. **프로젝트 메모리**: `MEMORY.md`의 cipher/flutter-test 교훈.

## 지금 상태
- `feat/pr-a-recovery-net`에 커밋 2개: `7efe580`(T3 lock MEK zeroization), `36b40ad`(T1-a 무결성 검사).
- **flutter test 260/260 green, dart analyze 0.**
- 미커밋 WIP ~131파일(`.claude/` 프레임워크 마이그레이션 등) — 별도 정리 필요, 새 작업과 얽지 말 것.

## 다음 시작점 = T1-b (export/import 왕복)
`lib/core/backup/vault_backup_service.dart` 확장. superpowers TDD(RED→GREEN):
- 버전드 자기설명 아카이브(헤더: format version·KDF params·salt·wrapped MEK + 레코드).
- import가 복호화 평문 동등 볼트 재구성(IV 랜덤 → ciphertext 동일 불가, 평문 동등으로 검증).
- 기존 `verifyIntegrity(records, mek)` 재사용. export→wipe→import 왕복 CI 테스트.
- **순수 로직이라 flutter test 가능** (cipher integration_test 불필요).

이후: T2(부팅 반전+salt 사이드카) → PR-B(암호화 flip, cipher 게이트는 integration_test로).

## 절대 잊지 말 것 (확정 결정)
- cipher = **sqlcipher_flutter_libs 유지**(sqlite3mc는 Riverpod 2→3 강제로 번복).
- cipher 검증은 **integration_test로만**(flutter test는 Apple sqlite로 공허 통과).
- PR 컷 = **복구망 먼저 → 암호화**.
- 커밋: Claude-Session URL 생성 불가 → **트레일러 없는 순수 톤 커밋**. 스테이징은 의도 파일만
  (`git add -A` 금지, WIP 131파일 제외).
