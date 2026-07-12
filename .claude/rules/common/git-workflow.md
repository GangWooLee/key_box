---
description: "Git 워크플로우 표준. 커밋 메시지 형식, PR 절차, 브랜치 전략."
globs: "*"
---

# Git 워크플로우

**커밋·푸시는 사용자가 명시 지시할 때만 수행한다** (정본: CLAUDE.md "작업 수행 원칙 > git 규율").

## 커밋 메시지 형식

Conventional Commits를 따릅니다:

```
<type>: <description>
```

### 타입
- `feat` — 새 기능
- `fix` — 버그 수정
- `refactor` — 리팩토링 (기능 변경 없음)
- `docs` — 문서 수정
- `test` — 테스트 추가/수정
- `chore` — 빌드, 설정 등 기타
- `perf` — 성능 개선
- `ci` — CI/CD 설정

### 예시
```
feat: 사용자 프로필 이미지 업로드 기능 추가
fix: 로그인 시 세션 만료 처리 오류 수정
refactor: OrderService 결제 로직 분리
```

## PR 절차

1. **전체 커밋 히스토리 확인** — 최신 커밋만이 아닌 전체 변경 내역 검토
   ```bash
   git diff main...HEAD
   ```

2. **PR 작성 시 포함 항목**:
   - 변경 요약 (1-3개 불릿 포인트)
   - 테스트 계획 (체크리스트)

3. **새 브랜치 푸시 시** `-u` 플래그 사용:
   ```bash
   git push -u origin feature/my-feature
   ```

## 기능 개발 순서

1. **계획 수립** — `/autoplan` (gstack)
2. **TDD 구현** — superpowers `test-driven-development`
3. **코드 리뷰** — `/review` (gstack)
4. **검증** — DoD: `dart analyze` 0건 + `flutter test` 전건 green + (UI·네이티브·라우팅 변경 시) `flutter build macos --debug`
5. **PR/배포** — `/ship` (gstack, 사용자 지시 시)

## Git Worktrees (병렬 개발)

독립 기능을 동시에 개발할 때 브랜치 전환 대신 worktree 사용:

```bash
git worktree add ../key_box-feature-x feature/feature-x  # 생성
git worktree list                                          # 목록
git worktree remove ../key_box-feature-x                   # 정리
```

**사용 시점**:
- Agent Teams에서 teammate별 독립 작업 공간 필요 시
- 긴급 버그 수정 중 기존 기능 브랜치 보존 시
- 두 기능의 통합 테스트를 별도 실행해야 할 때

**네이밍**: `key_box-<feature>` 형식, 프로젝트 루트 상위에 생성.
