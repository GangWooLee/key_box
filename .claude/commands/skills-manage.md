# /skills-manage — 외부 스킬 관리 도구

Find Skills CLI (`npx skills`)를 사용하여 커뮤니티 스킬을 검색·설치·업데이트합니다.

## 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `npx skills find [query]` | 커뮤니티 스킬 검색 (인터랙티브) |
| `npx skills add <source>` | GitHub 레포에서 스킬 설치 |
| `npx skills list` | 설치된 스킬 목록 (프로젝트 + 글로벌) |
| `npx skills check` | 업데이트 가능한 스킬 확인 |
| `npx skills update` | 모든 외부 스킬 업데이트 |

## 설치 규칙

1. **프로젝트 스코프 기본** — `.claude/skills/`에 설치하여 팀원 공유
2. **`.skill-lock` 커밋 필수** — 스킬 버전 동기화를 위해 git에 포함
3. **이름 충돌 확인** — 설치 전 `npx skills list`로 기존 커스텀 스킬과 이름 겹침 확인
4. **커스텀 스킬 우선** — 동일 기능이면 프로젝트 맞춤 커스텀 스킬 사용

## 사용 시나리오

### 새 스킬 검색 및 설치
```bash
npx skills find "docker"     # Docker 관련 스킬 검색
npx skills add user/repo     # GitHub 레포에서 설치
```

### 설치된 스킬 관리
```bash
npx skills list              # 전체 목록
npx skills check             # 업데이트 확인
npx skills update            # 일괄 업데이트
```

## 주의사항

- 외부 스킬은 `.claude/skills/` 내부에 설치되지만 커스텀 스킬(`SKILL.md`)과 구분됨
- `node_modules/` 캐시 디렉토리는 `.gitignore`에 이미 포함 — 추가 설정 불필요
- 설치 후 Claude Code 재시작 없이 즉시 사용 가능
