---
name: wrap-up
description: 작업 완료 시 자동 마무리. 교훈 추출 → CLAUDE.md 업데이트 → 인벤토리 동기화 → 자동 커밋. 기능 구현, 리팩토링, 버그 수정 후 사용하세요.
---

# Wrap-Up Skill

작업 완료 후 프로젝트 문서를 자동으로 최신 상태로 유지하고 커밋합니다.

## 실행 조건

다음 상황에서 자동 또는 수동으로 실행:
- 기능 구현 완료 후
- 리팩토링 완료 후
- 버그 수정 완료 후
- 사용자가 "커밋해줘", "마무리", "wrap up" 요청 시

## 워크플로우

```
1. 변경 분석
   └→ git diff --name-only HEAD~1..HEAD (또는 unstaged changes)

2. 교훈 추출 (AI 분석)
   ├→ 새로운 패턴/안티패턴 발견?
   ├→ 버그의 근본 원인?
   ├→ 향후 참고할 설계 결정?
   └→ 테스트에서 배운 점?

3. CLAUDE.md 업데이트
   ├→ Lessons Learned 섹션에 교훈 추가
   ├→ 코드베이스 인벤토리 업데이트 (모델/컨트롤러/테스트 수)
   └→ 신규 설정/서비스 문서화

4. 자동 커밋
   └→ 변경된 코드 + CLAUDE.md 함께 커밋
```

## 교훈 추출 기준

### 추가할 교훈 (CLAUDE.md Lessons Learned)

| 유형 | 예시 | 추가 여부 |
|------|------|----------|
| **패턴** | Rails config로 상수 중앙 관리 | ✅ 추가 |
| **버그 원인** | 테스트에서 상수 참조 시 config 마이그레이션 누락 | ✅ 추가 |
| **설계 결정** | 보안 검증용 상수는 코드에 하드코딩 유지 | ✅ 추가 |
| **단순 변경** | 변수명 변경 | ❌ 불필요 |
| **일반 지식** | Ruby 문법 | ❌ 불필요 |

### 교훈 포맷

```markdown
### [제목] — [핵심 요약]

[상황 설명 1-2문장]

\`\`\`ruby
# 예시 코드 (필요 시)
\`\`\`

**교훈**: [실제 적용할 수 있는 가이드라인]
```

## 인벤토리 업데이트 규칙

다음 항목이 변경되면 CLAUDE.md 인벤토리 섹션 업데이트:

| 변경 | 업데이트 대상 |
|------|-------------|
| `app/models/*.rb` 추가/삭제 | Models 수 |
| `db/migrate/*.rb` 추가 | Migrations 수 |
| `app/controllers/*.rb` 추가/삭제 | Controllers 수 |
| `app/services/**/*.rb` 추가/삭제 | Services 수 |
| `test/**/*_test.rb` 변경 | Tests runs/assertions |
| `app/javascript/controllers/*.js` 추가/삭제 | Stimulus controllers 수 |

## CLAUDE.md 정리 규칙

추가만 하면 비대해져 지시 품질 저하. 5회 wrap-up마다 또는 100줄 초과 시 정리:

| 정리 대상 | 기준 | 조치 |
|----------|------|------|
| 완료된 임시 메모 | 기능 출시 후 불필요 | 삭제 |
| 중복 교훈 | rules/에 이미 공식화됨 | 삭제 (승격 완료) |
| 오래된 설정 메모 | 3개월+ 경과 | 삭제 또는 docs/ 이동 |
| 모순 지시 | 이전 교훈 vs 현재 규칙 | 현재 규칙 우선, 교훈 삭제 |

**승격 경로**: 같은 교훈 3번 반복 → `.claude/rules/`에 정식 규칙 승격 → CLAUDE.md에서 삭제.

## 커밋 메시지 규칙

```
<type>: <설명>

[변경 내용 요약]
- 항목 1
- 항목 2

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Type 선택**:
- `feat`: 새 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `docs`: 문서만 변경 (CLAUDE.md 포함)
- `chore`: 설정, 의존성 등

## 실행 예시

```
User: 이 작업 끝났어. 커밋해줘.

AI:
1. 📊 변경 분석 중...
   - config/initializers/openrouter.rb (확장)
   - app/services/openrouter/client.rb (수정)
   - CLAUDE.md 업데이트 필요

2. 📝 교훈 추출...
   - Rails Config 중앙 관리 패턴 발견
   - 테스트 상수 참조 마이그레이션 주의점

3. 📄 CLAUDE.md 업데이트 중...
   - 외부 서비스 설정 섹션 추가
   - 인벤토리 최신화

4. ✅ 커밋 완료
   "refactor: 외부 서비스 클라이언트 상수를 Rails config로 통합"
```

## 스킵 조건

다음 경우 wrap-up 스킵:
- 탐색/조사만 수행한 경우 (코드 변경 없음)
- 사용자가 명시적으로 "커밋하지 마" 요청
- WIP(Work In Progress) 상태 명시

## Checklist

```
- [ ] git diff 분석 완료
- [ ] 새로운 교훈 식별 (있으면 추가)
- [ ] CLAUDE.md 인벤토리 최신화
- [ ] 변경 파일 + CLAUDE.md 스테이징
- [ ] 커밋 메시지 작성
- [ ] 커밋 실행
- [ ] CLAUDE.md 100줄 초과 시 정리 수행
```
