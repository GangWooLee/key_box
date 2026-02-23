---
description: "작업 체크포인트를 생성, 검증, 조회합니다. 사용법: /checkpoint create <이름>, /checkpoint verify <이름>, /checkpoint list"
---

# 체크포인트 관리

작업 진행 중 안전한 복원 지점을 관리합니다.

## 사용법

`$ARGUMENTS` 파라미터를 파싱하여 아래 동작을 수행합니다:

### `create <이름>`
1. `bin/rails test` 실행하여 현재 상태 검증
2. 변경사항을 git stash 또는 commit으로 저장
3. `.claude/checkpoints.log`에 기록:
   ```
   [타임스탬프] <이름> | SHA: <git-sha> | 테스트: pass/fail
   ```

### `verify <이름>`
1. 지정된 체크포인트와 현재 상태 비교
2. 보고:
   - 변경된 파일 수
   - 테스트 결과 변화
   - 진행 상황 요약

### `list`
모든 체크포인트를 시간순으로 표시:
- 타임스탬프
- Git SHA
- 현재 위치와의 관계

### `clear`
최근 5개를 제외한 체크포인트 정리

## 예시

```bash
# 기능 구현 전 체크포인트
/checkpoint create before-auth

# 구현 후 검증
/checkpoint verify before-auth

# 전체 목록
/checkpoint list
```
